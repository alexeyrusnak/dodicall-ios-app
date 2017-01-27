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

#include "stdafx.h"

namespace dodicall
{
namespace model
{

enum VoipEncryptionType
{
	VoipEncryptionNone,
	VoipEncryptionSrtp
};

class VoipEncryptionSettingsModel
{
public:
	VoipEncryptionType Type;
	bool Mandatory;
	bool Ignore;
};

enum CodecType
{
	CodecTypeAudio,
	CodecTypeVideo
};

enum CodecConnectionType
{
	ConnectionTypeCell,
	ConnectionTypeWifi
};

class CodecSettingModel
{
public:
	CodecType Type;
	CodecConnectionType ConnectionType;
	std::string Name;
	std::string Mime;
	unsigned int Rate;
	unsigned int Priority;
	bool Enabled;
};

enum ServerSettingType
{
	ServerTypeSip,
	ServerTypeXmpp
};
  
// TODO: refactor names
enum UserNotificationType
{
    UserNotificationTypeSip,
    UserNotificationTypeXmpp,
    UserNotificationTypeXmppInviteToChat, // при добавлении в чат
    UserNotificationTypeXmppInviteContact, //  при добавлении в друзья
    UserNotificationTypeMissedCall, //Missed sip call
    UserNotificationTypeXmppContact // при отправке контактных данных
};

enum ServerProtocolType
{
	ServerProtocolTypeTls,
	ServerProtocolTypeTcp,
	ServerProtocolTypeUdp
};

inline std::string VoipEncryptionTypeToString(VoipEncryptionType type)
{
	switch(type)
	{
	case VoipEncryptionNone:
		return std::string("None");
	case VoipEncryptionSrtp:
		return std::string("Srtp");
	}
	// TODO: log error
	return std::string("Unknown");
}

inline std::string ServerProtocolTypeToString(ServerProtocolType type)
{
	switch(type)
	{
	case ServerProtocolTypeTls:
		return std::string("TLS");
	case ServerProtocolTypeTcp:
		return std::string("TCP");
	case ServerProtocolTypeUdp:
		return std::string("UDP");
	}
	// TODO: log error
	return std::string("UNKNOWN");
}

class ServerSettingModel
{
public:
	ServerSettingType ServerType;
	ServerProtocolType ProtocolType;
	std::string Server;
	unsigned int Port;
	std::string Domain;
	std::string Username;
	std::string Password;
	std::string AuthUserName;
	std::string Extension;
	bool Default;
};

typedef std::vector<CodecSettingModel> CodecSettingsList;
typedef std::vector<ServerSettingModel> ServerSettingsList;

class DeviceSettingsModel
{
public:
	std::string VoiceMailGate;
	VoipEncryptionSettingsModel EncryptionSettings;
	CodecSettingsList CodecSettings;
	ServerSettingsList ServerSettings;

	DeviceSettingsModel(void);

	ServerSettingModel GetXmppSettings(void) const;
	ServerSettingModel GetDefaultVoipSettings(void) const;
	ServerSettingModel GetVoipSettingsForDomain(const std::string &domain) const;
};

}
}
