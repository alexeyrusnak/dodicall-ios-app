//
//  UiInCallStatusBar.m
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

#import "UiInCallStatusBar.h"
#import "UiNavRouter.h"
#import "UiCallsNavRouter.h"
#import "ObjC_CallsModel.h"
#import "ContactsManager.h"
#import <NUIRenderer.h>
#import "UiInCallStatusBarGestureRecogniser.h"

@interface UiInCallStatusBar ()

@property (strong, nonatomic) UIView *Bar;
@property (strong, nonatomic) UILabel *Label;

@property (strong, nonatomic) NSLayoutConstraint *BarHeight;
@property (strong, nonatomic) NSLayoutConstraint *BarTop;
@property (strong, nonatomic) UiInCallStatusBarGestureRecogniser *TapRecogniser;

@property (assign) BOOL IsShown;
@property (assign) NSTimeInterval CallDuration;
@property (strong, nonatomic) NSString *MainString;
@property (strong, nonatomic) NSString *DurationString;

@property (assign) BOOL ShouldChangeStatusBarColorBack;
@property (assign) BOOL ReceivedTap;

@property (strong, nonatomic) UIView *ParentView;
@property (nonatomic, copy, nullable) void (^TapCallback)(void);

@end

@implementation UiInCallStatusBar

-(instancetype)init {
    if(self = [super init]) {
        
        self.IsShown = NO;
        self.CallDuration = 0;
        self.Bar = [UIView new];
        self.Label = [UILabel new];
        self.TapRecogniser = [UiInCallStatusBarGestureRecogniser new];
        self.MainString = @"";
        self.DurationString = @"";
        self.ShouldChangeStatusBarColorBack = YES;
        self.ReceivedTap = NO;
        
        RACSignal *CallSignal = RACObserve(self, Call);
        
        @weakify(self);
        
        [CallSignal subscribeNext:^(ObjC_CallModel *Call) {
            @strongify(self);
            
            NSString *MainString = @"";
            
            if(Call) {
                if(Call.Contact) {
                    MainString = [ContactsManager GetContactTitle:Call.Contact];
                    MainString = [MainString stringByAppendingString:@" "];
                }
                
                
                if(Call.State == CallStateConversation)
                    MainString = [MainString stringByAppendingString:@"(вызов)"];
                
                else if((Call.State == CallStateRinging || Call.State == CallStateDialing || Call.State == CallStateEarlyMedia) && Call.Direction == CallDirectionOutgoing)
                    MainString = [MainString stringByAppendingString:@"(исходящий вызов)"];
                
                
                if(Call.Duration)
                    self.CallDuration = Call.Duration;
                else
                    self.CallDuration = 0;
            }
            
            self.MainString = MainString;
            
        }];
        
        RACSignal *TimerSignal = [RACSignal interval:1 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault]];

        [[TimerSignal filter:^BOOL(id value) {
            @strongify(self);
            return self.Call.State == CallStateConversation;
        }]subscribeNext:^(id x) {
            @strongify(self);
            self.CallDuration += 1;
        }];
        
        [[[RACObserve(self, CallDuration) ignore:nil] filter:^BOOL(NSNumber *Duration) {
            return YES;
        }]subscribeNext:^(id x) {
            @strongify(self);
            NSInteger ti = [x integerValue];
            NSInteger seconds = ti % 60;
            NSInteger minutes = (ti / 60) % 60;
            NSString *time = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
            if(minutes || seconds)
                self.DurationString = time;
            else
                self.DurationString = @"";
        }];
        
        UIWindow *MainWindow = [[UIApplication sharedApplication] keyWindow];
        
        [[[[RACObserve(MainWindow, frame)
            map:^id(NSValue *FrameValue) {
                return @(CGRectGetWidth([FrameValue CGRectValue]));
            }]
            distinctUntilChanged]
            deliverOnMainThread]
            subscribeNext:^(NSNumber *Width) {
                @strongify(self);
                [self KeyWindowWidthChanged:[Width floatValue]];
            }];
        
        }
    
    return self;
}

- (void)SetShouldChangeStatusBarColorBack:(BOOL)ShouldChange {
    self.ShouldChangeStatusBarColorBack = ShouldChange;
}

-(void)ShowInView:(UIView *)View WithTapCallback:(nullable void (^)())Callback{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(View)
            self.ParentView = View;
        else
            self.ParentView = [[[UiNavRouter Router] AppMainNavigationView] view];
        
        self.TapCallback = Callback;
        
        [self ShowBar];
    });
    
    
}

-(void)HideAnimated:(BOOL)Animated WithCompletion:(nullable void (^)())Completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self HideBarAnimated:Animated WithCompletion:Completion];
    });
    
}

#pragma mark - Bar Animation
- (void)ShowBar {
    
    if(self.IsShown)
        return;
    
    self.ReceivedTap = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(StatusBarTappedAction:) name:@"StatusBarTouched" object:nil];
    [self LayoutBar];
    
    CGRect MainStartFrame = self.ParentView.frame;
    CGRect MainEndFrame = self.ParentView.frame;
    MainStartFrame.size.height-=20;
    MainStartFrame.origin.y+=20;
    MainEndFrame.size.height-=40;
    MainEndFrame.origin.y+=40;
    self.ParentView.frame = MainStartFrame;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.ParentView.frame = MainEndFrame;
        self.BarHeight.constant = 40;
        self.BarTop.constant = -40;
    }completion:^(BOOL finished) {
        self.IsShown = YES;
        [self LayoutLabel];
        [self FadeInLabel];
        [self AddTouchRecogniser];
    }];
    
}

- (void)HideBarAnimated:(BOOL) Animated WithCompletion:(nullable void (^)())Completion {
    
    if(!self.IsShown)
        return;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"StatusBarTouched" object:nil];
    
    CGRect MainViewEndFrame = self.ParentView.frame;
    MainViewEndFrame.size.height+=40;
    MainViewEndFrame.origin.y-=40;
    
    self.IsShown = NO;
    [self RemoveTouchRecogniser];
    
    if(Animated)
    {
        if(self.Label.alpha)
            [self FadeOutLabel];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.ParentView.frame = MainViewEndFrame;
        }completion:^(BOOL finished) {
            if(self.ShouldChangeStatusBarColorBack)
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
            [self RemoveLabel];
            [self RemoveBar];
            if(Completion)
                Completion();
        }];

    }
    else
    {
        if(self.ShouldChangeStatusBarColorBack)
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

        self.ParentView.frame = MainViewEndFrame;
        [self RemoveLabel];
        [self RemoveBar];
        if(Completion)
            Completion();
    }

}

#pragma mark - Label Animation
- (void)FadeInLabel{
    
    self.Label.alpha = 0;
    
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut animations:^{
        self.Label.alpha = 1;
    }completion:^(BOOL finished) {
        if(self.IsShown)
            [self FadeOutLabel];
    }];
}

- (void)FadeOutLabel{
    
    self.Label.alpha = 1;
    
    [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn animations:^{
        self.Label.alpha = 0;
    }completion:^(BOOL finished) {
        if(self.IsShown)
            [self FadeInLabel];
    }];
}


#pragma mark - Layout
- (void)LayoutBar {
    
    self.Bar = [UIView new];
    self.Bar.translatesAutoresizingMaskIntoConstraints = NO;
    //Green
    //[self.Bar setBackgroundColor:[UIColor colorWithRed:0.26 green:0.84 blue:0.31 alpha:1]];
    [self.Bar setBackgroundColor:[UIColor colorWithRed:0.96 green:0.2 blue:0.16 alpha:1]];
    
    NSLayoutConstraint *LeadingConstraint = [NSLayoutConstraint constraintWithItem:self.Bar
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.ParentView
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1 constant:0];
    
    NSLayoutConstraint *TrailingConstraint = [NSLayoutConstraint constraintWithItem:self.Bar
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.ParentView
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1 constant:0];
    
    self.BarTop = [NSLayoutConstraint constraintWithItem:self.Bar
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.ParentView
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1 constant:0];
    self.BarHeight = [NSLayoutConstraint constraintWithItem:self.Bar
                                                  attribute:NSLayoutAttributeHeight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:nil
                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                 multiplier:1 constant:0];
    
    [self.ParentView addSubview:self.Bar];
    [self.ParentView addConstraints:@[LeadingConstraint, TrailingConstraint, self.BarTop]];
    [self.Bar addConstraints:@[self.BarHeight]];
}

- (void)LayoutLabel {

    self.Label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.Bar.frame.size.width, 20)];
    self.Label.textAlignment = NSTextAlignmentCenter;
    self.Label.text = @"";
    self.Label.alpha = 0;
    [self.Label setNuiClass:@"UiInCallStatusBarLabel"];
    
    [self.Bar addSubview:self.Label];
    
    RACSignal *LabelSignal =
    [RACSignal combineLatest:@[RACObserve(self, MainString), RACObserve(self, DurationString)]
                      reduce:^id(NSString *Main, NSString *Duration) {
                          return [NSString stringWithFormat:@"%@ %@", Main, Duration];
                      }];
    
    RAC(self.Label, text) = [LabelSignal deliverOnMainThread];
}

- (void)RemoveLabel {
    [self.Label removeFromSuperview];
}

- (void)RemoveBar {
    [self.Bar removeFromSuperview];
}

#pragma mark - Touch Recognition

- (void) AddTouchRecogniser {
    [self SetupGestureRecogniser];
    [[[UIApplication sharedApplication] keyWindow] addGestureRecognizer:self.TapRecogniser];
}

- (void) RemoveTouchRecogniser {
    [[[UIApplication sharedApplication] keyWindow] removeGestureRecognizer:self.TapRecogniser];
}

- (void) SetupGestureRecogniser {
    
    self.TapRecogniser.cancelsTouchesInView = NO;
    
    RACSignal *HeightSig =
    [RACObserve(self, Bar.bounds) map:^id(NSValue *Frame) {
        return @(CGRectGetHeight([Frame CGRectValue]));
    }];
    
    RACSignal *WidthSig =
    [RACObserve(self, Bar.bounds) map:^id(NSValue *Frame) {
        return @(CGRectGetWidth([Frame CGRectValue]));
    }];
    
    @weakify(self);
    [[[HeightSig combineLatestWith:WidthSig] ignore:nil] subscribeNext:^(id x) {
        RACTupleUnpack(NSNumber *Height, NSNumber *Width) = x;
        CGRect rect = CGRectMake(0, 0, [Width floatValue], [Height floatValue]);
        @strongify(self);
        self.TapRecogniser.FrameToTrack = rect;
    }];
    
    [[self.TapRecogniser rac_gestureSignal] subscribeNext:^(id x) {
        @strongify(self);
        [self StatusBarTappedAction:nil];
    }];
}
- (void)StatusBarTappedAction:(NSNotification*)notification {
    if(!self.ReceivedTap) {
        self.ReceivedTap = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.ShouldChangeStatusBarColorBack = NO;
            
            if(self.TapCallback) {
                self.TapCallback();
            }
            
            else {
                [self HideBarAnimated:YES WithCompletion:^{
                    [UiCallsNavRouter ShowCallView];
                }];
            }
            
        });
    }
}

#pragma mark - Orientation Change
- (void)KeyWindowWidthChanged:(CGFloat)NewWidth {
    
    if(!self.IsShown)
        return;
    
    CGRect NewLabelFrame = CGRectMake(0, 20, NewWidth, 20);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.Label.frame = NewLabelFrame;
    }];
}


@end
