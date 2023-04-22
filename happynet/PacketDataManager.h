//
//  packetDataManager.h
//  hin2n
//
//  Created by noontec on 2021/9/4.
//

#ifndef PacketDataManager_h
#define PacketDataManager_h

#include <stdio.h>
int initPipe(void);
int writePackets(char packets[], int packetLength);
int writeDataToTunnel(char data[], int length);
void closePipe(void);
int startServer(int description);
#endif /* PacketDataManager_h */
