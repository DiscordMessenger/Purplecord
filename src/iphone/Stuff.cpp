#include "../discord/DiscordInstance.hpp"
#include "Frontend_iOS.h"

DiscordInstance* g_pDiscordInstance;

DiscordInstance* GetDiscordInstance()
{
	return g_pDiscordInstance;
}
