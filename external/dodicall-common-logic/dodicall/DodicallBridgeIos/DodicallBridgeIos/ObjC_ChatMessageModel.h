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
//  ObjC_ChatMessageModel.h
//  DodicallBridgeIos
//


#ifndef ObjC_ChatMessageModel_h
#define ObjC_ChatMessageModel_h

#import <Foundation/Foundation.h>
#import "ObjC_ContactModel.h"

typedef NSMutableArray *ChatContactIdentitySet;

typedef enum {
    ChatNotificationTypeCreate,
    ChatNotificationTypeInvite,
    ChatNotificationTypeRevoke,
    ChatNotificationTypeLeave,
    ChatNotificationTypeRemove
} ChatNotificationType;

@interface ObjC_ChatNotificationData: NSObject {
};

    @property ChatNotificationType Type;
    @property NSMutableArray *Contacts;

@end

@interface ObjC_ChatMessageModel: NSObject {
};

typedef enum  {
    ChatMessageTypeTextMessage,
    ChatMessageTypeAudioMessage,
    ChatMessageTypeNotification,
    ChatMessageTypeContact,
    ChatMessageTypeDeleter,
    ChatMessageTypeSubject
} ChatMessageType;

    @property NSString *Id;
    @property NSString *chatId;
    @property ObjC_ContactModel *Sender;
    @property NSNumber *Servered;
    @property NSDate *SendTime;
    @property NSNumber *Readed;
    @property ChatMessageType Type;
    @property NSString *StringContent;
    @property NSNumber *Rownum;
    @property NSNumber *Changed;
    @property NSNumber *Encrypted;

    @property ObjC_ContactModel *ContactData;
    @property ObjC_ChatNotificationData *NotificationData;

@end



#endif /* Header_h */
