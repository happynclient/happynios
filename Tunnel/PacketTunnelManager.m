//
//  PacketTunnelManager.m
//  Tunnel
//
//  Created by mac on 2023/7/7.
//

#import <Foundation/Foundation.h>
#import "PacketTunnelManager.h"
#import <Foundation/Foundation.h>
#import "MMWormhole.h"
#import "MMWormholeSession.h"
#import <AVFoundation/AVFoundation.h>
#import "PacketDataManager.h"

@implementation PacketTunnelManager

MMWormhole * ptraditionalWormhole;
MMWormholeSession * pwatchConnectivityListeningWormhole;

//注册读取包后从tunnel 传出来的 packetArray
- (void)registerNotificationCallBack{
    
    if (ptraditionalWormhole == nil) {
        ptraditionalWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.net.happyn.happynios.happynet"
                                                                        optionalDirectory:@"n2n"];
        pwatchConnectivityListeningWormhole = [MMWormholeSession sharedListeningSession];

    }
   
    [ptraditionalWormhole listenForMessageWithIdentifier:@"readPackets" listener:^(id messageObject) {
        // The number is identified with the buttonNumber key in the message object
        NSArray * dataArray = [messageObject valueForKey:@"packets"];
        
        NSLog(@"%@",dataArray);
       
        for (int i = 0; i<dataArray.count; i++) {
            NSDictionary * dic = dataArray[i];
             NSData * data = dic[@"value"];
             char * packet = (void *)data.bytes;
             int packetLength = (int)data.length;
             //NSString * s = data.debugDescription;
             //char css[1024];

             //memcpy(css, [s cStringUsingEncoding:NSASCIIStringEncoding], 2*[s length]);
             writePacketsData(packet, packetLength);
        }
    }];
    
    [pwatchConnectivityListeningWormhole activateSessionListening];
    
}

#pragma mark // 读包 写进 packetDataManager管道
-(void)readPacketsDataFromTunnelProvider{
  __weak typeof(self) weakSelf = self;
    if (_currentProvider != nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
               [weakSelf readPacket];
        });
    }
}
    
#pragma mark // 读包 —本地外发
-(void)readPacket{
    __weak typeof(self) weakSelf = self;
    [_currentProvider.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
                      if (packets.count>0) {
      for (NSData * data in packets) {
          char * packet = (void *)data.bytes;
          int packetLength = (int)data.length;
          writePacketsData(packet, packetLength);
      }
    }
    [weakSelf readPacket];
    }];

}

#pragma mark // 写包- 远程进来
-(int)writePackets:(NSArray<NSData *>*)dataArray{
    
    NSMutableArray * packetArray = [NSMutableArray array];
    for (int i = 0; i<dataArray.count; i++) {
        NSData * da = dataArray[i];
        NEPacket * pack = [[NEPacket alloc]initWithData:da protocolFamily:AF_INET];
        [packetArray addObject:pack];
    }
    NSArray * arr = [NSArray arrayWithArray:packetArray];
    __block int writePacketResult = 0;
//    if (_currentProvider != nil) {
        dispatch_queue_t queue = dispatch_queue_create("com.hin2n.packetFlow.writePacket", DISPATCH_QUEUE_CONCURRENT);
        dispatch_semaphore_t checkAsycSemaphore = dispatch_semaphore_create(0);
        dispatch_sync(queue, ^{
            if([_currentProvider.packetFlow writePacketObjects:arr]){
                writePacketResult += 1;
                NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:@"writePacketObjects_success" forKey:@"writePacketObjects"];
                [userDefaults synchronize];
                dispatch_semaphore_signal(checkAsycSemaphore);
            }
        });
        dispatch_semaphore_wait(checkAsycSemaphore, 10);
//}

    return writePacketResult;
}


@end
