//
//  DropdownMenuSegue.m
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

#import "DropdownMenuSegue.h"
#import "UiDropdownMenuView.h"

@implementation DropdownMenuSegue

- (void) perform {
    UiDropDownMenuView *containerViewController = (UiDropDownMenuView *) self.sourceViewController;
    UIViewController *nextViewController = (UIViewController *) self.destinationViewController;
    UIViewController *currentViewController = (UIViewController *) containerViewController.currentViewController;
    
    // Add nextViewController as child of container view controller.
    [containerViewController addChildViewController:nextViewController];
    // Tell current View controller that it will be removed.
    [currentViewController willMoveToParentViewController:nil];
    
    // Set the frame of the next view controller to equal the outgoing (current) view controller
    nextViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    nextViewController.view.frame = currentViewController.view.frame;
    nextViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
    
    // Make the transition with a very short Cross disolve animation
    [containerViewController transitionFromViewController:currentViewController
                                         toViewController:nextViewController
                                                 duration:0.1f
                                                  options:UIViewAnimationOptionTransitionCrossDissolve
                                               animations:^{
                                                   
                                               }
                                               completion:^(BOOL finished) {
                                                   containerViewController.currentViewController = nextViewController;
                                                   [currentViewController removeFromParentViewController];
                                                   [nextViewController didMoveToParentViewController:containerViewController];
                                               }];
    
}

@end
