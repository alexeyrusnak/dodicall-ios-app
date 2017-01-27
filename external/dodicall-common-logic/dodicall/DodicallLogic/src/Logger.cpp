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
#include "Logger.h"
#include "FilesystemHelper.h"

namespace dodicall
{

std::string const LoggerStream::endl = "\n";


#ifdef DEBUG
    boost::recursive_mutex LoggerStream::coutMutex; 
#endif

LoggerStream::LoggerStream(std::ostream* s, boost::recursive_mutex* mutex, LogTypes logType) :
		mStream(s), mLinkCounter(new unsigned(1)),
		mGuard(mutex ? (new boost::lock_guard<boost::recursive_mutex>(
#ifdef DEBUG
			coutMutex
#else
			*mutex
#endif
			)) : 0),
		mLogType(logType)
	{
#ifdef __ANDROID__
		this->mAndroidBuffer = boost::shared_ptr<std::string>(new std::string());
#endif
	}

LoggerStream::LoggerStream(const LoggerStream& from): mStream(from.mStream), mGuard(from.mGuard), mLinkCounter(from.mLinkCounter), mLogType(from.mLogType)
{
	(*this->mLinkCounter)++;
#ifdef __ANDROID__
	this->mAndroidBuffer = from.mAndroidBuffer;
#endif
}

LoggerStream::~LoggerStream()
{
	if ((--(*this->mLinkCounter)) == 0 && this->mStream)
	{
#ifdef DEBUG
		std::cout << this->endl;
        std::cout.flush();
#ifdef __ANDROID__
		char *current;
		char *next;

		current = this->mAndroidBuffer->c_str();
		while ((next = strchr(current, '\n')) != NULL) {
			*next = '\0';
			__android_log_write(ANDROID_LOG_DEBUG, "DodicallLogicLogger", current);
			current = next + 1;
		}
		__android_log_write(ANDROID_LOG_DEBUG, "DodicallLogicLogger", current);
#endif
#endif
        (*this->mStream) << this->endl;
		this->mStream->flush();
	}
}
    
LogTypes LoggerStream::LogType()
{
    return this->mLogType;
}

Logger::Logger(void)
{
}

Logger::Logger(LogLevel priority, const boost::filesystem::path& logPath, LogTypes logType)
{
	this->Start(priority, logPath, logType);
}
    
bool Logger::CheckOutdatedLog() 
{
    bool fileIsOld = true;
        
	DateType now = posix_time_now();
	boost::gregorian::date dateNow = now.date();
	if (!posix_time_to_time_t(this->mLastModifiedDate))
	{
#ifdef _WIN32
		struct _stat attr;
#else
		struct stat attr;
#endif
		if (FilesystemHelper::GetFileStats(this->mLogPath, &attr))
		{
			DateType modified = time_t_to_posix_time(*((const time_t*)&(attr.st_mtime)));
			boost::gregorian::date dateNow = now.date();
			boost::gregorian::date dateModified = modified.date();

			if (dateNow.year() == dateModified.year() && dateNow.day_of_year() == dateModified.day_of_year())
				fileIsOld = false;
			this->mLastModifiedDate = modified;
		}
		else 
			this->mLastModifiedDate = now;
	}
	else 
	{
		boost::gregorian::date dateModified = this->mLastModifiedDate.date();
		if (dateNow.year() == dateModified.year() && dateNow.day_of_year() == dateModified.day_of_year())
			fileIsOld = false;
		this->mLastModifiedDate = now;
	}
    return fileIsOld;
}
    
void Logger::OpenForAppOrTrunc ()
{
	std::ios_base::openmode flags = std::ios::out;

	if (CheckOutdatedLog())
        flags |= std::ios::trunc;
    else
        flags |= std::ios::app;
	FilesystemHelper::OpenStream(this->mStream, this->mLogPath, flags);	
	
	this->mStream << this->mTempBuffer.str();
	this->mTempBuffer.clear();
}

void Logger::Start(LogLevel priority, const boost::filesystem::path& logPath, LogTypes logType)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	mLastModifiedDate = time_t_to_posix_time((time_t)0);
    mLogLevel = priority;
    mLogPath = logPath;
    mLogType = logType;
	OpenForAppOrTrunc();
}
void Logger::Stop(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	this->mStream.close();
}

LoggerStream operator << (LoggerStream s, const LogLevel& priority)
{
	std::string strPriority;
	switch(priority)
	{
	case LogLevelDebug:
		strPriority = "DEBUG";
		break;
	case LogLevelError:
		strPriority = "ERROR";
		break;
	case LogLevelInfo:
		strPriority = "INFO";
		break;
	case LogLevelWarning:
		strPriority = "WARNING";
		break;
	default:
		strPriority = "UNKNOWN_PRIORITY";
		break;
	}
	s << '[' << strPriority << ']';
    
	return s;
}

LoggerStream Logger::operator() (LogLevel priority)
{
	bool fileIsOpen = !this->mLogPath.empty();

	if (fileIsOpen)
	{
		if (CheckOutdatedLog())
			this->ClearLog();

		if (priority < 100 && this->mLogLevel < priority)
			return LoggerStream(NULL, NULL, this->mLogType);
	}

	LoggerStream stream = (fileIsOpen) ? LoggerStream(&this->mStream, &this->mMutex, this->mLogType) :
		LoggerStream(&this->mTempBuffer, &this->mMutex, this->mLogType);

	stream << "[" << boost::posix_time::microsec_clock::local_time() << "]";
	stream << '[' << boost::this_thread::get_id() << ']' << priority << ' ';
	return stream;
}

LogLevel Logger::GetLevel(void) const
{
	return this->mLogLevel;
}
    
void Logger::SetNonDebugLevel() {
    this->mLogLevel = LogLevelWarning;
}

bool Logger::GetLog(std::vector<std::string>& result, unsigned limit, unsigned offset) const
{
	std::fstream fs;
	FilesystemHelper::OpenStream(fs, this->mLogPath, std::ios_base::in);
	if (fs.is_open())
	{
		std::string line;
		while(std::getline(fs, line))
			result.push_back(line);
		if (offset)
		{
			std::vector<std::string>::iterator ibegin = ((result.size() > offset) ? (result.end() - offset) :  result.begin());
			std::vector<std::string>::iterator iend = result.end();
			result.erase(ibegin,iend);
		}
		if (limit && (result.size() > limit))
			result.erase(result.begin(),result.end()-limit);

		fs.close();
		return true;
	}
	return false;
}
    
void Logger::ClearLog(void)
{
	boost::lock_guard<boost::recursive_mutex> _lock(this->mMutex);
	if (this->mStream.is_open())
	{
		this->Stop();
		FilesystemHelper::OpenStream(this->mStream, this->mLogPath, std::ios::trunc | std::ios::out);
	}
	else if(!this->mLogPath.empty())
		boost::filesystem::remove(this->mLogPath);
}


}

