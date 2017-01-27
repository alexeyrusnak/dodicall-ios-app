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

#include "ApplicationServerApi.h"
#include "UniversalProcessors.h"
#include "UniversalContainers.h"

#include "ContactModel.h"
#include "ContactSubscriptionModel.h"

#include "ChatModel.h"
#include "ChatMessageModel.h"

#include "XmppHelper.h"

namespace dodicall
{

enum XmppConnectionState
{
	XmppConnectionStateDisconnected = 0,
	XmppConnectionStateConnection,
	XmppConnectionStateConnected,
	XmppConnectionStateShutdown = 9
};
    
typedef std::string ContactDeviceIdType;

class DODICALLLOGICAPI ApplicationMessengerApi: virtual public ApplicationServerApi
{
private:
	std::string mJid;
	std::string mBoundJid;
	std::string mNickname;

	xmpp_conn_t* mConnection;
	XmppConnectionState mConnectionState;

	xmpp_log_t mXmppLog;

	unsigned mServicesCount;
	unsigned mServicesDiscovered;
	std::string mConferenceDomain;

	bool mTimeSupported;
	bool mPingSupported;

    bool mMamSupported;
    
	bool mConferenceRsmSupported;


	boost::posix_time::time_duration mTimeDifference;

	ThreadPtr mIterator;
	mutable boost::recursive_mutex mMutex;
	DateType mIterateControlTime, mIterateLastTime;
	int mIterateCounter;

	unsigned mPingWdc;

	BaseUserStatus mCurrentBaseStatus;
	std::string mCurrentExtStatus;

    typedef std::map<ContactDeviceIdType, boost::tuple<BaseUserStatus,std::string,time_t>> DeviceStatusesMap;
    typedef std::map<ContactXmppIdType, DeviceStatusesMap> UserStatusesMap;
	UserStatusesMap mUserStatuses;
	mutable boost::mutex mUserStatusesMutex;

	bool mRosterReady;
	SafeContainer<ContactSubscriptionModel, std::map<ContactXmppIdType, ContactSubscriptionModel> > mRoster;
    
    bool p2pArchiveSynced;

	mutable unsigned mLastRequestId;
	mutable boost::mutex mLastRequestIdMutex;

	DelayedProcessor<ContactXmppIdType> mPresenceNotifyer;
	DelayedProcessor<ContactXmppIdType> mRosterNotifyer;
	DelayedProcessor<ChatIdType> mChatNotifyer;
	DelayedProcessor<ChatMessageIdType> mChatMessageNotifyer;
	
	DelayedCaller mChatRoomAserverizer;
	DelayedProcessor<ChatIdType> mChatRoomAsynchronizer;

    DelayedProcessor<ChatMessageDbModel, std::vector<ChatMessageDbModel> > mMessagesDelayedSender;
    
	class AsyncRequestSubscription
	{
	public:
		boost::condition_variable Event;
		xmpp_stanza_t* Result;

		AsyncRequestSubscription();
		~AsyncRequestSubscription();
		void Wait(void);
	};
	typedef boost::shared_ptr<AsyncRequestSubscription> AsyncRequestSubscriptionPtr;
	typedef std::map<std::string,AsyncRequestSubscriptionPtr> AsyncRequestSubscriptionMap;
	mutable AsyncRequestSubscriptionMap mAsyncSubscriptions;
	mutable boost::mutex mSubsMutex;

	ChatIdType mForceChatId;

	SafeContainer<ChatMessageIdType, ChatMessageIdSet> mSendedP2pMessages;

	DelayedProcessor<ChatMessageDbModel, std::vector<ChatMessageDbModel> > mMessageProcessor;

	ThreadPtr mP2pChatsSynchronizer;

	class ChatPreferences
	{
	public:
		bool Visible;
		DateType LastClearTime;
		std::string LastTitle;
		std::string RevokedBy;

		ChatPreferences();
		ChatPreferences(const DateType& t, bool visible, const std::string& lastTitle);
	};

protected:
	typedef std::map<ContactXmppIdType, ContactModel> ContactByXmppIdCache;
	typedef boost::shared_ptr<ContactByXmppIdCache> ContactByXmppIdCachePtr;

	bool Prepare(void);

	void Start(void);
	void Stop(void);
	void Ping(void);

	void Pause(void);
	void Resume(void);

	bool TurnVoipSocket(bool on);

	bool OpenConnection(void);
	void CloseConnection(void);

	void SendPresence(bool always = true);
	bool ChangePresence(BaseUserStatus baseStatus, const char* extStatus);

	void SendReadyForCall(const ContactXmppIdType& xmppId);

	bool SendSubscriptionRequestIfNeeded(const ContactXmppIdType& xmppId, bool subscribe);
	bool AnswerSubscriptionRequestIfNeeded(const ContactXmppIdType& xmppId, bool accept);
	bool RemoveFromRoster(const ContactXmppIdType& xmppId);

	void FillContactSubscriptionStatus(ContactModel& contact) const;

	void WaitForRoster(void) const;
	boost::optional<ContactSubscriptionModel> GetRosterRecord(const ContactXmppIdType& xmppId) const;
	void ChangeContactSubscriptionAndProcess(const ContactXmppIdType& xmppId, const ContactSubscriptionModel& record);
	void RemoveRosterRecord(const ContactXmppIdType& xmppId);
	void ClearRoster(const ContactXmppIdSet& except);

	// async/await operations
	bool RetrieveRoster(void);
	bool RetrieveDirectoryContacts(ContactDodicallIdSet& result) const;
	bool ApplyDirectoryContactChanges(ContactModel& contact) const;
	bool StoreDirectoryContacts(const ContactModelSet& contacts, const ContactDodicallIdSet& changedIds) const;
	bool RetrieveNativeContacts(ContactModelSet& result) const;
	bool StoreNativeContacts(const ContactModelSet& contacts) const;
	ContactSubscriptionStatus GetSubscriptionStatus(const ContactXmppIdType& xmppId) const;
	bool MarkSubscriptionStatus(const ContactXmppIdType& xmppId, ContactSubscriptionStatus status);
	ChatPreferences RetrieveChatPreferences(const ChatIdType& chatId) const;
	bool StoreChatPreferences(const ChatIdType& chatId, const ChatPreferences& prefs);
	bool RetrieveChatMembers(const ChatIdType& chatId, ContactXmppIdSet& result) const;

	bool GetAllChats(ChatDbModelSet& result) const;
	bool GetChatsByIds(const ChatIdSet& ids, ChatDbModelSet& result) const;
	bool GetChatMessages(const ChatIdType& chatId, ChatMessageDbModelSet& result) const;
	bool GetMessagesByIds(const ChatMessageIdSet& ids, ChatMessageDbModelSet& result) const;
	ChatMessageDbModel GetLastMessageOfChat(const ChatIdType& chatId) const;
    
    bool GetChatMessagesPaged(const ChatIdType& chatId, int pageSize, ChatMessageIdType const &lastMsgId, ChatMessageDbModelList& result) const;

	bool SendMessage(ChatMessageDbModel message);
	bool SendNotificationMessage(const ChatIdType& chatId, const ChatNotificationType& type, const ContactXmppIdSet& jids);

    ChatIdType InviteAndRevokeChatMembers(const char* roomJid, ContactXmppIdSet  &inviteList, ContactXmppIdSet &revokeList);

	static ContactModel GetMe(const ContactByXmppIdCache& cache);

	ChatNotificationData ParseNotificationMessage(const ChatMessageDbModel& message) const;
	ContactModel ParseContactMessage(const ChatMessageDbModel& message) const;

	ApplicationMessengerApi(void);
	~ApplicationMessengerApi(void);

public:
	void GetPresenceStatusesByXmppIds(const ContactXmppIdSet& ids, ContactPresenceStatusSet& result) const;

	// async/await operations
	bool MarkSubscriptionAsOld(const ContactXmppIdType& xmppId, bool old = true);
    
	int GetNewMessagesCount(void) const;

	bool CreateChatWithContacts(const ContactXmppIdSet& xmppIds, ChatDbModel& result);

	bool MarkMessagesAsReaded(const ChatMessageIdType& untilMessageId);
	bool MarkAllMessagesAsReaded(void);

	bool ClearChats(const ChatIdSet& chatIds, ChatIdSet& failed);

	// TODO: а нужен ли этот метод ?
	bool ExitChats(const ChatIdSet& chatIds, ChatIdSet& failed);

	ChatMessageIdType PregenerateMessageId(void) const;
	ChatMessageIdType SendTextMessage(const ChatMessageIdType& id, const ChatIdType& chatId, const char* text);

    bool RenameChat(const ChatIdType& chatId, const char* subject);
    
    bool SendContactToChat(const ChatMessageIdType& id, const ChatIdType& chatId, ContactModel const &contactData);
    
    bool DeleteMessages(const ChatMessageIdSet& ids);
    bool CorrectMessage(const ChatMessageIdType &id, const std::string &text);
    bool CanEditMessage (const ChatMessageIdType &id);
    bool GetEditableMessageIdsForChat(const ChatIdType &id, ChatMessageIdSet &messages);

	void ForceChatSync(const ChatIdType& id);

protected:
	template <class F> static ContactModel ContactFromCache(ContactByXmppIdCache& cache, const ContactXmppIdType& id, F externalSearchFunc)
	{
		auto found = cache.find(id);
		if (found != cache.end())
			return found->second;
		ContactModel contact = externalSearchFunc(id);
		cache[id] = contact;
		return contact;
	}

private: 
	bool Iterate(void);

	void SetConnectionState(XmppConnectionState state);

	std::string GenerateNextRequestId(const char* prefix) const;

	bool JustSendPresence();
    void EnterToChatRoom(const char* to, int lastEventDuration = 0);
    
    bool CreateMultiUserChat(ChatDbModel& chat, ContactXmppIdSet const &userJidList = ContactXmppIdSet(), bool onServer = false);
    int DestroyChat(char const *roomJid);
	
	void PrepareAndFilterChatsForView(ChatDbModelSet& chats) const;
	void PrepareChatMessageForView(ChatMessageDbModel& message) const;

	template <class TCONT> void PrepareChatMessagesForView(TCONT& messages) const
	{
		for (auto iter = messages.begin(); iter != messages.end(); iter++)
			this->PrepareChatMessageForView((ChatMessageDbModel&)*iter);
	}


	bool JustSendMessage(const ChatMessageDbModel& message);
    
    void SendPushAboutMessage(const ChatMessageDbModel& message);
    
    void SendPushAboutInviteToContact(const ContactXmppIdType& xmppId);

	static void StropheConnHandler(xmpp_conn_t *const conn, const xmpp_conn_event_t status, const int error, xmpp_stream_error_t *const stream_error, void *const userdata);
	static int StrophePresenceHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata);
	static int StropheMessageHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata);
	static int StropheIqHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata);
	static void StropheLogHandler(void * const userdata, const xmpp_log_level_t level, const char * const area, const char * const msg);

	bool AsyncRequestsHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool PingHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool TimeHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool ServiceDiscoveryHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool RosterHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool UserPresenceHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool UserSubscribesHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool ContactChangesNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool ChatMessageNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
	bool ChatChangesNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);

	bool RetrieveOrCreateP2pChat(const ContactXmppIdType& xmppId, ChatDbModel& result, bool needSync);
	bool RetrieveOrCreateMultiUserChat(const ContactXmppIdSet& contacts, ChatDbModel& result);

	void ResendUnserveredMessages(const ChatIdType& chatId);
	void ResendUnserveredP2pMessages(void);
    
    bool P2PArchiveNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);

	bool ReadyForCallNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);

    bool P2PArchiveEndHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza);
    
	static std::string CutJid(const std::string& fullJid);
	static std::string CutJidDomain(const std::string& jid);
    
    void SetMsgTime(xmpp_stanza_t* const delay, ChatMessageDbModel& msg);
    bool ParseMessage(xmpp_stanza_t* const serverMessage, ChatMessageDbModel& message);

	ContactModel PtreeToContact(const boost::property_tree::ptree& tree) const;
	bool JsonToContactsSet(const char* contactsJson, ContactModelSet& contacts) const;
	std::string ContactsSetToJson(const ContactModelSet& contacts) const;
    void ContactToPtree(boost::property_tree::ptree& contactTree, ContactModel const &contact) const;

	static std::string NotificationToJson(const ChatNotificationType& type, const ContactXmppIdSet& jids);

	void SyncChatRoomPrefs(ChatDbModel& chat, const ChatMessageDbModel& lastMessage);

	bool SyncChatRoom(const ChatIdType& jid, ChatIdSet* pActiveChatIds = 0, std::string changerJid = "");
	bool SyncP2pChat(const ChatIdType& jid);
	
    void StartP2PArchiveRetrieval();
    
    void RequestLatestP2PArchiveLive();
    
	ChatIdSet SyncChatRooms(int limit = 0, const ChatIdType& afterId = "");
	void SyncP2pChats(void);

	void SynchronizeChatRooms(void);

	void NotifyChatChanged(const ChatDbModel& chat, bool onlyMe = false);

	void ProcessBackgroundStatuses(void);
	void ProcessIncomingMessages(const std::vector<ChatMessageDbModel>& messages);
    
    void SendDelayedMessages(const std::vector<ChatMessageDbModel>& messages);

	void OnIncommingPacket(void);
    
    bool CanEditMessage(const ChatMessageDbModel& msg);

	virtual void StartDirectoryContactsSynchronization(const char* dodicallId = 0) = 0;
	virtual void StartNativeContactsSynchronization() = 0;
	virtual void InterruptContactsSynchronization(void) = 0;
	virtual void ProcessSubscriptionAsk(const ContactXmppIdType& xmppId) = 0;
	virtual void RemoveSubscriptionAsk(const ContactXmppIdType& xmppId) = 0;

	virtual ContactModel GetAccountData(bool format = false, bool useCache = true) = 0;
	virtual ContactModel RetriveContactByXmppId(const ContactXmppIdType& id) = 0;
	virtual void RetriveContactsByXmppIds(ContactXmppIdSet xmppIds) = 0;
	virtual ContactModel RetriveContactByDodicallId(const ContactDodicallIdType& id, bool forceServer = false) = 0;

	virtual void RecallToContact(const ContactModel& contact) = 0;

	virtual ChatModel DbChatToChatModel(const ChatDbModel& dbchat, bool withMe = false, ContactByXmppIdCachePtr contactsCache = ContactByXmppIdCachePtr(), const ChatMessageDbModelSet& lastMessages = ChatMessageDbModelSet()) = 0;

	// async/await executor
	template <class RL, class PL> bool AsyncRequestAndProcess(RL requestGenerator, PL responseProcessor) const
	{
		AsyncRequestSubscriptionPtr subscription(new AsyncRequestSubscription());
		{
			boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
			if (this->mConnectionState != XmppConnectionStateConnected)
				return false;

			boost::lock_guard<boost::mutex> _slock(this->mSubsMutex);
			std::string id = requestGenerator();
			if (id.empty())
				return false;

			AsyncRequestSubscriptionMap::iterator found = this->mAsyncSubscriptions.find(id);
			if (found != this->mAsyncSubscriptions.end())
				subscription = found->second;
			else
				this->mAsyncSubscriptions[id] = subscription;
		}
		auto waitAndProcess = [subscription, responseProcessor](bool sameThread = false)
		{
			subscription->Wait();
			if (subscription->Result)
				return responseProcessor(subscription->Result, sameThread);
			return false;
		};
		if (boost::this_thread::get_id() != this->mIterator->get_id())
			return waitAndProcess(true);
		this->mThreadsOnlyThenLoggedIn.StartThread(waitAndProcess);
		return true;
	}

	inline DateType LocalTimeToServer(const DateType& l) const
	{
		return l - this->mTimeDifference;
	}
	inline DateType ServerTimeToLocal(const DateType& s) const
	{
		return s + this->mTimeDifference;
	}

	friend class ChatRoomAsynchronizer;
	friend bool equals(const ChatPreferences& left, const ChatPreferences& right);
};

LoggerStream operator << (LoggerStream s, const ChatDbModel& chat);
LoggerStream operator << (LoggerStream s, const ChatMessageDbModel& msg);

LoggerStream operator << (LoggerStream s, const ContactPresenceStatusModel& presence);

}
