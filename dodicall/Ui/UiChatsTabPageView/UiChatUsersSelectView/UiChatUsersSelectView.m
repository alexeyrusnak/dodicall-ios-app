//
//  UiChatUsersSelectView.m
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

#import "UiChatUsersSelectView.h"
#import "UiContactsListView.h"

@interface UiChatUsersSelectView ()
{
    BOOL _IsBinded;
}

@property (weak, nonatomic) UiContactsListView *ContactsList;

@property (weak, nonatomic) IBOutlet UIButton *BackBtn;
@property (weak, nonatomic) IBOutlet UIButton *DoneBtn;
@property (weak, nonatomic) IBOutlet UILabel *TitleLabel;

@end

@implementation UiChatUsersSelectView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        
        self.ViewModel =  [[UiChatUsersSelectViewModel alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self BindAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)BindAll
{
    if (_IsBinded)
        return;
    
    @weakify(self);
    
    self.BackBtn.rac_command = self.ViewModel.BackAction;
    self.DoneBtn.rac_command = self.ViewModel.DoneAction;
    
    [[[RACSignal combineLatest:@[RACObserve(self.ViewModel, IsValid),
                                 RACObserve(self.ViewModel, IsActive),
                                 RACObserve(self.ViewModel, IsNewChat)]]
        deliverOnMainThread]
        subscribeNext:^(RACTuple *Tuple) {
            RACTupleUnpack(NSNumber *IsValid, NSNumber *IsActive, NSNumber *IsNewChat) = Tuple;
            @strongify(self);
            
            if([IsActive boolValue]||[IsNewChat boolValue])
                [self.DoneBtn setEnabled:[IsValid boolValue]];
            else
                [self.DoneBtn setEnabled:NO];
            
        }];

    
    [[RACObserve(self.ViewModel, IsValid) deliverOnMainThread] subscribeNext:^(NSNumber *Valid) {
        
        @strongify(self);
        
        if([Valid boolValue]) {
            [self.DoneBtn setEnabled:YES];
        }
        
        else {
            [self.DoneBtn setEnabled:NO];
        }
        
    }];
    
    [[RACObserve(self.ViewModel, ChatTitle) deliverOnMainThread] subscribeNext:^(NSString *Title) {
        @strongify(self);
        [self.TitleLabel setText:Title];
    }];
    
    _IsBinded = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender
{
    if([segue.identifier isEqualToString:@"UiChatUsersSelectContactsListEmbedSegue"])
    {
        UiContactsListView *ContactsList = (UiContactsListView *)[segue destinationViewController];
        
        [self.ViewModel setContactsListModel:ContactsList.ViewModel];
        
        [self.ViewModel Setup];
                                            
    }
    
    
}

@end
