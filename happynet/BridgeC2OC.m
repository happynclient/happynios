//
//  BridageC2OC.m
//  hin2n
//
//  Created by noontec on 2021/9/7.
//
#import <Foundation/Foundation.h>
#import "BridgeC2OC.h"
//#import "PacketTunnelEngine.h"
#import "MMWormhole.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeC2OC : NSObject

@end

NS_ASSUME_NONNULL_END

#import "BridgeC2OC.h"
#import "Hin2nTunnelManager.h"

@implementation BridgeC2OC

//启动Tunnel
int startTunnel(void){
int result = [[[BridgeC2OC alloc]init] startTunnelServer];
    return result;
}
-(int )startTunnelServer{
    NSLog(@"c_too_oc");
    return  [self callStart];
}

-(int)callStart{
  int re =  [[Hin2nTunnelManager shareManager] startTunnel];
  return re;
}

int setAddressFromSupernode(const char *ip , const char *subnetMark){
    NSString * ipAddrress = [NSString stringWithUTF8String:ip];
    NSString * subnetMarkString = [NSString stringWithUTF8String:subnetMark];
    NSDictionary * dic = @{@"ipAddress":ipAddrress,@"subnetMark":subnetMarkString};
    int re =  [[Hin2nTunnelManager shareManager] setIpFromSupernode:dic];
    return re;
}

void notifyConnectionStatus(connectStatus status){ //1,2,3,4
    [[Hin2nTunnelManager shareManager] setServiceConnectStatus:status];
}
void stopTunnel(void){
    [[Hin2nTunnelManager shareManager] stopTunnel];
}


//重新设置ip 并启动tunnel
-(int)setAddressFromSupernode:(NSDictionary *)params{
    return [[Hin2nTunnelManager shareManager] setIpFromSupernode:params];
}

@end
