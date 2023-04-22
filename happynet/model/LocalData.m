//
//  LocalData.m
//  HiN2N_demo
//
//  Created by noontec on 2021/8/18.
//

#import "LocalData.h"
#import <UIKit/UIKit.h>
@implementation LocalData

#pragma mark //查询已备份的数据
#pragma mark //查询已备份的数据
-(NSMutableArray *)searchLocalSettingLists{
    
    FMDatabase * fmdb = [self getSettingListsDB];

    if ([fmdb open]) {
      [fmdb beginTransaction];
      NSMutableArray * arr = [NSMutableArray array];
          //查询整个表
      FMResultSet * resultSet = [fmdb executeQuery:@"select * from t_setting_lists"];
      while ([resultSet next]) {
          SettingModel * model = [[SettingModel alloc]init];
          model.id_key = [[resultSet objectForColumn:@"id"] integerValue];
          model.name = [resultSet objectForColumn:@"name"];
          model.supernode = [resultSet objectForColumn:@"supernode"];
          model.community = [resultSet objectForColumn:@"community"];
          model.encrypt = [resultSet objectForColumn:@"encrypt_key"];
          model.ipAddress = [resultSet objectForColumn:@"ip"];
          model.supernode2 = [resultSet objectForColumn:@"supernode2"];
          model.subnetMark = [resultSet objectForColumn:@"subnet_mark"];
          model.deviceDescription = [resultSet objectForColumn:@"devicedescription"];
          model.subnetMark = [resultSet objectForColumn:@"subnet_mark"];
          model.gateway = [resultSet objectForColumn:@"gatewayip"];
          model.dns = [resultSet objectForColumn:@"gatewayip"];
          model.mac = [resultSet objectForColumn:@"macaddress"];
          NSNumber  * version = [resultSet objectForColumn:@"version"];
          if (![version isEqual:[NSNull class]]) {
              model.version = [version integerValue];
          }
          NSNumber  * port = [resultSet objectForColumn:@"port"];
          if (![port isEqual:[NSNull class]]) {
              model.port = [port integerValue];
          }
          
          NSNumber * mtu = [resultSet objectForColumn:@"mtu"];
          if (![mtu isEqual:[NSNull class]] || mtu != NULL ) {
              model.mtu = [mtu integerValue];
          }
          NSNumber * encryptionMethod = [resultSet objectForColumn:@"encryptionMethod"];
          if (![encryptionMethod isEqual:[NSNull class]]) {
              model.encryptionMethod = [encryptionMethod integerValue];
          }
          NSNumber * forwarding = [resultSet objectForColumn:@"forwarding"];
          if (![forwarding isEqual:[NSNull class]] || forwarding!= NULL) {
              model.forwarding = [forwarding integerValue];
          }
          NSNumber * level = [resultSet objectForColumn:@"tracelevel"];
          if (![level isEqual:[NSNull class]] ||level!= NULL ) {
              model.level = [level integerValue];
          }
          NSNumber * isAcceptMulticast = [resultSet objectForColumn:@"acceptmulticastmac"];
          if (![isAcceptMulticast isEqual:[NSNull class]] || isAcceptMulticast != NULL) {
              model.isAcceptMulticast = [isAcceptMulticast integerValue];
          }

         [arr addObject:model];
          }
        
        return arr;
    }else{
        NSLog(@"数据库打开失败");
        return nil;
    }
    return nil;
}

#pragma mark //建数据库
-(FMDatabase *)getSettingListsDB{
    
    NSString * docPath = [[NSString alloc]init];
       docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//获取本地存放路径
   
    NSString * DBName = @"setting_lists.db";
    NSString * fileName = [docPath stringByAppendingPathComponent:DBName];//设置数据库名称
    FMDatabase * fmdb = [FMDatabase databaseWithPath:fileName];//创建并获取数据库信息
    [fmdb open];
    return fmdb;
}

#pragma mark //表插入数据
-(void)insertLocalSettingLists:(SettingModel *)model {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_async(group, queue, ^{
         NSString * docPath = [[NSString alloc]init];
            docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//获取本地存放路径
         
         NSString * DBName = @"setting_lists.db";
         NSString * filePath = [docPath stringByAppendingPathComponent:DBName];//设置数据库名称
         FMDatabaseQueue * queue = [FMDatabaseQueue databaseQueueWithPath:filePath];
         [queue inDatabase:^(FMDatabase *db) {
            [db traceExecution];
             NSNumber * version =  [NSNumber numberWithLong:model.version];
             NSNumber * mtu =  [NSNumber numberWithLong:model.mtu];
             NSNumber * level =  [NSNumber numberWithLong:model.level];
             NSNumber * port =  [NSNumber numberWithLong:model.port];
             NSNumber * forwarding =  [NSNumber numberWithLong:model.forwarding];
             NSNumber * isAcceptMulticast =  [NSNumber numberWithLong:model.isAcceptMulticast];
             NSNumber * encryptionMethod =  [NSNumber numberWithLong:model.encryptionMethod];

             BOOL results = [db executeUpdate:@"INSERT INTO t_setting_lists (name,version,supernode,port,forwarding,acceptmulticastmac,mtu,tracelevel,community,encrypt_key,ip,subnet_mark,devicedescription,encryptionMethod,supernode2,gatewayip,dnsserverip,macaddress) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",model.name,version ,model.supernode,port,forwarding,isAcceptMulticast,mtu,level,model.community,model.encrypt,model.ipAddress,model.subnetMark,model.deviceDescription,encryptionMethod,model.supernode2,model.gateway,model.dns,model.mac];
             
             if (results) {
//                 int row = db.lastInsertRowId;
                 NSLog(@"%@===========数据插入成功",model.name);
                 [db close];
                 if (self.insertCallBack) {
                     self.insertCallBack(YES);
                 }
             }else{
                 if (self.insertCallBack) {
                     self.insertCallBack(NO);
                 }
             }
         }
         ];
    });
}
-(void)updateLocaSettingLists:(SettingModel *)model{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    BOOL __block result = NO;
    dispatch_group_async(group, queue, ^{
         NSString * docPath = [[NSString alloc]init];
            docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//获取本地存放路径

         NSString * DBName = @"setting_lists.db";
         NSString * filePath = [docPath stringByAppendingPathComponent:DBName];//设置数据库名称
         FMDatabaseQueue * queue = [FMDatabaseQueue databaseQueueWithPath:filePath];

         [queue inDatabase:^(FMDatabase *db) {
             [db traceExecution];
             NSNumber * version =  [NSNumber numberWithLong:model.version];
             NSNumber * mtu =  [NSNumber numberWithLong:model.mtu];
             NSNumber * level =  [NSNumber numberWithLong:model.level];
             NSNumber * port =  [NSNumber numberWithLong:model.port];
             NSNumber * forwarding =  [NSNumber numberWithLong:model.forwarding];
             NSNumber * isAcceptMulticast =  [NSNumber numberWithLong:model.isAcceptMulticast];
             NSNumber * encryptionMethod =  [NSNumber numberWithLong:model.encryptionMethod];
             NSNumber * id_key =  [NSNumber numberWithLong:model.id_key];
//
             NSString * sql = @"update t_setting_lists set name = ?,version = ?,supernode = ?,port = ?,forwarding = ?,acceptmulticastmac = ?,mtu = ?,tracelevel = ?,community = ?,encrypt_key = ?,ip = ?,subnet_mark = ?,devicedescription = ?,encryptionMethod = ?,supernode2 = ?,gatewayip = ?,dnsserverip = ?,macaddress = ? where id = ?";

             BOOL results = [db executeUpdate:sql,model.name,version,model.supernode,port,forwarding,isAcceptMulticast,mtu,level,model.community,model.encrypt,model.ipAddress,model.subnetMark,model.deviceDescription,encryptionMethod,model.supernode2,model.gateway,model.dns,model.mac,id_key];

             if (results) {
                NSLog(@"%@=========== 修改成功",model.name);
                [db close];
                 if (self.updateCallback) {
                     self.updateCallback(YES);
                 }
             }else{
                 if (self.updateCallback) {
                self.updateCallback(NO);
             } }
             
             }
         ];
    });

}

-(BOOL)createTable:(FMDatabase *)fmdb{
//   BOOL executeUpdate = [fmdb executeUpdate:@"CREATE TABLE IF NOT EXISTS t_setting_lists (id integer PRIMARY KEY AUTOINCREMENT, name text NOT NULL,version text NOT NULL);"];
    [fmdb open];
    BOOL executeUpdate = [fmdb executeUpdate:@"CREATE TABLE IF NOT EXISTS t_setting_lists (id integer PRIMARY KEY AUTOINCREMENT, name text,version long,supernode text,community text,encrypt_key text,ip text, subnet_mark text,devicedescription text,encryptionmethod integer,supernode2 text,mtu integer,port integer,gatewayip text,dnsserverip text,macaddress text,forwarding integer,acceptmulticastmac integer,tracelevel integer);"];
   return executeUpdate;
 }

#pragma mark //按名称删除某条数据
-(void)deleteSettingListsByid:(NSInteger )id_key{
    NSNumber * id_key_number = [NSNumber numberWithInteger:id_key];
    FMDatabase * db = [self getSettingListsDB];
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"DELETE FROM t_setting_lists WHERE id = ?"];
        BOOL isDeleted = [db executeUpdate:sql,id_key_number];
        NSLog(@"%d",isDeleted);
    }

//    NSMutableArray * arr = [self searchLocalSettingLists];
    [db close];
}
-(NSInteger )searchDataByName:(NSString *)name{
    FMDatabase * fmdb = [self getSettingListsDB];
    if ([fmdb open]) {
      [fmdb beginTransaction];
          //查询整个表
      FMResultSet * resultSet = [fmdb executeQuery:@"select * from t_setting_lists where name = ?",name];
        while ([resultSet next]) {
            NSInteger key_id = [[resultSet objectForColumn:@"id"] integerValue];
            [fmdb close];
            return key_id;
        }
    }
    return -1;
}

@end
