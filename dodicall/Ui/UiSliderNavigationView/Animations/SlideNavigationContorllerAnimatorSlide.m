//
//  SlideNavigationContorllerAnimationSlide.m
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

#import "SlideNavigationContorllerAnimatorSlide.h"

@implementation SlideNavigationContorllerAnimatorSlide

#pragma mark - Initialization -

- (id)init
{
    if (self = [self initWithSlideMovement:100])
    {
    }
    
    return self;
}

- (id)initWithSlideMovement:(CGFloat)slideMovement
{
	if (self = [super init])
	{
		self.slideMovement = slideMovement;
	}
	
	return self;
}

#pragma mark - SlideNavigationContorllerAnimation Methods -

- (void)prepareMenuForAnimation:(Menu)menu
{
	UIViewController *menuViewController = (menu == MenuLeft)
        ? [SlideNavigationController sharedInstance].leftMenu
        : [SlideNavigationController sharedInstance].rightMenu;
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	CGRect rect = menuViewController.view.frame;
	
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        rect.origin.x = (menu == MenuLeft) ? self.slideMovement*-1 : self.slideMovement;
    }
    else
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            if (orientation == UIInterfaceOrientationLandscapeRight)
            {
                rect.origin.y = (menu == MenuLeft) ? self.slideMovement*-1 : self.slideMovement;
            }
            else
            {
                rect.origin.y = (menu == MenuRight) ? self.slideMovement*-1 : self.slideMovement;
            }
        }
        else
        {
            if (orientation == UIInterfaceOrientationPortrait)
            {
                rect.origin.x = (menu == MenuLeft) ? self.slideMovement*-1 : self.slideMovement;
            }
            else
            {
                rect.origin.x = (menu == MenuRight) ? self.slideMovement*-1 : self.slideMovement;
            }
        }
    }
    
    menuViewController.view.frame = rect;
}

- (void)animateMenu:(Menu)menu withProgress:(CGFloat)progress
{
    UIViewController *menuViewController = (menu == MenuLeft)
        ? [SlideNavigationController sharedInstance].leftMenu
        : [SlideNavigationController sharedInstance].rightMenu;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    NSInteger location = (menu == MenuLeft)
        ? (self.slideMovement * -1) + (self.slideMovement * progress)
        : (self.slideMovement * (1-progress));
    
    if (menu == MenuLeft)
        location = (location > 0) ? 0 : location;
    
    if (menu == MenuRight)
        location = (location < 0) ? 0 : location;
    
    CGRect rect = menuViewController.view.frame;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        rect.origin.x = location;
    }
    else
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            rect.origin.y = (orientation == UIInterfaceOrientationLandscapeRight) ? location : location*-1;
        }
        else
        {
            rect.origin.x = (orientation == UIInterfaceOrientationPortrait) ? location : location*-1;
        }
    }
    
    menuViewController.view.frame = rect;
}

- (void)clear
{
    [self clearMenu:MenuLeft];
    [self clearMenu:MenuRight];
}

#pragma mark - Private Method -

- (void)clearMenu:(Menu)menu
{
    UIViewController *menuViewController = (menu == MenuLeft)
    ? [SlideNavigationController sharedInstance].leftMenu
    : [SlideNavigationController sharedInstance].rightMenu;
    
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	
    CGRect rect = menuViewController.view.frame;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        rect.origin.x = 0;
    }
    else
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            rect.origin.y = 0;
        }
        else
        {
            rect.origin.x = 0;
        }
    }
    
    menuViewController.view.frame = rect;
}

@end
