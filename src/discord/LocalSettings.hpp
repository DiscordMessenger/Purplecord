#pragma once

#include <string>
#include <set>
#include <ctime>

class LocalSettings
{
public:
	LocalSettings();

	bool Load();
	bool Save();
	std::string GetToken() const {
		return m_token;
	}
	void SetToken(const std::string& str) {
		m_token = str;
	}
	bool CheckTrustedDomain(const std::string& url);
	
	bool ReplyMentionByDefault() const {
		return m_bReplyMentionDefault;
	}
	void SetReplyMentionByDefault(bool b) {
		m_bReplyMentionDefault = b;
	}
	bool IsFirstStart() const {
		return m_bIsFirstStart;
	}
	const std::string& GetDiscordAPI() const {
		return m_discordApi;
	}
	void SetDiscordAPI(const std::string& str) {
		m_discordApi = str;
	}
	const std::string& GetDiscordCDN() const {
		return m_discordCdn;
	}
	void SetDiscordCDN(const std::string& str) {
		m_discordCdn = str;
	}
	void SetCheckUpdates(bool b) {
		m_bCheckUpdates = b;
		m_bAskToCheckUpdates = false;
	}
	bool CheckUpdates() const {
		if (!m_bCheckUpdates)
			return false;

		return time(NULL) >= m_remindUpdatesOn;
	}
	bool CheckUpdatesOption() const {
		return m_bCheckUpdates;
	}
	bool AskToCheckUpdates() const {
		return m_bAskToCheckUpdates;
	}
	bool EnableTLSVerification() const {
		return m_bEnableTLSVerification;
	}
	void SetEnableTLSVerification(bool b) {
		m_bEnableTLSVerification = b;
	}
	bool AddExtraHeaders() const {
		return m_bAddExtraHeaders;
	}
	void SetAddExtraHeaders(bool b) {
		m_bAddExtraHeaders = b;
	}
	void StopUpdateCheckTemporarily();
	bool DisableFormatting() const {
		return m_bDisableFormatting;
	}
	void SetDisableFormatting(bool b) {
		m_bDisableFormatting = b;
	}
	bool GetCompactMemberList() const {
		return m_bCompactMemberList;
	}
	void SetCompactMemberList(bool b) {
		m_bCompactMemberList = b;
	}
	bool ShowAttachmentImages() const {
		return m_bShowAttachmentImages;
	}
	bool ShowEmbedImages() const {
		return m_bShowEmbedImages;
	}
	bool ShowEmbedContent() const {
		return m_bShowEmbedContent;
	}
	void SetShowAttachmentImages(bool b) {
		m_bShowAttachmentImages = b;
	}
	void SetShowEmbedImages(bool b) {
		m_bShowEmbedImages = b;
	}
	void SetShowEmbedContent(bool b) {
		m_bShowEmbedContent = b;
	}
	bool UseDarkMode() const {
		return m_bUseDarkMode;
	}
	void SetDarkMode(bool b) {
		m_bUseDarkMode = b;
	}

private:
	std::string m_token;
	std::string m_discordApi;
	std::string m_discordCdn;
	std::set<std::string> m_trustedDomains;
	bool m_bReplyMentionDefault = true;
	bool m_bIsFirstStart = false;
	bool m_bCheckUpdates = false;
	bool m_bAskToCheckUpdates = true;
	bool m_bEnableTLSVerification = false;
	bool m_bDisableFormatting = false;
	bool m_bCompactMemberList = false;
	bool m_bAddExtraHeaders = true;
	bool m_bShowAttachmentImages = true;
	bool m_bShowEmbedImages = true;
	bool m_bShowEmbedContent = true;
	time_t m_remindUpdatesOn = 0;
	bool m_bUseDarkMode = false;
};

LocalSettings* GetLocalSettings();
