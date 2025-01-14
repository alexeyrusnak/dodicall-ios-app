//
//  NUINavigationBarRenderer.m
//  NUIDemo
//
//  Created by Tom Benner on 11/24/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import "NUINavigationBarRenderer.h"

@implementation NUINavigationBarRenderer

+ (void)render:(UINavigationBar*)bar withClass:(NSString*)className
{
    if ([bar respondsToSelector:@selector(setBarTintColor:)]) {
        if ([NUISettings hasProperty:@"bar-tint-color" withClass:className]) {
            [bar setBarTintColor:[NUISettings getColor:@"bar-tint-color" withClass:className]];
        }
    }
    
    if ([NUISettings hasProperty:@"background-tint-color" withClass:className]) {
        [bar setTintColor:[NUISettings getColor:@"background-tint-color" withClass:className]];
    }

    if ([NUISettings hasProperty:@"background-image" withClass:className]) {
        [bar setBackgroundImage:[NUISettings getImage:@"background-image" withClass:className] forBarMetrics:UIBarMetricsDefault];
    }
    if ([NUISettings hasProperty:@"shadow-image" withClass:className]) {
        [bar setShadowImage:[NUISettings getImage:@"shadow-image" withClass:className]];
    }
    if ([NUISettings hasProperty:@"bottom-shadow-color" withClass:className]) {
        
        [bar setShadowImage: [NUIGraphics createImageFromColor:[NUISettings getColor:@"bottom-shadow-color" withClass:className] ofRect:CGRectMake(0, 0, 1, 1)]];
    }

    NSString *property = @"title-vertical-offset";
    if ([NUISettings hasProperty:property withClass:className]) {
        float offset = [NUISettings getFloat:property withClass:className];
        [bar setTitleVerticalPositionAdjustment:offset forBarMetrics:UIBarMetricsDefault];
    }

    [self renderSizeDependentProperties:bar];

    NSDictionary *titleTextAttributes = [NUIUtilities titleTextAttributesForClass:className];

    if ([[titleTextAttributes allKeys] count] > 0) {
        bar.titleTextAttributes = titleTextAttributes;
    }
}

+ (void)sizeDidChange:(UINavigationBar*)bar
{
    [self renderSizeDependentProperties:bar];
}

+ (void)renderSizeDependentProperties:(UINavigationBar*)bar
{
    NSString *className = bar.nuiClass;

    if ([NUISettings hasProperty:@"background-color-top" withClass:className]) {
        CGRect frame = bar.bounds;
        UIImage *gradientImage = [NUIGraphics
                                  gradientImageWithTop:[NUISettings getColor:@"background-color-top" withClass:className]
                                  bottom:[NUISettings getColor:@"background-color-bottom" withClass:className]
                                  frame:frame];
        [bar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
    } else if ([NUISettings hasProperty:@"background-color" withClass:className]) {
        CGRect frame = bar.bounds;
        frame.origin.y -= 20;
        frame.size.height += 200;
        UIImage *colorImage = [NUIGraphics colorImage:[NUISettings getColor:@"background-color" withClass:className] withFrame:frame];
        [bar setBackgroundImage:colorImage forBarMetrics:UIBarMetricsDefault];
        //[bar setBackgroundColor:[NUISettings getColor:@"background-color" withClass:className]];
    }
}

@end
