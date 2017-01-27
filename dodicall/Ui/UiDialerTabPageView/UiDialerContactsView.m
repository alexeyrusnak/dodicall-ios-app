//
//  UiDialerContactsView.m
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

#import "UiDialerContactsView.h"
#import "UiDialerContactCellModel.h"
#import "UiDialerContactCell.h"
#import "ContactsManager.h"

#define ContactCellID @"UiDialerContactCell"

@interface UiDialerContactsView ()

@property (weak, nonatomic) IBOutlet UILabel *NameLabel;
@property (weak, nonatomic) IBOutlet UITableView *ContactsTable;
@property (weak, nonatomic) IBOutlet UIImageView *DodicallImageView;
@property (weak, nonatomic) IBOutlet UIImageView *AvatarImageView;

@end

@implementation UiDialerContactsView

#pragma mark - Lifecycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.ViewModel = [UiDialerContactsViewModel new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self BindAll];
}

- (void)BindAll {
    RAC(self.NameLabel, text) = [RACObserve(self.ViewModel, Name) deliverOnMainThread];
    RAC(self.DodicallImageView, alpha) = [RACObserve(self.ViewModel, IsDodicall) deliverOnMainThread];
    
    @weakify(self);
    [[[RACObserve(self.ViewModel, ContactRows) ignore:nil] deliverOnMainThread] subscribeNext:^(id x) {
        @strongify(self);
        [self.ContactsTable reloadData];
    }];
    
    RAC(self.AvatarImageView, image) = [[ContactsManager AvatarImageSignalForPathSignal:RACObserve(self.ViewModel, AvatarPath) WithTakeUntil:[RACSignal never]] deliverOnMainThread];
}

#pragma mark - Table View
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self ViewModel] ContactRows] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:ContactCellID];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UiDialerContactCell *Cell = (UiDialerContactCell *)cell;
    UiDialerContactCellModel *CellModel = [[[self ViewModel] ContactRows] objectAtIndex:[indexPath row]];
    
    [Cell BindViewModel:CellModel];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.ViewModel.SelectedRow = [indexPath row];
}

@end
