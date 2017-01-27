//
//  NUIButtonRenderer.m
//  NUIDemo
//
//  Created by Tom Benner on 11/24/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import "NUIButtonRenderer.h"
#import "NUIViewRenderer.h"
#import "UIButton+NUI.h"

@implementation NUIButtonRenderer

+ (void)render:(UIButton*)button withClass:(NSString*)className
{    
    
    // Set badge
    if([className isEqualToString:@"UiButtonWithBadgeView"])
    {
        if ([NUISettings hasProperty:@"badge-bg-color" withClass:className]) {
            
            if ([button respondsToSelector:NSSelectorFromString(@"badgeBGColor")])
            {
                [button setValue:[NUISettings getColor:@"badge-bg-color" withClass:className] forKey:@"badgeBGColor"];
            }
        }
        
        if ([NUISettings hasProperty:@"badge-text-color" withClass:className]) {
            
            if ([button respondsToSelector:NSSelectorFromString(@"badgeTextColor")])
            {
                [button setValue:[NUISettings getColor:@"badge-text-color" withClass:className] forKey:@"badgeTextColor"];
            }
        }
        
        if ([NUISettings hasProperty:@"badge-font-name" withClass:className] && [NUISettings hasProperty:@"badge-font-size" withClass:className]) {
            
            if ([button respondsToSelector:NSSelectorFromString(@"badgeFont")])
            {
                [button setValue: [UIFont fontWithName: [NUISettings get:@"badge-font-name" withClass:className] size: [NUISettings getFloat:@"badge-font-size" withClass:className]] forKey:@"badgeFont"];
            }
        }
    }
    
    [NUIViewRenderer renderSize:button withClass:className];
    // UIButtonTypeRoundedRect's first two sublayers contain its background and border, which
    // need to be hidden for NUI's rendering to be displayed correctly. Ideally we would switch
    // over to a UIButtonTypeCustom, but this appears to be impossible.
    if (button.buttonType == UIButtonTypeRoundedRect) {
        if ([button.layer.sublayers count] > 2) {
            [button.layer.sublayers[0] setOpacity:0.0f];
            [button.layer.sublayers[1] setOpacity:0.0f];
        }
    }

    // Set padding
    if ([NUISettings hasProperty:@"padding" withClass:className]) {
        [button setTitleEdgeInsets:[NUISettings getEdgeInsets:@"padding" withClass:className]];
    }
    
    // Set background color
    if ([NUISettings hasProperty:@"background-color" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImageFromColor:@"background-color" withClass:className] forState:UIControlStateNormal];
    }
    if ([NUISettings hasProperty:@"background-color-highlighted" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImageFromColor:@"background-color-highlighted" withClass:className] forState:UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"background-color-selected" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImageFromColor:@"background-color-selected" withClass:className] forState:UIControlStateSelected];
    }
    if ([NUISettings hasProperty:@"background-color-selected-highlighted" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImageFromColor:@"background-color-selected-highlighted" withClass:className] forState:UIControlStateSelected|UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"background-color-selected-disabled" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImageFromColor:@"background-color-selected-disabled" withClass:className] forState:UIControlStateSelected|UIControlStateDisabled];
    }
    if ([NUISettings hasProperty:@"background-color-disabled" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImageFromColor:@"background-color-disabled" withClass:className] forState:UIControlStateDisabled];
    }
    
    // Set background gradient
    if ([NUISettings hasProperty:@"background-color-top" withClass:className]) {
        CAGradientLayer *gradientLayer = [NUIGraphics
                                          gradientLayerWithTop:[NUISettings getColor:@"background-color-top" withClass:className]
                                          bottom:[NUISettings getColor:@"background-color-bottom" withClass:className]
                                          frame:button.bounds];
        
        if (button.gradientLayer) {
            [button.layer replaceSublayer:button.gradientLayer with:gradientLayer];
        } else {
            int backgroundLayerIndex = [button.layer.sublayers count] == 1 ? 0 : 1;
            [button.layer insertSublayer:gradientLayer atIndex:backgroundLayerIndex];
        }
        
        button.gradientLayer = gradientLayer;
    }
    
    // Set background image
    if ([NUISettings hasProperty:@"background-image" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImage:@"background-image" withClass:className] forState:UIControlStateNormal];
    }
    if ([NUISettings hasProperty:@"background-image-highlighted" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImage:@"background-image-highlighted" withClass:className] forState:UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"background-image-selected" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImage:@"background-image-selected" withClass:className] forState:UIControlStateSelected];
    }
    if ([NUISettings hasProperty:@"background-image-selected-highlighted" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImage:@"background-image-selected-highlighted" withClass:className] forState:UIControlStateSelected|UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"background-image-selected-disabled" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImage:@"background-image-selected-disabled" withClass:className] forState:UIControlStateSelected|UIControlStateDisabled];
    }
    if ([NUISettings hasProperty:@"background-image-disabled" withClass:className]) {
        [button setBackgroundImage:[NUISettings getImage:@"background-image-disabled" withClass:className] forState:UIControlStateDisabled];
    }
    
    // Set image
    if ([NUISettings hasProperty:@"image" withClass:className]) {
        [button setImage:[NUISettings getImage:@"image" withClass:className] forState:UIControlStateNormal];
    }
    if ([NUISettings hasProperty:@"image-highlighted" withClass:className]) {
        [button setImage:[NUISettings getImage:@"image-highlighted" withClass:className] forState:UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"image-selected" withClass:className]) {
        [button setImage:[NUISettings getImage:@"image-selected" withClass:className] forState:UIControlStateSelected];
    }
    if ([NUISettings hasProperty:@"image-selected-highlighted" withClass:className]) {
        [button setImage:[NUISettings getImage:@"image-selected-highlighted" withClass:className] forState:UIControlStateSelected|UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"image-selected-disabled" withClass:className]) {
        [button setImage:[NUISettings getImage:@"image-selected-disabled" withClass:className] forState:UIControlStateSelected|UIControlStateDisabled];
    }
    if ([NUISettings hasProperty:@"image-disabled" withClass:className]) {
        [button setImage:[NUISettings getImage:@"image-disabled" withClass:className] forState:UIControlStateDisabled];
    }
    
    // Image color
    if ([NUISettings hasProperty:@"image-color" withClass:className]) {
        [button setImage:[NUIGraphics changeImageColor:button.imageView.image :[NUISettings getColor:@"image-color" withClass:className]] forState:UIControlStateNormal];
    }
    if ([NUISettings hasProperty:@"image-color-highlighted" withClass:className]) {
        [button setImage:[NUIGraphics changeImageColor:button.imageView.image :[NUISettings getColor:@"image-color-highlighted" withClass:className]] forState:UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"image-color-selected" withClass:className]) {
        [button setImage:[NUIGraphics changeImageColor:button.imageView.image :[NUISettings getColor:@"image-color-selected" withClass:className]] forState:UIControlStateSelected];
    }
    if ([NUISettings hasProperty:@"image-color-disabled" withClass:className]) {
        [button setImage:[NUIGraphics changeImageColor:button.imageView.image :[NUISettings getColor:@"image-color-disabled" withClass:className]] forState:UIControlStateDisabled];
    }

    
    [NUILabelRenderer renderText:button.titleLabel withClass:className];
    
    // Set text align
    if ([NUISettings hasProperty:@"text-align" withClass:className]) {
        [button setContentHorizontalAlignment:[NUISettings getControlContentHorizontalAlignment:@"text-align" withClass:className]];
    }
    
    // Set font color
    if ([NUISettings hasProperty:@"font-color" withClass:className]) {
        [button setTitleColor:[NUISettings getColor:@"font-color" withClass:className] forState:UIControlStateNormal];
    }
    if ([NUISettings hasProperty:@"font-color-highlighted" withClass:className]) {
        [button setTitleColor:[NUISettings getColor:@"font-color-highlighted" withClass:className] forState:UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"font-color-selected" withClass:className]) {
        [button setTitleColor:[NUISettings getColor:@"font-color-selected" withClass:className] forState:UIControlStateSelected];
    }
    if ([NUISettings hasProperty:@"font-color-selected-highlighted" withClass:className]) {
        [button setTitleColor:[NUISettings getColor:@"font-color-selected-highlighted" withClass:className] forState:UIControlStateSelected|UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"font-color-selected-disabled" withClass:className]) {
        [button setTitleColor:[NUISettings getColor:@"font-color-selected-disabled" withClass:className] forState:UIControlStateSelected|UIControlStateDisabled];
    }
    if ([NUISettings hasProperty:@"font-color-disabled" withClass:className]) {
        [button setTitleColor:[NUISettings getColor:@"font-color-disabled" withClass:className] forState:UIControlStateDisabled];
    }
    
    // Set text shadow color
    if ([NUISettings hasProperty:@"text-shadow-color" withClass:className]) {
        [button setTitleShadowColor:[NUISettings getColor:@"text-shadow-color" withClass:className] forState:UIControlStateNormal];
    }
    if ([NUISettings hasProperty:@"text-shadow-color-highlighted" withClass:className]) {
        [button setTitleShadowColor:[NUISettings getColor:@"text-shadow-color-highlighted" withClass:className] forState:UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"text-shadow-color-selected" withClass:className]) {
        [button setTitleShadowColor:[NUISettings getColor:@"text-shadow-color-selected" withClass:className] forState:UIControlStateSelected];
    }
    if ([NUISettings hasProperty:@"text-shadow-color-selected-highlighted" withClass:className]) {
        [button setTitleShadowColor:[NUISettings getColor:@"text-shadow-color-selected-highlighted" withClass:className] forState:UIControlStateSelected|UIControlStateHighlighted];
    }
    if ([NUISettings hasProperty:@"text-shadow-color-selected-disabled" withClass:className]) {
        [button setTitleShadowColor:[NUISettings getColor:@"text-shadow-color-selected-disabled" withClass:className] forState:UIControlStateSelected|UIControlStateDisabled];
    }
    if ([NUISettings hasProperty:@"text-shadow-color-disabled" withClass:className]) {
        [button setTitleShadowColor:[NUISettings getColor:@"text-shadow-color-disabled" withClass:className] forState:UIControlStateDisabled];
    }
    
    // title insets
    if ([NUISettings hasProperty:@"title-insets" withClass:className]) {
        [button setTitleEdgeInsets:[NUISettings getEdgeInsets:@"title-insets" withClass:className]];
    }
    
    // content insets
    if ([NUISettings hasProperty:@"content-insets" withClass:className]) {
        [button setContentEdgeInsets:[NUISettings getEdgeInsets:@"content-insets" withClass:className]];
    }
    
    if([NSStringFromClass([button class]) isEqualToString:@"UiCheckListButtonView"])
    {
        //button.titleEdgeInsets = UIEdgeInsetsMake(0, -18, 0, 0);
        //button.imageEdgeInsets = UIEdgeInsetsMake(0, button.bounds.size.width - 31, 0, 0);
        
        //button.titleEdgeInsets = UIEdgeInsetsMake(0, -button.imageView.frame.size.width*2, 0, button.imageView.frame.size.width);
        //button.imageEdgeInsets = UIEdgeInsetsMake(0, button.bounds.size.width - 31, 0, 0);
        
        
        //Right-align the button image
        //CGSize size = [[button titleForState:UIControlStateNormal] sizeWithFont:button.titleLabel.font];
        //[button setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -size.width)];
        //[button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, button.imageView.image.size.width + 5)];
    }
    
    if([NSStringFromClass([button class]) isEqualToString:@"UiButtonWithDropDownIconView"])
    {
        
        button.titleEdgeInsets = UIEdgeInsetsMake(0, -button.imageView.frame.size.width, 0, button.imageView.frame.size.width + 4);
        button.imageEdgeInsets = UIEdgeInsetsMake(5, button.titleLabel.frame.size.width, 0, -button.titleLabel.frame.size.width);
    }
    
    [NUIViewRenderer renderBorder:button withClass:className];
    
    // If a shadow-* is configured and corner-radius is set disable mask to bounds and fall back to manually applying corner radius to all sub-views (except the label)
    if ([NUIViewRenderer hasShadowProperties:button withClass:className] &&
        [NUISettings hasProperty:@"corner-radius" withClass:className]) {
        CGFloat r = [NUISettings getFloat:@"corner-radius" withClass:className];
        for (UIView* subview in button.subviews) {
            if ([subview isKindOfClass:[UILabel class]] == NO) {
                subview.layer.cornerRadius = r;
            }
        }
        button.layer.masksToBounds = NO;
    }
    
    // corners
    if ([NUISettings hasProperty:@"corners-radius" withClass:className]) {
        
        NSArray *radArr = [[NUISettings get:@"corners-radius" withClass:className] componentsSeparatedByString: @","];
        
        UIRectCorner *corners;
        
        if([radArr[0] integerValue] > 0 && [radArr[1] integerValue] > 0 && [radArr[2] integerValue] > 0 && [radArr[3] integerValue] > 0)
            corners = UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomRight | UIRectCornerBottomLeft;
        
        else if([radArr[0] integerValue] > 0 && [radArr[1] integerValue] == 0 && [radArr[2] integerValue] == 0 && [radArr[3] integerValue] > 0)
            corners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
        
        else if([radArr[0] integerValue] == 0 && [radArr[1] integerValue] > 0 && [radArr[2] integerValue] > 0 && [radArr[3] integerValue] == 0)
            corners = UIRectCornerTopRight | UIRectCornerBottomRight;
        
        NSInteger radius = 0;
        
        for(NSString *rad in radArr)
        {
            if ([rad integerValue] > 0) {
                radius = [rad integerValue];
            }
        }
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:button.bounds byRoundingCorners:(corners) cornerRadii:CGSizeMake(radius, radius)];
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = button.bounds;
        maskLayer.path  = maskPath.CGPath;
        button.layer.mask = maskLayer;
        
        button.layer.masksToBounds = NO;
    }
    
    [NUIViewRenderer renderShadow:button withClass:className];
}

@end
