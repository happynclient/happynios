//
//  LocalData.h
//  HiN2N_demo
//
//  Created by noontec on 2021/8/18.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import "SettingModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^updateSuccessCallBack)(BOOL isSuccess);
typedef void(^insertSuccessCallBack)(BOOL isSuccess);

@interface LocalData : NSObject
@property(nonatomic,copy)updateSuccessCallBack updateCallback;
@property(nonatomic,copy)insertSuccessCallBack insertCallBack;

-(NSMutableArray *)searchLocalSettingLists;
-(FMDatabase *)getSettingListsDB;
-(NSInteger )searchDataByName:(NSString *)name;
-(void)updateLocaSettingLists:(SettingModel *)model;
-(void)insertLocalSettingLists:(SettingModel *)model;
-(BOOL)createTable:(FMDatabase *)fmdb;
-(void)deleteSettingListsByid:(NSInteger )id_key;
@end

NS_ASSUME_NONNULL_END
