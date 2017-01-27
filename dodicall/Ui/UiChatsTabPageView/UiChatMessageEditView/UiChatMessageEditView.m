//
//  UiChatMessageEditView.m
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

#import "UiChatMessageEditView.h"

@interface UiChatMessageEditView (){
    BOOL _IsBinded;
}

@property (weak, nonatomic) IBOutlet UITextView *MessageTextField;
@property (weak, nonatomic) IBOutlet UIButton *DoneButton;
@property (weak, nonatomic) IBOutlet UIButton *CancelButton;

@end

@implementation UiChatMessageEditView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder])
    {
        self.ViewModel = [UiChatMessageEditViewModel new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self BindAll];
    
    [self.MessageTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) BindAll
{
    if(_IsBinded)
        return;
    
    RAC(self.MessageTextField, text) = [RACObserve(self.ViewModel, OldMessageText) deliverOnMainThread];
    
    RAC(self.ViewModel, NewMessageText) = [self.MessageTextField.rac_textSignal merge:RACObserve(self.MessageTextField, text)];
    
    RAC(self.DoneButton, enabled) = [[RACSignal
     combineLatest:@[RACObserve(self.ViewModel, MessageTextChanged), RACObserve(self.ViewModel, MessageTextIsEmpty)]
     reduce:^NSNumber*(NSNumber *MessageTextChanged, NSNumber *MessageTextIsEmpty){
         return @([MessageTextChanged boolValue] && ![MessageTextIsEmpty boolValue]);
     }] deliverOnMainThread];
    
    @weakify(self);
    
    [[self.DoneButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x)
    {
        @strongify(self);
        [self.ViewModel UpdateMessageText];
        [self.ViewModel CloseView];
    }];
    
    [[self.CancelButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x)
    {
        @strongify(self);
        [self.ViewModel CloseView];
    }];
}

@end
