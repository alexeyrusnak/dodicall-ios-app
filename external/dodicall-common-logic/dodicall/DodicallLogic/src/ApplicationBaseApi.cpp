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
#include "ApplicationBaseApi.h"

#include "LogManager.h"
#include "AreaCodes.h"

#include "StringUtils.h"
#include "FilesystemHelper.h"

#include "Version.h"

std::map <std::string, bool> countryCodes;

namespace dodicall
{

ApplicationBaseApi::ApplicationBaseApi(void): mServerArea(0), 
	mSimpleCallbacker([this](const std::set<std::string>& data)
	{
		for (auto iter = data.begin(); iter != data.end(); iter++)
			this->DoCallback(iter->c_str(), CallbackEntityIdsList());
	}, 0)
{
     auto const NUM_AREA_CODES = std::extent< decltype(AreaCodes) >::value;
     for (int i = 0; i < NUM_AREA_CODES; ++i)
         countryCodes [AreaCodes[i]] = true;

	 std::string versionString = this->GetLibVersion();
	 unsigned int version = VersionStringToInt(versionString);
	 this->mGlobalDb.SetupVersion(version);
	 this->mUserDb.SetupVersion(version);
}
ApplicationBaseApi::~ApplicationBaseApi(void)
{
}

void ApplicationBaseApi::SetupApplicationModel(const char* name, const char* version)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Setup Application Model {"
		<< "name = '" << name << "', version = '" << version << "'}";

	this->mApplicationModel.Name = name;
	this->mApplicationModel.Version = version;

	this->FinalizeSetup();
}
void ApplicationBaseApi::SetupDeviceModel(const char* uid, const char* type, const char* platform, const char* model, const char* version, const char* appDataPath, const char* userDataPath, const char* tempDataPath)
{
	this->mDeviceModel.Uid = uid;
	this->mDeviceModel.Type = type;
	this->mDeviceModel.Platform = platform;
	this->mDeviceModel.Model = model;
	this->mDeviceModel.Version = version;
	this->mDeviceModel.ApplicationDataPath = FilesystemHelper::PathFromString(appDataPath);
	this->mDeviceModel.UserDataPath = FilesystemHelper::PathFromString(userDataPath);
	this->mDeviceModel.TempDataPath = FilesystemHelper::PathFromString(tempDataPath);

	// TODO: choose LogLevel
	LogManager::GetInstance().StartLoggers(LogLevelDebug,this->mDeviceModel.UserDataPath);

	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Setup Device Model {"
		<< "uid = '" << uid << "', type = '" << type << "', platform = '" << platform << "', "
		<< "model = '" << model << "', version = '" << version << "', "
		<< "appDataPath = '" << appDataPath << "', userDataPath = '" << userDataPath << "', tempDataPath = '" << tempDataPath << "'}";

	LogManager::GetInstance().TraceLogger(LogLevelInfo) << "dodicall logic library version is " << this->GetLibVersion();

	this->mGlobalCrypter.Init(uid);
    
	this->CreateAvatarSubFolders();

	this->FinalizeSetup();
}

void ApplicationBaseApi::SetupCallbackFunction(const CallbackFunctionType& func)
{
	this->mCallback = func;
}

void ApplicationBaseApi::SetNetworkTechnology(NetworkTechnology technology)
{
	boost::lock_guard<boost::mutex> _lock(this->mNetworkStateMutex);
	if (this->mNetworkState.Technology != technology)
	{
		this->mNetworkState.Technology = technology;
		this->mSimpleCallbacker.Call("NetworkStateChanged");
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Network technology changed to " << technology;
	}
}
const NetworkStateModel& ApplicationBaseApi::GetNetworkState(void) const
{
	boost::lock_guard<boost::mutex> _lock(this->mNetworkStateMutex);
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Get network state result:" << LoggerStream::endl
		<< "Network technology: " << this->mNetworkState.Technology << LoggerStream::endl
		<< "Voip status: " << this->mNetworkState.VoipStatus << LoggerStream::endl
		<< "Chat status: " << this->mNetworkState.ChatStatus;
	return this->mNetworkState;
}

std::string ApplicationBaseApi::GetLibVersion(void) const
{
	return std::string(CURRENT_VERSION_STRING);
}

GlobalApplicationSettingsModel ApplicationBaseApi::GetGlobalApplicationSettings(void) const
{
	GlobalApplicationSettingsModel result = this->mGlobalDb.GetGlobalApplicationSettings();
	if (!result.LastLogin.empty())
	{
		UserSettingsModel userSettings;
		if (this->mUserDb.IsOpened())
			userSettings = this->mUserDb.GetUserSettings();
		else
		{
            mServerArea = result.Area;
			UserDbAccessor userDb;
			userDb.SetupVersion(VersionStringToInt(this->GetLibVersion()));
			if (this->OpenUserDb(userDb,result.LastLogin.c_str()))
				userSettings = userDb.GetUserSettings();
		}
		result.Autologin = userSettings.Autologin;
		result.Autostart = userSettings.Autostart;
		if (result.DefaultGuiLanguage.empty())
			result.DefaultGuiLanguage = userSettings.GuiLanguage;
	}
	return result;
}

bool ApplicationBaseApi::SaveDefaultGuiLanguage(const char* lang)
{
	return this->mGlobalDb.SaveDefaultGuiLanguage(lang);
}

bool ApplicationBaseApi::SaveDefaultGuiTheme(const char* theme)
{
    return this->mGlobalDb.SaveDefaultGuiTheme(theme);
}
    
bool ApplicationBaseApi::ClearSavedPassword(void)
{
	return this->mGlobalDb.SaveSetting("LastPassword", "");
}

void ApplicationBaseApi::ChangeCodecSettings(const CodecSettingsList& settings)
{
	this->mDeviceSettings.SafeChange([settings](DeviceSettingsModel& self)
	{
		self.CodecSettings = settings;
	});
}

bool ApplicationBaseApi::GetDatabaseLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	bool res = true;
	result.push_back("===== Global Database Log =====");
	if (!LogManager::GetInstance().GlobalDbLogger.GetLog(result,limit,offset))
		res = false;
	result.push_back("===== User Database Log =====");
	if (!LogManager::GetInstance().UserDbLogger.GetLog(result,limit-result.size(),offset))
		res = false;
	return res;
}
bool ApplicationBaseApi::GetRequestsLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	return LogManager::GetInstance().AppServerLogger.GetLog(result,limit,offset);
}
bool ApplicationBaseApi::GetChatLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	return LogManager::GetInstance().XmppLogger.GetLog(result,limit,offset);
}
bool ApplicationBaseApi::GetVoipLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	return LogManager::GetInstance().VoipLogger.GetLog(result,limit,offset);
}
bool ApplicationBaseApi::GetTraceLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	return LogManager::GetInstance().TraceLogger.GetLog(result, limit, offset);
}
bool ApplicationBaseApi::GetGuiLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	return LogManager::GetInstance().GuiLog.GetLog(result,limit,offset);
}
bool ApplicationBaseApi::GetCallQualityLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	return LogManager::GetInstance().CallQualityLogger.GetLog(result, limit, offset);
}
bool ApplicationBaseApi::GetCallHistoryLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	return LogManager::GetInstance().CallHistoryLogger.GetLog(result, limit, offset);
}
void ApplicationBaseApi::ClearLogs(void)
{
	LogManager::GetInstance().ClearLogs();
}

void ApplicationBaseApi::WriteGuiLog(LogLevel level, const char* data)
{
	LogManager::GetInstance().GuiLog(level) << data;
}

UserSettingsModel ApplicationBaseApi::GetUserSettings(void) const
{
	UserSettingsModel result;
	if (this->mServerArea > 0)
		result.TraceMode = true;
	result = this->mUserDb.GetUserSettings(result);
	return result;
}
bool ApplicationBaseApi::SaveUserSettings(const UserSettingsModel& settings)
{
	bool result = (this->SaveDefaultGuiLanguage(settings.GuiLanguage.c_str()) && this->SaveDefaultGuiTheme(settings.GuiThemeName.c_str()) && this->mUserDb.SaveUserSettings(settings));
	if (result)
		this->mSimpleCallbacker.Call("UserSettingsChanged");
	return result;
}
bool ApplicationBaseApi::SaveUserSettings(const char *key, const char *value)
{
	bool result = true;
	if (std::string(key) == "GuiLanguage")
		result = this->SaveDefaultGuiLanguage(value);
    else if (std::string(key) == "GuiThemeName")
        result = this->SaveDefaultGuiTheme(value);
	result = (result && this->mUserDb.SaveSetting(key, value));
	if (result)
		this->mSimpleCallbacker.Call("UserSettingsChanged");
	return result;
}
bool ApplicationBaseApi::SaveUserSettings(const char *key, int value)
{
	bool result = this->mUserDb.SaveSetting(key, value);
	if (result)
		this->mSimpleCallbacker.Call("UserSettingsChanged");
	return result;
}

void ApplicationBaseApi::ChangeVoipNetworkStatus(bool value)
{
	boost::lock_guard<boost::mutex> _lock(this->mNetworkStateMutex);
	if (this->mNetworkState.VoipStatus != value)
	{
		this->mNetworkState.VoipStatus = value;
		this->mSimpleCallbacker.Call("NetworkStateChanged");
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Voip network status changed to " << value;
	}
}
void ApplicationBaseApi::ChangeChatNetworkStatus(bool value)
{
	boost::lock_guard<boost::mutex> _lock(this->mNetworkStateMutex);
	if (this->mNetworkState.ChatStatus != value)
	{
		this->mNetworkState.ChatStatus = value;
		this->mSimpleCallbacker.Call("NetworkStateChanged");
		LogManager::GetInstance().TraceLogger(LogLevelDebug) << "Chat network status changed to " << value;
	}
}

bool ApplicationBaseApi::OpenUserDb(UserDbAccessor& db, const char* login) const
{
    std::string curArea = boost::lexical_cast<std::string>(mServerArea);
    
	return db.Open(this->mDeviceModel.UserDataPath / (std::string(login) + "-" + curArea + ".db"), &this->mUserCrypter);
}

void ApplicationBaseApi::DoCallback(const char*modelName, const CallbackEntityIdsList& entityIds) const
{
	if (!this->mCallback.empty())
		this->mCallback(modelName,entityIds);
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "DoCallback called with modelName = " << modelName << " " << entityIds;
}
void ApplicationBaseApi::DoCallback(const char*modelName, const CallbackEntityIdsSet& entityIds) const
{
	CallbackEntityIdsList vec;
	std::copy(entityIds.begin(), entityIds.end(), std::back_inserter(vec));
	this->DoCallback(modelName, vec);
}

bool ApplicationBaseApi::CheckSetuped() const
{
	if (this->mApplicationModel.Name.length() && this->mApplicationModel.Version.length() && this->mDeviceModel.Uid.length() && this->mDeviceModel.Platform.length() && this->mDeviceModel.Model.length() && this->mDeviceModel.Version.length())
		return true;
	return false;
}

/*
bool is_valid_number(std::string const &number) 
{
    static const std::string AllowedChars = " -+0123456789";
    for(auto numberChar = number.begin();
        numberChar != number.end(); ++numberChar)
            
        if(AllowedChars.end() == std::find(AllowedChars.begin(), AllowedChars.end(), *numberChar)) {
            return false;
    }
        
    return true;
}
*/
    
bool FindAreaCode(std::string const &phone_prefix) 
{
    auto validIndex = countryCodes.find(phone_prefix);
    if (validIndex != countryCodes.end())
        return true;
    
    return false;
}
    
void ApplicationBaseApi::FilterNonNumbers(std::string &str)
{
    int const MIN_SYMBOL = '0';
    int const MAX_SYMBOL = '9';
    int const PLUS_SYMBOL = '+';  
    long size = str.length();
	for (auto iter = str.begin(); iter != str.end();)
	{
		if (*iter >= MIN_SYMBOL && *iter <= MAX_SYMBOL || (iter == str.begin() && *iter == PLUS_SYMBOL))
			iter++;
		else
			iter = str.erase(iter);
    }
}
    
            /* +кодстраны_кодгорода_основнойномер ("_" - пробел) */
    
            /*
    
             usage:
             std::string formatted_phone = this->FormatPhone("00078488489");
             ("+6788121 qwerty abc2 3-45qwerty-67");
     
            */
    
    
std::string ApplicationBaseApi::FormatPhone(std::string const &phone, ContactsContactType type) const
{
	if (phone.empty())
		return phone;

	if (type < 0)
	{
		if (phone.at(0) != '+')
			return this->FormatPhone(phone, ContactsContactSip);
		return this->FormatPhone(phone, ContactsContactPhone);
	}

	std::string result(phone);
    
    int const MIN_LENGTH = MAX_AREA_CODE_SIZE + 1;
    
    // sip:
    if (type == ContactsContactSip)
	{
		int const INTERNAL_CITY_CODE_LENGTH = 3;

		std::string domain = GetDomain(phone);
		result = CutDomain(phone);
		FilterNonNumbers(result);

        if (result.length() > MAX_AREA_CODE_SIZE + 1)
            result.insert(4, " ", 1);
		
		if (!(result.length() < MIN_LENGTH + 1 + INTERNAL_CITY_CODE_LENGTH))
			result.insert( (4) + INTERNAL_CITY_CODE_LENGTH + 1, " ", 1);

		if (!domain.empty())
			result += std::string("@")+ domain;
	}
	else if (type == ContactsContactPhone && result.at(0) == '+')
	{
		int const INTERNAL_PHONE_LENGTH = 7;
		FilterNonNumbers(result);
		// insert whitespace after '+area code' :
		for (auto i = MIN_AREA_CODE_SIZE; i <= MAX_AREA_CODE_SIZE; ++i)
		{
			size_t resultLen = result.length();
			if (resultLen >= i+1)
                if (FindAreaCode(result.substr(0, i + 1)))
                {
                    result.insert(i + 1, " ", 1);
					resultLen++;
					// TODO: доработать, когда добавится список кодов городов
                    if ( resultLen > ( (i + 1) + 1 + INTERNAL_PHONE_LENGTH) )
                        result.insert(resultLen - INTERNAL_PHONE_LENGTH, " ", 1);
                    break;
                }
        }
	}
    return result;
}

std::string ApplicationBaseApi::UnFormatPhone(std::string const &phone)
{
	std::string domain = GetDomain(phone);
	std::string result = CutDomain(phone);
	FilterNonNumbers(result);
	if (!domain.empty())
		result += std::string("@") + domain;
	return result;
}

void ApplicationBaseApi::CreateAvatarSubFolders()
{
	boost::filesystem::path tempDataAvatarDir = this->mDeviceModel.TempDataPath / "Avatars";
    boost::filesystem::path userDataAvatarDir = this->mDeviceModel.UserDataPath / "Avatars";
    
    if(!boost::filesystem::exists(tempDataAvatarDir))
		boost::filesystem::create_directory(tempDataAvatarDir);
    
    if(!boost::filesystem::exists(userDataAvatarDir))
		boost::filesystem::create_directory(userDataAvatarDir);
}

void ApplicationBaseApi::Stop(void)
{
	LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationBaseApi Stop start";
    this->mThreadsOnlyThenLoggedIn.InterruptAllThreads(true);

	this->mUserDb.Close();
	this->mUserCrypter.Cleanup();
    
    if(!this->mUserDb.IsOpened())
        LogManager::GetInstance().TraceLogger(LogLevelDebug) << "mUserDb closed successfully";
    
    if(!this->mUserCrypter.IsInitialized())
        LogManager::GetInstance().TraceLogger(LogLevelDebug) << "mUserCrypter cleanded up successfully";
    
    LogManager::GetInstance().TraceLogger(LogLevelDebug) << "ApplicationBaseApi Stop finished";
}

void ApplicationBaseApi::FinalizeSetup(void)
{
	if (this->CheckSetuped())
	{
		if (!this->mGlobalDb.IsOpened())
			this->mGlobalDb.Open(this->mDeviceModel.UserDataPath / "common.db", &this->mGlobalCrypter);
	}
}

}
