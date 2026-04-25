//
//  CurrentSettingListsVC.m
//  TNASN2N
//
//  Created by noontec on 2021/8/18.
//

#import "CurrentSettingListsVC.h"
#import "Masonry.h"
#import "LocalData.h"
#import "ListsViewCell.h"
#import "SettingVC.h"

@interface CurrentSettingListsVC ()

<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)UITableView * listView;
@property(nonatomic,strong)NSMutableArray * array;
@property(nonatomic,strong)SettingModel * currentModel;
//@property(nonatomic,assign)NSInteger  currentRow;

@end

@implementation CurrentSettingListsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _array = [NSMutableArray array];
    UIColor *bgColor = [UIColor colorWithRed:242/255.0 green:245/255.0 blue:250/255.0 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        bgColor = [UIColor systemGroupedBackgroundColor];
    }
    self.view.backgroundColor = bgColor;
//    _currentRow = -1;
    [self initUI];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self searchLocalSettingLists];

}

-(void)initUI{
    UIButton * leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 60, 44);
       [leftButton setImage:[UIImage imageNamed:@"back_blackColor"] forState:UIControlStateNormal];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 40);
       [leftButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
       self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftButton];
    
    UIColor *cardColor = [UIColor whiteColor];
    UIColor *titleColor = [UIColor blackColor];
    UIColor *subTitleColor = [UIColor grayColor];
    if (@available(iOS 13.0, *)) {
        cardColor = [UIColor secondarySystemGroupedBackgroundColor];
        titleColor = [UIColor labelColor];
        subTitleColor = [UIColor secondaryLabelColor];
    }

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
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"2.8";
    copyRightLabel.text = [NSString stringWithFormat:@"Version %@ © happyn.net | Based on N2N Project", appVersion];
    copyRightLabel.font = [UIFont systemFontOfSize:10];
    copyRightLabel.textColor = subTitleColor;
    [footerContentContainer addSubview:copyRightLabel];
    [copyRightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sloganLabel);
        make.bottom.equalTo(shieldIconBg).offset(-2);
        make.right.equalTo(footerContentContainer);
    }];

    _listView = [[UITableView alloc]init];
    [self.view addSubview:_listView];
    [_listView registerNib:[UINib nibWithNibName:@"ListsViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    [_listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(footerView.mas_top).offset(-10);
    }];
    _listView.delegate = self;
    _listView.dataSource = self;
    _listView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ListsViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    SettingModel * model = _array[indexPath.row];
    [cell setData:model];
   
    cell.next = ^{
        [self settinginfo:model];
    };

    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _array.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ListsViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.selectButton.selected = YES;
        SettingModel * data = _array[indexPath.row];
        if (self.settCallback) {
            self.settCallback(data);
        }
//    _currentRow = indexPath.row;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"currentSettingModel_row"];
    [userDefaults setInteger:data.id_key forKey:@"currentSettingModel_row"];
    [userDefaults synchronize];
    [tableView reloadData];
}
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
     return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
        if (editingStyle == UITableViewCellEditingStyleDelete)
        {
            // 删除数据
            SettingModel * model = _array[indexPath.row];
            [self deleteDataByid:model.id_key];
        }
}
#pragma mark //查询
-(void)searchLocalSettingLists{
    LocalData * db = [[LocalData alloc]init];
    NSMutableArray * arr =  [db searchLocalSettingLists];
    if (_array.count>0) {
        [_array removeAllObjects];
    }
    _array = arr;
    [_listView reloadData];
}

#pragma mark //shan
- (void)extracted {
    [self searchLocalSettingLists];
}

-(void)deleteDataByid:(NSInteger )id_key{
    LocalData * db = [[LocalData alloc]init];
    [db deleteSettingListsByid:id_key];
    
    [self extracted];
}

-(void)settinginfo:(SettingModel *)model{
    SettingVC * next = [[SettingVC alloc]init];
    next.model = model;
    next.isUpdate = YES;
    [self.navigationController pushViewController:next animated:YES];
}

-(void)back{
    if (self.settCallback) {
        if (_currentModel != nil) {
            self.settCallback(_currentModel);
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}
@end
