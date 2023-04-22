//
//  SettingVC.h
//  TNASN2N
//
//  Created by noontec on 2021/8/10.
//

#import <UIKit/UIKit.h>
#import "SettingModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SettingVC : UIViewController
@property(nonatomic,strong)NSDictionary * settingInfo;
@property(nonatomic,strong)SettingModel * model;
@property(nonatomic,assign)BOOL isUpdate;

@end

NS_ASSUME_NONNULL_END
