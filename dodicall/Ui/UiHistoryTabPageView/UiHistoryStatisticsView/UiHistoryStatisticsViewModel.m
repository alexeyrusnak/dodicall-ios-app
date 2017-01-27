//
//  UiHistoryStatisticsViewModel.m
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

#import "UiHistoryStatisticsViewModel.h"
#import "HistoryManager.h"
#import "UiHistoryStatisticsCellModel.h"
#import "ObjC_HistoryCallModel.h"
#import "ContactsManager.h"
#import "CallsManager.h"
#import "ChatsManager.h"
#import "UiChatsTabNavRouter.h"
#import "UiNavRouter.h"
#import "UiLogger.h"


@interface UiHistoryStatisticsViewModel()

@property (strong, nonatomic) NSMutableArray *DisposableRacArr;

@end

@implementation UiHistoryStatisticsViewModel
- (instancetype)init {
    if(self = [super init]) {
        
        self.DataUpdateStages = [NSMutableArray new];
        self.ThreadSafeRows = [NSMutableArray new];
        
        self.DisposableRacArr = [NSMutableArray new];
        [self BindAll];
        
    }
    return self;
}

- (void) BindAll {
    
    @weakify(self);
    [[[HistoryManager Manager].HistoryStatisticsListUpdatingStateSignal deliverOn:[HistoryManager Manager].ViewModelScheduler] subscribeNext:^(id x) {
        if([(NSNumber *)x integerValue] == HistoryStatisticsListUpdatingReady || [(NSNumber *)x integerValue] == HistoryStatisticsListUpdatingStateUpdated) {
            @strongify(self);
            [self UpdateRows];
        }
    }];
    
    self.ShowComingSoonCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteShowComingSoonCommand];
    }];
    
    self.CallCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(ObjC_HistoryStatisticsModel *input) {
        @strongify(self);
        return [self ExecuteCallCommandWithHistoryObject:input];
    }];
    
    self.ChatCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(ObjC_HistoryStatisticsModel *input) {
        @strongify(self);
        return [self ExecuteMessageCommandWithHistoryObject:input];
    }];
    
}

- (void) UpdateRows {
    
    for(RACDisposable *Disposable in self.DisposableRacArr)
    {
        [Disposable dispose];
    }
    
    [self.DisposableRacArr removeAllObjects];
    
    [UiLogger WriteLogDebug:@"UiHistoryViewModel: Start Update Rows"];
    
    NSMutableArray *newRows = [NSMutableArray new];
    NSArray *historyCopy = [[HistoryManager Manager].HistoryStatisticsList copy];
    for(ObjC_HistoryStatisticsModel *historyModel in historyCopy) {
        UiHistoryStatisticsCellModel *cell = [UiHistoryStatisticsCellModel new];
        
        cell.NumberOfIncomingSuccessfulCalls = historyModel.NumberOfIncomingSuccessfulCalls;
        cell.NumberOfIncomingUnsuccessfulCalls = historyModel.NumberOfIncomingUnsuccessfulCalls;
        cell.NumberOfOutgoingSuccessfulCalls = historyModel.NumberOfOutgoingSuccessfulCalls;
        cell.NumberOfOutgoingUnsuccessfulCalls = historyModel.NumberOfOutgoingUnsuccessfulCalls;
        cell.HasIncomingEncryptedCall = historyModel.HasIncomingEncryptedCall;
        cell.HasOutgoingEncryptedCall = historyModel.HasOutgoingEncryptedCall;
        cell.Title = [self GetTitle:historyModel];
        cell.TitleIndicator = [self GetTitleIndicator:historyModel];
        cell.CallInfo = [self GetCallInfo:historyModel.HistoryCallsList[0]];
        cell.CellId = [self GetCellId:historyModel.Contacts[0]];
        cell.IsDodicall = historyModel.Contacts[0].DodicallId.length>0? @(YES):@(NO);
        cell.TitleIndicatorColor = [self GetTitleColor:historyModel];
        cell.HistoryModel = historyModel;
        
        if(cell.IsDodicall) {
            [cell setXmppId:[ContactsManager GetXmppIdOfContact:historyModel.Contacts[0]]];
            
            if(cell.XmppId) {
                [self SetStatusToModel:cell];
                
                @weakify(self);
                
                RACDisposable *disposable = [RACObserve([ContactsManager Contacts], XmppStatuses) subscribeNext:^(NSMutableArray *StatusesArr) {
                    
                    @strongify(self);
                    
                    for(NSString *XmppId in StatusesArr) {
                        if([XmppId isEqualToString:cell.XmppId])
                            [self SetStatusToModel:cell];
                    }
                    
                }];
                
                [self.DisposableRacArr addObject:disposable];
            }
            @weakify(cell);
            RAC(cell, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:historyModel.Contacts[0]] WithDoNextBlock:^(NSString *Path) {
                @strongify(cell);
                cell.AvatarPath = Path;
            }];
        }
        
        [newRows addObject:cell];
    }
    [self.DataUpdateStages addObject:newRows];
    self.DataReloaded = @(YES);
    
    [UiLogger WriteLogDebug:@"UiHistoryViewModel: End Update Rows"];
    
}

- (NSString *) GetCallInfo:(ObjC_HistoryCallModel *)call {
    
    [UiLogger WriteLogDebug:@"UiHistoryViewModel: Start Get Call Info"];
    
    NSString *info = @"";
    
    
    if(call.Status == CallHistoryStatusSuccess) {
        if(call.Direction == CallDirectionOutgoing) {
            info = [info stringByAppendingString:[NSLocalizedString(@"CallHistory_Outgoing", nil) lowercaseString]];
        }
        else {
            info = [info stringByAppendingString:[NSLocalizedString(@"CallHistory_Incoming", nil) lowercaseString]];
        }
    }
    else if(call.Status == CallHistoryStatusAborted) {
        info = [info stringByAppendingString:[NSLocalizedString(@"CallHistory_Aborted", nil) lowercaseString]];
    }
    else if(call.Status == CallHistoryStatusMissed) {
        info = [info stringByAppendingString:[NSLocalizedString(@"CallHistory_Missed", nil) lowercaseString]];
    }
    else if(call.Status == CallHistoryStatusDeclined) {
        info = [info stringByAppendingString:[NSLocalizedString(@"CallHistory_Aborted", nil) lowercaseString]];
    }

    
    if(call.Date) {
        info = [info stringByAppendingString:@", "];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.doesRelativeDateFormatting = YES;
        
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[AppManager app].UserSettingsModel.GuiLanguage]];
        
        NSString *dateString = [dateFormatter stringFromDate:call.Date];
        
        info = [info stringByAppendingString:[dateString lowercaseString]];
    }
    [UiLogger WriteLogDebug:@"UiHistoryViewModel: End Get Call Info"];
    return info;
}

- (NSString *) GetTitle:(ObjC_HistoryStatisticsModel *)historyModel {
    
    //[UiLogger WriteLogDebug:@"UiHistoryViewModel: Start Get Title"];
    ObjC_ContactModel *contact = historyModel.Contacts[0];
    NSString *title = @"";
    
    if(contact) {
        /*
        if(contact.FirstName&&contact.FirstName.length) {
            title = [title stringByAppendingString:contact.FirstName];
        }
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
    else if(historyModel.Identity && historyModel.Identity.length){
        title = [title stringByAppendingString:historyModel.Identity];
        title = [title componentsSeparatedByString:@"@"][0];
    }
    
    //[UiLogger WriteLogDebug:@"UiHistoryViewModel: End Get Title"];
    return title;
}

- (NSString *) GetTitleIndicator:(ObjC_HistoryStatisticsModel *)historyModel {
    NSString *Indicator = [NSString new];
    
    if([historyModel.NumberOfMissedCalls intValue] > 0)
        Indicator = [Indicator stringByAppendingString:[NSString stringWithFormat:@" (%d)", [historyModel.NumberOfMissedCalls intValue]]];
    
    return Indicator;
}

- (NSString *) GetTitleColor:(ObjC_HistoryStatisticsModel *)historyModel {
    NSString *color = @"Black";
    //if(historyModel.HistoryCallsList[0].Status == CallHistoryStatusMissed) {
        if([historyModel.NumberOfMissedCalls intValue] > 0)
            color = @"Red";
    //}
    return color;
}

- (NSString *) GetCellId:(ObjC_ContactModel *)contact {
    [UiLogger WriteLogDebug:@"UiHistoryViewModel: Start Get CellID"];
    
    NSString *cellId;
    
    if(contact) {
        ContactProfileType contactType = [ContactsManager GetContactProfileType:contact];
        
        if(contactType == ContactProfileTypeDirectoryLocal) {
            if([ContactsManager CheckContactIsRequest:contact])
                cellId = @"UiHistoryTableCellNotAproved";
            else
                cellId = @"UiHistoryTableCellAproved";
        }
        else if(contactType == ContactProfileTypeDirectoryRemote) {
            cellId = @"UiHistoryTableCellNotAproved";
        }
        else if(contactType == ContactProfileTypeLocal) {
            cellId = @"UiHistoryTableCellExternal";
        }
        else if(contactType == ContactProfileTypePhonebook) {
            cellId = @"UiHistoryTableCellExternalAdd";
        }

    }
    else
        cellId = @"UiHistoryTableCellExternalAdd";
    
    [UiLogger WriteLogDebug:@"UiHistoryViewModel: End Get CellID"];
    return cellId;
}

- (void) SetStatusToModel:(UiHistoryStatisticsCellModel *) RowModel {
    
    ObjC_ContactPresenceStatusModel *Status = [ContactsManager GetXmppStatusByXmppId:RowModel.XmppId];
    
    switch (Status.BaseStatus) {
            
        case BaseUserStatusOnline:
            [RowModel setStatus:@"ONLINE"];
            break;
            
        case BaseUserStatusDnd:
            [RowModel setStatus:@"DND"];
            break;
            
        case BaseUserStatusAway:
            [RowModel setStatus:@"AWAY"];
            break;
            
        case BaseUserStatusHidden:
            [RowModel setStatus:@"INVISIBLE"];
            break;
            
        default:
            [RowModel setStatus:@"OFFLINE"];
            break;
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
//                [subscriber sendCompleted];
//                
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

- (void) SaveContactForIndexPath:(NSIndexPath *)IndexPath AndReturnInCallback: (void (^)(BOOL))Callback {
    
    
    
    UiHistoryStatisticsCellModel *cellModel = [self.ThreadSafeRows objectAtIndex:IndexPath.row];
    ObjC_ContactModel *ContactData = cellModel.HistoryModel.Contacts[0];
    
    
    [UiLogger WriteLogInfo:@"UiHistoryStatistics: Save action executed"];
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
                
                ((UiHistoryStatisticsCellModel *)[self.ThreadSafeRows objectAtIndex:IndexPath.row]).HistoryModel.Contacts[0] = ResultContact;
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





@end
