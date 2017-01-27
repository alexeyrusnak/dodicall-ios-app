/*
    Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
*/
//  This file is part of dodicall.
//  dodicall is free software : you can redistribute it and / or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  dodicall is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with dodicall.If not, see <http://www.gnu.org/licenses/>.

#pragma once

#include "ApplicationBaseApi.h"
#include "ApplicationMessengerApi.h"
#include "ApplicationVoipApi.h"
#include "ApplicationContactsApi.h"
#include "ApplicationServerApi.h"

#include "ChatModel.h"
#include "ChatMessageModel.h"

#include "ResultTypes.h"
#include "Singleton.h"
#include "DateTimeUtils.h"

namespace dodicall
{

using namespace model;
using namespace results;

class DODICALLLOGICAPI Application: public Singleton<Application> 
	, virtual public ApplicationBaseApi
	, virtual public ApplicationVoipApi
	, virtual public ApplicationMessengerApi
	, virtual public ApplicationContactsApi
	, virtual public ApplicationServerApi
{
private:
	boost::mutex mNetworkMutex;
	ContactModel mPusher;

	bool mChatReconnectedAfterResume;

public:
	void SendReadyForCallAfterStart(const std::string& pusherSipNumber);

	BaseResult Login(const std::string& login, const std::string& password, int area);
	bool TryAutoLogin(void);
	void Logout(void);

	bool IsLoggedIn(void) const;

	ContactModel GetAccountData(bool format = true);

	bool SaveUserSettings(const UserSettingsModel& settings);
	bool SaveUserSettings(const char *key, const char *value);
	bool SaveUserSettings(const char *key, int value);

	void ChangeCodecSettings(const CodecSettingsList& settings);

	void SetNetworkTechnology(NetworkTechnology technology);

    bool GetAllChats(ChatModelSet& result);
	bool GetChatsByIds(const ChatIdSet& ids, ChatModelSet& result);
    bool GetChatMessages(const ChatIdType& chatId, ChatMessageModelSet& result);
	bool GetMessagesByIds(const ChatMessageIdSet& ids, ChatMessageModelSet& result);
    bool GetChatMessagesPaged(const ChatIdType& chatId, int pageSize, ChatMessageIdType const &lastMsgId, ChatMessageModelList& result);

    bool CreateChatWithContacts(const ContactModelSet& contacts, ChatModel& result);
	ChatIdType InviteAndRevokeChatMembers(const char* roomJid, const ContactModelSet& inviteList, const ContactModelSet& revokeList);

	void Pause(void);
	void Resume(void);
    
    BaseResult FindContactsInDirectory(ContactModelSet& result, const char* searchPath);
    
    bool DeleteContact(ContactModel contact);

protected:
	virtual void ChangeChatNetworkStatus(bool value);
	virtual void ChangeVoipNetworkStatus(bool value);

	virtual void RecallToContact(const ContactModel& contact);

private:
	Application();

	ChatModel DbChatToChatModel(const ChatDbModel& dbchat, bool withMe = false, ContactByXmppIdCachePtr contactsCache = ContactByXmppIdCachePtr(), const ChatMessageDbModelSet& lastMessages = ChatMessageDbModelSet());
	void DbChatSetToChatModelSet(const ChatDbModelSet& dbchats, ChatModelSet& result, bool itIsAll = false);

	ChatMessageModel DbMessageToChatMessageModel(const ChatMessageDbModel& dbmessage, ContactByXmppIdCache& contactsCache);
	void DbMessageSetToChatMessageSet(const ChatMessageDbModelSet& dbmessages, ChatMessageModelSet& result);

	bool StartBackgroundLogin(const std::string& login, const std::string& password, int area, bool accountDataNeeded);

	void SendReadyForCallIfNeeded(void);

	void CyclicUpdateChecker(void);

	friend class Singleton<Application>;

	template <class INCONT, class OUTCONT> void DbMessageContToChatMessageCont(const INCONT& dbmessages, OUTCONT& result)
	{
		ContactByXmppIdCache contactsCache;
		this->PrepareContactsCache(contactsCache, [dbmessages](ContactXmppIdSet& contactXmppIds)
		{
			for (auto iter = dbmessages.begin(); iter != dbmessages.end(); iter++)
				contactXmppIds.insert(iter->Sender);
		});
		for (auto iter = dbmessages.begin(); iter != dbmessages.end(); iter++)
			std::inserter(result, result.end()) = this->DbMessageToChatMessageModel(*iter, contactsCache);
	}

	template <class F> void PrepareContactsCache(ContactByXmppIdCache& cache, F xmppIdsRetrieverFunc)
	{
		ContactXmppIdSet contactXmppIds;
		xmppIdsRetrieverFunc(contactXmppIds);
		ContactModelSet contacts;
		this->GetContactsByXmppIds(contactXmppIds, contacts);
		for (auto iter = contacts.begin(); iter != contacts.end(); iter++)
			cache[iter->GetXmppId()] = *iter;
	}
};

}
