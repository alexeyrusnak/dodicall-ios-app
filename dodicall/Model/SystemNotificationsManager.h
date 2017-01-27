//
//  SystemNotificationsManager.h
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
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "SystemNotificationModel.h"

#import <PushKit/PushKit.h>

@class ObjC_CallModel;

@interface SystemNotificationsManager : NSObject <PKPushRegistryDelegate>

@property SystemNotificationModel *SystemNotificationClicked;

@property RACSignal *SystemNotificationClickedSignal;

@property SystemNotificationModel *SystemNotificationInProcess;

@property RACSignal *SystemNotificationInProcessSignal;

@property SystemNotificationModel *SystemNotificationWait;

@property NSInteger CurrentIncomingCallSystemLocalNotificationId;

@property NSString *PushToken;

@property NSString *VoipPushToken;

+ (instancetype) Manager;

+ (instancetype) SystemNotifications;

+ (void) Destroy;

- (void) SetActive:(BOOL) Active;

- (void) SetupSystemNotificationsSettings;

- (void) RegisterForSystemNotifications;

- (void) PerformDidReceiveSystemLocalNotfification: (UILocalNotification *) LocalNotfification;

- (void) PerformDidReceiveSystemRemoteNotfification: (NSDictionary *) RemoteNotfification;

- (void) PerformHandleActionOfSystemRemoteNotfificationWithIdentifier:(NSString *) Identifier AndAction: (NSDictionary *) RemoteNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler;

- (void) PerformHandleActionOfSystemLocalNotfificationWithIdentifier:(NSString *) Identifier AndAction: (UILocalNotification *) LocalNotfification withResponseInfo:(NSDictionary *)ResponseInfo completionHandler:(void(^)())CompletionHandler;

- (NSInteger) SendSystemLocalNotification:(SystemNotificationModel *) SystemNotification;

- (void) CancelSystemLocalNotificationWithId:(NSInteger) Id;

- (void) SendSystemLocalIncomingCallNotificationWithCall:(ObjC_CallModel *) Call;

- (void) CancelSystemLocalIncomingCallNotification;

- (void) PerformDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)DevToken;

- (void) PerformDidFailToRegisterForRemoteNotificationsWithError:(NSError *)err;

@end
