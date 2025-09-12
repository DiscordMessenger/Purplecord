#import "NetworkController.h"
#import "LoginPageController.h"
#import "GuildListController.h"
#import "ChannelController.h"
#import "UIColorScheme.h"

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
	UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
	
	if ([UIColorScheme useDarkMode])
		navController.navigationBar.barStyle = UIBarStyleBlack;
	
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
	
    NSArray *oldSubviews = [[window.subviews copy] autorelease];
	
	[window addSubview:navController.view];
	[window makeKeyAndVisible];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:YES];
	
    for (UIView *v in oldSubviews) {
        [v removeFromSuperview];
    }
	
	[UIView commitAnimations];
}

- (void)setLoginStage:(NSString*)stage
{
	if (GetLoginPageController())
		[GetLoginPageController() setLoginStage:stage];
}

@end
