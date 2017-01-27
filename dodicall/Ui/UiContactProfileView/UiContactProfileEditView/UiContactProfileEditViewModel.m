//
//  UiContactProfileEditViewModel.m
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

#import "UiContactProfileEditViewModel.h"
#import "ContactsManager.h"
#import "AppManager.h"
#import "CoreHelper.h"
#import "UiLogger.h"

@interface UiContactProfileEditViewModel()
{
    BOOL IsBinded;
}

@end

@implementation UiContactProfileEditViewModel

/*

@synthesize FirstNameTextFieldText;

@synthesize LastNameTextFieldText;

@synthesize ContactsTable;

@synthesize MenuTable;

@synthesize ContactData;

@synthesize TypePickerRows;

@synthesize TypePickerCellModel;

@synthesize SavingProcessState;

@synthesize IsDataFalid;

@synthesize IsDataFalidSignal;

@synthesize IsDirectoryLocalType;

@synthesize IsDirectoryRemoteType;

@synthesize IsInLocalDirectory;

@synthesize IsLocalType;

@synthesize IsPhonebookType;

@synthesize ContactDataSignal;

@synthesize IsBlocked;

@synthesize IsWhite;
 
*/

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.IsDataValid = [NSNumber numberWithInt:0];
        
        self.ContactData = [[ObjC_ContactModel alloc] init];
        
        
        // Fill contact types array
        NSDictionary *TypeLabelValuesPhone = @{@"value":[NSNumber numberWithInt:ContactsContactPhone],@"title":[NSLocalizedString(@"Title_ContactsContactPhone", nil) lowercaseString]};
        
        // Требование от Яна - убрать возможность добавлять Sip
        //NSDictionary *TypeLabelValuesSip = @{@"value":[NSNumber numberWithInt:ContactsContactSip],@"title":NSLocalizedString(@"Title_ContactsContactSip", nil)};
        
        
        [self setTypePickerRows: @[TypeLabelValuesPhone/*,TypeLabelValuesSip*/]];
        
        self.BackViewAction = ^() {
          [UiContactsTabNavRouter CloseProfileEditViewWhenBackAction];
        };
        self.SaveViewAction = ^() {
            [UiContactsTabNavRouter CloseProfileEditViewWhenSaveAction];
        };
        
        
        [self BindAll];
    }
    return self;
}

- (void) BindAll
{
    if(IsBinded)
        return;
    
    @weakify(self);
    
    self.ContactDataSignal = [RACObserve(self, ContactData) deliverOn:[ContactsManager Manager].ViewModelScheduler];
    
    [self.ContactDataSignal subscribeNext:^(ObjC_ContactModel *Data)
    {
        
        @strongify(self);
        
        ContactProfileType Type = [ContactsManager GetContactProfileType:Data];
        
        if(Type == ContactProfileTypeDirectoryLocal)
        {
            [self setIsDirectoryLocalType:YES];
            [self setIsDirectoryRemoteType:NO];
            [self setIsLocalType:NO];
            [self setIsPhonebookType:NO];
        }
        
        if(Type == ContactProfileTypeDirectoryRemote)
        {
            [self setIsDirectoryLocalType:NO];
            [self setIsDirectoryRemoteType:YES];
            [self setIsLocalType:NO];
            [self setIsPhonebookType:NO];
        }
        
        if(Type == ContactProfileTypeLocal)
        {
            [self setIsDirectoryLocalType:NO];
            [self setIsDirectoryRemoteType:NO];
            [self setIsLocalType:YES];
            [self setIsPhonebookType:NO];
        }
        
        if(Type == ContactProfileTypePhonebook)
        {
            [self setIsDirectoryLocalType:NO];
            [self setIsDirectoryRemoteType:NO];
            [self setIsLocalType:NO];
            [self setIsPhonebookType:YES];
        }
        
        [self setFirstNameTextFieldText:Data.FirstName];
        
        [self setLastNameTextFieldText:Data.LastName];
        
        [self setIsBlocked:[NSNumber numberWithBool:[Data.Blocked boolValue]]];
        
        [self setIsWhite:[NSNumber numberWithBool:[Data.White boolValue]]];
        
        // Populate contacts table
        
        [self setContactsTable:[[NSMutableArray alloc] init]];
        
        for (ObjC_ContactsContactModel *Contact in Data.Contacts) {
            
            UiContactProfileEditContactsTableCellViewModel * CellModel = [[UiContactProfileEditContactsTableCellViewModel alloc] init];
            
            if((Contact.Type == ContactsContactSip || Contact.Type == ContactsContactPhone) && [Contact.Manual boolValue])
            {
                [self SetContactsTableCellTypeLabelText:CellModel withType:Contact.Type];
                
                [CellModel setPhoneTextFieldText:Contact.Identity];
                
                [self SetContactsTableCellBindings:CellModel];
                
                
                [self.ContactsTable addObject:CellModel];
                
            }
            
        }
        
        // Add button to contacts table
        UiContactProfileEditMenuTableCellViewModel * MenuCellModel = [[UiContactProfileEditMenuTableCellViewModel alloc] init];
        [MenuCellModel setTitleLabelText:NSLocalizedString(@"Title_AddNumber", nil)];
        [MenuCellModel setCellIdenty:@"UiContactProfileEditContactsTableAddCellView"];
        [self.ContactsTable addObject:MenuCellModel];
        
        
        // Populate menu table
        [self setMenuTable:[[NSMutableArray alloc] init]];
        
        if(self.ContactData.Id > 0)
        {
            MenuCellModel = [[UiContactProfileEditMenuTableCellViewModel alloc] init];
            
            if(![self.IsBlocked boolValue])
                [MenuCellModel setTitleLabelText:NSLocalizedString(@"Title_BlockContact", nil)];
            else
                [MenuCellModel setTitleLabelText:NSLocalizedString(@"Title_UnBlockContact", nil)];
            
            [MenuCellModel setCellIdenty:@"UiContactProfileEditMenuTableBlockContactCell"];
            [self.MenuTable addObject:MenuCellModel];
            
            
            MenuCellModel = [[UiContactProfileEditMenuTableCellViewModel alloc] init];
            
            if(![self.IsWhite boolValue])
                [MenuCellModel setTitleLabelText:NSLocalizedString(@"Title_AddToWhiteContact", nil)];
            else
                [MenuCellModel setTitleLabelText:NSLocalizedString(@"Title_RemoveFromWhiteContact", nil)];
            
            [MenuCellModel setCellIdenty:@"UiContactProfileEditMenuTableWhiteContactCell"];
            [self.MenuTable addObject:MenuCellModel];
            
            
            MenuCellModel = [[UiContactProfileEditMenuTableCellViewModel alloc] init];
            [MenuCellModel setTitleLabelText:NSLocalizedString(@"Title_DeleteContact", nil)];
            [MenuCellModel setCellIdenty:@"UiContactProfileEditMenuTableDeleteContactCell"];
            [self.MenuTable addObject:MenuCellModel];
        }
        
    }];
    
    
    self.IsDataValidSignal = [RACObserve(self, IsDataValid) distinctUntilChanged];
    
    RACSignal *FIOSignal = [[RACSignal
       combineLatest:@[RACObserve(self, FirstNameTextFieldText), RACObserve(self, LastNameTextFieldText) ]
       reduce:^(NSString *FirstName, NSString *LastName) {
           return @"";
       }]
       deliverOn:[ContactsManager Manager].ViewModelScheduler];
    
    [FIOSignal subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self ValidateData];
        self.DataChanged = @([self IsContactDataChanged]);
        
    }];
    
    [[RACObserve(self, ContactsTable)
        deliverOn:[ContactsManager Manager].ViewModelScheduler]subscribeNext:^(id x) {
            @strongify(self);
            self.DataChanged = @([self IsContactDataChanged]);
        }];
    
    //Avatar
    
    RAC(self, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:RACObserve(self, ContactData) WithDoNextBlock:^(NSString * Path) {
        @strongify(self);
        self.AvatarPath = Path;
    }];
    
    
    IsBinded = YES;
}

- (BOOL) ValidateData
{
    BOOL IsValid = NO;
    
    // Check first or last name
    if(self.FirstNameTextFieldText && self.FirstNameTextFieldText.length > 0)
        IsValid = YES;
    
    if(self.LastNameTextFieldText && self.LastNameTextFieldText.length > 0)
        IsValid = YES;
    
    // Check Contacts
    if(self.ContactsTable && [self.ContactsTable count] > 1)
    {
        for (int i = 0; i < [self.ContactsTable count] - 1; i++)
        {
            
            UiContactProfileEditContactsTableCellViewModel *ContactCellModel = (UiContactProfileEditContactsTableCellViewModel *)[self.ContactsTable objectAtIndex:i];
            
            if(!ContactCellModel.IsValid)
                IsValid = NO;
        }
    }
    
    if(IsValid)
        self.IsDataValid = [NSNumber numberWithInt:1];
    else
        self.IsDataValid = [NSNumber numberWithInt:0];
    
    
    return IsValid;

}

- (void) SetContactsTableCellTypeLabelText:(UiContactProfileEditContactsTableCellViewModel *) CellModel withType:(ContactsContactType) Type
{
    if(Type == ContactsContactSip)
    {
        [CellModel setTypeLabelValue:[NSNumber numberWithInt:ContactsContactSip]];
        
        [CellModel setTypeLabelPickerRow:@1];
        
        [CellModel setTypeLabelText:[NSLocalizedString(@"Title_ContactsContactSip", nil) lowercaseString]];
    }
    else if(Type == ContactsContactPhone)
    {
        [CellModel setTypeLabelValue:[NSNumber numberWithInt:ContactsContactPhone]];
        
        [CellModel setTypeLabelPickerRow:@0];
        
        [CellModel setTypeLabelText:[NSLocalizedString(@"Title_ContactsContactPhone", nil) lowercaseString]];
    }
    else
    {
        [CellModel setTypeLabelValue:[NSNumber numberWithInt:ContactsContactPhone]];
        
        [CellModel setTypeLabelPickerRow:@0];
        
        [CellModel setTypeLabelText:[NSLocalizedString(@"Title_ContactsContactPhone", nil) lowercaseString]];
    }

}

- (void) SetContactsTableCellBindings:(UiContactProfileEditContactsTableCellViewModel *) CellModel
{
    @weakify(self);
    
    [[RACObserve(CellModel, PhoneTextFieldText) distinctUntilChanged] subscribeNext:^(NSString *Text) {
        
        @strongify(self);
        
        [self ValidateAndFormatContactsTableCell:CellModel];
        self.DataChanged = @([self IsContactDataChanged]);
        
    }];
}

- (void) ValidateAndFormatContactsTableCell:(UiContactProfileEditContactsTableCellViewModel *) CellModel
{
    [UiLogger WriteLogInfo:@"ValidateAndFormatContactsTableCell"];
    
    if(CellModel.PhoneTextFieldText.length > 0)
    {
        /*
         
         DMC-2287 delayed
         
        [CellModel setPhoneTextFieldText:[self FormatContactIdentity:CellModel.PhoneTextFieldText]];
         
         */
        
        if([CellModel.TypeLabelValue intValue] == ContactsContactSip)
        {
            [CellModel setIsValid:[self ValidateSip:CellModel.PhoneTextFieldText]];
        }
        else
        {
            [CellModel setIsValid:[self ValidatePhone:CellModel.PhoneTextFieldText]];
        }
    }
    else
    {
        [CellModel setIsValid:YES];
    }
    
    [self ValidateData];
}

- (NSInteger) AddEmptyContact
{
    UiContactProfileEditContactsTableCellViewModel * CellModel = [[UiContactProfileEditContactsTableCellViewModel alloc] init];
    
    [self SetContactsTableCellTypeLabelText:CellModel withType:ContactsContactPhone];
    
    [CellModel setPhoneTextFieldText:@""];
    
    [self SetContactsTableCellBindings:CellModel];
    
    NSInteger InsertIndex = [self.ContactsTable count] - 1;
    
    if(InsertIndex < 0)
        InsertIndex = 0;
    
    [self.ContactsTable insertObject:CellModel atIndex:InsertIndex];
    self.DataChanged = @([self IsContactDataChanged]);
    
    return InsertIndex;
}

- (BOOL) RemoveContact: (NSInteger) Row
{
    [self.ContactsTable removeObjectAtIndex:Row];
    self.DataChanged = @([self IsContactDataChanged]);
    
    return YES;
}

- (void) ExecuteSaveAction
{
    self.SavingProcessState = [NSNumber numberWithInt:UiContactProfileEditSavingStateValidation];
    
    if(self.FirstNameTextFieldText.length > 256)
        self.ContactData.FirstName = [self.FirstNameTextFieldText substringToIndex:256];
    else
        self.ContactData.FirstName = self.FirstNameTextFieldText;
    
    if(self.LastNameTextFieldText.length > 256)
        self.ContactData.LastName = [self.LastNameTextFieldText substringToIndex:256];
    else
        self.ContactData.LastName = self.LastNameTextFieldText;
    
    
    NSMutableArray *ContactsContactList = [[NSMutableArray alloc] init];
    
    //Populate Not Manual from current model
    if(self.ContactData.Contacts)
    {
        for (ObjC_ContactsContactModel *ContactModel in self.ContactData.Contacts) {
            
            if(![ContactModel.Manual boolValue])
            {
                
                ObjC_ContactsContactModel *Contact = [[ObjC_ContactsContactModel alloc] init];
                
                Contact.Type = ContactModel.Type;
                
                Contact.Identity = ContactModel.Identity;
                
                Contact.Favourite = ContactModel.Favourite;
                
                Contact.Manual = ContactModel.Manual;
                
                [ContactsContactList addObject:Contact];
            }
            
        }

    }
    
    // Populate Manual from table
    for (int i = 0; i < [self.ContactsTable count] - 1; i++)
    {
        
        UiContactProfileEditContactsTableCellViewModel *ContactCellModel = (UiContactProfileEditContactsTableCellViewModel *)[self.ContactsTable objectAtIndex:i];
        
        if(ContactCellModel.PhoneTextFieldText.length > 0)
        {
            ObjC_ContactsContactModel *Contact = [[ObjC_ContactsContactModel alloc] init];
            
            Contact.Type = [ContactCellModel.TypeLabelValue intValue];
            
            if(ContactCellModel.PhoneTextFieldText.length > 256)
                Contact.Identity = [ContactCellModel.PhoneTextFieldText substringToIndex:256];
            else
                Contact.Identity = ContactCellModel.PhoneTextFieldText;
            
            Contact.Favourite = [NSNumber numberWithBool:ContactCellModel.IsFavourite];
            
            Contact.Manual = [NSNumber numberWithBool:YES];
            
            [ContactsContactList addObject:Contact];
        }
    }
    
    self.ContactData.Contacts = ContactsContactList;
    
    self.SavingProcessState = [NSNumber numberWithInt:UiContactProfileEditSavingStateStart];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 
        ContactIdType ContactId = 0;
        
        ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:self.ContactData];
        
        if(ResultContact && ResultContact.Id)
            ContactId = ResultContact.Id;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(ContactId > 0)
            {
                
                self.ContactData.Id = ContactId;
                
                self.SavingProcessState = [NSNumber numberWithInt:UiContactProfileEditSavingStateCompleteWithSuccess];
            }
            else
            {
                self.SavingProcessState = [NSNumber numberWithInt:UiContactProfileEditSavingStateCompleteWithError];
            }
            
            
        });
    });
}

- (BOOL) ValidateSip: (NSString *) Candidate {
    NSString *SipRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *SipTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", SipRegex];
    
    return [SipTest evaluateWithObject:Candidate];
}

- (BOOL) ValidatePhone: (NSString *) Candidate {
    
    BOOL IsValidType1 = NO;
    
    NSString *PhoneRegex = @"^\\+(?:[0-9] ?){6,14}[0-9]$";
    
    NSPredicate *PhoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", PhoneRegex];
    
    IsValidType1 = [PhoneTest evaluateWithObject:Candidate];
    
    
    BOOL IsValidType2 = NO;
    
    PhoneRegex = @"[235689][0-9]{6,14}([0-9]{3})?";
    
    PhoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", PhoneRegex];
    
    IsValidType2 = [PhoneTest evaluateWithObject:Candidate];
    
    return IsValidType1 || IsValidType2;
}

- (NSString *) FormatContactIdentity: (NSString *) ContactIdentity
{
    return [CoreHelper FormatContactIdentity:ContactIdentity];
}

- (BOOL) IsContactDataChanged {
    
    
    if(![self.FirstNameTextFieldText isEqualToString:self.ContactData.FirstName])
        return YES;
    
    if(![self.LastNameTextFieldText isEqualToString:self.ContactData.LastName])
        return YES;
    
    
    ContactsContactList ContactContacts = [self.ContactData.Contacts mutableCopy];
    for(ObjC_ContactsContactModel *Contact in self.ContactData.Contacts) {
        if(!(Contact.Type == ContactsContactSip || Contact.Type == ContactsContactPhone) || ![Contact.Manual boolValue]) {
            [ContactContacts removeObject:Contact];
        }
    }
    
    NSMutableArray *ContacModels = [self.ContactsTable mutableCopy];
    for(id Model in self.ContactsTable) {
        if(![Model isKindOfClass:[UiContactProfileEditContactsTableCellViewModel class]])
            [ContacModels removeObject:Model];
    }
    
    
    if([ContacModels count]!=[ContactContacts count]) {
        if([ContacModels count] > [ContactContacts count]) {
            NSInteger sizeDif = [ContacModels count] - [ContactContacts count];
            NSInteger maxInd = [ContacModels count]-1;
            NSInteger minInd = maxInd - sizeDif;
            
            for(NSInteger i = maxInd; i>minInd; i--) {
                
                UiContactProfileEditContactsTableCellViewModel *ContactVM = [ContacModels objectAtIndex:i];
                if(ContactVM.PhoneTextFieldText.length > 0)
                    return YES;
            }

        }
        else
            return YES;
    }
    else {
        for(NSInteger i=0;i<[ContacModels count];i++) {

            UiContactProfileEditContactsTableCellViewModel *ContactVM = [ContacModels objectAtIndex:i];
            ObjC_ContactsContactModel *Contact = [ContactContacts objectAtIndex:i];
            
            
            if(![ContactVM.PhoneTextFieldText isEqualToString:Contact.Identity])
                return YES;
            if([ContactVM.TypeLabelValue intValue] != Contact.Type)
                return YES;
            
        }
    }
    
    return NO;

}

@end
