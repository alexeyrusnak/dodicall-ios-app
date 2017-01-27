//
//  UiPreferenceWebView.m
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

#import "UiPreferenceWebView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiPreferencesTabNavRouter.h"

@interface UiPreferenceWebView ()

@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property (weak, nonatomic) IBOutlet UIWebView *WebView;

@property (weak, nonatomic) IBOutlet UIButton *TitleButton;

@end

@implementation UiPreferenceWebView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiPreferenceWebViewModel alloc] init];
        
        [self.TitleButton setTitle:self.ViewModel.TitleText forState:UIControlStateNormal];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
}

- (void)viewDidAppear:(BOOL)animated
{
    if(self.ViewModel.Url.length > 0)
    {
        [self NavigateTo:self.ViewModel.Url];
    }
}

- (void) BindAll
{
    
    if(_IsAllBinded)
        return;
    
    @weakify(self);
    
    [RACObserve(self.ViewModel, TitleText) subscribeNext: ^(NSString *Text) {
        
        @strongify(self);
        
        [self.TitleButton setTitle:Text forState:UIControlStateNormal];
        
    }];
    
    [RACObserve(self.ViewModel, Url) subscribeNext: ^(NSString *Url) {
        
        @strongify(self);
        
        [self NavigateTo: Url];
        
    }];
    
    [RACObserve(self.ViewModel, DataHtml) subscribeNext: ^(NSString *DataHtml) {
        
        @strongify(self);
        
        [self LoadData:DataHtml];
        
    }];
    
    
    // Bind Back action
    [[self.BackButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [UiPreferencesTabNavRouter ClosePreferenceWebView];
        
        [self.ViewModel ExecuteBackAction];
        
    }];
    
    _IsAllBinded = TRUE;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) NavigateTo:(NSString *) Url
{
    
    NSMutableURLRequest * Request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:Url]];
    [self.WebView loadRequest:Request];
    
}

- (void) LoadData:(NSString *) DataHtml
{

    [self.WebView loadHTMLString:DataHtml baseURL:nil];
    
}


@end
