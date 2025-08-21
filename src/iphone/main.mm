#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include "../discord/Util.hpp"
#include "../discord/LocalSettings.hpp"

#include "HTTPClient_iOS.h"
#include "Frontend_iOS.h"

// HTTP Client
HTTPClient_iOS* g_pHttpClient;
HTTPClient* GetHTTPClient() { return g_pHttpClient; }

// Frontend
Frontend_iOS* g_pFrontend;
Frontend* GetFrontend() { return g_pFrontend; }

int main(int argc, char *argv[])
{
	freopen("/var/mobile/Purplecord.log", "w", stderr);
	
	g_pHttpClient = new HTTPClient_iOS();
	g_pHttpClient->Init();
	g_pFrontend = new Frontend_iOS();
	
	SetBasePath("/var/mobile/Purplecord");
	GetLocalSettings()->Load();
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
	[pool release];
	
	GetLocalSettings()->Save();
	
	g_pHttpClient->StopAllRequests();
	g_pHttpClient->Kill();
	delete g_pHttpClient;
	delete g_pFrontend;
	return retVal;
}
