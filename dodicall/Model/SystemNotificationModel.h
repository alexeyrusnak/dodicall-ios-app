//
//  SystemNotificationModel.h
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define SystemNotificationModelMeta                             @"m"
#define SystemNotificationModelMetaTjid                         @"j"
#define SystemNotificationModelMetaType                         @"t"
#define SystemNotificationModelMetaTypeXmpp                     @"x"
#define SystemNotificationModelMetaTypeXmppInviteToChat         @"xichat"
#define SystemNotificationModelMetaTypeXmppInviteContact        @"xicontact"
#define SystemNotificationModelMetaTypeSip                      @"s"
#define SystemNotificationModelMetaTypeSipIncomingCall          @"sic"
#define SystemNotificationModelMetaTypeSipMissedIncomingCall    @"smc"
#define SystemNotificationModelMetaFrom                         @"f"
#define SystemNotificationModelMetaUserDestination              @"ud"
#define SystemNotificationModelMetaUserActionKey                @"ak"

#define SystemNotificationModelSoundXmpp                        @"m.m4r"
#define SystemNotificationModelSoundSip                         @"c.m4r"

#define SystemNotificationModelActionXmpp                       @"L"
#define SystemNotificationModelActionXmppAnswer                 @"A"
#define SystemNotificationModelActionXmppOpen                   @"O"
#define SystemNotificationModelActionXmppAccept                 @"ACCEPT"
#define SystemNotificationModelActionSip                        @"L"
#define SystemNotificationModelActionSipAnswer                  @"A"
#define SystemNotificationModelActionSipCancel                  @"C"
#define SystemNotificationModelActionSipOpen                    @"O"
#define SystemNotificationModelActionSipCall                    @"CALL"

#define SystemNotificationModelCategoryKey                      @"category"
#define SystemNotificationModelXmppMessageCategory              @"XMC"
#define SystemNotificationModelXmppMessageCategoryLookAction    @"XMC_LA"
#define SystemNotificationModelXmppMessageCategoryAnswerAction  @"XMC_AA"
#define SystemNotificationModelXmppMessageNoAnswerCategory      @"XMNAC"
#define SystemNotificationModelXmppMessageMucInviteCategory     @"XMMIC"

#define SystemNotificationModelIncomingCallCategory                 @"ICC"
#define SystemNotificationModelIncomingCallCategoryCancelAction     @"ICC_CA"
#define SystemNotificationModelIncomingCallCategoryAnswerAction     @"ICC_AA"

#define SystemNotificationModelPushIncomingCallCategory                 @"PICC"
#define SystemNotificationModelPushIncomingCallCategoryCancelAction     @"PICC_CA"
#define SystemNotificationModelPushIncomingCallCategoryAnswerAction     @"PICC_AA"

#define SystemNotificationModelPushMissedIncomingCallCategory               @"PMICC"
#define SystemNotificationModelPushMissedIncomingCallCategoryLookAction     @"PMICC_LA"
#define SystemNotificationModelPushMissedIncomingCallCategoryCallAction     @"PMICC_CA"

#define SystemNotificationModelXmppMessageContactInviteCategory                 @"XMCIC"
#define SystemNotificationModelXmppMessageContactInviteCategoryLookAction       @"XMCIC_LA"
#define SystemNotificationModelXmppMessageContactInviteCategoryAcceptAction     @"XMCIC_AA"


typedef NS_ENUM(NSInteger, SystemNotificationModelSystemType)
{
    SystemNotificationModelSystemTypeLocal,
    SystemNotificationModelSystemTypeRemote
};

typedef NS_ENUM(NSInteger, SystemNotificationModelUserType)
{
    SystemNotificationModelUserTypeSip,
    SystemNotificationModelUserTypeSipMissedIncomingCall,
    SystemNotificationModelUserTypeXmpp,
    SystemNotificationModelUserTypeXmppInviteToChat,
    SystemNotificationModelUserTypeXmppInviteContact
};

@interface SystemNotificationModel : NSObject

@property SystemNotificationModelSystemType SystemType;

@property SystemNotificationModelUserType UserType;

@property NSString *UserDestinationId;

@property NSString *Title;

@property NSString *Body;

@property NSString *FormatedTitleBodyString;

@property NSString *Action;

@property NSString *UserActionKey;

@property BOOL HasAction;

@property NSString *Sound;

@property NSDictionary *Meta;

@property NSInteger Id;

@property NSString *Categoty;

@property NSString *UserResponse;

@property UILocalNotification *LocalNotification;

@property (nonatomic, copy) void (^CompletionHandler)(void);

@end
