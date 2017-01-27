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
#include "StubsServerAccessor.h"
#include "JsonHelper.h"
#include "PushNotificationModel.h"
#include "StringUtils.h"
#include "LogManager.h"
#include "DateTimeUtils.h"


namespace dodicall
{
    
StubsServerAccessor::StubsServerAccessor(ApplicationModel& applicationModel, DeviceModel& deviceModel): mApplicationModel(applicationModel), mDeviceModel(deviceModel), mNotificationMode(NotificationModeProduction)
{
}
    
StubsServerAccessor::~StubsServerAccessor() 
{
    if (this->mCurl)
        curl_easy_cleanup(this->mCurl);
}

void StubsServerAccessor::InitIfNeeded(void)
{
	if (!this->mCurl)
		this->BasicHttpAccessor::Init(
		(this->mApplicationModel.Name + " " + this->mDeviceModel.Platform).c_str(),
			"admin:swisstok", 30, 15, true
		);
}

void StubsServerAccessor::Setup(std::string const &partyuid, int areaCode, ServerAreaModel const &area, char const *groupUuid, std::string const &login)
{
    mPartyUid = partyuid;
    mHost = area.PushUrl + "swissconf";
    mGroupUid = groupUuid;
    mUsername = login;

	this->InitIfNeeded();
	if (this->mCurl)
		curl_easy_setopt(this->mCurl, CURLOPT_FOLLOWLOCATION, true);

	this->SetHeader((std::string("X-Area-Code: ") + boost::lexical_cast<std::string>(areaCode)).c_str());
}
    
size_t File_CurlWriteFunc(void *ptr, size_t size, size_t nmemb, FILE *stream) 
{
    size_t written;
    written = fwrite(ptr, size, nmemb, stream);
    return written;
}
    
BaseResult StubsServerAccessor::DownloadResourceToDir(std::string const &url, std::string const &path) 
{
    
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
    FILE *fp;
    CURLcode res;
    
	// TODO: перенести в BasicHttpRequest
    if (!this->mCurl)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    CURL* curl = 0;
    
    {
        boost::lock_guard<boost::mutex> _lock1(this->mMutex);
        curl = curl_easy_duphandle(this->mCurl);
        
        if (!curl)
            return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
	
		curl_easy_setopt(curl, CURLOPT_TIMEOUT, 300L);
		curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 15L);
	}
    
    if (curl)
    {
		// REVIEW SV->AM: перейти на использование std и boost!
        fp = fopen(path.c_str(),"wb");
        if (fp != NULL) 
		{
            curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, File_CurlWriteFunc);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
            curl_easy_setopt (curl, CURLOPT_VERBOSE, 1L);
            res = curl_easy_perform(curl);
        
            fclose(fp);
        }
		curl_easy_cleanup(curl);
	}
    
	// REVIEW SV->AM: и что у нас будет в res, если не сработает условие if (curl) ???
    if (res != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    return result;
}
    
BaseResult StubsServerAccessor::CheckForUpdate(std::string &version, std::string &path) 
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
    
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
    
    const std::string method = std::string("/versions/" + mDeviceModel.Platform + "/?username=" + mUsername);
    
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), 0, httpCode, responseJson, 30L, 15L);
    
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    version = responseJson.get<std::string>("version","");
    path = responseJson.get<std::string>("link","");
    
    return result;
}
    
std::string StubsServerAccessor::NotificationModeToString () const
{
   return mNotificationMode == NotificationModeSandbox ? "sandbox" : "production";
}
    
BaseResult StubsServerAccessor::SetDeviceSettings(bool autoLogin, bool dnDisturb, const std::string& lang)
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
        
    const std::string method = std::string("/as3/users/addUserSettings");
        
    boost::property_tree::ptree issueJson;
        
    issueJson.add("userUuid", this->mPartyUid);
    issueJson.add("platform", mDeviceModel.Platform);
    issueJson.add("mode", NotificationModeToString ());
    issueJson.add("deviceUuid", mDeviceModel.Uid);
    issueJson.add("autoLogin", autoLogin ? "1" : "0");
    issueJson.add("whiteList", dnDisturb ? "1" : "0");
	issueJson.add("lang", lang);

    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(issueJson).c_str(),httpCode,responseJson, 30L, 15L);
        
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    return result;
}

BaseResult StubsServerAccessor::SetWhiteAndBlackLists(std::vector<std::string> const &blackList, std::vector<std::string> const &whiteList) 
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
        
    const std::string method = std::string("/as3/users/setContacts");
        
    boost::property_tree::ptree issueJson;
        
    issueJson.add("userUuid", this->mPartyUid);
        
    std::string contactsBlackList;
    for (auto it = begin (blackList); it != end (blackList); ++it)
    {
        contactsBlackList += contactsBlackList.empty() ? *it : ("," + *it);
    }
    issueJson.add("blockedUsers", contactsBlackList);
    
    std::string contactsWhiteList;
    for (auto it = begin (whiteList); it != end (whiteList); ++it)
    {
        contactsWhiteList += contactsWhiteList.empty() ? *it : ("," + *it);
    }
    issueJson.add("whiteUsers", contactsWhiteList);
        
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(issueJson).c_str(),httpCode,responseJson, 30L, 15L);
        
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    return result;
}
    
BaseResult StubsServerAccessor::RetrieveAreas(ServerAreaMap &result) 
{
	this->InitIfNeeded();
	
	BaseResult br = ResultFromErrorCode<BaseResult>(ResultErrorNo);
        
    // mHost еще не инициализирован когда вызывается этот метод
	// TODO: поменять на PRODUCTION_PUSH_URL после обновления push-сервера
	std::string method = "https://ddc2.build.swisstok.ru/swissconf/as3/area/getAreas";
        
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), 0, httpCode, responseJson, 15L, 5L);
        
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    boost::optional<boost::property_tree::ptree&> areasTree = responseJson.get_child_optional("areas");
    if (!areasTree)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    for (boost::property_tree::ptree::const_iterator giter = areasTree->begin(); giter != areasTree->end(); giter++)
    {
        std::string strUrl = giter->second.get<std::string>("asUrl");
        std::string strLcUrl = giter->second.get<std::string>("lcUrl");
        std::string strNameEn = giter->second.get<std::string>("nameEn");
        std::string strNameRu = giter->second.get<std::string>("nameRu");
        std::string strReg = giter->second.get<std::string>("registration");
        std::string strForgotPwd = giter->second.get<std::string>("forgotPw");
        std::string strPushUrl = giter->second.get<std::string>("pushUrl");
        
        int curArea = giter->second.get<int>("areaId");
        result[curArea] = ServerAreaModel();
		
        result[curArea].AsUrl = strUrl;
        result[curArea].LcUrl = strLcUrl;
        result[curArea].NameEn = strNameEn;
        result[curArea].NameRu = strNameRu;
        result[curArea].Reg = strReg;
        result[curArea].ForgotPwd = strForgotPwd;
        result[curArea].PushUrl = strPushUrl;
    }
    
    return br;
}
    
    
BaseResult StubsServerAccessor::PingServer() 
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
        
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    const std::string method = std::string("/as3/ping/ping");
    
    boost::property_tree::ptree issueJson;
    
    issueJson.add("device_guid", mDeviceModel.Uid);
        
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(issueJson).c_str(), httpCode, responseJson, 5L, 5L);
    
    if (resCode != CURLE_OK || httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
	/*
    std::string lastPingTimeStr = responseJson.get<std::string>("last_ping","");
   
    boost::posix_time::ptime lastPingTime = boost::posix_time::time_from_string(lastPingTimeStr);
    */

    //auto now = std::chrono::system_clock::now();
    
    //time_t tmNow = std::chrono::system_clock::to_time_t(now);
    //std::string tmNowStr = time_t_to_string(tmNow);
    //using namespace std::chrono;
    //time_t _lastPingTime = posix_time_to_time_t(lastPingTime);
    //double seconds = difftime(tmNow, _lastPingTime);
    //if (seconds > secondsInHalfMinute)
    
    return result;
}
    
BaseResult StubsServerAccessor::RegisterPushTokenOnServer (char const *token, NotificationMode pushNotificationsMode, bool isVoip)
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
	this->mNotificationMode = pushNotificationsMode;

	if (token && strlen(token) > 0)
	{
        const std::string method = std::string("/as3/push/") + (isVoip ? std::string("addVoipToken") : std::string("addDeviceToken"));

		boost::property_tree::ptree issueJson;

		issueJson.add("userUuid", this->mPartyUid);
		issueJson.add("token", token);
		issueJson.add("platform", mDeviceModel.Platform);
		issueJson.add("mode", NotificationModeToString ());
		issueJson.add("deviceUuid", mDeviceModel.Uid);

		long httpCode = 0;
		boost::property_tree::ptree responseJson;

		CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(issueJson).c_str(), httpCode, responseJson, 30L, 15L);

        if (resCode != CURLE_OK || httpCode != 200)
            return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
	}
    return result;
}

BaseResult StubsServerAccessor::RemovePushTokenFromServer (char const *token, bool isVoip)
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
    
    if (token && token[0])
    {
        const std::string method = std::string("/as3/push/") + (isVoip ? std::string("removeVoipToken") : std::string("removeDeviceToken"));
        
        boost::property_tree::ptree issueJson;
        issueJson.add("token", token);
        
        long httpCode = 0;
        boost::property_tree::ptree responseJson;
        
        CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(issueJson).c_str(), httpCode, responseJson, 30L, 15L);
        
        if (resCode != CURLE_OK || httpCode != 200)
            return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    }
    return result;
}
    
void StubsServerAccessor::FillNotification(boost::property_tree::ptree &notificationStruct, PushNotificationModel const &notification) const
{
    boost::property_tree::ptree metaStruct;
    
    metaStruct.add("f", notification.MetaStruct.From);
    
    switch (notification.MetaStruct.Type)
    {
        case UserNotificationTypeXmpp:
            metaStruct.add("t", "x");
            break;
        
        case UserNotificationTypeXmppInviteToChat:
            metaStruct.add("t", "xichat");
            break;
            
        case UserNotificationTypeXmppInviteContact:
            metaStruct.add("t", "xicontact");
            break;
            
        case UserNotificationTypeMissedCall:
            metaStruct.add("t", "smc");
            break;
            
        case UserNotificationTypeSip:
            metaStruct.add("t", "s");
            break;
         
        case UserNotificationTypeXmppContact:
            metaStruct.add("t", "xcontact");
            break;
            
        default:
            metaStruct.add("t", "s");
            break;
    }
	
	if (!notification.MetaStruct.ChatRoomJid.empty())
	{
        metaStruct.add("i", notification.MetaStruct.Type);
		metaStruct.add("j", notification.MetaStruct.ChatRoomJid);
		metaStruct.add("m", (int)notification.MetaStruct.ChatMessageType);
		metaStruct.add("n", notification.MetaStruct.ChatRoomCapacity);
		metaStruct.add("s", (int64_t)posix_time_to_time_t(notification.MetaStruct.ChatMessageSendTime));
		metaStruct.add("c", notification.MetaStruct.ChatRoomTitle);
	}
    
    if (!notification.MetaStruct.CallId.empty())
    {
        metaStruct.add("callId", notification.MetaStruct.CallId);
    }

    notificationStruct.add("alertTitle", notification.AlertTitle);
    
    switch (notification.AlertAction)
    {
        case dbmodel::AlertActionTypeAnswer:
            notificationStruct.add("alertAction", "A");
            break;
            
        case dbmodel::AlertActionTypeOpen:
            notificationStruct.add("alertAction", "O");
            break;
        
        case dbmodel::AlertActionTypeCancel:
            notificationStruct.add("alertAction", "C");
            break;
        
        case dbmodel::AlertActionTypeCall:
            notificationStruct.add("alertAction", "CALL");
            break;
            
        default:
            notificationStruct.add("alertAction", "L");
            break;
    }
    
    notificationStruct.add("alertBody", notification.AlertBody);
    notificationStruct.add("hasAction", notification.HasAction);
    
    switch (notification.SoundName)
    {
        case dbmodel::AlertSoundNameTypeCall:
            notificationStruct.add("soundName", "c.m4r");
            break;
            
        default:
            notificationStruct.add("soundName", "m.m4r");
            break;
    }
    
    notificationStruct.add("iconBage", notification.IconBadge);
    notificationStruct.add("expireInSec", notification.ExpireInSec);
    
    if (notification.DType == dodicall::NotificationRemote)
        notificationStruct.add("dType", "remote");
    else
        notificationStruct.add("dType", "local");
    
    if (notification.Type == ServerTypeXmpp)
        notificationStruct.add("type", "xmpp");
    else
        notificationStruct.add("type", "sip");
    
    
    switch (notification.AType)
    {
        case dodicall::XMC:
            notificationStruct.add("alertCategory", "XMC");
            break;
        
        case dodicall::XMNAC:
            notificationStruct.add("alertCategory", "XMNAC");
            break;
        
        case dodicall::PICC:
            notificationStruct.add("alertCategory", "PICC");
            break;
            
        case dodicall::PMICC:
            notificationStruct.add("alertCategory", "PMICC");
            break;
            
        case dodicall::XMMIC:
            notificationStruct.add("alertCategory", "XMMIC");
            break;
        
        case dodicall::XMCIC:
            notificationStruct.add("alertCategory", "XMCIC");
            break;
            
        default:
            notificationStruct.add("alertCategory", "SCC");
            break;
    }
    
    notificationStruct.add_child("m", metaStruct);
}

SendPushResult StubsServerAccessor::SendPushNotificationToSipIds(std::vector<std::string> const &sipids,
                                                                char const *from,
                                                                PushNotificationModel const &notification,
                                                                long TimeOut
                                                                ) 
{
	SendPushResult result = ResultFromErrorCode<SendPushResult>(ResultErrorNo);
    
    const std::string method = std::string("/as3/push/sendNotification");
    
    boost::property_tree::ptree requestJson;
    
	std::string strSipids;
    for (auto iterator = begin (sipids); iterator != end (sipids); ++iterator) 
	{
		if (iterator != begin(sipids))
			strSipids += ',';
		strSipids += *iterator;
    }
	requestJson.add("sipids", strSipids);
        
	requestJson.add("from", from);
    
    boost::property_tree::ptree notificationStruct;
    
    FillNotification(notificationStruct, notification);
    
	requestJson.add("notification", encode64(JsonHelper::ptree_to_json(notificationStruct).c_str()));
    
	requestJson.add("mode", NotificationModeToString ());
	requestJson.add("userGroup", mGroupUid);
    
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(),JsonHelper::ptree_to_json(requestJson).c_str(),httpCode,responseJson, 5L, 5L);
    
	result.Sended = responseJson.get<bool>("success", false);

    if (resCode != CURLE_OK)
        return ResultFromErrorCode<SendPushResult>(ResultErrorSystem);
    
    if (httpCode != 200)
        return ResultFromErrorCode<SendPushResult>(ResultErrorSystem);
    
    return result;
}
    
BaseResult StubsServerAccessor::SendPushNotificationToXmppIds(std::vector<std::string> const &xmppids, char const *from, PushNotificationModel const &notification)
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
        
    const std::string method = std::string("/as3/push/sendNotification");
        
    boost::property_tree::ptree issueJson;
        
    issueJson.add("sipids", "");
    
    std::string xmppList;
    for (auto iterator = begin (xmppids); iterator != end (xmppids); ++iterator) 
	{
        xmppList += xmppList.empty() ? *iterator : ("," + *iterator);
    }
    issueJson.add("xmppids", xmppList);
        
    issueJson.add("from", from); //UDID in from DMC-3259 
        
	boost::property_tree::ptree notificationStruct;
    FillNotification(notificationStruct, notification);
    issueJson.add("notification", encode64(JsonHelper::ptree_to_json(notificationStruct)));
        
    issueJson.add("mode", NotificationModeToString ());
    issueJson.add("userGroup", mGroupUid);
        
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(),JsonHelper::ptree_to_json(issueJson).c_str(),httpCode,responseJson, 30L, 15L);
        
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    return result;
}
  
BaseResult StubsServerAccessor::GetCompaniesInMyHolding (std::string const &myCompanyId, CompanyIdsSet &companies)
{
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
        
    const std::string method = std::string("/as3/push/GetCompaniesInMyHolding");
        
    boost::property_tree::ptree issueJson;
        
    issueJson.add("companyId", myCompanyId);
    
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
        
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(issueJson).c_str(),httpCode,responseJson, 30L, 15L);
        
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
        
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    boost::optional<boost::property_tree::ptree&> companiesTree = responseJson.get_child_optional("companies");
    if (!companiesTree)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    for (boost::property_tree::ptree::const_iterator giter = companiesTree->begin(); giter != companiesTree->end(); ++giter)
        companies.insert(giter->second.data());
    
    return result;
}
    
    
BaseResult StubsServerAccessor::SetUserContacts(std::vector<PushNotificationContactModel>  const &userContacts,
                                                                                FullNameContactModel const &fio,
                                                                                std::string const &companyId)
{
    //groupUuid =  // @todo : retrieve user group from server
    
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
    
    const std::string method = std::string("/as3/push/setUserContacts");
    
    boost::property_tree::ptree issueJson;
        
    issueJson.add("userUuid", this->mPartyUid);
    
    issueJson.add("userGroup", mGroupUid);
    
    issueJson.add("userName", fio.firstName);
    issueJson.add("userSurName", fio.lastName);
    issueJson.add("userMiddleName", fio.middleName);
    
    issueJson.add("companyId", companyId);
    
    boost::property_tree::ptree subTree;
    for (auto iterator = begin (userContacts); iterator != end (userContacts); ++iterator) {
        boost::property_tree::ptree cTree;
        
        cTree.put("type",iterator->Type);
        
        cTree.put("value",iterator->Value);

        subTree.push_back(std::make_pair("",cTree));
    }
    
    issueJson.add_child("userContacts", subTree);
    
    long httpCode = 0;
    boost::property_tree::ptree responseJson;
    
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(issueJson).c_str(),httpCode,responseJson, 30L, 15L);
    
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    return result;
}
    
BaseResult StubsServerAccessor::GetMissedCalls(CallDbModelList &calls)
{
	if (this->mPartyUid.empty())
		return ResultFromErrorCode<BaseResult>(ResultErrorSetupNotCompleted);

    boost::property_tree::ptree requestPt;
    requestPt.put ("userUuid", this->mPartyUid);
    
    BaseResult result = ResultFromErrorCode<BaseResult>(ResultErrorNo);
    
    long httpCode = 0;
    
    boost::property_tree::ptree responseJson;
    
    const std::string method = std::string("/as3/push/getMissedCalls");
    
    CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), JsonHelper::ptree_to_json(requestPt).c_str(), httpCode, responseJson, 30L, 15L);
    
    if (resCode != CURLE_OK)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    if (httpCode != 200)
        return ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    boost::optional<boost::property_tree::ptree&> callsTree = responseJson.get_child_optional("calls");
    
    if(callsTree)
    {
        for (boost::property_tree::ptree::const_iterator iter = callsTree->begin(); iter != callsTree->end(); iter++)
        {
            CallDbModel call;
            call.Identity = iter->second.get<std::string>("sipIdentity");
            call.Id = iter->second.get<std::string>("callId");
            call.StartTime = boost::posix_time::time_from_string(iter->second.get<std::string>("dateTime"));
            call.Direction = CallDirectionIncoming;
            call.HistoryStatus = HistoryStatusMissed;
            call.EndMode = CallEndModeCancel;
            call.AddressType = CallAddressDodicall;
            call.Encription = VoipEncryptionNone;
            
            if(!call.Identity.empty() && !call.Identity.empty())
                calls.push_back(call);
        }
    }
    else
        result = ResultFromErrorCode<BaseResult>(ResultErrorSystem);
    
    return result;
}

void StubsServerAccessor::CheckToken(void)
{
	// mHost еще не инициализирован когда вызывается этот метод
	// TODO: поменять на PRODUCTION_PUSH_URL после обновления push-сервера
	std::string method = "https://ddc2.build.swisstok.ru/as3/test123/checkToken";

	long httpCode = 0;
	boost::property_tree::ptree responseJson;

	CURLcode resCode = this->Request<CharVectorToPtreeConvertor>(method.c_str(), 0, httpCode, responseJson, 15L, 5L);

	int i = 0;
}

}


