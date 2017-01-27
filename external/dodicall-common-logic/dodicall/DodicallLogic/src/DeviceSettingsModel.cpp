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
#include "DeviceSettingsModel.h"


namespace dodicall
{
namespace model
{

DeviceSettingsModel::DeviceSettingsModel(void)
{
}

ServerSettingModel DeviceSettingsModel::GetXmppSettings(void) const
{
	for (ServerSettingsList::const_iterator iter = this->ServerSettings.begin(); iter != this->ServerSettings.end(); iter++)
	{
		if (iter->ServerType == ServerTypeXmpp)
			return *iter;
	}
	return ServerSettingModel();
}
ServerSettingModel DeviceSettingsModel::GetDefaultVoipSettings(void) const
{
	ServerSettingModel result;
	for (ServerSettingsList::const_iterator iter = this->ServerSettings.begin(); iter != this->ServerSettings.end(); iter++)
	{
		if (iter->ServerType == ServerTypeSip)
		{
			if (iter->Default)
				return *iter;
			else if (!result.Server.empty())
				result = *iter;
		}
	}
	return result;
}

ServerSettingModel DeviceSettingsModel::GetVoipSettingsForDomain(const std::string &domain) const
{
	for (ServerSettingsList::const_iterator iter = this->ServerSettings.begin(); iter != this->ServerSettings.end(); iter++)
	{
		if (iter->ServerType == ServerTypeSip && iter->Domain == domain)
			return *iter;
	}
	return ServerSettingModel();
}

}
}
