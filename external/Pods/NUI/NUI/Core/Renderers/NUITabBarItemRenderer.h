//
//  NUITabBarItemRenderer.h
//  NUIDemo
//
//  Created by Tom Benner on 12/9/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NUISettings.h"
#import "NUIUtilities.h"

@interface NUITabBarItemRenderer : NSObject

+ (void)render:(UITabBarItem*)item withClass:(NSString*)className;

+ (void) customizeBageView: (UITabBarItem*) item withValue:(NSString *) value withFont: (UIFont *) font andFontColor: (UIColor *) color andBackgroundColor: (UIColor *) backColor;

@end
