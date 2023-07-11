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

//c 传来的packet 写进tunnel
int writePacketIntoTunnel(char data[], int length){
//  NSString * str = [NSString stringWithFormat:@"%s",data];
    
    NSData * d = [[NSData alloc] initWithBytes:data length:length];
    if (d == nil) {
        return -1;
    }
    NSDictionary * dic = @{@"value":d};
    NSArray * arr = @[dic];
    [[[BridgeC2OC alloc]init] writePacketIntoTunnel:arr];
    return length;
}

-(int)writePacketIntoTunnel:(NSArray * )dataArray{
    MMWormhole * hole = [[MMWormhole alloc]initWithApplicationGroupIdentifier:@"group.net.happyn.happynios.happynet" optionalDirectory:@"n2n"];
    [hole passMessageObject:@{@"packets" : dataArray} identifier:@"writePacket"];
    return [[Hin2nTunnelManager shareManager] writePackets:dataArray];
}

//重新设置ip 并启动tunnel
-(int)setAddressFromSupernode:(NSDictionary *)params{
    return [[Hin2nTunnelManager shareManager] setIpFromSupernode:params];
}

@end
