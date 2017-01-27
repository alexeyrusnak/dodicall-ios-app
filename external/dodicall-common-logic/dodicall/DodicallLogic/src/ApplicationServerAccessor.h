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
#include "DeviceSettingsModel.h"

#include "BasicHttpAccessor.h"

namespace dodicall
{

using namespace model;
using namespace dbmodel;
using namespace results;

// REVIEW CV->AM: Нужно вынести эти модельные классы в отдельный заголовочный файл, дабы не устраивать помойку
class StateSettingsModel 
{
public:
    bool active;
    std::string destination; //<"voicemail"/abcnumber/sip/ext:string>,
};
    
class StateSettingsExtendedModel 
{
public:
    bool active;
    std::string destination; //<"voicemail"/abcnumber/sip/ext:string>,
    int duration; //<time(sec):int>
};
    
class CallForwardingSettingsModel 
{
public:
    StateSettingsModel stateSettingsAlways;
    StateSettingsModel stateSettingsBusy;
    StateSettingsExtendedModel stateSettingsNoAnswer;
    StateSettingsModel stateSettingsNotReachable;
};
 
typedef boost::tuple<bool, std::string, int> CallFwdConfigParams;

typedef boost::function<bool(const CompanyIdType&)> HoldingCheckFunction;

class ApplicationServerAccessor: protected BasicHttpAccessor
{
private:
	ApplicationModel& mApplicationModel;
	DeviceModel& mDeviceModel;

	HoldingCheckFunction mHoldingChecker;

	std::string mPartyUid;

	std::string mLogin;
    std::string mPassword; // @todo 111УБРАТЬ111

public:
	ApplicationServerAccessor(ApplicationModel& applicationModel, DeviceModel& deviceModel, HoldingCheckFunction func);
	~ApplicationServerAccessor(void);

    void Init(ServerAreaModel const &area);
	BaseResult Login(const char* login, const char* password);
	void Logout(void);

	BaseResult RetrieveDeviceSettings(DeviceSettingsModel& result);

	BaseResult FindContacts(ContactModelSet& result, const char* uuid, const char* qs, const char* username, const char* phone, const char* group, const char* owns, const char* xmpp);
	boost::optional<ContactModel> FindContactByDodicallId(const char* id);
	boost::optional<ContactModel> FindContactByXmppId(const char* id);
	boost::optional<ContactModel> FindContactByNumber(const char* number);

	BalanceResult GetBalance(void);

	bool IsLoggedIn(void) const;
	const std::string& GetLogin(void) const;
	const std::string& GetPartyUid(void) const;
    
    BaseResult RetrieveCallForwardingSettings(CallForwardingSettingsModel &cfSettings);
    BaseResult SetCallForwardingSettings(CallForwardingSettingsModel const &cfSettings);

private:
	CURLcode Request (const char* method, const char* data, long& httpCode, boost::property_tree::ptree& responseJson, long requestMethod = 0, bool reloginIfExpired = true);

	bool PtreeToContact(const boost::property_tree::ptree& tree, ContactModel& result);

};

}
