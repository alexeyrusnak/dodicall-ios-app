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
//  ObjC_ContactSubscription.h
//  DodicallBridgeIos
//


#ifndef ObjC_ContactSubscription_h
#define ObjC_ContactSubscription_h

#import <Foundation/Foundation.h>

typedef enum  {
    ContactSubscriptionStateNone = 0,
    ContactSubscriptionStateFrom,
    ContactSubscriptionStateTo,
    ContactSubscriptionStateBoth
} ContactSubscriptionState;


typedef enum  {
    ContactSubscriptionStatusNew = 0,
    ContactSubscriptionStatusReaded,
    ContactSubscriptionStatusConfirmed
} ContactSubscriptionStatus;

@interface ObjC_ContactSubscription: NSObject {
};

   // @property  NSString *ContactXmppId;
    @property  ContactSubscriptionState SubscriptionState;
    @property  NSNumber* AskForSubscription;
    @property  ContactSubscriptionStatus SubscriptionStatus;

@end

#endif /* ObjC_ContactSubscription_h */
