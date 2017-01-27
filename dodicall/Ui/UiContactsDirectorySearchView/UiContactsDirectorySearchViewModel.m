//
//  UiContactsDirectorySearchViewModel.m
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

#import "UiContactsDirectorySearchViewModel.h"
#import "UiContactsDirectorySearchListRowItemViewModel.h"
#import "AppManager.h"
#import "ContactsManager.h"

#import "UiLogger.h"

@interface UiContactsDirectorySearchViewModel ()

@property NSMutableDictionary *DataMutable;

@end

@implementation UiContactsDirectorySearchViewModel

/*
@synthesize Data;

@synthesize DataReloaded;

@synthesize DataReloadedSignal;

@synthesize SearchText;

@synthesize SearchState;

@synthesize SearchStateSignal;
 */


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.DataMutable = [[NSMutableDictionary alloc] init];
        self.ThreadSafeRows = [NSMutableArray new];
        self.RowsUpdateStages = [NSMutableArray new];
        
        self.DataReloaded = @(NO);
        self.DataReloadedSignal = RACObserve(self, DataReloaded);
        
        self.SearchState = UiContactsDirectorySearchLoadingStateNone;
        self.SearchStateSignal = RACObserve(self, SearchState);
        
        @weakify(self);
        
        [[[ContactsManager Contacts].ContactsListStateSignal
            deliverOn:[ContactsManager Manager].ViewModelScheduler]
            subscribeNext:^(NSNumber *State) {
                @strongify(self);
                if(self.SearchState == UiContactsDirectorySearchLoadingStateFinishedSuccess && ([State integerValue] == ContactsListLoadingStateFinishedSuccess || [State integerValue] == ContactsListLoadingStateUpdated))
                    [self ReloadData];
            }];

    }
    return self;
}

- (void) PerformSearch
{
    self.SearchState = UiContactsDirectorySearchLoadingStateFinishedSuccess;
    
    self.SearchState = UiContactsDirectorySearchLoadingStateInProgress;
    
    [self.DataMutable removeAllObjects];
    
    NSString *NewSearchText = [self.SearchText copy];
    
    NSMutableArray *ResultsArray = [NSMutableArray new];
    
    [self.DataMutable setObject:ResultsArray forKey:NewSearchText];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ObjC_BaseResult *Result = [[AppManager app].Core FindContactsInDirectory:ResultsArray :NewSearchText];
        
        dispatch_async([ContactsManager Manager].ViewModelQueue, ^{
            if([Result.Success boolValue])
            {
                [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsDirectorySearchViewModel:FindContactsInDirectory: Contacts fetched: %lu", (unsigned long)[ResultsArray count]]];
                
                [self ReloadData];
                
                self.SearchState = UiContactsDirectorySearchLoadingStateFinishedSuccess;
            }
            else
            {
                [UiLogger WriteLogInfo:@"UiContactsDirectorySearchViewModel:FindContactsInDirectory: Failed"];
                
                self.SearchState = UiContactsDirectorySearchLoadingStateFinishedFail;
            }
        });

    });

}

- (void) ReloadData
{
    dispatch_async([ContactsManager Manager].ViewModelQueue, ^{
        
        NSMutableArray *Rows = [NSMutableArray new];
        
        if([self.DataMutable objectForKey:self.SearchText])
        {
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsDirectorySearchViewModel:ReloadData: Contacts after filters apply: %lu", (unsigned long)[[self.DataMutable objectForKey:self.SearchText] count]]];
            
            for (ObjC_ContactModel *ContactModel in [[self.DataMutable objectForKey:self.SearchText] copy])
            {
                UiContactsDirectorySearchListRowItemViewModel *RowModel = [[UiContactsDirectorySearchListRowItemViewModel alloc] init];
                
                [RowModel setContactData:ContactModel];
                
                [RowModel setTitle:[NSString stringWithFormat:@"%@ %@", ContactModel.FirstName, ContactModel.LastName]];
                
                [RowModel setIsInLocalDirectory:[NSNumber numberWithBool:NO]];
                
                [RowModel setIsIam:[ContactModel.Iam copy]];
                
                // Check if contact is in local directory
                NSInteger ContactIndex = [[ContactsManager Contacts] FindContactIndex:ContactModel];
                if(ContactIndex != NSNotFound)
                {
                    [RowModel setIsInLocalDirectory:[NSNumber numberWithBool:YES]];
                    
                    ObjC_ContactModel *LocalContactModel = [[ContactsManager Contacts].ContactsList objectAtIndex:ContactIndex];
                    
                    [RowModel setContactData:[ContactsManager CopyContact:LocalContactModel]];
                }
                
                @weakify(RowModel);
                RAC(RowModel, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:[[RACSignal empty] startWith:RowModel.ContactData] WithDoNextBlock:^(NSString *Path) {
                    @strongify(RowModel);
                    RowModel.AvatarPath = Path;
                }];
                
                [Rows addObject: RowModel];
            }
        }
        
        [self.RowsUpdateStages addObject:Rows];
        
        self.DataReloaded = @(YES);
    });
}

#pragma mark Filters

- (void) SetSearchTextFilter:(NSString *)Search
{
    self.SearchText = Search;
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsDirectorySearchViewModel: User set text filter: %@", self.SearchText]];
    
    if(self.SearchText.length >= 3)
        [self PerformSearch];
    else
    {
        //self.Data = [NSArray new];
        [self.DataMutable removeAllObjects];
        dispatch_async([ContactsManager Manager].ViewModelQueue, ^{
            [self ReloadData];
            self.SearchState = UiContactsDirectorySearchLoadingStateFinishedSuccess;
        });
    }
}

- (void) ExecuteSaveAction:(ObjC_ContactModel *)ContactData withCallback:(void (^)(BOOL))Callback
{
    
    [UiLogger WriteLogInfo:@"UiContactsDirectorySearchViewModel: Save action executed"];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactData]]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ContactIdType ContactId = 0;
        
        ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:ContactData];
        
        if(ResultContact && ResultContact.Id)
            ContactId = ResultContact.Id;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(ContactId > 0)
            {
                
                [UiLogger WriteLogInfo:@"UiContactsDirectorySearchViewModel: Save action finished with success"];
                Callback(YES);
            }
            else
            {
                [UiLogger WriteLogInfo:@"UiContactsDirectorySearchViewModel: Save action failed"];
                Callback(NO);
            }
            
            
        });
    });
}

@end
