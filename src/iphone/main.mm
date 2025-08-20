#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include "../discord/Util.hpp"
#include "../discord/LocalSettings.hpp"

#include "HTTPClient_iOS.h"

// HTTP Client
HTTPClient_iOS* g_pHttpClient;

HTTPClient* GetHTTPClient()
{
	return g_pHttpClient;
}

// Testing Stuff
extern "C" void ShowModalTest(const char* msg);

void TestingCallback(NetRequest* pRequest)
{
	std::string finalString = "RESULT:" + std::to_string(pRequest->result) + "\nRESPONSE:" + pRequest->response;
	
	ShowModalTest(finalString.c_str());
}

extern "C" void TestFunction()
{
	GetHTTPClient()->PerformRequest(
		true,
		NetRequest::GET,
		"https://discord.com/api/v9/gateway",
		0,
		0,
		"",
		"",
		"",
		TestingCallback,
		nullptr,
		0
	);
}

int main(int argc, char *argv[])
{
	freopen("/var/mobile/Purplecord.log", "w", stderr);
	
	g_pHttpClient = new HTTPClient_iOS();
	g_pHttpClient->Init();
	
	SetBasePath("/var/mobile/Purplecord");
	GetLocalSettings()->Load();
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
	[pool release];
	
	GetLocalSettings()->Save();
	
	g_pHttpClient->StopAllRequests();
	g_pHttpClient->Kill();
	return retVal;
}
