//
//  UiPreferenceStatusSetTableView.m
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

#import "UiPreferenceStatusSetTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiPreferenceStatusSetTableView ()

@property (weak, nonatomic) IBOutlet UIImageView *StatusONLINECheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *StatusOFFLINECheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *StatusDNDCheckIcon;

@property (weak, nonatomic) IBOutlet UIImageView *StatusINVISIBLECheckIcon;

@property (weak, nonatomic) IBOutlet UITextField *StstusTextField;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;

@property (nonatomic, assign) id currentResponder;


@end

@implementation UiPreferenceStatusSetTableView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceStatusSetTableViewModel alloc] init];
        
        
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
    
    RACSignal *UiUserStatusSignal = [RACObserve(self.ViewModel, UiUserStatus) deliverOnMainThread];
    
    RAC(self.StatusONLINECheckIcon, alpha) = [UiUserStatusSignal map:^id(NSNumber *UiUserStatus) {
        return ([UiUserStatus integerValue] == BaseUserStatusOnline) ? @1.0 : @0.0;
    }];
    
    RAC(self.StatusOFFLINECheckIcon, alpha) = [UiUserStatusSignal map:^id(NSString *UiUserStatus) {
        return ([UiUserStatus integerValue] == BaseUserStatusOffline) ? @1.0 : @0.0;
    }];
    
    /*
    RAC(self.StatusDNDCheckIcon, alpha) = [UiUserStatusSignal map:^id(NSString *UiUserStatusString) {
        return [UiUserStatusString isEqualToString:@"DND"] ? @1.0 : @0.0;
    }];
     */
    
    RAC(self.StatusDNDCheckIcon, alpha) = [UiUserStatusSignal map:^id(NSString *UiUserStatus) {
        return ([UiUserStatus integerValue] == BaseUserStatusDnd) ? @1.0 : @0.0;
    }];
    
    RAC(self.StatusINVISIBLECheckIcon, alpha) = [UiUserStatusSignal map:^id(NSString *UiUserStatus) {
        return ([UiUserStatus integerValue] == BaseUserStatusHidden) ? @1.0 : @0.0;
    }];
    
    RAC(self.StstusTextField, text) = [RACObserve(self.ViewModel, UiUserTetxStatus) deliverOnMainThread];
    
    RAC(self.ViewModel, UiUserTetxStatus) = self.StstusTextField.rac_textSignal;
    
    @weakify(self);
    
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
    
}

- (void)resignOnTap:(id)iSender {
    [self.currentResponder resignFirstResponder];
    
    self.currentResponder = nil;
}

-(BOOL)textFieldShouldReturn:(UITextField *)TextField
{
    
    [self resignOnTap:nil];
    
    return YES;
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if(self.currentResponder)
        return YES;
    
    return NO;
}


@end
