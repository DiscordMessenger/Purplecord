#pragma once
#import <Foundation/Foundation.h>

@interface NetworkController : NSObject

- (instancetype)init;
- (void)dealloc;

- (void)processResponse:(NSValue*)netRequestNSValue;
- (void)processWebsocketMessage:(NSValue*)websocketMessageNSValue;
- (void)sendToGuildList;
- (void)refreshGuildList;

@end

NetworkController* GetNetworkController();
