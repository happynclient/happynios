//
//  SettingModel.h
//  HiN2N_demo
//
//  Created by noontec on 2021/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingModel : NSObject
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


/**
 name text NOT NULL,
 version text NOT NULL,i
 ssupernode int,
 supernode text,
 community text,
 encrypt_key text,ip text,
 subnet_mark text,
 devicedescription text,
 encryptionmethod int,
 supernode2 text,
 mtu int,
 port int,
 gatewayip text,
 dnsserverip text,
 macaddress text,
 forwarding int,
 acceptmulticastmac int,
 tracelevel int);
 
 @property(nonatomic,strong)UITextField * nameTF;

 @property(nonatomic,assign)NSInteger     method; //0-3 Twofish,AES-CBC,Chacha20,Speck-CTR

 @property(nonatomic,assign)BOOL        isEnablePacket;  // Enable packet forwarding default NO;
 @property(nonatomic,assign)BOOL        acceptMulticast; // Accept multicast mac address default NO;
 @property(nonatomic,assign)NSInteger   level; //0-4  error,warning,normal,info,debug

 //TF:TextField
 @property(nonatomic,strong)UITextField * superModeTF;
 @property(nonatomic,strong)UITextField * communityTF;
 @property(nonatomic,strong)UITextField * EncryptTF;
 @property(nonatomic,strong)UITextField * ipAddressTF;
 @property(nonatomic,strong)UITextField * subnetMarkTF;
 @property(nonatomic,strong)UITextField * deviceDescriptionTF;

 //More setting
 @property(nonatomic,strong)UITextField * supernode2;
 @property(nonatomic,strong)UITextField * mtuTF;
 @property(nonatomic,strong)UITextField * portTF;
 @property(nonatomic,strong)UITextField * gatewayTF;
 @property(nonatomic,strong)UITextField * DNSTF;
 @property(nonatomic,strong)UITextField * macAddressTF;
 

*/
@end

NS_ASSUME_NONNULL_END
