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

#include "ContactPresenceStatusModel.h"
#include "DeviceSettingsModel.h"

namespace dodicall
{
namespace dbmodel
{

using namespace model;

// TODO: move to Voip model
enum VideoSize
{
	VideoSizeQvga = 1,
	VideoSizeVga,
	VideoSize720p
};

// TODO: move to Voip model
enum EchoCancellationMode
{
	EchoCancellationModeOff = 0,
	EchoCancellationModeSoft,
	EchoCancellationModeHard
};

inline std::string VideoSizeToString(VideoSize size)
{
	switch(size)
	{
	case VideoSizeQvga:
		return std::string("Qvga");
	case VideoSizeVga:
		return std::string("Vga");
	case VideoSize720p:
		return std::string("720p");
	}
	// TODO: log error
	return std::string("Unknown");
}

inline std::string EchoCancellationModeToString(EchoCancellationMode mode)
{
	switch(mode)
	{
	case EchoCancellationModeOff:
		return std::string("Off");
	case EchoCancellationModeSoft:
		return std::string("Soft");
	case EchoCancellationModeHard:
		return std::string("Hard");
	}
	// TODO: log error
	return std::string("Unknown");
}

class DODICALLLOGICAPI UserSettingsModel
{
public:
	bool Autologin;

	BaseUserStatus UserBaseStatus;
	std::string UserExtendedStatus;
	bool DoNotDesturbMode;

	std::string DefaultVoipServer;
	VoipEncryptionType VoipEncryption;
	EchoCancellationMode EchoCancellationMode;

	bool VideoEnabled;
	VideoSize VideoSizeWifi;
	VideoSize VideoSizeCell;

	std::string GuiThemeName;
	bool GuiAnimation;
	std::string GuiLanguage;
	int GuiFontSize;

	bool TraceMode;

	// For windows only
	bool Autostart;

	UserSettingsModel(void);
};

}
}
