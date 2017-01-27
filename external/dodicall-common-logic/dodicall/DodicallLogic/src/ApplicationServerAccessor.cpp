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
#include "ApplicationServerAccessor.h"

#include "JsonHelper.h"
#include "LogManager.h"

#include "StringUtils.h"

namespace dodicall
{

ApplicationServerAccessor::ApplicationServerAccessor(ApplicationModel& applicationModel, DeviceModel& deviceModel, HoldingCheckFunction func):
	mApplicationModel(applicationModel), mDeviceModel(deviceModel), mHoldingChecker(func)
{
}
ApplicationServerAccessor::~ApplicationServerAccessor(void)
{
}
    
const std::string& ApplicationServerAccessor::GetPartyUid(void) const 
{
    return mPartyUid;
}

void ApplicationServerAccessor::Init(ServerAreaModel const &area)
{
    this->mHost = area.AsUrl;
	this->mPartyUid.clear();

	this->mHeaders->SList = curl_slist_append(this->mHeaders->SList, "Content-Type: application/json");
	this->mHeaders->SList = curl_slist_append(this->mHeaders->SList, (std::string("X-Client: ") + this->mDeviceModel.Type + "/" + this->mDeviceModel.Model + "/" + this->mDeviceModel.Platform + "/" + this->mDeviceModel.Version + "/" + this->mApplicationModel.Name + " " + this->mDeviceModel.Platform + " Client" + "/" + this->mApplicationModel.Version).c_str());
	this->mHeaders->SList = curl_slist_append(this->mHeaders->SList, (std::string("X-Device-Id: ") + this->mDeviceModel.Uid).c_str());

	this->BasicHttpAccessor::Init(
		(this->mApplicationModel.Name + " " + this->mDeviceModel.Platform).c_str(),
		"admin:swisstok", 30L, 15L, true
	);
}
    
boost::tuple<bool, std::string, int> RetrieveCallFwdConfigParams(boost::property_tree::ptree &responseJson, std::string const &nodeName, bool extended = false) 
{
    boost::optional<boost::property_tree::ptree&> nodeTree = responseJson.get_child_optional(nodeName);
    if (!nodeTree)
        return boost::make_tuple(false, "", 0);
    
    bool nodeActive = nodeTree->get<bool>("active", false);
    std::string nodeDestination = nodeTree->get<std::string>("destination", "");
    
    int nodeDuration = 0;
    if (extended)
        nodeDuration = nodeTree->get<int>("duration", 0);
    
    return boost::tuple<bool, std::string, int> (nodeActive, nodeDestination, nodeDuration);
}
    
BaseResult ApplicationServerAccessor::RetrieveCallForwardingSettings(CallForwardingSettingsModel &cfSettings) 
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
    
    std::string method = "/customer/" + mPartyUid + "/forwarding";
    
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
    
    CURLcode resCode = this->Request(method.c_str(), 0, httpCode, responseJson);
    
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    CallFwdConfigParams paramsAlways = RetrieveCallFwdConfigParams(responseJson, "always");
    cfSettings.stateSettingsAlways.active = paramsAlways.get<0>();
    cfSettings.stateSettingsAlways.destination = paramsAlways.get<1>();
    
    CallFwdConfigParams paramsBusy = RetrieveCallFwdConfigParams(responseJson, "busy");
    cfSettings.stateSettingsBusy.active= paramsBusy.get<0>();
    cfSettings.stateSettingsBusy.destination = paramsBusy.get<1>();
    
    CallFwdConfigParams paramsReach = RetrieveCallFwdConfigParams(responseJson, "not_reachable");
    cfSettings.stateSettingsNotReachable.active = paramsReach.get<0>();
    cfSettings.stateSettingsNotReachable.destination = paramsReach.get<1>();
    
    CallFwdConfigParams paramsAnswer = RetrieveCallFwdConfigParams(responseJson, "no_answer", true);
    cfSettings.stateSettingsNoAnswer.active = paramsAnswer.get<0>();
    cfSettings.stateSettingsNoAnswer.destination = paramsAnswer.get<1>();
    cfSettings.stateSettingsNoAnswer.duration = paramsAnswer.get<2>();

    return result;
}
    
BaseResult ApplicationServerAccessor::SetCallForwardingSettings(CallForwardingSettingsModel const &cfSettings) 
{
        
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
    
    std::string method = "/customer/" + mPartyUid + "/forwarding";
        
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    //@todo перенести заполнение
    boost::property_tree::ptree cfsettingsStruct;
    
    boost::property_tree::ptree alwaysStruct;
    alwaysStruct.add("active", cfSettings.stateSettingsAlways.active);
    alwaysStruct.add("destination", cfSettings.stateSettingsAlways.destination);
    
    cfsettingsStruct.add_child("always", alwaysStruct);
    
    boost::property_tree::ptree busyStruct;
    busyStruct.add("active", cfSettings.stateSettingsBusy.active);
    busyStruct.add("destination", cfSettings.stateSettingsBusy.destination);
    
    cfsettingsStruct.add_child("busy", busyStruct);
    
    boost::property_tree::ptree noAnswerStruct;
    noAnswerStruct.add("active", cfSettings.stateSettingsNoAnswer.active);
    noAnswerStruct.add("destination", cfSettings.stateSettingsNoAnswer.destination);
    noAnswerStruct.add("duration", cfSettings.stateSettingsNoAnswer.duration);
    
    cfsettingsStruct.add_child("no_answer", noAnswerStruct);
    
    boost::property_tree::ptree notReachableStruct;
    notReachableStruct.add("active", cfSettings.stateSettingsNotReachable.active);
    notReachableStruct.add("destination", cfSettings.stateSettingsNotReachable.destination);
    
    cfsettingsStruct.add_child("not_reachable", notReachableStruct);
    
    CURLcode resCode = this->Request(method.c_str(), JsonHelper::ptree_to_json(cfsettingsStruct).c_str(), httpCode, responseJson, CURLOPT_PUT);
    
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    if (httpCode != 202)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    return result;
}
    
BaseResult ApplicationServerAccessor::Login(const char* login, const char* password)
{
	static const char* const method = "/session/";
	
	BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
	
    this->mLogin = login;
	// TODO: защитить!
    this->mPassword = password;
    
	if (this->mCurl)
	{
		boost::property_tree::ptree requestPt;
		requestPt.put ("username", login);
		requestPt.put ("password", password);

		long httpCode = 0;
		boost::property_tree::ptree responseJson;
		CURLcode resCode = this->Request(method,JsonHelper::ptree_to_json(requestPt).c_str(),httpCode,responseJson);

		if (resCode == CURLE_OK)
		{
			switch(httpCode)
			{
			case 200:
				this->mPartyUid = responseJson.get<std::string>("uuid", "");
				if (this->mPartyUid.length())
					this->SetHeader((std::string("X-Party-Uuid: ") + this->mPartyUid).c_str());
				else
					result = ResultFromErrorCode<BaseResult>(ResultErrorSystem);
				break;
			case 401:
			case 403:
				result = ResultFromErrorCode<BaseResult>(ResultErrorAuthFailed);
				break;
			default:
				result = ResultFromErrorCode<BaseResult>(ResultErrorSystem);
				break;
			}
		}
		else
			result = ResultFromErrorCode<BaseResult>(ResultErrorSystem);
	}
	else
		result = ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
	return result;
}

void ApplicationServerAccessor::Logout(void)
{
	// TODO: close session on AS3
	this->Cleanup();

	this->mPartyUid.clear();
	this->mLogin.clear();
	this->mPassword.clear();
}

BaseResult ApplicationServerAccessor::RetrieveDeviceSettings(DeviceSettingsModel& result)
{
	const std::string method = std::string("/customer/")+this->mPartyUid+"/device/settings";
	
	long httpCode = 0;
	boost::property_tree::ptree responseJson;
	CURLcode resCode = this->Request(method.c_str(),0,httpCode,responseJson);
	if (resCode == CURLE_OK && httpCode == 200)
	{
		result.VoiceMailGate = responseJson.get<std::string>("voiceMailGate","");
		boost::optional<boost::property_tree::ptree&> voiceEncryption = responseJson.get_child_optional("voiceEncryption");
		if (voiceEncryption)
		{
			try
			{
				std::string strType = voiceEncryption->get<std::string>("type");
				
				if (strType == "SRTP")
					result.EncryptionSettings.Type = VoipEncryptionSrtp;
				else
					result.EncryptionSettings.Type = VoipEncryptionNone;
				
				result.EncryptionSettings.Mandatory = (voiceEncryption->get<int>("mandatory",0) > 0);
				result.EncryptionSettings.Ignore = (voiceEncryption->get<int>("ignore",0) > 0);
			}
			catch(...)
			{
				// TODO: write log
			}
		}
		boost::optional<boost::property_tree::ptree&> codecs = responseJson.get_child_optional("codecs");
		if (codecs)
		{
			for (boost::property_tree::ptree::const_iterator iter = codecs->begin(); iter != codecs->end(); iter++)
			{
				const boost::property_tree::ptree& codec = iter->second;
				try
				{
					CodecSettingModel codecSetting;

					std::string connType = codec.get<std::string>("connection");
					if (connType == "wifi")
						codecSetting.ConnectionType = ConnectionTypeWifi;
					else if (connType == "cell")
						codecSetting.ConnectionType = ConnectionTypeCell;
					else
					{
						// TODO: log warning
					}

					std::string strType = codec.get<std::string>("type");
					if (strType == "audio")
						codecSetting.Type = CodecTypeAudio;
					else if (strType == "video")
						codecSetting.Type = CodecTypeVideo;
					else
					{
						// TODO: log warning
					}
					codecSetting.Name = codec.get<std::string>("name");
					codecSetting.Mime = codec.get<std::string>("mime");
					codecSetting.Rate = codec.get<int>("rate");
					codecSetting.Priority = codec.get<int>("priority");
					codecSetting.Enabled = (codec.get<int>("enabled") != 0);

					result.CodecSettings.push_back(codecSetting);
				}
				catch(...)
				{
					// TODO: log error
				}
			}
		}
		boost::optional<boost::property_tree::ptree&> servers = responseJson.get_child_optional("servers");
		if (servers)
		{
			bool hasDefaultVoip = false;
			for (boost::property_tree::ptree::const_iterator iter = servers->begin(); iter != servers->end(); iter++)
			{
				const boost::property_tree::ptree& server = iter->second;
				try
				{
					ServerSettingModel serverSetting;
					std::string strType = server.get<std::string>("type");
					if (strType == "sip")
						serverSetting.ServerType = ServerTypeSip;
					else if (strType == "xmpp")
						serverSetting.ServerType = ServerTypeXmpp;
					// TODO: else throw exception "wrong data"
					std::string strProtocol = server.get<std::string>("protocol");
					if (strProtocol == "TLS")
						serverSetting.ProtocolType = ServerProtocolTypeTls;
					else if (strProtocol == "TCP")
						serverSetting.ProtocolType = ServerProtocolTypeTcp;
					// TODO: else throw exception "wrong data"
					serverSetting.Server = server.get<std::string>("server");
					serverSetting.Port = server.get<unsigned>("port");
					serverSetting.Domain = server.get<std::string>("domain");
					serverSetting.Username = server.get<std::string>("username");
					serverSetting.Password = server.get<std::string>("password");
					serverSetting.Extension = server.get<std::string>("extension");
					serverSetting.AuthUserName = server.get<std::string>("authUsername","");
					serverSetting.Default = (server.get<int>("default") > 0);
					hasDefaultVoip = (hasDefaultVoip || serverSetting.ServerType == ServerTypeSip && serverSetting.Default);
					
					result.ServerSettings.push_back(serverSetting);
				}
				catch(...)
				{
					// TODO: write log
				}
			}
			if (!hasDefaultVoip)
			{
				for (auto iter = result.ServerSettings.begin(); iter != result.ServerSettings.end(); iter++)
					if (iter->ServerType == ServerTypeSip)
					{
						iter->Default = true;
						break;
					}
			}
		}
		return ResultFromErrorCode<BaseResult>(ResultErrorNo);
	}
	return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
}

BaseResult ApplicationServerAccessor::FindContacts(ContactModelSet& result, const char* uuid, const char* qs, const char* username, const char* phone, const char* group, const char* owns, const char* xmpp)
{
	std::string method = "/customer/";
	if (uuid)
		method += uuid;

	boost::property_tree::ptree requestPt;
	requestPt.put("qs", qs?UrlEncode(qs):"");
	requestPt.put("username", username?UrlEncode(username):"");
	requestPt.put("phone", phone?UrlEncode(phone):"");
	requestPt.put("group", group?UrlEncode(group):"");
	requestPt.put("owns", owns?UrlEncode(owns):"");
	requestPt.put("xmpp", xmpp?UrlEncode(xmpp):"");

	method += PtreeToGetParameters(requestPt);

	long httpCode = 0;
	boost::property_tree::ptree responseJson;
	CURLcode resCode = this->Request(method.c_str(),0,httpCode,responseJson);

	if (resCode == CURLE_OK && httpCode == 200)
	{
		if (responseJson.count("") > 0)
		{
			for (boost::property_tree::ptree::const_iterator iter = responseJson.begin(); iter != responseJson.end(); iter++)
			{
				ContactModel contact;
				if (PtreeToContact(iter->second,contact))
					result.insert(contact);
			}
		}
		else
		{
			ContactModel contact;
			if (PtreeToContact(responseJson,contact))
				result.insert(contact);
		}
		return ResultFromErrorCode<BaseResult>(ResultErrorNo);
	}
	return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
}

boost::optional<ContactModel> ApplicationServerAccessor::FindContactByDodicallId(const char* id)
{
	ContactModelSet contacts;
	BaseResult result = this->FindContacts(contacts,id,0,0,0,0,0,0);
	if (result.Success)
	{
		if (!contacts.empty())
			return boost::optional<ContactModel>(*contacts.begin());
		return boost::optional<ContactModel>(ContactModel());
	}
	return boost::optional<ContactModel>();
}

boost::optional<ContactModel> ApplicationServerAccessor::FindContactByNumber(const char* number)
{
	ContactModelSet contacts;
	BaseResult result = this->FindContacts(contacts, 0, 0, 0, number, 0, 0, 0);
	if (result.Success)
	{
		if (!contacts.empty())
		{
			std::string pureNumber = CutDomain(number);
			for (auto iter = contacts.begin(); iter != contacts.end(); iter++)
				for (auto citer = iter->Contacts.begin(); citer != iter->Contacts.end(); citer++)
					if (citer->Identity == number || pureNumber == CutDomain(citer->Identity))
						return boost::optional<ContactModel>(*iter);
		}
		return boost::optional<ContactModel>(ContactModel());
	}
	return boost::optional<ContactModel>();
}

boost::optional<ContactModel> ApplicationServerAccessor::FindContactByXmppId(const char* id)
{
	ContactModelSet contacts;
	BaseResult result = this->FindContacts(contacts,0,0,0,0,0,0,id);
	if (result.Success)
	{
		if (!contacts.empty())
			return *contacts.begin();
		return boost::optional<ContactModel>(ContactModel());
	}
	return boost::optional<ContactModel>();
}

BalanceResult ApplicationServerAccessor::GetBalance(void)
{
	if (!this->mPartyUid.empty())
	{
		std::string method = std::string("/customer/") + this->mPartyUid + "/account";
	
		long httpCode = 0;
		boost::property_tree::ptree responseJson;
		CURLcode resCode = this->Request(method.c_str(),0,httpCode,responseJson);
		if (resCode == CURLE_OK && httpCode == 200)
		{
			boost::property_tree::ptree::const_iterator balanceData = responseJson.begin();
			if (balanceData != responseJson.end())
			{
				double balance = balanceData->second.get<double>("balance", 0.0f)/100;
				Currency currency = CurrencyRuble;
				std::string strCurrency = balanceData->second.get<std::string>("currency", "RUB");
				if (strCurrency == "RUB")
					currency = CurrencyRuble;
				else if (strCurrency == "USD")
					currency = CurrencyUsd;
				else if (strCurrency == "EUR")
					currency = CurrencyEur;
				else
				{
					// TODO: log warning
				}

				return ResultFromErrorCode<BalanceResult>(ResultErrorNo,balance,currency);
			}
			return ResultFromErrorCode<BalanceResult>(ResultErrorNo);
		}
	}
	return ResultFromErrorCode<BalanceResult>(ResultErrorSystem);
}

bool ApplicationServerAccessor::IsLoggedIn(void) const
{
	return !this->mLogin.empty();
}

const std::string& ApplicationServerAccessor::GetLogin(void) const
{
	return this->mLogin;
}

CURLcode ApplicationServerAccessor::Request (const char* method, const char* data, long& httpCode, boost::property_tree::ptree& responseJson, long requestMethod, bool reloginIfExpired)
{
	CURLcode result = this->BasicHttpAccessor::Request<CharVectorToPtreeConvertor>((this->mHost+method).c_str(), data, httpCode, responseJson, 0, 0, requestMethod);
    if (httpCode == 401 && reloginIfExpired) 
	{
		LogManager::GetInstance().AppServerLogger(LogLevelInfo) << "Session expired, attempting to relogin";
        if (this->Login(mLogin.c_str(), mPassword.c_str()).Success)
        {
            responseJson.clear();
            result = this->Request(method, data, httpCode, responseJson, requestMethod, false);
        }
    }
	return result;
}

LoggerStream operator << (LoggerStream s, const curl_slist& slist)
{
	const curl_slist* iter = &slist;
	while (iter)
	{
		s << iter->data << '\n';
		iter = iter->next;
	}
    return s;
};
    

bool ApplicationServerAccessor::PtreeToContact(const boost::property_tree::ptree& tree, ContactModel& result)
{
	try
	{
		result.DodicallId = tree.get<std::string>("uuid");
		result.FirstName = tree.get<std::string>("firstName");
		result.LastName = tree.get<std::string>("lastName");
		result.MiddleName = tree.get<std::string>("middleName");
		result.Iam = (result.DodicallId == this->mPartyUid);
        
        const boost::property_tree::ptree& groupsTree = tree.get_child("groups");
        
        for (boost::property_tree::ptree::const_iterator giter = groupsTree.begin(); giter != groupsTree.end(); giter++) 
		{
            std::string strType = giter->second.get<std::string>("type");
            
            if (strType == "group.organization") 
                result.CompanyId = giter->second.get<std::string>("uuid", "");
        }
		
		const boost::property_tree::ptree& contactsTree = tree.get_child("contacts");
		for (boost::property_tree::ptree::const_iterator citer = contactsTree.begin(); citer != contactsTree.end(); citer++)
		{
			ContactsContactModel ccm;
			std::string strType = citer->second.get<std::string>("type");
			if (strType == "sip")
				ccm.Type = ContactsContactSip;
			else if (strType == "xmpp")
				ccm.Type = ContactsContactXmpp;
			else if (strType == "phone")
				ccm.Type = ContactsContactPhone;
			else
				continue;
					
			ccm.Identity = citer->second.get<std::string>("value");
			ccm.Favourite = false;
			
            if (!ccm.Identity.empty())
                result.Contacts.insert(ccm);

			if (ccm.Type == ContactsContactSip && (result.Iam || this->mHoldingChecker(result.CompanyId)))
			{
				std::string extension = citer->second.get<std::string>("extension", "");
				if (!extension.empty() && extension != "null")
				{
					ccm.Identity = extension + "@" + GetDomain(ccm.Identity);
					result.Contacts.insert(ccm);
				}
			}
		}
		return true;
	}
	catch(...)
	{
		// TODO: log error
	}
	return false;
}

}
