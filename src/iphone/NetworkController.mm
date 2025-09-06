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

extern LoginPageController* g_pLoginPageController;
extern GuildListController* g_pGuildListController;

@implementation NetworkController

- (instancetype) init
{
	g_pNetworkController = self;
	return self;
}

- (void) dealloc
{
	g_pNetworkController = NULL;
	[super dealloc];
}

- (void)sendToGuildList
{
	if (g_pLoginPageController)
		[g_pLoginPageController sendToGuildList];
	else
		DbgPrintF("ERROR in sendToGuildList: No login page controller.");
}

- (void)refreshGuildList
{
	if (g_pGuildListController)
		[g_pGuildListController refreshGuilds];
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
