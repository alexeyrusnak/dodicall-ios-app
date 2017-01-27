//
//  UiContactsTabPageContactsListView.h
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

#import "UiContactsSkeleton.h"
#import "UiContactsTabPageContactsListViewModel.h"

@class UiContactsListView;
@class UiContactsTabPageContactsFilterTableView;

@interface UiContactsTabPageContactsListView : UIViewController

@property UiContactsTabPageContactsListViewModel *ViewModel;

@property (weak, nonatomic) UiContactsListView *ChildContactsListView;

@property (weak, nonatomic) UiContactsTabPageContactsFilterTableView *ChildFilterListMenuView;

//@property (weak, nonatomic) IBOutlet UINavigationBar *NavigationBar;


#pragma mark Filter menu delegates

@property (weak, nonatomic) IBOutlet UIView *FilterListMenu;

@property (weak, nonatomic) IBOutlet UIButton *FilterTitleButton;

@property RACSignal *FilterTitleButtonTapSignal;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *FilterListMenuOverlayTapGesture;

@property RACSignal *FilterListMenuOverlayTapGestureSignal;

- (void) ShowFilterList;
- (void) HideFilterList;
- (void) ToggleFilterList;

@end
