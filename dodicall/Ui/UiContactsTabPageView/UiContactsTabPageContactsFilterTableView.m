//
//  UiContactsTabPageContactsFilterTableView.m
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

#import "UiContactsTabPageContactsFilterTableView.h"
#import "UiContactsTabPageContactsFilterTableViewModel.h"
#import "UiContactsTabPageContactsFilterTableCellViewModel.h"

@interface UiContactsTabPageContactsFilterTableView ()


@end

@implementation UiContactsTabPageContactsFilterTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiContactsTabPageContactsFilterTableViewModel alloc] init];
        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
}

- (void) BindAll
{
    
    if(_IsAllBinded)
        return;
    
    
    _IsAllBinded = TRUE;
    
    
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.ViewModel.Data count];
   
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *CellIdentifier = @"UiContactsTabPageContactsFilterTableCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UiContactsTabPageContactsFilterTableCellViewModel *CellModel = (UiContactsTabPageContactsFilterTableCellViewModel *)[self.ViewModel.Data objectAtIndex:indexPath.row];
    
    UILabel *FilterName = (UILabel *)[cell viewWithTag:100];
    
    FilterName.text = CellModel.FilterName;
    
    UIImageView *FilterImageCheckIcon = (UIImageView *)[cell viewWithTag:101];
    
    // Bindings
    RAC(FilterImageCheckIcon, alpha) = [[self.ViewModel.FilterValueSignal map:^id(NSString *FilterValue) {
        return ([FilterValue isEqualToString:CellModel.FilterValue]) ? @1.0 : @0.0;
    }] takeUntil:cell.rac_prepareForReuseSignal];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    [self.ViewModel DidFilterSelected:indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
