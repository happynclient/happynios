//
//  CurrentModelSetting.h
//  hin2n
//
//  Created by noontec on 2021/8/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CurrentModelSetting : NSObject
@property(nonatomic,copy)NSString    * name;
@property(nonatomic,copy)NSString    * supernode;
@property(nonatomic,copy)NSString    * community;
@property(nonatomic,copy)NSString    * encrypt;
@property(nonatomic,copy)NSString    * ipAddress;
@property(nonatomic,copy)NSString    * subnetMark;
@property(nonatomic,copy)NSString    * deviceDescription;
@property(nonatomic,copy)NSString    * supernode2;
@property(nonatomic,copy)NSString    * gateway;
@property(nonatomic,copy)NSString    * dns;
@property(nonatomic,copy)NSString    * mac;

@property(nonatomic,assign)NSInteger   mtu;
@property(nonatomic,assign)NSInteger   version;   //0-3
@property(nonatomic,assign)NSInteger   encryptionMethod;
@property(nonatomic,assign)NSInteger   port;
@property(nonatomic,assign)NSInteger   forwarding;
@property(nonatomic,assign)NSInteger   isAcceptMulticast;
@property(nonatomic,assign)NSInteger   level; //0-4  error,warning,normal,info,debug
@property(nonatomic,assign)NSInteger   id_key;  //数据库主键

+ (instancetype)shareCurrentModelSetting;
@end

NS_ASSUME_NONNULL_END
