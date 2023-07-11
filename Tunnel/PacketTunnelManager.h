//
//  PacketTunnelManager.h
//  Tunnel
//
//  Created by mac on 2023/7/7.
//

#ifndef PacketTunnelManager_h
#define PacketTunnelManager_h

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>

@interface PacketTunnelManager : NSObject
@property(nonatomic,strong)NEPacketTunnelProvider * currentProvider;

- (void)registerNotificationCallBack;

@end


#endif /* PacketTunnelManager_h */
