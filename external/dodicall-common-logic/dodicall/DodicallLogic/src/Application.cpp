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
#include "Application.h"

#include "ThreadHelper.h"
#include "JsonHelper.h"
#include "LogManager.h"
#include "StringUtils.h"

namespace dodicall
{

Application::Application(): mChatReconnectedAfterResume(false)
{
}

void Application::SendReadyForCallAfterStart(const std::string& pusherSipNumber)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start SendReadyForCallAfterStart";
    
    this->mPusher.Contacts.insert(ContactsContactModel(pusherSipNumber));
	if (this->mApplicationServer.IsLoggedIn())
		this->mPusher = this->RetriveContactByNumberInternal(this->mPusher.Contacts.begin()->Identity, false);
    
    logger(LogLevelDebug) << "End SendReadyForCallAfterStart";
}

BaseResult Application::Login(const std::string& login, const std::string& password, int area)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start Login with login = " << login << " and area = " << area;

	BaseResult result = ApplicationServerApi::Login(login.c_str(),password.c_str(),area);
	if (result.Success)
	{
		this->mSimpleCallbacker.Call("LoggedIn");
        this->mGlobalDb.SaveGlobalApplicationSettings(GlobalApplicationSettingsModel(login.c_str(),password.c_str(),area));
		if (!this->StartBackgroundLogin(login, password, area, false))
			result = ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    }
	logger(LogLevelDebug) << "End Login with result " << result;
	return result;
}

bool Application::TryAutoLogin(void)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start trying autologin";

	bool result = false;
	if (this->mGlobalDb.IsOpened())
	{
		GlobalApplicationSettingsModel settings = this->mGlobalDb.GetGlobalApplicationSettings();
		if (!settings.LastLogin.empty() && !settings.LastPassword.empty())
		{
			this->mServerArea = settings.Area;
			result = this->StartBackgroundLogin(settings.LastLogin, settings.LastPassword, settings.Area, true);
		}
	}

	logger(LogLevelDebug) << "End trying autologin with result " << result;
	return result;
}

bool Application::StartBackgroundLogin(const std::string& login, const std::string& password, int area, bool accountDataNeeded)
{
#if !defined(_WIN32) || !defined(_DEBUG)		
	this->mUserCrypter.Init(password.c_str());
#endif
	bool result = true;
	if (this->mUserDb.IsOpened() || this->OpenUserDb(this->mUserDb, login.c_str()))
	{
		if (accountDataNeeded && !this->mUserDb.GetAccountData())
		{
			this->mUserDb.Close();
			return this->Login(login, password, area).Success;
		}

		if (!this->ApplicationVoipApi::Prepare() || !this->ApplicationMessengerApi::Prepare())
			result = false;

		if (result)
		{
			if (!this->GetUserSettings().TraceMode)
				LogManager::GetInstance().SetNonDebugLevel();

			this->mThreadsOnlyThenLoggedIn.StartThread([this](std::string login, std::string password, int area)
			{
				auto waitForNetwork = [this]
				{
					unsigned tryCount = 0;
					do
					{
						boost::this_thread::sleep(boost::posix_time::seconds(5));
					} while (this->mNetworkState.Technology == NetworkTechnologyNone || (++tryCount) % 20 == 0);
				};
				while (!this->mApplicationServer.IsLoggedIn())
				{
					BaseResult result = ApplicationServerApi::Login(login.c_str(), password.c_str(), area);
					if (result.Success)
                    {
						this->mSimpleCallbacker.Call("LoggedIn");
                        break;
                    }
					else if (result.ErrorCode == ResultErrorAuthFailed)
					{
						this->mSimpleCallbacker.Call("Logout");
						this->mGlobalDb.SaveSetting("LastPassword", "");
						this->Logout();
						break;
					}
					else
						waitForNetwork();
				}
				if (this->mApplicationServer.IsLoggedIn())
				{
					this->mThreadsOnlyThenLoggedIn.StartThread([this]
					{
						this->CyclicUpdateChecker();
					});

					Logger& logger = LogManager::GetInstance().TraceLogger;

					bool hasDeviceSettings = false;
					bool hasAccountDataUpdatedInDb = false;
					bool hasAccountDataUpdatedOnPush = false;
                    bool hasHoldingInfoUpdatedInDb = false;

					while (!hasDeviceSettings || !hasAccountDataUpdatedOnPush)
					{
						if (!hasDeviceSettings)
						{
							BaseResult result = this->RetrieveDeviceSettings();
							if (result.Success)
							{
								ApplicationVoipApi::Start();
								ApplicationMessengerApi::Start();
								hasDeviceSettings = true;
                                this->mSimpleCallbacker.Call("DeviceSettingsUpdated");
							}
							else if (result.ErrorCode != ResultErrorNoNetwork)
								logger(LogLevelWarning) << "Failed to retrieve device settings";
						}
						if (!hasAccountDataUpdatedInDb)
						{
							ContactModel iAm = this->GetAccountData(false);
							if (iAm)
                            {
								hasAccountDataUpdatedInDb = true;
                                this->mSimpleCallbacker.Call("AccountDataUpdated");
                            }
						}
                        if (!hasHoldingInfoUpdatedInDb && hasAccountDataUpdatedInDb)
                        {
                            ContactModel iAmDb = this->mUserDb.GetAccountData();
                            if (iAmDb)
                            {
                                CompanyIdsSet companies;
                                BaseResult result = this->GetCompaniesInMyHolding (iAmDb.CompanyId, companies);
                                
                                if (result.Success && this->mUserDb.SetHoldingCompanyIds(companies))
									hasHoldingInfoUpdatedInDb = true;
                            }
                        }
                        if (!hasAccountDataUpdatedOnPush && hasAccountDataUpdatedInDb)
						{
							BaseResult result = this->UpdateAccountDataOnPushServer();
							if (result.Success)
								hasAccountDataUpdatedOnPush = true;
							else if (result.ErrorCode != ResultErrorNoNetwork)
								logger(LogLevelWarning) << "Failed to register my contacts on push server";
						}

						waitForNetwork();
					}
				}
			}, login, password, area);
		}
	}
	if (!result && this->mUserDb.IsOpened())
		this->mUserDb.Close();
	return result;
}

void Application::SendReadyForCallIfNeeded(void)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start SendReadyForCallIfNeeded";
    
    if (!this->mPusher.DodicallId.empty() && this->mNetworkState.VoipStatus && this->mNetworkState.ChatStatus
#ifdef TARGET_OS_IPHONE
		&& this->mChatReconnectedAfterResume
#endif
		)
	{
		if (!this->YetActiveCalls())
        {
			logger(LogLevelDebug) << "No active calls, continue SendReadyForCall to " << this->mPusher.GetXmppId();
            this->ApplicationMessengerApi::SendReadyForCall(this->mPusher.GetXmppId());
        }
		this->mPusher = ContactModel();
	}
    
    logger(LogLevelDebug) << "End SendReadyForCallIfNeeded";
}

void Application::CyclicUpdateChecker(void)
{
	if (this->mPusher.DodicallId.empty() && !this->mPusher.Contacts.empty())
	{
		this->mPusher = this->RetriveContactByNumberInternal(this->mPusher.Contacts.begin()->Identity, false);
		this->SendReadyForCallIfNeeded();
	}
    while(true) 
	{
        std::string curVersion = this->mApplicationModel.Version;
        std::string availVersion, path;
		
		this->mStubsServer.CheckForUpdate(availVersion, path);
        
        if (VersionStringToInt(curVersion) < VersionStringToInt(availVersion)) 
		{
            CallbackEntityIdsList ids;
            ids.push_back(availVersion);
            ids.push_back(path);
			this->DoCallback("NewVersion", ids);
			this->PrepareForAutoUpdate();
        }
        boost::this_thread::sleep(boost::posix_time::millisec(3600000)); //1 hour
    }
}
    
void Application::Logout(void)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Application Logout start";
    
    ApplicationBaseApi::Stop();
	ApplicationMessengerApi::Stop();
	ApplicationVoipApi::Stop();
	ApplicationServerApi::Logout();
	ApplicationContactsApi::Clear();

	// TODO: temporary hack for Windows crush-on-end fix
#ifdef _WIN32
	this->mGlobalDb.Close();
#endif
    
    LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Application Logout finished";
}

bool Application::IsLoggedIn(void) const
{
	return this->mUserDb.IsOpened();
}

ContactModel Application::GetAccountData(bool format)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start getting account data";

	ContactModel result = this->ApplicationContactsApi::GetAccountData(true, false);

	logger(LogLevelDebug) << "End getting account data" << LoggerStream::endl << (result ? result : false);
	return result;
}

bool Application::SaveUserSettings(const UserSettingsModel& settings)
{
	if (this->ApplicationBaseApi::SaveUserSettings(settings))
	{
		this->ChangePresence(settings.UserBaseStatus,settings.UserExtendedStatus.c_str());
		this->ApplyVoipSettings(settings);
		
        Logger& logger = LogManager::GetInstance().TraceLogger;
		BaseResult res = this->SetDeviceSettings(settings.Autologin, settings.DoNotDesturbMode, settings.GuiLanguage);
        if ( !res.Success )
            logger(LogLevelWarning) << "Failed to save autologin and do not disturb mode to stubs server with error code" << res.ErrorCode;
		return true;
	}
	return false;
}

bool Application::SaveUserSettings(const char *key, const char *value)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start saving user settings with key = " << key << " and value = " << value;

	bool result = false;
	if (this->ApplicationBaseApi::SaveUserSettings(key, value))
	{
		std::string strKey = key;
		UserSettingsModel settings = this->GetUserSettings();
		BaseResult res;
		if (strKey == "UserExtendedStatus")
			this->ChangePresence(settings.UserBaseStatus, value);
		else if (strKey == "GuiLanguage")
			res = this->SetDeviceSettings(settings.Autologin, settings.DoNotDesturbMode, value);
		result = true;
	}
	logger(LogLevelDebug) << "End saving user settings with result = " << result;
	return result;
}

bool Application::SaveUserSettings(const char *key, int value)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start saving user settings with key = " << key << " and value = " << value;

	bool result = false;
	if (this->ApplicationBaseApi::SaveUserSettings(key, value))
	{
		std::string strKey = key;
        UserSettingsModel settings = this->GetUserSettings();
        BaseResult res;
		if (strKey == "Autologin")
			res = this->SetDeviceSettings((bool)value, settings.DoNotDesturbMode, settings.GuiLanguage);
		else if (strKey == "DoNotDesturbMode")
			res = this->SetDeviceSettings(settings.Autologin, (bool)value, settings.GuiLanguage);
		else if (strKey == "DefaultVoipServer" || strKey == "VoipEncryption" || strKey == "EchoCancellationMode" 
			|| strKey == "VideoEnabled" || strKey == "VideoSizeWifi" || strKey == "VideoSizeCell")
			ApplyVoipSettings(settings);
        if (!res.Success)
            logger(LogLevelWarning) << "Failed to save autologin and do not disturb mode to stubs server with error code" << res.ErrorCode;
		result = true;
	}
	logger(LogLevelDebug) << "End saving user settings with result = " << result;
	return result;
}

void Application::ChangeCodecSettings(const CodecSettingsList& settings)
{
	this->ApplicationBaseApi::ChangeCodecSettings(settings);
	this->EnableCodecs();
}

void Application::SetNetworkTechnology(NetworkTechnology technology)
{
	ApplicationBaseApi::SetNetworkTechnology(technology);

	this->EnableCodecs();
	this->RefreshRegistration();
	this->Ping();
}
    
bool Application::DeleteContact(ContactModel contact)
{
    if (this->ApplicationContactsApi::DeleteContact(contact))
    {
        ChatDbModelSet found;
        ChatDbModel chat;
        if (this->mUserDb.GetP2pChatByMemberId(contact.GetXmppId(), found) && !found.empty()) {
            for (auto iter = found.begin(); iter != found.end(); iter++)
                chat = *iter;
            if (chat.Active) 
			{
                chat.Active = false;
                if (this->mUserDb.SaveChat(chat))
                    return true;
            }
        }
        return true;
    }
    return false;
}

bool Application::GetAllChats(ChatModelSet& result)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start getting all chats";

	ChatDbModelSet dbchats;
	if (this->ApplicationMessengerApi::GetAllChats(dbchats))
	{
		this->DbChatSetToChatModelSet(dbchats,result,true);
		logger(LogLevelDebug) << "End getting all chats" << LoggerStream::endl << dbchats;
		return true;
	}
	logger(LogLevelDebug) << "End getting all chats with result false";
	return false;
}

bool Application::GetChatsByIds(const ChatIdSet& ids, ChatModelSet& result)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start getting chats by ids " << LoggerStream::endl << ids;

	ChatDbModelSet dbchats;
	if (this->ApplicationMessengerApi::GetChatsByIds(ids,dbchats))
	{
		this->DbChatSetToChatModelSet(dbchats,result);
		logger(LogLevelDebug) << "End getting chats by ids" << LoggerStream::endl << dbchats;
		return true;
	}
	logger(LogLevelDebug) << "End getting chats by ids with result false";
	return false;
}

bool Application::GetChatMessages(const ChatIdType& chatId, ChatMessageModelSet& result)
{
	ChatMessageDbModelSet dbresult;
	if (this->ApplicationMessengerApi::GetChatMessages(chatId,dbresult))
	{
		this->DbMessageSetToChatMessageSet(dbresult,result);
		return true;
	}
	return false;
}

bool Application::GetMessagesByIds(const ChatMessageIdSet& ids, ChatMessageModelSet& result)
{
	ChatMessageDbModelSet dbresult;
	if (this->ApplicationMessengerApi::GetMessagesByIds(ids,dbresult))
	{
		this->DbMessageSetToChatMessageSet(dbresult,result);
		return true;
	}
	return false;
}
    
bool Application::GetChatMessagesPaged(const ChatIdType& chatId, int pageSize, ChatMessageIdType const &lastMsgId, ChatMessageModelList& result)
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start GetChatMessagesPaged from chat " << chatId << " with page size " << pageSize << " and lastMsgId " << lastMsgId << LoggerStream::endl;

	ChatMessageDbModelList dbresult;
    if (this->ApplicationMessengerApi::GetChatMessagesPaged(chatId, pageSize, lastMsgId, dbresult))
    {
        this->DbMessageContToChatMessageCont(dbresult,result);
		logger(LogLevelDebug) << "End GetChatMessagesPaged" << LoggerStream::endl << dbresult;
		return true;
    }
	logger(LogLevelDebug) << "End GetChatMessagesPaged with result false";
	return false;
}
    
ChatIdType Application::InviteAndRevokeChatMembers(const char* roomJid, const ContactModelSet& inviteList, const ContactModelSet& revokeList)
{
    ContactXmppIdSet invites;
	ContactXmppIdSet revokes;
    
    for (auto it = begin(inviteList); it != end(inviteList); ++it)
		invites.insert(it->GetXmppId());
    for (auto it = begin(revokeList); it != end(revokeList); ++it)
		revokes.insert(it->GetXmppId());
    
    return ApplicationMessengerApi::InviteAndRevokeChatMembers(roomJid, invites, revokes);
}
    
bool Application::CreateChatWithContacts(const ContactModelSet& contacts, ChatModel& result) 
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start executing CreateChatWithContacts " << LoggerStream::endl << contacts;

	std::set<std::string> cList;
    for (auto it = begin(contacts); it != end(contacts); ++it)
        cList.insert(it->GetXmppId());
    
    ChatDbModel dbResult;
    bool res = ApplicationMessengerApi::CreateChatWithContacts(cList, dbResult);
    if (res)
        result = DbChatToChatModel(dbResult);
	
	logger(LogLevelDebug) << "End executing CreateChatWithContacts with result " << res;
	return res;
}
    
BaseResult Application::FindContactsInDirectory(ContactModelSet& result, const char* searchPath) 
{
	Logger& logger = LogManager::GetInstance().TraceLogger;
	logger(LogLevelDebug) << "Start finding contacts in directory with search path " << searchPath;

	BaseResult br = ApplicationServerApi::FindContactsInDirectory(result, searchPath);
    ApplicationContactsApi::PrepareDodicallContacts(result);
	
	logger(LogLevelDebug) << "End finding contacts in directory with search path " << searchPath << LoggerStream::endl << result;
	return br;
}

void Application::Pause(void)
{
	this->ApplicationVoipApi::Pause();
	this->ApplicationMessengerApi::Pause();

	this->mChatReconnectedAfterResume = false;

	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Application paused";
}
void Application::Resume(void)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Application resumed";

	this->ApplicationVoipApi::Resume();
	this->ApplicationMessengerApi::Resume();
}

void Application::ChangeChatNetworkStatus(bool value)
{
	boost::lock_guard<boost::mutex> _lock(this->mNetworkMutex);
	if (value)
		this->mChatReconnectedAfterResume = true;

	this->ApplicationBaseApi::ChangeChatNetworkStatus(value);
	this->SendReadyForCallIfNeeded();

#if TARGET_OS_IPHONE
	if (value && !this->mNetworkState.VoipStatus)
		this->ApplicationMessengerApi::TurnVoipSocket(true);
#endif
}
void Application::ChangeVoipNetworkStatus(bool value)
{
	boost::lock_guard<boost::mutex> _lock(this->mNetworkMutex);
	this->ApplicationBaseApi::ChangeVoipNetworkStatus(value);
	this->SendReadyForCallIfNeeded();

#if TARGET_OS_IPHONE
	if (value)
	{
		this->ApplicationMessengerApi::TurnVoipSocket(false);
		this->ApplicationVoipApi::TurnVoipSocket(true);
	}
	else
		this->ApplicationMessengerApi::TurnVoipSocket(true);
#endif
	if (value)
		this->ApplicationVoipApi::LoadMissedCallsFromServer();
}

void Application::RecallToContact(const ContactModel& contact)
{
	if ((bool)contact)
		this->ApplicationVoipApi::RecallToContact(contact);
}

ChatModel Application::DbChatToChatModel(const ChatDbModel& dbchat, bool withMe, ContactByXmppIdCachePtr contactsCache, const ChatMessageDbModelSet& lastMessages)
{
	ChatModel chat = dbchat;

	if (!contactsCache.get())
		contactsCache = ContactByXmppIdCachePtr(new ContactByXmppIdCache());

	ChatContactIdentitySet xmppIds = dbchat.ContactXmppIds;
	for (auto iter = xmppIds.begin(); iter != xmppIds.end();)
	{
		auto found = contactsCache->find(*iter);
		if (found != contactsCache->end())
		{
			chat.Contacts.insert(found->second);
			iter = xmppIds.erase(iter);
		}
		else
			iter++;
	}
	if (!xmppIds.empty())
	{
		ContactModelSet contacts;
		this->GetContactsByXmppIds(xmppIds, contacts);
		for (auto iter = contacts.begin(); iter != contacts.end(); iter++)
		{
			chat.Contacts.insert(*iter);
			ContactXmppIdType xmppId = iter->GetXmppId();
			(*contactsCache)[xmppId] = *iter;
			xmppIds.erase(xmppId);
		}
		for (auto iter = xmppIds.begin(); iter != xmppIds.end(); iter++)
			(*contactsCache)[*iter] = ContactModel();
	}
	
	this->QueryAvatarForPermanentContacts(chat.Contacts);
	this->PrepareRequestedContacts(chat.Contacts);
	if (chat.Title.empty())
        for (ContactModelSet::const_iterator iter = chat.Contacts.begin(); iter != chat.Contacts.end(); iter++) 
		{
            if (withMe || !iter->Iam)
                chat.Title += (chat.Title.empty() ? "" : ", ") + iter->FirstName + ((iter->FirstName.empty() || iter->LastName.empty()) ? "" : " ") + iter->LastName;
        }

	for (auto iter = lastMessages.begin(); iter != lastMessages.end(); iter++)
		if (iter->ChatId == dbchat.Id)
		{
			chat.LastMessage = this->DbMessageToChatMessageModel(*iter, *contactsCache);
			break;
		}
	if (!chat.LastMessage)
	{
		ChatMessageDbModel message = this->GetLastMessageOfChat(chat.Id);
		if ((bool)message)
			chat.LastMessage = this->DbMessageToChatMessageModel(message, *contactsCache);
	}
	return chat;
}
void Application::DbChatSetToChatModelSet(const ChatDbModelSet& dbchats, ChatModelSet& result, bool itIsAll)
{
	if (!dbchats.empty())
	{
		ChatIdSet chatIds;
		for (auto iter = dbchats.begin(); iter != dbchats.end(); iter++)
			chatIds.insert(iter->Id);

		ChatMessageDbModelSet lastMessages;
		if (itIsAll)
			this->mUserDb.GetLastMessagesOfAllChats(lastMessages);
		else
			this->mUserDb.GetLastMessagesOfChats(chatIds, lastMessages);

		ContactByXmppIdCachePtr contactsCache(new ContactByXmppIdCache());
		this->PrepareContactsCache(*contactsCache, [dbchats,lastMessages](ContactXmppIdSet& contactXmppIds)
		{
			for (auto iter = dbchats.begin(); iter != dbchats.end(); iter++)
				contactXmppIds.insert(iter->ContactXmppIds.begin(), iter->ContactXmppIds.end());
			for (auto iter = lastMessages.begin(); iter != lastMessages.end(); iter++)
				contactXmppIds.insert(iter->Sender);
		});

		for (auto iter = dbchats.begin(); iter != dbchats.end(); iter++)
			result.insert(this->DbChatToChatModel(*iter, false, contactsCache, lastMessages));
	}
}

ChatMessageModel Application::DbMessageToChatMessageModel(const ChatMessageDbModel& dbmessage, ContactByXmppIdCache& contactsCache)
{
	ChatMessageModel result = dbmessage;
	
	auto searchFunc = [this](const ContactXmppIdType& id) 
	{ 
		return this->GetContactByXmppId(id);
	};

	result.Sender = ContactFromCache(contactsCache, dbmessage.Sender, searchFunc);
	if (result.Sender)
	{
		this->QueryAvatarForPermanentContact(result.Sender);
		this->PrepareRequestedContact(result.Sender);
	}
    result.Changed = dbmessage.Changed;
	switch(result.Type)
	{
	case ChatMessageTypeContact:
		{
			ContactModel contact = this->ParseContactMessage(dbmessage);
			// TODO: change to GetContactByDodicallId
			if (!contact.DodicallId.empty())
				contact = this->RetriveContactByDodicallId(contact.DodicallId);
            if ((bool)contact)
            {
                this->QueryAvatarForPermanentContact(contact);
                this->PrepareRequestedContact(contact);
                result.ContactData = contact;
            }
		}
		break;
	case ChatMessageTypeNotification:
		result.NotificationData = this->ParseNotificationMessage(dbmessage);
		if (result.NotificationData->Contacts.begin() != result.NotificationData->Contacts.end())
		{
			ContactModel contact = *result.NotificationData->Contacts.begin();
			result.NotificationData->Contacts.clear();
			for (auto iter = contact.Contacts.begin(); iter != contact.Contacts.end(); iter++)
				if (iter->Type == ContactsContactXmpp)
					result.NotificationData->Contacts.insert(ContactFromCache(contactsCache, iter->Identity, searchFunc));
		}
		break;
	case ChatMessageTypeSubject:
		if (dbmessage.StringContent.empty() && !dbmessage.ExtendedContent.empty())
		{
			result.StringContent = dbmessage.ExtendedContent;
			ContactModel iAm = this->ApplicationContactsApi::GetAccountData();
			std::string replaceString = iAm.FirstName + ((iAm.FirstName.empty() || iAm.LastName.empty()) ? "" : " ") + iAm.LastName;
			boost::replace_first(result.StringContent, std::string(", ") + replaceString, "");
			boost::replace_first(result.StringContent, replaceString + ", ", "");
			boost::replace_first(result.StringContent, replaceString, "");
		}
		break;
	}
	return result;
}
void Application::DbMessageSetToChatMessageSet(const ChatMessageDbModelSet& dbmessages, ChatMessageModelSet& result)
{
	DbMessageContToChatMessageCont(dbmessages, result);
}

}
