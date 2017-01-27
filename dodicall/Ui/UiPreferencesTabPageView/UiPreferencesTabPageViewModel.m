//
//  UiPreferencesTabPageViewModel.m
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

#import "UiPreferencesTabPageViewModel.h"
#import "AppManager.h"

@implementation UiPreferencesTabPageViewModel

//@synthesize AppVersionText;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        
        self.AppVersionText = [NSString stringWithFormat:NSLocalizedString(@"Title_AppVersion",nil), [AppManager app].AppVersion];
        
        @weakify(self);
        
        [RACObserve([AppManager app].GlobalApplicationSettingsModel, Area) subscribeNext:^(NSNumber *Area) {
            
            @strongify(self);
            
            NSString *__AppVersionText = [NSString stringWithFormat:NSLocalizedString(@"Title_AppVersion",nil), [AppManager app].AppVersionShort];
            
            if([Area intValue] != 0)
            {
                __AppVersionText = [NSString stringWithFormat:NSLocalizedString(@"Title_AppVersionExtended",nil), [AppManager app].AppVersion, [[AppManager app].Core GetLibVersion], [[AppManager app].UserSession GetServerAreaName]];
                
                //__AppVersionText = [_AppVersionText stringByAppendingString:[NSString stringWithFormat:@" %@", [[AppManager app].UserSession GetServerAreaName]]];
            }
            
            self.AppVersionText = __AppVersionText;
            
        }];
    }
    return self;
}

- (void) Logout
{
    //[[AppManager app].UserSession LogOut];
    
    [[AppManager app].UserSession ExecuteLogoutProcess];
}

@end
