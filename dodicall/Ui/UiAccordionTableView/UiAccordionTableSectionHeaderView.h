//
//  UiAccordionTableSectionHeaderView.h
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
#import "UiAccordionTableSectionHeaderViewModel.h"

@protocol UiAccordionTableSectionHeaderViewDelegate;

@interface UiAccordionTableSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic) UiAccordionTableSectionHeaderViewModel* ViewModel;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *disclosureButton;
@property (nonatomic, weak) IBOutlet id <UiAccordionTableSectionHeaderViewDelegate> delegate;


@property (nonatomic) NSInteger section;

- (void)toggleOpenWithUserAction:(BOOL)userAction;

@end

#pragma mark - SectionHeaderViewDelegate

@protocol UiAccordionTableSectionHeaderViewDelegate <NSObject>

@optional

- (void)sectionHeaderView:(UiAccordionTableSectionHeaderView *)sectionHeaderView sectionOpened:(NSInteger)section;

- (void)sectionHeaderView:(UiAccordionTableSectionHeaderView *)sectionHeaderView sectionClosed:(NSInteger)section;

@end
