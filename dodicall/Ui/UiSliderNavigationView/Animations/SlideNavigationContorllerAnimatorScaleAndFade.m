//
//  SlideNavigationContorllerAnimationScaleAndFade.m
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

#import "SlideNavigationContorllerAnimatorScaleAndFade.h"
#import "SlideNavigationContorllerAnimatorFade.h"
#import "SlideNavigationContorllerAnimatorScale.h"

@interface SlideNavigationContorllerAnimatorScaleAndFade()
@property (nonatomic, strong) SlideNavigationContorllerAnimatorFade *fadeAnimation;
@property (nonatomic, strong) SlideNavigationContorllerAnimatorScale *scaleAnimation;
@end

@implementation SlideNavigationContorllerAnimatorScaleAndFade

#pragma mark - Initialization -

- (id)init
{
	if (self = [self initWithMaximumFadeAlpha:.8 fadeColor:[UIColor blackColor] andMinimumScale:.8])
	{
	}
	
	return self;
}

- (id)initWithMaximumFadeAlpha:(CGFloat)maximumFadeAlpha fadeColor:(UIColor *)fadeColor andMinimumScale:(CGFloat)minimumScale
{
	if (self = [super init])
	{
		self.fadeAnimation = [[SlideNavigationContorllerAnimatorFade alloc] initWithMaximumFadeAlpha:maximumFadeAlpha andFadeColor:fadeColor];
		self.scaleAnimation = [[SlideNavigationContorllerAnimatorScale alloc] initWithMinimumScale:minimumScale];
	}
	
	return self;
}

#pragma mark - SlideNavigationContorllerAnimation Methods -

- (void)prepareMenuForAnimation:(Menu)menu
{
	[self.fadeAnimation prepareMenuForAnimation:menu];
	[self.scaleAnimation prepareMenuForAnimation:menu];
}

- (void)animateMenu:(Menu)menu withProgress:(CGFloat)progress
{
	[self.fadeAnimation animateMenu:menu withProgress:progress];
	[self.scaleAnimation animateMenu:menu withProgress:progress];
}

- (void)clear
{
	[self.fadeAnimation clear];
	[self.scaleAnimation clear];
}

@end
