#import "NetworkController.h"
#import "LoginPageController.h"
#import "GuildListController.h"
#import "ChannelController.h"
#import "AppDelegate.h"
#import "UIColorScheme.h"
#import "AvatarCache.h"
#import "ImageLoader.h"

#include "HTTPClient_curl.h"
#include "Frontend_iOS.h"
#include "../discord/DiscordInstance.hpp"

bool ShouldLogInAgain(int code)
{
	switch (code)
	{
		case 4003: // Not Authenticated
		case 4004: // Authentication Failed
		case 4005: // Already Authenticated
		case 4008: // Rate Limited
		case 4012: // Invalid API Version
		case 4013: // Invalid Intents
		case 4014: // Disallowed Intents
			return false;
	}
	
	return true;
}

NetworkController* g_pNetworkController;
NetworkController* GetNetworkController() {
	return g_pNetworkController;
}

@implementation NetworkController {
	
	NSTimer* heartbeatTimer;
	BOOL shouldLogInAgain;
	
}

- (instancetype) init
{
	g_pNetworkController = self;
	shouldLogInAgain = true;
	return self;
}

- (void)dealloc
{
	g_pNetworkController = NULL;
	
	if (heartbeatTimer != nil) {
		[heartbeatTimer invalidate];
		[heartbeatTimer release];
		heartbeatTimer = nil;
	}
	
	[super dealloc];
}

- (void)heartbeatTimerFired:(NSTimer*)timer
{
	GetDiscordInstance()->SendHeartbeat();
}

- (void)setHeartbeatInterval:(NSInteger)timeMs
{
	if (heartbeatTimer != nil) {
		[heartbeatTimer invalidate];
		[heartbeatTimer release];
		heartbeatTimer = nil;
	}
	
	heartbeatTimer = [[
		NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(timeMs / 1000.0)
		target:self
		selector:@selector(heartbeatTimerFired:)
		userInfo:nil
		repeats:YES
	] retain];
}

- (void)finishedProcessingHugeMessage
{
	GetDiscordInstance()->FinishedProcessingHugeMessage();
}

- (void)onConnected
{
	if (GetLoginPageController())
		[GetLoginPageController() sendToGuildList];
	else
		DbgPrintF("ERROR in sendToGuildList: No login page controller.");
}

- (void)refreshGuildList
{
	if (GetGuildListController())
		[GetGuildListController() refreshGuilds];
	else
		DbgPrintF("ERROR in refreshGuildList: No guild list controller.");
}

- (void)updateAttachmentByID:(const std::string&)rid
{
	if (GetGuildListController())
		[GetGuildListController() updateAttachmentByID:rid];

	if (GetChannelController())
		[GetChannelController() updateAttachmentByID:rid];
}

- (void)processResponse:(NSValue*)netRequestNSValue
{
	NetRequest* netRequest = (NetRequest*) [netRequestNSValue pointerValue];
	
	GetDiscordInstance()->HandleRequest(netRequest);
	
	delete netRequest;
}

- (void)processWebsocketMessage:(NSValue*)websocketMessageNSValue
{
	WebsocketMessage* message = (WebsocketMessage*) [websocketMessageNSValue pointerValue];
	
	if (GetDiscordInstance()->GetGatewayID() == message->gatewayId)
		GetDiscordInstance()->HandleGatewayMessage(message->msg);
	
	delete message;
}

- (void)onWebsocketFail:(NSValue*)websocketFailNSValue
{
	WebsocketFailParams* parms = (WebsocketFailParams*) [websocketFailNSValue pointerValue];
	
	shouldLogInAgain = ShouldLogInAgain(parms->errorCode);
	
	char buffer[512];
	snprintf(
		buffer,
		sizeof buffer,
		"You have been disconnected. %s\n\nError code: %d",
		shouldLogInAgain ? "Purplecord will attempt to reconnect." : "You will most likely need to fix/retype your token.",
		parms->errorCode
	);
	NSString* nsString = [NSString stringWithUTF8String:buffer];
	
	UIAlertView *alert = [
		[UIAlertView alloc]
		initWithTitle:@"Disconnected"
		message:nsString
		delegate:self
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil
	];
	
	[alert show];
	[alert release];
}

- (void)sendToLoginPrompt
{
	LoginPageController* controller = [[LoginPageController alloc] initWithReconnectFlag:shouldLogInAgain];
	controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
	UINavigationController *navController = appDelegate.navController;
	
	[navController setViewControllers:@[controller] animated:NO];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	
	[UIView
		setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
		forView:navController.view
		cache:YES];
	
	[UIView commitAnimations];
	
	[controller release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self sendToLoginPrompt];
}

- (void)setLoginStage:(NSString*)stage
{
	if (GetLoginPageController())
		[GetLoginPageController() setLoginStage:stage];
}

- (void)invoke:(NSInvocation *)inv
{
    [inv invoke];
}

- (void)loadedImageFromDataMainThread:(NSValue*)loadedImgValue withAdditData:(NSString*)additData
{
	LoadedImage* loadedImg = (LoadedImage*) [loadedImgValue pointerValue];
	UIImage* image = loadedImg->ToUIImage();
	
	if (!image) {
		DbgPrintF("error converting LoadedImage to UIImage");
		return;
	}
	
	std::string additDataUTF8(additData ? [additData UTF8String] : "");
	
	[GetAvatarCache() loadedResource:additDataUTF8];
	[GetAvatarCache() setImage:additDataUTF8 image:image];
	[GetNetworkController() updateAttachmentByID:additDataUTF8];
}

- (void)loadedImageFromDataBackgroundThread:(LoadedImage*)loadedImg withAdditData:(NSString*)additData
{
	SEL sel = @selector(loadedImageFromDataMainThread:withAdditData:);
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
	NSValue* loadedImgValue = [NSValue valueWithPointer:loadedImg];
	
	[invocation setSelector:sel];
	[invocation setTarget:self];
	[invocation setArgument:&loadedImgValue atIndex:2];
	[invocation setArgument:&additData atIndex:3];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(invoke:) withObject:invocation waitUntilDone:YES];
}

- (void)loadImageFromDataBackgroundThread:(NSValue*)attachmentDownloadedParamsNSValue
{
@autoreleasepool {
	AttachmentDownloadedParams* parms = (AttachmentDownloadedParams*) [attachmentDownloadedParamsNSValue pointerValue];
	bool bIsProfilePicture = parms->bIsProfilePicture;
	std::string additData = std::move(parms->additData);
	std::vector<uint8_t> data = std::move(parms->data);
	delete parms;
	
	int nImSize = bIsProfilePicture ? -1 : 0;
	bool bHasAlpha = false;
	
	UIImage* himg = nil;
	LoadedImage* loadedImg = ImageLoader::ConvertToBitmap(data.data(), data.size(), nImSize, nImSize);
	data.clear();
	
	if (!loadedImg)
		return;
	
	[self loadedImageFromDataBackgroundThread:loadedImg withAdditData:[NSString stringWithUTF8String:additData.c_str()]];
	
	// Write the pre-processed data to cache to load it faster
	loadedImg->Save(GetCachePath() + "/" + additData);
	delete loadedImg;
}
}

@end
