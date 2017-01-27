//
//  NUITabBarItemRenderer.m
//  NUIDemo
//
//  Created by Tom Benner on 12/9/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import "NUITabBarItemRenderer.h"

#define CUSTOM_BADGE_TAG 99
#define OFFSET 0.6f

@implementation NUITabBarItemRenderer

+ (void)render:(UITabBarItem*)item withClass:(NSString*)className
{
    
    if ([NUISettings hasProperty:@"image-original" withClass:className]) {
        
        BOOL imageOriginal = FALSE;
        imageOriginal = [NUISettings getBoolean:@"image-original" withClass:className];
        
        if(imageOriginal)
            item.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    
    if ([NUISettings hasProperty:@"selected-image-original" withClass:className]) {
        
        BOOL selectedImageOriginal = FALSE;
        selectedImageOriginal = [NUISettings getBoolean:@"selected-image-original" withClass:className];
        
        if(selectedImageOriginal)
            item.selectedImage = [item.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    //[NUITabBarItemRenderer customizeBageView:item];
    //[NUITabBarItemRenderer customizeBageView: item withValue:@"dsfgsdfgsdfgsdf" withFont:[UIFont systemFontOfSize:17.0] andFontColor:[UIColor blueColor] andBackgroundColor:[UIColor blackColor]];

    
    NSDictionary *titleTextAttributes = [NUIUtilities titleTextAttributesForClass:className];

    if ([[titleTextAttributes allKeys] count] > 0) {
        [item setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }

    NSDictionary *selectedTextAttributes = [NUIUtilities titleTextAttributesForClass:className withSuffix:@"selected"];

    if ([[selectedTextAttributes allKeys] count] > 0) {
        [item setTitleTextAttributes:selectedTextAttributes forState:UIControlStateSelected];
    }

    if ([NUISettings hasProperty:@"text-offset" withClass:className]) {
        [item setTitlePositionAdjustment:[NUISettings getOffset:@"text-offset" withClass:className]];
    }

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    if ([NUISettings hasProperty:@"finished-image" withClass:className]) {
        UIImage *unselectedFinishedImage = [[NUISettings getImage:@"finished-image" withClass:className] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [item setImage:unselectedFinishedImage];
    }
    
    if ([NUISettings hasProperty:@"finished-image-selected" withClass:className]) {
        UIImage *selectedFinishedImage = [[NUISettings getImage:@"finished-image-selected" withClass:className] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [item setSelectedImage:selectedFinishedImage];
    }
#else
    if ([NUISettings hasProperty:@"finished-image" withClass:className]) {
        UIImage *unselectedFinishedImage = [NUISettings getImage:@"finished-image" withClass:className];
        UIImage *selectedFinishedImage = unselectedFinishedImage;
        
        if ([NUISettings hasProperty:@"finished-image-selected" withClass:className]) {
            selectedFinishedImage = [NUISettings getImage:@"finished-image-selected" withClass:className];
        }
        
        [item setFinishedSelectedImage:selectedFinishedImage withFinishedUnselectedImage:unselectedFinishedImage];
    }
#endif
}

+ (void)customizeBageViewOld: (UITabBarItem*) item /*withFont: (UIFont *) font andFontColor: (UIColor *) color andBackgroundColor: (UIColor *) backColor*/
{
    UIView *v = [item valueForKey:@"view"];  
    
    for(UIView *sv in v.subviews)
    { 
        NSString *str = NSStringFromClass([sv class]);
        
        if([str isEqualToString:@"_UIBadgeView"])
        {
            
            for (UIView* badgeSubview in sv.subviews) {
                NSString* className = NSStringFromClass([badgeSubview class]);
                
                // looking for _UIBadgeBackground
                if ([className rangeOfString:@"BadgeBackground"].location != NSNotFound) {
                    @try {
                        [badgeSubview setValue:[UIImage imageNamed:@"YourCustomImage.png"] forKey:@"image"];
                    }
                    @catch (NSException *exception) {}
                }
                
                if ([badgeSubview isKindOfClass:[UILabel class]]) {
                    ((UILabel *)badgeSubview).textColor = [UIColor greenColor];
                }
            }
        }
    }
}

+(void) customizeBageView: (UITabBarItem*) item withValue:(NSString *) value withFont: (UIFont *) font andFontColor: (UIColor *) color andBackgroundColor: (UIColor *) backColor
{
    return;
    UIView *v = [item valueForKey:@"view"];
    
    //[item setBadgeValue:value];

    for(UIView *sv in v.subviews)
    {
        
        NSString *str = NSStringFromClass([sv class]);
        
        if([str isEqualToString:@"_UIBadgeView"])
        {
            for(UIView *ssv in sv.subviews)
            {
                // REMOVE PREVIOUS IF EXIST
                //if(ssv.tag == CUSTOM_BADGE_TAG) { [ssv removeFromSuperview]; }
            }
            
            UIView *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            
            
            //[l setFont:font];
            //[l setText:value];
            [l setBackgroundColor:[UIColor blackColor]];
            //[l setTextColor:color];
            //[l setTextAlignment:NSTextAlignmentCenter];
            
            //l.layer.cornerRadius = l.frame.size.height/2;
            //l.layer.masksToBounds = YES;
            
            // Fix for border
            //sv.layer.borderWidth = 1;
            //sv.layer.borderColor = [backColor CGColor];
            //sv.layer.cornerRadius = sv.frame.size.height/2;
            //sv.layer.masksToBounds = YES;
            
            
            [v addSubview:l];
            
            l.tag = CUSTOM_BADGE_TAG;
        }
    }
}


@end
