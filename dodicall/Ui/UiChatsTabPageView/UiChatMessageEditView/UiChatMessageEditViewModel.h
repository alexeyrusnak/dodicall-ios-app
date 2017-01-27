//
//  UiChatMessageEditViewModel.h
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

#import "ObjC_ChatMessageModel.h"
#import "ChatsManager.h"

@interface UiChatMessageEditViewModel : NSObject

@property (strong, nonatomic) ObjC_ChatMessageModel *ChatMessageModel;

@property (strong, nonatomic) NSString *OldMessageText;
@property (strong, nonatomic) NSString *NewMessageText;

@property (strong, nonatomic) NSNumber *MessageTextChanged;
@property (strong, nonatomic) NSNumber *MessageTextIsEmpty;

- (void) UpdateMessageText;
- (void) CloseView;

@end
