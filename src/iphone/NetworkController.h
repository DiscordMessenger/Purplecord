#pragma once
#import <Foundation/Foundation.h>
#include <string>

struct WebsocketFailParams {
	int gatewayID;
	int errorCode;
	std::string message;
	bool isTLSError;
	bool mayRetry;
};

@interface NetworkController : NSObject <UIAlertViewDelegate>

- (instancetype)init;
- (void)dealloc;

- (void)processResponse:(NSValue*)netRequestNSValue;
- (void)processWebsocketMessage:(NSValue*)websocketMessageNSValue;
- (void)finishedProcessingHugeMessage;
- (void)refreshGuildList;
- (void)setHeartbeatInterval:(NSInteger)timeMs;
- (void)updateAttachmentByID:(const std::string&)rid;
- (void)onWebsocketFail:(NSValue*)websocketFailNSValue;
- (void)setLoginStage:(NSString*)stage;

@end

NetworkController* GetNetworkController();
