#pragma once
#import <Foundation/Foundation.h>

@interface NetworkController : NSObject

- (void)processResponse:(NSValue*)netRequestNSValue;
- (instancetype)init;
- (void)dealloc;

@end

NetworkController* GetNetworkController();
