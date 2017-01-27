//
//  NotificationsManager.h
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

#import <Foundation/Foundation.h>
#import "SystemNotificationModel.h"

#define UiNotificationsManagerConnectionStatusWiFi          @"WiFi"
#define UiNotificationsManagerConnectionStatusLte           @"Lte"
#define UiNotificationsManagerConnectionStatus3g            @"3g"
#define UiNotificationsManagerConnectionStatusEdge          @"Edge"
#define UiNotificationsManagerConnectionStatusNone          @"None"
typedef NSString*                                       UiNotificationsManagerConnectionStatus;

@interface UiNotificationsManager : NSObject

@property NSNumber *ContactsTabCounter;

@property NSNumber *HistoryTabCounter;

@property NSNumber *ChatsTabCounter;

@property NSNumber *ContactsSubscriptionsInvitesCounter;

@property NSNumber *AppIconBadgeCounter;

@property UiNotificationsManagerConnectionStatus NetworkConnectionStatus;

@property UiNotificationsManagerConnectionStatus VoipConnectionStatus;

@property UiNotificationsManagerConnectionStatus ChatConnectionStatus;

+ (instancetype) Manager;

+ (instancetype) NotificationsManager;

+ (void) Destroy;

- (void) SetActive:(BOOL) Active;

- (void) PerformContactsSubscriptionsInvitesCounterChangeEvent:(NSNumber *) InvitesCount;

- (void) PerformNetworkStateChangeEvent;

- (void) PerformChatsNewMessagesCounterChangeEvent:(NSNumber *) NewMessagesCount;

- (void) PerformMissedCallsCounterChangeEvent:(NSNumber *) MissedCallsCount;

@end
