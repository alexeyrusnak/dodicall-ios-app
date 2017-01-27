//
//  UiPreferenceIssueTicketView.m
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

#import "UiPreferenceIssueTicketView.h"
#import "UiPreferenceIssueTicketTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiPreferencesTabNavRouter.h"
#import "UiAlertControllerView.h"

@interface UiPreferenceIssueTicketView ()
@property (weak, nonatomic) IBOutlet UIButton *BackButton;
@property (weak, nonatomic) IBOutlet UIButton *SendButton;

@property UiPreferenceIssueTicketTableView *ChildView;

@end

@implementation UiPreferenceIssueTicketView

{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceIssueTicketViewModel alloc] init];
        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
}

- (void) BindAll
{
    
    @weakify(self);
    
    // Bind Back action
    [[self.BackButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [UiPreferencesTabNavRouter ClosePreferenceTicketView];
        
        [self.ViewModel ExecuteBackAction];
        
    }];
    
    // Bind Send action
    
    //RACSignal *IsSendingProcessActive = RACObserve(self.ChildView.ViewModel, IsSendingProcessActive);
    
    /*
    RAC(self.SendButton, enabled) = [IsSendingProcessActive map:^id(NSNumber *Value) {
        return [Value boolValue]?[NSNumber numberWithInt:0]:[NSNumber numberWithInt:1];
    }];
     */
    
    [[self.SendButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [self.ChildView resignOnTap:nil];
        
        // All is valid
        if(self.ChildView.ViewModel.MessageTitleText.length > 0 && self.ChildView.ViewModel.MessageText.length > 0)
        {
            [self.ChildView.ViewModel ExecuteSendAction];
        }
        
        else
        {
            
            UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleActionSheet];
            
            if(self.ChildView.ViewModel.MessageTitleText.length > 0 && self.ChildView.ViewModel.MessageText.length == 0)
            {
                [Alert setMessage:NSLocalizedString(@"Alert_TicketMessageIsEmpty", nil)];
                
                UIPopoverPresentationController *popPresenter = [Alert popoverPresentationController];
                popPresenter.sourceView = self.ChildView.MessageTextField;
                popPresenter.sourceRect = self.ChildView.MessageTextField.bounds;
            }
            
            else if(self.ChildView.ViewModel.MessageTitleText.length == 0 && self.ChildView.ViewModel.MessageText.length > 0)
            {
                [Alert setMessage:NSLocalizedString(@"Alert_TicketTitleIsEmpty", nil)];
                
                UIPopoverPresentationController *popPresenter = [Alert popoverPresentationController];
                popPresenter.sourceView = self.ChildView.MessageTitleTextField;
                popPresenter.sourceRect = self.ChildView.MessageTitleTextField.bounds;
            }
            
            else
            {
                [Alert setMessage:NSLocalizedString(@"Alert_TicketTitleAndMessageAreEmpty", nil)];
                
                UIPopoverPresentationController *popPresenter = [Alert popoverPresentationController];
                popPresenter.sourceView = self.ChildView.MessageTextField;
                popPresenter.sourceRect = self.ChildView.MessageTextField.bounds;
            }
            
            UIAlertAction* SendAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Send", nil) style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {

                                                                     [self.ChildView.ViewModel ExecuteSendAction];
                                                                     
                                                                 }];
            
            [Alert addAction:SendAction];
            
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            
            [Alert addAction:cancelAction];
            
            [self presentViewController:Alert animated:YES completion:nil];
            
            
            
            
            
            
            
            
            
        }
        
    }];
    
    RAC(self.SendButton, enabled) = [RACSignal combineLatest:@[RACObserve(self.ChildView.ViewModel, IsFormValid),
                                                              RACObserve(self.ChildView.ViewModel, IsSendingProcessActive)] reduce:^(NSNumber *IsFormValid, NSNumber *IsSendingProcessActive)
    {

        return [NSNumber numberWithBool: [IsFormValid boolValue] && ![IsSendingProcessActive boolValue]];
        
    }];

    
    //RACObserve(self.ChildView.ViewModel, IsFormValid);
    
    _IsAllBinded = TRUE;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UiPreferenceIssueTicketTableContainerView"]) {
        self.ChildView = segue.destinationViewController;
    }
}

@end
