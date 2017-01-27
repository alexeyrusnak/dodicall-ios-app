//
//  UiChatViewModel.h
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

#import "UiChatViewMessagesCellModel.h"

#import "UiChatViewMessagesHeaderCellModel.h"

@class ObjC_ChatModel;

@interface UiChatViewModel : NSObject

//@property NSMutableArray *BindedDisposableRacArr;

@property (nonatomic/*, copy*/) ObjC_ChatModel *ChatData;

@property NSMutableArray *DisposableRacArr;

@property NSMutableArray *MessagesUpdateStages;

@property NSMutableArray *Messages;

@property NSMutableDictionary *Sections;

@property NSMutableArray *SectionsKeys;

@property NSMutableDictionary *ThreadSafeSections;

@property NSMutableArray *ThreadSafeSectionsKeys;

@property NSNumber *DataReloaded;

@property RACSignal *DataReloadedSignal;

@property RACSignal *ChatDataSignal;

@property NSString *HeaderLabelText;

@property NSString *HeaderDescrLabelText;

@property NSString *Status;

@property NSString *XmppId;

@property BOOL IsP2P;

@property BOOL IsEmptyChat;

//@property RACSignal *XmppStatusesSignal;

@property NSString *FooterInputText;

@property BOOL AutoScrollEnabled;

@property BOOL ChatIsReaded;

@property NSString *LastUnreadedMessageId;

@property BOOL IsActive;

@property NSTimer *SetChatReadedTimer;

@property BOOL MarkedAsDeletedAndShouldBeClosed;

@property NSNumber *EditModeEnabled;

@property NSNumber *SelectedCellsNumber;

@property NSMutableArray<ObjC_ChatMessageModel *> *SelectedMessages;

@property (strong, nonatomic) NSMutableArray *MenuRowModels;

@property (strong, nonatomic) RACCommand *ShowComingSoon;
@property (strong, nonatomic) RACCommand *ShowChatSettings;
@property (strong, nonatomic) RACCommand *ShowChatUsers;

//- (void) UnBindAll;

- (void) ReloadData;

- (void) SendTextMessage;

- (void) SetChatReaded;

- (void) EnableEditMode:(BOOL) Enabled;

- (void) SwitchEditMode;

- (BOOL) CanEditSelectCellWithModel:(UiChatViewMessagesCellModel *) RowItem;

- (void) SetSelected:(UiChatViewMessagesCellModel *) RowModel;

- (BOOL) SelectCell:(BOOL) Selected withMessagesCellModel:(UiChatViewMessagesCellModel *) RowItem;

- (void) DeleteSelectedMessages;

//- (void) PrepareToDestroy;

@end
