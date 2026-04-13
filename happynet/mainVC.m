//
//  ViewController.m
//  HiN2N_demo
//
//  Created by noontec on 2021/8/18.
//

typedef enum {
  DISCONNECTED = 0,
  CONNECTING,
  CONNECTED,
  SUPERNODE_DISCONNECT
} connectStatus;

#import "mainVC.h"
#import "CurrentSettingListsVC.h"
#import "LocalData.h"
#import "Masonry.h"
#import "SettingModel.h"
#import "SettingVC.h"

#import "CurrentModelSetting.h"
#import "Hin2nTunnelManager.h"
#include "libs_def.h"
// #import "PacketTunnelEngine.h"

@interface mainVC ()
@property(nonatomic, strong) UIButton *currentSettingButton;
@property(nonatomic, strong) SettingModel *currentSettingModel;
//@property(nonatomic,strong)NSMutableArray * array;
@property(nonatomic, strong) dispatch_source_t source;

@property(nonatomic, strong) UITextView *logView; // 日志显示View

@property(nonatomic, strong) NSTimer *logTimer; // 日志监听定时器
@property(nonatomic, strong) Hin2nTunnelManager *manger;
@property(nonatomic, strong) UIButton *startButton;

// 用于区分「超时自动停止」与「手动停止」
// wasConnecting: CONNECTING 后置 YES，CONNECTED 后置 NO，DISCONNECTED
// 后读取并清零 isManualStop:  用户主动点击停止时置 YES，DISCONNECTED 后清零
@property(nonatomic, assign) BOOL wasConnecting;
@property(nonatomic, assign) BOOL isManualStop;

// 主 App 侧「连接中」看门狗
// 当 Extension 进程被 iOS 挂起/杀死时，内部 10s 超时无法触发。
// 此 epoch 计数器配合 dispatch_after 实现 15s 强制停止，
// 每次新连接 epoch 自增，旧看门狗 block 检测到 epoch 不匹配后自动放弃。
@property(nonatomic, assign) NSInteger connectingEpoch;

@end

@implementation mainVC
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self readLogFile];

  [self searchLocalSettingLists];
}
- (void)viewDidLoad {
  [super viewDidLoad];
  [self regNotificationNetworkConnectStatus];
  [self regApplicationExitNotification];
  // Do any additional setup after loading the view.

  if (@available(iOS 13.0, *)) {
    BOOL isDarkMode =
        self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    if (isDarkMode) {
      // 当前是夜间模式
      self.view.backgroundColor = [UIColor blackColor];
    } else {
      // 当前是白天模式
      self.view.backgroundColor = [UIColor whiteColor];
    }
  } else {
    // 设备运行的是旧版本的iOS，此时无法确定模式
    self.view.backgroundColor = [UIColor whiteColor];
  }
  self.title = @"Happynet";
  [self initUI];
}

- (void)regApplicationExitNotification {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(exit:)
                 name:@"app_exit"
               object:nil];
}
- (void)exit:(NSNotification *)notification {
  if (_manger) {
    [_manger stopTunnel];
  }
}
- (void)regNotificationNetworkConnectStatus {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(networkConnectStatus:)
                 name:@"serviceConnectStatus"
               object:nil];
}
- (void)networkConnectStatus:(NSNotification *)notification {
  NSDictionary *dic = [notification userInfo];
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([dic[@"status"] integerValue] == 0) {
      // DISCONNECTED: 恢复按钮，显示断开图标
      // epoch 自增 → 使任何仍在等待的「连接中」看门狗 block 失效
      self->_connectingEpoch++;
      self->_startButton.enabled = YES;
      self->_startButton.selected = NO;
      [self->_startButton setImage:[UIImage imageNamed:@"ic_state_disconnect"]
                          forState:UIControlStateNormal];

      // 若之前处于「连接中」且非用户主动停止 →
      // 说明是超时自动停止，在日志末尾追加提示
      if (self->_wasConnecting && !self->_isManualStop) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm:ss";
        NSString *timeStr = [fmt stringFromDate:[NSDate date]];
        NSString *msg = [NSString
            stringWithFormat:@"\n[%@] ⚠️ Connection timeout. The process has "
                             @"stopped automatically (Failed to connect to the "
                             @"server within 10 seconds)."\n ",
            timeStr];
        self->_logView.text = [self->_logView.text stringByAppendingString:msg];
        [self->_logView
            scrollRangeToVisible:NSMakeRange(self->_logView.text.length, 1)];
      }
      // 重置标志位
      self->_wasConnecting = NO;
      self->_isManualStop = NO;

    } else if ([dic[@"status"] integerValue] == 1) {
      // CONNECTING
      self->_wasConnecting = YES; // 记录进入连接中状态
      self->_startButton.enabled = YES;
      self->_startButton.selected = YES;
      [self->_startButton setImage:[UIImage imageNamed:@"connecting"]
                          forState:UIControlStateSelected];
      [self->_startButton setImage:[UIImage imageNamed:@"connecting"]
                          forState:UIControlStateNormal];

      // ── 主 App 侧「连接中」看门狗 ──────────────────────────────────────────
      // Extension 内部有 10s 超时，但 iOS 可能在极端情况下挂起/杀死 Extension
      // 进程，导致超时 GCD WorkItem 永远不触发，VPN 永久卡在 .connecting。
      // 此看门狗在 15s 后（给 Extension 5s 余量）检查是否仍处于「连接中」，
      // 若是则由主 App 强制调用 stopVPN，确保用户不会永久卡死。
      // epoch 保证旧的 block 在后续新连接时自动失效，不会误杀新连接。
      self->_connectingEpoch++;
      NSInteger capturedEpoch = self->_connectingEpoch;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC),
                     dispatch_get_main_queue(), ^{
                       if (self->_connectingEpoch == capturedEpoch &&
                           self->_wasConnecting) {
                         NSLog(@"[ConnectingWatchdog] 15s elapsed, still "
                               @"CONNECTING — force stopping");
                         [self stopVPN];
                       }
                     });
      // ──────────────────────────────────────────────────────────────────────

    } else if ([dic[@"status"] integerValue] == 2) {
      // CONNECTED：成功建立连接，清除「连接中」标志，不会展示超时提示
      self->_connectingEpoch++; // 使看门狗失效
      self->_wasConnecting = NO;
      self->_startButton.enabled = YES;
      self->_startButton.selected = YES;
      [self->_startButton setImage:[UIImage imageNamed:@"ic_state_connect"]
                          forState:UIControlStateSelected];
    } else if ([dic[@"status"] integerValue] == 3) {
      // SUPERNODE_DISCONNECT (即 .disconnecting)
      // 必须禁用按钮，防止用户在 VPN 尚未完全断开时再次发起连接
      // 超时自动停止场景：按钮在 CONNECTING 时是 enabled，必须在此强制禁止
      // 按钮将在收到 DISCONNECTED(0) 通知后恢复
      self->_startButton.enabled = NO;
      self->_startButton.selected = NO;
      [self->_startButton setImage:[UIImage imageNamed:@"disConnected"]
                          forState:UIControlStateNormal];
    }
  });
}
- (void)initUI {
  if (_startButton == nil) {

    _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:_startButton];
    _startButton.layer.cornerRadius = 40;
    [_startButton addTarget:self
                     action:@selector(startServer:)
           forControlEvents:UIControlEventTouchUpInside];
    _startButton.selected = NO;
    [_startButton setImage:[UIImage imageNamed:@"ic_state_disconnect"]
                  forState:UIControlStateNormal];
    [_startButton setImage:[UIImage imageNamed:@"ic_state_connect"]
                  forState:UIControlStateSelected];

    _startButton.backgroundColor = [UIColor lightGrayColor];
    [_startButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.centerX.mas_equalTo(self.view.mas_centerX);
      make.top.mas_equalTo(104);
      make.width.mas_equalTo(80);
      make.height.mas_equalTo(80);
    }];

    UILabel *settingTitle = [[UILabel alloc] init];
    [self.view addSubview:settingTitle];
    settingTitle.text = NSLocalizedString(@"Current Setting", nil);
    settingTitle.textColor = [UIColor grayColor];
    settingTitle.font = [UIFont systemFontOfSize:16];
    [settingTitle mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.mas_equalTo(_startButton.mas_bottom).offset(20);
      make.left.mas_equalTo(10);
      make.width.mas_equalTo(120);
      make.height.mas_equalTo(20);
    }];

    /*
    UIImageView * nextIcon = [[UIImageView alloc]init];
    [self.view addSubview:nextIcon];
    nextIcon.image = [UIImage imageNamed:@"TableViewArrow"];
    [nextIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(settingTitle.mas_top).offset(5);
        make.right.mas_equalTo(-30);
        make.width.mas_equalTo(18);
        make.height.mas_equalTo(18);
    }];
    */
    UIImage *image = [UIImage imageNamed:@"TableViewArrow"];
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nextButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [nextButton setBackgroundImage:image forState:UIControlStateNormal];
    [nextButton addTarget:self
                   action:@selector(currentSettingLists:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextButton];
    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.mas_equalTo(settingTitle.mas_top).offset(5);
      make.right.mas_equalTo(-30);
      make.width.mas_equalTo(18);
      make.height.mas_equalTo(18);
    }];

    _currentSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:_currentSettingButton];
    [_currentSettingButton addTarget:self
                              action:@selector(currentSettingLists:)
                    forControlEvents:UIControlEventTouchUpInside];
    _currentSettingButton.backgroundColor = [UIColor colorWithRed:135 / 255.0
                                                            green:206 / 255.0
                                                             blue:250 / 255.0
                                                            alpha:1];
    [_currentSettingButton setTitle:NSLocalizedString(@"settingName", nil)
                           forState:UIControlStateNormal];
    [_currentSettingButton setTitleColor:[UIColor grayColor]
                                forState:UIControlStateNormal];

    [_currentSettingButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.mas_equalTo(settingTitle.mas_top).offset(-5);
      make.right.mas_equalTo(-120);
      make.left.mas_equalTo(settingTitle.mas_right);
      make.height.mas_equalTo(30);
    }];

    _logView = [[UITextView alloc] init];
    [self.view addSubview:_logView];
    _logView.editable = NO;
    _logView.layoutManager.allowsNonContiguousLayout = NO;
    _logView.backgroundColor = [UIColor grayColor];
    [_logView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.mas_equalTo(settingTitle.mas_bottom).offset(15);
      make.right.mas_equalTo(-10);
      make.left.mas_equalTo(10);
      make.bottom.mas_equalTo(-20);
    }];
    _logView.textColor = [UIColor whiteColor];
    [_logView
        scrollRectToVisible:CGRectMake(0, _logView.contentSize.height - 15,
                                       _logView.contentSize.width, 10)
                   animated:YES];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithCustomView:button];
    [button addTarget:self
                  action:@selector(setting:)
        forControlEvents:UIControlEventTouchUpInside];
  }

  // 添加一个 footerView
  UIView *footerView = [[UIView alloc] init];
  footerView.backgroundColor = [UIColor grayColor];
  [self.view addSubview:footerView];
  [footerView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(self.view.mas_bottom);
    // make.width.equalTo(self.view.mas_width);
    make.height.mas_equalTo(50);
    make.right.mas_equalTo(-10);
    make.left.mas_equalTo(10);
  }];

  // 在 footerView 中添加版权信息
  UILabel *copyRightLabel = [[UILabel alloc] init];
  copyRightLabel.textColor = [UIColor whiteColor];
  copyRightLabel.font = [UIFont systemFontOfSize:12];
  copyRightLabel.numberOfLines = 2; // 设置为两行
  copyRightLabel.textAlignment = NSTextAlignmentCenter;
  copyRightLabel.text = @"Version 2.7 ©happyn.net\nBased on N2N Project";
  [footerView addSubview:copyRightLabel];
  [copyRightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(footerView.mas_centerX);
    make.centerY.equalTo(footerView.mas_centerY);
    make.width.equalTo(footerView.mas_width);
    make.height.equalTo(@40); // 改为两行文字的高度
  }];
}

+ (char *)ocStyleStrConvert2cStyleStr:(NSString *)stringOBJ {
  char *resultCString = NULL;
  if ((NSNull *)stringOBJ != [NSNull null] &&
      [stringOBJ canBeConvertedToEncoding:NSUTF8StringEncoding]) {
    resultCString =
        (char *)[stringOBJ cStringUsingEncoding:NSUTF8StringEncoding];
  }
  return resultCString;
}

- (void)getCurrentSettings:(CurrentSettings *)cStyleCurrentSetting {
  cStyleCurrentSetting->version = _currentSettingModel.version;
  cStyleCurrentSetting->supernode =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.supernode];
  cStyleCurrentSetting->community =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.community];
  cStyleCurrentSetting->encryptKey =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.encrypt];
  cStyleCurrentSetting->ipAddress =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.ipAddress];
  cStyleCurrentSetting->subnetMark =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.subnetMark];
  cStyleCurrentSetting->deviceDescription = [mainVC
      ocStyleStrConvert2cStyleStr:_currentSettingModel.deviceDescription];
  cStyleCurrentSetting->supernode2 =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.supernode2];
  cStyleCurrentSetting->mtu = (int)_currentSettingModel.mtu;
  cStyleCurrentSetting->gateway =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.gateway];
  cStyleCurrentSetting->dns =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.dns];
  cStyleCurrentSetting->mac =
      [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.mac];
  cStyleCurrentSetting->encryptionMethod =
      _currentSettingModel.encryptionMethod;
  cStyleCurrentSetting->port = _currentSettingModel.port;
  cStyleCurrentSetting->forwarding = _currentSettingModel.forwarding;
  cStyleCurrentSetting->acceptMultiMacaddr =
      _currentSettingModel.isAcceptMulticast;
  cStyleCurrentSetting->level = _currentSettingModel.level;
  return;
}

#pragma mark // 点击启动按钮，启动连接服务  //这里调用C 传参启动服务
- (void)startServer:(UIButton *)button {
  if (_currentSettingModel == nil) {
    _logView.text = @"no setting information";
    return;
  }
  _startButton.enabled = NO;
  [self watchFileChange];
  static CurrentSettings cSettings = {0};
  //[self watchFileChange];
  // button.selected = !button.selected;
  // Keep UI responsive while starting
  if (!button.selected) { // 开始
    //[self startVPNTunnel];
    [_startButton setImage:[UIImage imageNamed:@"connecting"]
                  forState:UIControlStateNormal];
    [_startButton setImage:[UIImage imageNamed:@"connecting"]
                  forState:UIControlStateSelected];

    memset(&cSettings, 0, sizeof(cSettings));
    [self getCurrentSettings:&cSettings];

    NSString *n2nLogPath = [self getn2nLogPath];
    NSLog(@"store property logpath:  %@", n2nLogPath);
    cSettings.logPath[sizeof(cSettings.logPath) - 1] = '\0';
    strncpy(cSettings.logPath, n2nLogPath.UTF8String,
            sizeof(cSettings.logPath));

    int result = [self->_manger startTunnel];
    if (result < 0) {
      [self stopVPN];
      _startButton.enabled = YES;
      button.selected = NO;
      [_startButton setImage:[UIImage imageNamed:@"ic_state_disconnect"]
                    forState:UIControlStateNormal];
    } else {
      _startButton.enabled = YES;
      // The status will be updated via networkConnectStatus: notification
    }
  } else {
    // 停止连接：直接交给 stopVPN 管理按钮状态，
    // 不在此处手动设置 enabled/selected，避免与 stopVPN 内 dispatch_async
    // 产生竞争。
    [self stopVPN];
    button.backgroundColor = [UIColor lightGrayColor];
  }
}

#pragma mark // 设置列表
- (void)currentSettingLists:(UIButton *)button {
  CurrentSettingListsVC *currentSetting = [[CurrentSettingListsVC alloc] init];
  currentSetting.settCallback = ^(SettingModel *_Nonnull callbackData) {
    self->_currentSettingModel = callbackData;
    [self->_currentSettingButton setTitle:callbackData.name
                                 forState:UIControlStateNormal];
  };
  [self.navigationController pushViewController:currentSetting animated:YES];
}

#pragma mark // 设置页面
- (void)setting:(UIButton *)button {
  [self.navigationController pushViewController:[[SettingVC alloc] init]
                                       animated:YES];
}

#pragma mark // 查询数据库默认取第一条
- (void)searchLocalSettingLists {
  LocalData *db = [[LocalData alloc] init];
  NSMutableArray *arr = [db searchLocalSettingLists];
  //    if (_array.count>0) {
  //        [_array removeAllObjects];
  //    }

  if (arr.count > 0) {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger currentId =
        [userDefaults integerForKey:@"currentSettingModel_row"];
    for (SettingModel *model in arr) {
      if (model.id_key == currentId) {
        _currentSettingModel = model;
      }
    }
    [_currentSettingButton setTitle:_currentSettingModel.name
                           forState:UIControlStateNormal];
    [self initVPN];
  }
}

#pragma mark // 创建日志文件夹
- (NSString *)getn2nLogPath {
  static NSString *logFolderPath = nil;
  static NSString *n2nLogPath = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // 获取共享容器的路径
    NSURL *appGroupContainerURL =
        [fileManager containerURLForSecurityApplicationGroupIdentifier:
                         @"group.net.happyn.happynios.happynet"];
    if (appGroupContainerURL == nil) {
      NSLog(@"Failed to get app group container URL");
      logFolderPath = nil;
    }

    // 创建日志文件夹路径
    NSURL *logFolderURL =
        [appGroupContainerURL URLByAppendingPathComponent:@"n2nLog"];
    NSError *error = nil;
    [fileManager createDirectoryAtURL:logFolderURL
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];
    if (error != nil) {
      NSLog(@"Failed to create log folder: %@", error);
      logFolderPath = nil;
    }

    // 构造日志文件路径
    NSURL *logFileURL = [logFolderURL URLByAppendingPathComponent:@"n2n.log"];
    n2nLogPath = [logFileURL path];
  });

  return n2nLogPath;
}

#pragma mark 监听n2n.log 的变化
- (void)watchFileChange {
  NSString *n2nLogPath = [self getn2nLogPath];
  NSFileManager *fileMg = [NSFileManager defaultManager];
  BOOL isLogFileExist = [fileMg fileExistsAtPath:n2nLogPath];
  if (!isLogFileExist) {
    [fileMg createFileAtPath:n2nLogPath contents:nil attributes:nil];
  }

  NSURL *directoryURL = [NSURL URLWithString:n2nLogPath];
  int const fd =
      open([[directoryURL path] fileSystemRepresentation], O_EVTONLY);

  if (fd < 0) {
    NSLog(@"Unable to open the path = %@", [directoryURL path]);
    return;
  }

  dispatch_source_t source =
      dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd,
                             DISPATCH_VNODE_WRITE | DISPATCH_VNODE_RENAME,
                             DISPATCH_TARGET_QUEUE_DEFAULT);

  dispatch_source_set_event_handler(source, ^() {
    unsigned long const type = dispatch_source_get_data(source);
    switch (type) {
    case DISPATCH_VNODE_WRITE: {
      [self readLogFile];
      break;
    }
    case DISPATCH_VNODE_RENAME: {
      break;
    }
    default:
      break;
    }
  });

  dispatch_source_set_cancel_handler(source, ^() {
    close(fd);
  });
  if (_source != nil) {
    _source = nil;
  }
  _source = source;
  dispatch_resume(self.source);
}

- (void)stopWatchFileChange {
  if (_source != nil) {
    dispatch_cancel(_source);
  }
}

#pragma mark // 读取n2n.log文件内容显示到logView
- (void)readLogFile {
  NSString *ksnowDir = [self getn2nLogPath];
  NSLog(@"readLogFile from  %@", ksnowDir);
  NSString *resultString =
      [NSString stringWithContentsOfFile:ksnowDir
                                encoding:NSUTF8StringEncoding
                                   error:nil];

  //    NSString * lastString = nil;
  //    int readLength = 1024 * 1024;

  //    if (resultString.length > readLength) {
  //        lastString = [resultString substringFromIndex:resultString.length -
  //        readLength];
  //    }else{
  //        lastString = resultString;
  //    }

  dispatch_async(dispatch_get_main_queue(), ^{
    self->_logView.text = resultString;
    [self->_logView
        scrollRangeToVisible:NSMakeRange(self->_logView.text.length, 1)];
  });
}

- (void)initVPN {
  [self setCurrentModelSetting];
  _manger = [Hin2nTunnelManager shareManager];
  [_manger initTunnel:_currentSettingModel];
  // 注意：tunnelStatus 回调（对应 vpnStatusDidChanged:）已废弃。
  // VPN 状态由 HappynedgeManager 通过 NEVPNStatusDidChange 监听，
  // 经 setServiceConnectStatus: → serviceConnectStatus 通知驱动 UI。
}

// 配置设置
- (void)setCurrentModelSetting {

  CurrentModelSetting *currentSet =
      [CurrentModelSetting shareCurrentModelSetting];
  currentSet.name = _currentSettingModel.name;
  currentSet.supernode = _currentSettingModel.supernode;
  currentSet.community = _currentSettingModel.community;
  currentSet.encrypt = _currentSettingModel.encrypt;
  currentSet.ipAddress = _currentSettingModel.ipAddress;
  currentSet.subnetMark = _currentSettingModel.subnetMark;
  currentSet.deviceDescription = _currentSettingModel.deviceDescription;
  currentSet.supernode2 = _currentSettingModel.supernode2;
  currentSet.gateway = _currentSettingModel.gateway;
  currentSet.dns = _currentSettingModel.dns;
  currentSet.mac = _currentSettingModel.mac;
  currentSet.mtu = _currentSettingModel.mtu;
  currentSet.version = _currentSettingModel.version;
  currentSet.encryptionMethod = _currentSettingModel.encryptionMethod;
  currentSet.port = _currentSettingModel.port;
  currentSet.forwarding = _currentSettingModel.forwarding;
  currentSet.isAcceptMulticast = _currentSettingModel.isAcceptMulticast;
  currentSet.level = _currentSettingModel.level;
}

- (void)stopVPN {
  Hin2nTunnelManager *manger = [Hin2nTunnelManager shareManager];
  NSLog(@"stop tunnel");
  // 标记为手动停止，防止 DISCONNECTED 时误判为超时并追加提示
  _isManualStop = YES;
  [manger stopTunnel];
  [_logTimer invalidate];
  _logTimer = nil;
  [self stopWatchFileChange];

  // 禁用按钮并显示 connecting 动画，等待 networkConnectStatus 收到
  // DISCONNECTED(0) 通知后再恢复按钮和图标
  // 避免用户在 VPN 还未真正断开时再次点击连接
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_startButton.enabled = NO;
    self->_startButton.selected = NO;
    [self->_startButton setImage:[UIImage imageNamed:@"connecting"]
                        forState:UIControlStateNormal];
  });

  // 安全兼底：如果 10s 内 DISCONNECTED(0) 通知仍未到达（Extension
  // 卡死等异常）， 强制重置 UI，确保用户不会永久卡在连接中状态。
  // 如果正常断开，DISCONNECTED 已恢复按钮，此处 !isEnabled 为 NO， watchdog
  // 不执行。
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{
                   if (!self->_startButton.isEnabled) {
                     NSLog(@"stopVPN watchdog: DISCONNECTED notification not "
                           @"received within "
                           @"10s, force resetting UI");
                     self->_startButton.enabled = YES;
                     self->_startButton.selected = NO;
                     [self->_startButton
                         setImage:[UIImage imageNamed:@"ic_state_disconnect"]
                         forState:UIControlStateNormal];
                   }
                 });
}

// tunnelConnectStatus: 已废弃，仅作历史注释保留。
// VPN 状态 UI 由 networkConnectStatus: (serviceConnectStatus 通知) 驱动，
// 此方法不再被调用。
// app 是否处于后台运行？
- (void)backgroundStatus {
  __weak typeof(self) weakSelf = self;
  [Hin2nTunnelManager shareManager].background = ^(BOOL backgroundStatus) {
    if (backgroundStatus) {
      [weakSelf stopWatchFileChange];
    } else {
      [weakSelf watchFileChange];
    }
  };
}
//-(void)dealloc{
//    NSLog(@"dealloc");
//    if (_manger) {
//        [_manger stopTunnel];
//    }
//}

#pragma mark // test Code 点击屏幕空白处调用此方法
#if 0
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self watchFileChange];
    [self writeFile];
}

#pragma mark //---写入文件内容测试

-(void)writeFile{
   
    NSString * log_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];

    NSString *log_path = [self getLogFolderPath];
    NSString * ksnowDir = [log_path stringByAppendingPathComponent:@"n2n.log"];
    NSLog(@"ksnowdir = %@",ksnowDir);
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:log_path]) {
         [fileManager createFileAtPath:log_path contents:nil attributes:nil];
       }
    NSString * textString = @"-";
   
    [textString writeToFile:ksnowDir atomically:YES encoding:NSUTF8StringEncoding error:nil];// 字符串写入时执行的代码

    NSString * resultString = [NSString stringWithContentsOfFile:ksnowDir encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@", resultString);
}

-(void)setDiscrption{
    NSUserDefaults  * shareDefaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.net.happyn.happynios.happynet"];
    [shareDefaults setInteger:123456 forKey:@"description"];
    
    NSString * d = @"ffffff";
    
    NSData * data = [d  dataUsingEncoding:NSUTF8StringEncoding];
    NSArray * arr = @[data];
    [shareDefaults setObject:arr forKey:@"write_packets"];
    [shareDefaults synchronize];
    
}

#endif
//---------------//test Code end

@end
