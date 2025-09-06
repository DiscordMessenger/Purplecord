#include "Frontend_iOS.h"
#import "NetworkController.h"

void Frontend_iOS::OnRequestDone(NetRequest* pRequest)
{
	@autoreleasepool {
		[GetNetworkController() performSelectorOnMainThread:@selector(processResponse:)
			withObject:[NSValue valueWithPointer:pRequest]
			waitUntilDone:NO];
	}
}

void Frontend_iOS::OnWebsocketMessage(int gatewayID, const std::string& payload)
{
	@autoreleasepool {
		WebsocketMessage* message = new WebsocketMessage;
		message->gatewayId = gatewayID;
		message->msg = payload;
		
		[GetNetworkController() performSelectorOnMainThread:@selector(processWebsocketMessage:)
			withObject:[NSValue valueWithPointer:message]
			waitUntilDone:NO];
	}
}

void Frontend_iOS::OnConnected()
{
	// N.B. This is run from main thread.
	[GetNetworkController() sendToGuildList];
}

void Frontend_iOS::RepaintGuildList()
{
	[GetNetworkController() refreshGuildList];
}

std::string Frontend_iOS::GetDirectMessagesText()
{
	return "Direct Messages";
}

std::string Frontend_iOS::GetPleaseWaitText()
{
	return "Please wait...";
}

std::string Frontend_iOS::GetMonthName(int index)
{
	static const char* const monthNames[] = {
		"January",
		"February",
		"March",
		"April",
		"May",
		"June",
		"July",
		"August",
		"September",
		"October",
		"November",
		"December"
	};
	
	if (index < 0 || index >= 12)
		return "Month-" + std::to_string(index);
	
	return std::string(monthNames[index]);
}

std::string Frontend_iOS::GetTodayAtText()
{
	return "Today at %H:%M";
}

std::string Frontend_iOS::GetYesterdayAtText()
{
	return "Yesterday at %H:%M";
}

std::string Frontend_iOS::GetFormatDateOnlyText()
{
	return "%s %d%s, %d";
}

std::string Frontend_iOS::GetFormatTimeLongText()
{
	return "%d-%m-%Y at %H:%M";
}

std::string Frontend_iOS::GetFormatTimeShortText()
{
	return "%d/%m %H:%M";
}

std::string Frontend_iOS::GetFormatTimeShorterText()
{
	return "%d/%m %H:%M";
}

#ifdef USE_DEBUG_PRINTS
void Frontend_iOS::DebugPrint(const char* fmt, va_list vl)
{
	vfprintf(stderr, fmt, vl);
	fprintf(stderr, "\n");
	fflush(stderr);
}
#endif

void Frontend_iOS::OnLoginAgain()
{
	//TODO
}

void Frontend_iOS::OnLoggedOut()
{
	//TODO
}

void Frontend_iOS::OnSessionClosed(int errorCode)
{
	//TODO
}

void Frontend_iOS::OnConnecting()
{
	//TODO
}

void Frontend_iOS::OnAddMessage(Snowflake channelID, const Message& msg)
{
	//TODO
}

void Frontend_iOS::OnUpdateMessage(Snowflake channelID, const Message& msg)
{
	//TODO
}

void Frontend_iOS::OnDeleteMessage(Snowflake messageInCurrentChannel)
{
	//TODO
}

void Frontend_iOS::OnStartTyping(Snowflake userID, Snowflake guildID, Snowflake channelID, time_t startTime)
{
	//TODO
}

void Frontend_iOS::OnLoadedPins(Snowflake channel, const std::string& data)
{
	//TODO
}

void Frontend_iOS::OnUpdateAvailable(const std::string& url, const std::string& version)
{
	//TODO
}

void Frontend_iOS::OnFailedToSendMessage(Snowflake channel, Snowflake message)
{
	//TODO
}

void Frontend_iOS::OnFailedToUploadFile(const std::string& file, int error)
{
	//TODO
}

void Frontend_iOS::OnFailedToCheckForUpdates(int result, const std::string& response)
{
	//TODO
}

void Frontend_iOS::OnStartProgress(Snowflake key, const std::string& fileName, bool isUploading)
{
	//TODO
}

bool Frontend_iOS::OnUpdateProgress(Snowflake key, size_t offset, size_t length)
{
	//TODO
	return false;
}

void Frontend_iOS::OnStopProgress(Snowflake key)
{
	//TODO
}

void Frontend_iOS::OnNotification()
{
	//TODO
}

void ShowMessageBox(const std::string& title, const std::string& message)
{
	DbgPrintF("ShowMessageBox(\"%s\", \"%s\")", title.c_str(), message.c_str());
	
	NSString *nsMessage = [NSString stringWithUTF8String:message.c_str()];
	NSString *nsTitle = [NSString stringWithUTF8String:title.c_str()];
	
	// Create and show alert (UIAlertView is deprecated, but here’s the classic form)
	UIAlertView *alert = [
		[UIAlertView alloc]
		initWithTitle:nsTitle
		message:nsMessage
		delegate:nil
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil
	];
	
	[alert show];
	[alert release];
}

void Frontend_iOS::OnGenericError(const std::string& message)
{
	ShowMessageBox("Generic Error", message);
}

void Frontend_iOS::OnJsonException(const std::string& message)
{
	ShowMessageBox("JSON Exception", message);
}

void Frontend_iOS::OnCantViewChannel(const std::string& channelName)
{
	ShowMessageBox(channelName, "You cannot view this channel.");
}

void Frontend_iOS::OnGatewayConnectFailure()
{
	ShowMessageBox("Gateway Connect Failure", "Failed to connect to gateway. I don't know why.");
}

void Frontend_iOS::OnProtobufError(Protobuf::ErrorCode code)
{
	ShowMessageBox("Protobuf Error", "Error code " + std::to_string(code));
}

void Frontend_iOS::OnAttachmentDownloaded(bool bIsProfilePicture, const uint8_t* pData, size_t nSize, const std::string& additData)
{
	//TODO
}

void Frontend_iOS::OnAttachmentFailed(bool bIsProfilePicture, const std::string& additData)
{
	//TODO
}

void Frontend_iOS::UpdateSelectedGuild()
{
	//TODO
}

void Frontend_iOS::UpdateSelectedChannel()
{
	//TODO
}

void Frontend_iOS::UpdateChannelList()
{
	//TODO
}

void Frontend_iOS::UpdateMemberList()
{
	//TODO
}

void Frontend_iOS::UpdateChannelAcknowledge(Snowflake channelID, Snowflake messageID)
{
	//TODO
}

void Frontend_iOS::UpdateProfileAvatar(Snowflake userID, const std::string& resid)
{
	//TODO
}

void Frontend_iOS::UpdateProfilePopout(Snowflake userID)
{
	//TODO
}

void Frontend_iOS::UpdateUserData(Snowflake userID)
{
	//TODO
}

void Frontend_iOS::UpdateAttachment(Snowflake attID)
{
	//TODO
}

void Frontend_iOS::RepaintProfile()
{
	//TODO
}

void Frontend_iOS::RepaintProfileWithUserID(Snowflake id)
{
	//TODO
}

void Frontend_iOS::RefreshMessages(ScrollDir::eScrollDir sd, Snowflake gapCulprit)
{
	//TODO
}

void Frontend_iOS::RefreshMembers(const std::set<Snowflake>& members)
{
	//TODO
}

void Frontend_iOS::JumpToMessage(Snowflake messageInCurrentChannel)
{
	//TODO
}

void Frontend_iOS::OnWebsocketClose(int gatewayID, int errorCode, const std::string& message)
{
	//TODO
}

void Frontend_iOS::OnWebsocketFail(int gatewayID, int errorCode, const std::string& message, bool isTLSError, bool mayRetry)
{
	//TODO
}

void Frontend_iOS::SetHeartbeatInterval(int timeMs)
{
	//TODO
}

void Frontend_iOS::LaunchURL(const std::string& url)
{
	//TODO
}

void Frontend_iOS::RegisterIcon(Snowflake sf, const std::string& avatarlnk)
{
	//TODO
}

void Frontend_iOS::RegisterAvatar(Snowflake sf, const std::string& avatarlnk)
{
	//TODO
}

void Frontend_iOS::RegisterAttachment(Snowflake sf, const std::string& avatarlnk)
{
	//TODO
}

void Frontend_iOS::RegisterChannelIcon(Snowflake sf, const std::string& avatarlnk)
{
	//TODO
}

void Frontend_iOS::RequestQuit()
{
	//TODO
}

void Frontend_iOS::HideWindow()
{
	//TODO
}

void Frontend_iOS::RestoreWindow()
{
	//TODO
}

void Frontend_iOS::MaximizeWindow()
{
	//TODO
}

bool Frontend_iOS::IsWindowMinimized()
{
	return false;
}

int Frontend_iOS::GetMinimumWidth()
{
	//TODO
	return 0;
}

int Frontend_iOS::GetMinimumHeight()
{
	//TODO
	return 0;
}

int Frontend_iOS::GetDefaultWidth()
{
	//TODO
	return 0;
}

int Frontend_iOS::GetDefaultHeight()
{
	//TODO
	return 0;
}

bool Frontend_iOS::UseGradientByDefault()
{
	//TODO
	return false;
}
