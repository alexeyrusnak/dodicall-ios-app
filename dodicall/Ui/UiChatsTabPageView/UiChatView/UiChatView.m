//
//  UiChatView.m
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

#import "UiChatView.h"

#import "AppManager.h"

#import "UiChatsTabNavRouter.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#import <NUI/NUIRenderer.h>

#import "UiChatViewMessagesCellIncomingText.h"

#import "UiChatViewMessagesCellOutgoingText.h"

#import "UiChatViewMessagesHeaderCellDate.h"

#import "UiChatViewMessagesHeaderCellNewMessages.h"

#import "UiLogger.h"

#import "CallsManager.h"

#import "UiChatMenuCell.h"

#import "UiChatMenuCellModel.h"

@interface UiChatView ()

// Common

//@property NSMutableArray *BindedDisposableRacArr;

@property (nonatomic, assign) id currentResponder;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;

// Navigation bar

@property (weak, nonatomic) IBOutlet UILabel *HeaderLabel;

@property (weak, nonatomic) IBOutlet UILabel *HeaderDescrLabel;

@property (strong, nonatomic) IBOutlet UIButton *BackButton;

@property (strong, nonatomic) IBOutlet UIButton *CallButton;

@property (strong, nonatomic) IBOutlet UIButton *MenuButton;

@property (weak, nonatomic) IBOutlet UIView *StatusIndicator;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *StatusIndicatorWidthConstraint;

@property CGFloat StatusIndicatorWidthConstraintInitial;

@property (strong, nonatomic) IBOutlet UIButton *SelectAllButton;

@property (strong, nonatomic) IBOutlet UIButton *CancelButton;

@property (weak, nonatomic) IBOutlet UINavigationItem *TopNavBar;

// Footer

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *FooterViewBottomLayoutConstraint;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *FooterHeightConstraint;

@property CGFloat FooterHeightConstraintInitial;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *FooterRightPanelWidthConstraint;

@property CGFloat FooterRightPanelWidthConstraintInitial;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *FooterInputTextViewTopContstraint;


@property (weak, nonatomic) IBOutlet UITextView *FooterInputTextView;

// Footer buttons

@property (weak, nonatomic) IBOutlet UIButton *FooterVideoButton;

@property (weak, nonatomic) IBOutlet UIButton *FooterAudioButton;

@property (weak, nonatomic) IBOutlet UIButton *FooterPhotoButton;

@property (weak, nonatomic) IBOutlet UIButton *FooterSendButton;

@property (weak, nonatomic) IBOutlet UIButton *FooterAttachButton;


// Footer Edit panel
@property (weak, nonatomic) IBOutlet UIView *EditToolBar;

@property (weak, nonatomic) IBOutlet UIButton *DeleteButton;

@property (weak, nonatomic) IBOutlet UILabel *SelectedCellsNumberLabel;

//Menu view
@property (weak, nonatomic) IBOutlet UITableView *MenuTable;

@property (weak, nonatomic) IBOutlet UIView *MenuBottomOverlay;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *MenuTableHeightConstraint;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *HeaderLabelTapRecognizer;

@end

@implementation UiChatView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        //self.BindedDisposableRacArr = [[NSMutableArray alloc]init];
        
        self.ViewModel =  [[UiChatViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.MenuTable setDelegate:self];
    [self.MenuTable setDataSource:self];
    
    [self BindAll];
    
    
}

- (void) viewWillAppear:(BOOL) animated {
    
    //[[[AppManager app] NavRouter].AppTabs.tabBar setHidden:YES];
    
    [super viewWillAppear:animated];
    
    
    //Set visibility of navBar shadow depending on menu visibility
    if(self.MenuTable.hidden)
        [self.navigationController.navigationBar setShadowImage:nil];
    else
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.ViewModel.ChatIsReaded = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    //Set visibility of navBar on
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setShadowImage:nil];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidUnload
{
    [super viewDidUnload];
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatView:viewDidUnload"]];
}

/*
- (void) PrepareToDestroy
{
    return;
    
    [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatView:PrepareToDestroy"]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.ViewModel PrepareToDestroy];
    
    self.ViewModel = nil;
}
 */

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify(self);
    
    UINib *UiChatViewMessagesCellIncomingTextNib = [UINib nibWithNibName:@"UiChatViewMessagesCellIncomingText" bundle:nil];
    [self.MessagesList registerNib:UiChatViewMessagesCellIncomingTextNib forCellReuseIdentifier:@"UiChatViewMessagesCellIncomingText"];
    
    UINib *UiChatViewMessagesCellOutgoingTextNib = [UINib nibWithNibName:@"UiChatViewMessagesCellOutgoingText" bundle:nil];
    [self.MessagesList registerNib:UiChatViewMessagesCellOutgoingTextNib forCellReuseIdentifier:@"UiChatViewMessagesCellOutgoingText"];
    
    UINib *UiChatViewMessagesCellInfoTextNib = [UINib nibWithNibName:@"UiChatViewMessagesCellInfoText" bundle:nil];
    [self.MessagesList registerNib:UiChatViewMessagesCellInfoTextNib forCellReuseIdentifier:@"UiChatViewMessagesCellIdentifierInfoText"];
    
    UINib *UiChatViewMessagesHeaderCellDateNib = [UINib nibWithNibName:@"UiChatViewMessagesHeaderCellDate" bundle:nil];
    [self.MessagesList registerNib:UiChatViewMessagesHeaderCellDateNib forHeaderFooterViewReuseIdentifier:@"UiChatViewMessagesHeaderCellDate"];
    
    UINib *UiChatViewMessagesHeaderCellNewMessagesNib = [UINib nibWithNibName:@"UiChatViewMessagesHeaderCellNewMessages" bundle:nil];
    [self.MessagesList registerNib:UiChatViewMessagesHeaderCellNewMessagesNib forHeaderFooterViewReuseIdentifier:@"UiChatViewMessagesHeaderCellNewMessages"];
    
    RAC(self.HeaderLabel,text) = [RACObserve(self.ViewModel, HeaderLabelText) deliverOnMainThread];
    
    RAC(self.HeaderDescrLabel,text) = [RACObserve(self.ViewModel, HeaderDescrLabelText) deliverOnMainThread];
    
    [self.HeaderLabelTapRecognizer.rac_gestureSignal subscribeNext:^(id x) {
        @strongify(self);
        [self.ViewModel.ShowChatUsers execute:nil];
    }];
    
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Superview gesture
    
    [[self.ViewTapGesture rac_gestureSignal] subscribeNext: ^(id value) {
        
        @strongify(self);
        [self resignOnTap:nil];
        
    }];
    
    // Nav bar
    self.StatusIndicatorWidthConstraintInitial = self.StatusIndicatorWidthConstraint.constant;
    
    [[[[RACObserve(self.ViewModel, IsP2P) not] combineLatestWith:RACObserve(self.ViewModel, IsEmptyChat)] deliverOnMainThread] subscribeNext:^(RACTuple *Tuple) {
        
        RACTupleUnpack(NSNumber *IsMultyUserChat, NSNumber *IsEmptyChat) = Tuple;
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            [self SetMultyUserModeEnabled:[IsMultyUserChat boolValue] ForChatEmpty:[IsEmptyChat boolValue]];
            
        //});
        
    }];
    
    [[RACObserve(self.ViewModel, Status) deliverOnMainThread] subscribeNext:^(NSString *StatusString) {
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);

            self.StatusIndicator.nuiClass = [NSString stringWithFormat:@"UiChatsListCellViewStatusIndicator%@", StatusString];
            
            [NUIRenderer renderView:self.StatusIndicator withClass:self.StatusIndicator.nuiClass];
            
            [self.StatusIndicator setNeedsDisplay];
            
        //});
        
    }];
    
    
    // Footer
    
    self.FooterHeightConstraintInitial = self.FooterHeightConstraint.constant;
    
    self.FooterRightPanelWidthConstraintInitial = self.FooterRightPanelWidthConstraint.constant;
    
    [NUIRenderer renderTextView:self.FooterInputTextView withClass:@"UiChatFooterMessageInputTextView"];
    
    [[RACObserve([AppManager app].UserSettingsModel, GuiFontSize) deliverOnMainThread] subscribeNext:^(NSNumber *GuiFontSize) {
        
        @strongify(self);
        
        self.FooterInputTextView.font = [self.FooterInputTextView.font fontWithSize:[GuiFontSize floatValue]];
        
    }];
    
    self.FooterInputTextView.font = [self.FooterInputTextView.font fontWithSize:[AppManager app].UserSettingsModel.GuiFontSize];
    
    [self SetFooterEditModeEnabled:NO];
    
    RAC(self.FooterInputTextView,text) = [RACObserve(self.ViewModel, FooterInputText) deliverOnMainThread];
    
    RAC(self.ViewModel, FooterInputText) = self.FooterInputTextView.rac_textSignal;
    
    [[RACObserve(self.ViewModel, FooterInputText) deliverOnMainThread] subscribeNext:^(NSString *Text) {
        
        @strongify(self);
        
        [self.FooterInputTextView setText:Text];
        
        [self.FooterSendButton setEnabled:(Text.length > 0 ? YES : NO)];
        
        [self AdjustFooterHeightByTextViewContent];
        
    }];
    
    
    [[[[self.ViewModel.DataReloadedSignal filter:^BOOL(NSNumber *Value) {
        return [Value boolValue];
    }] throttle:0.3 afterAllowing:1 withStrike:1] deliverOnMainThread] subscribeNext:^(NSNumber *Value) {

        //dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            
            if(self.ViewModel.MessagesUpdateStages && [self.ViewModel.MessagesUpdateStages count] > 0)
            {
                if([self.ViewModel.MessagesUpdateStages count] > 1)
                {
                    [self.ViewModel.MessagesUpdateStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.MessagesUpdateStages.count - 1)];
                }
                
                NSDictionary *MessagesStage = [self.ViewModel.MessagesUpdateStages lastObject];
                
                self.ViewModel.ThreadSafeSections = [[MessagesStage objectForKey:@"Sections"] copy];
                
                self.ViewModel.ThreadSafeSectionsKeys = [[MessagesStage objectForKey:@"SectionsKeys"] copy];
                
            }
            
            [self.MessagesList reloadData];
            
            [self.MessagesList layoutIfNeeded];
            
            [self AutoScrollToBottom:self.MessagesList];
        
        //});
    }];
    
    // Active mode
    
    [[[RACObserve(self.ViewModel, IsActive) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *IsActive) {
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            [self SetActiveModeEnabled:[IsActive boolValue]];
            
        //});
        
    }];
    
    // Should be closed
    
    [[[RACObserve(self.ViewModel, MarkedAsDeletedAndShouldBeClosed) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *MarkedAsDeletedAndShouldBeClosed) {
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            
            if([MarkedAsDeletedAndShouldBeClosed boolValue])
            {
                //[self BackButtonAction:nil];
                [UiChatsTabNavRouter CloseChatViewAndAllChatSubviewsWithChatId:self.ViewModel.ChatData.Id];
            }
            
        //});
    
    }];
        
    [[RACObserve(self.ViewModel, MenuRowModels) deliverOnMainThread] subscribeNext:^(id x) {
        @strongify(self);
        [self.MenuTable reloadData];
        
        NSInteger newHeight = self.ViewModel.MenuRowModels.count * 50;
        if(self.MenuTableHeightConstraint.constant != newHeight) {
            self.MenuTableHeightConstraint.constant = newHeight;
            [self.view setNeedsUpdateConstraints];
        }
    }];
    
    [[[RACObserve(self.ViewModel, IsEmptyChat) combineLatestWith:RACObserve(self.ViewModel, IsActive)] deliverOnMainThread] subscribeNext:^(RACTuple *Tuple) {
        
        RACTupleUnpack(NSNumber *IsEmpty, NSNumber *IsActive) = Tuple;
        
        @strongify(self);
        self.CallButton.enabled = [IsActive boolValue] && ![IsEmpty boolValue];
    }];
    
    [[[RACObserve(self.ViewModel, EditModeEnabled) take:1] deliverOnMainThread] subscribeNext:^(NSNumber *Enabled) {
        
        @strongify(self);
        
        [self EnableEditMode:[Enabled boolValue] withAnimation:NO];
        
    }];
    
    [[[RACObserve(self.ViewModel, EditModeEnabled) skip:1] deliverOnMainThread] subscribeNext:^(NSNumber *Enabled) {
        
        @strongify(self);
        
        [self EnableEditMode:[Enabled boolValue] withAnimation:YES];
        
    }];
    
    [[RACObserve(self.ViewModel, SelectedCellsNumber) deliverOnMainThread] subscribeNext:^(NSNumber *Number) {
        
        @strongify(self);
        
        [self.SelectedCellsNumberLabel setText:[NSString stringWithFormat:@"%@",Number]];
        
        [self.DeleteButton setEnabled:[Number boolValue]];
        
        
    }];
    
    _IsAllBinded = TRUE;
}

/*
- (void) UnBindAll
{
    for(RACDisposable *Disposable in self.BindedDisposableRacArr)
    {
        [Disposable dispose];
    }
    
    self.BindedDisposableRacArr = nil;
    
    [self.ViewModel UnBindAll];
    
    self.ViewModel = nil;
    
    _IsAllBinded = FALSE;
}
 */


#pragma mark - Buttons actions

- (IBAction)BackButtonAction:(id)sender
{
    //[self PrepareToDestroy];
    [UiChatsTabNavRouter CloseChatViewWhenBackAction];
    
}

- (IBAction)CallButtonAction:(id)sender
{
    
    if([self.ViewModel.ChatData.Contacts count]>2) {
        [UiChatsTabNavRouter ShowChatMakeConferenceForChat:self.ViewModel.ChatData];
    }
    else {
        for(ObjC_ContactModel *contact in self.ViewModel.ChatData.Contacts) {
            if(![contact.Iam boolValue]) {
                [self.CallButton setEnabled:NO];
                [CallsManager StartOutgoingCallToContact:contact WithCallback:^(BOOL Success) {
                    [self.CallButton setEnabled:YES];
                }];
            }
        }
    }
    
}

- (IBAction)MenuButtonAction:(id)sender
{
    [self SwitchMenuVisibility];
    
}
- (void) SwitchMenuVisibility {
    if(self.MenuTable.hidden) {
        [self.currentResponder resignFirstResponder];
        [self OpenMenu];
    }
    else {
        [self CloseMenu];
    }
}

- (void) CloseMenu {
    if(!self.MenuTable.hidden) {
        
        [self.navigationController.navigationBar setShadowImage:nil];
        [UIView animateWithDuration:0.3 animations:^{
            self.MenuTable.alpha = 0;
            self.MenuBottomOverlay.alpha = 0;
        }completion:^(BOOL finished) {
            [self.MenuTable setHidden:YES];
            [self.MenuBottomOverlay setHidden:YES];
            
            [self.ViewTapGesture setCancelsTouchesInView:YES];
            [self.ViewTapGesture setDelaysTouchesEnded:YES];
        }];
    }
}
- (void) OpenMenu {
    if(self.MenuTable.hidden) {
        
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
        [self.MenuTable setHidden:NO];
        [self.MenuBottomOverlay setHidden:NO];
        [UIView animateWithDuration:0.3 animations:^{
            self.MenuTable.alpha = 1;
            self.MenuBottomOverlay.alpha = 0.35;
        }completion:^(BOOL finished) {
            [self.ViewTapGesture setCancelsTouchesInView:NO];
            [self.ViewTapGesture setDelaysTouchesEnded:NO];
        }];
    }
}

- (IBAction)SelectAllButtonAction:(id)sender
{
    for (int section = 0; section < [self.MessagesList numberOfSections]; section++)
    {
        for (int row = 0; row < [self.MessagesList numberOfRowsInSection:section]; row ++)
        {
            NSIndexPath *IndexPath = [NSIndexPath indexPathForRow:row inSection:section];
            
            [self SelectCell:YES withIndexPath:IndexPath];
        }
    }
    
}

- (IBAction)CancelButtonAction:(id)sender
{
    [self.ViewModel EnableEditMode:FALSE];    
}

- (IBAction)DeleteAction:(id)sender
{
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    
    
    UIAlertAction* DeleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"ChatEditMenu_DeleteMessages", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [self.ViewModel DeleteSelectedMessages];
                                                             [self.ViewModel EnableEditMode:NO];
                                                             
                                                             
                                                         }];
    
    [alert addAction:DeleteAction];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
    
    
    
}


#pragma mark Keyboard delegates

- (void)KeyboardWillShow:(NSNotification*)Notification {
    
    [self AdjustingHeightWhenKeyboard:TRUE withNotification:Notification];
}

- (void)KeyboardWillHide:(NSNotification*)Notification {
    
    [self AdjustingHeightWhenKeyboard:FALSE withNotification:Notification];
}

- (void)AdjustingHeightWhenKeyboard:(BOOL) Show withNotification:(NSNotification*)Notification  {
    
    
    NSDictionary *userInfo = Notification.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
    
    self.FooterViewBottomLayoutConstraint.constant = (Show ?( -CGRectGetHeight(keyboardFrameEnd)) : 0);
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        
        //self.view.frame = CGRectMake(0, 0, keyboardFrameEnd.size.width, keyboardFrameEnd.origin.y);
        
        [self.view layoutIfNeeded];
        
        
    } completion:nil];
    
}


#pragma mark UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    self.currentResponder = textField;
    
}

- (void)textViewDidBeginEditing:(UITextView *)TextView {
    
    self.currentResponder = TextView;
    
    if(TextView == self.FooterInputTextView)
        [self SetFooterEditModeEnabled:YES];
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

- (void)textViewDidEndEditing:(UITextView *)TextView
{
    if(TextView == self.FooterInputTextView)
        [self SetFooterEditModeEnabled:NO];
}

- (void)resignOnTap:(id)iSender
{
    [self.currentResponder resignFirstResponder];
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    
    @weakify(self);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        @strongify(self);
        
        [self CloseMenu];
        
    });
}

-(BOOL)textFieldShouldReturn:(UITextField *)TextField
{
    
    [self resignOnTap:nil];
    
    return YES;
}

-(BOOL)textViewShouldReturn:(UITextView *)TextView
{
    
    [self resignOnTap:nil];
    
    return YES;
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == self.MessagesList)
        return [self.ViewModel.ThreadSafeSectionsKeys count];
    else return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.MessagesList)
        return [[self RowsOfTable:tableView InSection:section] count];
    else
        return [self.ViewModel.MenuRowModels count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == self.MessagesList) {
        UiChatViewMessagesCell *cell = (UiChatViewMessagesCell *)[self CellForTableView:tableView AtIndexPath:indexPath];
        
        
        return cell;
    }
    else {
        UiChatMenuCell *cell;
        
        if(indexPath.row == 0)
            cell = [tableView dequeueReusableCellWithIdentifier:@"UiChatMenuCellTop"];
        else
            cell = [tableView dequeueReusableCellWithIdentifier:@"UiChatMenuCell"];
        
        UiChatMenuCellModel *cellModel = (UiChatMenuCellModel *)[self.ViewModel.MenuRowModels objectAtIndex:indexPath.row];
        
        [cell.Image setImage:[UIImage imageNamed:cellModel.ImageName]];
        [cell.Title setText:cellModel.Title];
        
        
        return cell;
    }
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(tableView != self.MessagesList)
        return;
    
    
    UiChatViewMessagesCell *_cell = (UiChatViewMessagesCell *)cell;
    
    [_cell SetupAll];
    
    if([_cell respondsToSelector:@selector(MessageContactStatusPanelStatus)])
    {
        UIView *Status = _cell.MessageContactStatusPanelStatus;
        
        [[[RACObserve(_cell.ViewModel, Status) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSString *StatusString) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                Status.nuiClass = [NSString stringWithFormat:@"UiChatsListCellViewStatusIndicator%@", StatusString];
                
                [NUIRenderer renderView:Status withClass:Status.nuiClass];
                
                [Status setNeedsDisplay];
            });
            
        }];
    }
        
    if([_cell.ViewModel.IsSelected boolValue])
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:NO];

    
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    if(![self.ViewModel.EditModeEnabled boolValue])
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        if(tableView == self.MenuTable) {
            UiChatMenuCellModel *cellModel = [self.ViewModel.MenuRowModels objectAtIndex:indexPath.row];
            [cellModel.SelectCommand execute:nil];
        }
        
    }
    else
    {
        if(tableView == self.MessagesList)
        {
            
            UiChatViewMessagesCellModel *MessageModel = (UiChatViewMessagesCellModel *)[[self RowsOfTable:tableView InSection:indexPath.section] objectAtIndex:indexPath.row];
            
            if(![self.ViewModel SelectCell:YES withMessagesCellModel:MessageModel])
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
        }
        
    }
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UiChatViewMessagesCellModel *MessageModel = (UiChatViewMessagesCellModel *)[[self RowsOfTable:tableView InSection:indexPath.section] objectAtIndex:indexPath.row];
    
    [self.ViewModel SelectCell:NO withMessagesCellModel:MessageModel];
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == self.MessagesList) {
        UiChatViewMessagesCellModel *MessageModel = (UiChatViewMessagesCellModel *)[[self RowsOfTable:tableView InSection:indexPath.section] objectAtIndex:indexPath.row];
        
        return MessageModel.CellHeight;
    }
    else {
        return 50;
    }

}


-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if(tableView == self.MessagesList) {
        NSString *CellIdentifier = [self CellHeaderIdentifierForTableView:tableView ForSection:section];
        
        UiChatViewMessagesHeaderCellDate *HeaderView = (UiChatViewMessagesHeaderCellDate *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:CellIdentifier];
        
        UILabel *HeaderViewTitle = (UILabel *)[HeaderView viewWithTag:100];
        
        UiChatViewMessagesHeaderCellModel *SectionModel = (UiChatViewMessagesHeaderCellModel *)[self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:section];
        
        [HeaderViewTitle setText:[NSString stringWithFormat:@"   %@   ", SectionModel.Title]];
        
        return HeaderView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView == self.MessagesList) {
        return 30;
    }
    return 0;
}

- (NSArray *) RowsOfTable:(UITableView *)TableView InSection:(NSInteger)Section
{
    if(TableView == self.MessagesList)
    {
        UiChatViewMessagesHeaderCellModel *SectionModel = (UiChatViewMessagesHeaderCellModel *)[self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:Section];
        
        return [self.ViewModel.ThreadSafeSections objectForKey:SectionModel.Key];
    }
    
    return nil;
}

- (NSString *) CellIdentifierForTableView:(UITableView *)TableView AtIndexPath:(NSIndexPath *)IndexPath
{
    NSString *CellIdentifier = @"";
    
    if(TableView == self.MessagesList)
    {
        UiChatViewMessagesCellModel *MessageModel = (UiChatViewMessagesCellModel *)[[self RowsOfTable:TableView InSection:IndexPath.section] objectAtIndex:IndexPath.row];
        
        if([MessageModel.MessageType isEqualToString:UiChatMessageTypeText])
        {
            if([MessageModel.MessageDirection isEqualToString:UiChatMessageDirectionTypeOutgoing])
            {
                CellIdentifier = UiChatViewMessagesCellIdentifierOutgoingText;
            }
            
            else if([MessageModel.MessageDirection isEqualToString:UiChatMessageDirectionTypeIncoming])
            {
                CellIdentifier = UiChatViewMessagesCellIdentifierIncomingText;
            }
        }
        
        else if([MessageModel.MessageType isEqualToString:UiChatMessageTypeInfoText])
        {
            CellIdentifier = UiChatViewMessagesCellIdentifierInfoText;
        }
    }
    
    return CellIdentifier;
}

- (UITableViewCell *) CellForTableView:(UITableView *)TableView AtIndexPath:(NSIndexPath *)IndexPath
{
    if(TableView == self.MessagesList)
    {
        NSString *CellIdentifier = [self CellIdentifierForTableView:TableView AtIndexPath:IndexPath];
        
        UiChatViewMessagesCell *cell = (UiChatViewMessagesCell *)[TableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        UiChatViewMessagesCellModel *MessageModel = (UiChatViewMessagesCellModel *)[[self RowsOfTable:TableView InSection:IndexPath.section] objectAtIndex:IndexPath.row];
        
        cell.ViewModel = MessageModel;
        
        cell.ChatView = self;
        
        cell.CellIndexPath = IndexPath;
        
        return cell;
    }
    
    return nil;
}

- (NSString *) CellHeaderIdentifierForTableView:(UITableView *)TableView ForSection:(NSInteger)Section
{
    NSString *CellIdentifier = @"";
    
    if(TableView == self.MessagesList)
    {
        UiChatViewMessagesHeaderCellModel *SectionModel = (UiChatViewMessagesHeaderCellModel *)[self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:Section];
        
        return SectionModel.Type;
    }
    
    return CellIdentifier;
}

- (void) ScrollToBottom:(UITableView *)TableView
{
    [self ScrollToBottom:TableView withAnimation:YES];
}

- (void) AutoScrollToBottom:(UITableView *)TableView
{
    if(self.ViewModel.AutoScrollEnabled)
        [self ScrollToBottom:TableView withAnimation:NO];
}

- (void) ScrollToBottom:(UITableView *)TableView withAnimation:(BOOL) Animated
{
    if(TableView == self.MessagesList)
    {
        
        NSInteger LastSection = [self.ViewModel.ThreadSafeSectionsKeys count] - 1;
        
        if(LastSection < 0)
            return;
        
        NSInteger LastRowInLastSection = [[self RowsOfTable:TableView InSection:LastSection] count] - 1;
        
        if(LastRowInLastSection < 0)
            return;
        
        NSIndexPath *IndexPath = [NSIndexPath indexPathForRow:LastRowInLastSection inSection:LastSection];
        
        /*
        NSIndexPath* IndexPath = [NSIndexPath indexPathForRow: ([self.MessagesList numberOfRowsInSection:([self.MessagesList numberOfSections]-1)]-1) inSection: ([self.MessagesList numberOfSections]-1)];
         */
        
        [TableView scrollToRowAtIndexPath:IndexPath atScrollPosition:UITableViewScrollPositionBottom animated:Animated];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self resignOnTap:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Check for Autoscroll mode
    
    UITableView* TableView = (UITableView*) scrollView;
    
    if(TableView == self.MessagesList)
    {
        if(self.MessagesList.contentOffset.y >= (self.MessagesList.contentSize.height - self.MessagesList.bounds.size.height))
        {
            self.ViewModel.AutoScrollEnabled = YES;
        }
        else
        {
            self.ViewModel.AutoScrollEnabled = NO;
        }
    }
}

- (BOOL)tableView:(UITableView *)TableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)IndexPath
{
    BOOL Should = NO;
    
    if(TableView == self.MessagesList)
    {
        UiChatViewMessagesCell *cell = (UiChatViewMessagesCell *)[self CellForTableView:TableView AtIndexPath:IndexPath];
        
        Should = [self.ViewModel CanEditSelectCellWithModel:cell.ViewModel];
    }
    
    
    if(Should)
    {
        //Setup additional items for Edit menu
    
        UIMenuItem *DeleteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"ChatEditMenu_Delete",nil) action:@selector(Delete:)];
        
        UIMenuItem *EditMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"ChatEditMenu_Edit",nil) action:@selector(Edit:)];
        
        [[UIMenuController sharedMenuController] setMenuItems: @[EditMenuItem, DeleteMenuItem]];
        
        [[UIMenuController sharedMenuController] update];
    }
    else
    {
        [[UIMenuController sharedMenuController] setMenuItems: nil];
        
        [[UIMenuController sharedMenuController] update];
    }
    
    
    return Should;
}

- (BOOL)tableView:(UITableView *)TableView canEditRowAtIndexPath:(NSIndexPath *)IndexPath
{
    
    BOOL CanEdit = NO;
    
    if(TableView == self.MessagesList)
    {
        UiChatViewMessagesCell *cell = (UiChatViewMessagesCell *)[self CellForTableView:TableView AtIndexPath:IndexPath];
        
        CanEdit = [self.ViewModel CanEditSelectCellWithModel:cell.ViewModel];
    }
    
    return CanEdit;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return YES;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    // required
}

-(void) Edit: (id) sender
{
    
}

-(void) Delete: (id) sender
{
    
}

#pragma mark Footer

- (IBAction)FooterVideoButtonAction:(id)sender
{
    [UiNavRouter ShowComingSoon];
}

- (IBAction)FooterAudioButtonAction:(id)sender
{
    [UiNavRouter ShowComingSoon];
}

- (IBAction)FooterPhotoButtonAction:(id)sender
{
    [UiNavRouter ShowComingSoon];
}

- (IBAction)FooterSendButtonAction:(id)sender
{
    //[UiNavRouter ShowComingSoon];
    //[Chatsma]
    
    //[self ScrollToBottom:self.MessagesList];
    
    [self.ViewModel SendTextMessage];
}

- (IBAction)FooterAttachButtonAction:(id)sender
{
    [UiNavRouter ShowComingSoon];
}

- (void) AdjustFooterHeightByTextViewContent
{
    CGFloat FixedWidth = self.FooterInputTextView.frame.size.width;
    CGSize NewSize = [self.FooterInputTextView sizeThatFits:CGSizeMake(FixedWidth, MAXFLOAT)];
    
    CGFloat Default = self.FooterHeightConstraintInitial;
    
    CGFloat Margins = 2 * self.FooterInputTextViewTopContstraint.constant;
    
    CGFloat Max = 5 * (Default - Margins);
    
    self.FooterHeightConstraint.constant = (NewSize.height > Default - Margins) ? (NewSize.height < Max ? NewSize.height + Margins : Max + Margins) : Default;
    
}

#pragma mark Modes

- (void) SetFooterEditModeEnabled: (BOOL) Enabled
{
    
    if(Enabled && self.ViewModel.IsActive)
    {
        [self.FooterVideoButton setHidden:YES];
        [self.FooterPhotoButton setHidden:YES];
        [self.FooterAudioButton setHidden:YES];
        
        [self.FooterSendButton setHidden:NO];
        
        self.FooterRightPanelWidthConstraint.constant = self.FooterRightPanelWidthConstraintInitial / 2;
        
        if(self.ViewModel.AutoScrollEnabled)
            [self ScrollToBottom:self.MessagesList];
    }
    else
    {
        [self.FooterVideoButton setHidden:NO];
        [self.FooterPhotoButton setHidden:NO];
        [self.FooterAudioButton setHidden:NO];
        
        [self.FooterSendButton setHidden:YES];
        
        self.FooterRightPanelWidthConstraint.constant = self.FooterRightPanelWidthConstraintInitial;
    }
    
}

- (void) SetActiveModeEnabled: (BOOL) Enabled
{
    
    [self.HeaderLabelTapRecognizer setEnabled:Enabled];
    [self.FooterVideoButton setEnabled:Enabled];
    [self.FooterPhotoButton setEnabled:Enabled];
    [self.FooterAudioButton setEnabled:Enabled];
    [self.FooterInputTextView setEditable:Enabled];
    [self.FooterAttachButton setEnabled:Enabled];
    [self.MenuButton setEnabled:Enabled];
    
    if(self.ViewModel.IsEmptyChat)
        [self.CallButton setEnabled:NO];
    else
        [self.CallButton setEnabled:Enabled];
    
    if(!Enabled)
        [self SetFooterEditModeEnabled:Enabled];
}

#pragma mark Orientations

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    //[self.MessagesList reloadData];
    
    __weak UiChatView *_self = self;
    
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:_self.ViewModel
                                   selector:@selector(ReloadData)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark - Multy user chat mode
- (void) SetMultyUserModeEnabled: (BOOL) Enabled ForChatEmpty:(BOOL) Empty
{
    if(Enabled || Empty)
    {
        [self.StatusIndicator setHidden:YES];
        self.StatusIndicatorWidthConstraint.constant = 0;
        self.HeaderDescrLabel.hidden = NO;
    }
    else
    {
        [self.StatusIndicator setHidden:NO];
        self.StatusIndicatorWidthConstraint.constant = self.StatusIndicatorWidthConstraintInitial;
        self.HeaderDescrLabel.hidden = YES;
    }
}

#pragma mark - Edit mode

- (void) EnableEditMode: (BOOL) Enabled withAnimation: (BOOL) Animation
{
    
    [self.MessagesList setEditing:Enabled animated:Animation];
    
    [self.ViewTapGesture setCancelsTouchesInView:!Enabled];
    [self.ViewTapGesture setDelaysTouchesEnded:!Enabled];
    
    [self resignOnTap:nil];
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    if(Enabled)
    {
        NSArray<UIBarButtonItem *> *LeftBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView: self.SelectAllButton]];
        
        NSArray<UIBarButtonItem *> *RightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView: self.CancelButton]];
        
        [self.TopNavBar setLeftBarButtonItems:LeftBarButtonItems animated:YES];
        
        [self.TopNavBar setRightBarButtonItems:RightBarButtonItems animated:YES];
        
        
        
        [UIView animateWithDuration:AnimationDuration animations:^{
            
            if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad )
            {
                [self.TopNavBar.titleView setHidden:YES];
            }
            
            
            [self.EditToolBar setAlpha:1];
            
            [self.EditToolBar setUserInteractionEnabled:YES];
            
            
        } completion:nil];
        
    }
    else
    {
        NSArray<UIBarButtonItem *> *LeftBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView: self.BackButton]];
        
        NSArray<UIBarButtonItem *> *RightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView: self.MenuButton],[[UIBarButtonItem alloc] initWithCustomView: self.CallButton]];

        [self.TopNavBar setLeftBarButtonItems:LeftBarButtonItems animated:YES];
        
        [self.TopNavBar setRightBarButtonItems:RightBarButtonItems animated:YES];
        
        [UIView animateWithDuration:AnimationDuration animations:^{
            
            if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad )
            {
                [self.TopNavBar.titleView setHidden:NO];
            }
            
            CGRect frame = self.TopNavBar.titleView.frame;
            
            frame.size.width = 600;
            
            self.TopNavBar.titleView.frame = frame;
            
            [self.EditToolBar setAlpha:0];
            
            [self.EditToolBar setUserInteractionEnabled:NO];
            
            
        } completion:nil];
        
    }
    
    
    
    [self.TopNavBar.titleView setNeedsLayout];
    [self.TopNavBar.titleView setNeedsDisplay];
    
//    if(!(!Animation && !Enabled))
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.MessagesList reloadData];
//        });
//    }
    
    

}

- (void) SelectCell:(BOOL) Selected withIndexPath:(NSIndexPath *) IndexPath
{
    if(Selected)
    {
        
        
        [self.MessagesList selectRowAtIndexPath:IndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [self tableView:self.MessagesList didSelectRowAtIndexPath:IndexPath];
        
        //UiChatViewMessagesCellModel *MessageModel = (UiChatViewMessagesCellModel *)[[self RowsOfTable:self.MessagesList InSection:IndexPath.section] objectAtIndex:IndexPath.row];
        
        //[self.ViewModel SelectCell:YES withMessagesCellModel:MessageModel];
    }
    else
    {
        [self.MessagesList deselectRowAtIndexPath:IndexPath animated:NO];
        
        UiChatViewMessagesCellModel *MessageModel = (UiChatViewMessagesCellModel *)[[self RowsOfTable:self.MessagesList InSection:IndexPath.section] objectAtIndex:IndexPath.row];
        
        [self.ViewModel SelectCell:NO withMessagesCellModel:MessageModel];
    }
    
}


@end
