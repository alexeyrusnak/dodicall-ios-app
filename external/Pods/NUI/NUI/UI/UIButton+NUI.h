//
//  UIButton+NUI.h
//  NUIDemo
//
//  Created by Tom Benner on 12/8/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "NUIRenderer.h"

@interface UIButton (NUI)
@property (nonatomic, retain) CALayer* gradientLayer;
@end


