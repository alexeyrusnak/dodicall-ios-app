//
//  UiChatUsersSelectViewModel.h
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
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiContactsListModel.h"


@class ObjC_ChatModel;

@interface UiChatUsersSelectViewModel : NSObject

@property (nonatomic) ObjC_ChatModel *ChatData;

@property (weak, nonatomic) IBOutlet UiContactsListModel *ContactsListModel;

@property (strong, nonatomic) RACCommand *DoneAction;

@property (strong, nonatomic) RACCommand *BackAction;

@property BOOL IsValid;

@property (strong, nonatomic) NSNumber *IsNewChat;
@property (strong, nonatomic) NSNumber *IsActive;
@property (strong, nonatomic) NSString *ChatTitle;

- (void) Setup;


@end
