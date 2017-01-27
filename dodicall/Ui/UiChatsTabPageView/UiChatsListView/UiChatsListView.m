//
//  UiChatsListView.m
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

#import "UiChatsListView.h"

#import "UiChatsTabNavRouter.h"

#import "UiLogger.h"

#import "UiNavRouter.h"

#import "NUIRenderer.h"

#import "UiAlertControllerView.h"

#import "AppManager.h"
#import "ContactsManager.h"

@interface UiChatsListView ()

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;

@property (weak, nonatomic) IBOutlet UITableView *List;

@property (weak, nonatomic) IBOutlet UISearchBar *SearchBar;

@property (nonatomic, assign) id _CurrentResponder;

// Top tool bar

@property (weak, nonatomic) IBOutlet UIButton *TopToolAddButton;

@property (weak, nonatomic) IBOutlet UIButton *TopToolEditButton;



// Bottom tool bar

@property (weak, nonatomic) IBOutlet UIView *BottomToolBar;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *BottomToolBarHeightConstraint;

@property CGFloat BottomToolBarHeightConstraintInitial;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *BottomToolBarBottomMarginConstraint;

@property CGFloat BottomToolBarBottomMarginConstraintInitial;

@property (weak, nonatomic) IBOutlet UIButton *BottomToolButtonSelectAll;

@property (weak, nonatomic) IBOutlet UIButton *BottomToolButtonDelete;

//Reload
@property (strong, nonatomic) NSNumber *DataReloaded;

@end

@implementation UiChatsListView
{
    BOOL _IsAllBinded;
    NSTimer *_SearchDelayer;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiChatsListViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self BindAll];
}

- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    [[[AppManager app] NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    self.BottomToolBarHeightConstraintInitial = self.BottomToolBarHeightConstraint.constant;
    
    self.BottomToolBarBottomMarginConstraintInitial = self.BottomToolBarBottomMarginConstraint.constant;
    
    [self EnableEditMode:NO withAnimation:NO];
    
    @weakify(self);
    
    [[RACObserve(self.ViewModel, EditModeEnabled) deliverOnMainThread] subscribeNext:^(NSNumber *Enabled) {
        
        @strongify(self);
        
        [self EnableEditMode:[Enabled boolValue] withAnimation:YES];
        
    }];
    
    [[RACObserve(self.ViewModel, SelectedCellsNumber) deliverOnMainThread] subscribeNext:^(NSNumber *Number) {
        
        @strongify(self);
        
        NSString *Title = [NSString stringWithFormat:@"%@ (%@)",NSLocalizedString(@"Title_Delete", nil), Number];
        
        [self.BottomToolButtonDelete setTitle:Title forState:UIControlStateNormal];
        
        [self.BottomToolButtonDelete setTitle:Title forState:UIControlStateHighlighted];
        
        if (!Number || [Number intValue] == 0) {
            [self.BottomToolButtonDelete setEnabled:NO];
        }
        else
        {
            [self.BottomToolButtonDelete setEnabled:YES];
        }
        
    }];
    
    [[[[self.ViewModel.DataReloadedSignal filter:^BOOL(NSNumber *Value) {
        return [Value boolValue];
    }] throttle:0.3 afterAllowing:1 withStrike:1] deliverOnMainThread] subscribeNext:^(NSNumber *Value) {
        
        @strongify(self);
        
        if(self.ViewModel.RowsUpdateStages && [self.ViewModel.RowsUpdateStages count] > 0)
        {
            if([self.ViewModel.RowsUpdateStages count] > 1)
            {
                [self.ViewModel.RowsUpdateStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.RowsUpdateStages.count - 1)];
            }
            
            self.DataReloaded = @1;
            self.ViewModel.ThreadSafeRows = [self.ViewModel.RowsUpdateStages lastObject];
            
        }
        
        [self.List reloadData];
        
    }];
    
    
    _IsAllBinded = TRUE;
}

#pragma mark UISearchBar delegates

- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [theSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self._CurrentResponder = searchBar;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [_SearchDelayer invalidate], _SearchDelayer = nil;
    
    _SearchDelayer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                     target:self
                                                   selector:@selector(SearchBarTextDidChangeDelayed:)
                                                   userInfo:searchText
                                                    repeats:NO];
    
    
}

- (void) SearchBarTextDidChangeDelayed:(NSTimer *)Timer
{
    
    [self.ViewModel SetSearchTextFilter:self.SearchBar.text];
    
}

- (void)ResignOnTap:(id)iSender {
    
    [self._CurrentResponder resignFirstResponder];
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    [self ResignOnTap:nil];
    
    return NO;
}


#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.ViewModel.ThreadSafeRows count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UiChatsListRowItemViewModel *RowItem = (UiChatsListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:indexPath.row];
    
    NSString *CellIdentifier = @"UiChatsListCellViewP2P";
    
    if(RowItem.IsMultyUserChat || RowItem.IsEmptyChat)
        CellIdentifier = @"UiChatsListCellViewMulty";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *TitleLabel = (UILabel *)[cell viewWithTag:102];
    TitleLabel.text = RowItem.Title;
    
    UILabel *DateTimeLabel = (UILabel *)[cell viewWithTag:103];
    DateTimeLabel.text = RowItem.DateTime;
    //[DateTimeLabel sizeToFit];
    
    UILabel *AddInfoLabel = (UILabel *)[cell viewWithTag:104];
    AddInfoLabel.text = RowItem.AddInfo;
    
    UIView *CountLabelBg = (UIView *)[cell viewWithTag:105];
    
    UILabel *CountLabel = (UILabel *)[cell viewWithTag:106];
    CountLabel.text = RowItem.Count;
    if(CountLabel.text && CountLabel.text > 0)
    {
        [CountLabelBg setAlpha:1];
        [CountLabel setAlpha:1];
    }
    else
    {
        [CountLabel setAlpha:0];
        [CountLabelBg setAlpha:0];
    }
    
    UILabel *DescrLabel = (UILabel *)[cell viewWithTag:107];
    if(RowItem.AttributedDescription && RowItem.AttributedDescription.length > 0)
    {
        DescrLabel.attributedText = RowItem.AttributedDescription;
    }
    else
    {
        DescrLabel.text = RowItem.Description;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UiChatsListRowItemViewModel *RowItem = (UiChatsListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:indexPath.row];
    
    UIView *Status = (UIView *)[cell viewWithTag:101];
    
    @weakify(Status);
    
    RACSignal *TakeUntilSignal = [cell.rac_prepareForReuseSignal merge:[RACObserve(self, DataReloaded) skip:1]];
    
    [[[[RACObserve(RowItem, Status) takeUntil:TakeUntilSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSString *StatusString) {
        
        //dispatch_async(dispatch_get_main_queue(), ^{
        
            @strongify(Status);
        
            Status.nuiClass = [NSString stringWithFormat:@"UiChatsListCellViewStatusIndicator%@", StatusString];
            
            [NUIRenderer renderView:Status withClass:Status.nuiClass];
            
            [Status setNeedsDisplay];
        //});
        
        
    }];
    
    if([RowItem.IsSelected boolValue])
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UIImageView *AvatarView = (UIImageView *)[cell viewWithTag:100];
    
    if(RowItem.IsMultyUserChat)
    {
        [AvatarView setImage:[UIImage imageNamed:@"no_photo_multy"]];
    }
    else
    {
        UIImageView *AvatarView = [cell viewWithTag:100];
        @weakify(AvatarView);
        [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(RowItem, AvatarPath) WithTakeUntil:TakeUntilSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
            @strongify(AvatarView);
            AvatarView.image = Image;
        }];

    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if(![self.ViewModel.EditModeEnabled boolValue])
    {
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            [self performSegueWithIdentifier:UiChatsTabNavRouterSegueShowChat sender:self];
        }
        else
        {
            
            UiChatsListRowItemViewModel *RowItem;
            
            if ([self.ViewModel.ThreadSafeRows count] > 0)
            {
                NSIndexPath *IndexPath = [self.List indexPathForSelectedRow];
                
                RowItem = (UiChatsListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:IndexPath.row];
                
                [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatsListView: User did select row at index path %li %li", (long)IndexPath.section, (long)IndexPath.row]];
            }
            
            [UiChatsTabNavRouter ShowChatView:RowItem.Chat];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    }
    else
    {
        [self.ViewModel SelectCell:YES withIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.ViewModel SelectCell:NO withIndexPath:indexPath];
    
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    ObjC_ChatModel *Chat;
    
    if([segue.identifier isEqualToString:UiChatsTabNavRouterSegueShowChatUsers])
    {
        Chat = [self.ViewModel CreateFakeNewChatModel];
    }
    
    else
    {
        UiChatsListRowItemViewModel *RowItem;
    
        if ([self.ViewModel.ThreadSafeRows count] > 0)
        {
            NSIndexPath *IndexPath = [self.List indexPathForSelectedRow];
            
            RowItem = (UiChatsListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:IndexPath.row];
            
            Chat = RowItem.Chat;
            
            [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiChatsListView: User did select row at index path %li %li", (long)IndexPath.section, (long)IndexPath.row]];
        }
    }
    
    [UiChatsTabNavRouter PrepareForSegue:segue sender:sender chatModel:Chat];
    
}

#pragma mark - Edit mode

- (void) EnableEditMode: (BOOL) Enabled withAnimation: (BOOL) Animation
{
    
    CGRect TabBarFrame = self.tabBarController.tabBar.frame;
    CGFloat TabBarHeight = TabBarFrame.size.height;
    CGFloat TabBarOffsetY = (Enabled)? TabBarHeight : -TabBarHeight;
    
    if(Enabled)
    {
        //self.BottomToolBarHeightConstraint.constant = self.BottomToolBarHeightConstraintInitial;
        
        //self.BottomToolBarBottomMarginConstraint.constant = self.BottomToolBarBottomMarginConstraintInitial + self.tabBarController.tabBar.frame.size.height;
        
        [self.List setEditing:YES animated:YES];
        
        //[self.tabBarController.tabBar setHidden:YES];
        
        [self.TopToolEditButton setTitle:NSLocalizedString(@"Title_Cancel", nil) forState:UIControlStateNormal];
        
        [self.TopToolEditButton setTitle:NSLocalizedString(@"Title_Cancel", nil) forState:UIControlStateHighlighted];
        
        [self.TopToolAddButton setAlpha:0.0];
        [self.TopToolAddButton setEnabled:NO];
        
    }
    else
    {
        //self.BottomToolBarHeightConstraint.constant = 0;
        
        //self.BottomToolBarBottomMarginConstraint.constant = self.BottomToolBarBottomMarginConstraintInitial;
        
        [self.List setEditing:NO animated:YES];
        
        [self.tabBarController.tabBar setHidden:NO];
        
        [self.TopToolEditButton setTitle:NSLocalizedString(@"Title_Edit", nil) forState:UIControlStateNormal];
        
        [self.TopToolEditButton setTitle:NSLocalizedString(@"Title_Edit", nil) forState:UIControlStateHighlighted];
        
        [self.TopToolAddButton setAlpha:1];
        [self.TopToolAddButton setEnabled:YES];
    }
    
    
    
    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        self.tabBarController.tabBar.frame = CGRectOffset(TabBarFrame, 0, TabBarOffsetY);
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished)
    {
        
        if(Enabled)
        {
            [self.BottomToolBar setHidden:NO];
        }
        else
        {
            [self.BottomToolBar setHidden:YES];
        }
        
    }];
    
}

- (IBAction)SelectAllAction:(id)sender
{
    
    for (int row = 0; row < [self.List numberOfRowsInSection:0]; row ++)
    {
        NSIndexPath *IndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        
        [self SelectCell:YES withIndexPath:IndexPath];
    }
    
}

- (void) SelectCell:(BOOL) Selected withIndexPath:(NSIndexPath *) IndexPath
{
    if(Selected)
    {
        [self tableView:self.List didSelectRowAtIndexPath:IndexPath];
        
        [self.List selectRowAtIndexPath:IndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [self.ViewModel SelectCell:Selected withIndexPath:IndexPath];
    }
    else
    {
        [self.List deselectRowAtIndexPath:IndexPath animated:NO];
        
        //UiChatsListRowItemViewModel *RowItem = (UiChatsListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:IndexPath.row];
        
        //[RowItem setIsSelected:NO];
        
        [self.ViewModel SelectCell:Selected withIndexPath:IndexPath];
    }
    
}

- (IBAction)DeleteSelectedAction:(id)sender
{
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"Question_AreYouShureYouWantToLocalDeleteChats", nil)
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    
    
    UIAlertAction* DeleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Delete", nil) style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [self.ViewModel ClearSelectedChats];
                                                          
                                                          [self.ViewModel EnableEditMode:NO];

                                                          
                                                          //[UiNavRouter ShowComingSoon];
                                                          
                                                          
                                                      }];
    
    [alert addAction:DeleteAction];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             //[UiNavRouter ShowComingSoon];
                                                             
                                                         }];
    
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction)EditAction:(id)sender
{
    [self.ViewModel SwitchEditMode];
}

#pragma mark - New chat

- (IBAction)NewChatAction:(id)sender
{
    //[UiNavRouter ShowComingSoon];
}




@end
