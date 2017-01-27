//
//  UiPreferenceCodecsTableView.m
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

#import "UiPreferenceCodecsTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceCodecsTableView ()

@end

@implementation UiPreferenceCodecsTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceCodecsTableViewModel alloc] init];
        
        
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
    
    return [self.ViewModel.Data count];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSectionDynamicData:(NSInteger)section {
    
    return [[self.ViewModel.Data objectAtIndex:section] count];
   
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *CellIdentifier = @"UiPreferenceCodecsTableCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UiPreferenceCodecsTableCellViewModel *CellModel = (UiPreferenceCodecsTableCellViewModel *)[[self.ViewModel.Data objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    UISwitch *EnableSwitch = (UISwitch *)[cell viewWithTag:100];
    
    UILabel *CodecNameLabel = (UILabel *)[cell viewWithTag:101];
    
    // Bindings
    
    [CodecNameLabel setText:CellModel.CodecName];
    
    RAC(EnableSwitch, on) = [[RACObserve(CellModel, Enabled) distinctUntilChanged] takeUntil:cell.rac_prepareForReuseSignal];
    
    [[EnableSwitch.rac_newOnChannel takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(NSNumber *Value) {
        
        CellModel.Enabled = [Value boolValue];
        
    }];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self.ViewModel DidCellSelected:cell.reuseIdentifier];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.ViewModel.SectionItemModels objectAtIndex:section];
}

@end
