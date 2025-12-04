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

NetworkController* g_pNetworkController;
NetworkController* GetNetworkController() {
	return g_pNetworkController;
}

@implementation NetworkController {
	
	NSTimer* heartbeatTimer;
	
}

- (instancetype) init
{
	g_pNetworkController = self;
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
	
	UIAlertView *alert = [
		[UIAlertView alloc]
		initWithTitle:@"Disconnected"
		message:@"You have been disconnected. Purplecord will attempt to reconnect."
		delegate:self
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil
	];
	
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != alertView.cancelButtonIndex)
		return;
	
	// TODO: Test this
	LoginPageController* controller = [[LoginPageController alloc] init];
	
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

- (void)setLoginStage:(NSString*)stage
{
	if (GetLoginPageController())
		[GetLoginPageController() setLoginStage:stage];
}

- (void)invoke:(NSInvocation *)inv
{
    [inv invoke];
}

- (void)loadImageFromDataMainThread:(UIImage*)himg withAdditData:(NSString*)additData
{
	std::string additDataUTF8(additData ? [additData UTF8String] : "");
	
	[GetAvatarCache() loadedResource:additDataUTF8];
	[GetAvatarCache() setImage:additDataUTF8 image:himg];
	[GetNetworkController() updateAttachmentByID:additDataUTF8];
}

- (void)loadImageFromDataBackgroundThread:(NSValue*)attachmentDownloadedParamsNSValue
{
	AttachmentDownloadedParams* parms = (AttachmentDownloadedParams*) [attachmentDownloadedParamsNSValue pointerValue];
	bool bIsProfilePicture = parms->bIsProfilePicture;
	std::string additData = std::move(parms->additData);
	std::vector<uint8_t> data = std::move(parms->data);
	delete parms;
	
	int nImSize = bIsProfilePicture ? -1 : 0;
	bool bHasAlpha = false;
	
	UIImage* himg = [ImageLoader convertToBitmap:data.data() size:data.size() resizeToWidth:nImSize andHeight:nImSize];

	if (himg)
	{
		SEL sel = @selector(loadImageFromDataMainThread:withAdditData:);
		NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
		
		UIImage* himg2 = himg;
		NSString* str = [NSString stringWithUTF8String:additData.c_str()];
		[invocation setSelector:sel];
		[invocation setTarget:self];
		[invocation setArgument:&himg2 atIndex:2];
		[invocation setArgument:&str atIndex:3];
		[invocation retainArguments];
		
		[self performSelectorOnMainThread:@selector(invoke:) withObject:invocation waitUntilDone:NO];
	}
	
	// store the cached data..
	std::string final_path = GetCachePath() + "/" + additData;
	FILE* f = fopen(final_path.c_str(), "wb");
	if (!f) {
		DbgPrintF("ERROR: Could not open %s for writing", final_path.c_str());
		// TODO: error message
		return;
	}

	fwrite(data.data(), 1, data.size(), f);
	fclose(f);
}

@end
