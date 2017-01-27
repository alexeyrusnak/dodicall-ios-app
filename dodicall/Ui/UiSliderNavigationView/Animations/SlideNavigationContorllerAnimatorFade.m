//
//  SlideNavigationContorllerAnimationFade.m
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

#import "SlideNavigationContorllerAnimatorFade.h"

@interface SlideNavigationContorllerAnimatorFade()
@property (nonatomic, strong) UIView *fadeAnimationView;
@end

@implementation SlideNavigationContorllerAnimatorFade

#pragma mark - Initialization -

- (id)init
{
	if (self = [self initWithMaximumFadeAlpha:.8 andFadeColor:[UIColor blackColor]])
	{
	}
	
	return self;
}

- (id)initWithMaximumFadeAlpha:(CGFloat)maximumFadeAlpha andFadeColor:(UIColor *)fadeColor
{
	if (self = [super init])
	{
		self.maximumFadeAlpha = maximumFadeAlpha;
		self.fadeColor = fadeColor;
		
		self.fadeAnimationView = [[UIView alloc] init];
		self.fadeAnimationView.backgroundColor = self.fadeColor;
	}
	
	return self;
}

#pragma mark - SlideNavigationContorllerAnimation Methods -

- (void)prepareMenuForAnimation:(Menu)menu
{
	UIViewController *menuViewController = (menu == MenuLeft)
		? [SlideNavigationController sharedInstance].leftMenu
		: [SlideNavigationController sharedInstance].rightMenu;
	
	self.fadeAnimationView.alpha = self.maximumFadeAlpha;
	self.fadeAnimationView.frame = menuViewController.view.bounds;
}

- (void)animateMenu:(Menu)menu withProgress:(CGFloat)progress
{
	UIViewController *menuViewController = (menu == MenuLeft)
		? [SlideNavigationController sharedInstance].leftMenu
		: [SlideNavigationController sharedInstance].rightMenu;
	
	self.fadeAnimationView.frame = menuViewController.view.bounds;
	[menuViewController.view addSubview:self.fadeAnimationView];
	self.fadeAnimationView.alpha = self.maximumFadeAlpha - (self.maximumFadeAlpha *progress);
}

- (void)clear
{
	[self.fadeAnimationView removeFromSuperview];
}

@end
