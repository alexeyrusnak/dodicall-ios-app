//
//  NUIViewRenderer.m
//  NUIDemo
//
//  Created by Tom Benner on 11/24/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import "NUIViewRenderer.h"
#import "NUIGraphics.h"

@implementation NUIViewRenderer

+ (void)render:(UIView*)view withClass:(NSString*)className
{
    if ([NUISettings hasProperty:@"background-image" withClass:className]) {
        if ([NUISettings hasProperty:@"background-repeat" withClass:className] && ![NUISettings getBoolean:@"background-repeat" withClass:className]) {
            view.layer.contents = (__bridge id)[NUISettings getImage:@"background-image" withClass:className].CGImage;
        } else {
            [view setBackgroundColor: [NUISettings getColorFromImage:@"background-image" withClass: className]];
        }
    } else if ([NUISettings hasProperty:@"background-color" withClass:className]) {
        [view setBackgroundColor: [NUISettings getColor:@"background-color" withClass: className]];
    }
    
    if ([NUISettings hasProperty:@"tint-color" withClass:className])
    {
        [view setTintColor:[NUISettings getColor:@"tint-color" withClass:className]];
        //view.tintColor = [NUISettings getColor:@"tint-color" withClass:className];
    }
    
    // Image color
    if ([NUISettings hasProperty:@"image-color" withClass:className]) {
        
        UIImageView *ImageView = (UIImageView *) view;
        
        [ImageView setImage:[NUIGraphics changeImageColor:ImageView.image :[NUISettings getColor:@"image-color" withClass:className]]];
    }
    
    // Image stretchable
    if ([NUISettings hasProperty:@"image-stretchable" withClass:className] && [NUISettings getBoolean:@"image-stretchable" withClass:className]) {
        
        UIImageView *ImageView = (UIImageView *) view;
        
        [ImageView setImage:[ImageView.image stretchableImageWithLeftCapWidth:[NUISettings getFloat:@"image-leftCap" withClass:className] topCapHeight:[NUISettings getFloat:@"image-leftCap" withClass:className]]];
    }
    
    // Image rotate
    if ([NUISettings hasProperty:@"image-rotate" withClass:className]) {
        
        UIImageView *ImageView = (UIImageView *) view;
        
        [ImageView setTransform:CGAffineTransformMakeRotation(M_PI*[NUISettings getFloat:@"image-rotate" withClass:className])];
    }
    
    // Opacity
    if ([NUISettings hasProperty:@"alpha" withClass:className]) {
        
        [view setAlpha:[NUISettings getFloat:@"alpha" withClass:className]];
    }
    
    // Flip vertical
    if ([NUISettings hasProperty:@"flip-vertical" withClass:className] && [NUISettings getBoolean:@"flip-vertical" withClass:className]) {
        
        [view.layer setAffineTransform:CGAffineTransformMakeScale(1, -1)];
    }

    [self renderSize:view withClass:className];
    [self renderBorder:view withClass:className];
    [self renderShadow:view withClass:className];
}

+ (void)renderBorder:(UIView*)view withClass:(NSString*)className
{
    CALayer *layer = [view layer];
    
    if ([NUISettings hasProperty:@"border-color" withClass:className]) {
        [layer setBorderColor:[[NUISettings getColor:@"border-color" withClass:className] CGColor]];
    }
    
    if ([NUISettings hasProperty:@"border-width" withClass:className]) {
        [layer setBorderWidth:[NUISettings getFloat:@"border-width" withClass:className]];
    }
    
    if ([NUISettings hasProperty:@"corner-radius" withClass:className]) {
        [layer setCornerRadius:[NUISettings getFloat:@"corner-radius" withClass:className]];
        layer.masksToBounds = YES;
    }
}

+ (void)renderShadow:(UIView*)view withClass:(NSString*)className
{
    CALayer *layer = [view layer];
    
    if ([NUISettings hasProperty:@"shadow-radius" withClass:className]) {
        [layer setShadowRadius:[NUISettings getFloat:@"shadow-radius" withClass:className]];
    }
    
    if ([NUISettings hasProperty:@"shadow-offset" withClass:className]) {
        [layer setShadowOffset:[NUISettings getSize:@"shadow-offset" withClass:className]];
    }
    
    if ([NUISettings hasProperty:@"shadow-color" withClass:className]) {
        [layer setShadowColor:[NUISettings getColor:@"shadow-color" withClass:className].CGColor];
    }
    
    if ([NUISettings hasProperty:@"shadow-opacity" withClass:className]) {
        [layer setShadowOpacity:[NUISettings getFloat:@"shadow-opacity" withClass:className]];
    }
}

+ (void)renderSize:(UIView*)view withClass:(NSString*)className
{
    CGFloat height = view.frame.size.height;
    if ([NUISettings hasProperty:@"height" withClass:className]) {
        height = [NUISettings getFloat:@"height" withClass:className];
    }
    
    CGFloat width = view.frame.size.width;
    if ([NUISettings hasProperty:@"width" withClass:className]) {
        width = [NUISettings getFloat:@"width" withClass:className];
    }

    if (height != view.frame.size.height || width != view.frame.size.width) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, width, height);
    }
}

+ (BOOL)hasShadowProperties:(UIView*)view withClass:(NSString*)className {
    
    BOOL hasAnyShadowProperty = NO;
    for (NSString *property in @[@"shadow-radius", @"shadow-offset", @"shadow-color", @"shadow-opacity"]) {
        hasAnyShadowProperty |= [NUISettings hasProperty:property withClass:className];
    }
    return hasAnyShadowProperty;
}

@end
