//
//  UiChatSettingsView.m
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

#import "UiChatSettingsView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiChatSettingsCellModel.h"
#import "UiChatsTabNavRouter.h"

@interface UiChatSettingsView () {
    BOOL isBinded;
}
@property (weak, nonatomic) IBOutlet UITableView *SettingsTable;
@property (weak, nonatomic) IBOutlet UILabel *ChatTitle;

@end

@implementation UiChatSettingsView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.ViewModel = [UiChatSettingsViewModel new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
}

- (void) BindAll {
    
    if(isBinded)
        return;
    
    @weakify(self);
    [[RACObserve(self.ViewModel, RowsArray) deliverOnMainThread] subscribeNext:^(id x) {
        @strongify(self);
        [self.SettingsTable reloadData];
    }];
    
    [[RACObserve(self.ViewModel, ChatTitle) deliverOnMainThread] subscribeNext:^(NSString *Text) {
        @strongify(self);
        [self.ChatTitle setText:Text];
    }];
}
- (IBAction)BackButtonAction:(id)sender {
    [UiChatsTabNavRouter CloseChatSettingsWhenBackAction];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.ViewModel.RowsArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UiChatSettingsCellModel *cellVM = [self.ViewModel.RowsArray objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellVM.CellId];
    
    UILabel *fieldName = (UILabel *)[cell viewWithTag:100];
    [fieldName setText:cellVM.FieldName];
    
    if([cellVM.CellId isEqualToString:@"UiChatSettingsCell"]) {
        UILabel *fieldValue = (UILabel *)[cell viewWithTag:101];
        [fieldValue setText:cellVM.FieldValue];
    }

    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(![self.ViewModel.IsChatActive boolValue])
        return;
    
    UiChatSettingsCellModel *cellModel = [self.ViewModel.RowsArray objectAtIndex:indexPath.row];
    
    if(cellModel.SelectCommand)
        [cellModel.SelectCommand execute:nil];
}

@end
