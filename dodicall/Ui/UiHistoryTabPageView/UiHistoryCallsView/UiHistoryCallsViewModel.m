//
//  UiHistoryCallsViewModel.m
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

#import "UiHistoryCallsViewModel.h"
#import "ObjC_ContactModel.h"
#import "ObjC_HistoryCallModel.h"

#import "ContactsManager.h"
#import "UiHistoryCallsCallCellModel.h"

#import "CallsManager.h"
#import "ChatsManager.h"

#import "HistoryManager.h"

#import "UiLogger.h"

@interface UiHistoryCallsViewModel()

@property (strong, nonatomic) NSMutableArray *CallsArray;

@end

@implementation UiHistoryCallsViewModel

- (instancetype)init {
    if(self = [super init]) {
        
        self.ThreadSafeCallsRowsArray = [NSMutableArray new];
        self.CallsDataUpdateStages = [NSMutableArray new];
        self.CallsArray = [NSMutableArray new];
        
        [self BindAll];
    }
    return self;
}
- (void)BindAll {
    
    
    @weakify(self);
    self.ShowComingSoonCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteShowComingSoonCommand];
    }];
    
    self.CallCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteCallCommandWithHistoryObject:self.StatisticsModel];
    }];
    
    self.MessageCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteMessageCommandWithHistoryObject:self.StatisticsModel];
    }];
    
    [[RACObserve(self, StatisticsModel) ignore:nil] subscribeNext:^(id x) {
        @strongify(self);
        [self UpdateContactModel];
        [self UpdateRows];
        
    }];
    
    [[[HistoryManager Manager].HistoryStatisticsUpdatingSignal deliverOn:[HistoryManager Manager].ViewModelScheduler]subscribeNext:^(HistoryStatisticsUpdatingSignalObject *Signal) {
        
        @strongify(self);
        
        if([Signal.Id isEqualToString:self.StatisticsModel.Id ] && Signal.State == HistoryStatisticsUpdatingStateStateUpdated)
        {
            [self setStatisticsModel:[[HistoryManager Manager] GetHistoryStatisticsById:[Signal.Id copy]]];
        }
    }];
    
    [[[HistoryManager Manager].HistoryStatisticsListUpdatingStateSignal deliverOn:[HistoryManager Manager].ViewModelScheduler]subscribeNext:^(id x) {
        if([(NSNumber *)x integerValue] == HistoryStatisticsListUpdatingReady || [(NSNumber *)x integerValue] == HistoryStatisticsListUpdatingStateUpdated) {
            
            @strongify(self);
            
            if(self.StatisticsModel)
                [self setStatisticsModel:[[HistoryManager Manager] GetHistoryStatisticsById:[self.StatisticsModel.Id copy]]];
            
        }
    }];
    
    [[ContactsManager Contacts].XmppStatusesSignal subscribeNext:^(NSMutableArray *StatusesArr) {
        
        
        @strongify(self);
        
        for(NSString *XmppId in StatusesArr) {
            if([XmppId isEqualToString:self.ContactCellModel.XmppId])
                [self SetStatusToModel:self.ContactCellModel];
        }
        
    }];

}
- (void) UpdateContactModel {
    
    UiHistoryCallsContactCellModel *contactCell = [UiHistoryCallsContactCellModel new];
    
    contactCell.Contact = self.self.StatisticsModel.Contacts[0];
    contactCell.CellId = [self GetCellIdForContact];
    contactCell.Title = [self GetContactTitle];
    contactCell.IsDodicall = self.StatisticsModel.Contacts[0].DodicallId.length>0? @(YES):@(NO);
    
    if(contactCell.IsDodicall) {
        [contactCell setXmppId:[ContactsManager GetXmppIdOfContact:self.StatisticsModel.Contacts[0]]];
        
        if(contactCell.XmppId) {
            [self SetStatusToModel:contactCell];
        }
    }
    
    @weakify(contactCell);
    RAC(contactCell, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:self.StatisticsModel.Contacts[0]] WithDoNextBlock:^(NSString *Path) {
        @strongify(contactCell);
        contactCell.AvatarPath = Path;
    }];
    
    self.ContactCellModel = contactCell;
}

- (void)UpdateRows {
    
    NSMutableArray *newRows = [NSMutableArray new];

    self.CallsArray = [[HistoryManager Manager] GetHistoryStatisticsCallsById:self.StatisticsModel.Id];
    
    for (ObjC_HistoryCallModel *callModel in self.CallsArray) {
        UiHistoryCallsCallCellModel *cellModel = [UiHistoryCallsCallCellModel new];
        
        cellModel.CellId = [self GetCellIdForCall:callModel];
        cellModel.Title = [self GetCallTitle:callModel];
        cellModel.Encrypted = callModel.Encryption? @(YES):@(NO);
        cellModel.Duration = [self GetCallDuration:callModel];
        cellModel.Date = [self GetCallDate:callModel];
        cellModel.ArrowColor = callModel.Status == CallHistoryStatusSuccess? @"Green" : @"Red";
        
        [newRows addObject:cellModel];
    }
    
    [self.CallsDataUpdateStages addObject:newRows];
    self.CallsRowsUpdated = @(YES);
}

- (NSString *)GetCellIdForContact {
    NSString *cellId = @"";
    
    ObjC_ContactModel *contact = self.StatisticsModel.Contacts[0];
    
    if(contact) {
        ContactProfileType contactType = [ContactsManager GetContactProfileType:contact];
        BOOL isContactRequest = [ContactsManager CheckContactIsRequest:contact];
        
        if(contactType == ContactProfileTypeDirectoryLocal) {
            if(isContactRequest) {
                if([contact.Blocked boolValue])
                    cellId = @"UiHistoryCallsCellNotAprovedBlocked";
                else
                    cellId = @"UiHistoryCallsCellNotAproved";
            }
            else {
                if([contact.Blocked boolValue])
                    cellId = @"UiHistoryCallsCellAprovedBlocked";
                else
                    cellId = @"UiHistoryCallsCellAproved";
            }
        }
        else if(contactType == ContactProfileTypeDirectoryRemote) {
            if([contact.Blocked boolValue])
                cellId = @"UiHistoryCallsCellNotAprovedBlocked";
            else
                cellId = @"UiHistoryCallsCellNotAproved";
        }
        else if(contactType == ContactProfileTypeLocal) {
            if([contact.Blocked boolValue])
                cellId = @"UiHistoryCallsCellExternalBlocked";
            else
                cellId = @"UiHistoryCallsCellExternal";
        }
        else if(contactType == ContactProfileTypePhonebook) {
            if([contact.Blocked boolValue])
                cellId = @"UiHistoryCallsCellExternalAddBlocked";
            else
                cellId = @"UiHistoryCallsCellExternalAdd";
        }
        
    }
    else
        cellId = @"UiHistoryCallsCellExternalAdd";
    
    
    
    return cellId;
}

- (NSString *)GetCellIdForCall:(ObjC_HistoryCallModel *)callModel {
    NSString *cellId = @"";
    
    
    if(callModel.Direction == CallDirectionIncoming)
        cellId = @"UiHistoryCallsCellIncoming";
    else
        cellId = @"UiHistoryCallsCellOutgoing";
    
    return cellId;
}

- (NSString *) GetContactTitle {
    
    
    ObjC_ContactModel *contact = self.StatisticsModel.Contacts[0];
    NSString *title = @"";
    
    if(contact) {
        /*
        if(contact.FirstName&&contact.FirstName.length)
            title = [title stringByAppendingString:contact.FirstName];
        
        if(contact.MiddleName&&contact.MiddleName.length) {
            title = [title stringByAppendingString:@" "];
            title = [title stringByAppendingString:contact.MiddleName];
        }
        if(contact.LastName&&contact.LastName.length) {
            title = [title stringByAppendingString:@" "];
            title = [title stringByAppendingString:contact.LastName];
        }
         */
        title = [ContactsManager GetContactTitle:contact];
    }
    else
    {
        title = [title stringByAppendingString:self.StatisticsModel.Identity];
        title = [title componentsSeparatedByString:@"@"][0];
    }
    
    
    
    
    return title;
}
- (NSString *) GetCallTitle:(ObjC_HistoryCallModel *)callModel {
    NSString *title = @"";
    
    if(callModel.Status == CallHistoryStatusSuccess) {
        if(callModel.Direction == CallDirectionOutgoing) {
            title = NSLocalizedString(@"CallHistory_Outgoing", nil);
        }
        else {
            title = NSLocalizedString(@"CallHistory_Incoming", nil);
        }
    }
    else if(callModel.Status == CallHistoryStatusAborted) {
        title = NSLocalizedString(@"CallHistory_Aborted", nil);
    }
    else if(callModel.Status == CallHistoryStatusMissed) {
        title = NSLocalizedString(@"CallHistory_Missed", nil);
    }
    else if(callModel.Status == CallHistoryStatusDeclined) {
        title = NSLocalizedString(@"CallHistory_Aborted", nil);
    }

    
    return title;
}

- (NSString *) GetCallDuration:(ObjC_HistoryCallModel *)callModel {
    NSString *durationString = @"";
    
    
    NSTimeInterval duration = [callModel.DurationInSecs integerValue];
    
    NSDateComponentsFormatter *timeFormatter = [NSDateComponentsFormatter new];
    
    durationString = [durationString stringByAppendingString:[timeFormatter stringFromTimeInterval:duration]];
    
    durationString = [durationString stringByAppendingString:@" "];
    
    if((NSInteger)duration/(60*60)) {
        durationString = [durationString stringByAppendingString:NSLocalizedString(@"CallHistory_Hours", nil)];
    }
    

    else {
        if((NSInteger)duration/(60))
            durationString = [durationString stringByAppendingString:NSLocalizedString(@"CallHistory_Minutes", nil)];
        else
            durationString = [durationString stringByAppendingString:NSLocalizedString(@"CallHistory_Seconds", nil)];
    }
    
    
    return durationString;
}

- (NSString *) GetCallDate:(ObjC_HistoryCallModel *)callModel {
    NSString *dateString = @"";
    
    if(callModel.Date) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.doesRelativeDateFormatting = YES;
        
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[AppManager app].UserSettingsModel.GuiLanguage]];
        
        dateString = [dateFormatter stringFromDate:callModel.Date];
        dateString = [dateString lowercaseString];
    }
    
    return dateString;
}


- (void) SetStatusToModel:(UiHistoryCallsContactCellModel *) RowModel {
    
    ObjC_ContactPresenceStatusModel *Status = [ContactsManager GetXmppStatusByXmppId:RowModel.XmppId];
    
    switch (Status.BaseStatus) {
            
            
        case BaseUserStatusOnline:
            [RowModel setStatus:@"ONLINE"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_ONLINE", nil)]];
            break;
            
        case BaseUserStatusDnd:
            [RowModel setStatus:@"DND"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_DND", nil)]];
            break;
            
        case BaseUserStatusAway:
            [RowModel setStatus:@"AWAY"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_AWAY", nil)]];
            break;
            
        case BaseUserStatusHidden:
            [RowModel setStatus:@"INVISIBLE"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_INVISIBLE", nil)]];
            break;
            
        default:
            [RowModel setStatus:@"OFFLINE"];
            [RowModel setDescription:[NSStringHelper CapitalaizeFirstLetter:NSLocalizedString(@"title_OFFLINE", nil)]];
            break;
    }
    
    if(Status.ExtStatus && Status.ExtStatus.length > 0) {
        [RowModel setDescription:[[RowModel.Description stringByAppendingString:@". "] stringByAppendingString:Status.ExtStatus]];
    }
    
}

- (RACSignal *)ExecuteCallCommandWithHistoryObject:(ObjC_HistoryStatisticsModel *)historyModel {
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        ObjC_ContactModel *contact = historyModel.Contacts[0];
        if(contact) {
            [CallsManager StartOutgoingCallToContact:contact WithCallback:^(BOOL Success) {
                [subscriber sendCompleted];
            }];
        }
        else
            [CallsManager StartOutgoingCallToNumber:historyModel.Identity WithCallback:^(BOOL Success) {
                [subscriber sendCompleted];
            }];
        
        
        return [RACDisposable new];
    }];
    
}

- (RACSignal *)ExecuteMessageCommandWithHistoryObject:(ObjC_HistoryStatisticsModel *)historyModel {
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        ObjC_ContactModel *contact = historyModel.Contacts[0];
        if(contact) {
//            [[ChatsManager Chats] GetOrCreateP2PChatWithContact:contact AndReturnItInCallback:^(ObjC_ChatModel *chatModel) {
//                [UiChatsTabNavRouter ShowChatView:chatModel];
//            }];
            
            [UiChatsTabNavRouter CreateAndShowChatViewWithContact:contact];
        }
        
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
    
}

- (RACSignal *)ExecuteShowComingSoonCommand {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [UiNavRouter ShowComingSoon];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}

- (void) SaveContactAndReturnInCallback: (void (^)(BOOL))Callback {
    
    ObjC_ContactModel *ContactData = self.StatisticsModel.Contacts[0];
    
    
    [UiLogger WriteLogInfo:@"UiHistoryCalls: Save action executed"];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactData]]];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        ObjC_ContactModel *NewContact = [ContactsManager CopyContactAndPrepareForSaveLocal:ContactData];
        
        NewContact.NativeId = nil;
        NewContact.PhonebookId = nil;
        NewContact.DodicallId = nil;
        NewContact.Id = 0;
        
        ContactIdType ContactId = 0;
        
        ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:NewContact];
        
        if(ResultContact && ResultContact.Id)
            ContactId = ResultContact.Id;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(ContactId > 0)
            {
                [UiLogger WriteLogInfo:@"UiHistoryStatistics: Save action finished with success"];
                //Прийдет ли callback после сохранения контакта с новой историей?
                //Локально меняю контакт, чтобы при скролинге работало
                
                self.StatisticsModel.Contacts[0] = ResultContact;
                Callback(YES);
            }
            else
            {
                [UiLogger WriteLogInfo:@"UiHistoryStatistics: Save action failed"];
                Callback(NO);
            }
            
            
        });
        
        
    });
}

- (void) SetReaded
{
    if(self.StatisticsModel && self.StatisticsModel.Id)
        [[HistoryManager Manager] SetHistoryReadedForId:[self.StatisticsModel.Id copy]];
}




- (void) GenerateTestData {
    
    for(int i=0;i<4;i++) {
        ObjC_HistoryCallModel *callModel = [ObjC_HistoryCallModel new];
        
        callModel.Date = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
        callModel.DurationInSecs = [NSNumber numberWithInteger:123];
        callModel.Status = CallHistoryStatusSuccess;
        callModel.Encryption = 1;
        callModel.Direction = CallDirectionOutgoing;
        [self.CallsArray addObject:callModel];
    }
    
    for(int i=0;i<4;i++) {
        ObjC_HistoryCallModel *callModel = [ObjC_HistoryCallModel new];
        
        callModel.Date = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
        callModel.DurationInSecs = [NSNumber numberWithInteger:23];
        callModel.Status = CallHistoryStatusAborted;
        callModel.Encryption = 0;
        callModel.Direction = CallDirectionIncoming;
        [self.CallsArray addObject:callModel];
    }
    
}




@end
