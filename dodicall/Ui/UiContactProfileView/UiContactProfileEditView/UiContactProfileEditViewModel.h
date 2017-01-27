//
//  UiContactProfileEditViewModel.h
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

#import "UiContactProfileEditSkeleton.h"
#import "ObjC_ContactModel.h"


@class ObjC_ContactModel;
@class UiContactProfileEditContactsTableCellViewModel;

typedef enum {
    UiContactProfileEditSavingStateNone,
    UiContactProfileEditSavingStateValidation,
    UiContactProfileEditSavingStateValidationSuccess,
    UiContactProfileEditSavingStateValidationError,
    UiContactProfileEditSavingStateStart,
    UiContactProfileEditSavingStateCompleteWithSuccess,
    UiContactProfileEditSavingStateCompleteWithError
} UiContactProfileEditSavingState;


@interface UiContactProfileEditViewModel : NSObject

// TODO: relize copy protocol
@property (nonatomic/*, copy*/) ObjC_ContactModel *ContactData;

@property NSString *FirstNameTextFieldText;

@property NSString *LastNameTextFieldText;

@property NSMutableArray *ContactsTable; // Array of UiContactProfileEditContactsTableCellViewModel

@property NSMutableArray *MenuTable;

@property NSArray *TypePickerRows;

@property UiContactProfileEditContactsTableCellViewModel *TypePickerCellModel;

@property NSNumber* SavingProcessState;

@property NSNumber* IsDataValid;

@property RACSignal* IsDataValidSignal;

@property BOOL IsDirectoryLocalType;

@property BOOL IsDirectoryRemoteType;

@property BOOL IsInLocalDirectory;

@property BOOL IsLocalType;

@property BOOL IsPhonebookType;

@property NSString *AvatarPath;

@property NSNumber *IsBlocked;

@property NSNumber *IsWhite;

@property NSNumber *DataChanged;

@property RACSignal *ContactDataSignal;

@property (copy) void (^BackViewAction)(void);
@property (copy) void (^SaveViewAction)(void);

- (void) SetContactsTableCellTypeLabelText:(UiContactProfileEditContactsTableCellViewModel *) CellModel withType:(ContactsContactType) Type;

- (NSInteger) AddEmptyContact;

- (BOOL) RemoveContact: (NSInteger) Row;

- (void) ExecuteSaveAction;

- (BOOL) ValidateData;

- (BOOL) ValidateSip: (NSString *) Candidate;

- (BOOL) ValidatePhone: (NSString *) Candidate;

- (void) ValidateAndFormatContactsTableCell:(UiContactProfileEditContactsTableCellViewModel *) CellModel;

@end
