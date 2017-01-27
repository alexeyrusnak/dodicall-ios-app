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
#include "LogManager.h"

namespace dodicall
{

LogManager::LogManager(void)
{
}
LogManager::~LogManager(void)
{
}

void LogManager::StartLoggers(LogLevel priority, const boost::filesystem::path& logPath)
{
	static_assert(mNumLoggers == 9, "update LogManager::StartLoggers");
	this->GlobalDbLogger.Start(priority, logPath / "commondb.log", static_cast<LogTypes> (0));
	this->UserDbLogger.Start(priority, logPath / "userdb.log", static_cast<LogTypes> (1));
	this->AppServerLogger.Start(priority, logPath / "as.log", static_cast<LogTypes> (2));
	this->XmppLogger.Start(priority, logPath / "xmpp.log", static_cast<LogTypes> (3));
	this->VoipLogger.Start(priority, logPath / "voip.log", static_cast<LogTypes> (4));
	this->TraceLogger.Start(priority, logPath / "trace.log", static_cast<LogTypes> (5));
	this->GuiLog.Start(priority, logPath / "gui.log", static_cast<LogTypes> (6));
	this->CallQualityLogger.Start(priority, logPath / "quality.log", static_cast<LogTypes> (7));
	this->CallHistoryLogger.Start(priority, logPath / "history.log", static_cast<LogTypes> (8));
}
void LogManager::StopLoggers(void)
{
	for (auto&& loggers : mLoggers)
		loggers.Stop();
}
    
void LogManager::SetNonDebugLevel(void)
{
	for (auto&& loggers : mLoggers)
		loggers.SetNonDebugLevel();
}
    
void LogManager::ClearLogs(void)
{
	for (auto&& loggers : mLoggers)
		loggers.ClearLog();
}

}
