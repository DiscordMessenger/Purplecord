#import <UIKit/UIKit.h>
#include <string>
#include "../discord/Util.hpp"
#include <sys/types.h>
#include <sys/sysctl.h>

std::string GetIDeviceModel()
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = new char[size + 1];
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	std::string str(machine);
	delete[] machine;
	return str;
}

bool IsSlowIDevice()
{
	std::string ideviceModel = GetIDeviceModel();
	
	// iPhone 1, iPhone 3G, iPod Touch 1 and iPod Touch 2 are deemed "slow" devices.
	//
	// Not that the iPhone 3GS, iPod Touch 3 and iPad 1 are terribly fast devices,
	// but infinitely faster than these.
	return BeginsWith(ideviceModel, "iPhone1,") || BeginsWith(ideviceModel, "iPod1,") || BeginsWith(ideviceModel, "iPod2,");
}

bool IsIPad()
{
#ifdef IPHONE_OS_3
	return BeginsWith(GetIDeviceModel(), "iPad");
#else
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
#endif
}
