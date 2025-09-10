#include "MessageCache.hpp"
#include "ProfileCache.hpp"
#include "Frontend.hpp"
#include "DiscordInstance.hpp"

constexpr int MESSAGES_PER_REQUEST = 50;

using iprog::JsonObject;
static MessageCache g_MCSingleton;

MessageCache::MessageCache()
{
}

void MessageCache::RefreshChannelMRUQueue(Snowflake channel)
{
	auto iter = std::find(m_mruQueue.begin(), m_mruQueue.end(), channel);
	if (iter != m_mruQueue.end())
		m_mruQueue.erase(iter);
	
	m_mruQueue.push_front(channel);
}

void MessageCache::DropOneChannelFromMRUQueueIfNeeded()
{
	if (m_mruQueue.size() < LOADED_CHANNELS_LIMIT)
		return;
	
	Snowflake sf = m_mruQueue.back();
	m_mapMessages.erase(sf);
}

MessageChunkList* MessageCache::GetChannel(Snowflake channel, bool createIfNeeded)
{
	auto iter = m_mapMessages.find(channel);
	if (iter == m_mapMessages.end())
	{
#ifdef IGNORE_MESSAGES_TO_UNLOADED_CHANNELS
		if (createIfNeeded)
#endif
		{
			// create unconditionally otherwise.  It might be useful.
			DropOneChannelFromMRUQueueIfNeeded();
			return &m_mapMessages[channel];
		}
		
		return nullptr;
	}
	
	RefreshChannelMRUQueue(channel);
	return &iter->second;
}

void MessageCache::GetLoadedMessages(Snowflake channel, Snowflake guild, std::list<MessagePtr>& out)
{
	auto chunkList = GetChannel(channel);
	chunkList->m_guild = guild;

	for (auto& msg : chunkList->m_messages)
		out.push_back(msg.second);
}

void MessageCache::GetLoadedMessages(Snowflake channel, Snowflake guild, std::vector<MessagePtr>& out)
{
	auto chunkList = GetChannel(channel);
	chunkList->m_guild = guild;

	for (auto& msg : chunkList->m_messages)
		out.push_back(msg.second);
}

void MessageCache::ProcessRequest(Snowflake channel, ScrollDir::eScrollDir sd, Snowflake anchor, iprog::JsonObject& j, const std::string& channelName)
{
	auto chunkList = GetChannel(channel);
	chunkList->ProcessRequest(sd, anchor, j, channelName);
}

MessagePtr MessageCache::AddMessage(Snowflake channel, const Message& msg)
{
	auto chunkList = GetChannel(channel, false);
	if (!chunkList) return std::make_shared<Message>(msg);
	
	return chunkList->AddMessage(msg);
}

MessagePtr MessageCache::EditMessage(Snowflake channel, const Message& msg)
{
	auto chunkList = GetChannel(channel, false);
	if (!chunkList) return std::make_shared<Message>(msg);
	
	return chunkList->EditMessage(msg);
}

void MessageCache::DeleteMessage(Snowflake channel, Snowflake msg)
{
	auto chunkList = GetChannel(channel, false);
	if (!chunkList) return;
	
	return chunkList->DeleteMessage(msg);
}

int MessageCache::GetMentionCountSince(Snowflake channel, Snowflake message, Snowflake user)
{
	auto chunkList = GetChannel(channel, false);
	if (!chunkList) return 0;
	
	return chunkList->GetMentionCountSince(message, user);
}

void MessageCache::ClearAllChannels()
{
	m_mapMessages.clear();
}

bool MessageCache::IsMessageLoaded(Snowflake channel, Snowflake message)
{
	auto it = m_mapMessages.find(channel);
	if (it == m_mapMessages.end())
		return false;

	auto& msgs = it->second.m_messages;
	auto it2 = msgs.find(message);
	return it2 != msgs.end();
}

bool MessageCache::IsChannelLoaded(Snowflake channel) const
{
	return m_mapMessages.find(channel) != m_mapMessages.end();
}

MessagePtr MessageCache::GetLoadedMessage(Snowflake channel, Snowflake message)
{
	auto chunkList = GetChannel(channel, false);
	if (!chunkList) return nullptr;
	
	return chunkList->GetLoadedMessage(message);
}

MessageCache* GetMessageCache()
{
	return &g_MCSingleton;
}

MessageChunkList::MessageChunkList()
{
	// Add a single gap message to fetch stuff
	MessagePtr msg = MakeMessage();
	msg->m_type = MessageType::GAP_UP;
	msg->m_anchor = 0;
	msg->m_snowflake = 0;
	msg->m_author = GetFrontend()->GetPleaseWaitText();
	msg->m_message = "";
	msg->m_dateFull = "";
	msg->m_dateCompact = "";
	m_messages[msg->m_snowflake] = msg;
}

void MessageChunkList::ProcessRequest(ScrollDir::eScrollDir sd, Snowflake gap, iprog::JsonObject& j, const std::string& channelName)
{
	Snowflake lowestMsg = (Snowflake) -1LL, highestMsg = 0;

	bool addedMessages = false;

	// remove the anchor
	auto iter = m_messages.find(gap);
	if (iter != m_messages.end())
	{
		if (iter->second->IsLoadGap())
			m_messages.erase(iter);
	}

	// for each message
	int receivedMessages = 0;
	for (auto& data : j)
	{
		auto msg = MakeMessage();
		msg->Load(data, m_guild);

		if (!addedMessages)
		{
			if (m_messages.find(msg->m_snowflake) == m_messages.end())
				addedMessages = true;
		}

		m_messages[msg->m_snowflake] = msg;
		receivedMessages++;

		if (lowestMsg > msg->m_snowflake)
			lowestMsg = msg->m_snowflake;
		if (highestMsg < msg->m_snowflake)
			highestMsg = msg->m_snowflake;
	}

	bool addBefore = sd != ScrollDir::AFTER && receivedMessages >= MESSAGES_PER_REQUEST;
	bool addAfter  = sd != ScrollDir::BEFORE;

	if (receivedMessages < MESSAGES_PER_REQUEST)
	{
		auto msg = MakeMessage();
		msg->m_type = MessageType::CHANNEL_HEADER;
		msg->m_snowflake = 1;
		msg->m_author = channelName;
		m_messages[msg->m_snowflake] = msg;
	}

	if (addBefore && addedMessages)
	{
		auto msg = MakeMessage();
		msg->m_author = GetFrontend()->GetPleaseWaitText();
		msg->m_type = MessageType::GAP_UP;
		msg->m_anchor = lowestMsg;
		msg->m_snowflake = lowestMsg - 1;
		m_messages[msg->m_snowflake] = msg;
	}

	if (addAfter && addedMessages)
	{
		auto msg = MakeMessage();
		msg->m_author = GetFrontend()->GetPleaseWaitText();
		msg->m_type = MessageType::GAP_DOWN;
		msg->m_anchor = highestMsg;
		msg->m_snowflake = highestMsg + 1;
		m_messages[msg->m_snowflake] = std::move(msg);
	}

	GetDiscordInstance()->OnFetchedMessages(gap, sd);
}

MessagePtr MessageChunkList::AddMessage(const Message& msg)
{
	if (msg.m_anchor)
		DeleteMessage(msg.m_anchor);

	auto ptr = std::make_shared<Message>(msg);
	m_messages[msg.m_snowflake] = ptr;
	return ptr;
}

MessagePtr MessageChunkList::EditMessage(const Message& msg)
{
	DeleteMessage(msg.m_snowflake);
	auto ptr = std::make_shared<Message>(msg);
	m_messages[msg.m_snowflake] = ptr;
	return ptr;
}

void MessageChunkList::DeleteMessage(Snowflake message)
{
	auto iter = m_messages.find(message);
	if (m_messages.end() != iter)
		m_messages.erase(iter);
}

int MessageChunkList::GetMentionCountSince(Snowflake message, Snowflake user)
{
	int mentCount = 0;

	for (auto& msg : m_messages)
	{
		if (msg.first < message)
			continue;

		if (msg.second->CheckWasMentioned(user, m_guild))
			mentCount++;
	}

	return mentCount;
}

MessagePtr MessageChunkList::GetLoadedMessage(Snowflake message)
{
	auto iter = m_messages.find(message);
	if (m_messages.end() == iter)
		return nullptr;

	return iter->second;
}
