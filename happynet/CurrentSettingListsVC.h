//
//  CurrentSettingListsVC.h
//  TNASN2N
//
//  Created by noontec on 2021/8/18.
//

#import <UIKit/UIKit.h>
#import "SettingModel.h"
NS_ASSUME_NONNULL_BEGIN
typedef void(^settingName)(SettingModel *callbackData);
@interface CurrentSettingListsVC : UIViewController
@property(nonatomic,copy)settingName  settCallback;
@end

NS_ASSUME_NONNULL_END
