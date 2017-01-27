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

#include "UserSettingsModel.h"

#include "LogManager.h"

namespace dodicall
{

using namespace dbmodel;

ApplicationServerApi::ApplicationServerApi(void): ApplicationBaseApi(),
	mApplicationServer(mApplicationModel,mDeviceModel,
	[this](const CompanyIdType& companyId)
	{
		return this->mUserDb.IsCompanyInMyHolding(companyId);
	}),
    mStubsServer(mApplicationModel,mDeviceModel)
{
    // defaults for production :
    
    int const PRODUCTION_AREA = 0;
    
    std::string const productionUrl = "YOUR_AS_URL";
    std::string const productionLcUrl = "YOUR_LC_URL";
    
    mServerAreas[PRODUCTION_AREA] = ServerAreaModel();
    
    mServerAreas[PRODUCTION_AREA].AsUrl = productionUrl;
    mServerAreas[PRODUCTION_AREA].LcUrl = productionLcUrl;
    mServerAreas[PRODUCTION_AREA].NameEn = "Production";
    mServerAreas[PRODUCTION_AREA].NameRu = "Промышленная";
    
    mServerAreas[PRODUCTION_AREA].Reg = "/${COUNTRY}/${LANG}/auth/registration/invite-me";
    mServerAreas[PRODUCTION_AREA].ForgotPwd = "/${COUNTRY}/${LANG}/auth/registration/forgot-password";
    mServerAreas[PRODUCTION_AREA].PushUrl = PRODUCTION_PUSH_URL;
}

ApplicationServerApi::~ApplicationServerApi(void)
{
}

BaseResult ApplicationServerApi::Login(const char* login, const char* password, int area)
{
    BaseResult result;
    
	ServerAreaMap::const_iterator validArea = mServerAreas.find(area);
	if (validArea == mServerAreas.end())
    {
        ServerAreaMap dummy;
        if (!this->RetrieveAreas(dummy).Success || ((validArea = mServerAreas.find(area)) == mServerAreas.end()))
            return ResultFromErrorCode<BaseResult>(ResultErrorSetupNotCompleted);
    }
    
	this->mServerArea = area;
	
	this->mApplicationServer.Init(validArea->second);

    this->mIssAccessor.Init();
    
    std::string LcURL = this->mServerAreas[mServerArea].LcUrl;
    //Temporary---------------------------
    size_t beginIndex = LcURL.find_first_of("://")+3;
    size_t endIndex = LcURL.find_first_of(".");
    LcURL.replace(beginIndex, endIndex-beginIndex, "static");
    //Temporary---------------------------
    
    mIssAccessor.mHost = LcURL;
    
	if (!CheckSetuped())
		result = ResultFromErrorCode<BaseResult>(ResultErrorSetupNotCompleted);
    
	if (result.Success)
	{
		result = this->mApplicationServer.Login(login,password);
		if (result.Success)
        {
			BasicHttpAccessor::MergeHeadersAndCookies((BasicHttpAccessor&)this->mApplicationServer, (BasicHttpAccessor&)this->mStubsServer);
			this->mStubsServer.Setup(mApplicationServer.GetPartyUid(), area, validArea->second, "", login);
			
			this->mThreadsOnlyThenLoggedIn.StartThread([this]
			{
				this->CyclicPingStubsServer();
			});

			// TODO: temporary, убрать
			//this->mStubsServer.CheckToken();
        }
        else if (mNetworkState.Technology == NetworkTechnologyNone)
            result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
	}
    
	return result;
}

void ApplicationServerApi::Logout(void)
{
    LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationServerApi Logout start";
    this->mApplicationServer.Logout();
    
    ThreadHelper::StartThread([this]
                              {
                                  LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationServerApi mStubsServer delete tokens and Cleanup started";
                                  if(!this->PushToken.empty())
                                      this->RemovePushTokenFromServer(this->PushToken.c_str());
                                  
                                  if(!this->VoipPushToken.empty())
                                      this->RemovePushTokenFromServer(this->VoipPushToken.c_str());
                                  
                                  this->mStubsServer.Cleanup();
                                  LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationServerApi mStubsServer delete tokens and Cleanup finished";
                              });
    LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationServerApi Logout finished";
}

BaseResult ApplicationServerApi::RetrieveDeviceSettings(void)
{
	DeviceSettingsModel settings;
	BaseResult result = this->mApplicationServer.RetrieveDeviceSettings(settings);
	if (result.Success)
		this->mDeviceSettings = settings;
	else if (mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
	return result;
}

BaseResult ApplicationServerApi::RetrieveCallForwardingSettings(CallForwardingSettingsModel &cfSettings) 
{
	BaseResult result = this->mApplicationServer.RetrieveCallForwardingSettings(cfSettings);
	if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
	return result;
}
    
BaseResult ApplicationServerApi::SetCallForwardingSettings(CallForwardingSettingsModel const &cfSettings) 
{
	BaseResult result = this->mApplicationServer.SetCallForwardingSettings(cfSettings);
	if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
	return result;
}
    
BaseResult ApplicationServerApi::GetCompaniesInMyHolding(std::string entId, CompanyIdsSet &companies)
{
    BaseResult result = this->mStubsServer.GetCompaniesInMyHolding(entId, companies);
    
    if (!result.Success)
        result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
        
    return result;
}
    
BaseResult ApplicationServerApi::RetrieveAreas(ServerAreaMap &result) 
{
    if (mServerAreas.size()>1) 
	{
        result = mServerAreas;
        return ResultFromErrorCode<BaseResult>(ResultErrorNo);
    }
    auto res = this->mStubsServer.RetrieveAreas(mServerAreas);
    result = mServerAreas;
    return res;
}
    
BaseResult ApplicationServerApi::GetMissedCalls(CallDbModelList &calls)
{    
    BaseResult result = this->mStubsServer.GetMissedCalls(calls);
    
    if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
        result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
    
    return result;
}

std::string ApplicationServerApi::PrepareForAutoUpdate(void)
{
    std::string versionStr;
    std::string pathStr;
	
    BaseResult res = mStubsServer.CheckForUpdate(versionStr, pathStr);
	if (!res.Success)
        return std::string();
    
    size_t lastSlash = pathStr.find_last_of('/');
	if (lastSlash != pathStr.npos)
	{
		std::string fileName = pathStr.substr(lastSlash + 1);
		std::string installPath = (this->mDeviceModel.TempDataPath / fileName).string();
		BaseResult result = mStubsServer.DownloadResourceToDir(pathStr, installPath);
		if (result.Success)
			return installPath;
	}
	return std::string();
}

BalanceResult ApplicationServerApi::GetBalance(void)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start getting balance";
	BalanceResult result = this->mApplicationServer.GetBalance();
	if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<BalanceResult>(ResultErrorNoNetwork);
	logger(LogLevelDebug) << "End getting balance with result " << result;
	return result;
}

CreateTroubleTicketResult ApplicationServerApi::SendTroubleTicket(const char* subject, const char* description, const LogScope& logScope)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Sending trouble ticket";
	std::map<std::string,std::string> logs;
	if (logScope.DatabaseLog)
	{
		std::vector<std::string> log;
		if (this->GetDatabaseLog(log,0,0))
			logs["db.log"] = boost::algorithm::join(log,"\n");
	}
	if (logScope.RequestsLog)
	{
		std::vector<std::string> log;
		if (this->GetRequestsLog(log,0,0))
			logs["as.log"] = boost::algorithm::join(log,"\n");
	}
	if (logScope.VoipLog)
	{
		std::vector<std::string> log;
		if (this->GetVoipLog(log,0,0))
			logs["voip.log"] = boost::algorithm::join(log,"\n");
	}
	if (logScope.ChatLog)
	{
		std::vector<std::string> log;
		if (this->GetChatLog(log,0,0))
			logs["chat.log"] = boost::algorithm::join(log,"\n");
	}
	if (logScope.TraceLog)
	{
		std::vector<std::string> log;
		if (this->GetTraceLog(log, 0, 0))
			logs["trace.log"] = boost::algorithm::join(log, "\n");
	}
	if (logScope.GuiLog)
	{
		std::vector<std::string> log;
		if (this->GetGuiLog(log,0,0))
			logs["gui.log"] = boost::algorithm::join(log,"\n");
	}
	if (logScope.CallQualityLog)
	{
		std::vector<std::string> log;
		if (this->GetCallQualityLog(log, 0, 0))
			logs["quality.log"] = boost::algorithm::join(log, "\n");
	}
	if (logScope.CallHistoryLog)
	{
		std::vector<std::string> log;
		if (this->GetCallHistoryLog(log, 0, 0))
			logs["history.log"] = boost::algorithm::join(log, "\n");
	}
	std::string fullSubject = this->mApplicationModel.Name + " " + this->mApplicationModel.Version + ", " + this->mDeviceModel.Platform + ": " + subject;
	CreateTroubleTicketResult result;
	if (this->GetUserSettings().TraceMode)
		result = this->mCmsAccessor.SendTroubleTicket(fullSubject.c_str(),FillTroubleTicketDescription(description).c_str(),logs);
	else
		result = this->mCmsAccessor.SendTroubleTicket(fullSubject.c_str(), FillTroubleTicketDescription(description).c_str(), logs);
	if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<CreateTroubleTicketResult>(ResultErrorNoNetwork);
	return result;
}
    
BaseResult ApplicationServerApi::FindContactsInDirectoryByXmppIds(const ContactXmppIdSet& xmppIds, ContactModelSet& result)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << "Start FindContactsInDirectoryByXmppIds";
    
    BaseResult res = ResultFromErrorCode<BaseResult>(ResultErrorNo);
	for (ContactXmppIdSet::const_iterator iter = xmppIds.begin(); iter != xmppIds.end(); iter++)
	{
		BaseResult reqRes = this->mApplicationServer.FindContacts(result,0,0,0,0,0,0,iter->c_str());
		if (!reqRes.Success)
			res = reqRes;
	}
	if (!res.Success && mNetworkState.Technology == NetworkTechnologyNone)
		res = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
	logger(LogLevelDebug) << "End FindContactsInDirectoryByXmppIds" << res;
	return res;
}

std::string ApplicationServerApi::FillTroubleTicketDescription(const char* description) const
{
	std::string result = std::string(description) + "\n" + "--------- Start Common Info ------------\n";
	result += std::string("User: ") + this->mApplicationServer.GetLogin() + "\n";
	result += std::string("Device model: ") + this->mDeviceModel.Platform + " " + this->mDeviceModel.Model + "\n";
	result += std::string("Device uuid: ") + this->mDeviceModel.Uid + "\n";
    result += std::string("Server area: ") + boost::lexical_cast<std::string>(this->mServerArea) + "\n";
	result += std::string("dodicall logic version: ") + this->GetLibVersion() + "\n";

	result += std::string("\n--- User settings ---\n");
	UserSettingsModel userSettings = this->GetUserSettings();
	result += std::string("\tAutologin: ") + (userSettings.Autologin ? "on" : "off") + "\n";
	result += std::string("\tDnD mode: ") + (userSettings.DoNotDesturbMode ? "on" : "off") + "\n";
	result += std::string("\tDefault voip server: ") + userSettings.DefaultVoipServer + "\n";
	result += std::string("\tVoip encryption: ") + VoipEncryptionTypeToString(userSettings.VoipEncryption) + "\n";
	result += std::string("\tEcho cancellation: ") + EchoCancellationModeToString(userSettings.EchoCancellationMode) + "\n";
	result += std::string("\tVideo: ") + (userSettings.VideoEnabled ? "enabled" : "disabled") + "\n";
	result += std::string("\tVideo size (wi-fi): ") + VideoSizeToString(userSettings.VideoSizeWifi) + "\n";
	result += std::string("\tVideo size (cell): ") + VideoSizeToString(userSettings.VideoSizeCell) + "\n";
	result += std::string("\tGui language: ") + userSettings.GuiLanguage + "\n";
	result += std::string("\tGui theme: ") + userSettings.GuiThemeName + "\n";
	result += std::string("\tGui animation: ") + (userSettings.GuiAnimation ? "on" : "off") + "\n";
	result += std::string("\tGui font size: ") + boost::lexical_cast<std::string>(userSettings.GuiFontSize) + "\n";
	result += std::string("\tTrace mode: ") + (userSettings.TraceMode ? "on" : "off") + "\n";

	return result + "--------- End Common Info ------------";
}

BaseResult ApplicationServerApi::FindContactsInDirectory(ContactModelSet& result, const char* searchPath)
{
	std::string strSearchPath = searchPath;
	boost::algorithm::trim(strSearchPath);
	bool isQsNumeric = (!strSearchPath.empty() ? (strSearchPath.find_first_not_of("0123456789") == std::string::npos) : false);
	BaseResult res = this->mApplicationServer.FindContacts(result,0, (!isQsNumeric ? strSearchPath.c_str() : 0),0,(isQsNumeric ? strSearchPath.c_str() : 0),0,0,0);
	if (!res.Success && mNetworkState.Technology == NetworkTechnologyNone)
		res = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
    for (auto it = begin(result); it != end(result); ++it) {
        if ( it->Iam ) {
            it = result.erase(it);
            break;
        }
    }
	return res;
}

BaseResult ApplicationServerApi::RegisterPushTokenOnServer(char const *token, NotificationMode pushNotificationsMode, bool isVoip)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << (isVoip ? "Start RegisterPushVoipTokenOnServer" : "Start RegisterPushTokenOnServer");
    
    if(isVoip)
        this->VoipPushToken = token;
    else
        this->PushToken = token;
    
	BaseResult res = this->mStubsServer.RegisterPushTokenOnServer(token, pushNotificationsMode, isVoip);
	if (!res.Success && mNetworkState.Technology == NetworkTechnologyNone)
		res = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);

	// REVIEW SV->AM: "тайная" функциональность функции - надо перенести это отсюда в логин
	if (res.Success)
	{
		UserSettingsModel settings = this->GetUserSettings();
		this->SetDeviceSettings(settings.Autologin, settings.DoNotDesturbMode, settings.GuiLanguage);
	}

    logger(LogLevelDebug) << (isVoip ? "End RegisterPushVoipTokenOnServer with result " : "End RegisterPushTokenOnServer with result ") << res;
	return res;
}
    
BaseResult ApplicationServerApi::RemovePushTokenFromServer(char const *token, bool isVoip)
{
    Logger& logger = LogManager::GetInstance().TraceLogger;
    logger(LogLevelDebug) << (isVoip ? "Start RemovePushVoipTokenFromServer": "Start RemovePushTokenFromServer");
    
    BaseResult res = this->mStubsServer.RemovePushTokenFromServer(token, isVoip);
    if (!res.Success && mNetworkState.Technology == NetworkTechnologyNone)
        res = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
    
    logger(LogLevelDebug) << (isVoip ? "End RemovePushVoipTokenFromServer with result " : "End RemovePushTokenFromServer with result ") << res;
    return res;
}

SendPushResult ApplicationServerApi::SendPushNotificationToSipIds(std::vector<std::string> sipids, const PushNotificationModel& notification, long TimeOut)
{
	SendPushResult result = this->mStubsServer.SendPushNotificationToSipIds(sipids, this->mApplicationServer.GetPartyUid().c_str(), notification);
	if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<SendPushResult>(ResultErrorNoNetwork);
	return result;
}

BaseResult ApplicationServerApi::SendPushNotificationToXmppIds(std::vector<std::string> xmppids, const PushNotificationModel& notification) 
{
	BaseResult result = this->mStubsServer.SendPushNotificationToXmppIds(xmppids, this->mApplicationServer.GetPartyUid().c_str(), notification);
	if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
	return result;
}
    
BaseResult ApplicationServerApi::SetDeviceSettings(bool autoLogin, bool dnDisturb, std::string lang)
{
	lang = (lang.empty() ? "en" : boost::algorithm::to_lower_copy(lang));
    BaseResult result = this->mStubsServer.SetDeviceSettings(autoLogin, dnDisturb, lang);
    if (!result.Success)
        result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
    return result;
}
    
BaseResult ApplicationServerApi::SetWhiteAndBlackLists(std::vector<std::string> const &blackList, std::vector<std::string> const &whiteList) {
    BaseResult result = this->mStubsServer.SetWhiteAndBlackLists(blackList, whiteList);
    if (!result.Success)
        result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
    return result;
}
    
BaseResult ApplicationServerApi::UpdateAccountDataOnPushServer(void)
{
	BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);

    boost::optional<ContactModel> self = this->GetAccountData();
    if (!self || !*self)
		result = ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
	if (result.Success)
	{
		std::vector<PushNotificationContactModel> userContacts;

		FullNameContactModel fio;
		fio.firstName = self->FirstName;
		fio.lastName = self->LastName;
		fio.middleName = self->MiddleName;

		for (auto iterator = begin(self->Contacts); iterator != end(self->Contacts); ++iterator)
		{

			if (iterator->Type == ContactsContactSip || iterator->Type == ContactsContactXmpp)
			{
				PushNotificationContactModel contact;

				contact.Type = iterator->Type == ContactsContactSip ? "sip" : "xmpp";

				std::string trimmedIdentity = iterator->Identity;
				boost::algorithm::erase_all(trimmedIdentity, " ");

				contact.Value = trimmedIdentity;

				userContacts.push_back(contact);
			}


		}
		result = this->mStubsServer.SetUserContacts(userContacts, fio, self->CompanyId);
	}

    if (!result.Success && mNetworkState.Technology == NetworkTechnologyNone)
		result = ResultFromErrorCode<BaseResult>(ResultErrorNoNetwork);
	
    return result;
}

void ApplicationServerApi::CyclicPingStubsServer(void)
{
	while (true)
	{
		this->mStubsServer.PingServer();
		boost::this_thread::sleep(boost::posix_time::seconds(30));
	}
}


}




