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
//
//  ObjC_BaseResult.h
//  
//

#import <Foundation/Foundation.h>


typedef enum  {
    ResultErrorNo = 0,
    ResultErrorSystem = 1,
    ResultErrorSetupNotCompleted = 2,
    ResultErrorAuthFailed = 3,
    ResultErrorNoNetwork = 4
} ResultErrorCode;

typedef enum {
    LogLevelError = 1,
    LogLevelWarning,
    LogLevelDebug,
    LogLevelInfo = 100
} ObjC_LogLevel;

typedef enum {
    CurrencyRuble = 0,
    CurrencyUsd,
    CurrencyEur
} Currency;

@interface ObjC_BaseResult : NSObject {
};

    @property NSNumber* Success;
    @property ResultErrorCode ErrorCode;

@end

@interface ObjC_CreateTroubleTicketResult: NSObject {
};

    @property NSNumber*  Success;
    @property ResultErrorCode ErrorCode;
    @property long IssueId;

@end

@interface ObjC_LogScope : NSObject {
};

    @property NSNumber* DatabaseLog;
    @property NSNumber* RequestsLog;
    @property NSNumber* VoipLog;
    @property NSNumber* ChatLog;
    @property NSNumber* TraceLog;
    @property NSNumber* GuiLog;
    @property NSNumber* CallQualityLog;
    @property NSNumber* CallHistoryLog;

@end

@interface ObjC_BalanceResult : NSObject {
};

    @property NSNumber* Success;
    @property ResultErrorCode ErrorCode;
    @property double BalanceValue;
    @property Currency BalanceCurrency;
    @property NSNumber* HasBalance;

@end








