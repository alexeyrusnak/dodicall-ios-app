//
//  UiContactProfileViewModel.h
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

#import "UiContactProfileSkeleton.h"

typedef enum {
    UiContactProfileSavingStateNone,
    UiContactProfileSavingStateStart,
    UiContactProfileSavingStateCompleteWithSuccess,
    UiContactProfileSavingStateCompleteWithError
} UiContactProfileSavingState;


@class ObjC_ContactModel;
@class UiContactProfileContactsTableCellViewModel;


@interface UiContactProfileViewModel : NSObject

// TODO: relize copy protocol
@property (nonatomic/*, copy*/) ObjC_ContactModel *ContactData;

@property NSString *FirstNameLabelText;

@property NSString *LastNameLabelText;

@property NSString *Status;

@property NSString *StatusLabelText;

@property NSString *MyProfileStatus;

@property NSString *MyProfileStatusLabelText;

@property NSString *XmppId;

//@property RACSignal *XmppStatusesSignal;

//@property RACSignal *SubscriptionsStatusesSignal;

@property NSMutableArray *ContactsTable; // Array of UiContactProfileContactsTableCellViewModel

@property NSMutableArray *AddContactsTable; // Array of UiContactProfileContactsTableCellViewModel

@property BOOL IsCallAvailable;

@property BOOL IsVideoCallAvailable;

@property BOOL IsChatCallAvailable;

@property BOOL IsDirectoryLocalType;

@property BOOL IsDirectoryRemoteType;

@property BOOL IsInLocalDirectory;

@property BOOL IsLocalType;

@property BOOL IsPhonebookType;

@property NSNumber *IsInvite;

@property NSNumber *IsRequest;

@property NSNumber *IsDeclinedRequest;

@property BOOL IsBlocked;

@property BOOL IsIam;

@property BOOL IsInTabView;

@property NSNumber* SavingProcessState;

@property BOOL NeedToBeSaved;

@property BOOL IsRequestInputPanelOpened;

@property NSString *BalanceTextValue;

@property (strong, nonatomic) RACCommand *SaveCommand;

@property (strong, nonatomic) NSString *AvatarPath;


//@property BOOL IsApplyRequestContactAndInvitePanelsOpened;

//- (void) ExecuteSaveAction;

- (void) SetFavourite:(UiContactProfileContactsTableCellViewModel *) RowItem;

- (void) ExecuteAcceptAction:(BOOL) Accept withCallback:(void (^)(BOOL))Callback;

- (void) ExecuteUnblockAction:(void (^)(BOOL))Callback;

- (void) Logout;

@end
