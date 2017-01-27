//
//  UiContactsTabPageContactsFilterTableViewModel.m
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

#import "UiContactsTabPageContactsFilterTableViewModel.h"
#import "UiContactsTabPageContactsFilterTableCellViewModel.h"

@implementation UiContactsTabPageContactsFilterTableViewModel

@synthesize Data;

@synthesize FilterValue;

@synthesize FilterValueSignal;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.Data = [[NSMutableArray alloc] init];
        
        UiContactsTabPageContactsFilterTableCellViewModel *CellModel;
        
        // UiContactsFilterAll
        CellModel = [[UiContactsTabPageContactsFilterTableCellViewModel alloc] init];
        CellModel.FilterName = NSLocalizedString(@"Title_UiContactsFilterAll", nil);
        CellModel.FilterValue = UiContactsFilterAll;
        [self.Data addObject:CellModel];
        
        // UiContactsFilterDirectoryLocal
        CellModel = [[UiContactsTabPageContactsFilterTableCellViewModel alloc] init];
        CellModel.FilterName = NSLocalizedString(@"Title_UiContactsFilterDirectoryLocal", nil);
        CellModel.FilterValue = UiContactsFilterDirectoryLocal;
        [self.Data addObject:CellModel];
        
        // UiContactsFilterPhoneBook
        CellModel = [[UiContactsTabPageContactsFilterTableCellViewModel alloc] init];
        CellModel.FilterName = NSLocalizedString(@"Title_UiContactsFilterPhoneBook", nil);
        CellModel.FilterValue = UiContactsFilterPhoneBook;
        [self.Data addObject:CellModel];
        
        // UiContactsFilterLocal
        CellModel = [[UiContactsTabPageContactsFilterTableCellViewModel alloc] init];
        CellModel.FilterName = NSLocalizedString(@"Title_UiContactsFilterLocal", nil);
        CellModel.FilterValue = UiContactsFilterLocal;
        [self.Data addObject:CellModel];
        
        // UiContactsFilterBlocked
        CellModel = [[UiContactsTabPageContactsFilterTableCellViewModel alloc] init];
        CellModel.FilterName = NSLocalizedString(@"Title_UiContactsFilterBlocked", nil);
        CellModel.FilterValue = UiContactsFilterBlocked;
        [self.Data addObject:CellModel];
        
        // UiContactsFilterWhite
        CellModel = [[UiContactsTabPageContactsFilterTableCellViewModel alloc] init];
        CellModel.FilterName = NSLocalizedString(@"Title_UiContactsFilterWhite", nil);
        CellModel.FilterValue = UiContactsFilterWhite;
        [self.Data addObject:CellModel];
        
        FilterValueSignal = RACObserve(self, FilterValue);
        
        FilterValue = UiContactsFilterDirectoryLocal;
        
    }
    return self;
}

- (void) DidFilterSelected:(NSInteger) Row
{
    NSLog(@"DidFilterSelected %@",[[self.Data objectAtIndex:Row] FilterValue]);
    
    
    self.FilterValue = [[self.Data objectAtIndex:Row] FilterValue];
    
}

@end
