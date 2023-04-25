//
//  PacketTunnelProvider.m
//  Tunnel
//
//  Created by noontec on 2021/8/25.
//
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

#import "PacketTunnelProvider.h"
#import "SettingModel.h"
#import "CurrentModelSetting.h"
//#import "PacketTunnelEngine.h"
#import "Hin2nTunnelManager.h"
#import <Foundation/Foundation.h>
#import "MMWormhole.h"
#import "MMWormholeSession.h"

@implementation PacketTunnelProvider
{ NETunnelProviderManager * tunnelManager;
    
   MMWormhole * traditionalWormhole;
   MMWormhole * watchConnectivityWormhole;
   MMWormholeSession * watchConnectivityListeningWormhole;
   MMWormhole * hole;
    NWUDPSession * udpSession;
}
static id obj;
- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    NSString * remoteAdd = [self queryIpWithDomain:options[@"remoteAddress"]];
    NEPacketTunnelNetworkSettings * settings = [[NEPacketTunnelNetworkSettings alloc]initWithTunnelRemoteAddress:remoteAdd];

    NSLog(@"%@",options);

    NSString * ip = options[@"ip"];
    
    NSString * subnetMarks = options[@"subnetMark"];
    NEIPv4Settings * ipv4Settings = [[NEIPv4Settings alloc]initWithAddresses:@[ip] subnetMasks:@[subnetMarks]];
    
    // 添加 VPN 子网路由规则
    NSString *subnetAddress = [self subnetAddressWithIPAddress:ip subnetMask:subnetMarks];
    NSArray *subnetMasks = @[subnetMarks];
    //NEIPv4Route *vpnRoute = [[NEIPv4Route alloc] initWithDestinationAddress:@"10.202.48.0" subnetMask:@"255.255.255.0"];
    NEIPv4Route *vpnRoute = [[NEIPv4Route alloc] initWithDestinationAddress:subnetAddress subnetMask:subnetMasks[0]];
    ipv4Settings.includedRoutes = @[vpnRoute];
    
    // 添加默认路由规则
    NEIPv4Route *defaultRoute = [NEIPv4Route defaultRoute];
    ipv4Settings.excludedRoutes = @[defaultRoute];


    settings.IPv4Settings = ipv4Settings;
    NSString * dns = options[@"dns"];
    if (![[dns class] isEqual:[NSNull class]] && dns.length >0) {
        NEDNSSettings * set_dns = [[NEDNSSettings alloc]initWithServers:@[dns]];
        settings.DNSSettings = set_dns;
    }
    [NETunnelProviderManager sharedManager].localizedDescription = @"happyn";
//    [self setUdpSession];

//    NSLog(@"%@",description);
    __weak typeof(self) weakSelf = self;
    [weakSelf setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
        completionHandler(error);
        [weakSelf didStartTunnel];
        
    }];
    // Add code here to start the process of connecting the tunnel.
}

- (NSString *)subnetAddressWithIPAddress:(NSString *)ipAddress subnetMask:(NSString *)subnetMask {
     NSArray *ipArray = [ipAddress componentsSeparatedByString:@"."];
     NSArray *maskArray = [subnetMask componentsSeparatedByString:@"."];
     NSMutableString *subnet = [NSMutableString string];
     
     for (int i = 0; i < 4; i++) {
         NSString *ipPart = ipArray[i];
         NSString *maskPart = maskArray[i];
         NSInteger subnetPart = [ipPart integerValue] & [maskPart integerValue];
         [subnet appendFormat:@"%ld", subnetPart];
         if (i < 3) {
             [subnet appendString:@"."];
         }
     }
     return subnet;
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    // Add code here to start the process of stopping the tunnel.
    NSLog(@"stopTunnelWithReason______");
    completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
    NSLog(@"handleAppMessage_______");
    // Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    // Add code here to get ready to sleep.
    NSLog(@"sleepWithCompletionHandler______");
    completionHandler();
}

- (void)wake {
    NSLog(@"wake_____");
    // Add code here to wake up.
}

-(void)didStartTunnel{
    [self callBackProvider];
}


-(void)callBackProvider{
    NSLog(@"readPackets:--:");
    [self readPacket];
    [self registerNotificationCallBack];

}


//注册写包通知,如果有收到来自remote packet, 则写进tunnel
-(void)registerNotificationCallBack{
    if (traditionalWormhole == nil) {
        traditionalWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.net.happyn.happynios.happynet"
                                                                        optionalDirectory:@"n2n"];
        watchConnectivityListeningWormhole = [MMWormholeSession sharedListeningSession];

    }
   
    [traditionalWormhole listenForMessageWithIdentifier:@"writePacket" listener:^(id messageObject) {
        NSArray * dataArray = [messageObject valueForKey:@"packets"];
        
        NSMutableArray * array = [NSMutableArray array];
//        NSLog(@"%@",dataArray);
       
        for (int i = 0; i<dataArray.count; i++) {
            NSDictionary * dic = dataArray[i];
            NSData * da = dic[@"value"];
//          NEPacket * packet = [[NEPacket alloc]initWithData:da protocolFamily:AF_INET];
            [array addObject:da];
        }
        NSArray * protols = @[@(AF_INET)];
        BOOL success = [self.packetFlow writePackets:array withProtocols:protols];
//        NSLog(@"%d",success);
    }];

    [watchConnectivityListeningWormhole activateSessionListening];
    
}

-(void)localPacketsToServer{
    [self readPacket];
}

-(void)readPacket{
    __weak typeof(self) weakSelf = self;
   
    hole = [[MMWormhole alloc]initWithApplicationGroupIdentifier:@"group.net.happyn.happynios.happynet" optionalDirectory:@"n2n"];
    NSMutableArray * packArray = [NSMutableArray array];
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
                      if (packets.count>0) {
                         
      for (NSData * data in packets) {
//           char * packet =(void *)data.bytes;
          [self->udpSession writeDatagram:data completionHandler:^(NSError * _Nullable error) {
//              NSLog(@"writeDatagram::%@",error);
          }];
          NSDictionary * dic = @{@"value":data};
          [packArray addObject:dic];
      }
      [self->hole passMessageObject:@{@"packets" : packArray} identifier:@"readPackets"];
    }
      [weakSelf readPacket];
    }];
}

//域名解析
- (NSString *)queryIpWithDomain:(NSString *)domain {
    Boolean result,bResolved;
     CFHostRef hostRef;
     CFArrayRef addresses = NULL;
     NSMutableArray * ipsArr = [[NSMutableArray alloc] init];

   const char * dns =  [domain cStringUsingEncoding:NSUTF8StringEncoding];
     CFStringRef hostNameRef = CFStringCreateWithCString(kCFAllocatorDefault, dns, kCFStringEncodingASCII);
     
     hostRef = CFHostCreateWithName(kCFAllocatorDefault, hostNameRef);
     result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL);
     if (result == TRUE) {
         addresses = CFHostGetAddressing(hostRef, &result);
     }
     bResolved = result == TRUE ? true : false;
     
     if(bResolved)
     {
         struct sockaddr_in* remoteAddr;
         for(int i = 0; i < CFArrayGetCount(addresses); i++)
         {
             CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
             remoteAddr = (struct sockaddr_in*)CFDataGetBytePtr(saData);
             
             if(remoteAddr != NULL)
             {
                 //获取IP地址
                 char ip[16];
                 strcpy(ip, inet_ntoa(remoteAddr->sin_addr));
                 NSString * ipStr = [NSString stringWithCString:ip encoding:NSUTF8StringEncoding];
                 [ipsArr addObject:ipStr];
             }
         }
     }
//     CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
     CFRelease(hostNameRef);
     CFRelease(hostRef);
     NSString * ip = nil;
     if (ipsArr.count>0) {
       ip = ipsArr[0];
        return ip;
     }
    return nil;
}
@end
