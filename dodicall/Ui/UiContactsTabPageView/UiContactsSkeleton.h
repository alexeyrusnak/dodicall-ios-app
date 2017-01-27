//
//  UiContactsSkeleton.h
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

//#import "AppManager.h"

// Contacts filter enum
#define UiContactsFilterDefault       		@"UiContactsFilterAll"
#define UiContactsFilterAll            		@"UiContactsFilterAll"
#define UiContactsFilterDirectoryLocal 		@"UiContactsFilterDirectoryLocal"
#define UiContactsFilterDirectoryRemote 	@"UiContactsFilterDirectoryRemote"
#define UiContactsFilterPhoneBook       	@"UiContactsFilterPhoneBook"
#define UiContactsFilterLocal               @"UiContactsFilterLocal"
#define UiContactsFilterBlocked             @"UiContactsFilterBlocked"
#define UiContactsFilterWhite               @"UiContactsFilterWhite"
typedef NSString*               			UiContactsFilter;

// Contacts list modes enum
#define UiContactsListModeNormal                    @"UiContactsListModeNormal"
#define UiContactsListModeMultySelectable           @"UiContactsListModeMultySelectable"
#define UiContactsListModeMultySelectableForChat    @"UiContactsListModeMultySelectableForChat"
#define UiContactsListModeCallTransfer              @"UiContactsListModeCallTransfer"
typedef NSString*               			UiContactsListMode;

// Contacts tab page contacts list modes enum
#define UiContactsTabPageContactsListViewModeNormal         @"UiContactsTabPageContactsListViewModeNormal"
#define UiContactsTabPageContactsListViewModeCallTransfer   @"UiContactsTabPageContactsListViewModeCallTransfer"
typedef NSString*               			UiContactsTabPageContactsListViewMode;

/*
#import "UiContactProfileView.h"

#import "UiContactsTabPageContactsFilterTableCellViewModel.h"
#import "UiContactsTabPageContactsFilterTableViewModel.h"
#import "UiContactsTabPageContactsFilterTableView.h"
#import "UiContactsTabPageContactsListView.h"
#import "UiContactsListView.h"
#import "UiContactsTabPageView.h"
*/

