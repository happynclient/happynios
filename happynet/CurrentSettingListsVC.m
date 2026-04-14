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
    self.view.backgroundColor = [UIColor whiteColor];
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
    
    UIView *footerView = [[UIView alloc] init];
    if (@available(iOS 13.0, *)) {
        footerView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    } else {
        footerView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
    }
    footerView.layer.cornerRadius = 8;
    [self.view addSubview:footerView];
    
    [footerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-20);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(75);
    }];

    UILabel *sloganLabel = [[UILabel alloc] init];
    [footerView addSubview:sloganLabel];
    sloganLabel.text = @"HAPPYN makes the internet simpler.";
    sloganLabel.font = [UIFont italicSystemFontOfSize:14];
    sloganLabel.textColor = [UIColor grayColor];
    if (@available(iOS 13.0, *)) {
        sloganLabel.textColor = [UIColor secondaryLabelColor];
    }
    sloganLabel.textAlignment = NSTextAlignmentCenter;

    [sloganLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(8);
        make.centerX.mas_equalTo(footerView.mas_centerX);
        make.height.mas_equalTo(20);
    }];

    UILabel *copyRightLabel = [[UILabel alloc] init];
    copyRightLabel.textColor = [UIColor grayColor];
    if (@available(iOS 13.0, *)) {
        copyRightLabel.textColor = [UIColor tertiaryLabelColor];
    }
    copyRightLabel.font = [UIFont systemFontOfSize:13];
    copyRightLabel.numberOfLines = 2;
    copyRightLabel.textAlignment = NSTextAlignmentCenter;
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion == nil) {
        appVersion = @"2.7";
    }
    copyRightLabel.text = [NSString stringWithFormat:@"Version %@ ©happyn.net\nBased on N2N Project", appVersion];
    
    [footerView addSubview:copyRightLabel];
    [copyRightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(sloganLabel.mas_bottom).offset(2);
        make.centerX.equalTo(footerView.mas_centerX);
        make.height.equalTo(@40);
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
