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
#import "SettingVC.h"
#import "Masonry.h"
#import "CurrentSettingListsVC.h"
#import "SettingModel.h"
#import "LocalData.h"

#include "edge_ios.h"
#import "Hin2nTunnelManager.h"
#import "CurrentModelSetting.h"
//#import "PacketTunnelEngine.h"


@interface mainVC ()
@property(nonatomic,strong)UIButton * currentSettingButton;
@property(nonatomic,strong)SettingModel * currentSettingModel;
//@property(nonatomic,strong)NSMutableArray * array;
@property(nonatomic,strong)dispatch_source_t source;

@property(nonatomic,strong)UITextView * logView; //日志显示View

@property(nonatomic,strong)NSTimer * logTimer; //日志监听定时器
@property(nonatomic,strong)Hin2nTunnelManager * manger;
@property(nonatomic,strong)UIButton * startButton;

//@property (strong, nonatomic) NEVPNManager *vpnManager;
//
//@property (strong, nonatomic)NETunnelProviderManager * tunnelManager;

@end

@implementation mainVC
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self readLogFile];

  
    [self searchLocalSettingLists];

}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self regNotificationNetworkConnectStatus];
    [self regApplicationExitNotification];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Happynet";
    [self createLogFolder];
    [self initUI];
   
}

-(void)regApplicationExitNotification{
    NSNotificationCenter  * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(exit:) name:@"app_exit" object:nil];
}
-(void)exit:(NSNotification *)notification{
    if (_manger) {
        [_manger stopTunnel];
    }
}
-(void)regNotificationNetworkConnectStatus{
    NSNotificationCenter  * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(networkConnectStatus:) name:@"serviceConnectStatus" object:nil];
}
-(void)networkConnectStatus:(NSNotification *)notification{
    NSDictionary * dic = [notification userInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_startButton.enabled = YES;
        if ([dic[@"status"] integerValue] == 0) {
            self->_startButton.selected = NO;
            [self->_startButton setImage:[UIImage imageNamed:@"ic_state_disconnect"] forState:UIControlStateNormal];

        }else if([dic[@"status"] integerValue] == 1) {
            [self->_startButton setImage:[UIImage imageNamed:@"connecting"] forState:UIControlStateNormal];
        }else if([dic[@"status"] integerValue] == 2) {
            self->_startButton.selected = YES;
            
        }else if([dic[@"status"] integerValue] == 3){
            self->_startButton.selected = NO;
            [self->_startButton setImage:[UIImage imageNamed:@"disConnected"] forState:UIControlStateNormal];
            if (self->_manger) {
                [self->_manger stopTunnel];
            }
        }
    });
  
}
-(void)initUI{
    if (_startButton  == nil) {
        
  
    _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:_startButton];
    _startButton.layer.cornerRadius = 40;
    [_startButton addTarget:self action:@selector(startServer:) forControlEvents:UIControlEventTouchUpInside];
    _startButton.selected = NO;
    [_startButton setImage:[UIImage imageNamed:@"ic_state_disconnect"] forState:UIControlStateNormal];
    [_startButton setImage:[UIImage imageNamed:@"ic_state_connect"] forState:UIControlStateSelected];
   

    _startButton.backgroundColor = [UIColor lightGrayColor];
    [_startButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.top.mas_equalTo(104);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(80);
    }];
    
    UILabel * settingTitle = [[UILabel alloc]init];
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
    
    UIImageView * nextIcon = [[UIImageView alloc]init];
    [self.view addSubview:nextIcon];
    nextIcon.image = [UIImage imageNamed:@"TableViewArrow"];
    [nextIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(settingTitle.mas_top).offset(5);
        make.right.mas_equalTo(-30);
        make.width.mas_equalTo(18);
        make.height.mas_equalTo(18);
    }];
    
    _currentSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:_currentSettingButton];
    [_currentSettingButton addTarget:self action:@selector(currentSettingLists:) forControlEvents:UIControlEventTouchUpInside];
    _currentSettingButton.backgroundColor = [UIColor cyanColor];
    [_currentSettingButton setTitle:NSLocalizedString(@"settingName", nil) forState:UIControlStateNormal];
    [_currentSettingButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];

    [_currentSettingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(settingTitle.mas_top).offset(-5);
        make.right.mas_equalTo(-110);
        make.left.mas_equalTo(settingTitle.mas_right);
        make.height.mas_equalTo(30);
    }];
    
    _logView = [[UITextView alloc]init];
    [self.view addSubview:_logView];
    _logView.editable = NO;
    _logView.layoutManager.allowsNonContiguousLayout= NO;
    _logView.backgroundColor = [UIColor grayColor];
    [_logView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(settingTitle.mas_bottom).offset(15);
        make.right.mas_equalTo(-10);
        make.left.mas_equalTo(10);
        make.bottom.mas_equalTo(-20);
    }];
    _logView.textColor = [UIColor whiteColor];
    [_logView scrollRectToVisible:CGRectMake(0, _logView.contentSize.height-15, _logView.contentSize.width, 10) animated:YES];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeContactAdd];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button];
    [button addTarget:self action:@selector(setting:) forControlEvents:UIControlEventTouchUpInside];
    }
}

+(char *)ocStyleStrConvert2cStyleStr:(NSString *)stringOBJ {
    char *resultCString = NULL;
    if ((NSNull *)stringOBJ != [NSNull null] && [stringOBJ canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        resultCString = (char *)[stringOBJ cStringUsingEncoding:NSUTF8StringEncoding];
    }
    return resultCString;
}

-(void)getCurrentSettings:(CurrentSettings *)cStyleCurrentSetting  {
    cStyleCurrentSetting->version    = _currentSettingModel.version;
    cStyleCurrentSetting->supernode  = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.supernode];
    cStyleCurrentSetting->community  = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.community];
    cStyleCurrentSetting->encryptKey    = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.encrypt];
    cStyleCurrentSetting->ipAddress  = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.ipAddress];
    cStyleCurrentSetting->subnetMark = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.subnetMark];
    cStyleCurrentSetting->deviceDescription = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.deviceDescription];
    cStyleCurrentSetting->supernode2 = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.supernode2];
    cStyleCurrentSetting->mtu        = (int)_currentSettingModel.mtu ;
    cStyleCurrentSetting->gateway    = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.gateway];
    cStyleCurrentSetting->dns        = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.dns];
    cStyleCurrentSetting->mac        = [mainVC ocStyleStrConvert2cStyleStr:_currentSettingModel.mac];
    cStyleCurrentSetting->encryptionMethod = _currentSettingModel.encryptionMethod;
    cStyleCurrentSetting->port       = _currentSettingModel.port;
    cStyleCurrentSetting->forwarding = _currentSettingModel.forwarding;
    cStyleCurrentSetting->acceptMultiMacaddr = _currentSettingModel.isAcceptMulticast;
    cStyleCurrentSetting->level      = _currentSettingModel.level;
    return;
}

#pragma mark //点击启动按钮，启动连接服务  //这里调用C 传参启动服务
-(void)startServer:(UIButton *)button{
    if (_currentSettingModel == nil) {
        _logView.text = @"no setting information";
        return;
    }
    _startButton.enabled = NO;
    [self watchFileChange];
    static CurrentSettings cSettings = {0};
//    [self watchFileChange];
//    button.selected = !button.selected;
    [_startButton setImage:[UIImage imageNamed:@"connecting"] forState:UIControlStateNormal];
    if (!button.selected) { //开始

//       [self startVPNTunnel];
        
        memset(&cSettings, 0, sizeof(cSettings));
        [self getCurrentSettings:&cSettings];

        NSString *log_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];
        if(log_path == nil){ return;}
        NSString * logPath = [log_path stringByAppendingPathComponent:@"n2nLog/n2n.log"];
        cSettings.logPath[sizeof(cSettings.logPath) - 1] = '\0';
        strncpy(cSettings.logPath, logPath.UTF8String, sizeof(cSettings.logPath));
        
        cSettings.vpnFd = [self->_manger startTunnel];
      
        int result = StartEdge(&cSettings);
        if (result<0) {
        [self stopVPN];
         button.selected = NO;
        }
    }else{
        //关闭
        int result = StopEdge();
        if(0 == result){
            [self stopVPN];
            button.backgroundColor = [UIColor lightGrayColor];
            _startButton.selected = NO;
        }
    }
    
}

#pragma mark //设置列表
-(void)currentSettingLists:(UIButton *)button{
    CurrentSettingListsVC * currentSetting = [[CurrentSettingListsVC alloc]init];
    currentSetting.settCallback = ^(SettingModel * _Nonnull callbackData) {
        self->_currentSettingModel = callbackData;
        [self->_currentSettingButton setTitle:callbackData.name forState:UIControlStateNormal];
       
    };
    [self.navigationController pushViewController:currentSetting animated:YES];
}


#pragma mark //设置页面
-(void)setting:(UIButton *)button{
    [self.navigationController pushViewController:[[SettingVC alloc]init] animated:YES];
}


#pragma mark //查询数据库默认取第一条
-(void)searchLocalSettingLists{
    LocalData * db = [[LocalData alloc]init];
    NSMutableArray * arr =  [db searchLocalSettingLists];
//    if (_array.count>0) {
//        [_array removeAllObjects];
//    }
   
    if (arr.count>0) {
        
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger currentId= [userDefaults integerForKey:@"currentSettingModel_row"];
        for (SettingModel * model in arr) {
            if (model.id_key == currentId) {
                _currentSettingModel = model;
            }
        }
        [_currentSettingButton setTitle:_currentSettingModel.name forState:UIControlStateNormal];
        [self initVPN];
    }
 
}

#pragma mark //创建日志文件夹
-(void)createLogFolder{
    NSString * log_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];

    if(log_path == nil){return;}
    NSString * ksnowDir = [log_path stringByAppendingPathComponent:@"n2nLog"];
    NSLog(@"ksnowdir = %@",ksnowDir);
    NSFileManager  *fileMg = [NSFileManager defaultManager];
    BOOL isDirExist = [fileMg fileExistsAtPath:ksnowDir];
    if (!isDirExist) {
    [fileMg createDirectoryAtPath:ksnowDir withIntermediateDirectories:YES attributes:nil error:nil];
}
    
}

#pragma mark 监听n2n.log 的变化
-(void)watchFileChange{
    NSString * log_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];

    if(log_path == nil)
        return;
    
    NSString * n2nLogPath = [log_path stringByAppendingPathComponent:@"n2nLog/n2n.log"];
    NSFileManager  *fileMg = [NSFileManager defaultManager];
    BOOL isLogFileExist = [fileMg fileExistsAtPath:n2nLogPath];
    if (!isLogFileExist) {
        [fileMg createFileAtPath:n2nLogPath contents:nil attributes:nil];
    }
    
    NSURL*directoryURL = [NSURL URLWithString:n2nLogPath];
    int const fd = open([[directoryURL path]fileSystemRepresentation],O_EVTONLY);

    if(fd < 0){
        NSLog(@"Unable to open the path = %@",[directoryURL path]);
        return;
    }
        
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                      fd,
                                                      DISPATCH_VNODE_WRITE|DISPATCH_VNODE_RENAME,
                                                      DISPATCH_TARGET_QUEUE_DEFAULT);

    dispatch_source_set_event_handler(source,^(){
        unsigned long const type = dispatch_source_get_data(source);
        switch(type){
            case DISPATCH_VNODE_WRITE:{
                [self readLogFile];
                break;
            }
            case DISPATCH_VNODE_RENAME:{
                break;
            }
            default:
                break;
            }
        }
    );

    dispatch_source_set_cancel_handler(source,^(){
        close(fd);
    });
    if (_source!= nil) {
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
-(void)readLogFile{
    NSString * log_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];
    if(log_path == nil){return;}
    NSString * ksnowDir = [log_path stringByAppendingPathComponent:@"n2nLog/n2n.log"];
    NSString * resultString = [NSString stringWithContentsOfFile:ksnowDir encoding:NSUTF8StringEncoding error:nil];
//    NSString * lastString = nil;
//    int readLength = 1024 * 1024;
    
//    if (resultString.length > readLength) {
//        lastString = [resultString substringFromIndex:resultString.length - readLength];
//    }else{
//        lastString = resultString;
//    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self->_logView.text = resultString;
        [self->_logView scrollRangeToVisible:NSMakeRange(self->_logView.text.length, 1)];
    });
}


-(void)startVPNTunnel{
    [self initVPN];
}

-(void)initVPN{
    [self setCurrentModelSetting];
    _manger = [Hin2nTunnelManager shareManager];
    [_manger initTunnel:_currentSettingModel];
    __weak typeof(self) weakSelf = self;
    _manger.tunnelStatus = ^(NEVPNStatus status) {
        //tunnel 连接状态
    [weakSelf tunnelConnectStatus:status];
    };
}

//配置设置
-(void)setCurrentModelSetting{
    
    CurrentModelSetting * currentSet = [CurrentModelSetting shareCurrentModelSetting];
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

-(void)stopVPN{
    Hin2nTunnelManager * manger = [Hin2nTunnelManager shareManager];
    NSLog(@"stop tunnel");
    [manger stopTunnel];
    [_logTimer invalidate];
    _logTimer = nil;
    [self stopWatchFileChange];
    

}

//tunnel连接状态
-(void)tunnelConnectStatus:(NEVPNStatus )status{
//    _startButton.selected = NO;
    switch (status) {
        case NEVPNStatusConnected:
            NSLog(@"NEVPNStatusConnected");
//            _startButton.selected = YES;
            break;
        case NEVPNStatusInvalid:
            NSLog(@"NEVPNStatusInvalid");
            break;
        case NEVPNStatusDisconnected:
            NSLog(@"NEVPNStatusDisconnected");
            break;
        case NEVPNStatusConnecting:
            NSLog(@"NEVPNStatusConnecting");

            break;;
            
        case NEVPNStatusReasserting:
            NSLog(@"NEVPNStatusReasserting");

            break;
        case NEVPNStatusDisconnecting:
            NSLog(@"NEVPNStatusDisconnecting");

            break;
        default:
            break;
    }
}
//app 是否处于后台运行？
-(void)backgroundStatus{
    __weak typeof(self) weakSelf = self;
    [Hin2nTunnelManager shareManager].background = ^(BOOL backgroundStatus) {
        if (backgroundStatus) {
            [weakSelf stopWatchFileChange];
        }else{
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

#pragma mark //test Code 点击屏幕空白处调用此方法
#if 0
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self watchFileChange];
    [self writeFile];
}

#pragma mark//---写入文件内容测试

-(void)writeFile{
   
    NSString * log_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];

    if(log_path == nil){return;}
    NSString * ksnowDir = [log_path stringByAppendingPathComponent:@"n2nLog/n2n.log"];
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

