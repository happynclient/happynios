#import "edge_ios_oc.h"
#include "edge_jni.h"
#include "edge_ios.h"

#ifdef HAPPYNET_TEST_BRIDGE
#import "HappynetTests-Swift.h"
#endif

#ifdef HAPPYNET_BRIDGE
#import "Happynet-Swift.h"
#endif

#import "Tunnel-Swift.h"


typedef struct {
    UInt32 type; //0:ip, 1:port, 2:data
    UInt32 len;
} ios_udp_package;

static __weak PacketTunnelEngine *s_provider;

static ssize_t ios_sendto_sock(int fd, const void * buf, size_t len, const char *ip, int port) {
    if (s_provider && buf != NULL && ip != NULL) {
        NSData *data = [[NSData alloc] initWithBytes:buf length:len];
        NSString *portString = [NSString stringWithFormat:@"%d", port];
        NSLog(@"++++ ios_sendto_sock: %s, %d\n", ip, port);
        NSString *ipString = [NSString stringWithUTF8String:ip];
        //test
        //ipString = @"54.223.23.92";
        //portString = @"7787";
        if ([s_provider sendUdpWithData:data hostname:ipString port:portString]) {
            return len;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

static ssize_t ios_recvfrom(int fd, void *buf, size_t len, char *ip, int *port) {
    if (fd > 0 && buf != NULL) {
        ios_udp_package header = {0};
        int headerSize = sizeof(ios_udp_package);
        int data_len = 0;
        while (read(fd, &header, headerSize) > 0) {
            //ip
            if (header.type == 0) {
                read(fd, ip, header.len);
            } else if (header.type == 1) {
                read(fd, port, header.len);
            } else if (header.type == 2) {
                read(fd, buf, header.len);
                return header.len;
            } else {
                //error
                printf("error type: %d\n", header.type);
            }
        }
        return data_len;
    } else {
        return 0;
    }
}

static int ios_tuntap_write(unsigned char *buf, int len) {
    if (s_provider && buf != NULL && buf != NULL && len > 0) {
        @autoreleasepool {
            NSData *data = [[NSData alloc] initWithBytes:buf length:len];
            [s_provider writeTunData:data];
        }
        return len;
    } else {
        return 0;
    }
}

static void ios_report_edge_status(void) {
    NSLog(@"Happynet: ios_report_edge_status");
}

@interface EdgeEngine ()
@property (nonatomic, assign) void *n2nBridge;
@end

@implementation EdgeEngine

- (instancetype)initWithTunnelProvider:(id)provider {
    if (self = [super init]) {
        s_provider = provider;
        _n2nBridge = ios_create_bridge();
    }
    return self;
}

- (void)dealloc {
    if (_n2nBridge != NULL) {
        ios_destroy_bridge(_n2nBridge);
        _n2nBridge = NULL;
    }
}

- (BOOL)start:(EdgeConfig *)config {
    n2n_edge_status_t status = {0};
    [self reset_edgestatus:&status];
    pthread_mutex_init(&status.mutex, NULL);
    strncpy(status.cmd.ip_addr, config.ipAddress.UTF8String, sizeof(status.cmd.ip_addr) - 1);
    strncpy(status.cmd.ip_netmask, "255.255.255.0", sizeof(status.cmd.ip_netmask) - 1);
    strncpy(status.cmd.supernode, [NSString stringWithFormat:@"%@:%lu", config.superNodeAddr, (unsigned long)config.superNodePort].UTF8String, sizeof(status.cmd.supernode) - 1);
    
    strncpy(status.cmd.community, config.networkName.UTF8String, sizeof(status.cmd.community) - 1);
    status.cmd.enc_key = config.encryptionKey.UTF8String;

    strncpy(status.cmd.mac_addr, config.mac.UTF8String, sizeof(status.cmd.mac_addr) - 1);
    strncpy(status.cmd.ip_netmask, config.subnetMask.UTF8String, sizeof(status.cmd.ip_netmask) - 1);
    strncpy(status.cmd.gateway_ip, config.gateway.UTF8String, sizeof(status.cmd.gateway_ip) - 1);
    status.cmd.device_description = config.deviceDescription.UTF8String;
    
    status.cmd.encryption_mode = config.encryptionMethod;
    //strncpy(status.cmd.encryption_mode, "Twofish", sizeof(status.cmd.encryption_mode) - 1);
    status.cmd.mtu = config.mtu;
    status.cmd.allow_routing = config.forwarding;
    status.cmd.drop_multicast = !config.isAcceptMulticast;
    status.cmd.trace_vlevel = config.loglevel;
    
    status.cmd.vpn_fd = ios_get_fd(_n2nBridge, IOS_FD_TUNNEL);
    status.cmd.udp_fd = ios_get_fd(_n2nBridge, IOS_FD_UDP);
    status.cmd.mgr_fd = ios_get_fd(_n2nBridge, IOS_FD_MGR);
    status.cmd.sendto_sock = ios_sendto_sock;
    status.cmd.recvfrom = ios_recvfrom;
    status.cmd.tuntap_write = ios_tuntap_write;
    status.cmd.logpath = (char *)[self logPath].UTF8String;
    status.start_edge = start_edge_v3;
    status.stop_edge = stop_edge_v3;
    status.report_edge_status = ios_report_edge_status;
    
    int result = start_edge_v3(&status);
    return result;
}

- (void)onData:(NSData *)data withType:(NetDataType)type ip:(nonnull NSString *)ip port:(NSInteger)remotePort {
    UInt32 port = (UInt32)remotePort;
    char *value = (void *)data.bytes;
    int len = (int)data.length;
    ios_fd_type writeType = IOS_FD_TUNNEL;
    if (NetDataUdp == type) {
        writeType = IOS_FD_UDP;
        int totalLen = (sizeof(ios_udp_package) + ip.length/*ip*/
                        + sizeof(ios_udp_package) + sizeof(port)/*port*/
                        + sizeof(ios_udp_package) + (int)data.length);
        value = (char *)malloc(totalLen);
        if (value) {
            int udpLen = 0;
            ios_udp_package *item = (ios_udp_package *)value;
            //add ip
            item->type = 0;
            item->len = (UInt32)ip.length;
            strcpy((char *)item + sizeof(ios_udp_package), ip.UTF8String);
            udpLen += sizeof(ios_udp_package) + item->len;
            
            //add port
            item = (ios_udp_package *)((char *)item + sizeof(ios_udp_package) + item->len);
            item->type = 1;
            item->len = sizeof(port);
            memcpy((char *)item + sizeof(ios_udp_package), &port, sizeof(port));
            udpLen += sizeof(ios_udp_package) + item->len;
            
            //add data
            item = (ios_udp_package *)((char *)item + sizeof(ios_udp_package) + item->len);
            item->type = 2;
            item->len = len;
            memcpy((char *)item + sizeof(ios_udp_package), data.bytes, len);
            udpLen += sizeof(ios_udp_package) + item->len;
            len = udpLen;
        }
    }
    ios_write_data(_n2nBridge, writeType, value, len);
    if (NetDataUdp == type) {
        if (value) {
            free(value);
        }
    }
}

- (void)stop {
    //ios_write_data(_n2nBridge, IOS_FD_MGR, "stop", 4);
    stop_edge_v3();
}

// MARK: - Private
- (void)reset_edgestatus:(n2n_edge_status_t *)status {
    memset(&status->cmd, 0, sizeof(status->cmd));
    status->cmd.enc_key = NULL;
    status->cmd.enc_key_file = NULL;
    status->cmd.mtu = 1400;
    status->cmd.holepunch_interval = EDGE_CMD_HOLEPUNCH_INTERVAL;
    status->cmd.re_resolve_supernode_ip = 0;
    status->cmd.local_port = 0;
    status->cmd.allow_routing = 0;
    status->cmd.drop_multicast = 1;
    status->cmd.http_tunnel = 0;
    status->cmd.trace_vlevel = 4;
    status->cmd.vpn_fd = -1;
    status->cmd.logpath = NULL;

    status->start_edge = NULL;
    status->stop_edge = NULL;
    status->report_edge_status = NULL;

    status->edge_type = EDGE_TYPE_NONE;
    status->running_status = EDGE_STAT_DISCONNECT;
}

- (NSString *)documentPath {
    static NSString *dir;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSAssert(paths.count > 0, nil);
        dir = [paths objectAtIndex:0];
    });
    return dir;
}

- (NSString *)logPath {
    static NSString *logFolderPath = nil;
    static NSString *n2nLogPath = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // 获取共享容器的路径
        NSURL *appGroupContainerURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.net.happyn.happynios.happynet"];
        if (appGroupContainerURL == nil) {
            NSLog(@"Failed to get app group container URL");
            logFolderPath = nil;
        }
        
        // 创建日志文件夹路径
        NSURL *logFolderURL = [appGroupContainerURL URLByAppendingPathComponent:@"n2nLog"];
        
        // 构造日志文件路径
        NSURL *logFileURL = [logFolderURL URLByAppendingPathComponent:@"n2n.log"];
        n2nLogPath = [logFileURL path];
    });
        
    return n2nLogPath;
}

@end

@implementation EdgeConfig
@end
