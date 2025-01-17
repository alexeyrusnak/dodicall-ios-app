//
//  UiContactsRosterViewModel.h
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

#import "UiContactsRosterRowItemViewModel.h"

@interface UiContactsRosterViewModel : NSObject

@property NSMutableArray *Data;

@property NSMutableArray *DataUpdateStages;

@property NSMutableDictionary *ThreadSafeSections;

@property NSMutableArray *ThreadSafeSectionsKeys;

@property NSNumber *DataReloaded;

@property RACSignal *DataReloadedSignal;


- (void) ExecuteAcceptAction:(ObjC_ContactModel *)ContactData withAccept:(BOOL) Accept withCallback:(void (^)(BOOL))Callback;

@end
