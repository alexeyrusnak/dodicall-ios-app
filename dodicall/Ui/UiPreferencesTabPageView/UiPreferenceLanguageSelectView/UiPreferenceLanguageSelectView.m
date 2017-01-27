//
//  UiPreferenceLanguageSelectView.m
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

#import "UiPreferenceLanguageSelectView.h"
#import "UiPreferenceLanguageSelectTableView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiPreferencesTabNavRouter.h"

@interface UiPreferenceLanguageSelectView ()
@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property UiPreferenceLanguageSelectTableView *ChildView;

@end

@implementation UiPreferenceLanguageSelectView

{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceLanguageSelectViewModel alloc] init];
        
        
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
        
        if(!self.ChildView.ViewModel.WasLanguageChanged)
            [UiPreferencesTabNavRouter ClosePreferenceLanguageSelectView];
        
        [self.ChildView.ViewModel ExecuteBackAction];
        
        //[self.ViewModel ExecuteBackAction];
        
    }];
    
    _IsAllBinded = TRUE;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UiPreferenceLanguageSelectTableContainerView"]) {
        self.ChildView = segue.destinationViewController;
    }
}

@end
