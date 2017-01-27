//
//  UiDialerView.m
//  dodicall
//
//  Created by MD on 15.04.16.
//  Copyright © 2016 dodidone. All rights reserved.
//

#import "UiDialerView.h"
#import "NUIParse.h"
#import "NUIRenderer.h"
#import "UiNavRouter.h"
#import "UiDialerContactsView.h"

@interface UiDialerView ()

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *NumBtnsHeightConstraints;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *NumBtnsSuperViews;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *InfoHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *InputPanelTopConstraint;

@property (weak, nonatomic) IBOutlet UILabel *NumberLabel;

@property (weak, nonatomic) IBOutlet UILabel *InfoLabel;

@property (weak, nonatomic) IBOutlet UIButton *AddContactBtn;

@property (weak, nonatomic) IBOutlet UIButton *BackspaceBtn;

@property (weak, nonatomic) UiDialerContactsView *ContactsView;
@property (weak, nonatomic) IBOutlet UIView *ContactsViewContainer;

@property (weak, nonatomic) IBOutlet UIButton *ShowContactsButton;

@end

@implementation UiDialerView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.ViewModel =  [[UiDialerViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self AdjustSizes];
    
    [self BindAll];
    
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    
    RAC(self.NumberLabel, text) = [RACObserve(self.ViewModel, InputText) deliverOnMainThread];
    
    RAC(self.InfoLabel, attributedText) = [RACObserve(self.ViewModel, InfoText) deliverOnMainThread];
    
    RACSignal *TextEmptySigal = [[RACObserve(self.ViewModel, InputText) map:^NSNumber*(NSString *Text) {
        
        return [NSNumber numberWithBool:Text.length > 0 ? NO : YES];
        
    }] distinctUntilChanged];
    
    @weakify(self);
    
    [[TextEmptySigal deliverOnMainThread] subscribeNext:^(NSNumber *IsEmpty) {
        
        @strongify(self);
        
        if([IsEmpty boolValue])
        {
            [self.AddContactBtn setAlpha:0];
            
            [self.BackspaceBtn setAlpha:0];
        }
        else
        {
            [self.AddContactBtn setAlpha:1];
            
            [self.BackspaceBtn setAlpha:1];
        }
        
    }];
    
    
    RAC(self.ShowContactsButton, hidden) = [[[RACObserve(self.ViewModel, ResolvedContact) map:^id(ObjC_ContactModel *Contact) {
        return @(Contact == nil);
    }] distinctUntilChanged] deliverOnMainThread];
    
    RAC(self.AddContactBtn, hidden) = [[[RACObserve(self.ViewModel, ResolvedContact) map:^id(ObjC_ContactModel *Contact) {
        return @(Contact != nil);
    }] distinctUntilChanged] deliverOnMainThread];
    
    
    
    RACSignal *ContactsButtonPressSignal =
    [[self.ShowContactsButton rac_signalForControlEvents:UIControlEventTouchUpInside] map:^id(id value) {
        @strongify(self);
        return @(self.ContactsViewContainer.hidden);
    }];
    
    RACSignal *ContactNotRecognisedSignal =
    [[RACObserve(self.ViewModel, ResolvedContact)
        filter:^BOOL(ObjC_ContactModel *Contact) {
            @strongify(self);
            return (Contact == nil && !self.ContactsViewContainer.hidden);
        }]
        map:^id(id value) {
            return @(NO);
        }];
    
    [self rac_liftSelector:@selector(SetContactsViewVisibility:) withSignals:[[[ContactsButtonPressSignal merge:ContactNotRecognisedSignal] distinctUntilChanged] deliverOnMainThread], nil];
    
    
    
    RAC(self.ContactsView.ViewModel, ContactModel) = [RACObserve(self.ViewModel, ResolvedContact) doNext:^(id x) {
        @strongify(self);
        self.ContactsView.ViewModel.WrittenNumber = self.ViewModel.InputText;
    }];
    
    RAC(self.ViewModel, InputText) = [RACObserve(self.ContactsView.ViewModel, SelectedNumber) ignore:nil];
}

//TODO: Check
- (void)AdjustSizes
{
    if (self.ViewModel.IsSmallDevice)
    {
        
        for (NSLayoutConstraint *HeightConstraint in self.NumBtnsHeightConstraints)
        {
            
            HeightConstraint.constant = 60;
        }
        
        for (UIView *View in self.NumBtnsSuperViews)
        {
            
            View.nuiClass = [View.nuiClass stringByAppendingString:@"Compact"];
        }
        
        self.InfoHeightConstraint.constant = 22;
        
        self.InputPanelTopConstraint.constant = -199;
    }
}

- (void)SetNumBtnSuperViewHighlighted:(UIView *) View Highlighted:(BOOL) Highlighted
{
  
    [NUIRenderer renderView:View withClass:[NSString stringWithFormat:@"%@%@",View.nuiClass,Highlighted?@"Highlighted":@""]];
    
    for (UIView *Subview in View.subviews)
    {
        
        if([Subview isKindOfClass:[UILabel class]])
        {
            [(UILabel *)Subview setHighlighted:Highlighted];
        }
    }
}

- (void)SetContactsViewVisibility:(NSNumber *)Visibility {
    if([Visibility boolValue]) {
        self.ContactsViewContainer.alpha = 0;
        self.ContactsViewContainer.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.ContactsViewContainer.alpha = 1;
        }];
    }
    else {
        [UIView animateWithDuration:0.2 animations:^{
            self.ContactsViewContainer.alpha = 0;
        } completion:^(BOOL finished) {
            self.ContactsViewContainer.hidden = YES;
        }];
    }
}

- (IBAction)NumBtnTouchDownAction:(UIButton *)Sender
{
    [self SetNumBtnSuperViewHighlighted:Sender.superview Highlighted:YES];
    
    NSString *Character = ((UILabel*)Sender.superview.subviews[1]).text;
    
    [self.ViewModel PlayDtmf:Character];
    
    [self.ViewModel AddCharacterToNumber:Character];
    
}

- (IBAction)NumBtnTouchUpAction:(UIButton *)sender
{
    [self SetNumBtnSuperViewHighlighted:sender.superview Highlighted:NO];
    
    [self.ViewModel StopDtmf];
    
}
- (IBAction)NumBtnLongPressAction:(UILongPressGestureRecognizer *) Sender
{
    if (Sender.state == UIGestureRecognizerStateBegan)
    {
        [self.ViewModel ReplaceLastCharacterInNumberWith:((UILabel*)Sender.view.superview.subviews[2]).text];
    }
    
    
}

- (IBAction)BackspaceBtnAction:(id)Sender
{
    [self.ViewModel DeleteLastCharacterFromNumber];
}

- (IBAction)BackspaceBtnLongPressAction:(UILongPressGestureRecognizer *)Sender
{
    if (Sender.state == UIGestureRecognizerStateBegan)
    {
        [self.ViewModel ClearNumber];
    }
}

- (IBAction)AddContactBtnAction:(id)Sender
{
    [UiNavRouter ShowComingSoon];
}

- (IBAction)CallBtnAction:(id)Sender
{
    [self.ViewModel StartCall];
}

- (IBAction)ConferenceBtnAction:(id)Sender
{
    [UiNavRouter ShowComingSoon];
}

- (IBAction)TaxBtnAction:(id)Sender
{
    [UiNavRouter ShowComingSoon];
}

/*
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    CGAffineTransform targetRotation = [coordinator targetTransform];
    CGAffineTransform inverseRotation = CGAffineTransformInvert(targetRotation);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        self.view.transform = CGAffineTransformConcat(self.view.transform, inverseRotation);
        
        self.view.frame = self.view.bounds;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
}
 */
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"UiDialerContactsEmbed"]) {
        self.ContactsView = segue.destinationViewController;
    }
}


@end
