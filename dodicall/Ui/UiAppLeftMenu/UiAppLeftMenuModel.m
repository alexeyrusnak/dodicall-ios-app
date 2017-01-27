//
//  UiAppLeftMenuModel.m
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

#import "UiAppLeftMenuModel.h"

#import "UiLogger.h"

#import "ContactsManager.h"

@interface UiAppLeftMenuModel()
{
    BOOL IsBinded;
}

@end

@implementation UiAppLeftMenuModel

@synthesize AppVersionText;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        
        self.AppVersionText = [NSString stringWithFormat:NSLocalizedString(@"Title_AppVersion",nil), [AppManager app].AppVersion];
        
        [self BindAll];
        
    }
    return self;
}

- (void) BindAll
{
    if(IsBinded)
        return;
    
    @weakify(self);
    
    // Balance
    
    [RACObserve([AppManager app].UserSession, BalanceString) subscribeNext:^(NSString *BalanceString) {
        
        @strongify(self);
        
        [self setBalanceTextValue:BalanceString];
        
    }];
    
    // Bind status for my profile
    
    [RACObserve([AppManager app].UserSettingsModel, UserBaseStatus) subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self SetMyProfileStatus];
        
    }];
    
    [RACObserve([AppManager app].UserSettingsModel, UserExtendedStatus) subscribeNext:^(NSString *StatusString) {
        
        @strongify(self);
        
        [self SetMyProfileStatus];
        
    }];
    
    [RACObserve([AppManager app].GlobalApplicationSettingsModel, Area) subscribeNext:^(NSNumber *Area) {
        
        @strongify(self);
        
        NSString *_AppVersionText = [NSString stringWithFormat:NSLocalizedString(@"Title_AppVersion",nil), [AppManager app].AppVersion];
        
        if([Area intValue] != 0)
        {
            _AppVersionText = [_AppVersionText stringByAppendingString:[NSString stringWithFormat:@" %@", [[AppManager app].UserSession GetServerAreaName]]];
        }
        
        self.AppVersionText = _AppVersionText;
        
    }];
    
    RAC(self, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:RACObserve([[AppManager app] UserSession], MyProfile) WithDoNextBlock:^(NSString *Path) {
        @strongify(self);
        self.AvatarPath = Path;
    }];
    
    IsBinded = YES;
}

- (void) SetMyProfileStatus
{
    
    
    //Status
    BaseUserStatus _Status = [AppManager app].UserSettingsModel.UserBaseStatus;
    
    switch (_Status) {
            
        case BaseUserStatusOnline:
            [self setMyProfileStatus:@"ONLINE"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_ONLINE", nil)]];
            break;
            
        case BaseUserStatusDnd:
            [self setMyProfileStatus:@"DND"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_DND", nil)]];
            break;
            
        case BaseUserStatusAway:
            [self setMyProfileStatus:@"AWAY"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_AWAY", nil)]];
            break;
            
        case BaseUserStatusHidden:
            [self setMyProfileStatus:@"INVISIBLE"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_INVISIBLE", nil)]];
            break;
            
        default:
            [self setMyProfileStatus:@"INVISIBLE"];
            [self setMyProfileStatusLabelText:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
            break;
    }
    
    
    NSString *StatusString = [AppManager app].UserSettingsModel.UserExtendedStatus;
    
    if(StatusString && StatusString.length > 0)
        [self setMyProfileStatusLabelText:[[self.MyProfileStatusLabelText stringByAppendingString:@". "] stringByAppendingString:StatusString]];
}

@end
