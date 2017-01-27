//
//  UiContactsTabPageContactsListView.m
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

#import "UiContactsTabPageContactsListView.h"
#import "UiContactsListView.h"
#import "UiContactsTabPageContactsFilterTableView.h"
#import "UiContactsTabPageContactsFilterTableViewModel.h"
#import <NUI/NUIRenderer.h>
#import "UiButtonWithBadgeView.h"

#import "UiNavRouter.h"
#import "UiCallsNavRouter.h"

@interface UiContactsTabPageContactsListView ()

@property (weak, nonatomic) IBOutlet UiButtonWithBadgeView *RosterButton;

@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property (weak, nonatomic) IBOutlet UIButton *DirectorySearchButton;

@end

@implementation UiContactsTabPageContactsListView
{
    bool shouldDisplayDropShape;
    float fadeAlpha;
    float trianglePlacement;
    
    BOOL _IsAllBinded;
}



- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel = [[UiContactsTabPageContactsListViewModel alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self BindAll];
    
    shouldDisplayDropShape = NO;
    fadeAlpha = 0.1f;
    trianglePlacement = 0.87f;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    
    // Filter menu delegates
    self.FilterTitleButtonTapSignal = [self.FilterTitleButton rac_signalForControlEvents: UIControlEventTouchUpInside];
    
    self.FilterListMenuOverlayTapGestureSignal = [self.FilterListMenuOverlayTapGesture rac_gestureSignal];
    
    @weakify(self);
    
    [self.FilterTitleButtonTapSignal subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self ToggleFilterList];
        
        [self.ChildContactsListView ResignOnTap:nil];
        
    }];
    
    [self.FilterListMenuOverlayTapGestureSignal subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self HideFilterList];
        
        [self.ChildContactsListView ResignOnTap:nil];
        
    }];
    
    [[self.BackButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        @strongify(self);
        
        if([self.ViewModel.Mode isEqualToString:UiContactsTabPageContactsListViewModeCallTransfer])
        {
            [UiCallsNavRouter CloseCallTransferTabPageView];
        }
        
    }];
    
    
    [self.ChildFilterListMenuView.ViewModel.FilterValueSignal subscribeNext:^(UiContactsFilter Value) {
        
        @strongify(self);
        
        [self.ChildContactsListView.ViewModel SetFilter:Value];
        
        NSString *FilterTitleButtonTitle = [NSString stringWithFormat:@"Title_%@", Value];
        
        [self.FilterTitleButton setTitle:NSLocalizedString(FilterTitleButtonTitle, nil) forState:UIControlStateNormal];
        [self.FilterTitleButton setTitle:NSLocalizedString(FilterTitleButtonTitle, nil) forState:UIControlStateSelected];
        
        [NUIRenderer renderButton:self.FilterTitleButton];
        
        [self HideFilterList];
        
    }];
    
    [[RACObserve(self.ViewModel, ContactsRosterButtonBadgeValue) deliverOnMainThread] subscribeNext:^(NSString *Value) {
        
        @strongify(self);
        
        [self.RosterButton setBadgeValue:Value];
        
    }];
    
    
    [[RACObserve(self.ViewModel, Mode) deliverOnMainThread] subscribeNext:^(UiContactsTabPageContactsListViewMode Mode) {
        
        @strongify(self);
        
        if([Mode isEqualToString:UiContactsTabPageContactsListViewModeNormal])
        {
            
            NSMutableArray *ToolbarButtonsLeft = [self.navigationItem.leftBarButtonItems mutableCopy];
            
            [ToolbarButtonsLeft removeObjectAtIndex:1];
            [self.navigationItem setLeftBarButtonItems:ToolbarButtonsLeft animated:YES];
        }
        
        else if([Mode isEqualToString:UiContactsTabPageContactsListViewModeCallTransfer])
        {
            
            NSMutableArray *ToolbarButtonsLeft = [self.navigationItem.leftBarButtonItems mutableCopy];
            
            [ToolbarButtonsLeft removeObjectAtIndex:0];
            [self.navigationItem setLeftBarButtonItems:ToolbarButtonsLeft animated:YES];
            
            
            NSMutableArray *ToolbarButtonsRight = [self.navigationItem.rightBarButtonItems mutableCopy];
            
            [ToolbarButtonsRight removeObjectAtIndex:0];
            [self.navigationItem setRightBarButtonItems:ToolbarButtonsRight animated:YES];
        }
            
        
        
    }];

    _IsAllBinded = TRUE;
}

#pragma mark Filter menu delegates

- (void) ShowFilterList {
    
    self.FilterTitleButton.selected = YES;
    
    [self.FilterListMenu setAlpha:0.0f];
    self.FilterListMenu.hidden = NO;
    
    //float containerAlpha = fadeAlpha;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.FilterListMenu setAlpha:1.0f];
                     }
                     completion:^(BOOL finished){
                     }];
    
    [UIView commitAnimations];
    
}

- (void) HideFilterList {
    
    self.FilterTitleButton.selected = NO;
    
    //float containerAlpha = 1.0f;
    
    [UIView animateWithDuration:0.3f
                          delay:0.05f
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.FilterListMenu setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         self.FilterListMenu.hidden = YES;
                     }];
    
    [UIView commitAnimations];
    
}

- (void) ToggleFilterList {
    if(self.FilterListMenu.hidden) {
        [self ShowFilterList];
    } else {
        [self HideFilterList];
    }
}

#pragma mark - Segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"UiContactsTabPageListContainerViewSegue"])
    {
        
        self.ChildContactsListView = segue.destinationViewController;
        self.ChildContactsListView.ParentView = self;
        
        [UiNavRouter NavRouter].ContactsTabPageContactsListView = self;
        
        if([self.ViewModel.Mode isEqualToString:UiContactsTabPageContactsListViewModeCallTransfer])
           [self.ChildContactsListView.ViewModel setMode:UiContactsListModeCallTransfer];
        
    }
    
    else if ([segue.identifier isEqualToString:@"UiContactsTabPageFilterMenuListContainerViewSegue"])
    {
        
        self.ChildFilterListMenuView = segue.destinationViewController;
        self.ChildFilterListMenuView.ParentView = self;
        
    }
    
    else
    {
        [UiContactsTabNavRouter PrepareForSegue:segue sender:sender contactModel:nil];
    }

    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)Identifier sender:(id)Sender
{
    
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        if([Identifier isEqualToString:@"UiContactsTabPageListContainerViewSegue"] || [Identifier isEqualToString:@"UiContactsTabPageMenuFilterContainerViewSegue"])
        {

            double delayInSeconds = 0.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                [self performSegueWithIdentifier:Identifier sender:Sender];
                
            });
            
            
            return NO;
            
        }
    }
    
    return YES;
}

@end
