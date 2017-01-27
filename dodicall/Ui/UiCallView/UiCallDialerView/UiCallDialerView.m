//
//  UiCallDialerView.m
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

#import "UiCallDialerView.h"
#import "NUIRenderer.h"


@interface UiCallDialerView() {
    
}

@property (weak, nonatomic) IBOutlet UILabel *DTMFSymbolsLabel;


@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *NumButtonsArray;


@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *NumButtonsPlaces;

@property (weak, nonatomic) IBOutlet UIButton *DropCallButton;
@property (weak, nonatomic) IBOutlet UIButton *HideButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *NumButtonHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *NumButtonsTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *DTMFLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *CallButtonTopConstraint;
@property (weak, nonatomic) IBOutlet UILabel *HideButtonLabel;

@end
@implementation UiCallDialerView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]){
        self.ViewModel = [UiCallDialerViewModel new];
    }
    
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self AdjustSizes];
    [self BindAll];
}

- (void) BindAll {
    
    RAC(self.DTMFSymbolsLabel, text) = RACObserve(self.ViewModel, DTMFSymbols);
    self.DropCallButton.rac_command = self.ViewModel.HangupCallCommand;
    
    RACSignal *TouchDownSignal = [RACSignal merge:
                                        [[self.NumButtonsArray.rac_sequence
                                            map:^id(UIButton *Button) {
                                                return [Button rac_signalForControlEvents:UIControlEventTouchDown];
                                            }]
                                         array]];
    
    RACSignal *TouchUpSignal = [RACSignal merge:
                                        [[self.NumButtonsArray.rac_sequence
                                            map:^id(UIButton *Button) {
                                                return [Button rac_signalForControlEvents:UIControlEventTouchUpInside];
                                            }]
                                         array]];
    
    
    @weakify(self);
    
    [TouchDownSignal subscribeNext:^(UIButton *Sender) {
        
        UILabel *TextLabel = (UILabel *)Sender.superview.subviews[1];
        for(UIView *Subview in Sender.superview.subviews) {
            if([Subview isKindOfClass:[UILabel class]]) {
                UILabel *Label = (UILabel *)Subview;
                [Label setAlpha:0.7];
            }
        }
        @strongify(self);
        [self.ViewModel PlayDTMF:TextLabel.text];
     }];
    
    
    
    
    [TouchUpSignal subscribeNext:^(UIButton *Sender) {

        for(UIView *Subview in Sender.superview.subviews) {
            if([Subview isKindOfClass:[UILabel class]]) {
                UILabel *Label = (UILabel *)Subview;
                [Label setAlpha:1];
            }
        }
        @strongify(self);
        [self.ViewModel StopDTMF];
    }];
    
    
    
    [[self.HideButton rac_signalForControlEvents:UIControlEventTouchDown] subscribeNext:^(id x) {
        @strongify(self);
        [self.HideButtonLabel setAlpha:0.7];
    }];
    
    [[self.HideButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);

        [self.HideButtonLabel setAlpha:1];
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.view.alpha = 0;
        } completion:^(BOOL finished) {
            self.view.hidden = YES;
        }];
    }];
}

- (void) AdjustSizes {
    
    if([self.ViewModel.IsSmallDevice boolValue]) {
        
        self.NumButtonHeightConstraint.constant = 60;
        self.NumButtonsTopConstraint.constant = 10;
        self.DTMFLabelTopConstraint.constant = 5;
        self.CallButtonTopConstraint.constant = 10;
        
        for(UIView *ButtonPlace in self.NumButtonsPlaces) {
            ButtonPlace.nuiClass = [ButtonPlace.nuiClass stringByAppendingString:@"Compact"];
        }
        
        self.HideButtonLabel.nuiClass = [self.HideButtonLabel.nuiClass stringByAppendingString:@"Compact"];
    }
}

@end
