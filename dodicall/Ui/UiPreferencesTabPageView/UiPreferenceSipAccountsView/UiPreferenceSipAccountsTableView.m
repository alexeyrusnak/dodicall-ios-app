//
//  UiPreferenceSipAccountsTableView.m
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

#import "UiPreferenceSipAccountsTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceSipAccountsTableView ()

@end

@implementation UiPreferenceSipAccountsTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceSipAccountsTableViewModel alloc] init];
        
        
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSectionDynamicData:(NSInteger)section
{

    return [[self.ViewModel.Data[section][@"Settings"] allKeys] count];
   
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    NSArray *Keys = [self.ViewModel.Data[indexPath.section][@"Settings"] allKeys];
    id AKey = [Keys objectAtIndex:indexPath.row];
    id AnObject = [self.ViewModel.Data[indexPath.section][@"Settings"] objectForKey:AKey];
    
    NSString * CellIdentifier = [NSString stringWithFormat:@"UiPreferenceSipAccountsTableCell%@",AKey];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    if([AKey isEqualToString:@"IsDefault"])
    {
        UISwitch *IsDefaultSwitch = (UISwitch *)[cell viewWithTag:100];

        // Bindings
        RAC(IsDefaultSwitch, on) = [[RACObserve(self.ViewModel, Data) map:^id(NSDictionary *dic) {
            
            return AnObject;
            
        }] takeUntil:cell.rac_prepareForReuseSignal];
        
        @weakify(self);
        
        [[IsDefaultSwitch.rac_newOnChannel takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(id Value) {
            
            @strongify(self);
            
            [self.ViewModel.Data[indexPath.section][@"Settings"] setObject:Value forKey:AKey];
            
            if((BOOL) Value)
            {
                
                [IsDefaultSwitch setEnabled:NO];
                
                for (int i = 0; i < [self.ViewModel.Data count]; i++)
                {
                    if(i != indexPath.section)
                        [self.ViewModel.Data[i][@"Settings"] setObject:@NO forKey:AKey];
                }
            }
            else
            {
                [IsDefaultSwitch setEnabled:YES];
            }
            
            [self.ViewModel SaveChanges];
            
        }];
        
        if([self.ViewModel.Data count] < 2)
            [IsDefaultSwitch setEnabled:NO];
        else if(!IsDefaultSwitch.on)
            [IsDefaultSwitch setEnabled:YES];
        else
            [IsDefaultSwitch setEnabled:NO];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self.ViewModel DidCellSelected:cell.reuseIdentifier];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.ViewModel.Data[section][@"Title"];
}

@end
