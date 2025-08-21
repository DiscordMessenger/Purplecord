#import "NetworkController.h"
#import "LoginPageController.h"
#include "HTTPClient_iOS.h"
#include "../discord/DiscordInstance.hpp"

NetworkController* g_pNetworkController;
NetworkController* GetNetworkController() {
	return g_pNetworkController;
}

extern LoginPageController* g_pLoginPageController;

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

- (void)processResponse:(NSValue*)netRequestNSValue
{
	NetRequest* netRequest = (NetRequest*) [netRequestNSValue pointerValue];
	
	GetDiscordInstance()->HandleRequest(netRequest);
	
	// TODO
	delete netRequest;
}

@end
