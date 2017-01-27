//
//  UiChatTitleSettingsView.m
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

#import "UiChatTitleSettingsView.h"

@interface UiChatTitleSettingsView() {
    BOOL _IsBinded;
}

@property (weak, nonatomic) IBOutlet UITextField *TitleTextField;
@property (weak, nonatomic) IBOutlet UIButton *DoneButton;
@property (weak, nonatomic) IBOutlet UIButton *BackButton;
@property (weak, nonatomic) IBOutlet UIButton *DeleteButton;

@end

@implementation UiChatTitleSettingsView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.ViewModel = [UiChatTitleSettingsViewModel new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ValidateTextFieldLength) name:UITextFieldTextDidChangeNotification object:nil];
    
    [self.TitleTextField becomeFirstResponder];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

- (void) BindAll {
    if(_IsBinded)
        return;
    
    RAC(self.ViewModel, NewTitle) = [self.TitleTextField.rac_textSignal merge:RACObserve(self.TitleTextField, text)];
    RAC(self.DoneButton, enabled) = [RACObserve(self.ViewModel, TitleChanged) deliverOnMainThread];
    RAC(self.DeleteButton, enabled) = [[RACObserve(self.ViewModel, TitleIsEmpty) not] deliverOnMainThread];
    
    
    @weakify(self);
    
    [[[RACObserve(self.ViewModel, HasCustomTitle)
        filter:^BOOL(NSNumber *HasCustomTitle) {
            return [HasCustomTitle boolValue];
        }]
        deliverOnMainThread]
        subscribeNext:^(NSNumber *HasCustomTitle) {
            @strongify(self);
            [self.TitleTextField setText:self.ViewModel.ChatModel.Title];
        }];
    
    
    [[self.DoneButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self.ViewModel UpdateChatTitle];
        [self.ViewModel CloseView];
    }];
    
    [[self.BackButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self.ViewModel CloseView];
    }];
    
    [[self.DeleteButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self.TitleTextField setText:@""];
    }];
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if(range.length + range.location > textField.text.length)
        return NO;
    
    return YES;
}

- (void)ValidateTextFieldLength {
    if(self.TitleTextField.text.length > 30)
        [self.TitleTextField setText:[self.TitleTextField.text substringToIndex:30]];
    
}


@end
