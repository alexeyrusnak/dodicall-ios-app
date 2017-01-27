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

#include "stdafx.h"

#include "LogManager.h"
#include "ApplicationMessengerApi.h"

#include "ContactModel.h"

#include "JsonHelper.h"

#include "DateTimeUtils.h"
#include "StringUtils.h"

#define WDC_THRESHOLD_PING 1250
#define WDC_THRESHOLD_DISCONNECT 2500

#define BACKGROUND_PRESENCE_TTL 300

#define CHAT_ROOMS_BULK_SIZE 1000

namespace dodicall
{

using namespace dbmodel;

static const char *const gDirectoryContactsNs = "contacts:directory:as3";
static const char *const gNativeContactsNs = "contacts:native";
static const char *const gInviteContactsNs = "contacts:invite";
static const char *const gPresenceNs = "presence:settings";
static const char *const gChatPrefsNs = "chat:preferences";


ApplicationMessengerApi::AsyncRequestSubscription::AsyncRequestSubscription(): Result(NULL)
{
}
ApplicationMessengerApi::AsyncRequestSubscription::~AsyncRequestSubscription()
{
	if (this->Result)
		xmpp_stanza_release(this->Result);
}
void ApplicationMessengerApi::AsyncRequestSubscription::Wait(void)
{
	boost::mutex mutex;
	boost::unique_lock<boost::mutex> lock(mutex);
	this->Event.wait(lock);
}

ApplicationMessengerApi::ChatPreferences::ChatPreferences(): 
	Visible(true), LastClearTime(time_t_to_posix_time((time_t)0))
{
}
ApplicationMessengerApi::ChatPreferences::ChatPreferences(const DateType& t, bool visible, const std::string& lastTitle):
	Visible(visible), LastClearTime(t), LastTitle(lastTitle)
{
}

ApplicationMessengerApi::ApplicationMessengerApi(void): mConnection(0), 
	mConnectionState(XmppConnectionStateShutdown),
	mServicesCount(0), mServicesDiscovered(0), 
	mTimeSupported(false), mPingSupported(false), mConferenceRsmSupported(false),
	mMamSupported(false),
	mTimeDifference(0,0,0,0),
	mLastRequestId(0), mPingWdc(0),
	mCurrentBaseStatus(BaseUserStatusOnline),
	mRosterReady(false),
	mIterateControlTime(posix_time_now()),
	mIterateLastTime(posix_time_now()),
	mIterateCounter(0),
	mPresenceNotifyer([this](const ContactXmppIdSet& ids)
	{
		this->DoCallback("ContactsPresence",ids);
	}, 200),
	mRosterNotifyer([this](const ContactXmppIdSet& ids)
	{
		this->DoCallback("ContactSubscriptions", ids);
	}, 200),
	mChatNotifyer([this](const ChatIdSet& ids)
	{
		this->DoCallback("Chats", ids);
	}, 200),
	mChatMessageNotifyer([this](const ChatMessageIdSet& ids)
	{
		this->DoCallback("ChatMessages", ids);
	}, 200),
	mChatRoomAsynchronizer([this](const ChatIdSet& ids)
	{
		for (auto iter = ids.begin(); iter != ids.end(); iter++)
		{
			if (this->mMamSupported && GetDomain(*iter) != this->mConferenceDomain)
			{
				// REVIEW SV->AM: use 4.1.1 Filtering by JID of xep-0313
				RequestLatestP2PArchiveLive();
				this->SyncP2pChat(*iter);
			}
			else
				this->SyncChatRoom(*iter);
		}
	}, 200),
	mChatRoomAserverizer([this]
	{
		this->SynchronizeChatRooms();
	}, 0),
	mMessageProcessor([this](const std::vector<ChatMessageDbModel>& messages)
	{
		this->ProcessIncomingMessages(messages);
	}, 0),
    mMessagesDelayedSender([this](const std::vector<ChatMessageDbModel>& messages)
    {
        this->SendDelayedMessages(messages);
    }, 0)
{
	this->mXmppLog.handler = StropheLogHandler;
	this->mXmppLog.userdata = (void*)this;
}
ApplicationMessengerApi::~ApplicationMessengerApi(void)
{
	this->CloseConnection();
}

bool ApplicationMessengerApi::Prepare(void)
{
	ContactModel self = this->GetAccountData();
	if (self)
	{
		this->mJid = self.GetXmppId();
		return true;
	}
	return false;
}

void ApplicationMessengerApi::Start(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);

	UserSettingsModel settings = this->mUserDb.GetUserSettings();
	this->mCurrentBaseStatus = settings.UserBaseStatus;
	this->mCurrentExtStatus = settings.UserExtendedStatus;

	this->mMamSupported = this->mUserDb.GetSetting("MamSupported", false);
	this->mConferenceDomain = this->mUserDb.GetSetting("ConferenceDomain", std::string(""));
	
	if (!this->mConnection)
	{
		xmpp_initialize();
		this->SetConnectionState(XmppConnectionStateDisconnected);
		this->mIterator = this->mThreadsOnlyThenLoggedIn.StartThread([this]
		{
			while (this->Iterate())
				boost::this_thread::sleep(boost::posix_time::millisec(20));
		});
	}
}

void ApplicationMessengerApi::Stop(void)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationMessengerApi Stop start";
    if(this->mConnection)
	{
		boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
		this->CloseConnection();
		xmpp_shutdown();
	}
	this->SetConnectionState(XmppConnectionStateShutdown);
	
	this->mChatRoomAsynchronizer.Cancel();
	this->mMessageProcessor.Cancel();
	this->mMessagesDelayedSender.Cancel();
	this->mPresenceNotifyer.Cancel();
	this->mRosterNotifyer.Cancel();
	this->mChatNotifyer.Cancel();
	this->mChatMessageNotifyer.Cancel();
    LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationMessengerApi Stop finished";
}

void ApplicationMessengerApi::Ping(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mConnectionState == XmppConnectionStateDisconnected)
		this->OpenConnection();
	if (this->mConnectionState != XmppConnectionStateConnected)
		return;

	// TODO: move to XmppHelper
	xmpp_ctx_t* ctx = xmpp_conn_get_context(this->mConnection);
	
	xmpp_stanza_t* stanza = xmpp_stanza_new(ctx);
	xmpp_stanza_t* ping = xmpp_stanza_new(ctx);

	xmpp_stanza_set_name(stanza,"iq");
	xmpp_stanza_set_type(stanza,"get");
	xmpp_stanza_set_attribute(stanza, "to", this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; }).c_str());
	xmpp_stanza_set_id(stanza,"ping");

	xmpp_stanza_set_name(ping,"ping");
	xmpp_stanza_set_ns(ping,"urn:xmpp:ping");

	xmpp_stanza_add_child(stanza,ping);
	xmpp_stanza_release(ping);

	xmpp_send(this->mConnection, stanza);

	xmpp_stanza_release(stanza);
		
	this->mPingWdc = WDC_THRESHOLD_PING;
}

void ApplicationMessengerApi::Pause(void)
{
}
void ApplicationMessengerApi::Resume(void)
{
	this->ApplicationMessengerApi::Ping();
	this->ApplicationMessengerApi::SendPresence();
}

bool ApplicationMessengerApi::TurnVoipSocket(bool on)
{
#if TARGET_OS_IPHONE
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	bool result = false;
	if (this->mConnectionState == XmppConnectionStateConnected)
	{
		xmpp_set_voip_socket(xmpp_conn_get_context(this->mConnection), (on?1:0));
		result = true;
	}
	else if (!on)
		result = true;
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Voip socket for xmpp " << (result ? "is successfully " : "failed to ") << (on ? "on" : "off");
	return result;
#else
	return true;
#endif
}

bool ApplicationMessengerApi::OpenConnection(void)
{
	this->CloseConnection();

	ServerSettingModel xmppSettings = this->mDeviceSettings.SafeGet<ServerSettingModel>([](const DeviceSettingsModel& self) { return self.GetXmppSettings(); });
	if (xmppSettings.Domain.empty())
	{
		LogManager::GetInstance().XmppLogger(LogLevelError) << "Xmpp settings not found for this account!";
		return false;
	}

	xmpp_ctx_t* ctx = xmpp_ctx_new(NULL, &this->mXmppLog);
	this->mConnection = xmpp_conn_new(ctx);

	if (this->mConnection)
	{
		this->mJid = xmppSettings.Username + "@" + xmppSettings.Domain;
		this->mNickname = xmppSettings.Username;

		xmpp_conn_set_jid(this->mConnection, (this->mJid + "/" + this->mDeviceModel.Platform + "-" + this->mDeviceModel.Uid).c_str());
		xmpp_conn_set_pass(this->mConnection, xmppSettings.Password.c_str());


        char const *altdomain = 0;
        if (!xmppSettings.Server.empty())
            altdomain = xmppSettings.Server.c_str();
        unsigned short altport = (unsigned short)xmppSettings.Port;
        
        bool success = (xmpp_connect_client(this->mConnection, altdomain, altport, ApplicationMessengerApi::StropheConnHandler, (void*)this) >= 0);

		if (success)
		{
			this->SetConnectionState(XmppConnectionStateConnection);
			return true;
		}
	}
	this->SetConnectionState(XmppConnectionStateDisconnected);
	return false;
}
void ApplicationMessengerApi::CloseConnection(void)
{
	if (this->mConnection)
	{
		xmpp_conn_release(this->mConnection);
		this->mConnection = 0;
	}
	this->SetConnectionState(XmppConnectionStateDisconnected);
}
    

    
bool ApplicationMessengerApi::ChangePresence(BaseUserStatus baseStatus, const char* extStatus)
{
	this->mCurrentBaseStatus = baseStatus;
	this->mCurrentExtStatus = extStatus;

	return this->AsyncRequestAndProcess([this]
	{
		xmpp_ctx_t* ctx = xmpp_conn_get_context(this->mConnection);

		xmpp_stanza_t* presence = xmpp_stanza_new(ctx);
		xmpp_stanza_set_name(presence, "presence");
		xmpp_stanza_set_ns(presence, gPresenceNs);

		xmpp_stanza_t* base = xmpp_stanza_new(ctx);
		xmpp_stanza_set_name(base, "base");
		xmpp_stanza_t* baseText = xmpp_stanza_new(ctx);
		xmpp_stanza_set_text(baseText, BaseStatusToString(this->mCurrentBaseStatus).c_str());
		xmpp_stanza_add_child(base, baseText);
		xmpp_stanza_add_child(presence, base);

		xmpp_stanza_t* ext = xmpp_stanza_new(ctx);
		xmpp_stanza_set_name(ext, "ext");
		xmpp_stanza_t* extText = xmpp_stanza_new(ctx);
		xmpp_stanza_set_text(extText, this->mCurrentExtStatus.c_str());
		xmpp_stanza_add_child(ext, extText);
		xmpp_stanza_add_child(presence, ext);

		std::string id = GenerateNextRequestId("presence");
		XmppHelper::StorePrivateData(this->mConnection, presence, id.c_str());
		
		xmpp_stanza_release(baseText);
		xmpp_stanza_release(base);
		xmpp_stanza_release(extText);
		xmpp_stanza_release(ext);
		xmpp_stanza_release(presence);
		return id;
	}, [this](xmpp_stanza_t* answer, bool sameThread)
	{
		if (answer)
			return this->JustSendPresence();
		return false;
	});
}

bool ApplicationMessengerApi::SendSubscriptionRequestIfNeeded(const ContactXmppIdType& xmppId, bool subscribe)
{
	bool needToRequest = false;
	ContactSubscriptionModel subscription;
	{
		boost::optional<ContactSubscriptionModel> found = this->GetRosterRecord(xmppId);
		if (subscribe)
		{
			if (!found || found->SubscriptionState == ContactSubscriptionStateTo)
			{
				needToRequest = true;
				subscription = ((bool)found ? *found : ContactSubscriptionModel());
			}
		}
		else if ((bool)found)
		{
			subscription = *found;
			if (subscription.IsToEnabled() || subscription.AskForSubscription)
				needToRequest = true;
		}
	}

	if (needToRequest)
	{
		bool result = false;
		{
			boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
			if (this->mConnectionState == XmppConnectionStateConnected)
			{
				if (subscribe)
				{
					XmppHelper::SendPresenceEx(this->mConnection, xmppId.c_str(), "subscribe", 0, 0);
					subscription.AskForSubscription = true;

					if (subscription.SubscriptionState == ContactSubscriptionStateNone)
						this->SendPushAboutInviteToContact(xmppId);
				}
				else
				{
					XmppHelper::SendPresenceEx(this->mConnection, xmppId.c_str(), "unsubscribe", 0, 0);
					subscription.SubscriptionState = (subscription.SubscriptionState == ContactSubscriptionStateBoth || subscription.SubscriptionState == ContactSubscriptionStateFrom) ? ContactSubscriptionStateFrom : ContactSubscriptionStateNone;
					subscription.AskForSubscription = false;
				}
				result = true;
			}
		}
		this->ChangeContactSubscriptionAndProcess(xmppId, subscription);
		return result;
	}
	return false;
}

bool ApplicationMessengerApi::AnswerSubscriptionRequestIfNeeded(const ContactXmppIdType& xmppId, bool accept)
{
	ContactSubscriptionModel subscription;
	boost::optional<ContactSubscriptionModel> found = this->GetRosterRecord(xmppId);
	if ((bool)found)
		subscription = *found;

	bool result = true;
	if (accept && subscription.SubscriptionState == ContactSubscriptionStateTo)
		result = this->MarkSubscriptionStatus(xmppId, ContactSubscriptionStatusConfirmed);
	
	{
		boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
		if (result)
		{
			if (this->mConnectionState == XmppConnectionStateConnected)
			{
				if (accept)
				{
					if (!subscription.IsFromEnabled())
					{
						XmppHelper::SendPresenceEx(this->mConnection, xmppId.c_str(), "subscribed", 0, 0);
						subscription.SubscriptionState = (subscription.SubscriptionState == ContactSubscriptionStateNone) ? ContactSubscriptionStateFrom : ContactSubscriptionStateBoth;
					}
				}
				else
				{
					XmppHelper::SendPresenceEx(this->mConnection, xmppId.c_str(), "unsubscribed", 0, 0);
					if (!subscription.IsFromEnabled())
						XmppHelper::SendXmppMessage(this->mConnection, 0, "normal", xmppId.c_str(), "#InviteCancelled#", 0, 0, 0, true);
					subscription.SubscriptionState = (subscription.SubscriptionState == ContactSubscriptionStateBoth || subscription.SubscriptionState == ContactSubscriptionStateTo) ? ContactSubscriptionStateTo : ContactSubscriptionStateNone; //Blocked
				}
			}
			else
				result = false;
		}
	}
	if (result)
	{
		this->ChangeContactSubscriptionAndProcess(xmppId, subscription);
		this->SendPresence();
	}
	return result;
}

bool ApplicationMessengerApi::RemoveFromRoster(const ContactXmppIdType& xmppId)
{
	return this->AsyncRequestAndProcess([this, xmppId]
	{
		std::string id = this->GenerateNextRequestId("contacts");
		XmppHelper::AddRosterItem(this->mConnection, xmppId.c_str(), "remove", id.c_str());
		return id;
	},
	[this, xmppId](xmpp_stanza_t* answer, bool sameThread)
	{
		if (answer != 0)
		{
			const char* type = xmpp_stanza_get_type(answer);
			if (type && std::string(type) == "result")
			{
				this->mRoster.Erase(xmppId);
				return true;
			}
		}
		return false;
	});
}

void ApplicationMessengerApi::FillContactSubscriptionStatus(ContactModel& contact) const
{
	std::string xmppId = contact.GetXmppId();
	boost::optional<ContactSubscriptionModel> found = this->GetRosterRecord(xmppId);
	if ((bool)found)
	{
		contact.Subscription = *found;
		if (contact.Id)
		{
			if (contact.Subscription.SubscriptionState == ContactSubscriptionStateTo)
				contact.Subscription.SubscriptionStatus = ContactSubscriptionStatusConfirmed;
			contact.Subscription.SubscriptionState = (contact.Subscription.SubscriptionState == ContactSubscriptionStateNone ? ContactSubscriptionStateFrom :
				(contact.Subscription.SubscriptionState == ContactSubscriptionStateTo ? ContactSubscriptionStateBoth : contact.Subscription.SubscriptionState));
		}
		if (contact.Subscription.AskForSubscription
			&& contact.Subscription.SubscriptionStatus == ContactSubscriptionStatusConfirmed)
		{
			contact.Subscription.SubscriptionState = ContactSubscriptionStateBoth;
			contact.Subscription.AskForSubscription = false;
		}
	}
	else
		contact.Subscription = ContactSubscriptionModel();
}

void ApplicationMessengerApi::WaitForRoster(void) const
{
	while(!this->mRosterReady)
		boost::this_thread::sleep(boost::posix_time::milliseconds(100));
}

boost::optional<ContactSubscriptionModel> ApplicationMessengerApi::GetRosterRecord(const ContactXmppIdType& xmppId) const
{
	return this->mRoster.Get(xmppId);
}

void ApplicationMessengerApi::ChangeContactSubscriptionAndProcess(const ContactXmppIdType& xmppId, const ContactSubscriptionModel& record)
{
    this->mRoster.Set(std::pair<ContactXmppIdType, ContactSubscriptionModel>(xmppId,record));
    this->mRosterNotifyer.Call(xmppId);
    
    ChatDbModelSet found;
    ChatDbModel chat;
    if (this->mUserDb.GetP2pChatByMemberId(xmppId, found, false) && !found.empty())
	{
        for (auto iter = found.begin(); iter != found.end(); iter++) 
		{
            chat = *iter;
            if (record.SubscriptionState == ContactSubscriptionStateBoth || record.SubscriptionState == ContactSubscriptionStateTo || record.AskForSubscription && record.SubscriptionStatus == ContactSubscriptionStatusConfirmed)
            {
                if (!chat.Active)
                {
                    chat.Active = true;
					if (this->mUserDb.SaveChat(chat))
						this->mChatNotifyer.Call(chat.Id);
                }
            }
            else
            {
                if (chat.Active)
                {
                    chat.Active = false;
                    if (this->mUserDb.SaveChat(chat))
						this->mChatNotifyer.Call(chat.Id);
				}
            }
        }
    }
}
void ApplicationMessengerApi::RemoveRosterRecord(const ContactXmppIdType& xmppId)
{
	this->mRoster.Erase(xmppId);
	this->mRosterNotifyer.Call(xmppId);
}

void ApplicationMessengerApi::ClearRoster(const ContactXmppIdSet& except)
{
	ContactXmppIdSet zombieXmppIds;
	this->mRoster.ForEach([except,&zombieXmppIds](const std::pair<ContactXmppIdType,ContactSubscriptionModel> &value)
	{
		if (except.find(value.first) == except.end() && value.second.SubscriptionState != ContactSubscriptionStateTo)
			zombieXmppIds.insert(value.first);
		return true;
	});
	for (ContactXmppIdSet::const_iterator iter = zombieXmppIds.begin(); iter!= zombieXmppIds.end(); iter++)
	{
		this->SendSubscriptionRequestIfNeeded(*iter,false);
		this->AnswerSubscriptionRequestIfNeeded(*iter,false);
		this->RemoveFromRoster(*iter);
		this->MarkSubscriptionAsOld(*iter, false);
	}
}

bool ApplicationMessengerApi::RetrieveRoster(void)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;

	logger(LogLevelDebug) << "Start retrieving roster data";
	bool res = this->AsyncRequestAndProcess([this]
		{
			std::string id = this->GenerateNextRequestId("contacts");
			XmppHelper::RetrieveRoster(mConnection, id.c_str());
			return id;
		},
		[this](xmpp_stanza_t* answer, bool sameThread)
		{
			return (this->RosterHandler(this->mConnection, answer) && (this->mRosterReady = true));
		});
	logger(LogLevelDebug) << "End retrieving roster data with result " << res;
	return res;
}

bool ApplicationMessengerApi::RetrieveDirectoryContacts (ContactDodicallIdSet& result) const
{
	Logger& logger = LogManager::GetInstance().TraceLogger;

	logger(LogLevelDebug) << "Start retrieving directory contacts";
	bool res = this->AsyncRequestAndProcess([this]
		{
			std::string id = this->GenerateNextRequestId("contacts");
			XmppHelper::RetrivePrivateData(mConnection,gDirectoryContactsNs,"contacts",id.c_str());
			return id;
		}, 
		[this,&result](xmpp_stanza_t* answer, bool sameThread)
		{
			xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer,"query");
			if (query)
			{
				const char* strXmlns = xmpp_stanza_get_ns(query);
				std::string xmlns = (strXmlns ? strXmlns : "");

				if (xmlns == "jabber:iq:private")
				{
					xmpp_stanza_t* contacts = xmpp_stanza_get_child_by_name(query,"contacts");
					if (contacts)
					{
						const char* strContactsXmlns = xmpp_stanza_get_ns(contacts);
						std::string contactsXmlns = (strContactsXmlns ? strContactsXmlns : "");

						if (contactsXmlns == gDirectoryContactsNs)
						{
							xmpp_stanza_t* idStanza = xmpp_stanza_get_children(contacts);
							while (idStanza)
							{
								if (std::string(xmpp_stanza_get_name(idStanza)) == "id")
								{
                                    XmppText strId(this->mConnection,idStanza);
                                    if (strId)
										result.insert(ContactDodicallIdType(strId));
								}
								idStanza = xmpp_stanza_get_next(idStanza);
							}
						}
						return true;
					}
				}
			}
			return false;
		});
	logger(LogLevelDebug) << "End retrieving directory contacts with result " << res;
	return res;
}

bool ApplicationMessengerApi::StoreNativeContacts(const ContactModelSet& contacts) const
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start storing native contacts";

	std::string strContacts = this->ContactsSetToJson(contacts);
	bool res = this->AsyncRequestAndProcess([this,strContacts]
		{
			xmpp_ctx_t* ctx = xmpp_conn_get_context(this->mConnection);
			xmpp_stanza_t* stanza = xmpp_stanza_new(ctx);
		
			xmpp_stanza_set_name(stanza,"contacts");
			xmpp_stanza_set_ns(stanza,gNativeContactsNs);
			if (!strContacts.empty())
			{
				xmpp_stanza_t* text = xmpp_stanza_new(ctx);
				xmpp_stanza_set_text(text,strContacts.c_str());
				xmpp_stanza_add_child(stanza,text);
				xmpp_stanza_release(text);
			}

			std::string id = GenerateNextRequestId("contacts");
			XmppHelper::StorePrivateData(this->mConnection,stanza,id.c_str());
			xmpp_stanza_release(stanza);
			return id;
		}, [this,contacts](xmpp_stanza_t* answer, bool sameThread)
		{
			boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
			XmppHelper::SendXmppMessage(this->mConnection,0,"normal",this->mJid.c_str(),"#ContactChanged#",0,0,0, true);
			return true;
		});
	logger(LogLevelDebug) << "End storing native contacts with result " << res;
	return res;
}

bool ApplicationMessengerApi::ApplyDirectoryContactChanges(ContactModel& contact) const
{
	return this->AsyncRequestAndProcess([this,contact]
		{ 
			std::string id = GenerateNextRequestId("contacts");
			XmppHelper::RetrivePrivateData(this->mConnection,(std::string(gDirectoryContactsNs)+":"+contact.DodicallId).c_str(),"contact",id.c_str());
			return id;
		}, [this,&contact](xmpp_stanza_t* answer, bool sameThread)
		{
			xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer,"query");
			if (query)
			{
				xmpp_stanza_t* ct = xmpp_stanza_get_child_by_name(query,"contact");
				if (ct)
				{
					for (ContactsContactSet::iterator iter = contact.Contacts.begin(); iter != contact.Contacts.end();)
					{
						if (iter->Manual)
						{
							contact.Contacts.erase(iter);
							iter = contact.Contacts.begin();
							continue;
						}
						else if (iter->Favourite)
							((ContactsContactModel&)*iter).Favourite = false;
						iter++;
					}
					XmppText changes(this->mConnection,ct);
					if (changes)
					{
						boost::property_tree::ptree changesTree;
						if (JsonHelper::json_to_ptree(changes,changesTree))
						{
							for (boost::property_tree::ptree::const_iterator iter = changesTree.begin(); iter != changesTree.end(); iter++)
							{
								if (iter->second.count("blocked") > 0 || iter->second.count("white") > 0)
								{
									contact.Blocked = (iter->second.get<int>("blocked",0) != 0);
									contact.White = (iter->second.get<int>("white",0) != 0);
								}
								else if(iter->second.count("contact_type") > 0)
								{
									ContactsContactModel ccm;
									std::string strType = iter->second.get<std::string>("contact_type");
									ccm.Type = StringToContactsContactType(strType);
									ccm.Identity = iter->second.get<std::string>("contact_identy");
									ccm.Favourite = (iter->second.get<int>("contact_favour",0) != 0);
									ccm.Manual = (iter->second.get<int>("manual",1) != 0);

									bool found = false;
									for (ContactsContactSet::iterator iter = contact.Contacts.begin(); iter != contact.Contacts.end(); iter++)
									{
										if (iter->Type == ccm.Type && iter->Identity == ccm.Identity)
										{
											(ContactsContactModel&)*iter = ccm;
											found = true;
										}
									}
									if (!found)
										contact.Contacts.insert(ccm);
								}
							}
						}
					}
				}
				return true;
			}
			return false;
		});
}

bool ApplicationMessengerApi::StoreDirectoryContacts(const ContactModelSet& contacts, const ContactDodicallIdSet& changedIds) const
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start storing directory contacts";

	bool res = this->AsyncRequestAndProcess([this,contacts]
		{
			xmpp_ctx_t* ctx = xmpp_conn_get_context(this->mConnection);
			xmpp_stanza_t* stanza = xmpp_stanza_new(ctx);
		
			xmpp_stanza_set_name(stanza,"contacts");
			xmpp_stanza_set_ns(stanza,gDirectoryContactsNs);
		
			for (ContactModelSet::const_iterator iter = contacts.begin(); iter != contacts.end(); iter++)
			{
				if (!iter->DodicallId.empty())
				{
					xmpp_stanza_t* id = xmpp_stanza_new(ctx);
					xmpp_stanza_set_name(id,"id");
					xmpp_stanza_t* text = xmpp_stanza_new(ctx);
					xmpp_stanza_set_text(text,iter->DodicallId.c_str());

					xmpp_stanza_add_child(id,text);
					xmpp_stanza_add_child(stanza,id);

					xmpp_stanza_release(text);
					xmpp_stanza_release(id);

					if (!iter->Contacts.empty())
					{
						boost::property_tree::ptree changesTree;
						{
							boost::property_tree::ptree blockAndWhite;
							blockAndWhite.put("blocked",(iter->Blocked ? 1 : 0));
							blockAndWhite.put("white",(iter->White ? 1 : 0));
							changesTree.push_back(std::make_pair("",blockAndWhite));
						}
						for (ContactsContactSet::const_iterator citer = iter->Contacts.begin(); citer != iter->Contacts.end(); citer++)
						{
							if (citer->Manual || (citer->Favourite && citer != iter->Contacts.begin()))
							{
								boost::property_tree::ptree manual;
								std::string strType;
								switch(citer->Type)
								{
								case ContactsContactSip:
									strType = "sip";
									break;
								case ContactsContactXmpp:
									strType = "xmpp";
									break;
								case ContactsContactPhone:
									strType = "phone";
									break;
								default:
									// TODO: log warning
									break;
								}
								manual.put("contact_type",strType);
								manual.put("contact_identy",citer->Identity);
								manual.put("contact_favour",(citer->Favourite ? 1 : 0));
								manual.put("manual",(citer->Manual ? 1 : 0));
								changesTree.push_back(std::make_pair("",manual));
							}
						}
						boost::property_tree::ptree changesObject;
						changesObject.add_child("changes", changesTree);
						
						std::string changesJson = JsonHelper::ptree_to_json_array(changesObject);
						XmppHelper::UploadDirectoryContactManuals(this->mConnection, (std::string(gDirectoryContactsNs)+":"+iter->DodicallId).c_str(), 
							changesJson.c_str(), this->GenerateNextRequestId("contacts").c_str());
					}
				}
			}
			std::string id = GenerateNextRequestId("contacts");
			XmppHelper::StorePrivateData(this->mConnection,stanza,id.c_str());
			xmpp_stanza_release(stanza);
			return id;
		}, [this,changedIds](xmpp_stanza_t* answer, bool sameThread)
		{
			boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
			for (ContactDodicallIdSet::const_iterator citer = changedIds.begin(); citer != changedIds.end(); citer++)
				XmppHelper::SendXmppMessage(this->mConnection,0,"normal",this->mJid.c_str(),"#ContactChanged#",citer->c_str(),0,0, true);
			return true;
		});
	logger(LogLevelDebug) << "End storing directory contacts with result " << res;
	return res;
}

bool ApplicationMessengerApi::RetrieveNativeContacts(ContactModelSet& result) const
{
	return this->AsyncRequestAndProcess([this]
		{
			std::string id = GenerateNextRequestId("contacts");
			XmppHelper::RetrivePrivateData(this->mConnection,gNativeContactsNs,"contacts",id.c_str());
			return id;
		}, [this,&result](xmpp_stanza_t* answer, bool sameThread)
		{
			xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer,"query");
			if (query)
			{
				const char* strXmlns = xmpp_stanza_get_ns(query);
				std::string xmlns = (strXmlns ? strXmlns : "");

				if (xmlns == "jabber:iq:private")
				{
					xmpp_stanza_t* contacts = xmpp_stanza_get_child_by_name(query,"contacts");
					if (contacts)
					{
						const char* strContactsXmlns = xmpp_stanza_get_ns(contacts);
						std::string contactsXmlns = (strContactsXmlns ? strContactsXmlns : "");

						if (contactsXmlns == gNativeContactsNs)
						{
							XmppText contactsJson(this->mConnection,contacts);
                            if (contactsJson)
								JsonToContactsSet(contactsJson,result);
						}
						return true;
					}
				}
			}
			return false;
		});
}

ContactSubscriptionStatus ApplicationMessengerApi::GetSubscriptionStatus(const ContactXmppIdType& xmppId) const
{
	ContactSubscriptionStatus result = ContactSubscriptionStatusNew;
	this->AsyncRequestAndProcess([this,xmppId]
		{
			std::string id = GenerateNextRequestId("contacts");
			XmppHelper::RetrivePrivateData(this->mConnection,(std::string(gInviteContactsNs)+":"+this->CutJidDomain(xmppId)).c_str(),"invite",id.c_str());
			return id;
		}, [this,&result](xmpp_stanza_t* answer, bool sameThread)
		{
			xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer,"query");
			if (query)
			{
				const char* strXmlns = xmpp_stanza_get_ns(query);
				std::string xmlns = (strXmlns ? strXmlns : "");

				if (xmlns == "jabber:iq:private")
				{
					xmpp_stanza_t* invite = xmpp_stanza_get_child_by_name(query,"invite");
					if (invite)
					{
						XmppText text(this->mConnection,invite);
                        if (text)
							result = (ContactSubscriptionStatus)boost::lexical_cast<int>(std::string(text));
					}
					return true;
				}
			}
			return false;
		});
	return result;
}

void ApplicationMessengerApi::GetPresenceStatusesByXmppIds(const ContactXmppIdSet& ids, ContactPresenceStatusSet& result) const
{
    
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start GetPresenceStatusesByXmppIds " << ids;
    
    boost::lock_guard<boost::mutex> _slock(this->mUserStatusesMutex);
	for (ContactXmppIdSet::const_iterator iter = ids.begin(); iter != ids.end(); iter++)
	{
		bool found = false;
		auto innerMapIterator = this->mUserStatuses.find(*iter);
		if (innerMapIterator != this->mUserStatuses.end())
		{
			for (auto const &ent : innerMapIterator->second)
			{
				if (ent.second.get<0>() != BaseUserStatusOffline)
				{
					result.insert(ContactPresenceStatusModel(*iter, ent.second.get<0>(), ent.second.get<1>()));
					found = true;
					break;
				}
			}
		}
		if (!found)
			result.insert(ContactPresenceStatusModel(*iter));
	}
	// TODO: log result
    logger(LogLevelDebug) << "End GetPresenceStatusesByXmppIds with result " << result;
}

bool ApplicationMessengerApi::MarkSubscriptionStatus(const ContactXmppIdType& xmppId, ContactSubscriptionStatus status)
{
	return this->AsyncRequestAndProcess([this,xmppId,status]
		{
			xmpp_ctx_t* ctx = xmpp_conn_get_context(this->mConnection);
			xmpp_stanza_t* stanza = xmpp_stanza_new(ctx);
			xmpp_stanza_t* text = xmpp_stanza_new(ctx);
		
			xmpp_stanza_set_name(stanza,"invite");
			xmpp_stanza_set_ns(stanza,(std::string(gInviteContactsNs)+":"+this->CutJidDomain(xmppId)).c_str());

			xmpp_stanza_set_text(text, boost::lexical_cast<std::string>((int)status).c_str());
			xmpp_stanza_add_child(stanza, text);

			std::string id = GenerateNextRequestId("contacts");
			XmppHelper::StorePrivateData(this->mConnection,stanza,id.c_str());

			xmpp_stanza_release(text);
			xmpp_stanza_release(stanza);
			return id;
		}, [](xmpp_stanza_t* answer, bool sameThread)
		{
			const char* type = xmpp_stanza_get_type(answer);
			if (type && std::string(type) == "result")
				return true;
			return false;
		});
}

bool ApplicationMessengerApi::MarkSubscriptionAsOld(const ContactXmppIdType& xmppId, bool old)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start MarkSubscriptionAsOld";
    
	if (this->MarkSubscriptionStatus(xmppId, (old ? ContactSubscriptionStatusReaded : ContactSubscriptionStatusNew)))
	{
		if (old)
		{
			boost::optional<ContactSubscriptionModel> subscription = this->GetRosterRecord(xmppId);
			if ((bool)subscription)
			{
				subscription->SubscriptionStatus = ContactSubscriptionStatusReaded;
				this->ChangeContactSubscriptionAndProcess(xmppId, *subscription);
			}
		}
        logger(LogLevelDebug) << "End MarkSubscriptionAsOld";
		return true;
	}
    logger(LogLevelDebug) << "End MarkSubscriptionAsOld";
	return false;
}

ApplicationMessengerApi::ChatPreferences ApplicationMessengerApi::RetrieveChatPreferences(const ChatIdType& chatId) const
{
	ChatPreferences result;
	this->AsyncRequestAndProcess([this,chatId]
	{
		std::string id = GenerateNextRequestId("chats");
		XmppHelper::RetrivePrivateData(this->mConnection, (std::string(gChatPrefsNs)+":"+chatId).c_str(), "preferences", id.c_str());
		return id;
	}, [this, chatId, &result](xmpp_stanza_t* answer, bool sameThread)
	{
		xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer, "query");
		if (query)
		{
			const char* strXmlns = xmpp_stanza_get_ns(query);
			std::string xmlns = (strXmlns ? strXmlns : "");

			if (xmlns == "jabber:iq:private")
			{
				xmpp_stanza_t* preferences = xmpp_stanza_get_child_by_name(query, "preferences");
				if (preferences)
				{
					const char* prefsXmlns = xmpp_stanza_get_ns(preferences);
					std::string strPrefsXmlns = (prefsXmlns ? prefsXmlns : "");

					if (sameThread && strPrefsXmlns == (std::string(gChatPrefsNs) + ":" + chatId))
					{
						xmpp_stanza_t* clearTime = xmpp_stanza_get_child_by_name(preferences, "ClearTime");
						if (clearTime)
						{
							XmppText strClearTime(this->mConnection,clearTime);
							time_t lastClearTimeT = (time_t)(strClearTime ? boost::lexical_cast<int64_t>(std::string(strClearTime)) : 0);
							result.LastClearTime = time_t_to_posix_time(lastClearTimeT);
							if (lastClearTimeT)
								result.LastClearTime = this->ServerTimeToLocal(result.LastClearTime);
                        }
						xmpp_stanza_t* visible = xmpp_stanza_get_child_by_name(preferences, "Visible");
						if (visible)
						{
							XmppText strVisible(this->mConnection, visible);
                            if (strVisible)
								result.Visible = (boost::lexical_cast<int>(strVisible) > 0);
						}
						else
							result.Visible = (result.LastClearTime == time_t_to_posix_time((time_t)0));
						xmpp_stanza_t* title = xmpp_stanza_get_child_by_name(preferences, "LastTitle");
						if (title)
						{
							XmppText lastTitle(this->mConnection, title);
                            if (lastTitle)
								result.LastTitle = lastTitle;
						}
						xmpp_stanza_t* revoked = xmpp_stanza_get_child_by_name(preferences, "RevokedBy");
						if (revoked)
						{
							XmppText revokedBy(this->mConnection, revoked);
                            if (revokedBy)
								result.RevokedBy = revokedBy;
						}
					}
					return true;
				}
			}
		}
		return false;
	});
	return result;
}

bool ApplicationMessengerApi::StoreChatPreferences(const ChatIdType& chatId, const ApplicationMessengerApi::ChatPreferences& prefs)
{
	return this->AsyncRequestAndProcess([this, chatId, prefs]
	{
		xmpp_ctx_t* ctx = xmpp_conn_get_context(this->mConnection);
		xmpp_stanza_t* stanza = xmpp_stanza_new(ctx);
		xmpp_stanza_t* clearTime = xmpp_stanza_new(ctx);
		xmpp_stanza_t* visible = xmpp_stanza_new(ctx);
		xmpp_stanza_t* title = xmpp_stanza_new(ctx);
		xmpp_stanza_t* revoked = xmpp_stanza_new(ctx);

		xmpp_stanza_set_name(stanza, "preferences");
		xmpp_stanza_set_ns(stanza, (std::string(gChatPrefsNs) + ":" + chatId).c_str());

		if (posix_time_to_time_t(prefs.LastClearTime))
		{
			xmpp_stanza_set_name(clearTime, "ClearTime");
			{
				xmpp_stanza_t* text = xmpp_stanza_new(ctx);
				xmpp_stanza_set_text(text, boost::lexical_cast<std::string>((int64_t)posix_time_to_time_t(this->LocalTimeToServer(prefs.LastClearTime))).c_str());
				xmpp_stanza_add_child(clearTime, text);
				xmpp_stanza_release(text);
			}
			xmpp_stanza_add_child(stanza, clearTime);
		}

		xmpp_stanza_set_name(visible, "Visible");
		{
			xmpp_stanza_t* text = xmpp_stanza_new(ctx);
			xmpp_stanza_set_text(text, boost::lexical_cast<std::string>(prefs.Visible ? 1 : 0).c_str());
			xmpp_stanza_add_child(visible, text);
			xmpp_stanza_release(text);
		}
		xmpp_stanza_add_child(stanza, visible);

		xmpp_stanza_set_name(title, "LastTitle");
		{
			xmpp_stanza_t* text = xmpp_stanza_new(ctx);
			xmpp_stanza_set_text(text, prefs.LastTitle.c_str());
			xmpp_stanza_add_child(title, text);
			xmpp_stanza_release(text);
		}
		xmpp_stanza_add_child(stanza, title);

		xmpp_stanza_set_name(revoked, "RevokedBy");
		{
			xmpp_stanza_t* text = xmpp_stanza_new(ctx);
			xmpp_stanza_set_text(text, prefs.RevokedBy.c_str());
			xmpp_stanza_add_child(revoked, text);
			xmpp_stanza_release(text);
		}
		xmpp_stanza_add_child(stanza, revoked);

		std::string id = GenerateNextRequestId("chats");
		XmppHelper::StorePrivateData(this->mConnection, stanza, id.c_str());
		
		xmpp_stanza_release(clearTime);
		xmpp_stanza_release(visible);
		xmpp_stanza_release(title);
		xmpp_stanza_release(revoked);
		xmpp_stanza_release(stanza);
		return id;
	}, [this](xmpp_stanza_t* answer, bool sameThread)
	{
		return true;
	});
}

bool ApplicationMessengerApi::RetrieveChatMembers(const ChatIdType& chatId, ContactXmppIdSet& result) const
{
	return this->AsyncRequestAndProcess([this, chatId]
	{
		std::string id = this->GenerateNextRequestId("chats");
		XmppHelper::DiscoverChatRoomMembers(this->mConnection, chatId.c_str(), "owner", id.c_str());
		return id;
	}, [this, &result](xmpp_stanza_t* answer, bool sameThread)
	{
		const char* type = xmpp_stanza_get_type(answer);
		if (type)
		{
			std::string strType = type;
			if (strType == "result")
			{
				xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer, "query");
				if (query)
				{
					xmpp_stanza_t* roomContacts = xmpp_stanza_get_children(query);
					while (roomContacts)
					{
						char const *contactJid = xmpp_stanza_get_attribute(roomContacts, "jid");
						if (contactJid)
							result.insert(std::string(contactJid));
						roomContacts = xmpp_stanza_get_next(roomContacts);
					}
					return (result.find(this->mJid) != result.end());
				}
			}
		}
		return false;
	});
}

int ApplicationMessengerApi::GetNewMessagesCount(void) const
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start GetNewMessagesCount";
	int result = this->mUserDb.GetNewMessagesCount();
    logger(LogLevelDebug) << "End GetNewMessagesCount with result = " << result;
	return result;
}

bool ApplicationMessengerApi::Iterate(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);

	switch (this->mConnectionState)
	{
	case XmppConnectionStateDisconnected:
		{
			static unsigned connectionWatcher = 0;
			if ((connectionWatcher++ % 500) == 0)
			{
				LogManager::GetInstance().XmppLogger(LogLevelDebug) << "Auto open connection initialized";
				if (this->OpenConnection())
					connectionWatcher = 0;
			}
		}
		break;
	case XmppConnectionStateConnected:
	case XmppConnectionStateConnection:
		if ((++this->mPingWdc) > WDC_THRESHOLD_DISCONNECT)
		{
			xmpp_disconnect(this->mConnection);
			LogManager::GetInstance().XmppLogger(LogLevelDebug) << "Connection may be dead, automatic reconnect initialized";
			this->mPingWdc = 0;
		}
		else if (this->mPingWdc == WDC_THRESHOLD_PING)
			this->Ping();
		break;
	}

	if (this->mConnection)
		xmpp_run_once(xmpp_conn_get_context(this->mConnection),0);
	
	this->mIterateCounter++;
	this->mIterateLastTime = posix_time_now();
	int32_t duration = (this->mIterateLastTime - this->mIterateControlTime).total_seconds();
	if (duration > 60)
	{
		this->ProcessBackgroundStatuses();
		LogManager::GetInstance().XmppLogger(LogLevelDebug) << "Iterator was executed " << this->mIterateCounter << " times last minute"
			<< LoggerStream::endl << "Current connection state is " << this->mConnectionState;
		this->mIterateControlTime = this->mIterateLastTime;
		this->mIterateCounter = 0;
	}

	return true;
}

void ApplicationMessengerApi::SetConnectionState(XmppConnectionState state)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	this->mConnectionState = state;
}

std::string ApplicationMessengerApi::GenerateNextRequestId(const char* prefix) const
{
	boost::lock_guard<boost::mutex> _lock(this->mLastRequestIdMutex);
	return std::string(prefix) + boost::lexical_cast<std::string>(++this->mLastRequestId);
}

void ApplicationMessengerApi::SendReadyForCall(const ContactXmppIdType& xmppId)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	XmppHelper::SendXmppMessage(this->mConnection, 0, "normal", xmppId.c_str(),
		"#ReadyForCall#", 0, 0, 0, true);
}

bool ApplicationMessengerApi::JustSendPresence()
{
	std::string typeString;
	if (this->mCurrentBaseStatus == BaseUserStatusOffline)
		typeString = "unavailable";
	std::string statusString = BaseStatusToString(this->mCurrentBaseStatus);

	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mConnectionState == XmppConnectionStateConnected)
	{
		XmppHelper::SendPresenceEx(this->mConnection, 0, typeString.c_str(), statusString.c_str(), this->mCurrentExtStatus.c_str(), 0);
		if (this->mCurrentBaseStatus == BaseUserStatusOffline)
		{
			{
				boost::lock_guard<boost::mutex> _slock(this->mUserStatusesMutex);
				this->mUserStatuses.clear();
			}
			this->mSimpleCallbacker.Call("PresenceOffline");
		}
		return true;
	}
	return false;
}
void ApplicationMessengerApi::SendPresence(bool always)
{
	this->AsyncRequestAndProcess([this]
	{
		std::string id = GenerateNextRequestId("presence");
		XmppHelper::RetrivePrivateData(mConnection, gPresenceNs, "presence", id.c_str());
		return id;
	}, [this,always](xmpp_stanza_t* answer, bool sameThread)
	{
		if (answer)
		{
			xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer, "query");
			if (query)
			{
				const char* queryNs = xmpp_stanza_get_ns(query);
				xmpp_stanza_t* presence = xmpp_stanza_get_child_by_name(query, "presence");
				if (queryNs && std::string(queryNs) == "jabber:iq:private" && presence)
				{
					xmpp_stanza_t* base = xmpp_stanza_get_child_by_name(presence, "base");
					xmpp_stanza_t* ext = xmpp_stanza_get_child_by_name(presence, "ext");
					bool changed = false;
					if (base)
					{
						XmppText baseStr(this->mConnection,base);
						BaseUserStatus newBaseStatus = StringToBaseStatus(std::string(baseStr?baseStr:""), true);
						if (this->mCurrentBaseStatus != newBaseStatus)
						{
							changed = true;
							this->mCurrentBaseStatus = newBaseStatus;
						}
					}
					if (ext)
					{
						XmppText extStr(this->mConnection, ext);
						if (extStr)
						{
                            if (this->mCurrentExtStatus != extStr)
                            {
                                changed = true;
                                this->mCurrentExtStatus = extStr;
                            }
						}
					}
					if (changed)
					{
						UserSettingsModel settings = this->GetUserSettings();
						settings.UserBaseStatus = this->mCurrentBaseStatus;
						settings.UserExtendedStatus = this->mCurrentExtStatus;
						if (this->SaveUserSettings(settings))
							this->mSimpleCallbacker.Call("UserSettings");
					}
					else if (always)
						return this->JustSendPresence();
				}
			}
		}
		return false;
	});
}
    
void ApplicationMessengerApi::EnterToChatRoom(const char* to, int lastEventDuration)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mConnectionState != XmppConnectionStateConnected)
		return;

	xmpp_ctx_t* ctx = xmpp_conn_get_context(this->mConnection);

	xmpp_stanza_t* x = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(x, "x");
	xmpp_stanza_set_ns(x,"http://jabber.org/protocol/muc");

	if (lastEventDuration)
	{
		xmpp_stanza_t* history = xmpp_stanza_new(ctx);
		xmpp_stanza_set_name(history, "history");
		xmpp_stanza_set_attribute(history, "seconds", boost::lexical_cast<std::string>(lastEventDuration).c_str());

		xmpp_stanza_add_child(x, history);
		xmpp_stanza_release(history);
	}

	XmppHelper::SendPresenceEx(this->mConnection,to,0,"",this->mCurrentExtStatus.c_str(),x);

	xmpp_stanza_release(x);	
}

ChatMessageIdType ApplicationMessengerApi::PregenerateMessageId(void) const
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    logger(LogLevelDebug) << "Start PregenerateMessageId";
	return boost::lexical_cast<std::string>(boost::uuids::random_generator()());
}

ChatMessageIdType ApplicationMessengerApi::SendTextMessage(const ChatMessageIdType& id, const ChatIdType& chatId, const char* text)
{
	if (!text || !text[0])
		return ChatMessageIdType("");

    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    logger(LogLevelDebug) << "Start SendTextMessage";
	ChatMessageDbModel message;
	message.Id = id;
	message.ChatId = chatId;
	message.Type = ChatMessageTypeTextMessage;
	message.StringContent = text;
    if (this->SendMessage(message)) 
	{
        logger(LogLevelDebug) << "End SendTextMessage";
		return message.Id;
    }
    logger(LogLevelDebug) << "Failed SendTextMessage";
	return ChatMessageIdType("");
}
    
void ApplicationMessengerApi::SendDelayedMessages(const std::vector<ChatMessageDbModel>& messages)
{
    bool needPing = false;
    
    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    for (auto iter = messages.begin(); iter != messages.end(); ++iter)
    {
        logger(LogLevelDebug) << "Start JustSendMessage";
        
        bool justSended = this->JustSendMessage(*iter);
        if (justSended && this->mMamSupported)
        {
            ChatDbModel chat = this->mUserDb.GetChatById(iter->ChatId);
            if (chat && chat.IsP2P)
            {
				needPing = true;
				this->mSendedP2pMessages.Set(iter->Id);
            }
            logger(LogLevelDebug) << "End JustSendMessage";
        }
        
        if(!justSended)
            logger(LogLevelDebug) << "Failed JustSendMessage";
    }
    if (needPing)
        this->Ping();
}

bool ApplicationMessengerApi::SendMessage(ChatMessageDbModel message)
{
	if (message.Id.empty())
		message.Id = boost::lexical_cast<std::string>(boost::uuids::random_generator()());
	message.Readed = true;
	message.Servered = false;
	message.Sender = this->mJid;

	if (this->mUserDb.SaveChatMessage(message))
	{
        ChatDbModel chat = mUserDb.GetChatById(message.ChatId.c_str(), false);
        chat.Visible = true;
		if (mUserDb.SaveChat(chat))
			this->mChatNotifyer.Call(message.ChatId);
        
        if(!message.ReplacedId.empty())
            this->mChatMessageNotifyer.Call(message.ReplacedId);
        else
            this->mChatMessageNotifyer.Call(message.Id);
        
		mMessagesDelayedSender.Call(message);
		return true;
	}
	return false;
}

bool ApplicationMessengerApi::SendNotificationMessage(const ChatIdType& chatId, const ChatNotificationType& type, const ContactXmppIdSet& jids)
{
	ChatMessageDbModel message;
	message.ChatId = chatId;
	message.Id = this->PregenerateMessageId();
	message.Type = ChatMessageTypeNotification;
	message.StringContent = "#Notification#";
	message.ExtendedContent = NotificationToJson(type,jids);

	return this->SendMessage(message);
}

bool ApplicationMessengerApi::GetAllChats(ChatDbModelSet& result) const
{
	if (this->mUserDb.GetAllVisibleChats(result))
	{
		this->PrepareAndFilterChatsForView(result);
		return true;
	}
	return false;
}

bool ApplicationMessengerApi::GetChatsByIds(const ChatIdSet& ids, ChatDbModelSet& result) const
{
	if (this->mUserDb.GetChatsByIds(ids, result))
	{
		this->PrepareAndFilterChatsForView(result);
		return true;
	}
	return false;
}

bool ApplicationMessengerApi::GetChatMessages(const ChatIdType& chatId, ChatMessageDbModelSet& result) const
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start getting messages of chat " << chatId;

	if (this->mUserDb.GetChatMessages(chatId, result))
	{
		PrepareChatMessagesForView(result);
		logger(LogLevelDebug) << "End getting messages of chat" << LoggerStream::endl << result;
		return true;
	}
	logger(LogLevelDebug) << "End getting messages of chat with result false";
	return false;
}

bool ApplicationMessengerApi::GetMessagesByIds(const ChatMessageIdSet& ids, ChatMessageDbModelSet& result) const
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start getting chat messages by ids " << LoggerStream::endl << ids;

	if (this->mUserDb.GetMessagesByIds(ids, result))
	{
		PrepareChatMessagesForView(result);
		logger(LogLevelDebug) << "End getting chat messages by ids" << LoggerStream::endl << result;
		return true;
	}
	logger(LogLevelDebug) << "End getting messages with result false";
	return false;
}

ChatMessageDbModel ApplicationMessengerApi::GetLastMessageOfChat(const ChatIdType& chatId) const
{
	ChatMessageDbModel message = this->mUserDb.GetLastMessageOfChat(chatId);
	this->PrepareChatMessageForView(message);
	return message;
}
    
bool ApplicationMessengerApi::GetChatMessagesPaged(const ChatIdType& chatId, int pageSize, ChatMessageIdType const &lastMsgId, ChatMessageDbModelList& result) const
{
    if (this->mUserDb.GetChatMessagesPaged(chatId, pageSize, lastMsgId, result))
    {
        PrepareChatMessagesForView(result);
        return true;
    }
    return false;
}

void ApplicationMessengerApi::SendPushAboutMessage(const ChatMessageDbModel& message)
{
	std::string strMessage;
	UserNotificationType notificationType;
	AlertCategoryType alertCategory;
	switch (message.Type)
	{
	case ChatMessageTypeTextMessage:
		strMessage = message.StringContent;
		notificationType = dodicall::model::UserNotificationTypeXmpp;
		alertCategory = dodicall::model::XMNAC;
		break;
	/* Not supported yet
	case ChatMessageTypeAudioMessage:
		strMessage = "audio";
		break;
     */
	case ChatMessageTypeContact:
		strMessage = "contact";
        notificationType = dodicall::model::UserNotificationTypeXmppContact;
        alertCategory = dodicall::model::XCONTACT;
		break;
	
	case ChatMessageTypeNotification:
		if (message.ExtendedContent.find("invite") != message.ExtendedContent.npos)
		{
			strMessage = "invite";
			notificationType = dodicall::model::UserNotificationTypeXmppInviteToChat;
			alertCategory = dodicall::model::XMMIC;
		}
		break;
	}
    
	if (strMessage.empty())
        return;
	
    std::vector<std::string> xmppVector;

    ChatModel chat = this->DbChatToChatModel(mUserDb.GetChatById(message.ChatId.c_str(), false));

    for (auto iterator = begin(chat.Contacts); iterator != end(chat.Contacts); ++iterator)
    {
        ContactXmppIdType xmppId = iterator->GetXmppId();
        if (this->mJid != xmppId)
            xmppVector.push_back(xmppId);
    }

    PushNotificationModel notification;
    notification.AlertBody = strMessage;
    notification.AlertAction = AlertActionTypeLook;
    notification.HasAction = true;
    notification.SoundName = AlertSoundNameTypeMessage;
    notification.IconBadge = 1;
    notification.ExpireInSec = 345600;
    notification.DType = dodicall::NotificationRemote;
    notification.Type = dodicall::model::ServerTypeXmpp;
    notification.AType = alertCategory;

    notification.MetaStruct.From = this->mJid;
    notification.MetaStruct.Type = notificationType;
    notification.MetaStruct.ChatRoomJid = ((chat.IsP2p && mMamSupported) ? this->mJid : chat.Id);
    notification.MetaStruct.ChatRoomTitle = chat.Title;
    notification.MetaStruct.ChatMessageType = message.Type;
    notification.MetaStruct.ChatRoomCapacity = (chat.IsP2p ? 0 : chat.Contacts.size());
    if (notification.MetaStruct.ChatRoomCapacity <= 2)
        notification.MetaStruct.ChatRoomCapacity = 0;

    ContactModel myContact = this->GetAccountData();
    if (!myContact.DodicallId.empty())
        notification.AlertTitle = myContact.FirstName + ((myContact.LastName.empty() || myContact.FirstName.empty()) ? "" : " ") + myContact.LastName;
    else
        notification.AlertTitle = "Unknown";

    this->SendPushNotificationToXmppIds(xmppVector, notification);
}

void ApplicationMessengerApi::SendPushAboutInviteToContact(const ContactXmppIdType& xmppId)
{
    std::vector<std::string> xmppVector;
    xmppVector.push_back(xmppId);
    
    PushNotificationModel notification;
    notification.AlertBody = "contact invite";
    notification.AlertAction = AlertActionTypeLook;
    notification.HasAction = true;
    notification.SoundName = AlertSoundNameTypeMessage;
    notification.IconBadge = 1;
    notification.ExpireInSec = 345600;
    notification.DType = dodicall::NotificationRemote;
    notification.Type = dodicall::model::ServerTypeXmpp;
    notification.AType = dodicall::model::XMCIC;
    
    notification.MetaStruct.From = this->mJid;
    notification.MetaStruct.Type = dodicall::model::UserNotificationTypeXmppInviteContact;
    
    this->SendPushNotificationToXmppIds(xmppVector, notification);
}
    
bool ApplicationMessengerApi::JustSendMessage(const ChatMessageDbModel& message)
{
	bool sended = false;
	if (this->mConnectionState == XmppConnectionStateConnected && !this->mConferenceDomain.empty()) //DMC-5271
	{
        boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
		std::string messageType = ((message.ChatId.find(std::string("@") + this->mConferenceDomain) == message.ChatId.npos) ? "chat" : "groupchat");
		XmppHelper::SendXmppMessage(this->mConnection, message.Id.c_str(), messageType.c_str(), message.ChatId.c_str(),
			((message.StringContent.empty() || message.Type == ChatMessageTypeSubject) ? 0 : message.StringContent.c_str()),
			(message.ExtendedContent.empty() ? 0 : message.ExtendedContent.c_str()),
			(message.Type != ChatMessageTypeSubject ? 0 : message.StringContent.c_str()),
			(message.ReplacedId.empty() ? 0 : message.ReplacedId.c_str()), ((message.Type == ChatMessageTypeSubject && !message.ExtendedContent.empty()) ? message.ExtendedContent.c_str() : 0));
		sended = true;
	}
	return sended;
}

ChatIdType ApplicationMessengerApi::InviteAndRevokeChatMembers(const char* roomJid, ContactXmppIdSet& inviteList, ContactXmppIdSet& revokeList)
{
	ChatDbModel chat = this->mUserDb.GetChatById(roomJid, false);
	if (!chat || !chat.Active)
		return ChatIdType();

	for (auto it = begin(inviteList); it != end(inviteList);)
	{
		if (chat.ContactXmppIds.find(*it) != chat.ContactXmppIds.end())
		{
			this->mUserDb.RemoveUnsynchronizedChatEvent(chat.Id, UnsynchronizedChatEventDbModel(UnsynchronizedChatEventRevoke, *it));
			it = inviteList.erase(it);
		}
		else
			++it;
	}

	for (auto it = begin(revokeList); it != end(revokeList);)
	{
		if (chat.ContactXmppIds.find(*it) == chat.ContactXmppIds.end())
		{
			this->mUserDb.RemoveUnsynchronizedChatEvent(chat.Id, UnsynchronizedChatEventDbModel(UnsynchronizedChatEventInvite, *it));
			it = revokeList.erase(it);
		}
		else
			++it;
	}

	if (inviteList.empty() && revokeList.empty())
		return ChatIdType();

	if (chat.IsP2P && mMamSupported)
	{
		if (!revokeList.empty())
			return ChatIdType();

		ChatDbModel chatResult;

		for (auto it = begin(chat.ContactXmppIds); it != end(chat.ContactXmppIds); ++it)
			inviteList.insert(*it);

		if (RetrieveOrCreateMultiUserChat(inviteList, chatResult))
			return chatResult.Id;
		return ChatIdType();
	}

	for (auto iter = inviteList.begin(); iter != inviteList.end(); iter++)
	{
		chat.ContactXmppIds.insert(*iter);
		this->mUserDb.AddUnsynchronizedChatEvent(chat.Id, UnsynchronizedChatEventDbModel(UnsynchronizedChatEventInvite, *iter));
	}
	for (auto iter = revokeList.begin(); iter != revokeList.end(); iter++)
	{
		chat.ContactXmppIds.erase(*iter);
		this->mUserDb.AddUnsynchronizedChatEvent(chat.Id, UnsynchronizedChatEventDbModel(UnsynchronizedChatEventRevoke, *iter));
	}

	chat.IsP2P = false;
	chat.Synchronized = false;

	if (this->mUserDb.SaveChat(chat))
	{
		this->mChatNotifyer.Call(chat.Id);
		this->mChatRoomAserverizer.Call();
		return chat.Id;
	}
	return ChatIdType();
}

ContactModel ApplicationMessengerApi::GetMe(const ContactByXmppIdCache& cache)
{
	for (auto iter = cache.begin(); iter != cache.end(); iter++)
		if (iter->second.Iam)
			return iter->second;
	return ContactModel();
}

bool ApplicationMessengerApi::CreateChatWithContacts(const ContactXmppIdSet& xmppIds, ChatDbModel& result)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    logger(LogLevelDebug) << "Start CreateChatWithContacts";
    if (xmppIds.empty()) 
	{
        logger(LogLevelDebug) << "Failed CreateChatWithContacts";
        return false;
    }
    
	if (xmppIds.size() == 1 && mMamSupported)
		return this->RetrieveOrCreateP2pChat(*xmppIds.begin(),result, true);
    
    logger(LogLevelDebug) << "End CreateChatWithContacts" << result;
    return this->RetrieveOrCreateMultiUserChat(xmppIds,result);
}

bool ApplicationMessengerApi::MarkMessagesAsReaded(const ChatMessageIdType& untilMessageId)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start MarkMessagesAsReaded";
	bool result = this->mUserDb.MarkMessagesAsReaded(untilMessageId);
	if (result)
	{
		ChatMessageDbModel message = this->mUserDb.GetChatMessageById(untilMessageId);
		if (!message.ChatId.empty())
			this->mChatNotifyer.Call(message.ChatId);
	}
	logger(LogLevelDebug) << "End MarkMessagesAsReaded with result " << result;
	return result;
}

bool ApplicationMessengerApi::MarkAllMessagesAsReaded(void)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start MarkAllMessagesAsReaded";
	ChatIdSet chatIds;
	this->mUserDb.GetChatIdsWithNewMessages(chatIds);
	bool result = this->mUserDb.MarkAllMessagesAsReaded();
	if (result)
	{
		for (auto iter = chatIds.begin(); iter != chatIds.end(); iter++)
			this->mChatNotifyer.Call(*iter);
	}
	logger(LogLevelDebug) << "End MarkAllMessagesAsReaded with result " << result;
	return result;
}

bool ApplicationMessengerApi::CreateMultiUserChat(ChatDbModel& chat, ContactXmppIdSet const &userJidList, bool onServer)
{
	bool result = true;
	bool isNew = false;
	if (chat.Id.empty())
	{
		auto serverTime = LocalTimeToServer(posix_time_now());
		std::string t = boost::posix_time::to_iso_extended_string(serverTime);
		static const char charsToDelete[] = " -:T";
		for (unsigned int i = 0; i < sizeof(charsToDelete) - 1; ++i)
			t.erase(std::remove(t.begin(), t.end(), charsToDelete[i]), t.end());

		std::string randString = std::to_string(rand() % 100);
		while (randString.length() < 2)
			randString = std::string("0") + randString;
		randString += "x";
		
		// [jid_создателя_комнаты]YYYYMMDDHHMMSSXXX@[conference_domain]
		std::string name = CutDomain(this->mJid) + t + randString;

		chat.Id = name + (this->mConferenceDomain.empty() ? "" : (std::string("@") + this->mConferenceDomain));
		chat.ContactXmppIds.insert(this->mJid);
		for (auto it = begin(userJidList); it != end(userJidList); ++it)
            if (!it->empty())
                chat.ContactXmppIds.insert(*it);
		chat.Servered = false;
		chat.Synchronized = false;
		if (!this->mMamSupported && chat.ContactXmppIds.size() == 2)
            chat.IsP2P = true;
		result = this->mUserDb.SaveChat(chat);
		isNew = true;
	}

	if (result && !this->mConferenceDomain.empty() && chat.Id.find_first_of("@") == chat.Id.npos)
	{
		std::string newId = chat.Id + "@" + this->mConferenceDomain;
		if (this->mUserDb.UpdateChatId(chat.Id, newId))
			chat.Id = newId;
		else
			result = false;
	}

	if (result)
	{
		if (isNew && userJidList.size() > 1)
		{
			this->SendNotificationMessage(chat.Id, ChatNotificationTypeCreate, ContactXmppIdSet());
			ContactXmppIdSet filteredJidList;
			for (auto citer = userJidList.begin(); citer != userJidList.end(); ++citer) {
				if (*citer != this->mJid)
					filteredJidList.insert(*citer);
			}
			this->SendNotificationMessage(chat.Id, ChatNotificationTypeInvite, filteredJidList);
		}

		if (onServer)
			result = this->AsyncRequestAndProcess([this, chat]
			{
				std::string id = GenerateNextRequestId("chats");
				XmppHelper::CreateChatRoom(this->mConnection, (chat.Id + "/" + this->mNickname).c_str(), id.c_str());
				return id;
			}, [this, &chat, userJidList](xmpp_stanza_t* answer, bool sameThread)
			{
				if (!answer)
					return false;

				// checking result:
				const char* strFrom = xmpp_stanza_get_attribute(answer, "from");
				std::string from(strFrom);
				xmpp_stanza_t* x = xmpp_stanza_get_child_by_name(answer, "x");
				xmpp_stanza_t* item = xmpp_stanza_get_child_by_name(x, "item");

				return this->AsyncRequestAndProcess([this, chat, userJidList]
				{
					std::string id = GenerateNextRequestId("chats");
					XmppHelper::RequestConfigForm(this->mConnection, chat.Id.c_str(), id.c_str());
					return id;
				}, [this, &chat, userJidList](xmpp_stanza_t* answer, bool sameThread)
				{
					if (!answer)
						return false;
					return this->AsyncRequestAndProcess([this, chat, userJidList]
					{
						std::string id = GenerateNextRequestId("chats");
						XmppHelper::ConfigureChatRoom(this->mConnection, chat.Id.c_str(), id.c_str(), userJidList);
						return id;
					}, [this, &chat, userJidList](xmpp_stanza_t* answer, bool sameThread)
					{
						if (!answer)
							return false;

						const char* strResultType = xmpp_stanza_get_attribute(answer, "type");
						std::string resultType(strResultType);
						if (resultType == "error")
							return false;

						EnterToChatRoom((chat.Id + "/" + this->mNickname).c_str());

						return this->AsyncRequestAndProcess([this, chat, userJidList]
						{
							std::string id = GenerateNextRequestId("chats");
							XmppHelper::GrantRoomToUsers(this->mConnection, chat.Id.c_str(), userJidList, "owner", id.c_str());
							XmppHelper::InviteUsers(this->mConnection, chat.Id.c_str(), userJidList);
							return id;
						}, [this, &chat](xmpp_stanza_t* answer, bool sameThread)
						{
							if (!answer)
								return false;

							chat.Servered = true;
							chat.Synchronized = true;

							bool result = mUserDb.SaveChat(chat);
							if (result)
							{
								this->mChatNotifyer.Call(chat.Id);
								this->NotifyChatChanged(chat, true);

								this->ResendUnserveredMessages(chat.Id);
							}
							return result;
						});
					});
				});
			});
		else
			this->mChatRoomAserverizer.Call();
	}
	return result;
}

bool ApplicationMessengerApi::ClearChats(const ChatIdSet& chatIds, ChatIdSet& failed)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    logger(LogLevelDebug) << "Start ClearChats";
	ChatDbModelSet chats;
	if (this->mUserDb.GetChatsByIds(chatIds, chats))
	{
		bool result = true;
		for (auto iter = chats.begin(); iter != chats.end(); iter++)
		{
			bool notify = false;
			if (iter->Servered)
			{
                if (this->StoreChatPreferences(iter->Id, ChatPreferences((iter->IsP2p() ? posix_time_now() : posix_time_now()/*iter->LastModifiedDate*/), false, iter->CustomTitle)))
				{
					ChatDbModel chat = *iter;
                    chat.LastClearTime = chat.IsP2p() ? posix_time_now() : posix_time_now()/*chat.LastModifiedDate*/;
                    
					chat.Visible = false;
					if (!this->mUserDb.SaveChat(chat))
						result = false;
					notify = true;
				}
				else
					failed.insert(iter->Id);
			}
			else
			{
				// TODO: переработать
				// наверное, лучше досылать сообщения очищенного чата после появления сети
				if (this->mUserDb.DeleteChat(*iter))
					notify = true;
				else
				{
					result = false;
					failed.insert(iter->Id);
				}
			}
			if (notify)
				this->NotifyChatChanged(*iter, true);
		}
        logger(LogLevelDebug) << "End ClearChats" << result;
		return result;
	}
    logger(LogLevelDebug) << "Failed ClearChats";
	return false;
}

bool ApplicationMessengerApi::ExitChats(const ChatIdSet& chatIds, ChatIdSet& failed)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    logger(LogLevelDebug) << "Start ExitChats";
    if ( this->mConnectionState != XmppConnectionStateConnected) {
        logger(LogLevelDebug) << "Failed ExitChats";
        return false;
    }
    for (auto it = begin(chatIds); it != end(chatIds); ++it) {
        // "{\"type\":\"revoke\",\"jid\":\"00070207591-spb.swisstok.ru@swisstok.ru\",\"action\":\"leave\"}
        boost::property_tree::ptree msgJson;
    
        msgJson.add("type", "revoke");
        msgJson.add("jid", *it);
        msgJson.add("action", "leave");
    
        std::string postData = JsonHelper::ptree_to_json(msgJson);

        ChatMessageDbModel msg;
    
        std::string msgid = PregenerateMessageId();
        msg.Id = msgid;
        msg.ChatId = *it;
        msg.Type = ChatMessageTypeNotification;
        msg.StringContent = "#Notification#";
        msg.ExtendedContent = postData;
    
		if (!this->SendMessage(msg))
		{
			failed.insert(*it);
			continue;
		}
    
        ChatDbModel chat = this->mUserDb.GetChatById(*it);
		if (!chat)
		{
			failed.insert(*it);
			continue;
		}

        chat.Active = false;
        if (this->mUserDb.SaveChat(chat))
	        mChatNotifyer.Call(*it);
    }
    logger(LogLevelDebug) << "End ExitChats";
    return true;
}
    
bool ApplicationMessengerApi::RenameChat(const ChatIdType& chatId, const char* subject) 
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    logger(LogLevelDebug) << "Start RenameChat";
    
    ChatDbModel chat = this->mUserDb.GetChatById(chatId);
	if (!chat)
	{
		logger(LogLevelDebug) << "Failed RenameChat";
		return false;
	}
	if (chat.IsP2P)
    {
        logger(LogLevelDebug) << "Can't Rename P2P Chat";
        return false;
    }
	if (chat.CustomTitle == subject)
	{
		logger(LogLevelDebug) << "Failed RenameChat";
		return false;
	}

    ChatMessageDbModel msg;
    msg.ChatId = chatId;
    msg.Type = ChatMessageTypeSubject;
    msg.StringContent = subject;

	if (msg.StringContent.empty())
	{
		chat.CustomTitle.clear();
		ChatModel mChat = DbChatToChatModel(chat, true);
		msg.ExtendedContent = mChat.Title;
	}
    
    if (!this->SendMessage(msg))
    {
        logger(LogLevelDebug) << "Failed RenameChat";
        return false;
    }
    chat.CustomTitle = msg.StringContent;
    
    if (this->mUserDb.SaveChat(chat))
	    mChatNotifyer.Call(chat.Id);
    
    logger(LogLevelDebug) << "End RenameChat";
    return true;
}
    
bool ApplicationMessengerApi::SendContactToChat(const ChatMessageIdType& id, const ChatIdType& chatId, ContactModel const &contactData)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    
    logger(LogLevelDebug) << "Start SendContactToChat";
    
    ChatMessageDbModel msg;
    
    msg.Id = id;
    msg.ChatId = chatId;
    msg.Type = ChatMessageTypeContact;
    
    msg.StringContent = "{\"type\":\"Contact\"}";
    //"#Contact#";
    
    
    boost::property_tree::ptree contactTree;
    
    this->ContactToPtree(contactTree, contactData);
    
    std::string contactStr = JsonHelper::ptree_to_json(contactTree);
    
    msg.ExtendedContent = contactStr;
    
    if (!this->SendMessage(msg)) {
        logger(LogLevelDebug) << "Failed SendContactToChat";
        return false;
    }
    
    ChatDbModel chat = this->mUserDb.GetChatById(msg.ChatId);
    if (!chat) {
        logger(LogLevelDebug) << "Failed SendContactToChat";
        return false;
    }
    // ?
    //this->mUserDb.SaveChat(chat);
    
    this->mChatMessageNotifyer.Call(msg.Id);
    
    logger(LogLevelDebug) << "End SendContactToChat";
    return true;
}
    
bool ApplicationMessengerApi::CanEditMessage (const ChatMessageIdType &id)
{
    ChatMessageDbModel msg = this->mUserDb.GetChatMessageById(id);
    return this->CanEditMessage(msg);
}
    
bool ApplicationMessengerApi::CanEditMessage (const ChatMessageDbModel &msg)
{
	if (!msg || msg.Sender != this->mJid || ((posix_time_now() - msg.SendTime).total_seconds() > 10 * 60))
		return false;
	return true;
}
    
bool ApplicationMessengerApi::GetEditableMessageIdsForChat(const ChatIdType &id, ChatMessageIdSet &messages)
{
    ChatMessageDbModelSet dbresult;
    if (!this->GetChatMessages(id, dbresult))
        return false;
    
    for(auto iter = dbresult.begin(); iter!=dbresult.end(); ++iter)
    {
        if(this->CanEditMessage(*iter))
            messages.insert(iter->Id);
    }
    return true;
}
    
bool ApplicationMessengerApi::DeleteMessages(const ChatMessageIdSet& ids)
{
    ChatMessageDbModelSet removeMsgs;
    this->mUserDb.GetMessagesByIds(ids, removeMsgs);
    
    if (removeMsgs.empty())
        return false;
    
	bool result = true;
    for (auto it = begin(removeMsgs); it != end(removeMsgs); ++it)
    {
        if (!*it || this->mJid != it->Sender)
            continue;

        ChatMessageDbModel msg;
        msg.Id = PregenerateMessageId();
        msg.ReplacedId = it->Id;
        msg.ChatId = it->ChatId;
        msg.Type = ChatMessageTypeDeleter;
        msg.StringContent = "#Deleted#";
        
		if (!this->SendMessage(msg))
			result = false;
    }
    return result;
}
    
bool ApplicationMessengerApi::CorrectMessage(const ChatMessageIdType &id, const std::string &text)
{
    ChatMessageDbModel oldMessage = this->mUserDb.GetChatMessageById(id);
    
    if (!oldMessage || this->mJid != oldMessage.Sender)
        return false;
    
    ChatMessageDbModel newMessage;
    newMessage.Id = PregenerateMessageId();
    newMessage.ReplacedId = oldMessage.Id;
    newMessage.ChatId = oldMessage.ChatId;
    newMessage.Type = ChatMessageTypeTextMessage;
    newMessage.StringContent = text;
    
	return this->SendMessage(newMessage);
}
    
void ApplicationMessengerApi::ForceChatSync(const ChatIdType& id)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Force synchronization chat with id " << id;
	if (this->mConnectionState == XmppConnectionStateConnected && !this->mConferenceDomain.empty())
	{
        bool IsP2P = (GetDomain(id) != this->mConferenceDomain);
        if(!IsP2P)
        {
			this->mChatRoomAsynchronizer.Call(id);
            this->mForceChatId.clear();
        }
		// TODO: else use 4.1.1 Filtering by JID of xep-0313
	}
	else
    {
        this->mForceChatId = id;
        this->Ping();
    }
}

int ApplicationMessengerApi::DestroyChat(char const *roomJid)
{
    if ( this->mConnectionState != XmppConnectionStateConnected)
        return 0;
        
    XmppHelper::DestroyChatRoom(this->mConnection, roomJid, 0/*delId*/);
    
    return 1;
}

void ApplicationMessengerApi::PrepareAndFilterChatsForView(ChatDbModelSet& chats) const
{
	ChatDbModelSet::iterator iter = chats.begin();
	while (iter != chats.end())
	{
		if (!iter->Visible)
			iter = chats.erase(iter);
		else
			iter++;
	}
}

void ApplicationMessengerApi::PrepareChatMessageForView(ChatMessageDbModel& message) const
{
}

void ApplicationMessengerApi::StropheConnHandler(xmpp_conn_t* const conn, const xmpp_conn_event_t status, const int error, xmpp_stream_error_t* const stream_error, void* const userdata)
{
	ApplicationMessengerApi* self = (ApplicationMessengerApi*)userdata;
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	boost::lock_guard<boost::recursive_mutex> _lock(self->mMutex);

	switch (status)
	{
	case XMPP_CONN_CONNECT:
		self->SetConnectionState(XmppConnectionStateConnected);
		self->mBoundJid = xmpp_conn_get_bound_jid(self->mConnection);
		self->ChangeChatNetworkStatus(true);

		xmpp_handler_add(conn, ApplicationMessengerApi::StrophePresenceHandler, NULL, "presence", NULL, self);
		xmpp_handler_add(conn, ApplicationMessengerApi::StropheMessageHandler, NULL, "message", NULL, self);
		xmpp_handler_add(conn, ApplicationMessengerApi::StropheIqHandler, NULL, "iq", NULL, self);

		self->SendPresence();
		XmppHelper::DiscoverInfo(conn, self->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; }).c_str());
		self->RetrieveRoster();
		break;
	case XMPP_CONN_DISCONNECT:
	case XMPP_CONN_FAIL:
		self->SetConnectionState(XmppConnectionStateDisconnected);
		self->ChangeChatNetworkStatus(false);
		{
			boost::lock_guard<boost::mutex> _lock(self->mSubsMutex);
			for (AsyncRequestSubscriptionMap::const_iterator iter = self->mAsyncSubscriptions.begin(); iter != self->mAsyncSubscriptions.end(); iter++)
				iter->second->Event.notify_one();
			self->mAsyncSubscriptions.clear();
		}
		self->mSendedP2pMessages.Clear();
		if (self->mP2pChatsSynchronizer)
			self->mP2pChatsSynchronizer->interrupt();
		self->InterruptContactsSynchronization();
		self->mPingWdc = 0;
		break;
	}
}

int ApplicationMessengerApi::StrophePresenceHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata)
{
	ApplicationMessengerApi* self = (ApplicationMessengerApi*)userdata;

	boost::lock_guard<boost::recursive_mutex> _lock(self->mMutex);

	self->OnIncommingPacket();

	self->UserPresenceHandler(conn,stanza)
	|| self->UserSubscribesHandler(conn,stanza)
    ;

	self->AsyncRequestsHandler(conn, stanza);

	return 1;
}

int ApplicationMessengerApi::StropheMessageHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata)
{
	ApplicationMessengerApi* self = (ApplicationMessengerApi*)userdata;

	boost::lock_guard<boost::recursive_mutex> _lock(self->mMutex);

	self->OnIncommingPacket();

	self->ContactChangesNotificationHandler(conn,stanza) ||
	self->ChatChangesNotificationHandler(conn,stanza) ||
    self->P2PArchiveNotificationHandler(conn, stanza) ||
    self->ChatMessageNotificationHandler(conn,stanza) ||
	self->ReadyForCallNotificationHandler(conn,stanza);
	return 1;
}

int ApplicationMessengerApi::StropheIqHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata)
{
	ApplicationMessengerApi* self = (ApplicationMessengerApi*)userdata;
	boost::lock_guard<boost::recursive_mutex> _lock(self->mMutex);

	self->OnIncommingPacket();

	self->PingHandler(conn,stanza)
	|| self->TimeHandler(conn,stanza)
	|| self->ServiceDiscoveryHandler(conn,stanza)
	|| self->RosterHandler(conn,stanza)
	|| self->P2PArchiveEndHandler(conn, stanza)
	;
	
	self->AsyncRequestsHandler(conn, stanza);

	return 1;
}
    
void ApplicationMessengerApi::StropheLogHandler(void * const userdata, const xmpp_log_level_t level, const char * const area, const char * const msg)
{
	Logger& logger = LogManager::GetInstance().XmppLogger;
	LogLevel logLevel;
	switch(level)
	{
	case XMPP_LEVEL_DEBUG:
		logLevel = LogLevelDebug;
		break;
	case XMPP_LEVEL_INFO:
		logLevel = LogLevelInfo;
		break;
	case XMPP_LEVEL_WARN:
		logLevel = LogLevelWarning;
		break;
	case XMPP_LEVEL_ERROR:
		logLevel = LogLevelError;
		break;
	default:
		logger(LogLevelWarning) << "Unknown log level value";
		break;
	}
	logger(logLevel) << area << " - " << msg;
}

bool ApplicationMessengerApi::AsyncRequestsHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	const char* id = xmpp_stanza_get_attribute(stanza,"id");
	if (id)
	{
		boost::lock_guard<boost::mutex> _lock(this->mSubsMutex);
		AsyncRequestSubscriptionMap::iterator found = this->mAsyncSubscriptions.find(std::string(id));
		if (found != this->mAsyncSubscriptions.end())
		{
			xmpp_stanza_t* copy = xmpp_stanza_clone(stanza);
			found->second->Result = copy;
			found->second->Event.notify_one();
			this->mAsyncSubscriptions.erase(found);
			return true;
		}
	}
	return false;
}
bool ApplicationMessengerApi::PingHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	const char* id = xmpp_stanza_get_id(stanza);
	if (id && std::string(id) == "ping")
		return true;
	return false;
}
bool ApplicationMessengerApi::TimeHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	const char* id = xmpp_stanza_get_id(stanza);
	if (id && std::string(id) == "time")
	{
		bool found = false;
		xmpp_stanza_t* stime = xmpp_stanza_get_child_by_name(stanza,"time");
		if (stime)
		{
			xmpp_stanza_t* utc = xmpp_stanza_get_child_by_name(stime, "utc");
			if (utc)
			{
				XmppText strUtc(this->mConnection,utc);
				if (strUtc)
				{
					DateType serverTime = timestamp_to_posix_time(std::string(strUtc));
					this->mTimeDifference = posix_time_now() - serverTime;
					xmpp_info(xmpp_conn_get_context(conn), "dodicall", (std::string("Time difference with server is ") + boost::lexical_cast<std::string>(this->mTimeDifference.total_seconds()) + " seconds").c_str());
					found = true;
				}
			}
		}
		if (!found)
			xmpp_warn(xmpp_conn_get_context(conn), "dodicall", "Failed to parse urn:xmpp:time");
		XmppHelper::DiscoverItems(conn, this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; }).c_str());
		return true;
	}
	return false;
}
bool ApplicationMessengerApi::ServiceDiscoveryHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	xmpp_ctx_t* ctx = xmpp_conn_get_context(conn);

	xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(stanza,"query");
	if (query)
	{
		const char* strXmlns = xmpp_stanza_get_ns(query);
		std::string xmlns = (strXmlns ? strXmlns : "");
		const char* strFrom = xmpp_stanza_get_attribute(stanza,"from");
		std::string from = (strFrom ? strFrom : "");
		const char* strType = xmpp_stanza_get_type(stanza);
		std::string type = (strType ? strType : "");

		ServerSettingModel xmppSettings = this->mDeviceSettings.SafeGet<ServerSettingModel>([](const DeviceSettingsModel& self) { return self.GetXmppSettings(); });

		if (type == "result" && !from.empty())
		{
			if (xmlns == "http://jabber.org/protocol/disco#items" && from == xmppSettings.Domain)
			{
				this->mServicesCount = 0;
				this->mServicesDiscovered = 0;
				xmpp_stanza_t* services = xmpp_stanza_get_children(query);
				while (services)
				{
					const char* jid = xmpp_stanza_get_attribute(services, "jid");
					if (jid)
					{
						XmppHelper::DiscoverInfo(conn, jid);
						this->mServicesCount++;
					}
					services = xmpp_stanza_get_next(services);
				}
				return true;
			}
			else if (xmlns == "http://jabber.org/protocol/disco#info")
			{
				if (from == xmppSettings.Domain)
				{
					xmpp_stanza_t* feature = xmpp_stanza_get_child_by_name(query, "feature");
					while (feature)
					{
						const char* var = xmpp_stanza_get_attribute(feature, "var");
						if (var)
						{
							std::string strVar = var;
							if (strVar == "urn:xmpp:time")
							{
								this->mTimeSupported = true;
								XmppHelper::RequestTime(conn, this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; }).c_str());
							}
							if (strVar == "urn:xmpp:ping")
								this->mPingSupported = true;
                            if (strVar == "urn:xmpp:mam:1")
                            {
								if (!this->mMamSupported)
									this->mUserDb.SaveSetting("MamSupported", true);
								this->mMamSupported = true;
                                this->ResendUnserveredP2pMessages(); //DMC-5271
                                this->StartP2PArchiveRetrieval();
                            }
						}
						feature = xmpp_stanza_get_next(feature);
					}
					if (!this->mTimeSupported)
					{
						XmppHelper::DiscoverItems(conn, this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; }).c_str());
						xmpp_warn(ctx, "dodicall", "urn:xmpp:time feature is not supported");
					}
					if (!this->mPingSupported)
						xmpp_warn(ctx, "dodicall", "urn:xmpp:ping feature is not supported");
				}
				else
				{
					xmpp_stanza_t* identity = xmpp_stanza_get_child_by_name(query, "identity");

					if (identity)
					{
						const char* strCategory = xmpp_stanza_get_attribute(identity, "category");
						if (strCategory && std::string(strCategory) == "conference")
						{
							this->mConferenceDomain = from;
							this->mUserDb.SaveSetting("ConferenceDomain", this->mConferenceDomain);
							xmpp_stanza_t* features = xmpp_stanza_get_children(query);
							while (features)
							{
								const char* name = xmpp_stanza_get_name(features);
								if (name && std::string(name) == "feature")
								{
									const char* var = xmpp_stanza_get_attribute(features, "var");
									if (var && std::string(var) == "http://jabber.org/protocol/rsm")
									{
										this->mConferenceRsmSupported = true;
										break;
									}
								}
								features = xmpp_stanza_get_next(features);
							}
							if (!this->mForceChatId.empty())
								this->ForceChatSync(this->mForceChatId);
							this->SyncChatRooms();
							this->SyncP2pChats();
						}
					}

					if ((++this->mServicesDiscovered) >= this->mServicesCount)
					{
						if (this->mConferenceDomain.empty())
						{
							xmpp_error(ctx, "dodicall", "MUC service not found");
							xmpp_disconnect(conn);
						}
						else
						{
                            this->StartDirectoryContactsSynchronization();
							this->StartNativeContactsSynchronization();
						}
					}
				}
				return true;
			}
		}
	}
	return false;
}

bool ApplicationMessengerApi::RosterHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(stanza, "query");
	if (query)
	{
		const char* xmlns = xmpp_stanza_get_ns(query);
		if (xmlns && std::string(xmlns) == "jabber:iq:roster")
		{
			xmpp_stanza_t* item = xmpp_stanza_get_children(query);
			while (item)
			{
				const char* jid = xmpp_stanza_get_attribute(item, "jid");
				const char* subscription = xmpp_stanza_get_attribute(item, "subscription");
				const char* ask = xmpp_stanza_get_attribute(item, "ask");

				if (jid && subscription)
				{
					std::string strJid = jid;
					std::string strSubscription = subscription;

					if (strSubscription == "remove")
						this->mRoster.Erase(strJid);
					else
					{
						ContactSubscriptionState state;
						if (strSubscription == "from")
							state = ContactSubscriptionStateFrom;
						else if (strSubscription == "to")
							state = ContactSubscriptionStateTo;
						else if (strSubscription == "both")
							state = ContactSubscriptionStateBoth;
						else
							state = ContactSubscriptionStateNone;

						auto func = [this, state, ask, strJid]()
						{
							ContactSubscriptionModel newSubscription(state, (ask ? true : false), this->GetSubscriptionStatus(strJid.c_str()));
							boost::optional<ContactSubscriptionModel> found = this->GetRosterRecord(strJid);
							if (!found || (found->SubscriptionState != newSubscription.SubscriptionState
								|| found->AskForSubscription != newSubscription.AskForSubscription
								|| found->SubscriptionStatus != newSubscription.SubscriptionStatus))
							{
								this->ChangeContactSubscriptionAndProcess(strJid, newSubscription);
								if (!newSubscription.IsToEnabled())
								{
									boost::lock_guard<boost::mutex> _lock(this->mUserStatusesMutex);
									this->mUserStatuses.erase(strJid);
								}
								if (newSubscription.IsFromEnabled())
									this->JustSendPresence();
							}
						};
						if (boost::this_thread::get_id() == this->mIterator->get_id())
							this->mThreadsOnlyThenLoggedIn.StartThread(func);
						else
							func();
					}
				}
				item = xmpp_stanza_get_next(item);
			}

			const char* type = xmpp_stanza_get_type(stanza);
			if (type && std::string(type) == "set")
			{
				const char* id = xmpp_stanza_get_id(stanza);
				boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
				XmppHelper::SendIqResult(this->mConnection, id, this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; }).c_str());
				this->SendPresence();
			}
			return true;
		}
	}
	return false;
}
    
bool ApplicationMessengerApi::P2PArchiveEndHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
    xmpp_stanza_t* iqFin = xmpp_stanza_get_child_by_name(stanza,"fin");
    
    if (!iqFin)
        return false;
    
    xmpp_stanza_t* iqSet = xmpp_stanza_get_child_by_name(iqFin,"set");
    
    if (iqSet)
    {
        char const *setns = xmpp_stanza_get_ns(iqSet);
        std::string strNs = (setns ? setns : "");
        if (!strNs.compare("http://jabber.org/protocol/rsm"))
        {
            p2pArchiveSynced = true;
            // start p2p chats sync
            
            Logger& logger = LogManager::GetInstance().TraceLogger;
            
            logger(LogLevelDebug) << "Received end of p2p archive";

			this->ResendUnserveredP2pMessages();

            return true;
        }
    }
    return false;
}
    
bool ApplicationMessengerApi::UserPresenceHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	std::string from = xmpp_stanza_get_attribute(stanza,"from");
    
    std::size_t foundSlash = from.find_first_of("/");
    std::string deviceKey;
    if (foundSlash != std::string::npos)
        deviceKey = from.substr(foundSlash+1);
        
	std::string fromJid = CutJid(from);
	
	const char* pType = xmpp_stanza_get_type(stanza);
	std::string type(pType ? pType : "");

	if (this->mConferenceDomain.empty() || fromJid.find("@"+this->mConferenceDomain) == fromJid.npos)
	{
		if (type == "unavailable" || type.empty())
		{
			BaseUserStatus baseStatus = BaseUserStatusOffline;
			std::string extStatus;
			if (type.empty())
			{
				xmpp_stanza_t* show = xmpp_stanza_get_child_by_name(stanza,"show");
				XmppText pShowStr(this->mConnection,show);
				std::string showStr(pShowStr ? pShowStr : "");
				baseStatus = StringToBaseStatus(showStr,(this->mJid == fromJid));

				xmpp_stanza_t* status = xmpp_stanza_get_child_by_name(stanza,"status");
				XmppText pStatusStr(this->mConnection, status);
				extStatus = (pStatusStr ? pStatusStr : "");
            }

			if (fromJid == this->mJid && from != this->mBoundJid)
				this->SendPresence(false);
			else
			{
				std::string key = ((this->mJid == fromJid) ? "My" : fromJid);
				boost::lock_guard<boost::mutex> _slock(this->mUserStatusesMutex);
                
                auto userMapIterator = this->mUserStatuses.find(key);
                
                if (userMapIterator == this->mUserStatuses.end())
                {
                    this->mUserStatuses[key] = DeviceStatusesMap();
					userMapIterator = this->mUserStatuses.find(key);
                }
                
				time_t bgTime = (time_t)0;

				auto deviceMapIterator = userMapIterator->second.find(deviceKey);
				/* DMC-1821
				if (boost::starts_with(deviceKey, "iOS"))
				{
					time_t now = posix_time_to_time_t(posix_time_now());
					if (deviceMapIterator != userMapIterator->second.end())
					{
						bgTime = deviceMapIterator->second.get<2>();
						if (baseStatus == BaseUserStatusOffline && bgTime == (time_t)0)
						{
							baseStatus = deviceMapIterator->second.get<0>();
							extStatus = deviceMapIterator->second.get<1>();
							bgTime = now;
						}
						else
							bgTime = (time_t)0;
					}
				}
				*/
				bool notify = (deviceMapIterator == userMapIterator->second.end() || baseStatus != deviceMapIterator->second.get<0>() || extStatus != deviceMapIterator->second.get<1>());
				
				userMapIterator->second[deviceKey] = boost::tuple<BaseUserStatus, std::string, time_t>(baseStatus, extStatus, bgTime);

				if (this->mCurrentBaseStatus == BaseUserStatusOffline)
				{
					this->mUserStatuses.clear();
					this->mPresenceNotifyer.Cancel();
					this->mSimpleCallbacker.Call("PresenceOffline");
				}
				else if (notify)
					this->mPresenceNotifyer.Call(key);
			}
			return true;
		}
		else if (type == "probe")
		{
			this->JustSendPresence();
			return true;
		}
	}
	return false;
}

bool ApplicationMessengerApi::UserSubscribesHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	const char* type = xmpp_stanza_get_type(stanza);
	std::string strType = (type ? type : "");
	const char* from = xmpp_stanza_get_attribute(stanza, "from");
	if (strType == "subscribe")
	{
		if (from)
			this->ProcessSubscriptionAsk(from);
		return true;
	}
	return false;
}

bool ApplicationMessengerApi::ContactChangesNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	const char* from = xmpp_stanza_get_attribute(stanza,"from");
	std::string fromStr = (from ? from : "");

	xmpp_stanza_t* body = xmpp_stanza_get_child_by_name(stanza, "body");
	XmppText bodyStr(this->mConnection,body);
	std::string strBody = (bodyStr ? bodyStr : "");
    
	if (!fromStr.empty() && boost::starts_with(fromStr,this->mJid))
	{
		if (strBody == "#ContactChanged#")
		{
			xmpp_stanza_t* data = xmpp_stanza_get_child_by_name(stanza, "data");
			XmppText dataStr(this->mConnection, data);
			if (fromStr != xmpp_conn_get_bound_jid(conn))
			{
                if (dataStr) 
				{
					this->StartDirectoryContactsSynchronization(dataStr);
                    //free(dataStr);
                }
                else
					this->StartNativeContactsSynchronization();
			}
			return true;
		}
	}
	else if (strBody == "#InviteCancelled#")
	{
		this->RemoveSubscriptionAsk(this->CutJid(fromStr));
		return true;
	}
	return false;
}

bool ApplicationMessengerApi::ChatChangesNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	const char* from = xmpp_stanza_get_attribute(stanza, "from");
	std::string fromStr = (from ? from : "");

	xmpp_stanza_t* body = xmpp_stanza_get_child_by_name(stanza, "body");
	XmppText bodyStr(this->mConnection,body);
	std::string strBody = (bodyStr ? bodyStr : "");

	xmpp_stanza_t* data = xmpp_stanza_get_child_by_name(stanza, "data");
	XmppText dataStr(this->mConnection, data);
    
	// TODO: remove legacy "#RoomCreated#" sygnal processing
	if (fromStr != this->mBoundJid &&  (dataStr && strBody == "#ChatChanged#" || strBody == "#RoomCreated#"))
	{
        ChatDbModelSet found;
        std::string chatId = (dataStr ? dataStr : "");
		if (!chatId.empty())
			this->mChatRoomAsynchronizer.Call(chatId);
		else
			this->SyncChatRooms();
        return true;
	}
	return false;
}

bool ApplicationMessengerApi::ReadyForCallNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
	const char* from = xmpp_stanza_get_attribute(stanza, "from");

	xmpp_stanza_t* body = xmpp_stanza_get_child_by_name(stanza, "body");
	XmppText bodyStr(this->mConnection,body);

	if (from && bodyStr && std::string(bodyStr) == "#ReadyForCall#" && std::string(CutJid(from)) != this->mJid)
	{
        Logger& logger = LogManager::GetInstance().TraceLogger;
        logger(LogLevelDebug) << "#ReadyForCall# recieved";
        
        this->RecallToContact(this->RetriveContactByXmppId(CutJid(from)));
		return true;
	}
	return false;
}

bool ApplicationMessengerApi::RetrieveOrCreateP2pChat(const ContactXmppIdType& xmppId, ChatDbModel& result, bool needSync)
{
    if (xmppId.empty())
        return false;
    
	result = this->mUserDb.GetChatById(xmppId, false);
	if ((bool)result)
		return true;
    else
    {
        result.IsP2P = true;
        result.Servered = false;
        result.Visible = false;
        result.Active = true;
        result.Id = xmppId;
        
        result.ContactXmppIds.insert(this->mJid);
        result.ContactXmppIds.insert(xmppId);
        
        if (this->mUserDb.SaveChat(result))
        {
            this->mChatNotifyer.Call(result.Id);
            
            if (!needSync)
                return true;

			return
            this->AsyncRequestAndProcess([this, &result]
            {
                std::string id = GenerateNextRequestId("chats");
                
                XmppHelper::RetrieveArchivePrefs(this->mConnection, id.c_str());
                return id;
            }, [this,xmppId,&result](xmpp_stanza_t* answer, bool sameThread)
                {
                    // @todo: properly check for config unsupported error?
                
                    xmpp_stanza_t* prefs = xmpp_stanza_get_child_by_name(answer,"prefs");
                    if (!prefs)
                        return false;
                    char const *xmlns = xmpp_stanza_get_ns(prefs);
                
                    xmpp_stanza_t* always = xmpp_stanza_get_child_by_name(prefs,"always");
                    if (!always)
                        return false;
                
                    xmpp_stanza_t* alwaysIds = xmpp_stanza_get_children(always);
                
                    ContactXmppIdSet userJidList;
                    while (alwaysIds)
                    {
                        XmppText idStr(this->mConnection,alwaysIds);
                        std::string strId = (idStr ? idStr : "");
                        if (!strId.empty())
                            userJidList.insert(strId);
                        
                        alwaysIds = xmpp_stanza_get_next(alwaysIds);
                    }
                
                    userJidList.insert(xmppId);
                
                    return this->AsyncRequestAndProcess([this,xmppId,&userJidList]
                    {
                        std::string id = GenerateNextRequestId("chats");
                        
                        XmppHelper::SetArchivePrefs(this->mConnection, userJidList, id.c_str());
                        
                        return id;
                    }, [this,xmppId](xmpp_stanza_t* answer, bool sameThread)
                    {
                    
                        // optionally check?
                        xmpp_stanza_t* prefs = xmpp_stanza_get_child_by_name(answer,"prefs");
                        if (!prefs)
                            return false;
                        
                        ChatDbModel chatResult = this->mUserDb.GetChatById(xmppId, false);
                        
                        chatResult.Servered = true;
                            
                        if (this->mUserDb.SaveChat(chatResult))
	                        this->mChatNotifyer.Call(chatResult.Id);
                        
                        return true;
                    });
                }
            );
        }
    }
    return false;
}

bool ApplicationMessengerApi::RetrieveOrCreateMultiUserChat(const ContactXmppIdSet& contacts, ChatDbModel& result)
{
    if (contacts.size() == 1)
    {
        if ( (*contacts.begin()).empty() )
            return false;
        ChatDbModelSet found;
        if (this->mUserDb.GetP2pChatByMemberId(*contacts.begin(), found) && !found.empty())
        {
            for (auto iter = found.begin(); iter != found.end(); iter++)
                if (iter->Visible)
                    result = *iter;
                    // no need to set isP2P here, should be marked as such in sql
            if (!result)
            {
                result = *found.begin();
                result.Visible = true;
                // no need to set isP2P here, should be marked as such in sql
                ChatPreferences prefs = this->RetrieveChatPreferences(result.Id);
                prefs.Visible = true;
                if (posix_time_to_time_t(result.LastClearTime) > 0)
                {
                    prefs.LastClearTime = posix_time_now();
                    result.LastClearTime = prefs.LastClearTime;
                }
                if (this->mUserDb.SaveChat(result) && this->StoreChatPreferences(result.Id, prefs))
                    return true;
            }
            else
                return true;
        }
    }
    return CreateMultiUserChat(result, contacts);
}
    
void ApplicationMessengerApi::ResendUnserveredMessages(const ChatIdType& chatId)
{
	ChatMessageDbModelList dbmessages;
	if (this->mUserDb.GetUnserveredMessages(chatId, dbmessages))
	{
		for (auto iter = dbmessages.begin(); iter != dbmessages.end(); iter++)
			this->mMessagesDelayedSender.Call(*iter);
	}
}

void ApplicationMessengerApi::ResendUnserveredP2pMessages(void)
{
	if (!this->mMamSupported)
		return;
	ChatMessageDbModelList dbmessages;
	if (this->mUserDb.GetUnserveredP2pMessages(dbmessages))
	{
		for (auto iter = dbmessages.begin(); iter != dbmessages.end(); iter++)
			this->SendMessage(*iter);
	}
}

void ApplicationMessengerApi::SetMsgTime(xmpp_stanza_t *delay, ChatMessageDbModel &msg)
{
    if (!delay)
        return;
        
    char const *stamp = xmpp_stanza_get_attribute(delay, "stamp");
        
    if (!stamp)
        return;
    
    DateType sendTime = timestamp_to_posix_time(std::string(stamp));
        
    if (msg.SendTime > sendTime)
        msg.SendTime = ServerTimeToLocal(sendTime);
}
    
bool ApplicationMessengerApi::ParseMessage(xmpp_stanza_t* const serverMsg, ChatMessageDbModel &message)
{
	const char* type = xmpp_stanza_get_attribute(serverMsg, "type");
	std::string typeStr = (type ? type : "");
	if (typeStr.empty() || !(typeStr == "groupchat" || typeStr == "chat"))
		return false;

	char const *id = xmpp_stanza_get_attribute(serverMsg, "id");
	if (!id)
		return false;
	std::string strId = (id ? id : "");

	const char* from = xmpp_stanza_get_attribute(serverMsg, "from");
	char const *to = xmpp_stanza_get_attribute(serverMsg, "to");
	if (!from || !to)
		return false;

	std::string strFrom = from;
	std::string strTo = CutJid(to);

	message.Id = strId;
	message.ChatId = strFrom;

	std::string::size_type delim = message.ChatId.find_first_of("/");
	if (delim == message.ChatId.npos)
		return false;

	if (typeStr == "chat") // p2p
	{
		message.ChatId = message.ChatId.substr(0, delim);
		message.Sender = message.ChatId;
		if (message.ChatId == this->mJid)
			message.ChatId = strTo;
	}
	else // muc
	{
		message.Sender = message.ChatId.substr(delim + 1) + "@" + this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; });
		message.ChatId = message.ChatId.substr(0, delim);
	}

    xmpp_stanza_t* body = xmpp_stanza_get_child_by_name(serverMsg, "body");
    XmppText strBody(this->mConnection,body);
    
    xmpp_stanza_t* x = xmpp_stanza_get_child_by_name(serverMsg, "x");
    if (x)
    {
        char const *xmlns = xmpp_stanza_get_ns(x);
        std::string xmlnsStr = (xmlns ? xmlns : "");
        if (xmlnsStr == "jabber:x:encrypted")
            message.Encrypted = true;
    }
	xmpp_stanza_t* encryption = xmpp_stanza_get_child_by_name(serverMsg, "encryption");
	if (encryption)
		message.Encrypted = true;
    
    xmpp_stanza_t* data = xmpp_stanza_get_child_by_name(serverMsg, "data");
    XmppText strData(this->mConnection,data);
        
    if (strBody && strBody[0])
    {
        message.Type = ChatMessageTypeTextMessage;
        message.StringContent = std::string(strBody ? strBody : "");
            
        const std::string cNotificationTag = "#Notification#";
        // TODO: change to #Contact#
        const std::string cContactTag = "{\"type\":\"Contact\"}";
        // TODO: change to #Audio#
        const std::string cAudioTag = "{\"type\":\"Audio\"";
        if (strData)
        {
            if (message.StringContent.find(cNotificationTag) == 0)
            {
                message.Type = ChatMessageTypeNotification;
                message.StringContent = "";
                message.ExtendedContent = strData;
            }
            else if (message.StringContent.find(cContactTag) == 0)
            {
                message.Type = ChatMessageTypeContact;
                message.StringContent = "";
                message.ExtendedContent = strData;
            }
            else if (message.StringContent.find(cAudioTag) == 0)
            {
                message.Type = ChatMessageTypeAudioMessage;
                message.StringContent = "";
                // TODO: save data to file
            }
        }
    }

    xmpp_stanza_t* replace = xmpp_stanza_get_child_by_name(serverMsg, "replace");
	if (replace)
	{
		const char* strReplace = xmpp_stanza_get_attribute(replace, "id");
		message.ReplacedId = (strReplace ? strReplace : "");


		const std::string cDeleterTag = "#Deleted#";
		// TODO: add <data>#Deleted#
		if (message.StringContent.find(cDeleterTag) == 0)
		{
			message.Type = ChatMessageTypeDeleter;
			message.StringContent = "";
		}
	}

	xmpp_stanza_t* subject = xmpp_stanza_get_child_by_name(serverMsg, "subject");
	XmppText strSubject(this->mConnection, subject);

	if (subject)
	{
		message.Type = ChatMessageTypeSubject;
		message.StringContent = strSubject ? strSubject : "";
		if (message.StringContent.empty() && strData)
			message.ExtendedContent = strData;
	}

	return true;
}

ChatNotificationData ApplicationMessengerApi::ParseNotificationMessage(const ChatMessageDbModel& message) const
{
	ChatNotificationData notification;
	if (message.Type == ChatMessageTypeNotification)
	{
		boost::property_tree::ptree notificationTree;
		if (JsonHelper::json_to_ptree(message.ExtendedContent.c_str(), notificationTree))
		{
			std::string action = notificationTree.get<std::string>("action", "");
			if (!action.empty())
			{
				bool known = true;
				if (action == "create")
					notification.Type = ChatNotificationTypeCreate;
				else if (action == "invite")
					notification.Type = ChatNotificationTypeInvite;
				else if (action == "revoke")
					notification.Type = ChatNotificationTypeRevoke;
				else if (action == "leave")
					notification.Type = ChatNotificationTypeLeave;
				else if (action == "remove")
					notification.Type = ChatNotificationTypeRemove;
				else
					known = false;
				if (known)
				{
					notification.Contacts.insert(ContactModel());
					ContactModel& contact = (ContactModel&)*notification.Contacts.begin();
					std::string jid = notificationTree.get<std::string>("jid", "");;
					if (!jid.empty())
						contact.Contacts.insert(ContactsContactModel(jid,ContactsContactXmpp));
					else
					{
						boost::optional<boost::property_tree::ptree&> jidsTree = notificationTree.get_child_optional("jids");
						if (jidsTree)
						{
							for (boost::property_tree::ptree::const_iterator iter = jidsTree->begin(); iter != jidsTree->end(); iter++)
							{
								jid = iter->second.data();
								if (!jid.empty())
									contact.Contacts.insert(ContactsContactModel(jid, ContactsContactXmpp));
							}
						}
					}
				}
				else
				{
					// TODO: log warning
				}
			}
		}
	}
	return notification;
}

ContactModel ApplicationMessengerApi::ParseContactMessage(const ChatMessageDbModel& message) const
{
	ContactModel contact;
	boost::property_tree::ptree contactTree;
	if (JsonHelper::json_to_ptree(message.ExtendedContent.c_str(), contactTree))
	{
		contact.DodicallId = contactTree.get<std::string>("swisstok_id", "");
        
		if (contact.DodicallId.empty())
		{
			// TODO: support manual contacts
		}
	}
	return contact;
}

bool ApplicationMessengerApi::P2PArchiveNotificationHandler(xmpp_conn_t* const conn, xmpp_stanza_t* const stanza)
{
    xmpp_stanza_t* result = xmpp_stanza_get_child_by_name(stanza,"result");
    
    if (result)
    {
		const char* xmlns = xmpp_stanza_get_ns(result);
		if (xmlns && std::string(xmlns) == "urn:xmpp:mam:1")
		{
			xmpp_stanza_t* forwarded = xmpp_stanza_get_child_by_name(result, "forwarded");
			xmpp_stanza_t* serverMsg = 0;
			if (forwarded && (serverMsg = xmpp_stanza_get_child_by_name(forwarded, "message")))
			{
				ChatMessageDbModel msg;
				msg.Servered = true;
				

				if (this->ParseMessage(serverMsg, msg))
				{
                    xmpp_stanza_t *delay = xmpp_stanza_get_child_by_name(forwarded, "delay");
                    
                    SetMsgTime(delay, msg);
                    
					this->mMessageProcessor.Call(msg);
					return true;
				}
			}
		}
    }
    return false;
}
    
bool ApplicationMessengerApi::ChatMessageNotificationHandler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza)
{
    const char* type = xmpp_stanza_get_attribute(stanza,"type");
    std::string typeStr = (type ? type : "");
    if (typeStr.empty())
        return false;
    
    const char* from = xmpp_stanza_get_attribute(stanza,"from");
    
	if (from)
	{
		std::string strFrom = from;
		if (typeStr == "normal" && strFrom.find(std::string("@")+this->mConferenceDomain) != strFrom.npos)
		{
			xmpp_stanza_t* x = xmpp_stanza_get_child_by_name(stanza, "x");
			if (x)
			{
				const char* xmlns = xmpp_stanza_get_ns(x);
				if (xmlns && !strcmp(xmlns, "http://jabber.org/protocol/muc#user"))
				{
					xmpp_stanza_t* invite = xmpp_stanza_get_child_by_name(x, "invite");
					if (invite)
					{
						this->mChatRoomAsynchronizer.Call(strFrom);
						return true;
					}
				}
			}
		}
		else
		{
			ChatMessageDbModel msg;
			msg.Servered = true;

			if (this->ParseMessage(stanza, msg))
			{
                xmpp_stanza_t *delay = xmpp_stanza_get_child_by_name(stanza, "delay");
                
                SetMsgTime(delay, msg);
                
				this->mMessageProcessor.Call(msg);
				return true;
			}
		}
	}
    return false;
}

std::string ApplicationMessengerApi::CutJid (const std::string& fullJid)
{
	return fullJid.substr(0,fullJid.find_first_of('/'));
}
std::string ApplicationMessengerApi::CutJidDomain(const std::string& jid)
{
	return CutDomain(jid);
}

ContactModel ApplicationMessengerApi::PtreeToContact(const boost::property_tree::ptree& tree) const
{
	ContactModel contact;
	contact.NativeId = tree.get<std::string>("native_id","");
	std::string phonebookId = tree.get<std::string>("phonebook_id","");
	std::string phonebookDeviceId = tree.get<std::string>("phonebook_device_id","");
	if (phonebookDeviceId == this->mDeviceModel.Uid)
		contact.PhonebookId = phonebookId;
	contact.FirstName = tree.get<std::string>("first_name","");
	contact.LastName = tree.get<std::string>("last_name","");
	if (contact.FirstName == "null")
		contact.FirstName.clear();
	if (contact.LastName == "null")
		contact.LastName.clear();
	if (contact.FirstName.empty() && contact.LastName.empty())
	{
		std::string title = tree.get<std::string>("title","");
		std::vector<std::string> splits;
		boost::split(splits,title,boost::is_any_of(" "));
		if (!splits.empty())
		{
			contact.FirstName = splits.at(0);
			if (splits.size() > 1)
				contact.LastName = splits.at(1);
		}
	}
	contact.MiddleName = tree.get<std::string>("middle_name","");
	contact.Blocked = tree.get<int>("blocked",0);
	contact.White = tree.get<int>("white",0);
	
	// TODO: change to contacts_crypted and decrypt
	boost::property_tree::ptree subContactsTree = tree.get_child("contactsArr");
	for (boost::property_tree::ptree::const_iterator citer = subContactsTree.begin(); citer != subContactsTree.end(); citer++)
	{
		ContactsContactModel cts;
		std::string strType = citer->second.get<std::string>("contact_type","");
		if (!strType.empty())
		{
			cts.Type = StringToContactsContactType(strType);
			if (cts.Type == ContactsContactSip)
				continue;
			cts.Identity = citer->second.get<std::string>("contact_identy","");
			cts.Favourite = citer->second.get<int>("contact_favour",0);
			cts.Manual = citer->second.get<int>("manual",1);
			if (!cts.Identity.empty())
				contact.Contacts.insert(cts);
		}
	}
	contact.Synchronized = true;
	return contact;
}
bool ApplicationMessengerApi::JsonToContactsSet(const char* contactsJson, ContactModelSet& contacts) const
{
	boost::property_tree::ptree contactsTree;
	if (JsonHelper::json_to_ptree(contactsJson,contactsTree))
	{
		for (boost::property_tree::ptree::const_iterator iter = contactsTree.begin(); iter != contactsTree.end(); iter++)
			contacts.insert(PtreeToContact(iter->second));
		return true;
	}
	return false;
}
    
    
void ApplicationMessengerApi::ContactToPtree(boost::property_tree::ptree &contactTree, ContactModel const &contact) const{
    if (!contact.PhonebookId.empty())
    {
        contactTree.put("phonebook_id",contact.PhonebookId);
        contactTree.put("phonebook_device_id",this->mDeviceModel.Uid);
    }
    contactTree.put("native_id",contact.NativeId);
    contactTree.put("first_name",contact.FirstName);
    contactTree.put("last_name",contact.LastName);
    contactTree.put("middle_name",contact.MiddleName);
    contactTree.put("blocked",contact.Blocked?1:0);
    contactTree.put("white",contact.White?1:0);
    contactTree.put("swisstok_id",contact.DodicallId);
    
    
    boost::property_tree::ptree subTree;
    for (ContactsContactSet::const_iterator citer = contact.Contacts.begin(); citer != contact.Contacts.end(); citer++)
    {
        boost::property_tree::ptree cTree;
        std::string type;
        if (citer->Type == ContactsContactSip)
            continue;
        else if (citer->Type == ContactsContactXmpp)
            type = "xmpp";
        else if (citer->Type == ContactsContactPhone)
            type = "phone";
        else
        {
            // TODO: log warning
        }
        cTree.put("contact_type",type);
        cTree.put("contact_identy",citer->Identity);
        cTree.put("contact_favour",citer->Favourite?1:0);
        cTree.put("manual",citer->Manual?1:0);
        
        subTree.push_back(std::make_pair("",cTree));
    }
    contactTree.add_child("contactsArr",subTree);
}
 
std::string ApplicationMessengerApi::NotificationToJson(const ChatNotificationType& type, const ContactXmppIdSet& jids)
{
	boost::property_tree::ptree msgJson;
	std::string action;
	switch (type)
	{
	case ChatNotificationTypeCreate:
		action = "create";
		break;
	case ChatNotificationTypeInvite:
		action = "invite";
		break;
	case ChatNotificationTypeRevoke:
		action = "revoke";
		break;
	case ChatNotificationTypeLeave:
		action = "leave";
		break;
	case ChatNotificationTypeRemove:
		action = "remove";
		break;
	default:
		// TODO: log warning
		break;
	}
	if (!action.empty())
	{
		msgJson.add("type", action);
		msgJson.add("action", action);
		if (jids.size() > 1)
		{
			boost::property_tree::ptree jidsJson;
			for (auto iter = jids.begin(); iter != jids.end(); iter++)
			{
				boost::property_tree::ptree jidJson;
				jidJson.put("", *iter);
				jidsJson.push_back(std::make_pair("", jidJson));
			}
			msgJson.add_child("jids", jidsJson);
		}
		else if (!jids.empty())
			msgJson.add("jid", *jids.begin());
		return JsonHelper::ptree_to_json(msgJson);
	}
	return "";
}

std::string ApplicationMessengerApi::ContactsSetToJson(const ContactModelSet& contacts) const
{
	boost::property_tree::ptree contactsTree;
	for (ContactModelSet::const_iterator iter = contacts.begin(); iter != contacts.end(); iter++)
	{
		boost::property_tree::ptree contactTree;
        
        this->ContactToPtree(contactTree, (*iter));
		
		contactsTree.push_back(std::make_pair("",contactTree));
	}
	boost::property_tree::ptree resultTree;
	resultTree.push_back(std::make_pair("contacts",contactsTree));

	return JsonHelper::ptree_to_json_array(resultTree);
}

void ApplicationMessengerApi::SyncChatRoomPrefs(ChatDbModel& chat, const ChatMessageDbModel& lastMessage)
{
	ChatPreferences prefs = this->RetrieveChatPreferences(chat.Id);

	bool reprefs = false;
	if (prefs.LastClearTime < chat.LastClearTime || (chat.Visible && !prefs.Visible && (bool)lastMessage && lastMessage.SendTime > prefs.LastClearTime))
	{
		if (prefs.LastClearTime < chat.LastClearTime)
			prefs.LastTitle = chat.CustomTitle;
		else
			chat.CustomTitle = prefs.LastTitle;
		prefs.LastClearTime = chat.LastClearTime;
		prefs.Visible = chat.Visible;
		reprefs = true;
	}
	else
	{
		chat.CustomTitle = prefs.LastTitle;
		chat.Visible = prefs.Visible;
		chat.LastClearTime = prefs.LastClearTime;
	}

	if (reprefs && this->StoreChatPreferences(chat.Id, prefs))
		this->NotifyChatChanged(chat.Id, true);
}

bool ApplicationMessengerApi::SyncChatRoom(const ChatIdType& jid, ChatIdSet* pActiveChatIds, std::string changerJid)
{
	ChatDbModel chat = this->mUserDb.GetChatById(jid, false);
	ChatDbModel exists = chat;

	ContactXmppIdSet serverMembers;
	if (this->RetrieveChatMembers(jid, serverMembers))
	{
		if (pActiveChatIds)
			pActiveChatIds->insert(jid);
		if (!chat || chat.Synchronized)
		{
			chat.ContactXmppIds = serverMembers;
			if (!chat)
				chat.Id = jid;

			chat.Active = true;
			if (!this->mMamSupported && !exists && chat.ContactXmppIds.size() == 2)
				chat.IsP2P = true;

			this->RetriveContactsByXmppIds(chat.ContactXmppIds);

			ChatMessageDbModel lastMessage = this->mUserDb.GetLastMessageOfChat(chat.Id);
			this->SyncChatRoomPrefs(chat, lastMessage);

			if (this->mUserDb.SaveChat(chat))
			{
				using namespace std;
				DateType lastTime = max(((bool)lastMessage ? lastMessage.SendTime : time_t_to_posix_time((time_t)0)), chat.LastClearTime);
				if (posix_time_to_time_t(lastTime) > 0)
					this->EnterToChatRoom((chat.Id + "/" + this->mNickname).c_str(), (posix_time_now() - lastTime).total_seconds() + 60);
				else
					this->EnterToChatRoom((chat.Id + "/" + this->mNickname).c_str());
				this->ResendUnserveredMessages(chat.Id);

				if ((chat || exists) && !equals(chat, exists))
					this->mChatNotifyer.Call(((bool)chat) ? chat.Id : exists.Id);

				return true;
			}
		}
		else
		{
			UnsynchronizedChatEventDbSet unsynchronizedEvents;
			if (this->mUserDb.GetUnsynchronizedChatEvents(chat.Id, unsynchronizedEvents))
			{
				ContactXmppIdSet contactsToInvite, contactsToRevoke;

				for (auto iter = unsynchronizedEvents.begin(); iter != unsynchronizedEvents.end(); iter++)
					switch (iter->Type)
					{
					case UnsynchronizedChatEventInvite:
						contactsToInvite.insert(iter->Identity);
						break;
					case UnsynchronizedChatEventRevoke:
						contactsToRevoke.insert(iter->Identity);
						break;
					}

				auto doInvite = [this, contactsToInvite, &chat]
				{
					bool result = true;
					if (!contactsToInvite.empty())
						result = this->AsyncRequestAndProcess([this, contactsToInvite, chat]
						{
							std::string id = GenerateNextRequestId("chats");
							XmppHelper::GrantRoomToUsers(this->mConnection, chat.Id.c_str(), contactsToInvite, "owner", id.c_str());
							XmppHelper::InviteUsers(this->mConnection, chat.Id.c_str(), contactsToInvite);
							return id;
						}, [this, &chat, contactsToInvite](xmpp_stanza_t* answer, bool sameThread)
						{
							if (answer)
								this->SendNotificationMessage(chat.Id, ChatNotificationTypeInvite, contactsToInvite);
							return (bool)answer;
						});
					if (result)
					{
						chat.Synchronized = true;
						result = this->mUserDb.SaveChat(chat);
						this->mChatRoomAsynchronizer.Call(chat.Id);
					}
					return result;
				};

				if (contactsToRevoke.empty())
					return doInvite();
				return this->AsyncRequestAndProcess([this, chat, contactsToRevoke]
				{
					std::string id = GenerateNextRequestId("chats");
					XmppHelper::GrantRoomToUsers(this->mConnection, chat.Id.c_str(), contactsToRevoke, "none", id.c_str());
					return id;
				}, [this, chat, contactsToRevoke, doInvite](xmpp_stanza_t* answer, bool sameThread)
				{
					bool result = false;
					if (answer)
					{
						this->SendNotificationMessage(chat.Id, ChatNotificationTypeRevoke, contactsToRevoke);
						result = doInvite();
					}
					return result;
				});
			}
		}
	}
	else if (this->mConnectionState == XmppConnectionStateConnected)
	{
		if ((bool)chat && chat.Active)
		{
			ChatPreferences prefs = this->RetrieveChatPreferences(chat.Id);
			if (!changerJid.empty() && prefs.RevokedBy != changerJid)
			{
				prefs.RevokedBy = changerJid;
				this->StoreChatPreferences(chat.Id, prefs);
			}
			if (!prefs.RevokedBy.empty())
			{
				static boost::mutex lmMutex;
				boost::lock_guard<boost::mutex> _lock(lmMutex);

				ChatMessageDbModel lastMessage = this->mUserDb.GetLastMessageOfChat(chat.Id);
				if (!
					((bool)lastMessage && lastMessage.Type == ChatMessageTypeNotification
						&& (lastMessage.ExtendedContent.find("revoke") != lastMessage.ExtendedContent.npos
							&& lastMessage.ExtendedContent.find(this->mJid) != lastMessage.ExtendedContent.npos
							|| lastMessage.ExtendedContent.find("remove") != lastMessage.ExtendedContent.npos))
					)
				{
					lastMessage = ChatMessageDbModel();
					lastMessage.Id = this->PregenerateMessageId();
					lastMessage.ChatId = chat.Id;
					lastMessage.Type = ChatMessageTypeNotification;
					lastMessage.Readed = false;
					lastMessage.Sender = prefs.RevokedBy;
					lastMessage.Servered = true;
					lastMessage.ExtendedContent = std::string("{\"type\":\"revoke\",\"jid\":\"") + this->mJid + "\",\"action\":\"revoke\"}";
					if (this->mUserDb.SaveChatMessage(lastMessage))
						this->mChatMessageNotifyer.Call(lastMessage.Id);
				}
			}
			chat.Active = false;
			if (this->mUserDb.SaveChat(chat))
				this->mChatNotifyer.Call(chat.Id);
			else
				return false;
		}
		return true;
	}
	else if (pActiveChatIds)
		pActiveChatIds->insert(jid);
	return false;
}
bool ApplicationMessengerApi::SyncP2pChat(const ChatIdType& jid)
{
	ChatDbModelSet chatList;
	if (this->mUserDb.GetP2pChatByMemberId(jid, chatList) && !chatList.empty())
	{
		ChatDbModel chat = *chatList.begin();
		ChatDbModel origin = chat;
		this->SyncChatRoomPrefs(chat, this->mUserDb.GetLastMessageOfChat(chat.Id));
		if (!equals(chat, origin) && this->mUserDb.SaveChat(chat))
			this->mChatNotifyer.Call(chat.Id);
		return true;
	}
	return false;
}

void ApplicationMessengerApi::StartP2PArchiveRetrieval()
{
    this->AsyncRequestAndProcess([this]
    {
        std::string id = this->GenerateNextRequestId("chats");
		time_t lastP2pMessageTime = this->mUserDb.GetLastP2pMessageTime();
		if (lastP2pMessageTime)
			XmppHelper::QueryLatestArchive(this->mConnection, id.c_str(), (LocalTimeToServer(time_t_to_posix_time(lastP2pMessageTime))) - boost::posix_time::seconds(10));
		else
	        XmppHelper::QueryUserArchive(this->mConnection, id.c_str());
        return id;
    }, [this](xmpp_stanza_t* answer, bool sameThread)
    {
        return true;
    });
}

    
void ApplicationMessengerApi::RequestLatestP2PArchiveLive()
{
    this->AsyncRequestAndProcess([this]
    {
        std::string id = this->GenerateNextRequestId("chats");
        XmppHelper::QueryLatestArchive(this->mConnection, id.c_str(), (LocalTimeToServer(posix_time_now() - boost::posix_time::seconds(60))));
        return id;
    }, [this](xmpp_stanza_t* answer, bool sameThread)
    {
        return true;
    }
    );
}

ChatIdSet ApplicationMessengerApi::SyncChatRooms(int limit, const ChatIdType& afterId)
{
	ChatIdSet result;

	this->mChatRoomAserverizer.Call();

	this->AsyncRequestAndProcess([this, limit, afterId]
		{
			std::string id = this->GenerateNextRequestId("chats");
			XmppHelper::DiscoverItems(this->mConnection,this->mConferenceDomain.c_str(), id.c_str(), limit, afterId.c_str());
			return id;
		}, [this,&result](xmpp_stanza_t* answer, bool sameThread)
		{
			xmpp_stanza_t* query = xmpp_stanza_get_child_by_name(answer,"query");
			if (query) 
			{
				const char* strXmlns = xmpp_stanza_get_ns(query);
				std::string xmlns = (strXmlns ? strXmlns : "");
				const char* strFrom = xmpp_stanza_get_attribute(answer,"from");
				std::string from = (strFrom ? strFrom : "");
				const char* strType = xmpp_stanza_get_type(answer);
				std::string type = (strType ? strType : "");
        
				if (xmlns == "http://jabber.org/protocol/disco#items" && from == this->mConferenceDomain) 
				{
					ChatIdSet activeChatIds;
					xmpp_stanza_t* chatRooms = xmpp_stanza_get_children(query);
					while (chatRooms) 
					{
						std::string name = xmpp_stanza_get_name(chatRooms);
						if (name == "item")
						{
							char const *jid = xmpp_stanza_get_attribute(chatRooms, "jid");
							if (jid)
							{
								if (this->mConferenceRsmSupported && std::string(jid) == "conference.localhost")
								{
									activeChatIds = this->SyncChatRooms(CHAT_ROOMS_BULK_SIZE);
									break;
								}
								this->SyncChatRoom(jid, &activeChatIds);
							}
						}
						if (name == "set")
						{
							const char* xmlns = xmpp_stanza_get_ns(chatRooms);
							if (xmlns && std::string(xmlns) == "http://jabber.org/protocol/rsm")
							{
								xmpp_stanza_t* last = xmpp_stanza_get_child_by_name(chatRooms, "last");
								if (last)
								{
									XmppText aLastValue(mConnection, last);
									std::string lastValue = static_cast<const char*>(aLastValue);
									xmpp_stanza_t* first = xmpp_stanza_get_child_by_name(chatRooms, "first");
									if (!first || lastValue != XmppText(mConnection,first))
									{
										ChatIdSet nextActiveChatIds = this->SyncChatRooms(CHAT_ROOMS_BULK_SIZE, lastValue);
										activeChatIds.insert(nextActiveChatIds.begin(), nextActiveChatIds.end());
										if (sameThread)
											result = activeChatIds;
									}
									return true;
								}
							}
						}
						chatRooms = xmpp_stanza_get_next(chatRooms);
					}
					ChatIdSet chatIdsToDeactivate;
					if (this->mUserDb.GetActiveMultiUserChatIds(activeChatIds, chatIdsToDeactivate))
					{
						bool result = this->mUserDb.DeactivateMultiUserChats(chatIdsToDeactivate);
						for (auto iter = chatIdsToDeactivate.begin(); iter != chatIdsToDeactivate.end(); iter++)
							this->mChatNotifyer.Call(*iter);
						return result;
					}
					return false;
				}
			}
			return false;
		});
	return result;
}

void ApplicationMessengerApi::SyncP2pChats(void)
{
	this->mP2pChatsSynchronizer = this->mThreadsOnlyThenLoggedIn.StartThread([this]
	{
		if (this->mMamSupported)
		{
			ChatDbModelSet chats;
			if (this->mUserDb.GetAllP2pChats(chats))
				for (auto iter = chats.begin(); iter != chats.end(); iter++)
					this->SyncP2pChat(iter->Id);
			boost::this_thread::interruption_point();
		}
		this->ResendUnserveredP2pMessages(); //DMC-5271
	});
}

void ApplicationMessengerApi::SynchronizeChatRooms(void)
{
	bool success = true;
	while (success)
	{
		ChatDbModelSet unsynchronizedChats;
		bool exists = false;
		if (this->mUserDb.GetUnsynchronizedChats(unsynchronizedChats) && !unsynchronizedChats.empty())
		{
			for (auto iter = unsynchronizedChats.begin(); iter != unsynchronizedChats.end(); iter++)
			{
				ChatDbModel chat = *iter;
				if (!chat.IsP2P || !this->mMamSupported)
				{
					exists = true;
					ContactXmppIdSet contacts = chat.ContactXmppIds;
					for (auto citer = contacts.begin(); citer != contacts.end(); citer++)
						if (*citer == this->mJid)
						{
							contacts.erase(citer);
							break;
						}
					if (iter->Servered)
					{
						if (!this->SyncChatRoom(chat.Id))
							success = false;
					}
					else if (!this->CreateMultiUserChat(chat, contacts, true))
						success = false;
				}
			}
		}
		if (!exists)
			break;
	}
}

void ApplicationMessengerApi::NotifyChatChanged(const ChatDbModel& chat, bool onlyMe)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mConnectionState == XmppConnectionStateConnected)
	{
		if (onlyMe)
			XmppHelper::SendXmppMessage(this->mConnection, 0, "normal", this->mJid.c_str(), "#ChatChanged#", chat.Id.c_str(), 0, 0, true);
		else
			for (ContactXmppIdSet::const_iterator iter = chat.ContactXmppIds.begin(); iter != chat.ContactXmppIds.end(); iter++)
				XmppHelper::SendXmppMessage(this->mConnection, 0, "normal", iter->c_str(), "#ChatChanged#", ((this->mMamSupported && chat.IsP2P && *iter != this->mJid) ? this->mJid : chat.Id).c_str(), 0, 0, true);
	}
}

void ApplicationMessengerApi::ProcessBackgroundStatuses(void)
{
	for (auto siter = this->mUserStatuses.begin(); siter != this->mUserStatuses.end(); siter++)
	{
		bool notify = false;
		for (auto diter = siter->second.begin(); diter != siter->second.end(); diter++)
		{
			time_t bgTime = diter->second.get<2>();
			if (bgTime && (bgTime + BACKGROUND_PRESENCE_TTL) <= posix_time_to_time_t(posix_time_now()))
			{
				diter->second = boost::tuple<BaseUserStatus, std::string, time_t>(BaseUserStatusOffline, std::string(""), (time_t)0);
				notify = true;
			}
		}
		if (notify)
			this->mPresenceNotifyer.Call(siter->first);
	}
}

void ApplicationMessengerApi::ProcessIncomingMessages(const std::vector<ChatMessageDbModel>& messages)
{
	ChatMessageDbModelSet dbMessages;
	{
		ChatMessageIdSet ids;
		for (auto iter = messages.begin(); iter != messages.end(); iter++)
			ids.insert(iter->Id);
		this->mUserDb.GetMessagesByIds(ids, dbMessages, true);
	}

	std::string domain = this->mDeviceSettings.SafeGet<std::string>([](const DeviceSettingsModel& self) { return self.GetXmppSettings().Domain; });
	std::map<ChatIdType,ChatDbModel> chatCache;
	std::map<ChatIdType, ChatPreferences> chatPrefsCache;

	for (auto iter = messages.begin(); iter != messages.end(); iter++)
	{
		ChatMessageDbModel msg = *iter;
		ChatDbModel chat;
		ChatPreferences prefs;

		bool isP2p = (GetDomain(msg.ChatId) != this->mConferenceDomain);

		auto found = chatCache.find(msg.ChatId);
		if (found != chatCache.end())
			chat = found->second;
		else if ((bool)(chat = this->mUserDb.GetChatById(msg.ChatId, false)))
			chatCache[msg.ChatId] = chat;
		
		{
			auto pfound = chatPrefsCache.find(msg.ChatId);
			if (pfound != chatPrefsCache.end())
				prefs = pfound->second;
			else
			{
				prefs = this->RetrieveChatPreferences(msg.ChatId);
				chatPrefsCache[msg.ChatId] = prefs;
			}
		}

		if (chat)
		{
            /*if (isP2p) {
                std::string s1 = to_simple_string(chat.LastClearTime);
                std::string s2 = to_simple_string(msg.SendTime);
                int x = 11;
                int y = x +1;
            }*/
			if (msg.SendTime < chat.LastClearTime)
				continue;
		}
		else
		{
			if (isP2p)
			{
				if (msg.SendTime < prefs.LastClearTime || !this->RetrieveOrCreateP2pChat(msg.ChatId, chat, false))
					continue;
			}
			else
				continue;
		}

		ChatMessageDbModel current;
		for (auto miter = dbMessages.begin(); miter != dbMessages.end(); miter++)
			if (miter->Id == msg.Id)
			{
				current = *miter;
				break;
			}

		ChatDbModel original = chat;
		ChatPreferences originalPrefs = prefs;
		if (mUserDb.SaveChatMessage(msg) && msg.IsNew)
		{
			if ((bool)current && !current.Servered)
				this->SendPushAboutMessage(msg);

			if (msg.Sender == this->mJid)
				this->MarkMessagesAsReaded(msg.Id);
			else
				this->RetriveContactByXmppId(msg.Sender);
	
			if (msg.Type == ChatMessageTypeNotification)
			{
				ChatNotificationData notification = this->ParseNotificationMessage(msg);
				if (notification.Contacts.begin() != notification.Contacts.end())
				{
					for (auto citer = notification.Contacts.begin()->Contacts.begin(); citer != notification.Contacts.begin()->Contacts.end(); citer++)
						if (citer->Type == ContactsContactXmpp)
							this->RetriveContactByXmppId(citer->Identity);
				}
			}
			else if (msg.Type == ChatMessageTypeContact)
			{
				ContactModel contact = this->ParseContactMessage(msg);
				if (!contact.DodicallId.empty())
					contact = this->RetriveContactByDodicallId(contact.DodicallId);
			}

			if (!isP2p)
			{
				/* TODO: think about this
				if (msg.ExtendedContent.find("revoke") != msg.ExtendedContent.npos && msg.Sender != this->mJid)
				{
					size_t found = msg.ExtendedContent.find("jid", 0);

					if (found != std::string::npos)
					{
						size_t found_jid = msg.ExtendedContent.find(":", found + 1);
						std::string revokedJid = msg.ExtendedContent.substr(found_jid + 1, std::string::npos);
						char const charsToDelete[] = "\\\"}";
						for (unsigned int i = 0; i < sizeof(charsToDelete) - 1; ++i)
							revokedJid.erase(std::remove(revokedJid.begin(), revokedJid.end(), charsToDelete[i]), revokedJid.end());
						if (revokedJid.compare(this->mJid) == 0)
							return true;
					}
				}
				*/

				if (msg.Type == ChatMessageTypeNotification)
				{
					if (msg.ExtendedContent.find("remove") == msg.ExtendedContent.npos)
					{
						/*
						@todo: переделать это или кривую рассылку уведомлений о покидании
						if (msg.ExtendedContent.find("revoke") != msg.ExtendedContent.npos && msg.Sender == this->mJid)
						{
						std::set<std::string> revoke_self;
						revoke_self.insert(this->mJid);
						if (chat.ContactXmppIds.size() > 1)
						XmppHelper::GrantRoomToUsers(this->mConnection, chat.Id.c_str(), revoke_self, "none");
						else
						XmppHelper::DestroyChatRoom(this->mConnection, chat.Id.c_str(), 0);
						this->NotifyChatChanged(chat);
						}*/
						if (!this->mMamSupported && chat.IsP2P && msg.ExtendedContent.find("create") != msg.ExtendedContent.npos)
							chat.IsP2P = false;
						else
							this->mChatRoomAsynchronizer.Call(msg.ChatId);
					}
					else
					{
						if (msg.Sender == this->mJid)
						{
							if (mUserDb.DeleteChat(chat))
								chat = ChatDbModel();
						}
						else
							this->mChatRoomAsynchronizer.Call(msg.ChatId);
					}
				}
				else
				{
					if (msg.Type == ChatMessageTypeSubject)
					{
						if (chat.CustomTitle != msg.StringContent)
							prefs.LastTitle = chat.CustomTitle = msg.StringContent;
					}
				}
				this->mChatNotifyer.Call(msg.ChatId);
			}
            
			if (!msg.ReplacedId.empty())
				this->mChatMessageNotifyer.Call(msg.ReplacedId);
			else
				this->mChatMessageNotifyer.Call(msg.Id);

			if ((bool)chat)
			{
				chat.Visible = prefs.Visible = true;
				chat.Servered = true;

				if (!equals(chat, original))
				{
					mUserDb.SaveChat(chat);
					chatCache[chat.Id] = chat;
				}
				if (!equals(prefs, originalPrefs))
				{
					this->StoreChatPreferences(chat.Id, prefs);
					chatPrefsCache[chat.Id] = prefs;
				}
			}
            this->mChatNotifyer.Call(msg.ChatId);
		}
	}
}

void ApplicationMessengerApi::OnIncommingPacket(void)
{
	this->mPingWdc = 0;
	
	ChatMessageIdSet p2pMsgIds;
	this->mSendedP2pMessages.Swap(p2pMsgIds);
	
	ChatMessageDbModelSet messages;
	ChatIdSet chatToNotifyIds;

	this->mUserDb.GetMessagesByIds(p2pMsgIds, messages, true);
	for (auto iter = messages.begin(); iter != messages.end(); iter++)
	{
		((ChatMessageDbModel&)*iter).Servered = true;
		this->mMessageProcessor.Call(*iter);
		chatToNotifyIds.insert(iter->ChatId);
	}

	if (!chatToNotifyIds.empty())
	{
		ChatDbModelSet chatsToNotify;
		if (this->mUserDb.GetChatsByIds(chatToNotifyIds, chatsToNotify))
			for (auto iter = chatsToNotify.begin(); iter != chatsToNotify.end(); iter++)
				this->NotifyChatChanged(*iter, true);
	}
}

bool equals(const ApplicationMessengerApi::ChatPreferences& left, const  ApplicationMessengerApi::ChatPreferences& right)
{
	return (left.LastClearTime == right.LastClearTime && left.LastTitle == right.LastTitle && left.Visible == right.Visible && left.RevokedBy == right.RevokedBy);
}

LoggerStream operator << (LoggerStream s, const ChatDbModel& chat)
{
	return s << "{ Id = " << chat.Id << ", CustomTitle = " << chat.CustomTitle << ", Active = " << chat.Active << ", Visible = " << chat.Visible << ", LastClearTime = " << chat.LastClearTime << ", ContactXmppIds = " << chat.ContactXmppIds << ", TotalMessagesCount = " << chat.TotalMessagesCount << ", NewMessagesCount = " << chat.NewMessagesCount << ", LastModifiedDate = " << chat.LastModifiedDate << " } ";
}
LoggerStream operator << (LoggerStream s, const ChatMessageDbModel& msg)
{
	return s << "{ Rownum = " << msg.Rownum << ", Id = " << msg.Id << ", ChatId = " << msg.ChatId << ", Sender = " << msg.Sender << ", Servered = " << msg.Servered << ", SendTime = " << msg.SendTime << ", Readed = " << msg.Readed << ", Type = " << msg.Type << ", StringContent = " << msg.StringContent << ", ExtendedContent = " << msg.ExtendedContent << ", ReplacedId = " << msg.ReplacedId << " } ";
}

LoggerStream operator << (LoggerStream s, const ContactPresenceStatusModel& presence)
{
	s << "{ XmppId = " << presence.XmppId << ", BaseStatus = " << (int)presence.BaseStatus << ", ExtStatus = " << presence.ExtStatus << " }";
	return s;
}

}
