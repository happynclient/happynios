//
//  Hin2nTunnelManager.h
//  hin2n
//
//  Created by noontec on 2021/8/25.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import "SettingModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^backgroundStatus)(BOOL backgroundStatus);
typedef void(^tunnelConnectStatusCallback)(NEVPNStatus status);
@interface Hin2nTunnelManager : NSObject
@property(nonatomic,strong)NEPacketTunnelProvider * currentProvider;
@property(nonatomic,strong)NSString * testCode;
@property(nonatomic,copy)tunnelConnectStatusCallback tunnelStatus;
@property(nonatomic,copy)backgroundStatus background;

+ (instancetype)shareManager;

-(void)initTunnel:(SettingModel *)currentSettingModel;
-(int)TunnelStartResult;
-(void)stopTunnel;
-(int)startTunnel;
//-(void)setTunnelProvider:(NEPacketTunnelProvider *)provider;
-(int)setIpFromSupernode:(NSDictionary*)params;
-(void)stopLoadPlayback;
-(void)startLoadPlayback;
-(void)setServiceConnectStatus:(int)status;

int openVPN(void);
@end

NS_ASSUME_NONNULL_END
