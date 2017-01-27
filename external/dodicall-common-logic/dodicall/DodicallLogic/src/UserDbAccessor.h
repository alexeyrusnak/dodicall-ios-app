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

#include "DBAccessor.h"

#include "UserSettingsModel.h"
#include "ContactModel.h"
#include "ChatDbModel.h"
#include "CallModel.h"
#include "CallHistoryModel.h"

namespace dodicall
{

using namespace dbmodel;

class UserDbAccessor: public DbAccessor
{
public:
	UserDbAccessor(void);
	~UserDbAccessor(void);

	UserSettingsModel GetUserSettings(UserSettingsModel defValues = UserSettingsModel()) const;
	bool SaveUserSettings(const UserSettingsModel& settings);

	bool GetAllContacts(ContactModelSet& result) const;
	ContactModel GetContactById(ContactIdType id) const;
	ContactModel GetContactByDodicallId(const ContactDodicallIdType& id) const;
	ContactModel GetContactByXmppId(const ContactXmppIdType& xmppId) const;
	bool GetContactsByXmppIds(const ContactXmppIdSet& xmppIds, ContactModelSet& result) const;
	ContactModel GetAccountData() const;

	bool SaveContact(ContactModel& contact);
	bool DeleteContact(ContactModel& contact);

	bool SaveContactInCache(ContactModel contact);

	bool OptimizeContactsCache(void);

	bool GetAllNativeContacts(ContactModelSet& nativeContacts);
	bool GetUnsynchronizedNativeContacts(ContactModelSet& unsinchronizedContacts) const;
	bool GetDirectoryContacts(ContactModelSet& contacts) const;
	bool GetUnsynchronizedDirectoryContacts(ContactModelSet& unsinchronizedContacts) const;
    
	int GetNewMessagesCount(void) const;
	bool GetAllVisibleChats(ChatDbModelSet& result) const;
	bool GetAllP2pChats(ChatDbModelSet& result) const;
	bool GetChatsByIds(const ChatIdSet& ids, ChatDbModelSet& result, bool onlyVisible = true) const;
	ChatDbModel GetChatById(const ChatIdType& id, bool onlyVisible = true) const;
	bool GetActiveMultiUserChatIds(const ChatIdSet& excepts, ChatIdSet& result) const;
	bool DeactivateMultiUserChats(const ChatIdSet& ids);
    
	bool SaveChat(ChatDbModel& chat);
	bool UpdateChatId(const ChatIdType& chatId, const ChatIdType& newChatId);
    bool DeleteChat(const ChatDbModel& chat);

	bool GetUnsynchronizedChatEvents(const ChatIdType& chatId, UnsynchronizedChatEventDbSet& result) const;
	bool AddUnsynchronizedChatEvent(const ChatIdType& chatId, const UnsynchronizedChatEventDbModel& evt);
	bool RemoveUnsynchronizedChatEvent(const ChatIdType& chatId, const UnsynchronizedChatEventDbModel& evt);

    bool GetChatMessages(const ChatIdType& chatId, ChatMessageDbModelSet& result) const;
    bool GetChatMessagesPaged(const ChatIdType& chatId, int pageSize, ChatMessageIdType const &lastMsgId, ChatMessageDbModelList& result) const;
	ChatMessageDbModel GetLastMessageOfChat(const ChatIdType& chatId) const;
	bool GetLastMessagesOfAllChats(ChatMessageDbModelSet& result) const;
	bool GetLastMessagesOfChats(const ChatIdSet& chatIds, ChatMessageDbModelSet& result) const;
	bool GetMessagesByIds(const ChatMessageIdSet& ids, ChatMessageDbModelSet& result, bool globally = false) const;
	ChatMessageDbModel GetChatMessageById(const ChatMessageIdType& id, bool globally = false);
	bool GetUnsynchronizedChats(ChatDbModelSet& result) const;
	bool GetUnserveredMessages(const ChatIdType& chatId, ChatMessageDbModelList& result) const;
	bool GetUnserveredP2pMessages(ChatMessageDbModelList& result) const;
	bool GetChatIdsWithNewMessages(ChatIdSet& chatIds) const;

	bool GetP2pChatByMemberId(ContactXmppIdType const &memberId, ChatDbModelSet& result, bool surelyActive = true) const;
	time_t GetLastP2pMessageTime(void) const;

	bool SaveChatMessage(ChatMessageDbModel& message);
	bool MarkMessagesAsReaded(const ChatMessageIdType& untilMessageId);
	bool MarkAllMessagesAsReaded(void);

	bool SaveCall(const CallDbModel& call);
	// TODO: make bulk
	bool DeleteCall(const CallDbModel& call);
	int GetNumberOfMissedCalls(void) const;
	bool GetCallHistory(CallDbModelList& result) const;
	bool SetCallHistoryEntriesReaded(const CallIdSet& ids);
    
    bool SetHoldingCompanyIds (CompanyIdsSet const &ids);
    bool IsCompanyInMyHolding(CompanyIdType const &id) const;

protected:
	Logger& GetLogger(void) const;

private:
	ContactModel CheckContactExists(const ContactModel& contact, const char* contactsTableName, const char* contactContactsTableName) const;
	bool InsertContact(ContactModel& contact, const char* contactsTableName, const char* contactContactsTableName);
	bool UpdateContact(ContactModel& contact, const char* contactsTableName, const char* contactContactsTableName);
	bool InsertContactContacts(const ContactModel& contact, const char* contactContactsTableName);

	bool SaveContactInternal(ContactModel& contact, bool cache = false);
    
	bool FillContactContacts(ContactModel& contact, const char* contactContactsTableName, int64_t internalId) const;
	void DbResultToContactSet(const DBResult& dbresult, ContactModelSet& result) const;
	ContactModel DbRowToContactModel(const DBRow& row, const char* contactContactsTableName = 0) const;
    
    bool InsertChat(ChatDbModel &chat);
    bool UpdateChat(ChatDbModel &chat);
    
    bool InsertChatContacts(const ChatDbModel &chat);
    bool FillChatsContacts(ChatDbModelSet& chats) const;

    bool InsertChatMessage(const ChatMessageDbModel& message);
    bool UpdateChatMessage(const ChatMessageDbModel& message);

    void DbResultToChatSet(const DBResult& dbresult, ChatDbModelSet& result) const;
    ChatDbModel DbRowToChatDbModel(const DBRow& row) const;

	UnsynchronizedChatEventDbModel DbResultToUnsynchronizedChatEventDbModel(const DBRow& row) const;
	void DbResultToUnsynchronizedChatEventDbSet(const DBResult& dbresult, UnsynchronizedChatEventDbSet& result) const;

    ChatMessageDbModel DbRowToChatMessageDbModel(const DBRow& row) const;
    void DbResultToChatMessageSet(const DBResult& dbresult, ChatMessageDbModelSet& result) const;
	void DbResultToChatMessageList(const DBResult& dbresult, ChatMessageDbModelList& result) const;

	CallDbModel DbRowToCallDbModel(const DBRow& row) const;
};

}
