//
//  UiPreferenceServerAreaSelectTableViewModel.m
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

#import "UiPreferenceServerAreaSelectTableViewModel.h"
#import "AppManager.h"

@implementation UiPreferenceServerAreaSelectTableRowViewModel
@end

@implementation UiPreferenceServerAreaSelectTableViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.Areas = [[NSMutableArray alloc] init];
        
        self.Rows = [[NSMutableArray alloc] init];
        
        RACChannelTo(self, Area) = RACChannelTo([AppManager app].GlobalApplicationSettingsModel, Area);
        
        @weakify(self);
        
        [[RACObserve([AppManager app].UserSession, ServerAreas) deliverOnMainThread] subscribeNext:^(id ServerAreas) {
            
            @strongify(self);
            
            self.Areas = ServerAreas;
            
        }];
        
        
        [[RACObserve(self, Areas) deliverOnMainThread] subscribeNext:^(id Areas) {
            
            @strongify(self);
            
            [self ReloadData];
            
        }];
        
        [[AppManager app].UserSession GetAreas];
        
    }
    return self;
}

- (void) DidCellSelected:(NSIndexPath *) CellIndex
{
    NSLog(@"DidCellSelected %@",CellIndex);
    
    self.Area = ((ObjC_ServerAreaModel *)[self.Areas objectAtIndex:CellIndex.row]).Key;
}

- (void) ReloadData
{
    NSMutableArray *Rows = [[NSMutableArray alloc] init];
    
    for (ObjC_ServerAreaModel *Area in self.Areas) {
        
        UiPreferenceServerAreaSelectTableRowViewModel *Row = [[UiPreferenceServerAreaSelectTableRowViewModel alloc] init];
        
        [Row setTitle:Area.Title];
        
        [Row setKey:Area.Key];
        
        [Rows addObject:Row];
    }
    
    self.Rows = Rows;
}

@end
