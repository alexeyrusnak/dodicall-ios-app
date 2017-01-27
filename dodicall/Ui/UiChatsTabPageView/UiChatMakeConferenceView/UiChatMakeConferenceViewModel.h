//
//  UiChatMakeConferenceViewModel.h
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

#import "UiChatsTabNavRouter.h"

#import "UiChatMakeConferenceUsersRowViewModel.h"

@interface UiChatMakeConferenceViewModel : NSObject

@property (strong, nonatomic) ObjC_ChatModel *ChatData;

@property (strong, nonatomic) NSMutableArray <UiChatMakeConferenceUsersRowViewModel *> *ThreadSafeChatUsersRows;

@property (strong, nonatomic) NSMutableArray *DataReloadStages;

@property (strong, nonatomic) NSString *Title;

@property (strong, nonatomic) NSNumber *IsActive;

@property (strong, nonatomic) NSNumber *DataReloaded;

@property NSMutableArray<ObjC_ContactModel *> *SelectedContacts;

@property NSMutableArray<ObjC_ContactModel *> *DisabledContacts;

@property NSNumber *SelectedContactsCount;

- (void) StartConference;

- (void) RevertSelected:(UiChatMakeConferenceUsersRowViewModel *) RowModel;

@end
