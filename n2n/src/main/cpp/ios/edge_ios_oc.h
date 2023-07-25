#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NetDataType) {
    NetDataTun,
    NetDataUdp
};

@interface EdgeConfig : NSObject //HappynedgeConfig
@property (nonatomic, copy) NSString *superNodeAddr;
@property (nonatomic, assign) NSUInteger superNodePort;
@property (nonatomic, copy) NSString *networkName;
@property (nonatomic, copy) NSString *encryptionKey;
@property (nonatomic, copy) NSString *ipAddress;

@property (nonatomic, copy) NSString *subnetMask;
@property (nonatomic, copy) NSString *deviceDescription;
@property (nonatomic, copy) NSString *gateway;
@property (nonatomic, copy) NSString *dns;
@property (nonatomic, copy) NSString *mac;
@property (nonatomic, assign) NSUInteger mtu;
@property (nonatomic, assign) NSUInteger encryptionMethod;
@property (nonatomic, assign) NSUInteger localPort;
@property (nonatomic, assign) NSUInteger forwarding;
@property (nonatomic, assign) NSUInteger isAcceptMulticast;
@property (nonatomic, assign) NSUInteger loglevel;
@end

@interface EdgeEngine : NSObject

- (instancetype)initWithTunnelProvider:(id)provider;

- (BOOL)start:(EdgeConfig *)config;
- (void)onData:(NSData *)data withType:(NetDataType)type ip:(NSString *)ip port:(NSInteger)port;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
