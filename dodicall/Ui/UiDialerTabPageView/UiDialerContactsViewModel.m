//
//  UiDialerContactsViewModel.m
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

#import "UiDialerContactsViewModel.h"
#import "UiDialerContactCellModel.h"
#import "ContactsManager.h"

@implementation UiDialerContactsViewModel

#pragma mark - Lifecycle
- (instancetype)init {
    if(self = [super init]) {
        self.ContactRows = [NSMutableArray new];
        self.Name = @"";
        self.WrittenNumber = @"";
        self.SelectedRow = NSNotFound;
        self.IsDodicall = @(0);
        
        [self BindAll];
    }
    return self;
}

- (void)BindAll {
    
    RACSignal *ContactSignal = RACObserve(self, ContactModel);
    RACSignal *ContactIdSignal = [[RACObserve(self, ContactModel.Id) distinctUntilChanged] delay:0.1];
    RACSignal *SampledContactSignal = [[ContactSignal sample:ContactIdSignal] ignore:nil];
    
    @weakify(self);
    
    RACSignal *RowsSignal = [[SampledContactSignal
        map:^id(ObjC_ContactModel *Contact) {
        
            NSMutableArray *NewRows = [NSMutableArray new];
            
            for(ObjC_ContactsContactModel *ContactsContact in Contact.Contacts) {
                
                if(ContactsContact.Type != ContactsContactPhone && ContactsContact.Type!=ContactsContactSip) {
                    continue;
                }
                
                UiDialerContactCellModel *CellModel = [UiDialerContactCellModel new];
                
                CellModel.Number = [ContactsContact.Identity componentsSeparatedByString:@"@"][0];
                
                //TODO: Localise
                if(ContactsContact.Type == ContactsContactSip)
                    CellModel.Type = @"d-sip";
                else if(ContactsContact.Type == ContactsContactPhone)
                    CellModel.Type = @"телефон";
                
                CellModel.IsFavourite = ContactsContact.Favourite;
                
                [NewRows addObject:CellModel];
            }
            
            return NewRows;
        }]
        doNext:^(NSMutableArray *RowsArray) {
            @strongify(self);
            
            self.SelectedRow = NSNotFound;
            self.ContactRows = [NSMutableArray new];
            
            for(UiDialerContactCellModel *CellModel in RowsArray)
            {
                if(self.WrittenNumber && CellModel.Number && [[self.WrittenNumber stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:[[CellModel Number] stringByReplacingOccurrencesOfString:@" " withString:@""]])
                {
                    [CellModel setIsSelected:@(YES)];
                    self.SelectedRow = [RowsArray indexOfObject:CellModel];
                }
                else
                {
                    [CellModel setIsSelected:@(NO)];
                }
            }
        }];
    
    RACSignal *SelectedRowSignal =
        [[[[RACObserve(self, SelectedRow)
            combineLatestWith:RACObserve(self, ContactRows)]
            filter:^BOOL(RACTuple *Tuple) {
                RACTupleUnpack(NSNumber *SelectedRow, NSMutableArray *ContactRows) = Tuple;
                return ContactRows && ContactRows.count && ![SelectedRow isEqual: @(NSNotFound)];
            }]
            doNext:^(RACTuple *Tuple) {
                 RACTupleUnpack(NSNumber *SelectedRow, NSMutableArray *ContactRows) = Tuple;
                
                 for(int i=0; i<[ContactRows count]; i++) {
                     UiDialerContactCellModel *CellModel = [ContactRows objectAtIndex:i];
                     
                     if(i == [SelectedRow integerValue]) {
                         [CellModel setIsSelected:@(1)];
                     }
                     else {
                         [CellModel setIsSelected:@(0)];
                     }
                 }
             }]
            map:^id(RACTuple *Tuple) {
                
                RACTupleUnpack(NSNumber *SelectedRow, NSMutableArray *ContactRows) = Tuple;
                
                UiDialerContactCellModel *SelectedCellModel = [ContactRows objectAtIndex:[SelectedRow integerValue]];
                return [[SelectedCellModel Number] stringByReplacingOccurrencesOfString:@" " withString:@""];
            }];
    
    
    
    
    RAC(self, ContactRows) = RowsSignal;
    
    RAC(self, Name) = [SampledContactSignal map:^id(ObjC_ContactModel *Contact) {
        return [ContactsManager GetContactTitle:Contact];
    }];
    
    RAC(self, SelectedNumber) = [SelectedRowSignal ignore:nil];
    
    RAC(self, IsDodicall) = [SampledContactSignal map:^id(ObjC_ContactModel *Contact) {
        return @(Contact.DodicallId && Contact.DodicallId.length);
    }];
    
    RAC(self, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:SampledContactSignal WithDoNextBlock:^(NSString *Path) {
        @strongify(self);
        self.AvatarPath = Path;
    }];

}

@end
