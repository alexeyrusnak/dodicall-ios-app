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

#include "ApplicationModel.h"
#include "DeviceModel.h"
#include "DeviceSettingsModel.h"
#include "NetworkStateModel.h"

#include "GlobalDbAccessor.h"
#include "UserDbAccessor.h"

#include "UniversalContainers.h"
#include "UniversalProcessors.h"

#include "ServerAreaModel.h"

#include "AesCrypter.h"

namespace dodicall
{

using namespace dbmodel;
using namespace model;

typedef std::string CallbackEntityId;
typedef std::vector<CallbackEntityId> CallbackEntityIdsList;
typedef std::set<CallbackEntityId> CallbackEntityIdsSet;
typedef boost::function<void (const char* modelName, const CallbackEntityIdsList& entityIds)> CallbackFunctionType;

class DODICALLLOGICAPI ApplicationBaseApi
{
protected:
	mutable int mServerArea;
	ApplicationModel mApplicationModel;
	DeviceModel mDeviceModel;
	SafeObject<DeviceSettingsModel> mDeviceSettings;

	NetworkStateModel mNetworkState;
	mutable boost::mutex mNetworkStateMutex;

	AesCrypter mGlobalCrypter;
	AesCrypter mUserCrypter;

	GlobalDbAccessor mGlobalDb;
	UserDbAccessor mUserDb;

	DelayedProcessor<std::string> mSimpleCallbacker;

	mutable ThreadPool mThreadsOnlyThenLoggedIn;

private:
	CallbackFunctionType mCallback;

public:
	/* Mandatory Setup methods */
	void SetupApplicationModel(const char* name, const char* version);
	void SetupDeviceModel(const char* uid, const char* type, const char* platform, const char* model, const char* version, const char* appDataPath, const char* userDataPath, const char* tempDataPath);

	/* Optional Setup methods */
	void SetupCallbackFunction(const CallbackFunctionType& func);

	std::string GetLibVersion(void) const;

	GlobalApplicationSettingsModel GetGlobalApplicationSettings(void) const;
	bool SaveDefaultGuiLanguage(const char* lang);
    bool SaveDefaultGuiTheme(const char* theme);
	bool ClearSavedPassword(void);

	UserSettingsModel GetUserSettings(void) const;

	bool GetDatabaseLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	bool GetRequestsLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	bool GetChatLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	bool GetVoipLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	bool GetTraceLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	bool GetGuiLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	bool GetCallQualityLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	bool GetCallHistoryLog(std::vector<std::string>& result, unsigned limit = 8000, unsigned offset = 0) const;
	void ClearLogs(void);

	void WriteGuiLog(LogLevel level, const char* data);

	const NetworkStateModel& GetNetworkState(void) const;
    
    std::string FormatPhone(std::string const &phone, ContactsContactType type = (ContactsContactType)-1) const;

protected:
	ApplicationBaseApi(void);
	~ApplicationBaseApi(void);

	virtual void ChangeVoipNetworkStatus(bool value);
	virtual void ChangeChatNetworkStatus(bool value);

	bool OpenUserDb(UserDbAccessor& db, const char* login) const;

	virtual bool SaveUserSettings(const UserSettingsModel& settings);
	bool SaveUserSettings(const char *key, const char *value);
	bool SaveUserSettings(const char *key, int value);
	void ChangeCodecSettings(const CodecSettingsList& settings);

	void SetNetworkTechnology(NetworkTechnology technology);

	void DoCallback(const char*modelName, const CallbackEntityIdsList& entityIds) const;
	void DoCallback(const char*modelName, const CallbackEntityIdsSet& entityIds) const;

	bool CheckSetuped() const;
	void FinalizeSetup(void);

	void Stop(void);

	static std::string UnFormatPhone(const std::string& phone);

private:
	static void FilterNonNumbers(std::string &str);

    void CreateAvatarSubFolders(void);
};

}
