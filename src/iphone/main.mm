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

std::string GetBasePathFromIPhoneOS()
{
	@autoreleasepool
	{
		NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
		std::string str([path UTF8String]);
		DbgPrintF("Base path is %s\n", str.c_str());
		return str;
	}
}

void PrepareSaveDirectories()
{
	int ret;
	
	//std::string path = "/var/mobile/Documents";
	std::string path = GetBasePathFromIPhoneOS();
	
	SetBasePath(path);
	
	// make sure that path exists
	ret = mkdir(path.c_str(), 0775);
	
	ret = mkdir(GetBasePath().c_str(), 0775);
	if (ret == -1 && errno != EEXIST) goto error;
	
	ret = mkdir(GetCachePath().c_str(), 0775);
	if (ret == -1 && errno != EEXIST) goto error;
	
	return;
error:
	DbgPrintF("ERROR: Cannot create directories for Purplecord: %s\nYou will likely be unable to save.", strerror(errno));
}

int main(int argc, char *argv[])
{
	g_pFrontend = new Frontend_iOS();
	
#ifdef _DEBUG
	freopen("/var/mobile/Purplecord.log", "w", stderr);
	DbgPrintF("Purplecord v%.2f - Copyright (C) 2025 iProgramInCpp", GetAppVersion());
#endif
	
	PrepareSaveDirectories();
	GetLocalSettings()->Load();
	
	HTTPClient_curl::InitializeCABlob();
	
	g_pHttpClient = new HTTPClient_curl();
	g_pHttpClient->Init();
	
	GetWebsocketClient()->Init();
	
	int retVal;
	@autoreleasepool
	{
		retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
	}
	
	GetLocalSettings()->Save();
	
	g_pHttpClient->StopAllRequests();
	g_pHttpClient->Kill();
	GetWebsocketClient()->Kill();
	
	if (g_pDiscordInstance)
		delete g_pDiscordInstance;
	
	delete g_pHttpClient;
	delete g_pFrontend;
	return retVal;
}

#ifndef IPHONE_OS_3

int ScaleByDPI(int size)
{
	return (int)(size * [[UIScreen mainScreen] scale]);
}

int UnscaleByDPI(int size)
{
	float scale = [[UIScreen mainScreen] scale];
	return (int) ceilf(size / scale);
}

#endif
