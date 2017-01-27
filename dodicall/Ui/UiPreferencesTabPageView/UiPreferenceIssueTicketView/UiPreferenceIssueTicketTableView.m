//
//  UiPreferenceIssueTicketTableView.m
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

#import "UiPreferenceIssueTicketTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceIssueTicketTableView ()

//@property (weak, nonatomic) IBOutlet UITextField *MessageTitleTextField;

@property (weak, nonatomic) IBOutlet UILabel *MessageTitleTextFieldPlaceholder;

//@property (weak, nonatomic) IBOutlet UITextView *MessageTextField;

@property (weak, nonatomic) IBOutlet UILabel *MessageTextFieldPlaceholder;


@property (weak, nonatomic) IBOutlet UISwitch *CallsLogEnableSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *CallsHistoryLogEnableSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *CallsQualityLogEnableSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *ChatLogEnableSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *DbLogEnableSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *ServerLogEnableSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *TraceLogEnableSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *UiLogEnableSwitch;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;

@property (nonatomic, assign) id currentResponder;


@end

@implementation UiPreferenceIssueTicketTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceIssueTicketTableViewModel alloc] init];
        
        self.ViewModel.View = self;
        
        
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
    
    [RACObserve(self.ViewModel, MessageTitleText) subscribeNext:^(NSString *Text) {
        
        @strongify(self);
        
        [self.MessageTitleTextField setText:Text];
        
        if(Text.length > 0)
            [self.MessageTitleTextFieldPlaceholder setHidden:YES];
        else if(self.currentResponder != self.MessageTitleTextField)
            [self.MessageTitleTextFieldPlaceholder setHidden:NO];
        
    }];
    
    RAC(self.ViewModel, MessageTitleText) = self.MessageTitleTextField.rac_textSignal;
    
    
    [RACObserve(self.ViewModel, MessageText) subscribeNext:^(NSString *Text) {
        
        @strongify(self);
        
        [self.MessageTextField setText:Text];
        
        if(Text.length > 0)
            [self.MessageTextFieldPlaceholder setHidden:YES];
        else if(self.currentResponder != self.MessageTextField)
            [self.MessageTextFieldPlaceholder setHidden:NO];
        
    }];
    
    RAC(self.ViewModel, MessageText) = self.MessageTextField.rac_textSignal;
    
    
    
    RAC(self.CallsLogEnableSwitch, on) = RACObserve(self.ViewModel, CallsLogEnabled);
    RAC(self.ViewModel, CallsLogEnabled) = self.CallsLogEnableSwitch.rac_newOnChannel;
    
    RAC(self.CallsHistoryLogEnableSwitch, on) = RACObserve(self.ViewModel, CallsHistoryLogEnabled);
    RAC(self.ViewModel, CallsHistoryLogEnabled) = self.CallsHistoryLogEnableSwitch.rac_newOnChannel;
    
    RAC(self.CallsQualityLogEnableSwitch, on) = RACObserve(self.ViewModel, CallsQualityLogEnabled);
    RAC(self.ViewModel, CallsQualityLogEnabled) = self.CallsQualityLogEnableSwitch.rac_newOnChannel;
    
    RAC(self.ChatLogEnableSwitch, on) = RACObserve(self.ViewModel, ChatLogEnabled);
    RAC(self.ViewModel, ChatLogEnabled) = self.ChatLogEnableSwitch.rac_newOnChannel;
    
    RAC(self.DbLogEnableSwitch, on) = RACObserve(self.ViewModel, DbLogEnabled);
    RAC(self.ViewModel, DbLogEnabled) = self.DbLogEnableSwitch.rac_newOnChannel;
    
    RAC(self.ServerLogEnableSwitch, on) = RACObserve(self.ViewModel, ServerLogEnabled);
    RAC(self.ViewModel, ServerLogEnabled) = self.ServerLogEnableSwitch.rac_newOnChannel;
    
    RAC(self.TraceLogEnableSwitch, on) = RACObserve(self.ViewModel, TraceLogEnabled);
    RAC(self.ViewModel, TraceLogEnabled) = self.TraceLogEnableSwitch.rac_newOnChannel;
    
    RAC(self.UiLogEnableSwitch, on) = RACObserve(self.ViewModel, UiLogEnabled);
    RAC(self.ViewModel, UiLogEnabled) = self.UiLogEnableSwitch.rac_newOnChannel;
    
    [[self.ViewTapGesture rac_gestureSignal] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [self resignOnTap:nil];
        
    }];
    
    _IsAllBinded = TRUE;
    
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self.ViewModel DidCellSelected:cell.reuseIdentifier];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    self.currentResponder = textField;
    
    [self.MessageTitleTextFieldPlaceholder setHidden:YES];
    
}

- (void)textViewDidBeginEditing:(UITextView *)TextView {
    
    self.currentResponder = TextView;
    
    [self.MessageTextFieldPlaceholder setHidden:YES];
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(![textField hasText])
        [self.MessageTitleTextFieldPlaceholder setHidden:NO];
}

- (void)textViewDidEndEditing:(UITextView *)TextView
{
    if(![TextView hasText])
        [self.MessageTextFieldPlaceholder setHidden:NO];
}

- (void)resignOnTap:(id)iSender
{
    [self.currentResponder resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)TextField
{
    
    [self resignOnTap:nil];
    
    return YES;
}

-(BOOL)textViewShouldReturn:(UITextView *)TextView
{
    
    [self resignOnTap:nil];
    
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self resignOnTap:nil];
}



@end
