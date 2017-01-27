//
//  NotificationsManager.m
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
//

#import "UiNotificationsManager.h"
#import "AppManager.h"
#import "UiLogger.h"

static UiNotificationsManager *NotificationsManagerSingleton = nil;
static dispatch_once_t NotificationsManagerSingletonOnceToken;

@interface UiNotificationsManager()

@property NSNumber *Active;

@end

@implementation UiNotificationsManager
{
    BOOL AllInited;
}

+ (instancetype) Manager
{
    return [self NotificationsManager];
}

+ (instancetype) NotificationsManager
{
    dispatch_once(&NotificationsManagerSingletonOnceToken, ^{
        
        NotificationsManagerSingleton = [[UiNotificationsManager alloc] init];
        
    });
    
    [NotificationsManagerSingleton InitAll];
    
    return NotificationsManagerSingleton;
}

+ (void) Destroy
{
    if(NotificationsManagerSingleton)
    {
        NotificationsManagerSingleton = nil;
        NotificationsManagerSingletonOnceToken = 0;
    }
}

- (void) SetActive:(BOOL) Active
{
    self.Active = [NSNumber numberWithBool:Active];
}

- (void) InitAll
{
    
    if (!AllInited) {
        
        AllInited = YES;
        
        self.ContactsTabCounter = [NSNumber numberWithInt:0];
        
        self.ContactsSubscriptionsInvitesCounter = [NSNumber numberWithInt:0];
        
        self.ChatsTabCounter = [NSNumber numberWithInt:0];
        
        self.AppIconBadgeCounter = [NSNumber numberWithInt:0];
        
        self.HistoryTabCounter = [NSNumber numberWithInt:0];
        
        self.NetworkConnectionStatus = UiNotificationsManagerConnectionStatusNone;
        
        
        [[RACSignal combineLatest:@[RACObserve(self, ChatsTabCounter), RACObserve(self, ContactsTabCounter), RACObserve(self, HistoryTabCounter)]
                         reduce:^id(NSNumber *ChatsCounter, NSNumber *ContactsCounter, NSNumber *HistoryCounter){
                             return [NSNumber numberWithInt:[ChatsCounter intValue] + [ContactsCounter intValue] + [HistoryCounter intValue]];
                         }]
         subscribeNext:^(NSNumber *Result) {
             
             self.AppIconBadgeCounter = [Result copy];
             
         }];
        
        [RACObserve(self, AppIconBadgeCounter) subscribeNext:^(NSNumber *Result) {
            
            if([AppManager app].UserSession.IsUserAuthorized && [Result intValue] > 0)
            {
                [UIApplication sharedApplication].applicationIconBadgeNumber = [Result intValue];
            }
            
        }];
        
        @weakify(self);
        
        [RACObserve([AppManager app], IsAppActive) subscribeNext:^(NSNumber *Result) {
            
            @strongify(self);
            
            if([AppManager app].UserSession.IsUserAuthorized && [self.AppIconBadgeCounter intValue])
            {
                [UIApplication sharedApplication].applicationIconBadgeNumber = [self.AppIconBadgeCounter intValue];
            }
            
        }];
        
        [[[RACObserve(self, AppIconBadgeCounter)
            throttle:20] filter:^BOOL(NSNumber *Result) {
                return [Result intValue] == 0;
            }]
            subscribeNext:^(NSNumber *Result) {
                [UIApplication sharedApplication].applicationIconBadgeNumber = [Result intValue];
            }];
        
    }
}

- (void) CalcAll
{
    
    self.ContactsTabCounter = [NSNumber numberWithInt:[self.ContactsSubscriptionsInvitesCounter intValue]];
    
}

- (void) PerformContactsSubscriptionsInvitesCounterChangeEvent:(NSNumber *) InvitesCount
{
    self.ContactsSubscriptionsInvitesCounter = [NSNumber numberWithInt:[InvitesCount intValue]];
    
    [self CalcAll];
}

- (void) PerformNetworkStateChangeEvent
{
    dispatch_async([AppManager Manager].AppSerialQueue, ^{
        
    
        ObjC_NetworkStateModel *State = [[AppManager app].Core GetNetworkState];
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
       
            switch (State.Technology) {
                case NetworkTechnologyWifi:
                    
                    self.NetworkConnectionStatus = UiNotificationsManagerConnectionStatusWiFi;
                    
                    self.VoipConnectionStatus = [State.VoipStatus boolValue] ? UiNotificationsManagerConnectionStatusWiFi : UiNotificationsManagerConnectionStatusNone;
                    
                    self.ChatConnectionStatus = [State.ChatStatus boolValue] ? UiNotificationsManagerConnectionStatusWiFi : UiNotificationsManagerConnectionStatusNone;
                    
                    break;
                    
                case NetworkTechnologyEdge:
                    
                    self.NetworkConnectionStatus = UiNotificationsManagerConnectionStatusEdge;
                    
                    self.VoipConnectionStatus = [State.VoipStatus boolValue] ? UiNotificationsManagerConnectionStatusEdge : UiNotificationsManagerConnectionStatusNone;
                    
                    self.ChatConnectionStatus = [State.ChatStatus boolValue] ? UiNotificationsManagerConnectionStatusEdge : UiNotificationsManagerConnectionStatusNone;
                    
                    break;
                    
                case NetworkTechnology3g:
                    
                    self.NetworkConnectionStatus = UiNotificationsManagerConnectionStatus3g;
                    
                    self.VoipConnectionStatus = [State.VoipStatus boolValue] ? UiNotificationsManagerConnectionStatus3g : UiNotificationsManagerConnectionStatusNone;
                    
                    self.ChatConnectionStatus = [State.ChatStatus boolValue] ? UiNotificationsManagerConnectionStatus3g : UiNotificationsManagerConnectionStatusNone;
                    
                    break;
                    
                case NetworkTechnologyLte:
                    
                    self.NetworkConnectionStatus = UiNotificationsManagerConnectionStatusLte;
                    
                    self.VoipConnectionStatus = [State.VoipStatus boolValue] ? UiNotificationsManagerConnectionStatusLte : UiNotificationsManagerConnectionStatusNone;
                    
                    self.ChatConnectionStatus = [State.ChatStatus boolValue] ? UiNotificationsManagerConnectionStatusLte : UiNotificationsManagerConnectionStatusNone;
                    
                    break;
                    
                default:
                    
                    self.NetworkConnectionStatus = UiNotificationsManagerConnectionStatusNone;
                    
                    self.VoipConnectionStatus = [State.VoipStatus boolValue] ? UiNotificationsManagerConnectionStatusNone : UiNotificationsManagerConnectionStatusNone;
                    
                    self.ChatConnectionStatus = [State.ChatStatus boolValue] ? UiNotificationsManagerConnectionStatusNone : UiNotificationsManagerConnectionStatusNone;
                    
                    break;
            }
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiNotificationsManager:PerformNetworkStateChangeEvent:Network = %@; Voip = %@; Chat = %@;", (NSString *) self.NetworkConnectionStatus, (NSString *) self.VoipConnectionStatus, (NSString *) self.VoipConnectionStatus]];
        
        //});
    });
}

- (void) PerformChatsNewMessagesCounterChangeEvent:(NSNumber *) NewMessagesCount
{
    self.ChatsTabCounter = [NSNumber numberWithInt:[NewMessagesCount intValue]];
}

- (void) PerformMissedCallsCounterChangeEvent:(NSNumber *) MissedCallsCount
{
    self.HistoryTabCounter = [NSNumber numberWithInt:[MissedCallsCount intValue]];
}

@end
