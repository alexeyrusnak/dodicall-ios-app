//
//  UiChatsListViewModel.h
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

#import "UiChatsListRowItemViewModel.h"

@interface UiChatsListViewModel : NSObject

@property NSMutableArray *Rows;

@property NSMutableArray *RowsUpdateStages;

@property NSMutableArray *ThreadSafeRows;

@property NSNumber *DataReloaded;

@property RACSignal *DataReloadedSignal;

@property NSString *SearchText;

@property NSNumber *EditModeEnabled;

@property NSNumber *SelectedCellsNumber;

@property NSMutableArray *DisposableRacArr;

@property NSMutableArray<ObjC_ChatModel *> *SelectedChats;

//@property RACSignal *XmppStatusesSignal;

- (void) SetSearchTextFilter:(NSString *)Search;

- (void) EnableEditMode: (BOOL) Enabled;

- (void) SwitchEditMode;

- (void) SelectCell:(BOOL) Selected withIndexPath:(NSIndexPath *) IndexPath;

- (ObjC_ChatModel *) CreateFakeNewChatModel;

- (void) ClearSelectedChats;

@end
