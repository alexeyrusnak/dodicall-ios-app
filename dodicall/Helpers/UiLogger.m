//
//  UiLogger.m
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

#import "UiLogger.h"
#import "AppManager.h"


static UiLogger* _Logger = nil;

static BOOL NSLogEnabled = NO;

@implementation UiLogger

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        _Logger = self;
        
    }
    
    return self;
}


+ (void) WriteLogUserTapEvent:(NSString *) ButtonName inPlace: (NSString *) Place
{
    
    [[AppManager app].Core WriteGuiLog:LogLevelInfo :[NSString stringWithFormat:UiLoggerTemplateUserTapEvent, ButtonName, Place]];
    
    #ifdef DEBUG
        if(NSLogEnabled)
            NSLog([NSString stringWithFormat:UiLoggerTemplateUserTapEvent, ButtonName, Place]);
    #endif
    
}

+ (void) WriteLogInfo:(NSString *) Event
{
    
    [[AppManager app].Core WriteGuiLog:LogLevelInfo :[NSString stringWithFormat:UiLoggerTemplateDefault, Event]];
    
    #ifdef DEBUG
        if(NSLogEnabled)
            NSLog([NSString stringWithFormat:UiLoggerTemplateDefault, Event]);
    #endif
    
}

+ (void) WriteLogDebug:(NSString *) DebugInfo
{
    
    [[AppManager app].Core WriteGuiLog:LogLevelDebug :[NSString stringWithFormat:UiLoggerTemplateDefault, DebugInfo]];
    
    #ifdef DEBUG
        if(NSLogEnabled)
            NSLog([NSString stringWithFormat:UiLoggerTemplateDefault, DebugInfo]);
    #endif
    
}


+ (UiLogger*) Logger {
    return _Logger;
}

@end
