#pragma once

#include <map>
#include <list>
#include <vector>
#include "iprogsjson.hpp"
#include "Snowflake.hpp"
#include "ScrollDir.hpp"
#include "Message.hpp"

#ifdef __APPLE__

// to avoid running out of memory, there is a limit of this many channels loaded at once.
#define LOADED_CHANNELS_LIMIT 10

// if a channels is unloaded, ignore MESSAGE_CREATE events
#define IGNORE_MESSAGES_TO_UNLOADED_CHANNELS

#endif

struct MessageChunkList
{
	// int - Offset. How many messages ago was this message posted
	std::map<Snowflake, MessagePtr> m_messages;

	bool m_lastMessagesLoaded = false;
	Snowflake m_guild = 0;

	MessageChunkList();
	void ProcessRequest(ScrollDir::eScrollDir sd, Snowflake anchor, iprog::JsonObject& j, const std::string& channelName);
	MessagePtr AddMessage(const Message& msg);
	MessagePtr EditMessage(const Message& msg);
	void DeleteMessage(Snowflake message);
	int GetMentionCountSince(Snowflake message, Snowflake user);
	MessagePtr GetLoadedMessage(Snowflake message);
};

class MessageCache
{
public:
	MessageCache();
	
	void GetLoadedMessages(Snowflake channel, Snowflake guild, std::list<MessagePtr>& out);
	void GetLoadedMessages(Snowflake channel, Snowflake guild, std::vector<MessagePtr>& out);

	// note: scroll dir used to add gap message
	void ProcessRequest(Snowflake channel, ScrollDir::eScrollDir sd, Snowflake anchor, iprog::JsonObject& j, const std::string& channelName);

	MessagePtr AddMessage(Snowflake channel, const Message& msg);
	MessagePtr EditMessage(Snowflake channel, const Message& msg);
	void DeleteMessage(Snowflake channel, Snowflake message);
	int GetMentionCountSince(Snowflake channel, Snowflake message, Snowflake user);
	void ClearAllChannels();
	bool IsMessageLoaded(Snowflake channel, Snowflake message);
	bool IsChannelLoaded(Snowflake channel) const;

	MessagePtr GetLoadedMessage(Snowflake channel, Snowflake message);

private:
	MessageChunkList* GetChannel(Snowflake channel, bool createIfNeeded = true);
	void RefreshChannelMRUQueue(Snowflake channel);
	void DropOneChannelFromMRUQueueIfNeeded();

	std::map <Snowflake, MessageChunkList> m_mapMessages;
	std::deque<Snowflake> m_mruQueue;
};

MessageCache* GetMessageCache();
