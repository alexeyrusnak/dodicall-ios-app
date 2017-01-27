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
//  ObjC_ContactModel.h
//
//

#import <Foundation/Foundation.h>


typedef long ContactIdType;
typedef NSString *ContactDodicallIdType;
typedef NSString *PhonebookIdType;

@class ObjC_ContactSubscription;

typedef enum {
    ContactsContactSip = 1,
    ContactsContactXmpp,
    ContactsContactPhone
} ContactsContactType;

@interface ObjC_ContactsContactModel: NSObject {

};

    @property ContactsContactType Type;
    @property NSString *Identity;
    @property NSNumber *Favourite;
    @property NSNumber *Manual;

@end


typedef NSMutableArray *ContactsContactList;

@interface ObjC_ContactModel : NSObject  {
    
};


    @property ContactIdType Id;
    @property ContactDodicallIdType DodicallId;
    @property PhonebookIdType PhonebookId;
    @property NSString *NativeId;
    @property NSString *EnterpriseId;

    @property NSString *FirstName;
    @property NSString *LastName;
    @property NSString *MiddleName;

    @property NSNumber *Blocked;
    @property NSNumber *White;

    @property NSNumber *Deleted;

    @property NSNumber *Iam;

    @property NSString *AvatarPath;

    @property ObjC_ContactSubscription *subscription;

    @property ContactsContactList Contacts;

@end



typedef NSMutableArray *ContactModelList;


