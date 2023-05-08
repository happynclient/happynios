//
//  Hin2nTunnelManager.m
//  hin2n
//
//  Created by noontec on 2021/8/25.
//

#include "PacketDataManager.h"
#import "Hin2nTunnelManager.h"
#import <Foundation/Foundation.h>
#import "MMWormhole.h"
#import "MMWormholeSession.h"
#import <AVFoundation/AVFoundation.h>

@implementation Hin2nTunnelManager

SettingModel * currentModel = nil;
NETunnelProviderManager * mg;
int startResult = 0;

MMWormhole * traditionalWormhole;
MMWormhole * watchConnectivityWormhole;
MMWormholeSession * watchConnectivityListeningWormhole;
AVAudioPlayer *_player;
//NSTimer * logTimer;

+ (instancetype)shareManager
{
    static Hin2nTunnelManager *_manager = nil;
       static dispatch_once_t onceToken;
       dispatch_once(&onceToken, ^{
            // 要使用self来调用
           _manager = [[self alloc] init];
           mg = [[NETunnelProviderManager alloc]init];
       });
       return _manager;
}
#pragma mark//开启 Tounnel
-(void)initTunnel:(SettingModel *)currentSettingModel{
    if (currentSettingModel != nil) {
        currentModel = currentSettingModel;
        }
}

-(int)startTunnel{
    __weak typeof(self) weakSelf = self;
    int result = initPipe();
    if ([[currentModel.ipAddress class] isEqual:[NSNull class]] || currentModel.ipAddress == nil ||
        [currentModel.ipAddress isEqual:@""]) {
        result = -1;
    }else{

        NETunnelProviderProtocol * protocal = [[NETunnelProviderProtocol alloc]init];
        mg.localizedDescription = @"happyn";
        protocal.providerBundleIdentifier = @"net.happyn.happynios.happynet.tunnel";
        protocal.serverAddress = currentModel.supernode;
        protocal.providerConfiguration = @{@"":@""};
        mg.protocolConfiguration = protocal;
//        mg.onDemandEnabled = YES;
        mg.enabled = YES;

        NSString * supernode =  currentModel.supernode;
        NSString * remoteAdd = nil;

        if ([supernode containsString:@":"]) {
            NSArray * tempArray  = [supernode componentsSeparatedByString:@":"];
            remoteAdd = tempArray[0];
        } else {
            remoteAdd = supernode;
        }
        NEPacketTunnelNetworkSettings * settings = [[NEPacketTunnelNetworkSettings alloc]initWithTunnelRemoteAddress:remoteAdd];

        NEIPv4Settings * set_ipv4 = [[NEIPv4Settings alloc]initWithAddresses:@[currentModel.ipAddress] subnetMasks:@[currentModel.subnetMark]];
        set_ipv4.includedRoutes = @[[NEIPv4Route defaultRoute]];

        settings.IPv4Settings = set_ipv4;

        if (![[currentModel.dns class]isEqual:[NSNull class]] && currentModel.dns.length >0) {
            NEDNSSettings * set_dns = [[NEDNSSettings alloc]initWithServers:@[currentModel.dns]];
            settings.DNSSettings = set_dns;
        }
        [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
            if (managers.count>0) {
                mg = managers.firstObject;
//                mg.onDemandEnabled = YES;
                [mg loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    if (error == nil) {
                            [weakSelf connectTunnelWithData:currentModel];
                        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                        [nc addObserver:self
                               selector:@selector(vpnStatusDidChanged:)
                                   name:NEVPNStatusDidChangeNotification
                                 object:nil];
                    }
                }];

            }else{
                
                [mg saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    NSLog(@"saveToPreferencesWithCompletionHandler::%@",error);
                    if (!error) {
                        [mg loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                            if (error == nil) {
                                    [weakSelf connectTunnelWithData:currentModel];
                                NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                [nc addObserver:self
                                       selector:@selector(vpnStatusDidChanged:)
                                           name:NEVPNStatusDidChangeNotification
                                         object:nil];
                            }
                        }];
                       
                    }
                }];
            }
           
        }];
    }
     return result;

}
-(void)connectTunnelWithData:(SettingModel *)data{
        NSString * supernode =  currentModel.supernode;
        NSString * remoteAdd = nil;
    if ([supernode containsString:@":"]) {
        NSArray * tempArray  = [supernode componentsSeparatedByString:@":"];
        remoteAdd = tempArray[0];
    } else {
        remoteAdd = supernode;
    }
    if ([[currentModel.ipAddress class] isEqual:[NSNull class]] || currentModel.ipAddress == nil ||
        [currentModel.ipAddress isEqual:@""]) {
        return;
    }
    if ([[currentModel.dns class] isEqual:[NSNull class]]) {
        currentModel.dns = @"8.8.8.8";
    }

    if ([[currentModel.ipAddress class] isEqual:[NSNull class]] || currentModel.ipAddress == nil ||
        [currentModel.ipAddress isEqual:@""]) {
        return;
    }
    NSDictionary * dic = @{
                           @"ip":currentModel.ipAddress,
                           @"subnetMark":currentModel.subnetMark,
                           @"gateway":currentModel.gateway,
                           @"dns":currentModel.dns,
                           @"mac":currentModel.mac,
                           @"mtu":@(currentModel.mtu),
                           @"port":@(currentModel.port),
                           @"forwarding":@(currentModel.forwarding),
                           @"isAcceptMulticast":@(currentModel.isAcceptMulticast),
                           @"remoteAddress":remoteAdd
                           };
    NSError * error;
    mg.enabled = YES;
//    BOOL en = mg.isEnabled;
//    BOOL en1 = mg.isOnDemandEnabled;

    BOOL isSuccess = [mg.connection startVPNTunnelWithOptions:dic andReturnError:&error];
    if (isSuccess) {
        [self registerNotificationCallBack];
    }
}
#pragma mark//是否启动成功
-(int)TunnelStartResult{
    return startResult;
}

-(void)setServiceConnectStatus:(int)status{
    NSDictionary * dic = @{@"status":@(status)};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"serviceConnectStatus" object:nil userInfo:dic];
}

#pragma mark //stop tunnel connect
-(void)stopTunnel{
    [mg.connection stopVPNTunnel];
     closePipe();
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
          writePackets(packet, packetLength);
      }
    }
    [weakSelf readPacket];
    }];

}

#pragma mark // 写包- 远程进来
-(int)writPackets:(NSArray<NSData *>*)dataArray{
    
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

//注册读取包后从tunnel 传出来的 packetArray
-(void)registerNotificationCallBack{
    
    if (traditionalWormhole == nil) {
        traditionalWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.net.happyn.happynios.happynet"
                                                                        optionalDirectory:@"n2n"];
        watchConnectivityListeningWormhole = [MMWormholeSession sharedListeningSession];

    }
   
    [traditionalWormhole listenForMessageWithIdentifier:@"readPackets" listener:^(id messageObject) {
        // The number is identified with the buttonNumber key in the message object
        NSArray * dataArray = [messageObject valueForKey:@"packets"];
        
        NSLog(@"%@",dataArray);
       
        for (int i = 0; i<dataArray.count; i++) {
            NSDictionary * dic = dataArray[i];
             NSData * data = dic[@"value"];
             char * packet = (void *)data.bytes;
             int packetLength = (int)data.length;
//            NSString * s = data.debugDescription;
//            char css[1024];

//               memcpy(css, [s cStringUsingEncoding:NSASCIIStringEncoding], 2*[s length]);
            writePackets(packet, packetLength);
            }
    }];
    
    [watchConnectivityListeningWormhole activateSessionListening];
    
}
- (void)vpnStatusDidChanged:(NSNotification *)notification
{
    NEVPNStatus status = mg.connection.status;
    if (self.tunnelStatus ) {
        self.tunnelStatus(status);
    }
}
int openVPN(void){
    return 1;
}


-(void)stopLoadPlayback
{ if (_player) {
        [_player  stop];
        _player = nil;
    }
    if (self.background) {
        self.background(NO);
    }
}
- (void)startLoadPlayback
{
    if (self.background) {
        self.background(YES);
    }
    
    /*
    AVAudioSession *as = [AVAudioSession sharedInstance];
    [as setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    NSURL * url = [[NSBundle mainBundle] URLForResource:@"silence.mp3" withExtension:nil];
    if (_player == nil) {
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    }
    _player.numberOfLoops = -1;
    [_player prepareToPlay];
    [_player play];
    */
}

-(int)setIpFromSupernode:(NSDictionary*)params{
   
    return [self reStartTunnel:params];
}

-(int)reStartTunnel:(NSDictionary *)params{
    NSString * ipAddrerss = params[@"ipAddress"];
    NSString * subnetMark = params[@"subnetMark"];
    NETunnelProviderProtocol * protocal = [[NETunnelProviderProtocol alloc]init];
    mg.localizedDescription = @"happyn";
    protocal.providerBundleIdentifier = @"net.happyn.happynios.happynet.tunnel";
    protocal.serverAddress = currentModel.supernode;
    protocal.providerConfiguration = @{@"":@""};
    mg.protocolConfiguration = protocal;
    NSString * supernode =  currentModel.supernode;
    NSString * remoteAdd = nil;
    mg.enabled = YES;
    if ([supernode containsString:@":"]) {
        NSArray * tempArray  = [supernode componentsSeparatedByString:@":"];
        remoteAdd = tempArray[0];
    } else {
        remoteAdd = supernode;
    }
    NEPacketTunnelNetworkSettings * settings = [[NEPacketTunnelNetworkSettings alloc]initWithTunnelRemoteAddress:remoteAdd];
    NEIPv4Settings * set_ipv4 = [[NEIPv4Settings alloc]initWithAddresses:@[ipAddrerss] subnetMasks:@[subnetMark]];
    set_ipv4.includedRoutes = @[[NEIPv4Route defaultRoute]];
    settings.IPv4Settings = set_ipv4;

    if (![[currentModel.dns class]isEqual:[NSNull class]] && currentModel.dns.length >0) {
        NEDNSSettings * set_dns = [[NEDNSSettings alloc]initWithServers:@[currentModel.dns]];
        settings.DNSSettings = set_dns;
    }
    [NETunnelProviderManager sharedManager].enabled = YES;
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (managers.count>0) {
            mg = managers.firstObject;
            [mg loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                if (error == nil) {
                    [self startTunnelFromSupernode:params];
                    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                    [nc addObserver:self
                           selector:@selector(vpnStatusDidChanged:)
                               name:NEVPNStatusDidChangeNotification
                             object:nil];
                }
            }];

        }else{
            [mg saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                NSLog(@"saveToPreferencesWithCompletionHandler::%@",error);
                if (!error) {
                    [mg loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                        if (error == nil) {
                            [self startTunnelFromSupernode:params];
                            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                            [nc addObserver:self
                                   selector:@selector(vpnStatusDidChanged:)
                                       name:NEVPNStatusDidChangeNotification
                                     object:nil];
                        }
                    }];
                   
                }
            }];
        }
       
    }];
    
    int result = initPipe();
    return result;
}
-(void)startTunnelFromSupernode:(NSDictionary *)params{
    
    NSString * ipAddress = params[@"ipAddress"];
    NSString * subnetMark = params[@"subnetMark"];
    
    NSString * supernode =  currentModel.supernode;
    NSString * remoteAdd = nil;
    if ([supernode containsString:@":"]) {
        NSArray * tempArray  = [supernode componentsSeparatedByString:@":"];
        remoteAdd = tempArray[0];
    } else {
        remoteAdd = supernode;
    }
//    remoteAdd = currentModel.supernode;
    if ([[currentModel.dns class] isEqual:[NSNull class]]) {
        currentModel.dns = @"8.8.8.8";
    }
    if ([[currentModel.ipAddress class] isEqual:[NSNull class]] || currentModel.ipAddress == nil) {
        return ;
    }
    NSDictionary * dic = @{
                           @"ip":ipAddress,
                           @"subnetMark":subnetMark,
                           @"gateway":currentModel.gateway,
                           @"dns":currentModel.dns,
                           @"mac":currentModel.mac,
                           @"mtu":@(currentModel.mtu),
                           @"port":@(currentModel.port),
                           @"forwarding":@(currentModel.forwarding),
                           @"isAcceptMulticast":@(currentModel.isAcceptMulticast),
                           @"remoteAddress":remoteAdd
                           };
    NSError * error;
//    mg.onDemandEnabled = YES;
//    mg.enabled = YES;
//    mg.onDemandEnabled = YES;
//    BOOL en = mg.isEnabled;
//    BOOL en1 = mg.isOnDemandEnabled;
    BOOL isSuccess = [mg.connection startVPNTunnelWithOptions:dic andReturnError:&error];
    if (isSuccess) {
        [self registerNotificationCallBack];
    }
}
@end
