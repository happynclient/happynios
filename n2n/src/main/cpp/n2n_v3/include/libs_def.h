#ifndef _LIBS_DEF_H_
#define _LIBS_DEF_H_

typedef struct tagCurrentSettings {
    char           version;
    char           *supernode;
    char           *community;
    char           *encryptKey;
    char           *ipAddress;
    char           *subnetMark;
    char           *deviceDescription;
    char           *supernode2;
    int             mtu;
    char           *gateway;
    char           *dns;
    char           *mac;
    char            encryptionMethod;
    unsigned short  port;
    char            forwarding;
    char            acceptMultiMacaddr;
    char            level;
    
    int             vpnFd;
    char            logPath[1024];
} CurrentSettings;

#ifdef _N2N_H_  //Make sure included ONLY in n2n v2 and v3 projects （not in main project)

#define ARP_PERIOD_INTERVAL     10 /* sec */

typedef struct {
    uint32_t gateway_ip;
    n2n_mac_t gateway_mac;
    n2n_edge_conf_t *conf;
    uint8_t tap_mac[6];
    uint32_t tap_ipaddr;
    time_t lastArpPeriod;
} n2n_android_t;
#endif

#endif
