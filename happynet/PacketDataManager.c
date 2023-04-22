//
//  PacketDataManager.c
//  hin2n
//
//  Created by noontec on 2021/9/4.
//
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>
#include "BridgeC2OC.h"

int result = 0;
pid_t pid=0;
static int pipe_fd_1[2];
char c_buf[10240];

int initPipe(void){
    if(pipe(pipe_fd_1) < 0)
        return -1;
    
    return pipe_fd_1[0];  // 返回管道的read端
}
int startServer(int description){
    int re = description;
    return re;
}
void closePipe(void){
    close(pipe_fd_1[0]);
    close(pipe_fd_1[1]);
}
//将从tunnel读取的包写入管道
int writePackets(char packets[], int packetLength)
{
#if 1
    unsigned short pktHead = 0x1234;
    if(sizeof(pktHead) != write(pipe_fd_1[1], &pktHead, sizeof(pktHead)))
        return -1;
    
    unsigned short pktLen = (unsigned short)packetLength;
    if(sizeof(pktLen) != write(pipe_fd_1[1], &pktLen, sizeof(pktLen)))
        return -1;
#endif
    int writtenLength = 0;
    while (writtenLength < packetLength) {
        int ret = (int)write(pipe_fd_1[1], &packets[writtenLength], packetLength - writtenLength);
        if (ret < 0)
            return ret;
        writtenLength += ret;
    }
    return writtenLength;
}

int writeDataToTunnel(char data[], int length){
    //   c 调用object c  写包到tunnel
    return writePacketIntoTunnel(data, length);
}
