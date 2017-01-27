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
//  ObjC_ChatModel.h
//  DodicallBridgeIos
//


#ifndef ObjC_ChatModel_h
#define ObjC_ChatModel_h

#import <Foundation/Foundation.h>
#include "ObjC_ChatMessageModel.h"


typedef NSString *ChatIdType;

typedef NSMutableArray *ChatContactIdentitySet;

@interface ObjC_ChatModel: NSObject {
};


    @property ChatIdType Id;
    @property NSString *Title;
    @property NSDate *LastModifiedDate;
    @property NSNumber *Active;

    @property NSMutableArray *Contacts;

    @property ObjC_ChatMessageModel *lastMessage;

    @property NSNumber *IsP2p;

    // Statistics
    @property int TotalMessagesCount;
    @property int NewMessagesCount;

@end

#endif /* ObjC_ChatModel_h */
