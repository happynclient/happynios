//
//  ListsViewCell.m
//  HiN2N_demo
//
//  Created by noontec on 2021/8/19.
//

#import "ListsViewCell.h"

@implementation ListsViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.nextButton addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
    self.selectButton.userInteractionEnabled = NO;
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
