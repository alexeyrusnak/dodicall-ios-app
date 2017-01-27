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

#include "ResultTypes.h"

#include "ApplicationModel.h"
#include "ContactModel.h"
#include "DeviceModel.h"
#include "PushNotificationModel.h"

#include "BasicHttpAccessor.h"


namespace dodicall
{

#define PRODUCTION_PUSH_URL "YOUR_PRODUCTION_PUSH_URL"

using namespace model;
using namespace dbmodel;
using namespace results;
    
    
enum NotificationMode 
{
	NotificationModeSandbox = 0,
	NotificationModeProduction
};
    
inline LoggerStream operator << (LoggerStream s, const curl_slist& slist) {
    const curl_slist* iter = &slist;
    while (iter)
    {
        s << iter->data << '\n';
        iter = iter->next;
    }
    return s;
}
    
class StubsServerAccessor: public BasicHttpAccessor
{
private:
    ApplicationModel& mApplicationModel;

    DeviceModel& mDeviceModel;
    
    std::string mPartyUid;
	std::string mGroupUid;
    
    std::string mUsername;
    
    NotificationMode mNotificationMode;
    
public:
    StubsServerAccessor(ApplicationModel& applicationModel, DeviceModel& deviceModel);
    ~StubsServerAccessor();

	void InitIfNeeded(void);

	void Setup(std::string const &partyuid, int areaCode, ServerAreaModel const &area, char const *groupUuid, std::string const &login);
    
    BaseResult DownloadResourceToDir(std::string const &url, std::string const &path);
    
    BaseResult CheckForUpdate(std::string &version, std::string &path);

    BaseResult RegisterPushTokenOnServer(char const *token, NotificationMode pushNotificationsMode, bool isVoip = false);
    
    BaseResult RemovePushTokenFromServer (char const *token, bool isVoip = false);
    
    SendPushResult SendPushNotificationToSipIds(std::vector<std::string> const &sipids,
                                            char const *from,
                                            PushNotificationModel const &notification,
                                            long TimeOut = 5L
                                            );
    BaseResult SendPushNotificationToXmppIds(std::vector<std::string>const &xmppids,
                                             char const *from,
                                             PushNotificationModel const &notification
                                            );
    
    BaseResult GetCompaniesInMyHolding(std::string const &myCompanyId, CompanyIdsSet &companies);
    
    BaseResult SetUserContacts(std::vector<PushNotificationContactModel>  const &userContacts, FullNameContactModel const &fio, std::string const &companyId);
    
    BaseResult PingServer();
    
    BaseResult RetrieveAreas(ServerAreaMap &result);
    
    BaseResult SetDeviceSettings(bool autoLogin, bool dnDisturb, const std::string& lang);
    
    BaseResult SetWhiteAndBlackLists(std::vector<std::string> const &blackList, std::vector<std::string> const &whiteList);
    
    BaseResult GetMissedCalls(CallDbModelList &calls);
    
	// TODO: temporary, убрать
	void CheckToken(void);

private:
	void FillNotification(boost::property_tree::ptree &notificationStruct, PushNotificationModel const &notification) const;
    
    std::string NotificationModeToString () const;
};
    
}

/* StubsServerAccessor_h */
