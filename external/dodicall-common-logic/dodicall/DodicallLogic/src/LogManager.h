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

#include "Singleton.h"
#include "Logger.h"

namespace dodicall
{

class LogManager: public Singleton<LogManager>
{
	static const size_t mNumLoggers = 9;
	Logger mLoggers[mNumLoggers];
public:
	Logger& GlobalDbLogger = mLoggers[0];
	Logger& UserDbLogger = mLoggers[1];
	Logger& AppServerLogger = mLoggers[2];
	Logger& XmppLogger = mLoggers[3];
	Logger& VoipLogger = mLoggers[4];
	Logger& TraceLogger = mLoggers[5];
	Logger& GuiLog = mLoggers[6];
	Logger& CallQualityLogger = mLoggers[7];
	Logger& CallHistoryLogger = mLoggers[8];

	void StartLoggers(LogLevel priority, const boost::filesystem::path& logPath);
	void StopLoggers(void);

	void ClearLogs(void);
    
    void SetNonDebugLevel(void);

private:
	LogManager(void);
	~LogManager(void);

	friend class Singleton<LogManager>;
};

}