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
#include "DateTimeUtils.h"

#ifdef __ANDROID__
#include <android/log.h>
#endif

namespace dodicall
{

enum LogTypes {
 
        DEBUG_LOG_CHAT =
#if _DEBUG_LOG_CHAT == 1
        0
#else
        -11
#endif
        , DEBUG_LOG_VOIP =
#if _DEBUG_LOG_VOIP == 1
        1
#else
        -12
#endif
        , DEBUG_LOG_DB =
#if _DEBUG_LOG_DB == 1
        2
#else
        -13
#endif
        , DEBUG_LOG_TRACE =
#if _DEBUG_LOG_TRACE == 1
        3
#else
        -14
#endif
    , DEBUG_LOG_REQUESTS =
#if _DEBUG_LOG_REQUESTS == 1
    4
#else
    -15
#endif
    , DEBUG_LOG_GUI =
#if _DEBUG_LOG_GUI == 1
    5
#else
    -16
#endif
    
};
    
LogTypes const LogIndexPosVector[] = { DEBUG_LOG_CHAT, DEBUG_LOG_VOIP, DEBUG_LOG_DB, DEBUG_LOG_TRACE, DEBUG_LOG_REQUESTS, DEBUG_LOG_GUI };

enum LogLevel {
    LogLevelError = 1,
    LogLevelWarning,
    LogLevelDebug,
    LogLevelInfo = 100
};
    
class LoggerStream 
{
private:
    
	boost::shared_ptr<unsigned> mLinkCounter;

    std::ostream *mStream;
    
    boost::shared_ptr<boost::lock_guard<boost::recursive_mutex> > mGuard;
    
#ifdef DEBUG
    static boost::recursive_mutex coutMutex;
#endif

#ifdef __ANDROID__
	boost::shared_ptr<std::string> mAndroidBuffer;
#endif
    
    LogTypes mLogType;

public:
	static const std::string endl;

	LoggerStream(std::ostream* s, boost::recursive_mutex* mutex, LogTypes logType);
	LoggerStream(const LoggerStream& from);
	~LoggerStream();
    
    LogTypes LogType();

	template <class T> friend LoggerStream operator << (LoggerStream s, const T& input);
    template <class T> friend LoggerStream operator << (LoggerStream s, const std::vector<T>& input);
    template <class T> friend LoggerStream operator << (LoggerStream s, const std::set<T>& input);
};


class Logger 
{
private:
    LogLevel mLogLevel;
    LogTypes mLogType;
	boost::filesystem::path mLogPath;
    std::ofstream mStream;
	std::stringstream mTempBuffer;
	DateType mLastModifiedDate;
    mutable boost::recursive_mutex mMutex;
    
    bool CheckOutdatedLog ();
    
    void OpenForAppOrTrunc ();

public:
	Logger(void);
    Logger (LogLevel priority, const boost::filesystem::path& logPath, LogTypes logType);

	void Start(LogLevel priority, const boost::filesystem::path& logPath, LogTypes logType);
	void Stop(void);
    
    LoggerStream operator() (LogLevel priority);
    
	LogLevel GetLevel(void) const;
    bool GetLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const;
    
	void ClearLog(void);
    
    void SetNonDebugLevel();
};
    
inline bool IsActiveConsoleLog (LogTypes logType) {
    for (LogTypes pos : LogIndexPosVector) {
        int int_logType = static_cast<int>(logType);
        int int_pos = static_cast<int>(pos);
        if (int_logType == int_pos)
            return true;
    }
    return false;
}
    
template <class T> LoggerStream operator << (LoggerStream s, const T& input)
{
    if (s.mStream) {
		*(s.mStream) << input;
#ifdef DEBUG
        if (IsActiveConsoleLog(s.LogType()))
            std::cout << input;
#ifdef __ANDROID__
		*(s.mAndroidBuffer) += boost::lexical_cast<std::string>(input);
#endif
#endif
    }
    return s;
};

inline LoggerStream operator << (LoggerStream s, const std::string& input)
{
	return (s << input.c_str());
}

template <class K, class V> LoggerStream operator << (LoggerStream s, const std::map<K, V>& input)
{
	s << "{";
	for (auto iter = input.begin(); iter != input.end(); iter++)
	{
		if (iter != input.begin())
			s << ", ";
		s << iter->first << " = " << iter->second;
	}
	s << "}";
	return s;
};

template <class T> LoggerStream operator << (LoggerStream s, const std::set<T>& input)
{
	s << "[";
	for (auto iter = input.begin(); iter != input.end(); iter++)
	{
		if (iter != input.begin()) {
			s << ", ";
		}
		s << *iter;
	}
	s << "]";
	return s;
};

template <class T> LoggerStream operator << (LoggerStream s, const std::vector<T>& input)
{
	s << "[";
	for (auto iter = input.begin(); iter != input.end(); iter++)
	{
		if (iter != input.begin()) {
			s << ", ";
		}
		s << *iter;
	}

	s << "]";
	return s;
};

}
