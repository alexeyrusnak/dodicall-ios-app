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

#include "ApplicationServerAccessor.h"
#include "CMSAccessor.h"
#include "JiraAccessor.h"
#include "StubsServerAccessor.h"

#include "CallHistoryModel.h"

namespace dodicall
{

class LogScope
{
public:
	bool DatabaseLog;
	bool RequestsLog;
	bool VoipLog;
	bool ChatLog;
	bool TraceLog;
	bool GuiLog;
	bool CallQualityLog;
	bool CallHistoryLog;
};

class DODICALLLOGICAPI ApplicationServerApi: virtual public ApplicationBaseApi
{
protected:
	mutable ApplicationServerAccessor mApplicationServer;
	CMSAccessor mCmsAccessor;
   	JiraAccessor mJiraAccessor;
    mutable StubsServerAccessor mStubsServer;
    
    ServerAreaMap mServerAreas;
    BasicHttpAccessor mIssAccessor;

public:
	BalanceResult GetBalance(void);

	CreateTroubleTicketResult SendTroubleTicket(const char* subject, const char* description, const LogScope& logScope);

	BaseResult FindContactsInDirectoryByXmppIds(const ContactXmppIdSet& xmppIds, ContactModelSet& result);

	BaseResult RegisterPushTokenOnServer(char const *token, NotificationMode pushNotificationsMode, bool isVoip = false);
    
    BaseResult RemovePushTokenFromServer(char const *token, bool isVoip = false);
    
    
    std::string PrepareForAutoUpdate(void);
    
    BaseResult RetrieveCallForwardingSettings(CallForwardingSettingsModel &cfSettings);
    BaseResult SetCallForwardingSettings(CallForwardingSettingsModel const &cfSettings);
    
    BaseResult RetrieveAreas(ServerAreaMap &result);
    
    BaseResult GetMissedCalls(CallDbModelList &calls);
    
    BaseResult GetCompaniesInMyHolding(std::string entId, CompanyIdsSet &companies);

protected:
	ApplicationServerApi(void);
	~ApplicationServerApi(void);

	BaseResult Login(const char* login, const char* password, int area);
	void Logout(void);

	BaseResult RetrieveDeviceSettings(void);
	BaseResult UpdateAccountDataOnPushServer(void);

	SendPushResult SendPushNotificationToSipIds(std::vector<std::string> sipids, const PushNotificationModel& notification, long TimeOut = 5L);
    
	BaseResult SendPushNotificationToXmppIds(std::vector<std::string> xmppids, const PushNotificationModel& notification);
    
    BaseResult FindContactsInDirectory(ContactModelSet& result, const char* searchPath);
    
    // REVIEW SV->AM: плохое название функции - переименовать, например, в SaveDeviceSettingsToServer
	BaseResult SetDeviceSettings(bool autoLogin, bool dnDisturb, std::string lang);
    
	// REVIEW SV->AM: плохое название функции - переименовать, например, в SaveWhiteAndBlackListsToServer
	BaseResult SetWhiteAndBlackLists(std::vector<std::string> const &blackList, std::vector<std::string> const &whiteList);
    
private:
	virtual ContactModel GetAccountData(bool format = false, bool useCache = true) = 0;

	std::string FillTroubleTicketDescription(const char* description) const;

	void CyclicPingStubsServer(void);
    
    std::string PushToken;
    std::string VoipPushToken;

};

}
