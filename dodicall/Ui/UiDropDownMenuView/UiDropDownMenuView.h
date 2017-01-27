//
//  UiDropDownMenuViewViewController.h
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

#import <UIKit/UIKit.h>

@interface UiDropDownMenuView : UIViewController

@property (weak,nonatomic) UIViewController *currentViewController;
@property (strong, nonatomic) NSString *currentSegueIdentifier;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIView *menubar;
@property (weak, nonatomic) IBOutlet UIView *menu;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

- (IBAction) displayGestureForTapRecognizer:(UITapGestureRecognizer *) recognizer;
- (IBAction) menuButtonAction: (UIButton *) sender;
- (IBAction) listButtonAction: (UIButton *) sender;

- (void) setTrianglePlacement: (float) trianglePlacementVal;
- (void) setFadeAmountWithAlpha:(float) alphaVal;
- (void) setFadeTintWithColor:(UIColor *) color;
- (void) dropShapeShouldShowWhenOpen:(BOOL)shouldShow;
- (void) setMenubarTitle:(NSString *) menubarTitle;
- (void) setMenubarBackground:(UIColor *) color;
- (void) toggleMenu;
- (void) showMenu;
- (void) hideMenu;

@end
