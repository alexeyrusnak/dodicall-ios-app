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
namespace results
{

enum ResultErrorCode
{
	ResultErrorNo = 0,
	ResultErrorSystem = 1,
	ResultErrorSetupNotCompleted = 2,
	ResultErrorAuthFailed = 3,
    ResultErrorNoNetwork = 4
};
    
enum DownloadFileStatus
{
    DownloadFileStatusDownloaded = 0,
    DownloadFileStatusNotChanged = 1,
    DownloadFileStatusNotFound = 2
};

class BaseResult
{
public:
	bool Success;
	ResultErrorCode ErrorCode;

	inline BaseResult(): Success(true), ErrorCode(ResultErrorNo)
	{
	}
	inline BaseResult(bool success, ResultErrorCode errorCode): Success(success), ErrorCode(errorCode)
	{
	}
};
    

template <class T> T& operator << (T& stream, BaseResult const &result) 
{
	stream << "{ Success = " << result.Success << ", ErrorCode = " << (int)result.ErrorCode << " }";
	return stream;
}

class CreateTroubleTicketResult
{
public:
	bool Success;
	ResultErrorCode ErrorCode;
	long IssueId;

	inline CreateTroubleTicketResult(): Success(true), ErrorCode(ResultErrorNo), IssueId(0)
	{
	}
	inline CreateTroubleTicketResult(bool success, ResultErrorCode errorCode): Success(success), ErrorCode(errorCode), IssueId(0)
	{
	}
};

template <class T> T& operator << (T& stream, CreateTroubleTicketResult const &result) 
{
	stream << "{ Success = " << result.Success << ", ErrorCode = " << (int)result.ErrorCode << " }";
	return stream;
}

class SendPushResult
{
public:
    bool Success;
    ResultErrorCode ErrorCode;
	bool Sended;
        
    inline SendPushResult(): Success(true), ErrorCode(ResultErrorNo), Sended(false)
    {
    }
    inline SendPushResult(bool success, ResultErrorCode errorCode): Success(success), ErrorCode(errorCode), Sended(false)
    {
    }
};

template <class T> T& operator << (T& stream, SendPushResult const &result)
{
	stream << "{ Success = " << result.Success << ", ErrorCode = " << (int)result.ErrorCode << " }";
	return stream;
}

enum Currency
{
	CurrencyRuble = 0,
	CurrencyUsd,
	CurrencyEur
};

class BalanceResult
{
public:
	bool Success;
	ResultErrorCode ErrorCode;
	bool HasBalance;
	double BalanceValue;
	Currency BalanceCurrency;

	inline BalanceResult(): Success(true), ErrorCode(ResultErrorNo), HasBalance(false), BalanceValue(0.0), BalanceCurrency(CurrencyRuble)
	{
	}
	inline BalanceResult(bool success, ResultErrorCode errorCode): Success(success), ErrorCode(errorCode), HasBalance(false), BalanceValue(0.0), BalanceCurrency(CurrencyRuble)
	{
	}
	inline BalanceResult(bool success, ResultErrorCode errorCode, double balanceValue, Currency currencyValue): Success(success), ErrorCode(errorCode), HasBalance(true), BalanceValue(balanceValue), BalanceCurrency(currencyValue)
	{
	}
};
    
class DownloadFileResult
{
public:
    bool Success;
    ResultErrorCode ErrorCode;
    DownloadFileStatus FileStatus;
    std::string FilePath;
    std::map<std::string, std::string> Headers;
	bool LastModifiedProblemDetected;
    
    inline DownloadFileResult(): Success(true), ErrorCode(ResultErrorNo), 
		FileStatus(DownloadFileStatusDownloaded), LastModifiedProblemDetected(false)
    {
    }
    inline DownloadFileResult(bool success, ResultErrorCode errorCode): Success(success), ErrorCode(errorCode), 
		FileStatus(DownloadFileStatusDownloaded), LastModifiedProblemDetected(false)
    {
    }
    inline DownloadFileResult(bool success, ResultErrorCode errorCode, DownloadFileStatus fileStatus, std::string filePath, std::map<std::string, std::string> headers): 
		Success(success), ErrorCode(errorCode), FileStatus(fileStatus), FilePath(filePath), Headers(headers),
		LastModifiedProblemDetected(false)
    {
    }
};

template <class T> T& operator << (T& stream, BalanceResult const &result)
{
	stream << "{ Success = " << result.Success << ", ErrorCode = " << (int)result.ErrorCode << " }";
	return stream;
}

template<class T> T ResultFromErrorCode(ResultErrorCode code)
{
	T result((code == ResultErrorNo), code);
	return result;
}

template<class T, class I> T ResultFromErrorCode(ResultErrorCode code, I arg)
{
	T result((code == ResultErrorNo), code, arg);
	return result;
}

template<class T, class I1, class I2> T ResultFromErrorCode(ResultErrorCode code, I1 arg1, I2 arg2)
{
	T result((code == ResultErrorNo), code, arg1, arg2);
	return result;
}


    
}
}
