//
//  ListsViewCell.m
//  HiN2N_demo
//
//  Created by noontec on 2021/8/19.
//

#import "ListsViewCell.h"
#import "Masonry.h"

@implementation ListsViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.nextButton addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
    self.selectButton.userInteractionEnabled = NO;
    
    // Beautify nextButton
    self.nextButton.backgroundColor = [UIColor colorWithRed:26/255.0 green:126/255.0 blue:240/255.0 alpha:0.1];
    self.nextButton.layer.cornerRadius = 14;
    self.nextButton.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 8);
    
    [self.nextButton setTitle:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Edit Config", nil)] forState:UIControlStateNormal];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.nextButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    
    if (@available(iOS 13.0, *)) {
        UIImage *chevron = [UIImage systemImageNamed:@"chevron.right.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium]];
        [self.nextButton setImage:chevron forState:UIControlStateNormal];
        self.nextButton.tintColor = [UIColor systemBlueColor];
        
        // Flip image to right side
        self.nextButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        
        // Add spacing between text and icon
        self.nextButton.imageEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
        self.nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
    }

    [self.nextButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.centerY.mas_equalTo(self.contentView);
        make.height.mas_equalTo(28);
        make.width.mas_greaterThanOrEqualTo(95);
    }];
    
    // Create and setup deleteButton
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.contentView addSubview:self.deleteButton];
    [self.deleteButton addTarget:self action:@selector(deleteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.deleteButton.backgroundColor = [UIColor colorWithRed:255/255.0 green:59/255.0 blue:48/255.0 alpha:0.1];
    self.deleteButton.layer.cornerRadius = 14;
    self.deleteButton.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 8);
    
    [self.deleteButton setTitle:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Delete Config", nil)] forState:UIControlStateNormal];
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [self.deleteButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    
    if (@available(iOS 13.0, *)) {
        UIImage *trash = [UIImage systemImageNamed:@"trash.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium]];
        [self.deleteButton setImage:trash forState:UIControlStateNormal];
        self.deleteButton.tintColor = [UIColor systemRedColor];
        
        // Flip image to right side
        self.deleteButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        
        // Add spacing between text and icon
        self.deleteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
        self.deleteButton.titleEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
    }
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.nextButton.mas_left).offset(-10);
        make.centerY.mas_equalTo(self.contentView);
        make.height.mas_equalTo(28);
        make.width.mas_greaterThanOrEqualTo(95);
    }];
}

-(void)deleteBtnClick:(UIButton *)btn{
    if (self.deleteSetting) {
        self.deleteSetting();
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}
-(void)setData:(SettingModel *)model{
    self.settingName.text = model.name;

    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger currentRow = [userDefaults integerForKey:@"currentSettingModel_row"];
    if (model.id_key == currentRow) {
        self.selectButton.selected = YES;
    }else{
        self.selectButton.selected = NO;
    }
}
-(void)next:(UIButton *)next{
    if (self.next) {
        self.next();
    }
}
//-(void)select:(UIButton *)next{
//    if (self.select) {
//        self.selectButton.selected = !next.selected;
//        self.select();
//    }
//}
@end
