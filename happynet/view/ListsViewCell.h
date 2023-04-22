//
//  ListsViewCell.h
//  HiN2N_demo
//
//  Created by noontec on 2021/8/19.
//

#import <UIKit/UIKit.h>
#import "SettingModel.h"

NS_ASSUME_NONNULL_BEGIN
//typedef void(^selectCell)(void);
typedef void(^next)(void);

@interface ListsViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *settingName;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property(nonatomic,copy)next  next;
-(void)setData:(SettingModel *)model;
//@property(nonatomic,copy)selectCell  select;

@end

NS_ASSUME_NONNULL_END
