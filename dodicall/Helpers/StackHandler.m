//
//  StackHandler.m
//  dodicall
//
//  Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
//
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

#import "StackHandler.h"
#import "execinfo.h"
#import "UiLogger.h"

#define kKEY_ExceptionName                      @"ExceptionName"
#define kKEY_ExceptionReason                    @"ExceptionReason"
#define kKEY_ExceptionCallStack                 @"ExceptionCallStack"
typedef NSString*                               ExceptionKeys;

void RegisterHandler();

@implementation StackHandler

+ (void) RegisterCrashHandler {
    RegisterHandler();
}

+ (NSDictionary *) GetExceptionDictionary:(NSException *) exception {

    NSMutableDictionary *crashReport = [NSMutableDictionary dictionary];
    crashReport[kKEY_ExceptionName] = exception.name;
    crashReport[kKEY_ExceptionReason] = exception.reason;
    crashReport[kKEY_ExceptionCallStack] = exception.callStackSymbols.debugDescription;
    
    return crashReport;
}

+ (NSDictionary *) GetBadSignalDictionary:(int) signal {
    //Get symbolic backtrace
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = 0; i < 10;i++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    //Build dictionary
    NSMutableDictionary *crashReport = [NSMutableDictionary dictionary];
    crashReport[kKEY_ExceptionName] = [NSNumber numberWithInt:signal];
    crashReport[kKEY_ExceptionCallStack] = backtrace;
    
    return crashReport;
}

+ (void) LogCrashReport:(NSDictionary *)crashReport {
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"Application crashed: \n"]];
    for(id value in crashReport.allValues) {
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"%@", value]];
    }
}

+ (void) LogCurrentStackTrace {
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"Current stack trace: \n%@", [NSThread callStackSymbols]]];
}

@end



void ExceptionHandler(NSException *exception) {
    [StackHandler LogCrashReport:[StackHandler GetExceptionDictionary:exception]];
}

void SignalHandler(int signal) {
    [StackHandler LogCrashReport:[StackHandler GetBadSignalDictionary:signal]];
}

void RegisterHandler() {
    NSSetUncaughtExceptionHandler(&ExceptionHandler);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
}
