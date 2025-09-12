#pragma once
#import <Foundation/Foundation.h>
#include <string>

@interface NetworkController : NSObject

- (instancetype)init;
- (void)dealloc;

- (void)processResponse:(NSValue*)netRequestNSValue;
- (void)processWebsocketMessage:(NSValue*)websocketMessageNSValue;
- (void)finishedProcessingHugeMessage;
- (void)refreshGuildList;
- (void)setHeartbeatInterval:(NSInteger)timeMs;
- (void)updateAttachmentByID:(const std::string&)rid;

@end

NetworkController* GetNetworkController();
