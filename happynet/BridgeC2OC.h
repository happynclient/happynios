//
//  BridageC2OC.h
//  hin2n
//  Created by noontec on 2021/9/7.
//
typedef enum
{
    DISCONNECTED = 0,
    CONNECTING,
    CONNECTED,
    SUPERNODE_DISCONNECT
}connectStatus;

#include <stdio.h>

int startTunnel(void);
void stopTunnel(void);
int writePacketIntoTunnel(char data[], int length);

int setAddressFromSupernode(const char *ip , const char *subnetMark);

void notifyConnectionStatus(connectStatus status); //1,2,3,4false

//#import <Foundation/Foundation.h>
//
//NS_ASSUME_NONNULL_BEGIN
//
//@interface BridageC2OC : NSObject
//
//@end
//
//NS_ASSUME_NONNULL_END
