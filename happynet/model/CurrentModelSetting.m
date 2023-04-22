//
//  CurrentModelSetting.m
//  hin2n
//
//  Created by noontec on 2021/8/26.
//

#import "CurrentModelSetting.h"

@implementation CurrentModelSetting

+ (instancetype)shareCurrentModelSetting
{
    static CurrentModelSetting * setting = nil;
       static dispatch_once_t onceToken;
       dispatch_once(&onceToken, ^{
             // 要使用self来调用
           setting = [[self alloc] init];
       });
       return setting;
}
@end
