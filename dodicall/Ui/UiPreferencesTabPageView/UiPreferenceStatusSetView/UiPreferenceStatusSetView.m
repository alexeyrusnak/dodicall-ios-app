//
//  UiPreferenceStatusSetView.m
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

#import "UiPreferenceStatusSetView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "UiPreferencesTabNavRouter.h"
#import "UiPreferenceStatusSetTableView.h"

@interface UiPreferenceStatusSetView ()

@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property (weak, nonatomic) IBOutlet UIButton *DoneButton;

@end

@implementation UiPreferenceStatusSetView

{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceStatusSetViewModel alloc] init];
        
        
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
        
        [self.ViewModel ExecuteCancelAction];
        
        if(self.CallbackOnBackAction)
        {
            self.CallbackOnBackAction();
        }
        else
        {
            [UiPreferencesTabNavRouter ClosePreferenceStatusSetView];
        }
        
        
        
    }];
    
    [[self.DoneButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [self.ViewModel ExecuteSaveAction];
        
        if(self.CallbackOnBackAction)
        {
            self.CallbackOnBackAction();
        }
        else
        {
            [UiPreferencesTabNavRouter ClosePreferenceStatusSetView];
        }
        
    }];
    
    _IsAllBinded = YES;
    
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"UiPreferenceStatusSetTableViewEmbed"]) {
        self.ViewModel.SetStatusTableViewModel = [(UiPreferenceStatusSetTableView *)segue.destinationViewController ViewModel];
    }
}

@end
