#import "NetworkController.h"
#import "LoginPageController.h"
#include "HTTPClient_iOS.h"
#include "../discord/DiscordRequest.hpp"
#include "../discord/Util.hpp"

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
	
	switch (netRequest->itype)
	{
		case DiscordRequest::GATEWAY:
		{
			LoginPageController* login = g_pLoginPageController;
			if (!login)
				break;
			
			login.navigationItem.rightBarButtonItem.title = [NSString stringWithUTF8String:netRequest->response.c_str()];
			
			break;
		}
	}
	
	// TODO
	delete netRequest;
}

@end
