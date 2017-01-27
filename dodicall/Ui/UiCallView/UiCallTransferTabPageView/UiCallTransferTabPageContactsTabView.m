//
//  UiCallTransferTabPageContactsTabView.m
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

#import "UiCallTransferTabPageContactsTabView.h"
#import "UiContactsSkeleton.h"
#import "UiContactsTabPageContactsListView.h"

@interface UiCallTransferTabPageContactsTabView ()

@end

@implementation UiCallTransferTabPageContactsTabView
{
    BOOL IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        
        self.ViewModel = [[UiCallTransferTabPageContactsTabViewModel alloc] init];
        
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self BindAll];
}

- (void) BindAll
{
    if(IsAllBinded)
        return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender
{
    if([segue.identifier isEqualToString:@"UiContactsTabPageContactsListViewNavEmbedSegue"])
    {
        UiContactsTabPageContactsListView *ContactsTabPageContactsListView = (UiContactsTabPageContactsListView *)[(UINavigationController *)[segue destinationViewController] topViewController];
        
        [ContactsTabPageContactsListView.ViewModel setMode:UiContactsTabPageContactsListViewModeCallTransfer];
        
    }
    
    
}

@end
