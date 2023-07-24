//
//  HappynedgeManager.h
//  happynet
//
//  Created by mac on 2023/7/20.
//

#ifndef HappynedgeManager_h
#define HappynedgeManager_h


// HappynedgeManager.h
@import HappynetDylib;
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^Handler)(NSError * _Nullable error);

@interface HappynedgeManager : NSObject

@property (nonatomic, copy) void (^statusDidChangeHandler)(NSString *status);

@property (nonatomic, readonly) BOOL isOn;
@property (nonatomic, readonly) NSString *status;

+ (instancetype)sharedManager;

- (void)startWithConfig:(HappynedgeConfig * _Nonnull)config
             completion:(Handler)completion;

- (void)start:(Handler)completion;

- (void)stop;

- (void)refresh:(nullable Handler)completion;

- (void)setEnabled:(BOOL)isEnabled
        completion:(Handler)completion;

- (void)saveToPreferencesWithConfig:(HappynedgeConfig * _Nullable)config
                         completion:(Handler)completion;

- (void)removeFromPreferences:(Handler)completion;

@end

NS_ASSUME_NONNULL_END


#endif /* HappynedgeManager_h */
