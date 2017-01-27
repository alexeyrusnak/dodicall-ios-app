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
//  Dodicall_Bridge+Push_Notify.m
//  DodicallBridgeIos
//


#import "Dodicall_Bridge+Push_Notify.h"
#import <UIKit/UIKit.h>
#include "StubsServerAccessor.h"
#include "Application.h"
#import "Dodicall_Bridge+Helpers.h"

@interface objc_contact_struct () {
}

@end

@implementation objc_contact_struct {
}

@end

@interface local_notify_struct () {
}

@end

@implementation local_notify_struct {
}

@end

@implementation Dodicall_Bridge (Push_Notify)

-(void)registerDeviceForPushNotifications {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSString *)token
{
    char const *c_token = [token UTF8String];
    
#ifndef DEBUG
    dodicall::Application::GetInstance().RegisterPushTokenOnServer(c_token, dodicall::NotificationModeProduction);
#else
    dodicall::Application::GetInstance().RegisterPushTokenOnServer(c_token, dodicall::NotificationModeSandbox);
#endif
}

- (void)didRegisterForRemoteVoipNotificationsWithDeviceToken:(NSString *)token
{
    char const *c_token = [token UTF8String];
    
#ifndef DEBUG
    dodicall::Application::GetInstance().RegisterPushTokenOnServer(c_token, dodicall::NotificationModeProduction, true);
#else
    dodicall::Application::GetInstance().RegisterPushTokenOnServer(c_token, dodicall::NotificationModeSandbox, true);
#endif
}

- (void) RemoveRemoteNotificationsDeviceToken:(NSString *)token
{
    char const *c_token = [token UTF8String];
    
    dodicall::Application::GetInstance().RemovePushTokenFromServer(c_token);
}

- (void) RemoveRemoteVoipNotificationsDeviceToken:(NSString *)token
{
    char const *c_token = [token UTF8String];
    
    dodicall::Application::GetInstance().RemovePushTokenFromServer(c_token, true);
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSString *)token {
    
}


const int cMaxLastLocalUserNotifications = 50;
NSMutableArray* mLastLocalUserNotifications;
/**
 * Send local system user notification
 */

- (BOOL) sendLocalSystemUserNotification:(local_notify_struct*)notify_command {
    BOOL res;
    
    BOOL inBg = FALSE;
    
    // Check option
    if(notify_command.inBg) {
        inBg = TRUE;
    }
    
    if(inBg && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
        return YES;
    }
    
    NSString* title = notify_command.title;
    NSString* body = notify_command.body;
    NSString* action = notify_command.action;
    BOOL hasAction = notify_command.hasAction;
    NSString* sound = notify_command.sound;
    
    NSData *metaData = [ notify_command.metaData base64EncodedDataWithOptions:NSUTF8StringEncoding];
    NSError *error;
    
    NSDictionary *jsonDict;
    
    if ( metaData != nil )
        jsonDict = [NSJSONSerialization JSONObjectWithData:metaData options:0 error:&error];
    
    int notifId = notify_command.notifId;
    
    int vibrate = notify_command.vibrate;
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertAction = action;
    localNotification.hasAction = hasAction;
    localNotification.alertBody = [NSString stringWithFormat:@"%@\n%@",title,body];
    localNotification.soundName = sound;
    localNotification.userInfo = jsonDict;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    
    if (mLastLocalUserNotifications.count >= cMaxLastLocalUserNotifications)
        [mLastLocalUserNotifications removeLastObject];
    
    //if(vibrate == 1)
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [mLastLocalUserNotifications insertObject:localNotification atIndex:0];
    
    return YES;
}

/*
 * Cancel local system user notification
 */

- (BOOL)cancelLocalSystemUserNotification:(local_notify_struct*)notify_command {
    BOOL res;
    
    int notifId = notify_command.notifId;
    
    UIApplication *app = [UIApplication sharedApplication];
    for (int i=0; i<[mLastLocalUserNotifications count]; i++)
    {
        @try {
            UILocalNotification* oneEvent = [mLastLocalUserNotifications objectAtIndex:i];
            NSDictionary *userInfoCurrent = oneEvent.userInfo;
            int _notifId = [[userInfoCurrent valueForKey:@"id"] integerValue];
            if (_notifId == notifId)
            {
                //Cancelling local notification
                [app cancelLocalNotification:oneEvent];
                
                [mLastLocalUserNotifications removeObjectAtIndex:i];
                
                break;
            }
        }
        @catch (NSException *exception) {
            
        }
    }
    return YES;
}

@end
