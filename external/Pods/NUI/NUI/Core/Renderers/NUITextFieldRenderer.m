//
//  NUITextFieldRenderer.m
//  NUIDemo
//
//  Created by Tom Benner on 11/24/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import "NUITextFieldRenderer.h"
#import "NUIViewRenderer.h"

@implementation NUITextFieldRenderer

+ (void)render:(UITextField*)textField withClass:(NSString*)className
{
    if ([NUISettings hasFontPropertiesWithClass:className]) {
        [textField setFont:[NUISettings getFontWithClass:className baseFont:textField.font]];
    }
    
    // Set font color
    if ([NUISettings hasProperty:@"font-color" withClass:className]) {
        [textField setTextColor:[NUISettings getColor:@"font-color" withClass:className]];
    }
    
    // Set background color
    if ([NUISettings hasProperty:@"background-color" withClass:className]) {
        [textField setBackgroundColor:[NUISettings getColor:@"background-color" withClass:className]];
    }
    
    // Set background gradient
    if ([NUISettings hasProperty:@"background-color-top" withClass:className]) {
        UIImage *gradient = [NUIGraphics
                             gradientImageWithTop:[NUISettings getColor:@"background-color-top" withClass:className]
                             bottom:[NUISettings getColor:@"background-color-bottom" withClass:className]
                             frame:textField.bounds];
        [textField setBackground:gradient];
    }
    
    // Set background image
    if ([NUISettings hasProperty:@"background-image" withClass:className]) {
        [textField setBackground:[NUISettings getImage:@"background-image" withClass:className]];
    }
    
    if ([NUISettings hasProperty:@"vertical-align" withClass:className]) {
        [textField setContentVerticalAlignment:[NUISettings getControlContentVerticalAlignment:@"vertical-align" withClass:className]];
    }

    // Set border style
    if ([NUISettings hasProperty:@"border-style" withClass:className]) {
        [textField setBorderStyle:[NUISettings getBorderStyle:@"border-style" withClass:className]];
    }
    
    if ([NUISettings hasProperty:@"place-holder-text-color" withClass:className] || [NUISettings hasProperty:@"place-holder-font-name" withClass:className]){
        if ([NUISettings hasProperty:@"place-holder-text-color" withClass:className]){
            // Change the search bar placeholder text color
            [textField setValue:[NUISettings getColor:@"place-holder-text-color" withClass:className] forKeyPath:@"_placeholderLabel.textColor"];
        }
        if ([NUISettings hasProperty:@"place-holder-font-name" withClass:className]){
            // Change the search bar placeholder text font
            float placeHolderFontSize = 18;
            if ([NUISettings hasProperty:@"place-holder-font-size" withClass:className]){
                placeHolderFontSize = [NUISettings getFloat:@"place-holder-font-size" withClass:className];
            }
            
            [textField setValue:[UIFont fontWithName:[NUISettings get:@"place-holder-font-name" withClass:className] size:placeHolderFontSize] forKeyPath:@"_placeholderLabel.font"];
        }
    }

    [NUIViewRenderer renderSize:textField withClass:className];
    [NUIViewRenderer renderBorder:textField withClass:className];
    [NUIViewRenderer renderShadow:textField withClass:className];
}

@end
