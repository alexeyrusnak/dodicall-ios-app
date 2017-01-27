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
//  Dodicall_Bridge+Logs.m
//  DodicallBridgeIos
//


#import "Dodicall_Bridge+Logs.h"
#import "Dodicall_Bridge+Helpers.h"

@implementation Dodicall_Bridge (Logs)



- (BOOL) convert_log: (std::vector<std::string> const &) c_result : (NSMutableArray*) result {
    for (auto iterator = begin (c_result); iterator != end (c_result); ++iterator) {
        std::string s = *iterator;
        
        NSString *objc_str = [NSString stringWithUTF8String: s.c_str()];
        
        [result addObject: objc_str];
    }
    if ( result == nil || [result count] <= 0)
        return NO;
    
    return YES;
}

- (BOOL) GetDatabaseLog: (NSMutableArray*) result {
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetDatabaseLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}

- (BOOL) GetRequestsLog: (NSMutableArray*) result {
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetRequestsLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}

- (BOOL) GetChatLog: (NSMutableArray*) result {
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetChatLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}

- (BOOL) GetTraceLog: (NSMutableArray*) result {
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetTraceLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}

- (BOOL) GetVoipLog: (NSMutableArray*) result {
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetVoipLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}

- (BOOL) GetGuiLog: (NSMutableArray*) result {
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetGuiLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}

- (BOOL) GetCallQualityLog: (NSMutableArray*) result
{
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetCallQualityLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}

- (BOOL) GetCallHistoryLog: (NSMutableArray*) result
{
    std::vector<std::string> c_result;
    
    if( !dodicall::Application::GetInstance().GetCallHistoryLog(c_result) )
        return NO;
    
    return [self convert_log: c_result : result];
}


- (void) WriteGuiLog: (ObjC_LogLevel) level :
                                      (NSString*) data {
    dodicall::LogLevel c_level;
    
    std::string c_data = [self convert_to_std_string: data];
    
    switch ( level ) {
        case LogLevelError:
            c_level = dodicall::LogLevelError;
            break;
        case LogLevelWarning:
            c_level = dodicall::LogLevelWarning;
            break;
        case LogLevelDebug:
            c_level = dodicall::LogLevelDebug;
            break;
        case LogLevelInfo:
            c_level = dodicall::LogLevelInfo;
            break;
    }
    dodicall::Application::GetInstance().WriteGuiLog(c_level, c_data.c_str());
}


- (void) ClearLogs {
    dodicall::Application::GetInstance().ClearLogs();
}

@end
