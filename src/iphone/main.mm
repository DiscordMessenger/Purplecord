#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include "HTTPClient_iOS.h"

HTTPClient_iOS* g_pHttpClient;

HTTPClient* GetHTTPClient()
{
	return g_pHttpClient;
}

void TestingCallback(NetRequest* pRequest)
{
	std::string finalString = "RESULT:" + std::to_string(pRequest->result) + "\nRESPONSE:" + pRequest->response;
	
	FILE* f = fopen("/var/mobile/Media/yousuck.txt", "w");
	fprintf(f, "%s", finalString.c_str());
	fclose(f);
}

extern "C" void TestFunction()
{
	GetHTTPClient()->PerformRequest(
		true,
		NetRequest::GET,
		"http://example.com",
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
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
	[pool release];
	
	g_pHttpClient->StopAllRequests();
	g_pHttpClient->Kill();
	return retVal;
}
