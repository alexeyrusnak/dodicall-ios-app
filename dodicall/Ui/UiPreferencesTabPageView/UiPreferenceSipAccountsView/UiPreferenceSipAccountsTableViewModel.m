//
//  UiPreferenceSipAccountsTableViewModel.m
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

#import "UiPreferenceSipAccountsTableViewModel.h"
#import "AppManager.h"

#import "UiLogger.h"

@implementation UiPreferenceSipAccountsTableViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.Data = [[NSMutableArray alloc] init];
        
        // Populate data
        for (ServerSettingModel *SettingsObj in [AppManager app].DeviceSettingsModel.ServerSettings) {
            
            if(SettingsObj.ServerType == ServerTypeSip)
            {
                NSMutableDictionary *SipAccount = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *SipAccountSettings = [[NSMutableDictionary alloc] init];
                
                [SipAccountSettings setObject:(([SettingsObj.Default boolValue]?@YES:@NO)) forKey:@"IsDefault"];
                
                [SipAccount setObject:[NSString stringWithFormat:@"%@@%@",(SettingsObj.AuthUserName.length > 0)?SettingsObj.AuthUserName:SettingsObj.Username,SettingsObj.Domain] forKey:@"Title"];
                
                [SipAccount setObject:[NSString stringWithFormat:@"%@",SettingsObj.Domain] forKey:@"Domain"];
                
                [SipAccount setObject:SipAccountSettings forKey:@"Settings"];
                
                [self.Data addObject:SipAccount];
            }
            
        }
        
        //Check for default
        
        NSString *DefautDomain = @"";
        
        if([AppManager app].UserSettingsModel.DefaultVoipServer && [AppManager app].UserSettingsModel.DefaultVoipServer.length > 0)
        {
            for (NSMutableDictionary *SettingsObj in self.Data)
            {
                NSString *Domain = [SettingsObj objectForKey:@"Domain"];
                
                if([[AppManager app].UserSettingsModel.DefaultVoipServer isEqualToString:Domain])
                {
                    [[SettingsObj objectForKey:@"Settings"] setObject:@YES forKey:@"IsDefault"];
                    
                    DefautDomain = Domain;
                }
                else
                {
                    [[SettingsObj objectForKey:@"Settings"] setObject:@NO forKey:@"IsDefault"];
                }
                
            }
        }
        
        [AppManager app].UserSettingsModel.DefaultVoipServer = DefautDomain;
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UiPreferenceSipAccountsTableViewModel: Sip Accounts:%lul",(unsigned long)[self.Data count]]];
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UiPreferenceSipAccountsTableViewModel: DefaultVoipServer:%@",[AppManager app].UserSettingsModel.DefaultVoipServer]];
        
        
        
    }
    return self;
}

- (void) SaveChanges
{
    for (NSMutableDictionary *SettingsObj in self.Data)
    {
        if([[[SettingsObj objectForKey:@"Settings"] objectForKey:@"IsDefault"] boolValue])
        {
            
            [AppManager app].UserSettingsModel.DefaultVoipServer = [SettingsObj objectForKey:@"Domain"];
            
        }
        
    }
    
    [UiLogger WriteLogInfo:@"UiPreferenceSipAccountsTableViewModel: SaveChanges"];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UiPreferenceSipAccountsTableViewModel: DefaultVoipServer:%@",[AppManager app].UserSettingsModel.DefaultVoipServer]];
    
    [[AppManager app] SaveUserSettingsModel];
}

- (void) DidCellSelected:(NSString *) CellIdentifier
{

}

@end
