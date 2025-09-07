#import "NetworkController.h"
#import "LoginPageController.h"
#import "GuildListController.h"

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

@end
