//
//  UiChatMessageEditViewModel.m
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

#import "UiChatMessageEditViewModel.h"

@implementation UiChatMessageEditViewModel

-(instancetype)init
{
    if(self = [super init]) {
        self.MessageTextChanged = @NO;
        [self BindAll];
    }
    
    return self;
}

- (void) BindAll
{
    RAC(self, OldMessageText) = [[[RACObserve(self, ChatMessageModel) ignore:nil] take:1] map:^NSString *(ObjC_ChatMessageModel *ChatMessageModel)
    {
        return [ChatMessageModel.StringContent copy];
    }];
    
    @weakify(self);
    
    [RACObserve(self, NewMessageText) subscribeNext:^(NSString *Text) {
        
        @strongify(self);
        
        if(![Text isEqualToString:self.OldMessageText])
            self.MessageTextChanged = @YES;
        else
            self.MessageTextChanged = @NO;
        
        
        if(Text && Text.length)
            self.MessageTextIsEmpty = @NO;
        else
            self.MessageTextIsEmpty = @YES;
        
    }];
}

- (void) UpdateMessageText
{
    [[ChatsManager Chats] UpdateMessage:self.ChatMessageModel WithNewText:self.NewMessageText];
}

-(void)CloseView
{
    [UiChatsTabNavRouter CloseChatTitleSettings];
}

@end
