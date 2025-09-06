#pragma once
#import <Foundation/Foundation.h>

@interface NetworkController : NSObject

- (void)processResponse:(NSValue*)netRequestNSValue;
- (void)processWebsocketMessage:(NSValue*)websocketMessageNSValue;
- (instancetype)init;
- (void)dealloc;

@end

NetworkController* GetNetworkController();
