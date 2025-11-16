#include <fstream>
#include "iprogsjson.hpp"
#include "LocalSettings.hpp"
#include "Util.hpp"
#include "DiscordAPI.hpp"
#include "Frontend.hpp"
using iprog::JsonObject;

static LocalSettings* g_pInstance;

LocalSettings* GetLocalSettings()
{
	if (!g_pInstance)
		g_pInstance = new LocalSettings;

	return g_pInstance;
}

LocalSettings::LocalSettings()
{
	// Add some default trusted domains:
	m_trustedDomains.insert("discord.gg");
	m_trustedDomains.insert("discord.com");
	m_trustedDomains.insert("discordapp.com");
	m_trustedDomains.insert("canary.discord.com");
	m_trustedDomains.insert("canary.discordapp.com");
	m_trustedDomains.insert("cdn.discord.com");
	m_trustedDomains.insert("cdn.discordapp.com");
	m_trustedDomains.insert("media.discordapp.net");

	m_discordApi = OFFICIAL_DISCORD_API;
	m_discordCdn = OFFICIAL_DISCORD_CDN;
}

bool LocalSettings::Load()
{
	m_bIsFirstStart = false;

	std::string data = LoadEntireTextFile(GetBasePath() + "/settings.json");

	if (data.empty()) {
		// ok, check if settings.jso (8.3) exists at least
		data = LoadEntireTextFile(GetBasePath() + "/settings.jso");

		if (data.empty()) {
			m_bIsFirstStart = true;
			return false;
		}
	}

	auto j = iprog::JsonParser::parse(data);

	// Load properties from the json object.
	if (j.contains("Token"))
		m_token = j["Token"];

	if (j.contains("DiscordAPI"))
		m_discordApi = j["DiscordAPI"];

	if (j.contains("TrustedDomains")) {
		for (auto& dom : j["TrustedDomains"])
			m_trustedDomains.insert(dom);
	}

	if (j.contains("ReplyMentionDefault"))
		m_bReplyMentionDefault = j["ReplyMentionDefault"];

	if (j.contains("EnableTLSVerification"))
		m_bEnableTLSVerification = j["EnableTLSVerification"];

	if (j.contains("DisableFormatting"))
		m_bDisableFormatting = j["DisableFormatting"];

	if (j.contains("CompactMemberList"))
		m_bCompactMemberList = j["CompactMemberList"];

	if (j.contains("ShowAttachmentImages"))
		m_bShowAttachmentImages = j["ShowAttachmentImages"];

	if (j.contains("ShowEmbedImages"))
		m_bShowEmbedImages = j["ShowEmbedImages"];

	if (j.contains("ShowEmbedContent"))
		m_bShowEmbedContent = j["ShowEmbedContent"];

	if (j.contains("UseDarkMode"))
		m_bUseDarkMode = j["UseDarkMode"];

	if (j.contains("CheckUpdates")) {
		m_bCheckUpdates = j["CheckUpdates"];
		m_bAskToCheckUpdates = false;
	}
	else {
		m_bAskToCheckUpdates = true;
	}

	if (j.contains("RemindUpdateCheckOn"))
		m_remindUpdatesOn = (time_t) (long long) j["RemindUpdateCheckOn"];

	if (j.contains("AddExtraHeaders"))
		m_bAddExtraHeaders = j["AddExtraHeaders"];
	return true;
}

bool LocalSettings::Save()
{
	iprog::JsonObject j;
	iprog::JsonObject trustedDomains;

	for (auto& dom : m_trustedDomains)
		trustedDomains.push_back(dom);

	j["Token"] = m_token;
	j["DiscordAPI"] = m_discordApi;
	j["TrustedDomains"] = trustedDomains;
	j["ReplyMentionDefault"] = m_bReplyMentionDefault;
	j["CheckUpdates"] = m_bCheckUpdates;
	j["EnableTLSVerification"] = m_bEnableTLSVerification;
	j["DisableFormatting"] = m_bDisableFormatting;
	j["CompactMemberList"] = m_bCompactMemberList;
	j["RemindUpdateCheckOn"] = (long long)(m_remindUpdatesOn);
	j["AddExtraHeaders"] = m_bAddExtraHeaders;
	j["ShowAttachmentImages"] = m_bShowAttachmentImages;
	j["ShowEmbedImages"] = m_bShowEmbedImages;
	j["ShowEmbedContent"] = m_bShowEmbedContent;
	j["UseDarkMode"] = m_bUseDarkMode;

	// save the file
	std::string fileName = GetBasePath() + "/settings.json";
	std::ofstream of(fileName.c_str(), std::ios::trunc);

	if (!of.is_open())
	{
		DbgPrintF("ERROR: Cannot save settings to '%s'!", fileName.c_str());
		perror("Saving Settings");
		return false;
	}

	of << j.dump();
	of.close();

	return true;
}

bool LocalSettings::CheckTrustedDomain(const std::string& url)
{
	// check if the domain belongs to the trusted list
	std::string domain, resource;
	SplitURL(url, domain, resource);
	return m_trustedDomains.find(domain) != m_trustedDomains.end();
}

void LocalSettings::StopUpdateCheckTemporarily()
{
	m_remindUpdatesOn = time(NULL) + time_t(72LL * 60 * 60);
}
