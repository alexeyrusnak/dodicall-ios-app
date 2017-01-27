//
//  UiChatsListRowItemViewModel.h
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

#define UiChatsListCellViewDescrLabelNuiClass @"UiChatsListCellViewDescrLabel"
#define UiChatsListCellViewDescrLabelReadedNuiClass @"UiChatsListCellViewDescrLabelReaded"

@class ObjC_ChatModel;
@class ObjC_ContactModel;

@interface UiChatsListRowItemViewModel : NSObject

@property ObjC_ChatModel *Chat;

@property NSString *Title;

@property NSString *DateTime;

@property NSString *AddInfo;

@property NSString *Description;

@property NSMutableAttributedString *AttributedDescription;

@property NSString *Count;

@property NSString *Status;

@property BOOL IsMultyUserChat;

@property BOOL IsEmptyChat;

@property NSNumber *IsSelected;

@property BOOL IsLastMessageReaded;

@property NSString *XmppId;

@property NSString *AvatarPath;

@property ObjC_ContactModel *P2PContact;

- (void) PrepareDescriptionAttributedString;

@end
