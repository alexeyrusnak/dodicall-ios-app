//
//  UiContactProfileView.m
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

#import "UiContactProfileView.h"
#import "UiContactProfileEditView.h"
#import "AppManager.h"

#import "UiContactsTabNavRouter.h"

#import <NUI/NUIRenderer.h>

#import "UiAlertControllerView.h"

#import "UiLogger.h"

#import "CallsManager.h"
#import "ContactsManager.h"
#import "UiInCallStatusBar.h"

@interface UiContactProfileView ()

@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property (weak, nonatomic) IBOutlet UIButton *EditButton;

@property (weak, nonatomic) IBOutlet UILabel *FirstNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *LastNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *StatusLabel;

@property (weak, nonatomic) IBOutlet UIView *StatusIndicator;

@property (weak, nonatomic) IBOutlet UILabel *MyProfileStatusLabel;

@property (weak, nonatomic) IBOutlet UIView *MyProfileStatusIndicator;


@property (weak, nonatomic) IBOutlet UITableView *ContactsTable;

@property (weak, nonatomic) IBOutlet UIScrollView *ScrollView;


//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ContactsTableTopConstraint;



@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ContactsTableHeightConstraint;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *AddContactsTablePanelHeightConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarLogoMark;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarImageView;


@property (weak, nonatomic) IBOutlet UIView *AddContactsTablePanel;


@property (weak, nonatomic) IBOutlet UITableView *AddContactsTable;

@property (weak, nonatomic) IBOutlet UIView *CallControllsPanelView;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *CallControllsPanelHeightConstraint;

@property (assign) CGFloat CallControllsPanelHeightConstraintInitial;

@property (weak, nonatomic) IBOutlet UIView *StatusPanelView;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *StatusPanelHeighConstraint;

@property (assign) CGFloat StatusPanelHeighConstraintInitial;



@property (weak, nonatomic) IBOutlet UIView *AddContactPanel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *AddContactPanelHeightConstraint;

@property (weak, nonatomic) IBOutlet UIButton *AddContactButton;

@property (weak, nonatomic) IBOutlet UIButton *AddContactAndChatButton;


@property (weak, nonatomic) IBOutlet UIButton *AddContactRequestButton;


@property (weak, nonatomic) IBOutlet UIView *RequestInputPanel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *RequestInputPanelHeightConstraint;

@property (assign) CGFloat RequestInputHeighConstraintInitial;

@property (weak, nonatomic) IBOutlet UITextView *RequestInputTextView;


@property (weak, nonatomic) IBOutlet UIView *InviteNotifyPanel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *InviteNotifyPanelHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *InviteNotifyPanelLabel;

@property (weak, nonatomic) IBOutlet UIView *ApplyContactRequestPanel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ApplyContactRequestPanelHeightConstraint;

@property (weak, nonatomic) IBOutlet UIButton *ApplyContactRequestButton;

@property (weak, nonatomic) IBOutlet UIButton *RejectContactRequestButton;

@property (assign) CGFloat InviteNotifyPanelHeightConstraintInitial;

@property (assign) CGFloat ApplyContactRequestPanelHeightConstraintInitial;

@property (nonatomic, assign) id _CurrentResponder;


@property (weak, nonatomic) IBOutlet UIView *BlockedContactPanel;

@property (weak, nonatomic) IBOutlet UIButton *UnblockContactButton;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *BlockedContactPanelHeightConstraint;

@property (assign) CGFloat BlockedContactPanelHeightConstraintInitial;


@property (weak, nonatomic) IBOutlet UITableView *BalanceStatusTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *BalanceStatusTableHeightConstraint;
@property (assign) CGFloat BalanceStatusTableHeightConstraintInitial;


@property (weak, nonatomic) IBOutlet UIView *MyProfileStatusPanel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *MyProfileStatusPanelHeighConstraint;
@property (assign) CGFloat MyProfileStatusPanelHeighConstraintInitial;


@property (weak, nonatomic) IBOutlet UIView *ContactsSectionHeaderPanel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ContactsSectionHeaderPanelHeightConstraint;


@property (weak, nonatomic) IBOutlet UIButton *ProfileHeaderButton;

@property (weak, nonatomic) IBOutlet UIView *RequestSendedPanel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *RequestSendedPanelHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *RequestSendedPanelLabel;
@property (assign) CGFloat RequestSendedPanelHeightConstraintInitial;


@property (weak, nonatomic) IBOutlet UIButton *CallVideoButton;

@property (weak, nonatomic) IBOutlet UIButton *CallButton;

@property (weak, nonatomic) IBOutlet UIButton *ChatButton;

@property (weak, nonatomic) IBOutlet UIButton *ServicesButton;


@property (weak, nonatomic) IBOutlet UIView *MyProfileMenuPanel;

@end

@implementation UiContactProfileView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        self.ViewModel = [[UiContactProfileViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self BindAll];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(OrientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:nil];
    
    if(self.ViewModel.IsIam)
    {
        if(self.ViewModel.IsInTabView)
        {
            [self.EditButton setImage:[UIImage imageNamed:@"settings_toolbar_icon"] forState:UIControlStateNormal];
            
            [NUIRenderer renderButtonAndSetNuiClass:self.EditButton withClass:self.EditButton.nuiClass];
            
            [self.BackButton setEnabled:NO];
            [self.BackButton setHidden:YES];
            [self.MyProfileMenuPanel setHidden:NO];
        }
        else
        {
            [self.EditButton setEnabled:NO];
        }
        
        [[AppManager Manager].UserSession UpdateBalance];
        
    }
    
    [self.view layoutIfNeeded];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    
    self.CallControllsPanelHeightConstraintInitial = self.CallControllsPanelHeightConstraint.constant;
    
    self.StatusPanelHeighConstraintInitial = self.StatusPanelHeighConstraint.constant;
    
    self.RequestInputHeighConstraintInitial = self.RequestInputPanelHeightConstraint.constant;
    
    self.InviteNotifyPanelHeightConstraintInitial = self.InviteNotifyPanelHeightConstraint.constant;
    
    self.ApplyContactRequestPanelHeightConstraintInitial = self.ApplyContactRequestPanelHeightConstraint.constant;
    
    self.BlockedContactPanelHeightConstraintInitial = self.BlockedContactPanelHeightConstraint.constant;
    
    //self.BalanceStatusTableHeightConstraintInitial = self.BalanceStatusTableHeightConstraint.constant;
    
    self.MyProfileStatusPanelHeighConstraintInitial = self.MyProfileStatusPanelHeighConstraint.constant;
    
    self.RequestSendedPanelHeightConstraintInitial = self.RequestSendedPanelHeightConstraint.constant;
    
    
    [self AdjustBalanceStatusTableHeight:NO];
    
    [self SetViewsVisibility];
    
    
    RAC(self.FirstNameLabel,text) = [RACObserve(self.ViewModel, FirstNameLabelText) deliverOnMainThread];
    RAC(self.LastNameLabel,text) = [RACObserve(self.ViewModel, LastNameLabelText) deliverOnMainThread];
    RAC(self.StatusLabel,text) = [RACObserve(self.ViewModel, StatusLabelText) deliverOnMainThread];
    RAC(self.MyProfileStatusLabel, text) = [RACObserve(self.ViewModel, MyProfileStatusLabelText) deliverOnMainThread];
    
    
    @weakify(self);
    
    [[RACObserve(self.ViewModel, ContactData) deliverOnMainThread] subscribeNext:^(id x) {
        @strongify(self);
        [self SetViewsVisibility];
    }];
    
//    Check: added delay to fix NUIRenderer bug during open animation
    [[[[[RACObserve(self.ViewModel, Status)
        distinctUntilChanged]
        map:^id(NSString *StatusString) {

            return RACTuplePack(([NSString stringWithFormat:@"UiContactProfileStatusIndicatorView%@", StatusString]), ([NSString stringWithFormat:@"UiContactProfileButton%@", StatusString]));

        }]
        delay:0.3]
        deliverOnMainThread]
        subscribeNext:^(RACTuple *Status) {
            @strongify(self);

            RACTupleUnpack(NSString *Indicator, NSString *Button) = Status;

            [NUIRenderer renderView:self.StatusIndicator withClass:Indicator];
            [NUIRenderer renderButtonAndSetNuiClass:self.CallButton withClass:Button];
            [NUIRenderer renderButtonAndSetNuiClass:self.CallVideoButton withClass:Button];
            [NUIRenderer renderButtonAndSetNuiClass:self.ChatButton withClass:Button];

            [self.StatusIndicator setNeedsDisplay];
            [self.CallButton setNeedsDisplay];
            [self.CallVideoButton setNeedsDisplay];
            [self.ChatButton setNeedsDisplay];
        }];
    

    
    [[[[RACObserve(self.ViewModel, MyProfileStatus)
        map:^id(NSString *StatusString) {
            return [NSString stringWithFormat:@"UiContactProfileStatusIndicatorView%@", StatusString];
        }]
        delay:0.3]
        deliverOnMainThread]
        subscribeNext:^(NSString *StatusClass) {
            @strongify(self);

            [NUIRenderer renderView:self.MyProfileStatusIndicator withClass:StatusClass];
            [self.MyProfileStatusIndicator setNeedsDisplay];
        }];
    
    
    
    [[RACObserve(self.ViewModel, ContactsTable)
        deliverOnMainThread]
        subscribeNext:^(id x) {
            @strongify(self);
        
            [self.ContactsTable reloadData];
            [self AdjustContactsTableViewHeight];
        }];
    
    
    
    [[RACObserve(self.ViewModel, AddContactsTable)
        deliverOnMainThread]
        subscribeNext:^(id x) {
            @strongify(self);
        
            [self.AddContactsTable reloadData];
            [self AdjustAddContactsTablePanelViewHeight];
        }];
    
    

    [[RACObserve(self.ViewModel, SavingProcessState)
        deliverOnMainThread]
        subscribeNext:^(NSNumber *Value) {
        
            @strongify(self);
            
            if([Value intValue] == UiContactProfileSavingStateStart)
                [[AppManager app].NavRouter ShowPageProcessWithView:self.view];
            
            if([Value intValue] == UiContactProfileSavingStateCompleteWithSuccess || [Value intValue] ==UiContactProfileSavingStateCompleteWithError)
                [[AppManager app].NavRouter HidePageProcessWithView:self.view];
            
            if([Value intValue] == UiContactProfileSavingStateCompleteWithSuccess)
                [self CompleteSaveActionWithSuccess:YES];
            
            if([Value intValue] == UiContactProfileSavingStateCompleteWithError)
                [self CompleteSaveActionWithSuccess:NO];
        }];
    
    
    [self SetRequestInputPanelVisibility:self.ViewModel.IsRequestInputPanelOpened withAnimation:NO];
    
    [[[RACObserve(self.ViewModel, IsRequestInputPanelOpened)
        distinctUntilChanged]
        deliverOnMainThread]
        subscribeNext:^(NSNumber *IsOpened) {
            @strongify(self);
            
            if(self.ViewModel.IsIam) {
                [self SetRequestInputPanelVisibility:NO withAnimation:NO];
                return;
            }
            
            [self SetRequestInputPanelVisibility:[IsOpened boolValue] withAnimation:[IsOpened boolValue]];
        }];
    
    
    [self SetApplyRequestContactAndInvitePanelsVisibility:[self.ViewModel.IsInvite boolValue] withAnimation:NO];
    
    [[[RACObserve(self.ViewModel, IsInvite)
        distinctUntilChanged]
        deliverOnMainThread]
        subscribeNext:^(NSNumber *IsOpened) {
            @strongify(self);
            
            if(self.ViewModel.IsIam) {
                [self SetApplyRequestContactAndInvitePanelsVisibility:NO withAnimation:NO];
                return;
            }
            
            [self SetApplyRequestContactAndInvitePanelsVisibility:[IsOpened boolValue] withAnimation:NO];
        }];
    
    [self SetBlockedContactPanelsVisibility:self.ViewModel.IsBlocked withAnimation:NO];
    
    [[[RACObserve(self.ViewModel, IsBlocked)
        distinctUntilChanged]
        deliverOnMainThread]
        subscribeNext:^(NSNumber *IsBlocked) {
            @strongify(self);
            
            if(self.ViewModel.IsIam) {
                [self SetBlockedContactPanelsVisibility:NO withAnimation:NO];
                return;
            }
            
            [self SetBlockedContactPanelsVisibility:[IsBlocked boolValue] withAnimation:NO];
        }];
    
    [self SetRequestSendedPanelVisibility:[self.ViewModel.IsRequest boolValue] withAnimation:NO];
    
    
    
    [[[[RACSignal combineLatest:@[RACObserve(self.ViewModel, IsRequest), RACObserve(self.ViewModel, IsDeclinedRequest)]]
        distinctUntilChanged]
        deliverOnMainThread]
        subscribeNext:^(id x){
            @strongify(self);
            
            if(self.ViewModel.IsIam || [self.ViewModel.IsDeclinedRequest boolValue]) {
                [self SetRequestSendedPanelVisibility:NO withAnimation:NO];
            }
            
            else
            {
                [self SetRequestSendedPanelVisibility:[self.ViewModel.IsRequest boolValue] withAnimation:NO];
            }
            
        }];
    
    
    RAC(self.AvatarImageView, image) = [[ContactsManager AvatarImageSignalForPathSignal:RACObserve(self.ViewModel, AvatarPath) WithTakeUntil:[RACSignal never]] deliverOnMainThread];
    
    [[RACObserve([AppManager Manager].UserSession, IsBalanceAvailable)
      deliverOnMainThread]
     subscribeNext:^(id x) {
         @strongify(self);
         
         if(self.ViewModel.IsIam)
         {
             [self.BalanceStatusTable reloadData];
             [self AdjustBalanceStatusTableHeight:NO];
         }
         
     }];
    
    
    _IsAllBinded = TRUE;
}



- (IBAction)BackButtonAction:(id)sender
{

    if(self.ViewModel.NeedToBeSaved) {
        [self.ViewModel.SaveCommand execute:nil];
    }
    else {
        if(self.CallbackOnBackAction)
            self.CallbackOnBackAction();
        
        else
            [UiContactsTabNavRouter CloseProfileViewWhenBackAction];
    }
    
    
}

- (IBAction)AddContactButtonAction:(id)sender
{
    
    [self.AddContactButton setEnabled:NO];
    [self.AddContactAndChatButton setEnabled:NO];
    [self.ViewModel.SaveCommand execute:nil];
    
}

- (IBAction)AddContactAndChatButtonAction:(id)sender
{
    
    [self.AddContactButton setEnabled:NO];
    [self.AddContactAndChatButton setEnabled:NO];
    [self.ViewModel.SaveCommand execute:nil];
    
}

- (IBAction)AddContactRequestButtonAction:(id)sender
{
    [self.ViewModel setIsRequestInputPanelOpened:!self.ViewModel.IsRequestInputPanelOpened];
}

- (IBAction)ApplyContactRequestButtonAction:(id)sender
{
    [UiLogger WriteLogInfo:@"UiContactsRosterView: Apply contact button tapped"];
    
    [self AcceptAction:YES];
}

- (IBAction)RejectContactRequestButtonAction:(id)sender
{
    [UiLogger WriteLogInfo:@"UiContactProfileView: Reject contact button tapped"];
    
    [self AcceptAction:NO];
}

-(void) AcceptAction:(BOOL) Accept
{
    
    [self.ApplyContactRequestButton setEnabled:NO];
    
    [self.RejectContactRequestButton setEnabled:NO];
    
    
    void (^Callback)(BOOL) = ^(BOOL Success){
        
        if(Success)
        {
            [self.ApplyContactRequestButton setEnabled:NO];
            
            [self.RejectContactRequestButton setEnabled:NO];
            
            [self SetApplyRequestContactAndInvitePanelsVisibility:NO withAnimation:YES];
        }
        else
        {
            [self.ApplyContactRequestButton setEnabled:YES];
            
            [self.RejectContactRequestButton setEnabled:YES];
            
            UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleAlert];
            
            Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotSaved", nil);
            
            UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 
                                                             }];
            
            [Alert addAction:OkAction];
            
            [self presentViewController:Alert animated:YES completion:nil];
        }
        
    };
    
    [self.ViewModel ExecuteAcceptAction:Accept withCallback:Callback];
}

- (IBAction)UnblockContactButtonAction:(id)sender
{
    
    [self.UnblockContactButton setEnabled:NO];
    
    [self SetBlockedContactPanelsVisibility:NO withAnimation:YES];
    
    
    void (^Callback)(BOOL) = ^(BOOL Success){
        
        if(Success)
        {
            [self.UnblockContactButton setEnabled:YES];
        }
        else
        {
            [self.UnblockContactButton setEnabled:YES];
            
            UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleAlert];
            
            Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotSaved", nil);
            
            UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 
                                                             }];
            
            [Alert addAction:OkAction];
            
            [self presentViewController:Alert animated:YES completion:nil];
        }
        
    };
    
    [self.ViewModel ExecuteUnblockAction: Callback];
    
}

- (IBAction)ComingSoonAction:(id)sender
{
    [UiNavRouter ShowComingSoon];
}

- (IBAction)CallButtonAction:(id)sender {
    
    [self.CallButton setEnabled:NO];
    [CallsManager StartOutgoingCallToContact:self.ViewModel.ContactData WithCallback:^(BOOL Success) {
        [self.CallButton setEnabled:YES];
    }];
}

- (IBAction)ChatButtonAction:(id)sender
{
    [UiChatsTabNavRouter CreateAndShowChatViewWithContact:self.ViewModel.ContactData];
}
- (IBAction)EditButtonAction:(id)sender
{
    if(self.ViewModel.IsInTabView && self.ViewModel.IsIam)
    {
        [self performSegueWithIdentifier:UiContactsTabNavRouterSegueShowPreferencesView sender:self];
    }
    else
    {
        [self performSegueWithIdentifier:UiContactsTabNavRouterSegueShowContactProfileEdit sender:self];
    }
}

- (IBAction)LogoutButtonAction:(id)sender
{
    [self ShowLogoutAlert];
}


#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(tableView == self.ContactsTable)
    {
        return [self.ViewModel.ContactsTable count];
    }
    
    else if(tableView == self.AddContactsTable)
    {
        return [self.ViewModel.AddContactsTable count];
    }
    
    else if(tableView == self.BalanceStatusTable)
    {
        if([AppManager app].UserSession.IsBalanceAvailable)
            return 2;
        else
            return 1;
    }
    
    return 0;
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableView == self.ContactsTable)
    {
        NSString *CellIdentifier = @"UiContactProfileContactsTableCellView";
        
        if(self.ViewModel.IsDirectoryRemoteType || [self.ViewModel.IsRequest boolValue] || [self.ViewModel.IsInvite boolValue])
        {
            CellIdentifier = @"UiContactProfileContactsTableCellViewRemote";
        }
        
        if(self.ViewModel.IsIam)
        {
            CellIdentifier = @"UiContactProfileContactsTableCellViewIam";
        }
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        UiContactProfileContactsTableCellViewModel *RowItem = (UiContactProfileContactsTableCellViewModel *)[self.ViewModel.ContactsTable objectAtIndex:indexPath.row];
        
        
        UILabel *TypeLabel = (UILabel *)[cell viewWithTag:102];
        TypeLabel.text = RowItem.TypeLabelText;
        
        UILabel *PhoneLabel = (UILabel *)[cell viewWithTag:103];
        PhoneLabel.text = RowItem.PhoneLabelText;
        
        if([self.ViewModel.ContactsTable count] - 1 == indexPath.row)
        {
            UIView *SplitBorderView = (UIView *)[cell viewWithTag:105];
            [SplitBorderView setAlpha:0.0];
        }
        
        @weakify(self);
        
        if(!self.ViewModel.IsIam)
        {
            
            if(!self.ViewModel.IsDirectoryRemoteType)
            {
                UIButton *FavButton = (UIButton *)[cell viewWithTag:101];
                
                // Bindings
                RAC(FavButton, selected) = [[RACObserve(RowItem, IsFavourite) distinctUntilChanged] takeUntil:cell.rac_prepareForReuseSignal];
                
                [[[FavButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
                    
                    @strongify(self);
                    
                    [self.ViewModel SetFavourite:RowItem];
                    
                }];
                
            }
            
            UIButton *CallButton = (UIButton *)[cell viewWithTag:104];
            
            [[[CallButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
                @strongify(self);
                
                [CallButton setEnabled:NO];
                
                [CallsManager StartOutgoingCallToContact:self.ViewModel.ContactData ContactNumber:RowItem.Contact WithCallback:^(BOOL Success) {
                    [CallButton setEnabled:YES];
                }];
                
            }];
            
            [[[[[[[RACObserve(self.ViewModel, Status)
                 takeUntil:cell.rac_prepareForReuseSignal]
                 distinctUntilChanged]
                 map:^id(NSString *StatusString) {
                     return [NSString stringWithFormat:@"UiContactProfileButton%@", StatusString];
                 }]
                 delay:0.3]
                 combineLatestWith:RACObserve(self.ViewModel, IsRequest)]
                 deliverOnMainThread]
                 subscribeNext:^(RACTuple *Tuple) {
                
                     RACTupleUnpack(NSString *StatusClass, NSNumber *IsRequest) = Tuple;
                     if([IsRequest boolValue])
                         [NUIRenderer renderButtonAndSetNuiClass:CallButton withClass:@"UiContactProfileButton"];
                     else
                         [NUIRenderer renderButtonAndSetNuiClass:CallButton withClass:StatusClass];
                     
                     [CallButton setNeedsDisplay];
                 }];
            
        }
        
        return cell;
    }
    
    else if(tableView == self.AddContactsTable)
    {
        NSString *CellIdentifier = @"UiContactProfileAddContactsTableCellView";
        
        if(self.ViewModel.IsIam)
        {
            CellIdentifier = @"UiContactProfileAddContactsTableCellViewIam";
        }
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        UiContactProfileAddContactsTableCellViewModel *RowItem = (UiContactProfileAddContactsTableCellViewModel *)[self.ViewModel.AddContactsTable objectAtIndex:indexPath.row];
        
        UILabel *TypeLabel = (UILabel *)[cell viewWithTag:102];
        TypeLabel.text = RowItem.TypeLabelText;
        
        UILabel *PhoneLabel = (UILabel *)[cell viewWithTag:103];
        PhoneLabel.text = RowItem.PhoneLabelText;
        
        if([self.ViewModel.AddContactsTable count] - 1 == indexPath.row)
        {
            UIView *SplitBorderView = (UIView *)[cell viewWithTag:105];
            [SplitBorderView setAlpha:0.0];
        }
        
        if(!self.ViewModel.IsIam)
        {
            UIButton *CallButton = (UIButton *)[cell viewWithTag:104];

            @weakify(self);
            [[[CallButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
                
                @strongify(self);
                
                [CallButton setEnabled:NO];
                
                [CallsManager StartOutgoingCallToContact:self.ViewModel.ContactData ContactNumber:RowItem.Contact WithCallback:^(BOOL Success) {
                    [CallButton setEnabled:YES];
                }];
                
            }];
        }
        
        return cell;
    }
    
    else if(tableView == self.BalanceStatusTable)
    {
        NSString *CellIdentifier = @"UiContactProfileStatusCellView";
        
        if([AppManager app].UserSession.IsBalanceAvailable && indexPath.row == 0)
            CellIdentifier = @"UiContactProfileBalanceCellView";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        
        if([CellIdentifier isEqualToString: @"UiContactProfileBalanceCellView"])
        {
            
            
            UILabel *BalanceValueLabel = (UILabel *)[cell viewWithTag:102];
            
            RAC(BalanceValueLabel, text) = [[RACObserve(self.ViewModel, BalanceTextValue) takeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread];
        }
        
        
        
        return cell;
    }
    
    
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableView == self.BalanceStatusTable)
    {
        if([tableView numberOfRowsInSection:indexPath.section] > 1 && indexPath.row == 0)
        {
            [[[AppManager app] NavRouter] OpenUrlInExternalBrowser:[[AppManager app].UserSession GetBalanceInfoUrl]];
        }
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [UiContactsTabNavRouter PrepareForSegue:segue sender:sender contactModel:self.ViewModel.ContactData];
    
}

#pragma mark - Sizes adjustments

- (void) AdjustContactsTableViewHeight
{
    [self AdjustContactsTableViewHeight:NO];
}

- (void) AdjustContactsTableViewHeight:(BOOL) Animation
{
    
    float CellHeight = self.ContactsTable.rowHeight;
    
    self.ContactsTableHeightConstraint.constant = CellHeight * [self.ViewModel.ContactsTable count];
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        //[self SetViewsVisibility];
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
    }];
    
    
}

- (void) AdjustAddContactsTablePanelViewHeight
{
    [self AdjustAddContactsTablePanelViewHeight:NO];
}

- (void) AdjustAddContactsTablePanelViewHeight:(BOOL) Animation
{
    
    float CellHeight = self.AddContactsTable.rowHeight;
    
    if([self.ViewModel.AddContactsTable count] > 0)
    {
        self.AddContactsTablePanelHeightConstraint.constant = CellHeight * [self.ViewModel.AddContactsTable count] + 30;
        
        [self.AddContactsTablePanel setAlpha:1.0];
    }
    else
    {
        self.AddContactsTablePanelHeightConstraint.constant = 0;
        [self.AddContactsTablePanel setAlpha:0.0];
    }
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        //[self SetViewsVisibility];
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
    }];
    
    
}

- (void) AdjustBalanceStatusTableHeight:(BOOL) Animation
{
    
    float CellHeight = self.BalanceStatusTable.rowHeight;
    
    self.BalanceStatusTableHeightConstraint.constant = CellHeight * [self.BalanceStatusTable numberOfRowsInSection:0];
    
    self.BalanceStatusTableHeightConstraintInitial = self.BalanceStatusTableHeightConstraint.constant;
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        //[self SetViewsVisibility];
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
    }];
    
    
}

- (void)OrientationChanged:(NSNotification *)notification
{
    [self AdjustContactsTableViewHeight];
}

- (void) SetViewsVisibility
{
    if(self.ViewModel.IsLocalType || self.ViewModel.IsPhonebookType)
    {
        [self.AvatarLogoMark setAlpha:0.0];
        
        [self.CallControllsPanelView setAlpha:0.0];
        self.CallControllsPanelHeightConstraint.constant = 0;
        
        [self.StatusPanelView setAlpha:0.0];
        self.StatusPanelHeighConstraint.constant = 0;
        
        [self.ServicesButton setEnabled:NO];
        [self.ServicesButton setAlpha:0];
        
        //self.ContactsTableTopConstraint.constant = 0;
    }
    
    //Disable edit if phonebook contact
    if(self.ViewModel.IsPhonebookType || self.ViewModel.IsDirectoryRemoteType)
    {
        if(!self.ViewModel.IsInTabView)
            [self.EditButton setEnabled:NO];
        
        if(!self.ViewModel.IsIam)
            [self.EditButton setAlpha:0.0];
    }
    
    if(!self.ViewModel.IsDirectoryRemoteType || self.ViewModel.IsIam)
    {
        [self.AddContactPanel setAlpha:0.0];
        self.AddContactPanelHeightConstraint.constant = 0;
    }
    
    if(self.ViewModel.IsDirectoryRemoteType)
    {
        if([self.ViewModel.IsInvite boolValue])
        {
            [self.AddContactPanel setAlpha:0.0];
            self.AddContactPanelHeightConstraint.constant = 0;
        }
        
        [self.CallControllsPanelView setAlpha:0.0];
        self.CallControllsPanelHeightConstraint.constant = 0;
        
        [self.StatusPanelView setAlpha:0.0];
        self.StatusPanelHeighConstraint.constant = 0;
        
        //self.ContactsTableTopConstraint.constant = self.StatusPanelHeighConstraint.constant;
        
        if(self.ViewModel.IsInLocalDirectory)
        {
            [self.AddContactButton setEnabled:NO];
            [self.AddContactRequestButton setEnabled:NO];
        }
        else
        {
            [self.AddContactButton setEnabled:YES];
            [self.AddContactRequestButton setEnabled:YES];
        }
    }
    
    if(!self.ViewModel.IsIam)
    {
        [self.BalanceStatusTable setAlpha:0.0];
        self.BalanceStatusTableHeightConstraint.constant = 0;
        
        [self.MyProfileStatusPanel setAlpha:0.0];
        self.MyProfileStatusPanelHeighConstraint.constant = 0;
        
        [self.ContactsSectionHeaderPanel setAlpha:0.0];
        self.ContactsSectionHeaderPanelHeightConstraint.constant = 0;
    }
    else
    {
        [self.CallControllsPanelView setAlpha:0.0];
        self.CallControllsPanelHeightConstraint.constant = 0;
        
        [self.StatusPanelView setAlpha:0.0];
        self.StatusPanelHeighConstraint.constant = 0;
        
        [self.ProfileHeaderButton setTitle:NSLocalizedString(@"Title_MyProfile", nil) forState:UIControlStateNormal];
        
        if(!self.ViewModel.IsInTabView)
            [self.EditButton setEnabled:NO];
        
        //[self.EditButton setAlpha:0.0];
    }
    
    if(self.ViewModel.IsDirectoryLocalType && !self.ViewModel.IsIam)
    {
        if([self.ViewModel.IsRequest boolValue])
        {
            [self.CallControllsPanelView setAlpha:0.0];
            self.CallControllsPanelHeightConstraint.constant = 0;
            
            [self.StatusPanelView setAlpha:0.0];
            self.StatusPanelHeighConstraint.constant = 0;
        }
        
        else
        {
            [self.CallControllsPanelView setAlpha:1.0];
            self.CallControllsPanelHeightConstraint.constant = self.CallControllsPanelHeightConstraintInitial;
            
            [self.StatusPanelView setAlpha:1.0];
            self.StatusPanelHeighConstraint.constant = self.StatusPanelHeighConstraintInitial;
        }
    }
    
}

- (void)viewDidLayoutSubviews
{
    
    [NUIRenderer renderButton:self.AddContactButton withClass:[self.AddContactButton valueForKey:@"nuiClass"]];
    
    [NUIRenderer renderButton:self.UnblockContactButton withClass:[self.UnblockContactButton valueForKey:@"nuiClass"]];
}


- (void) CompleteSaveActionWithSuccess:(BOOL) Success
{
    
    if(Success)
    {
        if(self.CallbackOnBackAction)
        {
            self.CallbackOnBackAction();
        }
        else
        {
            [UiContactsTabNavRouter CloseProfileViewWhenSaveAction];
        }
        
    }
    else
    {
        [self.AddContactButton setEnabled:YES];
        
        UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleAlert];
        
        Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotSaved", nil);
        
        UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                         }];
        
        [Alert addAction:OkAction];
        
        [self presentViewController:Alert animated:YES completion:nil];
    }
    
}

- (void) SetRequestInputPanelVisibility: (BOOL) IsVsible withAnimation: (BOOL) Animation
{
    
    if (IsVsible) {
        self.RequestInputPanelHeightConstraint.constant = self.RequestInputHeighConstraintInitial;
        [self.RequestInputPanel setAlpha:1];
        
        [self.AddContactRequestButton setEnabled:NO];
        [self.AddContactButton setEnabled:NO];
        [self.AddContactAndChatButton setEnabled:YES];
        
        [self.AddContactRequestButton setAlpha:0.0];
        [self.AddContactButton setAlpha:0.0];
        [self.AddContactAndChatButton setAlpha:1.0];
        
        [self.RequestInputTextView becomeFirstResponder];
        [self.ScrollView setContentOffset:self.RequestInputTextView.frame.origin animated:YES];
    }
    else
    {
        self.RequestInputPanelHeightConstraint.constant = 0;
        [self.RequestInputPanel setAlpha:0];
        
        
        [self.AddContactRequestButton setEnabled:YES];
        [self.AddContactButton setEnabled:YES];
        [self.AddContactAndChatButton setEnabled:NO];
        
        [self.AddContactRequestButton setAlpha:1.0];
        [self.AddContactButton setAlpha:1.0];
        [self.AddContactAndChatButton setAlpha:0.0];
    }
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.RequestInputTextView setNeedsDisplay];
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        [self SetViewsVisibility];
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
    }];
}

- (void) SetApplyRequestContactAndInvitePanelsVisibility: (BOOL) IsVsible withAnimation: (BOOL) Animation
{
    
    if (IsVsible) {
        
        self.InviteNotifyPanelHeightConstraint.constant = self.InviteNotifyPanelHeightConstraintInitial;
        self.ApplyContactRequestPanelHeightConstraint.constant = self.ApplyContactRequestPanelHeightConstraintInitial;
        
        [self.InviteNotifyPanel setAlpha:1];
        [self.ApplyContactRequestPanel setAlpha:1];
    }
    else
    {
        self.InviteNotifyPanelHeightConstraint.constant = 0;
        self.ApplyContactRequestPanelHeightConstraint.constant = 0;
        
        [self.InviteNotifyPanel setAlpha:0];
        [self.ApplyContactRequestPanel setAlpha:0];
    }
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        [self SetViewsVisibility];
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
    }];
}

- (void) SetBlockedContactPanelsVisibility: (BOOL) IsVsible withAnimation: (BOOL) Animation
{
    
    if (IsVsible) {
        
        self.BlockedContactPanelHeightConstraint.constant = self.BlockedContactPanelHeightConstraintInitial;
        
    }
    else
    {
        self.BlockedContactPanelHeightConstraint.constant = 0;
        
    }
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        [self SetViewsVisibility];
        
        
        if (IsVsible) {
            
            [self.BlockedContactPanel setAlpha:1];
        }
        else
        {
            
            [self.BlockedContactPanel setAlpha:0];
        }
        
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
        
        
    }];
}

- (void) SetRequestSendedPanelVisibility: (BOOL) IsVsible withAnimation: (BOOL) Animation
{
    
    if (IsVsible) {
        
        self.RequestSendedPanelHeightConstraint.constant = self.RequestSendedPanelHeightConstraintInitial;
        
    }
    else
    {
        self.RequestSendedPanelHeightConstraint.constant = 0;
        
    }
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        [self SetViewsVisibility];
        
        if (IsVsible) {
            
            [self.RequestSendedPanel setAlpha:1];
        }
        else
        {
            
            [self.RequestSendedPanel setAlpha:0];
        }
        
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
        
        
    }];
}

#pragma mark UIText delegates

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
    self._CurrentResponder = textView;
    
}

- (BOOL)textViewShouldReturn:(UITextField *)textField
{
    [self ResignOnTap:nil];
    
    return NO;
}

- (void)ResignOnTap:(id)iSender {
    [self._CurrentResponder resignFirstResponder];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if(touch.view != self._CurrentResponder && touch.view.superview != self._CurrentResponder)
        [self ResignOnTap:nil];
    
    
    
    return NO;
}

- (void) ShowLogoutAlert
{
    
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"Question_DoYouWantToLogout", nil)
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* LogoutAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Logout", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [self.ViewModel Logout];
                                                             
                                                             
                                                         }];
    
    [alert addAction:LogoutAction];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             
                                                         }];
    
    [alert addAction:cancelAction];
    
    
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = self.view;
    popPresenter.sourceRect = self.view.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}
@end
