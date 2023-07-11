//
//  edge_ios.c
//  hin2n
//
//  Created by twm01 on 2021/8/21.
//
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include "edge_ios.h"

typedef struct {
    int tun_read_fd;
    int tun_write_fd;
    int udp_read_fd;
    int udp_write_fd;
    int mgr_read_fd;
    int mgr_write_fd;
} ios_io_bridge;


int start_edge_v1(CurrentSettings *settings);
int stop_edge_v1(void);
int start_edge_v2s(CurrentSettings *settings);
int stop_edge_v2s(void);
int start_edge_v2(CurrentSettings *settings);
int stop_edge_v2(void);
int start_edge_v3(CurrentSettings *settings);
int stop_edge_v3(void);

typedef int (*start_edge_func)(CurrentSettings *);
typedef int (*stop_edge_func)(void);

static int g_current_running_edge_version = 0;
static pthread_t g_tid = -1;
static start_edge_func g_start_edge = NULL;
static stop_edge_func  g_stop_edge  = NULL;

void printSettingInfo(CurrentSettings *settings){
    printf("Now print current settings.\n");
    printf("===========================\n");
    printf("\tversion : %d.\n", settings->version);
    printf("\tsupernode: %s\n", settings->supernode);
    printf("\tcommunity: %s\n", settings->community);
    printf("\tencrypt key: %s\n", settings->encryptKey);
    printf("\tipaddr: %s\n", settings->ipAddress);
    printf("\tnetmask: %s\n", settings->subnetMark);
    printf("\tdevDesc: %s\n", settings->deviceDescription);
    printf("\tencrypt_method: %d\n", settings->encryptionMethod);
    printf("\tsupernode-2: %s\n", settings->supernode2);
    printf("\tmtu: %d\n", settings->mtu);
    printf("\tport: %d\n", settings->port);
    printf("\tgateway: %s\n", settings->gateway);
    printf("\tdns: %s\n", settings->dns);
    printf("\tmac: %s\n", settings->mac);
    printf("\tpacket_forwarding: %d\n", settings->forwarding);
    printf("\taccept_multi_macaddr: %d\n", settings->acceptMultiMacaddr);
    printf("\ttraceLevel : %d\n", settings->level);
    printf("===========================\n");
    return;
}

static void init_fd(ios_io_bridge *bridge) {
    if (bridge->tun_read_fd == 0) {
        int fd[2] = {0};
        
        //tun
        int result = pipe(fd);
        //assert(result >= 0);
        if (result >= 0) {
            bridge->tun_read_fd = fd[0];
            bridge->tun_write_fd = fd[1];
        }
        
        //udp
        result = pipe(fd);
        //assert(result >= 0);
        if (result >= 0) {
            bridge->udp_read_fd = fd[0];
            bridge->udp_write_fd = fd[1];
        }

        //mgr
        result = pipe(fd);
        //assert(result >= 0);
        if (result >= 0) {
            bridge->mgr_read_fd = fd[0];
            bridge->mgr_write_fd = fd[1];
        }
    }
}

void *EdgeRoutine(void *params){
    CurrentSettings *settings = (CurrentSettings *)params;
    
    printSettingInfo(settings);
    
    if(!params || !g_start_edge)
        return NULL;
    
    int ret = g_start_edge(settings);
    if(ret < 0){
        ; //TODO : 向前端报告异常。
        g_stop_edge = NULL;
    }
    
    return NULL;
}


int StartEdge(CurrentSettings *settings){
    // 打印调试信息，看看是否运行正常。
    printSettingInfo(settings);
    
    printf("Now start edge.\n");
    g_current_running_edge_version = settings->version;
    switch(settings->version){
        case 0:   //v1
            g_start_edge = start_edge_v1;
            g_stop_edge  = stop_edge_v1;
            break;
        case 1:   //v2s
            g_start_edge = start_edge_v2s;
            g_stop_edge  = stop_edge_v2s;
            break;
        case 2:   //v2
            g_start_edge = start_edge_v2;
            g_stop_edge  = stop_edge_v2;
            break;
        case 3:   //v3
            g_start_edge = start_edge_v3;
            g_stop_edge  = stop_edge_v3;
            break;
        default:
            printf("n2n version is error!\n");
            return -1;
    }
    
    int ret = pthread_create(&g_tid, NULL, EdgeRoutine, (void *)settings);
    if (ret != 0) {
        return -1;
    }
    
    return 0;
}

int StopEdge(void){
    printf("Stop Edge.\n");
    int ret = 0;
    if(g_stop_edge) {
        ret = g_stop_edge();
        g_stop_edge = NULL;
    }
    return ret;
}
