#pragma once
#import <Foundation/Foundation.h>
#include <string>
#include <vector>
#import "ImageLoader.h"

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
- (void)sendToLoginPrompt;
- (void)setHeartbeatInterval:(NSInteger)timeMs;
- (void)updateAttachmentByID:(const std::string&)rid;
- (void)onWebsocketFail:(NSValue*)websocketFailNSValue;
- (void)setLoginStage:(NSString*)stage;
- (void)loadedImageFromDataBackgroundThread:(LoadedImage*)loadedImg withAdditData:(NSString*)additData;
- (void)loadImageFromDataBackgroundThread:(NSValue*)attachmentDownloadedParamsNSValue;

@end

NetworkController* GetNetworkController();
