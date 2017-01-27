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
//  Dodicall_Bridge+Push_Notify.h
//  DodicallBridgeIos
//


#import "Dodicall_Bridge.h"




@interface objc_contact_struct: NSObject {
};
    @property   NSString* type;
    @property   NSString* value;

@end

@interface local_notify_struct: NSObject {
};

    @property NSString* title;
    @property NSString* body;
    @property NSString* action;
    @property BOOL hasAction;
    @property NSString* sound;

    @property NSData *metaData;
    @property  NSError *error;

    @property int notifId;

    @property int vibrate;

    @property BOOL inBg;

@end




@interface Dodicall_Bridge (Push_Notify)

- (void)registerDeviceForPushNotifications;

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSString *)token;

- (void)didRegisterForRemoteVoipNotificationsWithDeviceToken:(NSString *)token;

- (void) RemoveRemoteNotificationsDeviceToken:(NSString *)token;

- (void) RemoveRemoteVoipNotificationsDeviceToken:(NSString *)token;

//- (void) SetUserContacts: (NSString *) userUuid : (NSMutableArray *) userContacts;

- (void) didFailToRegisterForRemoteNotificationsWithError:(NSString *)token;

- (BOOL) sendLocalSystemUserNotification:(local_notify_struct*)notify_command;

- (BOOL)cancelLocalSystemUserNotification:(local_notify_struct*)notify_command;

@end
