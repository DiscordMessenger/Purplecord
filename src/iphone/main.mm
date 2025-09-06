#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include <sys/stat.h>

#include "../discord/Util.hpp"
#include "../discord/LocalSettings.hpp"
#include "../discord/DiscordInstance.hpp"
#include "../discord/WebsocketClient.hpp"

#include "HTTPClient_curl.h"
#include "Frontend_iOS.h"

// HTTP Client
HTTPClient_curl* g_pHttpClient;
HTTPClient* GetHTTPClient() { return g_pHttpClient; }

// Frontend
Frontend_iOS* g_pFrontend;
Frontend* GetFrontend() { return g_pFrontend; }

// DiscordInstance
DiscordInstance* g_pDiscordInstance;
DiscordInstance* GetDiscordInstance() { return g_pDiscordInstance; }

void CreateDiscordInstanceIfNeeded()
{
	if (g_pDiscordInstance)
		delete g_pDiscordInstance;
	
	g_pDiscordInstance = new DiscordInstance(GetLocalSettings()->GetToken());
}

int main(int argc, char *argv[])
{
	HTTPClient_curl::InitializeCABlob();
	freopen("/var/mobile/Purplecord.log", "w", stderr);
	
	g_pHttpClient = new HTTPClient_curl();
	g_pHttpClient->Init();
	g_pFrontend = new Frontend_iOS();
	
	mkdir("/var/mobile/Documents/Purplecord", 0775);
	mkdir("/var/mobile/Documents/Purplecord/cache", 0775);
	SetBasePath("/var/mobile/Documents/Purplecord");
	GetLocalSettings()->Load();
	
	GetWebsocketClient()->Init();
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
	[pool release];
	
	GetLocalSettings()->Save();
	
	g_pHttpClient->StopAllRequests();
	g_pHttpClient->Kill();
	
	if (g_pDiscordInstance)
		delete g_pDiscordInstance;
	
	delete g_pHttpClient;
	delete g_pFrontend;
	return retVal;
}
