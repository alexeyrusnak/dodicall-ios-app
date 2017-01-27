//
//  UiChatTitleSettingsViewModel.m
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

#import "UiChatTitleSettingsViewModel.h"
#import "UiChatsTabNavRouter.h"
#import "ContactsManager.h"

@implementation UiChatTitleSettingsViewModel

-(instancetype)init {
    if(self = [super init]) {
        self.TitleChanged = @(YES);
        [self BindAll];
    }
    
    return self;
}

- (void) BindAll {
    
    @weakify(self);
    [[[[RACObserve(self, ChatModel)
        ignore:nil]
        map:^id(ObjC_ChatModel *Chat) {
            NSString *defaultTitle=@"";
            
            for(int i=0;i<Chat.Contacts.count;i++) {
                ObjC_ContactModel *contact = Chat.Contacts[i];
                if(![contact.Iam boolValue]) {
                    NSString *contactName = [ContactsManager GetContactTitle:Chat.Contacts[i]];
                    
                    if(i>0)
                        defaultTitle = [defaultTitle stringByAppendingString:@", "];
                    defaultTitle = [defaultTitle stringByAppendingString:contactName];
                }
            }
            
            NSString *currentTitle = [ChatsManager GetTitleOfChat:Chat];
            return RACTuplePack(defaultTitle, currentTitle);
        }] deliverOn:[ChatsManager Manager].ViewModelScheduler]
        subscribeNext:^(RACTuple *Tuple) {
            RACTupleUnpack(NSString *defaultTitle, NSString *currentTitle) = Tuple;

            @strongify(self);
            self.OldTitle = currentTitle;
            self.HasCustomTitle = @(![currentTitle isEqualToString:defaultTitle] && ![currentTitle isEqualToString:NSLocalizedString(@"Title_ChatHasNoName", nil)] && ![currentTitle isEqualToString:NSLocalizedString(@"Title_ChatHasNoUsers", nil)]);
        }];
    
    
    [[[RACObserve(self, HasCustomTitle)
        combineLatestWith:RACObserve(self, NewTitle)] deliverOn:[ChatsManager Manager].ViewModelScheduler]
        subscribeNext:^(RACTuple *Tuple) {
            RACTupleUnpack(NSNumber *HasCustomTitle, NSString *Title) = Tuple;
            
            @strongify(self);
            
            if([Title isEqualToString:self.OldTitle])
                self.TitleChanged = @(NO);
            else {
                if((Title.length == 0) && ![HasCustomTitle boolValue])
                    self.TitleChanged = @(NO);
                else
                    self.TitleChanged = @(YES);
            }
            
            self.TitleIsEmpty = @(!(Title.length > 0));
        }];
    
    [[[ChatsManager Chats].ChatUpdateSignal deliverOn:[ChatsManager Manager].ViewModelScheduler] subscribeNext:^(ChatUpdateSignalObject *Signal) {
        
        @strongify(self);
        
        if([Signal.ChatId isEqualToString:self.ChatModel.Id]) {
            
            if(Signal.State == ChatsMessagesUpdatingStateListLoadingFinishedSuccess || Signal.State == ChatsUpdatingStateUpdated) {
                ObjC_ChatModel *UpdatedChat = [[ChatsManager Chats] GetChatById:Signal.ChatId];
                if(UpdatedChat) {
                    self.ChatModel = [ChatsManager CopyChat:UpdatedChat];
                }
            }
            
            else if(Signal.State == ChatsUpdatingStateIdChanged) {
                
                ObjC_ChatModel *ChatData = [ChatsManager CopyChat:self.ChatModel];
                ChatData.Id = [Signal.NewChatId copy];
                self.ChatModel = ChatData;
                
            }
        }
            
    }];
    
    
}

- (void) UpdateChatTitle {
    [ChatsManager UpdateChat:self.ChatModel Title:self.NewTitle];
}

-(void)CloseView {
    [UiChatsTabNavRouter CloseChatTitleSettings];
}




@end
