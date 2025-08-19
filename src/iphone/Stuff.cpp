#include "../discord/DiscordInstance.hpp"
#include "Frontend_iOS.h"

Frontend_iOS* g_pFrontEnd;
DiscordInstance* g_pDiscordInstance;

Frontend* GetFrontend()
{
	return g_pFrontEnd;
}

DiscordInstance* GetDiscordInstance()
{
	return g_pDiscordInstance;
}
