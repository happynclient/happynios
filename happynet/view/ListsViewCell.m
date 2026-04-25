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
    
    [self.nextButton setTitle:@" 编辑配置" forState:UIControlStateNormal];
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
