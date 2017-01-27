//
//  SlideNavigationContorllerAnimationScale.m
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

#import "SlideNavigationContorllerAnimatorScale.h"

@implementation SlideNavigationContorllerAnimatorScale

#pragma mark - Initialization -

- (id)init
{
	if (self = [self initWithMinimumScale:.9])
	{
	}
	
	return self;
}

- (id)initWithMinimumScale:(CGFloat)minimumScale
{
	if (self = [super init])
	{
		self.minimumScale = minimumScale;
	}
	
	return self;
}

#pragma mark - SlideNavigationContorllerAnimation Methods -

- (void)prepareMenuForAnimation:(Menu)menu
{
	UIViewController *menuViewController = (menu == MenuLeft)
		? [SlideNavigationController sharedInstance].leftMenu
		: [SlideNavigationController sharedInstance].rightMenu;
	
	menuViewController.view.transform = CGAffineTransformScale(menuViewController.view.transform, self.minimumScale, self.minimumScale);
}

- (void)animateMenu:(Menu)menu withProgress:(CGFloat)progress
{
	UIViewController *menuViewController = (menu == MenuLeft)
		? [SlideNavigationController sharedInstance].leftMenu
		: [SlideNavigationController sharedInstance].rightMenu;
	
	CGFloat scale = MIN(1, (1-self.minimumScale) *progress + self.minimumScale);
	menuViewController.view.transform = CGAffineTransformScale([SlideNavigationController sharedInstance].view.transform, scale, scale);
}

- (void)clear
{
	[SlideNavigationController sharedInstance].leftMenu.view.transform = CGAffineTransformScale([SlideNavigationController sharedInstance].view.transform, 1, 1);
	[SlideNavigationController sharedInstance].rightMenu.view.transform = CGAffineTransformScale([SlideNavigationController sharedInstance].view.transform, 1, 1);
}

@end
