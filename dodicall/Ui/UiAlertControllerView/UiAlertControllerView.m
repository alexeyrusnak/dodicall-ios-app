//
//  UiAlertControllerView.m
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

#import "UiAlertControllerView.h"
#import <NUI/NUIRenderer.h>
#import <NUI/NUISettings.h>

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation UIView (viewRecursion)
- (NSMutableArray*)allSubViews
{
    NSMutableArray *arr=[[NSMutableArray alloc] init];
    [arr addObject:self];
    for (UIView *subview in self.subviews)
    {
        [arr addObjectsFromArray:(NSArray*)[subview allSubViews]];
    }
    return arr;
}
@end

@interface UiAlertControllerView ()

@end

@implementation UiAlertControllerView

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    
    
    UIColor *CancelColor = [NUISettings getColor:@"tint-color" withClass:@"UiActionListCancelLabel"];
    UIColor *DestructiveColor = [NUISettings getColor:@"tint-color" withClass:@"UiActionListDestructiveLabel"];
    UIColor *DefaultColor = [NUISettings getColor:@"tint-color" withClass:@"UiActionListDefaultLabel"];
    
    
    [NUIRenderer renderView:self.view withClass:@"UiActionListCancelLabel"];
    
    for(UIView *Label in [self.view allSubViews])
    {
        if([Label isKindOfClass:[UILabel class]])
        {
            UILabel *_Label = (UILabel *) Label;
            
            if(_Label.text.length > 0)
            {
                if([self.title isEqualToString:_Label.text])
                {
                    [NUIRenderer renderLabel:_Label withClass:@"UiActionListTitleLabel"];
                }
                
                else
                {
                    for (UIAlertAction *Action in self.actions) {
                        
                        if([Action.title isEqualToString:_Label.text])
                        {
                            @weakify(_Label);
                            
                            if(Action.style == UIAlertActionStyleCancel)
                            {
                                [NUIRenderer renderLabel:_Label withClass:@"UiActionListCancelLabel"];
                                
                                [[RACObserve(_Label, tintColor)
                                    filter:^BOOL(UIColor *Color) {
                                        return ![Color isEqual:CancelColor];
                                    }]
                                    subscribeNext:^(id x) {
                                        @strongify(_Label);
                                        [_Label setTintColor:CancelColor];
                                    }];
                            }
                            
                            else if(Action.style == UIAlertActionStyleDestructive)
                            {
                                [NUIRenderer renderLabel:_Label withClass:@"UiActionListDestructiveLabel"];
                                
                                [[RACObserve(_Label, tintColor)
                                    filter:^BOOL(UIColor *Color) {
                                        return ![Color isEqual:DestructiveColor];
                                    }]
                                    subscribeNext:^(id x) {
                                        @strongify(_Label);
                                        [_Label setTintColor:DestructiveColor];
                                    }];
                            }
                            
                            else
                            {
                                [NUIRenderer renderLabel:_Label withClass:@"UiActionListDefaultLabel"];
                                
                                [[RACObserve(_Label, tintColor)
                                    filter:^BOOL(UIColor *Color) {
                                      return ![Color isEqual:DefaultColor];
                                    }]
                                    subscribeNext:^(id x) {
                                        @strongify(_Label);
                                        [_Label setTintColor:DefaultColor];
                                    }];
                            }
                            
                            
                        }
                        
                    }
                }
            }
        }
    }
}

@end
