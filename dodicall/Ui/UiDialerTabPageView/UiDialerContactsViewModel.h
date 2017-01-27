//
//  UiDialerContactsViewModel.h
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
#import "ObjC_ContactModel.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiDialerContactsViewModel : NSObject

@property (strong, nonatomic) ObjC_ContactModel *ContactModel;
@property (strong, nonatomic) NSMutableArray *ContactRows;
@property (strong, nonatomic) NSString *Name;
@property (assign) NSInteger SelectedRow;
@property (strong, nonatomic) NSString *WrittenNumber;
@property (strong, nonatomic) NSString *SelectedNumber;
@property (strong, nonatomic) NSNumber *IsDodicall;
@property (strong, nonatomic) NSString *AvatarPath;

@end
