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
#include "GlobalDbAccessor.h"

#include "LogManager.h"

namespace dodicall
{

GlobalDbAccessor::GlobalDbAccessor(void)
{
}
GlobalDbAccessor::~GlobalDbAccessor(void)
{
}

GlobalApplicationSettingsModel GlobalDbAccessor::GetGlobalApplicationSettings(void) const
{
	GlobalApplicationSettingsModel result;
	DBResult dbresult;
	if (this->Execute("select * from SETTINGS",DBValueList(),&dbresult))
	{
		for (DBRowList::const_iterator iter = dbresult.Rows.begin(); iter != dbresult.Rows.end(); iter++)
		{
			try
			{
				std::string name = iter->Values.at("NAME");
				DBValue value = iter->Values.at("VALUE");
				if (name == "LastLogin")
					result.LastLogin = (std::string)value;
				else if (name == "LastPassword")
					result.LastPassword = this->Decrypt((std::string)value);
				else if (name == "Area")
					result.Area = (int)value;
				else if (name == "DefaultGuiLanguage")
					result.DefaultGuiLanguage = (std::string)value;
                else if (name == "DefaultGuiThemeName")
                    result.DefaultGuiThemeName = (std::string)value;
			}
			catch(...)
			{
				// TODO: log warning
			}
		}
	}
	return result;
}

bool GlobalDbAccessor::SaveGlobalApplicationSettings(const GlobalApplicationSettingsModel& settings)
{
	bool result = true;
	result = result && this->Execute("insert or replace into SETTINGS(NAME,VALUE) values(?,?)",boost::assign::list_of(DBValue("LastLogin"))(DBValue(settings.LastLogin)));
	result = result && this->Execute("insert or replace into SETTINGS(NAME,VALUE) values(?,?)",boost::assign::list_of(DBValue("LastPassword"))(DBValue(this->Encrypt(settings.LastPassword))));
	result = result && this->Execute("insert or replace into SETTINGS(NAME,VALUE) values(?,?)",boost::assign::list_of(DBValue("Area"))(DBValue((int)settings.Area)));
	return result;
}

bool GlobalDbAccessor::SaveDefaultGuiLanguage(const char* lang)
{
	return this->Execute("insert or replace into SETTINGS(NAME,VALUE) values(?,?)", boost::assign::list_of(DBValue("DefaultGuiLanguage"))(DBValue(lang)));
}
    
bool GlobalDbAccessor::SaveDefaultGuiTheme(char const * theme)
{
    return this->Execute("insert or replace into SETTINGS(NAME,VALUE) values(?,?)", boost::assign::list_of(DBValue("DefaultGuiThemeName"))(DBValue(theme)));
}

Logger& GlobalDbAccessor::GetLogger(void) const
{
	return LogManager::GetInstance().GlobalDbLogger;
}

}
