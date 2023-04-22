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


@property(nonatomic,assign)NSInteger    method; //0-3 Twofish,AES-CBC,Speck-CTR,Chacha20

@property(nonatomic,assign)BOOL         forwarding;  // Enable packet forwarding default NO;
@property(nonatomic,assign)BOOL         acceptMulticast; // Accept multicast mac address default NO;
@property(nonatomic,assign)NSInteger    level; //0-4  error,warning,normal,info,debug default 4

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

@end

@implementation SettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initUI];
    if (_isUpdate) {
        self.title = @"Update Setting";
        [self setDataFromListVC];
    }else{
        self.title = @"Setting";
        _level = 0;
        _version = 3;
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

-(void)initUI{

   _scrollView = [[UIScrollView alloc]init];
    _scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height+200);
    [self.view addSubview:_scrollView];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1150);
    _contextView = [[UIView alloc]initWithFrame:CGRectZero];
    
    [_scrollView addSubview:_contextView];
    _contextView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height+1150);

    UILabel * name = [[UILabel alloc]init];
    name.text = @"Setting name";
    
    name.font = [UIFont systemFontOfSize:14];
    name.textColor = [UIColor grayColor];
    [_contextView addSubview:name];
  
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(44);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(18);
    }];
    
    _nameTF = [[UITextField alloc]init];
    [_contextView addSubview:_nameTF];
    _nameTF.delegate = self;
    [_nameTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(name.mas_bottom);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    _nameTF.keyboardType  = UIKeyboardTypeDefault;
    _nameTF.placeholder  = @"name";
    _nameTF.returnKeyType = UIReturnKeyDone;
    if (@available(iOS 10.0, *)) {
        _nameTF.textContentType = @"userName";
    }
    UIView * line1 = [[UIView alloc]init];
    [_contextView addSubview:line1];
    line1.backgroundColor = [UIColor grayColor];
    [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_nameTF.mas_bottom).mas_offset(1);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(1);
    }];
    
    
    UIView * versionView = [[UIView alloc]init];
    [_contextView addSubview:versionView];
//    versionView.backgroundColor = [UIColor blueColor];
    [versionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(line1.mas_bottom).mas_offset(10);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(-50);
        make.height.mas_equalTo(75);
    }];
    
    UILabel * versionLabel = [[UILabel alloc]init];
    [versionView addSubview:versionLabel];
    versionLabel.text = @"N2N version";
    versionLabel.font = [UIFont systemFontOfSize:14];
    versionLabel.textColor = [UIColor grayColor];
    [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(5);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(20);
    }];
    _array = [NSMutableArray array];
    NSArray * arrayTitleText = @[@"v1",@"v2s",@"v2",@"v3"];
    for (int i = 0; i<4; i++) {
        UIButton * itemView = [UIButton buttonWithType:UIButtonTypeCustom];
        [versionView addSubview:itemView];
        itemView.layer.borderColor = [UIColor grayColor].CGColor;
        itemView.layer.cornerRadius = 3;
        itemView.layer.borderWidth = 1;
        itemView.tag = 30+i;
        [itemView addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];
        [itemView setTitle:arrayTitleText[i] forState:UIControlStateNormal];
        [itemView setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
        [itemView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [itemView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(30);
            make.height.mas_equalTo(34);
        }];
       
        if (_isUpdate) {
            _version = _model.version;
            if (_version == i) {
                itemView.selected = YES;
                itemView.layer.borderColor = [UIColor orangeColor].CGColor;
            }
        }else{
            if (i==3) {
                itemView.selected = YES;
                itemView.layer.borderColor = [UIColor orangeColor].CGColor;
                _version = 3;
            }
        }
        [_array addObject:itemView];
    }
    [_array mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:20 tailSpacing:10];
    
    
    UILabel * supernodeLabel = [[UILabel alloc]init];
    [_contextView addSubview:supernodeLabel];
    supernodeLabel.text = @"Supernode";
    supernodeLabel.textColor = [UIColor grayColor];
    supernodeLabel.font = [UIFont systemFontOfSize:13];
    [supernodeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(versionView.mas_bottom);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(20);
    }];
    _supernodeTF = [[UITextField alloc]init];
    [_contextView addSubview:_supernodeTF];
   
    [_supernodeTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(supernodeLabel.mas_bottom);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    _supernodeTF.placeholder = @"192.168.0.2";
    _supernodeTF.keyboardType  = UIKeyboardTypeDefault;
    _supernodeTF.delegate = self;
    _superModeTFline = [[UIView alloc]init];
    [_contextView addSubview:_superModeTFline];
    _superModeTFline.backgroundColor = [UIColor grayColor];
    [_superModeTFline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_supernodeTF.mas_bottom).mas_offset(1);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(1);
    }];
    
    UILabel * communityTitle = [[UILabel alloc]init];
    [_contextView addSubview:communityTitle];
    communityTitle.text = @"community";
    communityTitle.textColor = [UIColor grayColor];
    communityTitle.font = [UIFont systemFontOfSize:13];
    [communityTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_supernodeTF.mas_bottom).mas_offset(5);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(20);
    }];
    _communityTF = [[UITextField alloc]init];
    _communityTF.delegate = self;
    [_contextView addSubview:_communityTF];
    _communityTF.keyboardType  = UIKeyboardTypeDefault;

    [_communityTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(communityTitle.mas_bottom);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    _communityTF.placeholder = @"community";
    
    _communityTFline = [[UIView alloc]init];
    [_contextView addSubview:_communityTFline];
    _communityTFline.backgroundColor = [UIColor grayColor];
    [_communityTFline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_communityTF.mas_bottom).mas_offset(1);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(1);
    }];
    
    _EncryptTF = [[UITextField alloc]init];
    [_contextView addSubview:_EncryptTF];
    _EncryptTF.delegate = self;
    _EncryptTF.keyboardType  = UIKeyboardTypeDefault;

    [_EncryptTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_communityTF.mas_bottom);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    _EncryptTF.placeholder = @"Encrypt Key";
    _EncryptTF.textColor = [UIColor grayColor];
    _EncryptTF.font = [UIFont systemFontOfSize:13];
    UIView * EncryptTFline = [[UIView alloc]init];
    [_contextView addSubview:EncryptTFline];
    EncryptTFline.backgroundColor = [UIColor grayColor];
    [EncryptTFline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_EncryptTF.mas_bottom).mas_offset(1);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(1);
    }];
    
    _getSuperModelIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    [_contextView addSubview:_getSuperModelIcon];
    [_getSuperModelIcon setImage:[UIImage imageNamed:@"buttom_unselect"] forState:UIControlStateNormal];
    [_getSuperModelIcon setImage:[UIImage imageNamed:@"buttom_select"] forState:UIControlStateSelected];
    [_getSuperModelIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_EncryptTF.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
    [_getSuperModelIcon addTarget:self action:@selector(getSuperModel:) forControlEvents:UIControlEventTouchUpInside];
    _getSuperModelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_contextView addSubview:_getSuperModelButton];
    [_getSuperModelButton setTitle:@"Get IP from supernode" forState:UIControlStateNormal];
    [_getSuperModelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _getSuperModelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_getSuperModelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_EncryptTF.mas_bottom).offset(10);
        make.left.mas_equalTo(_getSuperModelIcon.mas_right);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(34);
    }];
        
//    UILabel * deviceDescription = [[UILabel alloc]init];
//    [_contextView addSubview:deviceDescription];
//    deviceDescription.text = @"Device Description";
//    deviceDescription.textColor = [UIColor grayColor];
//    deviceDescription.font = [UIFont systemFontOfSize:13];
//    [deviceDescription mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(getSuperModelButton.mas_bottom).offset(10);
//        make.left.mas_equalTo(20);
//        make.right.mas_equalTo(-20);
//        make.height.mas_equalTo(24);
//    }];
//
    _supernodeView = [[UIView alloc]init];
    [_contextView addSubview:_supernodeView];
    [_supernodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_getSuperModelButton.mas_bottom).offset(10);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(90);
    }];
    
    _ipAddressTF = [[UITextField alloc]init];
    [_supernodeView addSubview:_ipAddressTF];
    _ipAddressTF.delegate = self;
    _ipAddressTF.keyboardType  = UIKeyboardTypeDecimalPad;

    _ipAddressTF.placeholder = @"ip address";
    [_ipAddressTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_getSuperModelButton.mas_bottom).offset(10);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    
    _ipAddressTFline = [[UIView alloc]init];
    [_supernodeView addSubview:_ipAddressTFline];
    _ipAddressTFline.backgroundColor = [UIColor grayColor];
    [_ipAddressTFline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_ipAddressTF.mas_bottom).mas_offset(1);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(1);
    }];
    
    
    _subnetMarkTF = [[UITextField alloc]init];
    [_supernodeView addSubview:_subnetMarkTF];
    _subnetMarkTF.delegate = self;
    _subnetMarkTF.keyboardType  = UIKeyboardTypeDecimalPad;

    _subnetMarkTF.placeholder = @"Subnet Mark";
    [_subnetMarkTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_ipAddressTFline.mas_bottom).offset(10);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    
    _subnetMarkTFLine = [[UIView alloc]init];
    [_supernodeView addSubview:_subnetMarkTFLine];
    _subnetMarkTFLine.backgroundColor = [UIColor grayColor];
    
    [_subnetMarkTFLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_subnetMarkTF.mas_bottom).mas_offset(1);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(1);
    }];
    
    
    _deviceDescriptionTF = [[UITextField alloc]init];
    [_contextView addSubview:_deviceDescriptionTF];
    _deviceDescriptionTF.delegate = self;
    _deviceDescriptionTF.keyboardType  = UIKeyboardTypeDefault;

    _deviceDescriptionTF.placeholder = @"Device Description";
    [_deviceDescriptionTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_supernodeView.mas_bottom).offset(10);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    
    UIView * deviceDescriptionTFLine = [[UIView alloc]init];
    [_contextView addSubview:deviceDescriptionTFLine];
    deviceDescriptionTFLine.backgroundColor = [UIColor grayColor];
    [deviceDescriptionTFLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_deviceDescriptionTF.mas_bottom).mas_offset(1);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(1);
    }];
    
    
    UIButton * moreSettingIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    [_contextView addSubview:moreSettingIcon];
    [moreSettingIcon setImage:[UIImage imageNamed:@"buttom_unselect"] forState:UIControlStateNormal];
    [moreSettingIcon setImage:[UIImage imageNamed:@"buttom_select"] forState:UIControlStateSelected];
    [moreSettingIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_deviceDescriptionTF.mas_bottom).offset(20);
        make.left.mas_equalTo(10);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(34);
    }];
    [moreSettingIcon addTarget:self action:@selector(moreSettingIcon:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _moreSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_contextView addSubview:_moreSettingButton];
//    [_moreSettingButton addTarget:self action:@selector(moreSetting:) forControlEvents:UIControlEventTouchUpInside];
    [_moreSettingButton setTitle:@"more setting" forState:UIControlStateNormal];
    [_moreSettingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _moreSettingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_moreSettingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_deviceDescriptionTF.mas_bottom).offset(20);
        make.left.mas_equalTo(moreSettingIcon.mas_right);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(34);
    }];
    
    _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_contextView addSubview:_saveButton];
    [_saveButton addTarget:self action:@selector(saveSettingData:) forControlEvents:UIControlEventTouchUpInside];
    [_saveButton setTitle:@"Save" forState:UIControlStateNormal];
    
    [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(_moreSettingButton.mas_bottom).offset(60);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
    _saveButton.backgroundColor = [UIColor colorWithRed:26/255.0 green:126/255.0  blue:240/255.0  alpha:1];
    _saveButton.layer.cornerRadius = 5;

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
    
    UILabel * encryptionLabel = [[UILabel alloc]init];
    [_moreView addSubview:encryptionLabel];
    encryptionLabel.text = @"Encryption method";
    encryptionLabel.textColor = [UIColor lightGrayColor];
    encryptionLabel.font = [UIFont systemFontOfSize:14];
    [encryptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_moreView.mas_top).offset(5);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(20);
    }];
    
    _selectMethodButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreView addSubview:_selectMethodButton];
    if (_isUpdate) {
        [self setSelectMethodButtonTitle];
    }else{
       [_selectMethodButton setTitle:@"Twofish" forState:UIControlStateNormal];
    }
    [_selectMethodButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _selectMethodButton.contentHorizontalAlignment =UIControlContentHorizontalAlignmentLeft;
    [_selectMethodButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(encryptionLabel.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-100);
        make.height.mas_equalTo(40);
    }];
    [_selectMethodButton addTarget:self action:@selector(selectMethod) forControlEvents:UIControlEventTouchUpInside];
    
    
    _supernode2 = [[UITextField alloc]init];
    [_moreView addSubview:_supernode2];
    _supernode2.delegate = self;
    _supernode2.placeholder = @"Supernode2";
    [_supernode2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_selectMethodButton.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(44);
    }];
    UIView * supernode2Line = [[UIView alloc]init];
    [_moreView addSubview:supernode2Line];
    supernode2Line.backgroundColor = [UIColor grayColor];
    [supernode2Line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_supernode2.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(1);
    }];
    
    
    UILabel * mtuLabel = [[UILabel alloc]init];
    [_moreView addSubview:mtuLabel];
    mtuLabel.textColor = [UIColor lightGrayColor];
    mtuLabel.font = [UIFont systemFontOfSize:14];
    mtuLabel.text = @"MTU";
    [mtuLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(supernode2Line.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(20);
    }];
    
    _mtuTF = [[UITextField alloc]init];
    [_moreView addSubview:_mtuTF];
    _mtuTF.delegate = self;
    _mtuTF.placeholder = @"1386";
    _mtuTF.keyboardType = UIKeyboardTypeNumberPad;
    [_mtuTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(mtuLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(44);
    }];
    
    UIView * mtuTFLine = [[UIView alloc]init];
    [_moreView addSubview:mtuTFLine];
    mtuTFLine.backgroundColor = [UIColor grayColor];
    [mtuTFLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_mtuTF.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(1);
    }];

    UILabel * portLabel = [[UILabel alloc]init];
    [_moreView addSubview:portLabel];
    portLabel.textColor = [UIColor lightGrayColor];
    portLabel.font = [UIFont systemFontOfSize:14];
    portLabel.text = @"Port";
    [portLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(mtuTFLine.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(20);
    }];

    _portTF = [[UITextField alloc]init];
    [_moreView addSubview:_portTF];
    _portTF.delegate = self;
    _portTF.placeholder = @"0";
    _portTF.keyboardType = UIKeyboardTypeNumberPad;
    [_portTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(portLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(44);
    }];
    UIView * portTFLine = [[UIView alloc]init];
    [_moreView addSubview:portTFLine];
    portTFLine.backgroundColor = [UIColor grayColor];
    [portTFLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_portTF.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(1);
    }];

    _gatewayTF = [[UITextField alloc]init];
    [_moreView addSubview:_gatewayTF];
    _gatewayTF.delegate = self;
    _gatewayTF.keyboardType = UIKeyboardTypeDecimalPad;
    _gatewayTF.placeholder = @"gateway ip address";
    [_gatewayTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(portTFLine.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(44);
    }];
    
    UIView * gatewayTFLine = [[UIView alloc]init];
    [_moreView addSubview:gatewayTFLine];
    gatewayTFLine.backgroundColor = [UIColor grayColor];
    [gatewayTFLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_gatewayTF.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(1);
    }];
    
    
    _DNSTF = [[UITextField alloc]init];
    [_moreView addSubview:_DNSTF];
    _DNSTF.delegate = self;
    _DNSTF.keyboardType = UIKeyboardTypeDecimalPad;
    _DNSTF.placeholder = @"DNS server ip address";
    [_DNSTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(gatewayTFLine.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(44);
    }];
    
    UIView * DNSTFLine = [[UIView alloc]init];
    [_moreView addSubview:DNSTFLine];
    DNSTFLine.backgroundColor = [UIColor grayColor];
    [DNSTFLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_DNSTF.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(1);
    }];
    
    UILabel * macLabel = [[UILabel alloc]init];
    [_moreView addSubview:macLabel];
    macLabel.textColor = [UIColor lightGrayColor];
    macLabel.text = @"Mac  address";
//    macLabel.backgroundColor = [UIColor blueColor];
    [macLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(DNSTFLine.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(20);
    }];
    
   _macAddressTF = [[UITextField alloc]init];
    [_moreView addSubview:_macAddressTF];
    _macAddressTF.delegate  = self;
    _macAddressTF.placeholder = @"Mac  ";
    [_macAddressTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(macLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-100);
        make.height.mas_equalTo(44);
    }];

    UIButton * getMacButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreView addSubview:getMacButton];
    [getMacButton setTitle:@"Refresh" forState:UIControlStateNormal];
    [getMacButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    getMacButton.layer.cornerRadius = 4;
    getMacButton.backgroundColor = [UIColor colorWithRed:26/255.0 green:126/255.0  blue:240/255.0  alpha:1];
    [getMacButton addTarget:self action:@selector(refreshMac:) forControlEvents:UIControlEventTouchUpInside];
    [getMacButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(macLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(_macAddressTF.mas_right);
        make.right.mas_equalTo(-15);
        make.height.mas_equalTo(40);
    }];
    
    _macLine = [[UIView alloc]init];
    [_moreView addSubview:_macLine];
    _macLine.backgroundColor = [UIColor grayColor];
    [_macLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_macAddressTF.mas_bottom);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(1);
    }];
    
    
    UIButton * forwardingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreView addSubview:forwardingButton];
    [forwardingButton setImage:[UIImage imageNamed:@"buttom_unselect"] forState:UIControlStateNormal];
    [forwardingButton setImage:[UIImage imageNamed:@"buttom_select"] forState:UIControlStateSelected];
    [forwardingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_macLine.mas_bottom).offset(20);
        make.left.mas_equalTo(10);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
    [forwardingButton addTarget:self action:@selector(forwardingButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel * forwardLabel = [[UILabel alloc]init];
    [_moreView addSubview:forwardLabel];
    forwardLabel.text = @"Enable packet forwarding";
    forwardLabel.textColor = [UIColor lightGrayColor];
    forwardLabel.font = [UIFont systemFontOfSize:14];
    [forwardLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(forwardingButton.mas_top);
        make.left.mas_equalTo(forwardingButton.mas_right);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(30);
    }];


    UIButton * acceptMulticastButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreView addSubview:acceptMulticastButton];
    [acceptMulticastButton setImage:[UIImage imageNamed:@"buttom_unselect"] forState:UIControlStateNormal];
    [acceptMulticastButton setImage:[UIImage imageNamed:@"buttom_select"] forState:UIControlStateSelected];
    [acceptMulticastButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(forwardingButton.mas_bottom).offset(20);
        make.left.mas_equalTo(10);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
    [acceptMulticastButton addTarget:self action:@selector(acceptMulticast:) forControlEvents:UIControlEventTouchUpInside];

    
    UILabel * acceptMulticastLabel = [[UILabel alloc]init];
    [_moreView addSubview:acceptMulticastLabel];
    acceptMulticastLabel.text = @"Accept multicast Mac address";
    acceptMulticastLabel.textColor = [UIColor lightGrayColor];
    acceptMulticastLabel.font = [UIFont systemFontOfSize:14];
    [acceptMulticastLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(acceptMulticastButton.mas_top);
        make.left.mas_equalTo(acceptMulticastButton.mas_right);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(30);
    }];
    
    UILabel * traceLabel = [[UILabel alloc]init];
    [_moreView addSubview:traceLabel];
    traceLabel.text = @"Trace level:";
    traceLabel.textColor = [UIColor lightGrayColor];
    traceLabel.font = [UIFont systemFontOfSize:14];
//    traceLabel.backgroundColor = [UIColor orangeColor];
    [traceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(acceptMulticastLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(30);
    }];
    _selectLevelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreView addSubview:_selectLevelButton];
    if (_isUpdate) {
        [self setlevelButtonTitle];
    }else{
        [_selectLevelButton setTitle:@"NORMAL" forState:UIControlStateNormal];
    }
    _selectLevelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _selectLevelButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [_selectLevelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_selectLevelButton addTarget:self action:@selector(alertLevelView) forControlEvents:UIControlEventTouchUpInside];
    [_selectLevelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(traceLabel.mas_top);
        make.left.mas_equalTo(traceLabel.mas_right);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(30);
    }];
    
    [_saveButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(traceLabel.mas_bottom).offset(20);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(44);
    }];
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
            [self alertMessage:@"Supnode is error"];
        return;
        }
    }
    if (_communityTF.text == nil ||
        _communityTF.text.length <1 ||
        [_communityTF.text isEqual:@""]){
        [self alertMessage:@"Community is error"];
        _communityTFline.backgroundColor = [UIColor redColor];
        return;
    }
    if (_deviceDescriptionTF.text == nil||      _deviceDescriptionTF.text.length <1||
        [_deviceDescriptionTF.text isEqual:@""]){
        [self alertMessage:@"Description is error"];
        return;
    }
    if (_macAddressTF.text != nil){
        if (![self checkMacAddress:_macAddressTF.text]) {
            [self alertMessage:@"MAC Address is error!"];
            _macLine.backgroundColor = [UIColor redColor];
            return;
        };
        }
    if (_getSuperModelIcon.selected == NO) {
        if (![self checkIpAddress:_ipAddressTF.text]) {
            [self alertMessage:@"IP address is error"];
            return;
        };
        if (![self checkMark:_subnetMarkTF.text]) {
            [self alertMessage:@"subnetMark is error"];
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
    model.isAcceptMulticast = 1;
    model.forwarding = 1;
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
    NSArray * itemTextArray = @[@"Twofish",@"AES-CBC",@"Speck-CRT",@"ChaCha20"];
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
        alertLevelView.frame = CGRectMake(self.view.frame.size.width-220, self.view.frame.size.height-250, 200, 250);
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
    if (button.selected) {
        _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1800);
        [self moreSetting: _moreSettingButton];
    }else{
        [self cancelMoreView];
        _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1150);
    }
    [self setlevelButtonTitle];
    
    if ([[_model.mac class] isEqual:[NSNull class]] ||_model.mac.length <5 ) {
        self.macAddressTF.text = [self getMac];
    }else{
        self.macAddressTF.text = _model.mac;
    }
}

-(void)cancelMoreView{
    [_moreView removeFromSuperview];
    _moreView = nil;
}
-(void)getSuperModel:(UIButton *)button
{
    _getSuperModelIcon.selected = !button.selected;
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
        alertLevelView.frame = CGRectMake(self.view.frame.size.width-220, self.view.frame.size.height-250, 200, 250);
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
            levelName = @"Twofish";
            break;
        case 1:
            levelName = @"AES-CBC";
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

//ip 地址 校验
-(BOOL)checkIpAddress:(NSString *)ipAddress{
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
            if (temp >254) {
                return NO;
            }
        }
        return YES;
    
    }else{
        return NO;
    }
    return NO;
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
