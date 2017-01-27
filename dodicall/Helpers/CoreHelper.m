//
//  CoreHelper.m
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

#import "CoreHelper.h"
#import "Dodicall_Bridge.h"
//#import "Dodicall_Bridge+Helpers.h"
#import "ObjC_ContactSubscription.h"
#import "ObjC_ChatModel.h"
#import "ChatsManager.h"
#import "SystemNotificationModel.h"

@implementation CoreHelper

+ (NSString *) GlobalApplicationSettingsDescription: (ObjC_GlobalApplicationSettingsModel *) Object
{
    
    NSString * AreaTitle = [[AppManager app].UserSession GetServerAreaName];
    
    
    return [NSString stringWithFormat:@"LastLogin:%@; AreaCode:%ld; AreaName:%@; Autologin:%@; DefaultGuiLanguage:%@",Object.LastLogin,(long)Object.Area,AreaTitle,[Object.Autologin boolValue]?@"YES":@"NO",Object.DefaultGuiLanguage];
}

+ (NSString *) UserSettingsModelDescription: (ObjC_UserSettingsModel *) Object
{
    
    NSArray *Format = @[
                       @"Autologin: %@",
                       @"UserBaseStatus: %@",
                       @"UserExtendedStatus: %@",
                       @"DoNotDesturbMode: %@",
                       @"DefaultVoipServer: %@",
                       @"VoipEncryption: %@",
                       @"EchoCancellationMode: %@",
                       @"VideoEnabled: %@",
                       @"VideoSizeWifi: %@",
                       @"VideoSizeCell: %@",
                       @"GuiThemeName: %@",
                       @"GuiAnimation: %@",
                       @"GuiLanguage: %@",
                       @"GuiFontSize: %@",
                       @"TraceMode: %@"
                                        /**/
                       ];
    
    NSString * UserBaseStatusString = @"";
    
    switch(Object.UserBaseStatus) {
        case BaseUserStatusOffline:
            UserBaseStatusString = @"BaseUserStatusOffline";
            break;
        case BaseUserStatusOnline:
            UserBaseStatusString = @"BaseUserStatusOnline";
            break;
        case BaseUserStatusHidden:
            UserBaseStatusString = @"BaseUserStatusHidden";
            break;
        case BaseUserStatusAway:
            UserBaseStatusString = @"BaseUserStatusAway";
            break;
        case BaseUserStatusDnd:
            UserBaseStatusString = @"BaseUserStatusDnd";
            break;
    }
    
    NSString * VoipEncryptionString = @"";
    
    switch(Object.VoipEncryption) {
        case VoipEncryptionNone:
            VoipEncryptionString = @"VoipEncryptionNone";
            break;
        case VoipEncryptionSrtp:
            VoipEncryptionString = @"VoipEncryptionSrtp";
            break;
    }
    
    NSString * EchoCancellationModeString = @"";
    
    switch(Object.EchoCancellationMode) {
        case EchoCancellationModeOff:
            EchoCancellationModeString = @"EchoCancellationModeOff";
            break;
        case EchoCancellationModeSoft:
            EchoCancellationModeString = @"EchoCancellationModeSoft";
            break;
        case EchoCancellationModeHard:
            EchoCancellationModeString = @"EchoCancellationModeHard";
            break;
    }
    
    NSString * VideoSizeWifiString = @"";
    
    switch(Object.VideoSizeWifi) {
        case VideoSizeQvga:
            VideoSizeWifiString = @"VideoSizeQvga";
            break;
        case VideoSizeVga:
            VideoSizeWifiString = @"VideoSizeVga";
            break;
        case VideoSize720p:
            VideoSizeWifiString = @"VideoSize720p";
            break;
    }
    
    NSString * VideoSizeCellString = @"";
    
    switch(Object.VideoSizeCell) {
        case VideoSizeQvga:
            VideoSizeCellString = @"VideoSizeQvga";
            break;
        case VideoSizeVga:
            VideoSizeCellString = @"VideoSizeVga";
            break;
        case VideoSize720p:
            VideoSizeCellString = @"VideoSize720p";
            break;
    }
    
    NSString * FormatString = [Format componentsJoinedByString:@"; "];
    
    return [NSString stringWithFormat:FormatString,
            
            [Object.Autologin boolValue]?@"YES":@"NO",
            
            UserBaseStatusString,
            Object.UserExtendedStatus,
            [Object.DoNotDesturbMode boolValue]?@"YES":@"NO",
            Object.DefaultVoipServer,
            VoipEncryptionString,
            EchoCancellationModeString,
            [Object.VideoEnabled boolValue]?@"YES":@"NO",
            VideoSizeWifiString,
            VideoSizeCellString,
            Object.GuiThemeName,
            [Object.GuiAnimation boolValue]?@"YES":@"NO",
            Object.GuiLanguage,
            [NSNumber numberWithInt:Object.GuiFontSize],
            Object.TraceMode
             /**/
            
            ];
}

+ (NSString *) ResultErrorCodeDescription: (int) Object
{
    
    NSString * ObjectString = @"";
    
    switch(Object) {
        case ResultErrorNo:
            ObjectString = @"ResultErrorNo";
            break;
        case ResultErrorSystem:
            ObjectString = @"ResultErrorSystem";
            break;
        case ResultErrorSetupNotCompleted:
            ObjectString = @"ResultErrorSetupNotCompleted";
            break;
        case ResultErrorAuthFailed:
            ObjectString = @"ResultErrorAuthFailed";
            break;
    }
    
    
    return [NSString stringWithFormat:@"ResultError:%@;",ObjectString];
}

+ (NSString *) ContactModelDescription: (ObjC_ContactModel *) Object
{
    
    NSArray *Format = @[
                        @"Id: %d",
                        @"DodicallId: %@",
                        @"PhonebookId: %@",
                        @"NativeId: %@",
                        @"FirstName: %@",
                        @"LastName: %@",
                        @"MiddleName: %@",
                        @"Blocked: %@",
                        @"White: %@",
                        @"Iam: %@",
                        @"SubscriptionState: %@",
                        @"AskForSubscription: %@",
                        @"SubscriptionNew: %@",
                        @"Contacts: %@"
                        ];
    
    NSMutableArray * Contacts = [[NSMutableArray alloc] init];
    
    for(ObjC_ContactsContactModel *Contact in Object.Contacts)
    {
        
        NSString * TypeString = @"";
        
        switch(Contact.Type) {
            case ContactsContactSip:
                TypeString = @"ContactsContactSip";
                break;
            case ContactsContactXmpp:
                TypeString = @"ContactsContactXmpp";
                break;
            case ContactsContactPhone:
                TypeString = @"ContactsContactPhone";
                break;
        }
        
        
        [Contacts addObject:[NSString stringWithFormat:@"Type:%@; Identity:%@; Favourite:%@; Manual:%@;", TypeString, Contact.Identity, [Contact.Favourite boolValue] ? @"YES" : @"NO", [Contact.Manual boolValue] ? @"YES" : @"NO"]];
        
    }
    
    
    
    NSString *FormatString = [Format componentsJoinedByString:@";\n "];
    
    NSString *ContactsString = [Contacts componentsJoinedByString:@";\n "];
    
    NSString *SubscriptionState = @"";
    
    switch(Object.subscription.SubscriptionState) {
        case ContactSubscriptionStateNone:
            SubscriptionState = @"ContactSubscriptionStateNone";
            break;
        case ContactSubscriptionStateFrom:
            SubscriptionState = @"ContactSubscriptionStateFrom";
            break;
        case ContactSubscriptionStateTo:
            SubscriptionState = @"ContactSubscriptionStateTo";
            break;
        case ContactSubscriptionStateBoth:
            SubscriptionState = @"ContactSubscriptionStateBoth";
            break;
    }
    
    return [NSString stringWithFormat:FormatString,
            Object.Id,
            Object.DodicallId,
            Object.PhonebookId,
            Object.NativeId,
            Object.FirstName,
            Object.LastName,
            Object.MiddleName,
            [Object.Blocked boolValue] ? @"YES" : @"NO",
            [Object.White boolValue] ? @"YES" : @"NO",
            [Object.Iam boolValue] ? @"YES" : @"NO",
            SubscriptionState,
            [Object.subscription.AskForSubscription boolValue] ? @"YES" : @"NO",
            Object.subscription.SubscriptionStatus == ContactSubscriptionStatusNew ? @"YES" : @"NO",
            ContactsString
            ];
}

+ (NSString *) ContactSubscriptionDescription: (ObjC_ContactSubscription *) Object
{
    
    NSArray *Format = @[
                        @"SubscriptionState: %@",
                        @"AskForSubscription: %@",
                        @"SubscriptionStatus: %@"
                        ];
    
    
    NSString *SubscriptionState = @"";
    
    switch(Object.SubscriptionState) {
        case ContactSubscriptionStateNone:
            SubscriptionState = @"ContactSubscriptionStateNone";
            break;
        case ContactSubscriptionStateFrom:
            SubscriptionState = @"ContactSubscriptionStateFrom";
            break;
        case ContactSubscriptionStateTo:
            SubscriptionState = @"ContactSubscriptionStateTo";
            break;
        case ContactSubscriptionStateBoth:
            SubscriptionState = @"ContactSubscriptionStateBoth";
            break;
    }
    
    NSString *SubscriptionStatus = @"";
    
    switch(Object.SubscriptionStatus) {
        case ContactSubscriptionStatusConfirmed:
            SubscriptionStatus = @"ContactSubscriptionStatusConfirmed";
            break;
        case ContactSubscriptionStatusNew:
            SubscriptionStatus = @"ContactSubscriptionStatusNew";
            break;
        case ContactSubscriptionStatusReaded:
            SubscriptionStatus = @"ContactSubscriptionStatusReaded";
            break;
    }
    
    NSString *FormatString = [Format componentsJoinedByString:@";\n "];
    
    return [NSString stringWithFormat:FormatString,
            SubscriptionState,
            [Object.AskForSubscription boolValue] ? @"YES" : @"NO",
            SubscriptionStatus
            ];
}

+ (NSString *) ChatModelDescription: (ObjC_ChatModel *) Object
{
    NSArray *Format = @[
                        @"Id: %@",
                        @"CustomTitle: %@",
                        @"Title: %@",
                        @"LastModifiedDate: %@",
                        @"Active: %@",
                        @"LastMessage: %@",
                        @"Contacts count: %lu"
                        ];
    
    NSDateFormatter *DateFormatter = [[NSDateFormatter alloc] init];
    
    [DateFormatter setDateFormat:@"dd/MM/yy HH:mm"];
    
    NSString *FormatString = [Format componentsJoinedByString:@";\n "];

    return [NSString stringWithFormat:FormatString,
            Object.Id,
            Object.Title,
            [ChatsManager GetTitleOfChat:Object],
            [DateFormatter stringFromDate:Object.LastModifiedDate],
            [Object.Active boolValue] ? @"YES" : @"NO",
            [ChatsManager MessageToText:Object.lastMessage],
            [Object.Contacts count]
            ];
}

+ (SystemNotificationModel *) TransformRemoteNotificationToSystemNotificationModel: (NSDictionary *) RemoteNotification
{
    SystemNotificationModel *SystemNotification = [[SystemNotificationModel alloc] init];
    
    [SystemNotification setSystemType:SystemNotificationModelSystemTypeRemote];
    
    if([RemoteNotification objectForKey:@"aps"])
    {
        NSDictionary *Aps = [RemoteNotification objectForKey:@"aps"];
        
        if([Aps objectForKey:SystemNotificationModelCategoryKey])
        {
            [SystemNotification setCategoty:[Aps objectForKey:SystemNotificationModelCategoryKey]];
        }
    }
    
    if([RemoteNotification objectForKey:@"UIUserNotificationActionResponseTypedTextKey"])
    {
        [SystemNotification setUserResponse:[RemoteNotification objectForKey:@"UIUserNotificationActionResponseTypedTextKey"]];
    }
    
    if([RemoteNotification objectForKey:SystemNotificationModelMetaUserActionKey])
    {
        [SystemNotification setUserActionKey:[RemoteNotification objectForKey:SystemNotificationModelMetaUserActionKey]];
    }
    
    if([RemoteNotification objectForKey:SystemNotificationModelMeta])
    {
        NSString * MetaJsonString = [RemoteNotification objectForKey:SystemNotificationModelMeta];
        
        NSError *jsonError;
        NSData *MetaJsonData = [MetaJsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *MetaJson = [NSJSONSerialization JSONObjectWithData:MetaJsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        
        if(!jsonError && MetaJsonData)
        {
            if([MetaJson objectForKey:SystemNotificationModelMetaTjid])
            {
                [SystemNotification setUserDestinationId:[[MetaJson objectForKey:SystemNotificationModelMetaTjid] copy]];
            }
            
            if([MetaJson objectForKey:SystemNotificationModelMetaUserDestination])
            {
                [SystemNotification setUserDestinationId:[[MetaJson objectForKey:SystemNotificationModelMetaUserDestination] copy]];
            }
            
            if([MetaJson objectForKey:SystemNotificationModelMetaType])
            {
                if([[MetaJson objectForKey:SystemNotificationModelMetaType] isEqualToString:SystemNotificationModelMetaTypeXmpp])
                    [SystemNotification setUserType:SystemNotificationModelUserTypeXmpp];
                
                if([[MetaJson objectForKey:SystemNotificationModelMetaType] isEqualToString:SystemNotificationModelMetaTypeXmppInviteToChat])
                    [SystemNotification setUserType:SystemNotificationModelUserTypeXmppInviteToChat];
                
                if([[MetaJson objectForKey:SystemNotificationModelMetaType] isEqualToString:SystemNotificationModelMetaTypeXmppInviteContact])
                {
                    [SystemNotification setUserType:SystemNotificationModelUserTypeXmppInviteContact];
                    
                    if([MetaJson objectForKey:SystemNotificationModelMetaFrom])
                    {
                        [SystemNotification setUserDestinationId:[[MetaJson objectForKey:SystemNotificationModelMetaFrom] copy]];
                    }
                }
                
                if([[MetaJson objectForKey:SystemNotificationModelMetaType] isEqualToString:SystemNotificationModelMetaTypeSip])
                {
                    [SystemNotification setUserType:SystemNotificationModelUserTypeSip];
                    
                    if([MetaJson objectForKey:SystemNotificationModelMetaFrom])
                    {
                        [SystemNotification setUserDestinationId:[[MetaJson objectForKey:SystemNotificationModelMetaFrom] copy]];
                    }
                    
                }
                
                if([[MetaJson objectForKey:SystemNotificationModelMetaType] isEqualToString:SystemNotificationModelMetaTypeSipMissedIncomingCall])
                {
                    [SystemNotification setUserType:SystemNotificationModelUserTypeSipMissedIncomingCall];
                    
                    if([MetaJson objectForKey:SystemNotificationModelMetaFrom])
                    {
                        [SystemNotification setUserDestinationId:[[MetaJson objectForKey:SystemNotificationModelMetaFrom] copy]];
                    }
                    
                }
            }
        }
    }
    
    
    
    return  SystemNotification;
}

+ (SystemNotificationModel *) TransformLocalNotificationToSystemNotificationModel: (UILocalNotification *) LocalNotification
{
    SystemNotificationModel *SystemNotification = [[SystemNotificationModel alloc] init];
    
    [SystemNotification setSystemType:SystemNotificationModelSystemTypeLocal];
    
    [SystemNotification setCategoty:[LocalNotification.category copy]];
    
    if([LocalNotification.userInfo objectForKey:@"UIUserNotificationActionResponseTypedTextKey"])
    {
        [SystemNotification setUserResponse:[LocalNotification.userInfo objectForKey:@"UIUserNotificationActionResponseTypedTextKey"]];
    }
    
    if([LocalNotification.userInfo objectForKey:SystemNotificationModelMetaUserActionKey])
    {
        [SystemNotification setUserActionKey:[LocalNotification.userInfo objectForKey:SystemNotificationModelMetaUserActionKey]];
    }
    
    if([LocalNotification.userInfo objectForKey:SystemNotificationModelMeta])
    {
        NSDictionary *MetaJson = [LocalNotification.userInfo objectForKey:SystemNotificationModelMeta];
        
        if(MetaJson)
        {
            if([MetaJson objectForKey:SystemNotificationModelMetaTjid])
            {
                [SystemNotification setUserDestinationId:[[MetaJson objectForKey:SystemNotificationModelMetaTjid] copy]];
            }
            
            if([MetaJson objectForKey:SystemNotificationModelMetaUserDestination])
            {
                [SystemNotification setUserDestinationId:[[MetaJson objectForKey:SystemNotificationModelMetaUserDestination] copy]];
            }
            
            if([MetaJson objectForKey:SystemNotificationModelMetaType])
            {
                if([[MetaJson objectForKey:SystemNotificationModelMetaType] isEqualToString:SystemNotificationModelMetaTypeXmpp])
                    [SystemNotification setUserType:SystemNotificationModelUserTypeXmpp];
                
                if([[MetaJson objectForKey:SystemNotificationModelMetaType] isEqualToString:SystemNotificationModelMetaTypeSip])
                    [SystemNotification setUserType:SystemNotificationModelUserTypeSip];
            }
        }
    }
    
    return  SystemNotification;
}

+ (NSString *) SystemNotificationModelDescription: (SystemNotificationModel *) Object
{
    NSArray *Format = @[
                        @"SystemType: %@",
                        @"UserType: %@",
                        @"UserDestinationId: %@",
                        @"Category: %@",
                        @"UserResponse: %@"
                        ];
    
    
    NSString * SystemTypeString = @"";
    
    switch(Object.SystemType) {
        case SystemNotificationModelSystemTypeLocal:
            SystemTypeString = @"SystemNotificationModelSystemTypeLocal";
            break;
            
        case SystemNotificationModelSystemTypeRemote:
            SystemTypeString = @"SystemNotificationModelSystemTypeRemote";
            break;
    }
    
    NSString * UserTypeTypeString = @"";
    
    switch(Object.UserType) {
        case SystemNotificationModelUserTypeSip:
            UserTypeTypeString = @"SystemNotificationModelUserTypeSip";
            break;
            
        case SystemNotificationModelUserTypeXmpp:
            UserTypeTypeString = @"SystemNotificationModelUserTypeXmpp";
            break;
    }
    
    NSString *FormatString = [Format componentsJoinedByString:@";\n "];
    
    return [NSString stringWithFormat:FormatString,
            SystemTypeString,
            UserTypeTypeString,
            Object.UserDestinationId,
            Object.Categoty ? Object.Categoty : @"",
            Object.UserResponse ? Object.UserResponse : @""
            ];
}

+ (NSString *) FormatContactIdentity: (NSString *) ContactIdentity
{
    return [NSString stringWithString:[[AppManager app].Core FormatPhone:ContactIdentity]];
    //return [NSString stringWithString:ContactIdentity];
}

@end
