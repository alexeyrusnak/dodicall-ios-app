//
//  UiAppTabsViewModel.m
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

#import "UiAppTabsViewModel.h"
#import "UiNotificationsManager.h"
#import "AppManager.h"


@implementation UiAppTabsViewModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        RAC(self,ContactsTabBadgeValue) = [[[RACObserve([UiNotificationsManager NotificationsManager], ContactsTabCounter) ignore:nil] deliverOn:[AppManager Manager].ViewModelScheduler] map:^NSString *(NSNumber *Value) {
            
            return [Value intValue] > 99 ? @"99+" : [Value intValue] == 0 ? nil : [NSString stringWithFormat:@"%@", Value];
            
        }];
        
        RAC(self,ChatsTabBadgeValue) = [[[RACObserve([UiNotificationsManager NotificationsManager], ChatsTabCounter) ignore:nil] deliverOn:[AppManager Manager].ViewModelScheduler] map:^NSString *(NSNumber *Value) {
            
            return [Value intValue] > 99 ? @"99+" : [Value intValue] == 0 ? nil : [NSString stringWithFormat:@"%@", Value];
            
        }];
        
        RAC(self,HistoryTabBadgeValue) = [[[RACObserve([UiNotificationsManager NotificationsManager], HistoryTabCounter) ignore:nil] deliverOn:[AppManager Manager].ViewModelScheduler] map:^NSString *(NSNumber *Value) {
            
            return [Value intValue] > 99 ? @"99+" : [Value intValue] == 0 ? nil : [NSString stringWithFormat:@"%@", Value];
            
        }];
        
        RAC(self,VoipTabIconName) = [[[RACObserve([UiNotificationsManager NotificationsManager], VoipConnectionStatus) distinctUntilChanged] deliverOn:[AppManager Manager].ViewModelScheduler] map:^NSString *(UiNotificationsManagerConnectionStatus Value)
        {
            
            NSString *IconName = @"dialpad_no_reg_tab_icon";
            
            if([Value isEqualToString:UiNotificationsManagerConnectionStatusWiFi])
            {
                IconName = @"dialpad_wifi_tab_icon";
            }
            
            else if([Value isEqualToString:UiNotificationsManagerConnectionStatusLte])
            {
                IconName = @"dialpad_lte_tab_icon";
            }
            
            else if([Value isEqualToString:UiNotificationsManagerConnectionStatus3g])
            {
                IconName = @"dialpad_3g_tab_icon";
            }
            
            else if([Value isEqualToString:UiNotificationsManagerConnectionStatusEdge])
            {
                IconName = @"dialpad_e_tab_icon";
            }
            
            return  IconName;
            
        }];
        
        RAC(self,ChatTabIconName) = [[[RACObserve([UiNotificationsManager NotificationsManager], ChatConnectionStatus) distinctUntilChanged] deliverOn:[AppManager Manager].ViewModelScheduler] map:^NSString *(UiNotificationsManagerConnectionStatus Value)
         {
             
             NSString *IconName = @"chat_no_reg_tab_icon";
             
             if([Value isEqualToString:UiNotificationsManagerConnectionStatusWiFi])
             {
                 IconName = @"chat_wifi_tab_icon";
             }
             
             else if([Value isEqualToString:UiNotificationsManagerConnectionStatusLte])
             {
                 IconName = @"chat_lte_tab_icon";
             }
             
             else if([Value isEqualToString:UiNotificationsManagerConnectionStatus3g])
             {
                 IconName = @"chat_3g_tab_icon";
             }
             
             else if([Value isEqualToString:UiNotificationsManagerConnectionStatusEdge])
             {
                 IconName = @"chat_e_tab_icon";
             }
             
             return  IconName;
             
         }];
        
    }
    return self;
}

@end
