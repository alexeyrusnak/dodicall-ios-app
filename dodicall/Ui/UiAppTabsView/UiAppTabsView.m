//
//  UiAppTabsView.m
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

#import "UiAppTabsView.h"
#import "UiLogger.h"
#import "UiTabBarItemView.h"
#import "NUIRenderer.h"

#import "HistoryManager.h"

@interface UiAppTabsView ()

@end

@implementation UiAppTabsView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel = [[UiAppTabsViewModel alloc] init];
        
        /*
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate:)
                                                     name:@"UIDeviceOrientationDidChangeNotification" object:nil];
         */
        
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self BindAll];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify(self);
    
    [[RACObserve(self.ViewModel, ContactsTabBadgeValue) deliverOnMainThread] subscribeNext:^(NSString *Value) {
        
        @strongify(self);
        
        [(UiTabBarItemView *)[self.tabBar.items objectAtIndex:UiAppTabsViewTabIndexCobtacts] setBadgeValue:Value];
        
    }];
    
    [[RACObserve(self.ViewModel, ChatsTabBadgeValue) deliverOnMainThread] subscribeNext:^(NSString *Value) {
        
        @strongify(self);
        
        [(UiTabBarItemView *)[self.tabBar.items objectAtIndex:UiAppTabsViewTabIndexChats] setBadgeValue:Value];
        
    }];
    
    [[RACObserve(self.ViewModel, HistoryTabBadgeValue) deliverOnMainThread] subscribeNext:^(NSString *Value) {
        
        @strongify(self);
        
        [(UiTabBarItemView *)[self.tabBar.items objectAtIndex:UiAppTabsViewTabIndexHistory] setBadgeValue:Value];
        
    }];
    
    [[RACObserve(self.ViewModel, VoipTabIconName) deliverOnMainThread] subscribeNext:^(NSString *Value) {
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            
            UiTabBarItemView *TabBarItem = (UiTabBarItemView *)[self.tabBar.items objectAtIndex:UiAppTabsViewTabIndexCall];
            
            [TabBarItem setImage:[UIImage imageNamed:Value]];
            [TabBarItem setSelectedImage:TabBarItem.image];
            
            [NUIRenderer renderTabBarItem:TabBarItem withClass:@"TabBarItem"];
            
        //});
    }];
    
    [[RACObserve(self.ViewModel, ChatTabIconName) deliverOnMainThread] subscribeNext:^(NSString *Value) {
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            
            UiTabBarItemView *TabBarItem = (UiTabBarItemView *)[self.tabBar.items objectAtIndex:UiAppTabsViewTabIndexChats];
            
            [TabBarItem setImage:[UIImage imageNamed:Value]];
            [TabBarItem setSelectedImage:TabBarItem.image];
            
            [NUIRenderer renderTabBarItem:TabBarItem withClass:@"TabBarItem"];
            
        //});
    }];
    
    _IsAllBinded = YES;
}

/*
- (void) didRotate:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [NUIRenderer renderTabBar:self.tabBar withClass:@"TabBar"];
        
    });
}
 */


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [NUIRenderer renderTabBar:self.tabBar withClass:@"TabBar"];
        
    });
    
 
}


#pragma mark - Segues

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiAppTabsView: User tapped tab bar item %@", item.title]];
    
    if((int) self.selectedIndex == UiAppTabsViewTabIndexHistory)
    {
        [[HistoryManager Manager] SetAllHistoryReaded];
    }
    
}

#pragma mark - SlideNavigationController Methods -

- (BOOL)slideNavigationControllerShouldDisplayLeftMenu
{
    return YES;
}

- (BOOL)slideNavigationControllerShouldDisplayRightMenu
{
    return NO;
}


@end
