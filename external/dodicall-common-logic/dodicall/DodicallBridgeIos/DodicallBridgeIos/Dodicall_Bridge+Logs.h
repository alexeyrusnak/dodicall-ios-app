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
//  Dodicall_Bridge+Logs.h
//  DodicallBridgeIos


#import "Dodicall_Bridge.h"

@interface Dodicall_Bridge (Logs)


- (BOOL) GetDatabaseLog: (NSMutableArray*) result;

- (BOOL) GetRequestsLog: (NSMutableArray*) result;

- (BOOL) GetChatLog: (NSMutableArray*) result;

- (BOOL) GetVoipLog: (NSMutableArray*) result;

- (BOOL) GetGuiLog: (NSMutableArray*) result;

- (BOOL) GetTraceLog: (NSMutableArray*) result;

- (BOOL) GetCallQualityLog: (NSMutableArray*) result;

- (BOOL) GetCallHistoryLog: (NSMutableArray*) result;

- (void) ClearLogs;


- (void) WriteGuiLog: (ObjC_LogLevel) level :
                      (NSString*) data;

@end
