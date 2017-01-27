//
//  CoreHelper.h
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
#import <UIKit/UIKit.h>

@class ObjC_GlobalApplicationSettingsModel;

@class ObjC_UserSettingsModel;

@class ObjC_ContactModel;

@class ObjC_ChatModel;

@class SystemNotificationModel;

@class ObjC_ContactSubscription;

@interface CoreHelper : NSObject

+ (NSString *) GlobalApplicationSettingsDescription: (ObjC_GlobalApplicationSettingsModel *) Object;

+ (NSString *) UserSettingsModelDescription: (ObjC_UserSettingsModel *) Object;

+ (NSString *) ResultErrorCodeDescription: (int) Object;

+ (NSString *) ContactModelDescription: (ObjC_ContactModel *) Object;

+ (NSString *) ContactSubscriptionDescription: (ObjC_ContactSubscription *) Object;

+ (NSString *) ChatModelDescription: (ObjC_ChatModel *) Object;

+ (SystemNotificationModel *) TransformRemoteNotificationToSystemNotificationModel: (NSDictionary *) RemoteNotification;

+ (SystemNotificationModel *) TransformLocalNotificationToSystemNotificationModel: (UILocalNotification *) LocalNotification;

+ (NSString *) SystemNotificationModelDescription: (SystemNotificationModel *) Object;

+ (NSString *) FormatContactIdentity: (NSString *) ContactIdentity;

@end
