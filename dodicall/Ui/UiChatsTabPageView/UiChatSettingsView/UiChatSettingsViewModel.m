//
//  UiChatSettingsViewModel.m
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

#import "UiChatSettingsViewModel.h"
#import "UiChatSettingsCellModel.h"
#import "NSStringHelper.h"
#import "UiNavRouter.h"
#import "UiChatsTabNavRouter.h"
#import "ChatsManager.h"

@implementation UiChatSettingsViewModel

- (instancetype)init {
    
    if(self = [super init]) {
        self.RowsArray = [NSMutableArray new];
        [self BindAll];
    }
    
    return self;
}

- (void) BindAll {
    
    @weakify(self);
    
    self.ShowComingSoon = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteShowComingSoon];
    }];
    
    self.ShowUserSettings = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteShowUserSettings];
    }];
    
    self.ShowTitleSettings = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteShowTitleSettings];
    }];
    
    [[RACObserve(self, ChatData) deliverOn:[ChatsManager Manager].ViewModelScheduler] subscribeNext:^(ObjC_ChatModel *Chat) {
        
        self.IsChatActive = [Chat.Active copy];
        self.IsP2P = @([ChatsManager IsChatP2P:Chat]);
        
        NSMutableArray *newRows = [NSMutableArray new];
        
        UiChatSettingsCellModel *nameCell = [[UiChatSettingsCellModel alloc] initWithFieldName:NSLocalizedString(@"ChatSettings_Title", nil) andValue:[ChatsManager GetTitleOfChat:Chat]];
        nameCell.SelectCommand = self.ShowTitleSettings;
        nameCell.CellId = @"UiChatSettingsCell";
        
        UiChatSettingsCellModel *backgroundCell = [[UiChatSettingsCellModel alloc] initWithFieldName:NSLocalizedString(@"ChatSettings_Background", nil) andValue:NSLocalizedString(@"ChatSettings_BackgroundByDefault", nil)];
        backgroundCell.SelectCommand = self.ShowComingSoon;
        backgroundCell.CellId = @"UiChatSettingsCell";
        
        
        NSInteger contactsCount = 0;
        for(ObjC_ContactModel *Contact in Chat.Contacts) {
            if(![Contact.Iam boolValue])
                contactsCount++;
        }
        
        NSString *menString = [NSString new];
        if(contactsCount < 2) {
            menString = [NSString stringWithFormat:@"%lu %@", contactsCount, NSLocalizedString(@"ChatSettings_MenSingle", nil)];
        }
        else {
            if([NSStringHelper GetManEnding:contactsCount] == ManEndingPlural) {
                menString = [NSString stringWithFormat:@"%lu %@", contactsCount, NSLocalizedString(@"ChatSettings_MenPlural", nil)];
            }
            else
                menString = [NSString stringWithFormat:@"%lu %@", contactsCount, NSLocalizedString(@"ChatSettings_MenPluralComp", nil)];
        }

        
        UiChatSettingsCellModel *contactsCell = [[UiChatSettingsCellModel alloc] initWithFieldName:NSLocalizedString(@"ChatSettings_Participants", nil) andValue:menString];
        contactsCell.SelectCommand = self.ShowUserSettings;
        contactsCell.CellId = @"UiChatSettingsCell";
        
        UiChatSettingsCellModel *historyCell = [[UiChatSettingsCellModel alloc] initWithFieldName:NSLocalizedString(@"ChatSettings_History", nil) andValue:@""];
        historyCell.SelectCommand = nil;
        historyCell.CellId = @"UiChatSettingsCellSlider";
        
        if(![self.IsP2P boolValue]) {
            [newRows addObject:nameCell];
        }
        
        [newRows addObjectsFromArray:@[backgroundCell, contactsCell, historyCell]];
        
        @strongify(self);
        self.RowsArray = newRows;
        self.ChatTitle = Chat.Title;
    }];
    
    
    [[[ChatsManager Chats].ChatUpdateSignal deliverOn:[ChatsManager Manager].ViewModelScheduler] subscribeNext:^(ChatUpdateSignalObject *Signal) {
        
        @strongify(self);
        
        if([Signal.ChatId isEqualToString:self.ChatData.Id ] && (Signal.State == ChatsMessagesUpdatingStateListLoadingFinishedSuccess || Signal.State == ChatsUpdatingStateUpdated)) {
            
            ObjC_ChatModel *UpdatedChat = [[ChatsManager Chats] GetChatById:Signal.ChatId];
            if(UpdatedChat) {
                self.ChatData = [ChatsManager CopyChat:UpdatedChat];
            }
        }
        
        if([Signal.ChatId isEqualToString:self.ChatData.Id] && (Signal.State == ChatsUpdatingStateIdChanged)) {
            
            ObjC_ChatModel *ChatData = [ChatsManager CopyChat:self.ChatData];
            ChatData.Id = [Signal.NewChatId copy];
            self.ChatData = ChatData;
            
        }
        
    }];

}
- (RACSignal *)ExecuteShowComingSoon {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [UiNavRouter ShowComingSoon];
        
        
        [subscriber sendCompleted];
        return [RACDisposable new];
    }];
}

- (RACSignal *)ExecuteShowUserSettings {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        @strongify(self);
        [UiChatsTabNavRouter ShowChatUserSettingsForChat:self.ChatData];
        
        [subscriber sendCompleted];
        return [RACDisposable new];
    }];
}

- (RACSignal *)ExecuteShowTitleSettings {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        @strongify(self);
        [UiChatsTabNavRouter ShowChatTitleSettingsForChat:self.ChatData];
        
        [subscriber sendCompleted];
        return [RACDisposable new];
    }];
}


@end
