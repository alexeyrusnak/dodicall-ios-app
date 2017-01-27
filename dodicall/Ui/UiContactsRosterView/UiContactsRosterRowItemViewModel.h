//
//  UiContactsRosterRowItemViewModel.h
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

#import "UiContactsSkeleton.h"


#define UiContactsRosterRequestTypeInvite   @"UiContactsRosterRequestTypeInvite"
#define UiContactsRosterRequestTypeRequest  @"UiContactsRosterRequestTypeRequest"
typedef NSString*               			UiContactsRosterRequestType;


@class ObjC_ContactModel;

@interface UiContactsRosterRowItemViewModel : NSObject

// TODO: relize copy protocol
@property (nonatomic/*, copy*/) ObjC_ContactModel *ContactData;

@property NSString *Title;
@property NSString *Description;
@property NSString *Status;
@property NSString *AvatarPath;

@property BOOL IsNew;

@property UiContactsRosterRequestType RequestType;

@property NSString *XmppId;

@end
