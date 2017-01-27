//
//  UiPreferenceServerAreaSelectTableView.m
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

#import "UiPreferenceServerAreaSelectTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceServerAreaSelectTableView ()

@property (strong, nonatomic) IBOutlet UITableView *List;

@end

@implementation UiPreferenceServerAreaSelectTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceServerAreaSelectTableViewModel alloc] init];
        
        
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
    
    @weakify(self);
    
    [[RACObserve(self.ViewModel, Rows) deliverOnMainThread] subscribeNext:^(id Areas) {
        
        @strongify(self);
        
        [self.List reloadData];
        
    }];
    
    _IsAllBinded = TRUE;
    
    
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [self.ViewModel.Rows count];
}

- (UITableViewCell *)tableView:(UITableView *)TableView cellForRowAtIndexPath:(NSIndexPath *)IndexPath
{
    UITableViewCell *Cell = [TableView dequeueReusableCellWithIdentifier:@"ServerAreaCell"];
    
    UiPreferenceServerAreaSelectTableRowViewModel *Row = self.ViewModel.Rows[IndexPath.row];
    
    UILabel *TitleLabel = (UILabel *)[Cell viewWithTag:100];
    
    [TitleLabel setText: Row.Title];
    
    
    UIImageView *CheckIcon = (UIImageView *)[Cell viewWithTag:110];
    
    [[[[RACObserve(self.ViewModel, Area) takeUntil:Cell.rac_prepareForReuseSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *Area) {
        
        if([Area intValue] == [Row.Key intValue])
            [CheckIcon setAlpha:1.0];
        else
            [CheckIcon setAlpha:0.0];
        
        
    }];
    
    return Cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)IndexPath
{
    [self.ViewModel DidCellSelected:IndexPath];
    
    [tableView deselectRowAtIndexPath:IndexPath animated:YES];
}

@end
