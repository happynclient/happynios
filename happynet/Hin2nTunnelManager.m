//
//  Hin2nTunnelManager.m
//  hin2n
//
//  Created by noontec on 2021/8/25.
//

@import HappynetDylib;
#import "Hin2nTunnelManager.h"
#import "MMWormhole.h"
#import "MMWormholeSession.h"
#include "happynet-Swift.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@implementation Hin2nTunnelManager

SettingModel *currentModel = nil;
NETunnelProviderManager *mg;
int startResult = 0;

MMWormhole *traditionalWormhole;
MMWormhole *watchConnectivityWormhole;
MMWormholeSession *watchConnectivityListeningWormhole;
AVAudioPlayer *_player;
// NSTimer * logTimer;

+ (instancetype)shareManager {
  static Hin2nTunnelManager *_manager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // 要使用self来调用
    _manager = [[self alloc] init];
    mg = [[NETunnelProviderManager alloc] init];
  });
  return _manager;
}

#pragma mark // 开启 Tounnel
- (void)initTunnel:(SettingModel *)currentSettingModel {
  if (currentSettingModel != nil) {
    currentModel = currentSettingModel;
  }
}

- (int)startTunnel {
  // 每次调用前重置，避免返回上一次连接留下的旧状态导致 UI 判断错误
  // 注意：startWithConfig:completion: 是完全异步的，这里立即返回，
  // 真正的连接结果通过 NEVPNStatusDidChange → serviceConnectStatus 通知驱动 UI
  startResult = 0;

  if ([[currentModel.ipAddress class] isEqual:[NSNull class]] ||
      currentModel.ipAddress == nil || [currentModel.ipAddress isEqual:@""]) {
    startResult = -1;
  } else {
    // 创建HappynedgeConfig配置信息
    HappynedgeConfig *config = [[HappynedgeConfig alloc] init];

    NSArray *components =
        [currentModel.supernode componentsSeparatedByString:@":"];
    config.superNodeAddr = components[0];
    config.superNodePort = components[1];
    config.networkName = currentModel.community;
    config.encryptionKey = currentModel.encrypt;
    config.ipAddress = currentModel.ipAddress;

    config.subnetMask = currentModel.subnetMark;
    config.deviceDescription = currentModel.deviceDescription;

    if (![currentModel.gateway isKindOfClass:[NSNull class]] &&
        currentModel.gateway.length > 0) {
      config.gateway = currentModel.gateway;
    }
    if (![currentModel.dns isKindOfClass:[NSNull class]] &&
        currentModel.dns.length > 0) {
      config.dns = currentModel.dns;
    }
    if (![currentModel.mac isKindOfClass:[NSNull class]] &&
        currentModel.mac.length > 0) {
      config.mac = currentModel.mac;
    }
    config.mtu = currentModel.mtu;

    config.encryptionMethod = currentModel.encryptionMethod;
    config.localPort = currentModel.port;
    config.forwarding = currentModel.forwarding;
    config.isAcceptMulticast = currentModel.isAcceptMulticast;
    config.loglevel = currentModel.level;

    // 调用HappynedgeManager的start方法（异步）
    // 此处 completion 仅作日志，不修改 startResult（startTunnel 此时已返回）
    HappynedgeManager *manager = [HappynedgeManager shared];
    [manager startWithConfig:config
                  completion:^(NSError *_Nullable error) {
                    if (error) {
                      NSLog(@"Error starting VPN: %@", error);
                    } else {
                      NSLog(@"VPN started successfully!");
                    }
                  }];
  }
  return startResult;
}

#pragma mark // 是否启动成功
- (int)TunnelStartResult {
  return startResult;
}

- (void)setServiceConnectStatus:(int)status {
  NSDictionary *dic = @{@"status" : @(status)};
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"serviceConnectStatus"
                    object:nil
                  userInfo:dic];
}

#pragma mark // stop tunnel connect
- (void)stopTunnel {
  [[HappynedgeManager shared] stop];
}

// vpnStatusDidChanged: 已废弃 —— 只在未启用的 reStartTunnel 中注册，
// 且读取的是旧 'mg' 实例的状态，不再使用。
// VPN 状态变化由 HappynedgeManager (NEVPNStatusDidChange) →
// serviceConnectStatus 通知驱动。

int openVPN(void) { return 1; }

- (void)stopLoadPlayback {
  if (_player) {
    [_player stop];
    _player = nil;
  }
  if (self.background) {
    self.background(NO);
  }
}
- (void)startLoadPlayback {
  if (self.background) {
    self.background(YES);
  }

  AVAudioSession *as = [AVAudioSession sharedInstance];
  [as setCategory:AVAudioSessionCategoryPlayback
      withOptions:AVAudioSessionCategoryOptionMixWithOthers
            error:nil];

  NSURL *url;
  NSLog(@"has real settings, play silence");
  url = [[NSBundle mainBundle] URLForResource:@"silence.mp3" withExtension:nil];

  if (_player == nil) {
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
  }
  _player.numberOfLoops = -1;
  [_player prepareToPlay];
  [_player play];
}

- (int)setIpFromSupernode:(NSDictionary *)params {

  return [self reStartTunnel:params];
}

// 暂时没有使用，计划自动获取ip后调用
- (int)reStartTunnel:(NSDictionary *)params {
  NSString *ipAddrerss = params[@"ipAddress"];
  NSString *subnetMark = params[@"subnetMark"];
  NETunnelProviderProtocol *protocal = [[NETunnelProviderProtocol alloc] init];
  mg.localizedDescription = @"happyn";
  protocal.providerBundleIdentifier = @"net.happyn.happynios.happynet.tunnel";
  protocal.serverAddress = currentModel.supernode;
  protocal.providerConfiguration = @{@"" : @""};
  mg.protocolConfiguration = protocal;
  NSString *supernode = currentModel.supernode;
  NSString *remoteAdd = nil;
  mg.enabled = YES;
  if ([supernode containsString:@":"]) {
    NSArray *tempArray = [supernode componentsSeparatedByString:@":"];
    remoteAdd = tempArray[0];
  } else {
    remoteAdd = supernode;
  }
  NEPacketTunnelNetworkSettings *settings =
      [[NEPacketTunnelNetworkSettings alloc]
          initWithTunnelRemoteAddress:remoteAdd];
  NEIPv4Settings *set_ipv4 =
      [[NEIPv4Settings alloc] initWithAddresses:@[ ipAddrerss ]
                                    subnetMasks:@[ subnetMark ]];
  set_ipv4.includedRoutes = @[ [NEIPv4Route defaultRoute] ];
  settings.IPv4Settings = set_ipv4;

  if (![[currentModel.dns class] isEqual:[NSNull class]] &&
      currentModel.dns.length > 0) {
    NEDNSSettings *set_dns =
        [[NEDNSSettings alloc] initWithServers:@[ currentModel.dns ]];
    settings.DNSSettings = set_dns;
  }
  [NETunnelProviderManager sharedManager].enabled = YES;
  [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(
                               NSArray<NETunnelProviderManager *>
                                   *_Nullable managers,
                               NSError *_Nullable error) {
    if (managers.count > 0) {
      mg = managers.firstObject;
      [mg loadFromPreferencesWithCompletionHandler:^(NSError *_Nullable error) {
        if (error == nil) {
          [self startTunnelFromSupernode:params];
          NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
          [nc addObserver:self
                 selector:@selector(vpnStatusDidChanged:)
                     name:NEVPNStatusDidChangeNotification
                   object:nil];
        }
      }];

    } else {
      [mg saveToPreferencesWithCompletionHandler:^(NSError *_Nullable error) {
        NSLog(@"saveToPreferencesWithCompletionHandler::%@", error);
        if (!error) {
          [mg loadFromPreferencesWithCompletionHandler:^(
                  NSError *_Nullable error) {
            if (error == nil) {
              [self startTunnelFromSupernode:params];
              NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
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

  int result = 0;
  return result;
}
- (void)startTunnelFromSupernode:(NSDictionary *)params {

  NSString *ipAddress = params[@"ipAddress"];
  NSString *subnetMark = params[@"subnetMark"];

  NSString *supernode = currentModel.supernode;
  NSString *remoteAdd = nil;
  if ([supernode containsString:@":"]) {
    NSArray *tempArray = [supernode componentsSeparatedByString:@":"];
    remoteAdd = tempArray[0];
  } else {
    remoteAdd = supernode;
  }
  //    remoteAdd = currentModel.supernode;
  if ([[currentModel.dns class] isEqual:[NSNull class]]) {
    currentModel.dns = @"119.29.29.29";
  }
  if ([[currentModel.ipAddress class] isEqual:[NSNull class]] ||
      currentModel.ipAddress == nil) {
    return;
  }
  NSDictionary *dic = @{
    @"ip" : ipAddress,
    @"subnetMark" : subnetMark,
    @"gateway" : currentModel.gateway,
    @"dns" : currentModel.dns,
    @"mac" : currentModel.mac,
    @"mtu" : @(currentModel.mtu),
    @"port" : @(currentModel.port),
    @"forwarding" : @(currentModel.forwarding),
    @"isAcceptMulticast" : @(currentModel.isAcceptMulticast),
    @"remoteAddress" : remoteAdd
  };
  NSError *error;
  //    mg.onDemandEnabled = YES;
  //    mg.enabled = YES;
  //    mg.onDemandEnabled = YES;
  //    BOOL en = mg.isEnabled;
  //    BOOL en1 = mg.isOnDemandEnabled;
  BOOL isSuccess = [mg.connection startVPNTunnelWithOptions:dic
                                             andReturnError:&error];
}
@end
