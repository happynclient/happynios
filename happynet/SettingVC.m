//
//  SettingVC.m
//  TNASN2N
//
//  Created by noontec on 2021/8/10.
//

#import "SettingVC.h"
#import "Masonry.h"
#import "FMDB.h"
#import "LocalData.h"
#import "SettingModel.h"

@interface SettingVC ()
<UITextFieldDelegate>

@property(nonatomic,strong)NSMutableArray * array; //version 控件布局array
@property(nonatomic,strong)UIView * contextView;
@property(nonatomic,strong)UIScrollView * scrollView;
@property(nonatomic,strong)UIView      * backgroundView;


@property(nonatomic,assign)NSInteger    method; //0-3 AES-CBC,Twofish,Speck-CTR,Chacha20

@property(nonatomic,assign)BOOL         forwarding;  // Enable packet forwarding default NO;
@property(nonatomic,assign)BOOL         acceptMulticast; // Accept multicast mac address default NO;
@property(nonatomic,assign)NSInteger    level; //0-4  error,warning,normal,info,debug default normal

@property(nonatomic,assign)NSInteger    version; //0-3 default 3

//TF:TextField
@property(nonatomic,strong)UITextField * nameTF;
@property(nonatomic,strong)UITextField * supernodeTF;
@property(nonatomic,strong)UITextField * communityTF;
@property(nonatomic,strong)UITextField * EncryptTF;
@property(nonatomic,strong)UITextField * ipAddressTF;
@property(nonatomic,strong)UITextField * subnetMarkTF;
@property(nonatomic,strong)UITextField * deviceDescriptionTF;
@property(nonatomic,strong)UIView      * supernodeView;

//More setting
@property(nonatomic,strong)UITextField * supernode2;
@property(nonatomic,strong)UITextField * mtuTF;
@property(nonatomic,strong)UITextField * portTF;
@property(nonatomic,strong)UITextField * gatewayTF;
@property(nonatomic,strong)UITextField * DNSTF;
@property(nonatomic,strong)UITextField * macAddressTF;

//button
@property(nonatomic,strong)UIButton * selectLevelButton;
@property(nonatomic,strong)UIButton * selectMethodButton;
@property(nonatomic,strong)UIButton * saveButton; //保存
@property(nonatomic,strong)UIButton * moreSettingButton; //更多设置button
@property(nonatomic,strong)UIView   * moreView; //更多设置View

@property(nonatomic,strong)UIButton * getSuperModelButton; //getIp Button

@property(nonatomic,strong)UIButton * getSuperModelIcon;// getIp icon

@property(nonatomic,strong)UIView * superModeTFline;
@property(nonatomic,strong)UIView * communityTFline;
@property(nonatomic,strong)UIView * macLine;
@property(nonatomic,strong)UIView * ipAddressTFline;
@property(nonatomic,strong)UIView * subnetMarkTFLine;

- (UIView *)createFormRowWithIcon:(NSString *)iconName title:(NSString *)titleText control:(UIView *)control parent:(UIView *)parent topAnchor:(UIView *)topAnchor offset:(CGFloat)offset;
- (UIView *)createSwitchRowWithIcon:(NSString *)iconName title:(NSString *)titleText control:(UISwitch *)control parent:(UIView *)parent topAnchor:(UIView *)topAnchor offset:(CGFloat)offset;

@end

@implementation SettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *bgColor = [UIColor colorWithRed:242/255.0 green:245/255.0 blue:250/255.0 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        bgColor = [UIColor systemGroupedBackgroundColor];
    }
    self.view.backgroundColor = bgColor;

    UILabel *titleLabel = [[UILabel alloc] init];
    if (_isUpdate) {
        titleLabel.text = NSLocalizedString(@"Update Setting", nil);
    } else {
        titleLabel.text = NSLocalizedString(@"Add Setting", nil);
        _level = 2;
        _version = 3;
    }
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    if (@available(iOS 13.0, *)) {
        titleLabel.textColor = [UIColor labelColor];
    } else {
        titleLabel.textColor = [UIColor blackColor];
    }
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;

    [self initUI];
    if (_isUpdate) {
        [self setDataFromListVC];
    }
    [self initDB];
}
-(void)initDB{
    LocalData * data =  [[LocalData alloc]init];
    FMDatabase * db =  [data getSettingListsDB];
    [db open];
    [data createTable:db];

}

-(void)searchData:(SettingModel *)model{
    LocalData * data =  [[LocalData alloc]init];
    NSInteger  id_key = [data searchDataByName:model.name];
    _model.id_key = id_key;
}

#pragma mark - UI Helpers

- (UIView *)createFormRowWithIcon:(NSString *)iconName
                            title:(NSString *)titleText
                          control:(UIView *)control
                           parent:(UIView *)parent
                        topAnchor:(UIView *)topAnchor
                           offset:(CGFloat)offset {
    UIView *container = [[UIView alloc] init];
    [parent addSubview:container];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        if (topAnchor) {
            make.top.mas_equalTo(topAnchor.mas_bottom).offset(offset);
        } else {
            make.top.mas_equalTo(parent).offset(offset);
        }
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(60);
    }];
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        iconBg.backgroundColor = [UIColor systemGray6Color];
    }
    iconBg.layer.cornerRadius = 12;
    [container addSubview:iconBg];
    [iconBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.centerY.mas_equalTo(container);
        make.width.height.mas_equalTo(44);
    }];
    
    UIImageView *iconView = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        iconView.image = [UIImage systemImageNamed:iconName];
        iconView.tintColor = [UIColor systemBlueColor];
    }
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [iconBg addSubview:iconView];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(iconBg);
        make.width.height.mas_equalTo(20);
    }];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = titleText;
    titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor grayColor];
    if (@available(iOS 13.0, *)) {
        titleLabel.textColor = [UIColor secondaryLabelColor];
    }
    [container addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(iconBg.mas_right).offset(12);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(16);
    }];
    
    UIView *controlBg = [[UIView alloc] init];
    controlBg.backgroundColor = [UIColor whiteColor];
    controlBg.layer.cornerRadius = 8;
    controlBg.layer.borderWidth = 1.0;
    if (@available(iOS 13.0, *)) {
        controlBg.layer.borderColor = [UIColor separatorColor].CGColor;
        controlBg.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    } else {
        controlBg.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    }
    [container addSubview:controlBg];
    [controlBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(iconBg.mas_right).offset(12);
        make.top.mas_equalTo(titleLabel.mas_bottom).offset(4);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [controlBg addSubview:control];
    [control mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(12);
        make.right.mas_equalTo(-12);
        make.top.bottom.mas_equalTo(0);
    }];
    
    return container;
}

- (UIView *)createSwitchRowWithIcon:(NSString *)iconName title:(NSString *)titleText control:(UISwitch *)control parent:(UIView *)parent topAnchor:(UIView *)topAnchor offset:(CGFloat)offset {
    UIView *row = [[UIView alloc] init];
    row.backgroundColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        row.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    }
    row.layer.cornerRadius = 12;
    [parent addSubview:row];
    
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        if (topAnchor) {
            make.top.mas_equalTo(topAnchor.mas_bottom).offset(offset);
        } else {
            make.top.mas_equalTo(parent.mas_top).offset(offset);
        }
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(60);
    }];
    
    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = [UIColor colorWithRed:26/255.0 green:126/255.0 blue:240/255.0 alpha:0.1];
    if (@available(iOS 13.0, *)) {
        iconBg.backgroundColor = [UIColor systemGray6Color];
    }
    iconBg.layer.cornerRadius = 12;
    [row addSubview:iconBg];
    [iconBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.centerY.mas_equalTo(row);
        make.width.height.mas_equalTo(44);
    }];
    
    UIImageView *iconView = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        iconView.image = [UIImage systemImageNamed:iconName];
        iconView.tintColor = [UIColor systemBlueColor];
    }
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [iconBg addSubview:iconView];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(iconBg);
        make.width.height.mas_equalTo(20);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = titleText;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    if (@available(iOS 13.0, *)) {
        label.textColor = [UIColor labelColor];
    }
    [row addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(iconBg.mas_right).offset(12);
        make.centerY.mas_equalTo(row);
    }];
    
    [row addSubview:control];
    [control mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-12);
        make.centerY.mas_equalTo(row);
    }];
    
    return row;
}

-(void)initUI{

    UIColor *cardColor = [UIColor whiteColor];
    UIColor *titleColor = [UIColor blackColor];
    UIColor *subTitleColor = [UIColor grayColor];
    if (@available(iOS 13.0, *)) {
        cardColor = [UIColor secondarySystemGroupedBackgroundColor];
        titleColor = [UIColor labelColor];
        subTitleColor = [UIColor secondaryLabelColor];
    }

    // Background Gradient
    UIView *gradientBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 300)];
    [self.view insertSubview:gradientBg atIndex:0];
    CAGradientLayer *gl = [CAGradientLayer layer];
    gl.frame = gradientBg.bounds;
    gl.colors = @[
        (__bridge id)[UIColor colorWithRed:0.85 green:0.92 blue:1.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.85 green:0.92 blue:1.0 alpha:0.0].CGColor
    ];
    [gradientBg.layer addSublayer:gl];

    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor = cardColor;
    footerView.layer.cornerRadius = 16;
    footerView.layer.shadowColor = [UIColor blackColor].CGColor;
    footerView.layer.shadowOffset = CGSizeMake(0, 2);
    footerView.layer.shadowOpacity = 0.05;
    footerView.layer.shadowRadius = 8;
    [self.view addSubview:footerView];

    [footerView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
        } else {
            make.bottom.equalTo(self.view.mas_bottom).offset(-20);
        }
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(70);
    }];

    UIView *footerContentContainer = [[UIView alloc] init];
    [footerView addSubview:footerContentContainer];
    [footerContentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(footerView);
        make.height.mas_equalTo(40);
    }];

    UIView *shieldIconBg = [[UIView alloc] init];
    shieldIconBg.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0];
    shieldIconBg.layer.cornerRadius = 8;
    [footerContentContainer addSubview:shieldIconBg];
    [shieldIconBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(footerContentContainer);
        make.centerY.equalTo(footerContentContainer);
        make.width.height.mas_equalTo(40);
    }];

    UIImageView *shieldIcon = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        shieldIcon.image = [UIImage systemImageNamed:@"checkmark.shield.fill"];
        shieldIcon.tintColor = [UIColor whiteColor];
    }
    [shieldIconBg addSubview:shieldIcon];
    [shieldIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(shieldIconBg);
        make.width.height.mas_equalTo(24);
    }];

    UILabel *sloganLabel = [[UILabel alloc] init];
    sloganLabel.text = @"HAPPYN makes the internet simpler.";
    sloganLabel.font = [UIFont boldSystemFontOfSize:12];
    sloganLabel.textColor = titleColor;
    [footerContentContainer addSubview:sloganLabel];
    [sloganLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(shieldIconBg.mas_right).offset(12);
        make.top.equalTo(shieldIconBg).offset(2);
    }];

    UILabel *copyRightLabel = [[UILabel alloc] init];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"2.9";
    copyRightLabel.text = [NSString stringWithFormat:@"Version %@ © happyn.net | Based on N2N Project", appVersion];
    copyRightLabel.font = [UIFont systemFontOfSize:10];
    copyRightLabel.textColor = subTitleColor;
    [footerContentContainer addSubview:copyRightLabel];
    [copyRightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sloganLabel);
        make.bottom.equalTo(shieldIconBg).offset(-2);
        make.right.equalTo(footerContentContainer);
    }];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = [UIColor clearColor]; // Reveal gradient
    [self.view addSubview:_scrollView];
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.mas_equalTo(self.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.mas_equalTo(64);
        }
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(footerView.mas_top).offset(-10);
    }];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1150);
    _contextView = [[UIView alloc]initWithFrame:CGRectZero];
    
    [_scrollView addSubview:_contextView];
    _contextView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height+1150);

    _nameTF = [[UITextField alloc]init];
    _nameTF.delegate = self;
    _nameTF.keyboardType = UIKeyboardTypeDefault;
    _nameTF.placeholder = @"name";
    _nameTF.returnKeyType = UIReturnKeyDone;
    if (@available(iOS 10.0, *)) {
        _nameTF.textContentType = @"userName";
    }
    UIView *row1 = [self createFormRowWithIcon:@"person.crop.square" title:NSLocalizedString(@"Setting Name", nil) control:_nameTF parent:_contextView topAnchor:nil offset:30];

    _supernodeTF = [[UITextField alloc]init];
    _supernodeTF.delegate = self;
    _supernodeTF.keyboardType = UIKeyboardTypeDefault;
    _supernodeTF.placeholder = @"vip00.happyn.cc:30001";
    UIView *row2 = [self createFormRowWithIcon:@"link" title:NSLocalizedString(@"supernode", nil) control:_supernodeTF parent:_contextView topAnchor:row1 offset:20];

    _communityTF = [[UITextField alloc]init];
    _communityTF.delegate = self;
    _communityTF.keyboardType = UIKeyboardTypeDefault;
    _communityTF.placeholder = @"VIP0378";
    UIView *row3 = [self createFormRowWithIcon:@"person.2.badge.gearshape" title:NSLocalizedString(@"community", nil) control:_communityTF parent:_contextView topAnchor:row2 offset:20];

    _EncryptTF = [[UITextField alloc]init];
    _EncryptTF.delegate = self;
    _EncryptTF.keyboardType = UIKeyboardTypeDefault;
    _EncryptTF.placeholder = NSLocalizedString(@"Encrypt Key", nil);
    UIView *row4 = [self createFormRowWithIcon:@"key.fill" title:NSLocalizedString(@"Encrypt Key", nil) control:_EncryptTF parent:_contextView topAnchor:row3 offset:20];


    _supernodeView = [[UIView alloc]init];
    [_contextView addSubview:_supernodeView];
    [_supernodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(row4.mas_bottom).offset(20);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(140);
    }];

    _ipAddressTF = [[UITextField alloc]init];
    _ipAddressTF.delegate = self;
    _ipAddressTF.keyboardType = UIKeyboardTypeDecimalPad;
    _ipAddressTF.placeholder = NSLocalizedString(@"ip address", nil);
    UIView *row5 = [self createFormRowWithIcon:@"network" title:NSLocalizedString(@"ip address", nil) control:_ipAddressTF parent:_supernodeView topAnchor:nil offset:0];

    _subnetMarkTF = [[UITextField alloc]init];
    _subnetMarkTF.delegate = self;
    _subnetMarkTF.keyboardType = UIKeyboardTypeDecimalPad;
    _subnetMarkTF.placeholder = NSLocalizedString(@"Subnet Mark", nil);
    [self createFormRowWithIcon:@"globe" title:NSLocalizedString(@"Subnet Mark", nil) control:_subnetMarkTF parent:_supernodeView topAnchor:row5 offset:20];

    _deviceDescriptionTF = [[UITextField alloc]init];
    _deviceDescriptionTF.delegate = self;
    _deviceDescriptionTF.keyboardType = UIKeyboardTypeDefault;
    _deviceDescriptionTF.placeholder = NSLocalizedString(@"Device Description", nil);
    UIView *row7 = [self createFormRowWithIcon:@"doc.text" title:NSLocalizedString(@"Device Description", nil) control:_deviceDescriptionTF parent:_contextView topAnchor:_supernodeView offset:20];

    // Expert Settings Card
    UIView *expertCard = [[UIView alloc] init];
    expertCard.backgroundColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        expertCard.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    }
    expertCard.layer.cornerRadius = 12;
    [_contextView addSubview:expertCard];
    [expertCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(row7.mas_bottom).offset(30);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(64);
    }];

    UIImageView *checkIcon = [[UIImageView alloc] init];
    checkIcon.tag = 1001;
    if (@available(iOS 13.0, *)) {
        checkIcon.image = [UIImage systemImageNamed:@"square"];
        checkIcon.tintColor = [UIColor systemGrayColor];
    }
    [expertCard addSubview:checkIcon];
    [checkIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.centerY.mas_equalTo(expertCard);
        make.width.height.mas_equalTo(24);
    }];

    UILabel *expertTitle = [[UILabel alloc] init];
    expertTitle.text = @"专家设置";
    expertTitle.font = [UIFont boldSystemFontOfSize:16];
    [expertCard addSubview:expertTitle];
    [expertTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(checkIcon.mas_right).offset(12);
        make.top.mas_equalTo(12);
    }];

    UILabel *expertSub = [[UILabel alloc] init];
    expertSub.text = @"显示高级选项 (路由、加密、NAT 穿透等)";
    expertSub.font = [UIFont systemFontOfSize:12];
    expertSub.textColor = [UIColor systemGrayColor];
    [expertCard addSubview:expertSub];
    [expertSub mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(expertTitle);
        make.top.mas_equalTo(expertTitle.mas_bottom).offset(2);
    }];

    UIImageView *chevron = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        chevron.image = [UIImage systemImageNamed:@"chevron.right"];
        chevron.tintColor = [UIColor systemGrayColor];
    }
    [expertCard addSubview:chevron];
    [chevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.centerY.mas_equalTo(expertCard);
        make.width.mas_equalTo(12);
        make.height.mas_equalTo(20);
    }];

    _moreSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [expertCard addSubview:_moreSettingButton];
    [_moreSettingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    [_moreSettingButton addTarget:self action:@selector(moreSettingIcon:) forControlEvents:UIControlEventTouchUpInside];

    // Placeholder subviews to keep original references intact if needed
    UIView *versionView = [[UIView alloc] init];
    versionView.hidden = YES;
    [_contextView addSubview:versionView];
    
    _getSuperModelIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    _getSuperModelIcon.hidden = YES;
    [_contextView addSubview:_getSuperModelIcon];
    
    _getSuperModelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _getSuperModelButton.hidden = YES;
    [_contextView addSubview:_getSuperModelButton];

    _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_contextView addSubview:_saveButton];
    [_saveButton addTarget:self action:@selector(saveSettingData:) forControlEvents:UIControlEventTouchUpInside];
    [_saveButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateNormal];
    [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _saveButton.backgroundColor = [UIColor systemBlueColor];
    _saveButton.layer.cornerRadius = 12;
    _saveButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    
    [_saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(expertCard.mas_bottom).offset(40);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(54);
    }];
}

#pragma mark moreSettingView
-(void)moreSetting:(UIButton *)button{
    _moreView = [[UIView alloc]init];
    [_contextView addSubview:_moreView];
    [_moreView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(button.mas_bottom).offset(5);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(620);
    }];
    
    _selectMethodButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (_isUpdate) {
        [self setSelectMethodButtonTitle];
    }else{
       [_selectMethodButton setTitle:@"AES-CBC" forState:UIControlStateNormal];
    }
    [_selectMethodButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        [_selectMethodButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    }
    _selectMethodButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_selectMethodButton addTarget:self action:@selector(selectMethod) forControlEvents:UIControlEventTouchUpInside];
    UIView *mRow1 = [self createFormRowWithIcon:@"lock.shield" title:NSLocalizedString(@"Encryption method", nil) control:_selectMethodButton parent:_moreView topAnchor:nil offset:20];

    _supernode2 = [[UITextField alloc]init];
    _supernode2.delegate = self;
    _supernode2.placeholder = NSLocalizedString(@"Supernode2", nil);
    _supernode2.hidden = YES;
    UIView *mRow2 = [self createFormRowWithIcon:@"link.badge.plus" title:NSLocalizedString(@"Supernode2", nil) control:_supernode2 parent:_moreView topAnchor:mRow1 offset:20];
    mRow2.hidden = YES;

    _mtuTF = [[UITextField alloc]init];
    _mtuTF.delegate = self;
    if (_model.mtu > 0) {
        self.mtuTF.text = [NSString stringWithFormat:@"%ld",_model.mtu];
    } else {
        _mtuTF.placeholder = @"1386";
    }
    _mtuTF.keyboardType = UIKeyboardTypeNumberPad;
    UIView *mRow3 = [self createFormRowWithIcon:@"ruler" title:NSLocalizedString(@"MTU", nil) control:_mtuTF parent:_moreView topAnchor:mRow1 offset:20];

    _portTF = [[UITextField alloc]init];
    _portTF.delegate = self;
    if (_model.port > 0) {
        self.portTF.text = [NSString stringWithFormat:@"%ld",_model.port];
    } else {
        _portTF.placeholder = @"0";
    }
    _portTF.keyboardType = UIKeyboardTypeNumberPad;
    UIView *mRow4 = [self createFormRowWithIcon:@"number" title:NSLocalizedString(@"Port", nil) control:_portTF parent:_moreView topAnchor:mRow3 offset:20];

    _gatewayTF = [[UITextField alloc]init];
    _gatewayTF.delegate = self;
    _gatewayTF.keyboardType = UIKeyboardTypeDecimalPad;
    _gatewayTF.placeholder = NSLocalizedString(@"gateway ip address", nil);
    UIView *mRow5 = [self createFormRowWithIcon:@"externaldrive" title:NSLocalizedString(@"gateway", nil) control:_gatewayTF parent:_moreView topAnchor:mRow4 offset:20];

    _DNSTF = [[UITextField alloc]init];
    _DNSTF.delegate = self;
    _DNSTF.keyboardType = UIKeyboardTypeDecimalPad;
    _DNSTF.placeholder = NSLocalizedString(@"DNS server ip address", nil);
    UIView *mRow6 = [self createFormRowWithIcon:@"bolt.horizontal.circle" title:NSLocalizedString(@"DNS", nil) control:_DNSTF parent:_moreView topAnchor:mRow5 offset:20];
    _DNSTF.hidden = YES;
    mRow6.hidden = YES;

    _macAddressTF = [[UITextField alloc]init];
    _macAddressTF.delegate = self;
    _macAddressTF.placeholder = NSLocalizedString(@"mac address", nil);
    UIView *mRow7 = [self createFormRowWithIcon:@"cpu" title:NSLocalizedString(@"mac address", nil) control:_macAddressTF parent:_moreView topAnchor:mRow5 offset:20];

    // Forwarding Row
    UISwitch *forwardingSwitch = [[UISwitch alloc] init];
    [forwardingSwitch setOn:_forwarding];
    [forwardingSwitch addTarget:self action:@selector(forwardingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    UIView *mRow8 = [self createSwitchRowWithIcon:@"arrow.right.arrow.left" title:NSLocalizedString(@"Enable packet forwarding", nil) control:forwardingSwitch parent:_moreView topAnchor:mRow7 offset:20];

    // Accept Multicast Row
    UISwitch *multicastSwitch = [[UISwitch alloc] init];
    [multicastSwitch setOn:_acceptMulticast];
    [multicastSwitch addTarget:self action:@selector(multicastSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    UIView *mRow9 = [self createSwitchRowWithIcon:@"antenna.radiowaves.left.and.right" title:NSLocalizedString(@"Accept multicast Mac address", nil) control:multicastSwitch parent:_moreView topAnchor:mRow8 offset:20];

    // Trace Level Row
    _selectLevelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (_isUpdate) {
        [self setlevelButtonTitle];
    } else {
        [_selectLevelButton setTitle:@"NORMAL" forState:UIControlStateNormal];
    }
    _selectLevelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_selectLevelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        [_selectLevelButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    }
    [_selectLevelButton addTarget:self action:@selector(alertLevelView) forControlEvents:UIControlEventTouchUpInside];
    UIView *mRow10 = [self createFormRowWithIcon:@"list.bullet.rectangle" title:NSLocalizedString(@"Trace level:", nil) control:_selectLevelButton parent:_moreView topAnchor:mRow9 offset:20];

    [_saveButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(mRow10.mas_bottom).offset(40);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(54);
    }];
}

- (void)forwardingSwitchChanged:(UISwitch *)sender {
    _forwarding = sender.isOn;
}

- (void)multicastSwitchChanged:(UISwitch *)sender {
    _acceptMulticast = sender.isOn;
}



#pragma mark //选择版本
-(void)selectItem:(UIButton *)button{
    _version = button.tag - 30;
    for (UIButton * btn in _array) {
        if (btn == button) {
            btn.selected = YES;
//            _version = button.titleLabel.text;
            btn.layer.borderColor = [UIColor orangeColor].CGColor;
        }else{
            btn.layer.borderColor = [UIColor grayColor].CGColor;
            btn.selected = NO;
        }
    }
}

#pragma mark //保存设置
-(void)saveSettingData:(UIButton *)button{
    if (_nameTF.text  == nil || _nameTF.text.length <1|| [_nameTF.text isEqual:@""]) {
        [self alertMessage:@"Name is error"];
        return;
    }
    if (_supernodeTF.text != nil){
        if (![self checkSupnodeAddress:_supernodeTF.text]) {
            [self alertMessage:NSLocalizedString(@"Supnode is error", nil)];
        return;
        }
    }
    if (_communityTF.text == nil ||
        _communityTF.text.length <1 ||
        [_communityTF.text isEqual:@""]){
        [self alertMessage:NSLocalizedString(@"Community is error", nil)];
        _communityTFline.backgroundColor = [UIColor redColor];
        return;
    }
    if (_deviceDescriptionTF.text == nil||      _deviceDescriptionTF.text.length <1||
        [_deviceDescriptionTF.text isEqual:@""]){
        //[self alertMessage:@"Description is error"];
        _deviceDescriptionTF.text = @"happynios";
        return;
    }
    if (_macAddressTF.text != nil){
        if (![self checkMacAddress:_macAddressTF.text]) {
            [self alertMessage:NSLocalizedString(@"MAC Address is error!", nil)];
            _macLine.backgroundColor = [UIColor redColor];
            return;
        };
        }
    if (_getSuperModelIcon.selected == NO) {
        if (![self checkIpAddress:_ipAddressTF.text]) {
            [self alertMessage:NSLocalizedString(@"IP address is error", nil)];
            return;
        };
        if (![self checkMark:_subnetMarkTF.text]) {
            [self alertMessage:NSLocalizedString(@"subnetMark is error", nil)];
            return;
        }
    }
    LocalData * data = [[LocalData alloc]init];
    SettingModel * model = [[SettingModel alloc]init];
    model.forwarding = _forwarding;
    model.isAcceptMulticast = _acceptMulticast;
    model.version = _version;
    model.level = _level;
    model.name  = _nameTF.text;
    model.supernode = _supernodeTF.text;
    model.community = _communityTF.text;
    model.encrypt = _EncryptTF.text;
    model.ipAddress = _ipAddressTF.text;
    model.subnetMark = _subnetMarkTF.text;
    model.deviceDescription = _deviceDescriptionTF.text;
    model.supernode2 = _supernode2.text;
        
    model.gateway = _gatewayTF.text;
    model.dns = _DNSTF.text;
    model.mac = _macAddressTF.text;
    
    model.mtu = [_mtuTF.text integerValue];
    model.port = [_portTF.text integerValue];
    model.encryptionMethod = _method;
    __weak typeof(self) weakSelf = self;
    if (_isUpdate) {
        model.id_key = self.model.id_key;
        [data updateLocaSettingLists:model];
        data.updateCallback = ^(BOOL isSuccess) {
            if (isSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];

                });  
            }
        };
    }else{
        [data insertLocalSettingLists:model];
        data.insertCallBack = ^(BOOL isSuccess) {
            if (isSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];

                });            }
        };
    }

}

-(void)selectMethod{
    _backgroundView = [[UIView alloc]init];
    _backgroundView.frame = self.view.window.bounds;
    _backgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_backgroundView];
    
    UIView * alertLevelView = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.size.width-220, self.view.frame.size.height, 200, 250)];
    [_backgroundView addSubview:alertLevelView];
    alertLevelView.backgroundColor = [UIColor whiteColor];
    alertLevelView.layer.borderWidth = 1;
    alertLevelView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    alertLevelView.layer.cornerRadius = 5;
    CGFloat item_h = 5;
    
//    2是speck，3是chacha。
    NSArray * itemTextArray = @[@"AES-CBC",@"Twofish",@"Speck-CRT",@"ChaCha20"];
    for (int i = 0; i<itemTextArray.count; i++) {
        UIButton * levelItemButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [alertLevelView addSubview:levelItemButton];
        levelItemButton.frame = CGRectMake(0, item_h, alertLevelView.frame.size.width, 44);
        [levelItemButton setTitle:itemTextArray[i] forState:UIControlStateNormal];
        [levelItemButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [levelItemButton addTarget:self action:@selector(selectMethodItem:) forControlEvents:UIControlEventTouchUpInside];
        levelItemButton.tag = 20+i;
        item_h += 44;
    }
    [UIView animateWithDuration:0.33 animations:^{
        //alertLevelView.frame = CGRectMake(self.view.frame.size.width-220, self.view.frame.size.height-250, 200, 250);
        alertLevelView.frame = CGRectMake((self.view.frame.size.width-200)/2, (self.view.frame.size.height-250)/2, 200, 250);
        } completion:^(BOOL finished) {
            
        }];
    
    UITapGestureRecognizer * ges = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelAlertLevelView)];
    _backgroundView.userInteractionEnabled = YES;
    [_backgroundView addGestureRecognizer:ges];
    
}

-(void)selectMethodItem:(UIButton *)selectItemButton{
    _method = selectItemButton.tag - 20;
    [_selectMethodButton setTitle:selectItemButton.titleLabel.text forState:UIControlStateNormal];
    [self cancelAlertLevelView];
}

-(void)moreSettingButton:(UIButton *)button{
    button.selected = !button.selected;
}
-(void)moreSettingIcon:(UIButton *)button{
    button.selected = !button.selected;
    _moreSettingButton.selected = button.selected;
    
    UIImageView *checkIcon = [button.superview viewWithTag:1001];
    if (button.selected) {
        if (@available(iOS 13.0, *)) {
            checkIcon.image = [UIImage systemImageNamed:@"checkmark.square.fill"];
            checkIcon.tintColor = [UIColor systemBlueColor];
        }
        _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1800);
        [self moreSetting: _moreSettingButton];
        
        [_saveButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_moreView.mas_bottom).offset(40);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(54);
        }];
    }else{
        if (@available(iOS 13.0, *)) {
            checkIcon.image = [UIImage systemImageNamed:@"square"];
            checkIcon.tintColor = [UIColor systemGrayColor];
        }
        [self cancelMoreView];
        _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1150);
        
        [_saveButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(button.superview.mas_bottom).offset(40);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(54);
        }];
    }
    
    if ([[_model.mac class] isEqual:[NSNull class]] ||_model.mac.length <5 ) {
        self.macAddressTF.text = [self getMac];
    }else{
        self.macAddressTF.text = _model.mac;
    }
    
    if ([[_model.gateway class] isEqual:[NSNull class]]) {
        _gatewayTF.placeholder = NSLocalizedString(@"gateway ip address", nil);
    } else {
        self.gatewayTF.text = _model.gateway;
    }
    
}

-(void)cancelMoreView{
    [_moreView removeFromSuperview];
    _moreView = nil;
}
-(void)getSuperModel:(UIButton *)button
{
    //_getSuperModelIcon.selected = !button.selected;
    _getSuperModelIcon.selected = false;
    if (button.selected) {
        _supernodeView.hidden = YES;
        _ipAddressTF.text = nil;
        _subnetMarkTF.text = nil;
        [_supernodeView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_getSuperModelButton.mas_bottom).offset(10);
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.height.mas_equalTo(0);
        }];
    }else{
        _supernodeView.hidden = NO;
        
        [_supernodeView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_getSuperModelButton.mas_bottom).offset(10);
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.height.mas_equalTo(90);
        }];

    }
    [self viewWillLayoutSubviews];
}
-(void)forwardingButtonClick:(UIButton *)button{
    button.selected = !button.selected;
    _forwarding = button.selected;
}

-(void)acceptMulticast:(UIButton *)button{
     button.selected = !button.selected;
    _acceptMulticast = button.selected;
    
}

//level 选择框
-(void)alertLevelView{
    _backgroundView = [[UIView alloc]init];
    _backgroundView.frame = self.view.window.bounds;
    _backgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_backgroundView];
    
    UIView * alertLevelView = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.size.width-220, self.view.frame.size.height, 200, 250)];

    [_backgroundView addSubview:alertLevelView];
    alertLevelView.backgroundColor = [UIColor whiteColor];
    alertLevelView.layer.borderWidth = 1;
    alertLevelView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    alertLevelView.layer.cornerRadius = 5;
    CGFloat item_h = 5;
    
    NSArray * itemTextArray = @[@"ERROR",@"WARNING",@"NORMAL",@"INFO",@"DEBUG"];
    for (int i = 0; i<5; i++) {
        UIButton * levelItemButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [alertLevelView addSubview:levelItemButton];
        levelItemButton.frame = CGRectMake(0, item_h, alertLevelView.frame.size.width, 44);
        [levelItemButton setTitle:itemTextArray[i] forState:UIControlStateNormal];
        [levelItemButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [levelItemButton addTarget:self action:@selector(selectLevel:) forControlEvents:UIControlEventTouchUpInside];
        levelItemButton.tag = 10+i;
        item_h += 44;
    }
    [UIView animateWithDuration:0.33 animations:^{
        //alertLevelView.frame = CGRectMake(self.view.frame.size.width-220, self.view.frame.size.height-250, 200, 250);
        alertLevelView.frame = CGRectMake((self.view.frame.size.width-200)/2, (self.view.frame.size.height-250)/2, 200, 250);
        } completion:^(BOOL finished) {
            
        }];
    
    UITapGestureRecognizer * ges = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelAlertLevelView)];
    _backgroundView.userInteractionEnabled = YES;
    [_backgroundView addGestureRecognizer:ges];
}
-(void)cancelAlertLevelView{
    [_backgroundView removeFromSuperview];
    _backgroundView = nil;
}

-(void)methodAlertView{
    
}
-(void)cancelMethodAlertView{
    
}

-(void)selectLevel:(UIButton *)selectLevelButton{
    _level = selectLevelButton.tag - 10;
    [_selectLevelButton setTitle: selectLevelButton.titleLabel.text forState:UIControlStateNormal];
    [self cancelAlertLevelView];
}

-(void)viewDidLayoutSubviews{
    if (!_moreSettingButton.selected) {
        [_saveButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(_moreSettingButton.mas_bottom).offset(60);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(44);
        }];
    }
    NSLog(@"viewDidLayoutSubviews");
}


-(void)setDataFromListVC{
    if (self.model) {
        self.version =_model.version;
        self.nameTF.text = _model.name;
        self.forwarding = _model.forwarding;
        self.acceptMulticast = _model.isAcceptMulticast;
        self.supernodeTF.text = _model.supernode;
        self.communityTF.text = _model.community;
        self.EncryptTF.text = _model.encrypt;
        self.ipAddressTF.text = _model.ipAddress;
        self.subnetMarkTF.text = _model.subnetMark;
        self.deviceDescriptionTF.text = _model.deviceDescription;
        self.supernode2.text = _model.supernode2;
        self.mtuTF.text = [NSString stringWithFormat:@"%ld",_model.mtu];
        self.portTF.text = [NSString stringWithFormat:@"%ld",_model.port];
        self.gatewayTF.text = _model.gateway;
        self.DNSTF.text = _model.dns;
        for (UIButton *button in _array) {
            if (button.tag - 30 == _model.version) {
                [self selectItem:button];
        }}
        
        [self setlevelButtonTitle];
        [self setSelectMethodButtonTitle];
        if (self.ipAddressTF.text.length<5) {
            [self getSuperModel:_getSuperModelIcon];
        }
    }
}

//设置levelbutton 显示的信息
-(void)setlevelButtonTitle{
    _level = _model.level;
    NSString * levelName = nil;
    switch (_model.level) {
        case 0:
            levelName = @"ERROR";
            break;
        case 1:
            levelName = @"WARNING";
            break;
        case 2:
            levelName = @"NORMAL";
            break;
        case 3:
            levelName = @"INFO";
            break;
        case 4:
            levelName = @"DEBUG";
            break;
        default:
            break;
    }
    [_selectLevelButton setTitle:levelName forState:UIControlStateNormal];
}

-(void)setSelectMethodButtonTitle{
    NSString * levelName = nil;
    _method = _model.encryptionMethod;
    switch (_model.encryptionMethod) {
        case 0:
            levelName = @"AES-CBC";
            break;
        case 1:
            levelName = @"Twofish";
            break;
        case 2:
            levelName = @"Speck-CTR";
            break;
        case 3:
            levelName = @"Chacha20";
            break;
        default:
            break;
    }
    [_selectMethodButton setTitle:levelName forState:UIControlStateNormal];
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [_scrollView endEditing:YES];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField endEditing:YES];
    return YES;
}

-(void)refreshMac:(UIButton *)button{
    _macAddressTF.text = [self getMac];
}

#pragma mark //随机生成mac
-(NSString *)getMac{
    NSDate *datenow = [NSDate date];
        NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];

    NSString * timeValue = timeSp;

    NSString * macString = @"00";
    NSString * temp = nil;

    for (int i = 0; i<timeValue.length/2; i++) {
            temp = [timeValue substringFromIndex:2*i];
            NSString * mac1 = [temp substringToIndex:2];
            NSInteger  macInt = [mac1 integerValue];
            NSString * realyMac = [self toHex:macInt];
            macString = [NSString stringWithFormat:@"%@:%@",macString,realyMac];
    }
    
    NSLog(@"%@",macString);
    return macString;

}
-(NSString *)toHex:(long int)tmpid
{
    NSString *nLetterValue;
    NSString *str = @"";
    long long int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:nLetterValue = [[NSString alloc]initWithFormat:@"%lli",ttmpig];
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    if (str.length<2) {
        str = [NSString stringWithFormat:@"%@0",str];
    }
    return str;
}

//return YES
-(BOOL)checkSupnodeAddress:(NSString *)strng{
    
    if (![strng isEqual:@""]||
        [strng rangeOfString:@":"].location != NSNotFound
        ) {
        NSArray * arr = [strng componentsSeparatedByString:@":"];
        if (arr.count == 2) {
            NSString * port = arr[1];
            if (port.length<1) {
                _superModeTFline.backgroundColor = [UIColor redColor];
                [self alertMessage:@"Supnode error!"];
                return NO;
            }
        }else{
            _superModeTFline.backgroundColor = [UIColor redColor];
            return NO;
        }
    }else{
        _superModeTFline.backgroundColor = [UIColor redColor];

        return NO;
    }
    return YES;
}

// IP 地址校验
-(BOOL)checkIpAddress:(NSString *)ipAddress {
    if (ipAddress != nil) {
        NSArray *arr = [ipAddress componentsSeparatedByString:@"."];
        if (arr.count != 4) {
            return NO;
        }
        for (int i = 0; i < arr.count; i++) {
            NSString *ipItem = arr[i];
            NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            if ([ipItem rangeOfCharacterFromSet:nonDigitCharacterSet].location != NSNotFound) {
                return NO; // 包含非数字字符
            }
            NSInteger temp = [ipItem integerValue];
            if ((temp < 0) || (temp > 255)) { // 校验范围 0-255
                return NO;
            }
        }
        return YES;
    } else {
        return NO;
    }
}


//校验netSmark address
-(BOOL)checkMark:(NSString *)ipAddress{
    if (ipAddress!= nil) {
        NSArray * arr = [ipAddress componentsSeparatedByString:@"."];
        if (arr.count != 4) {
            return NO;
        }
        for (int i = 0; i<arr.count; i++) {
            NSString * ipItem =  arr[i];
            NSInteger  temp = [ipItem integerValue];
            if (i == 0) {
                if (temp <1) {
                    return NO;
                }
            }
            if (temp >255) {
                return NO;
            }
        }
        return YES;
    }else{
        return NO;
    }
    return NO;
}

//mac 地址校验
-(BOOL)checkMacAddress:(NSString *)address{
    if (address) {
        NSString * macAdd =   @"^([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])$";
        NSPredicate * numberPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",macAdd];
        return [numberPre evaluateWithObject:address];
    }else{
        return NO;
    }
}
//弹框提示
-(void)alertMessage:(NSString * )message{
  
        UIAlertController * alertView = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

        [alertView addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self.navigationController presentViewController:alertView animated:YES completion:nil];
}
@end
