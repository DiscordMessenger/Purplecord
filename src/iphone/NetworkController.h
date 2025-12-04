#pragma once
#import <Foundation/Foundation.h>
#include <string>
#include <vector>

struct WebsocketFailParams {
	int gatewayID;
	int errorCode;
	std::string message;
	bool isTLSError;
	bool mayRetry;
};

struct AttachmentDownloadedParams {
	std::vector<uint8_t> data;
	std::string additData;
	bool bIsProfilePicture;
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
- (void)loadedImageFromDataBackgroundThread:(UIImage*)himg withAdditData:(NSString*)additData;
- (void)loadImageFromDataBackgroundThread:(NSValue*)attachmentDownloadedParamsNSValue;

@end

NetworkController* GetNetworkController();
