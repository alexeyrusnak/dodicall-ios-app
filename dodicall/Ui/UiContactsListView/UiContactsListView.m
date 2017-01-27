//
//  UiContactsListView.m
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

#import "UiContactsListView.h"
#import "UiContactProfileView.h"
#import "UiContactProfileEditView.h"

#import "UiAlertControllerView.h"

#import "UiContactsTabNavRouter.h"

#import "UiLogger.h"

#import <NUI/NUIRenderer.h>

#import "UiNavRouter.h"

#import "UiChatsTabNavRouter.h"

#import "UiCallsNavRouter.h"

#import "CallsManager.h"

#import "ContactsManager.h"

@interface UiContactsListView ()

@property (nonatomic, assign) id _CurrentResponder;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;

@end

@implementation UiContactsListView
{
    BOOL _IsAllBinded;
    NSTimer *SearchDelayer;
}

@synthesize List, SearchBar, ParentView;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        
        self.ViewModel =  [[UiContactsListModel alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self BindAll];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify(self);
    
    [[[[self.ViewModel.DataReloadedSignal filter:^BOOL(NSNumber *Value) {
        return [Value boolValue];
    }] throttle:0.3 afterAllowing:1 withStrike:1] deliverOnMainThread] subscribeNext:^(NSNumber *Value) {
        
        @strongify(self);
        
        if(self.ViewModel.DataUpdateStages && [self.ViewModel.DataUpdateStages count] > 0)
        {
            if([self.ViewModel.DataUpdateStages count] > 1)
            {
                [self.ViewModel.DataUpdateStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.DataUpdateStages.count-1)];
            }
            
            NSDictionary *DataStage = [self.ViewModel.DataUpdateStages lastObject];
            
            self.ViewModel.ThreadSafeSections = [[DataStage objectForKey:@"Sections"] copy];
            
            self.ViewModel.ThreadSafeSectionsKeys = [[DataStage objectForKey:@"SectionsKeys"] copy];
            
        }
        
        [self.List reloadData];
        
    }];
    
    [[RACObserve(self.ViewModel, Mode) deliverOnMainThread] subscribeNext:^(UiContactsListMode Mode) {
        
        if([Mode isEqualToString:UiContactsListModeMultySelectable] || [Mode isEqualToString:UiContactsListModeMultySelectableForChat] || [Mode isEqualToString:UiContactsListModeCallTransfer])
        {
            @strongify(self);
            self.AddContactButton.hidden = YES;
            self.AddContactButton.alpha = 0.0;
        }
    }];
    
    _IsAllBinded = TRUE;
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UiContactsListRowItemModel *RowItem;
    
    if ([self.ViewModel.ThreadSafeSectionsKeys count] > 0 &&  [self.ViewModel.ThreadSafeSections count] > 0)
    {
        NSIndexPath *IndexPath = [self.List indexPathForSelectedRow];
        id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:IndexPath.section];
        NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
        
        RowItem = (UiContactsListRowItemModel *)[Rows objectAtIndex:IndexPath.row];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsListView: User did select row at index path %li %li", (long)IndexPath.section, (long)IndexPath.row]];
    }
    
    if(self.ViewModel.TempContactData == nil)
        self.ViewModel.TempContactData = RowItem ? RowItem.ContactData : nil;
    
    
    [UiContactsTabNavRouter PrepareForSegue:segue sender:sender contactModel:self.ViewModel.TempContactData];
    
    self.ViewModel.TempContactData = nil;
    
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return [self.ViewModel.ThreadSafeSectionsKeys count];
    
}

- (NSInteger)NumberOfRowsInSection:(UITableView *)tableView InSection:(NSInteger)section {
    
    id Key = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:section];
    
    NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:Key];
    
    return [Rows count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self NumberOfRowsInSection:tableView InSection:section];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:indexPath.section];
    NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
    UiContactsListRowItemModel *RowItem = (UiContactsListRowItemModel *)[Rows objectAtIndex:indexPath.row];
    
    NSString *CellIdentifier = @"UiContactsListCellView";
    
    if([RowItem.Filter isEqualToString:UiContactsFilterPhoneBook])
        CellIdentifier = @"UiContactsListPhonebookCellView";
    
    if([RowItem.Filter isEqualToString:UiContactsFilterLocal])
        CellIdentifier = @"UiContactsListLocalCellView";
    
    if([CellIdentifier isEqualToString: @"UiContactsListCellView"] && RowItem.IsRequest)
        CellIdentifier = [CellIdentifier stringByAppendingString:@"NotAccepted"];
    
    if(RowItem.IsBlocked)
        CellIdentifier = [CellIdentifier stringByAppendingString:@"Blocked"];
    
    if([self.ViewModel.Mode isEqualToString:UiContactsListModeMultySelectable] || [self.ViewModel.Mode isEqualToString:UiContactsListModeMultySelectableForChat])
        CellIdentifier = @"UiContactsListCellViewSelectable";
    
    
    UiContactsListRowItemView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    UILabel *TitleLabel = (UILabel *)[cell viewWithTag:101];
    TitleLabel.text = RowItem.Title;
    
    @weakify(RowItem);
    @weakify(cell);
    
    if([CellIdentifier isEqualToString: @"UiContactsListPhonebookCellView"] || [CellIdentifier isEqualToString: @"UiContactsListPhonebookCellViewBlocked"]) {
        
        UIButton *AddContactButton = (UIButton *)[cell viewWithTag:102];
        [AddContactButton setEnabled:YES];
        @weakify(self);
        
        [[[AddContactButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
            @strongify(self);
            @strongify(cell);
            @strongify(RowItem);
            [self AddContactAction:AddContactButton :RowItem :cell];
        }];
        
        UIButton *CallPstnButton = (UIButton *)[cell viewWithTag:103];
        
        [[[CallPstnButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
            @strongify(RowItem);
            [CallPstnButton setEnabled:NO];
            [CallsManager StartOutgoingCallToContact:RowItem.ContactData WithCallback:^(BOOL Success) {
                [CallPstnButton setEnabled:YES];
            }];
        }];
        
        if([self.ViewModel.Mode isEqualToString:UiContactsListModeCallTransfer])
        {
            [AddContactButton setEnabled:NO];
            [AddContactButton setAlpha:0];
            
            [CallPstnButton setEnabled:NO];
            [CallPstnButton setAlpha:0];
        }
    }
    
    if([CellIdentifier isEqualToString: @"UiContactsListLocalCellView"] || [CellIdentifier isEqualToString: @"UiContactsListLocalCellViewBlocked"])
    {
        // Bindings
        
        UIButton *CallPstnButton = (UIButton *)[cell viewWithTag:102];
        
        [[[CallPstnButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
            @strongify(RowItem);
            [CallPstnButton setEnabled:NO];
            [CallsManager StartOutgoingCallToContact:RowItem.ContactData WithCallback:^(BOOL Success) {
                [CallPstnButton setEnabled:YES];
            }];
            
        }];
        
        if([self.ViewModel.Mode isEqualToString:UiContactsListModeCallTransfer])
        {
            [CallPstnButton setEnabled:NO];
            [CallPstnButton setAlpha:0];
        }
    }
    
    if([CellIdentifier isEqualToString: @"UiContactsListCellView"] ||
       [CellIdentifier isEqualToString: @"UiContactsListCellViewBlocked"] ||
       [CellIdentifier isEqualToString: @"UiContactsListCellViewNotAccepted"] ||
       [CellIdentifier isEqualToString: @"UiContactsListCellViewNotAcceptedBlocked"] ||
       [CellIdentifier isEqualToString: @"UiContactsListCellViewSelectable"])
    {
        UILabel *DescrLabel = (UILabel *)[cell viewWithTag:102];

        
        [[[[RACObserve(RowItem, Description) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSString *StatusString) {
            
            [DescrLabel setText:StatusString];
        }];
        
        UIButton *CallButton;
        
        if(![CellIdentifier isEqualToString: @"UiContactsListCellViewSelectable"])
        {
            CallButton = (UIButton *)[cell viewWithTag:104];
        
            [[[CallButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
                @strongify(RowItem);
                [CallButton setEnabled:NO];
                [CallsManager StartOutgoingCallToContact:RowItem.ContactData WithCallback:^(BOOL Success) {
                    [CallButton setEnabled:YES];
                }];
                
            }];
        }
        
        UIButton *ChatButton;
        
        if([CellIdentifier isEqualToString: @"UiContactsListCellView"] || [CellIdentifier isEqualToString: @"UiContactsListCellViewBlocked"] )
        {
            ChatButton = (UIButton *)[cell viewWithTag:105];
            
            [[[ChatButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
                
                @strongify(RowItem);
                
                [UiChatsTabNavRouter CreateAndShowChatViewWithContact:RowItem.ContactData];
                
            }];
        }
        
        if([self.ViewModel.Mode isEqualToString:UiContactsListModeCallTransfer])
        {
            [ChatButton setEnabled:NO];
            [ChatButton setAlpha:0];
            
            [CallButton setEnabled:NO];
            [CallButton setAlpha:0];
        }
        
        
        if([CellIdentifier isEqualToString: @"UiContactsListCellView"] ||
           [CellIdentifier isEqualToString: @"UiContactsListCellViewBlocked"] ||
           [CellIdentifier isEqualToString: @"UiContactsListCellViewSelectable"] )
        {
            UIView *Status = (UIView *)[cell viewWithTag:103];
            
            [[[[RACObserve(RowItem, Status) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSString *StatusString) {
                    
                [NUIRenderer renderView:Status withClass:[NSString stringWithFormat:@"UiContactsListCellViewStatusIndicator%@", StatusString]];
                
                [NUIRenderer renderButton:CallButton withClass:[NSString stringWithFormat:@"UiContactsListCellButton%@", StatusString]];
                
                [NUIRenderer renderButton:ChatButton withClass:[NSString stringWithFormat:@"UiContactsListCellButton%@", StatusString]];
                
                [Status setNeedsDisplay];
                
                [CallButton setNeedsDisplay];
                
                [ChatButton setNeedsDisplay];
                
            }];
        }
        
        if([CellIdentifier isEqualToString: @"UiContactsListCellViewSelectable"] )
        {
            UIImageView *CheckIcon = (UIImageView *)[cell viewWithTag:110];
            
            [[[[RACObserve(RowItem, IsSelected) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *Selected) {
                
                if([Selected boolValue])
                    [CheckIcon setAlpha:1.0];
                else
                    [CheckIcon setAlpha:0.0];
            }];
            
            [[[[RACObserve(RowItem, IsDisabled) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *Disabled) {
                @strongify(cell);

                if([Disabled boolValue])
                {
                    [cell setUserInteractionEnabled:NO];
                    [cell.contentView setAlpha:0.5];
                }
                else
                {
                    [cell setUserInteractionEnabled:YES];
                    [cell.contentView setAlpha:1.0];
                }
            }];
        }
        
        
        if([self.ViewModel.Mode isEqualToString:UiContactsListModeCallTransfer])
        {
            NSLayoutConstraint *HeaderTableTrailingToBtn;
            NSLayoutConstraint *DescrTableTrailingToBtn;
            
            NSLayoutConstraint *HeaderTableTrailingToSuperView;
            NSLayoutConstraint *DescrTableTrailingToSuperView;
            
            for(NSLayoutConstraint *constraint in cell.contentView.constraints) {
                if([constraint.identifier isEqualToString:@"HeaderTableTrailingToBtn"])
                    HeaderTableTrailingToBtn = constraint;
                if([constraint.identifier isEqualToString:@"DescrTableTrailingToBtn"])
                    DescrTableTrailingToBtn = constraint;
                if([constraint.identifier isEqualToString:@"HeaderTableTrailingToSuperView"])
                    HeaderTableTrailingToSuperView = constraint;
                if([constraint.identifier isEqualToString:@"DescrTableTrailingToSuperView"])
                    DescrTableTrailingToSuperView = constraint;
            }
            
            if(HeaderTableTrailingToBtn)
                [HeaderTableTrailingToBtn setPriority:100];
            
            if(DescrTableTrailingToBtn)
                [DescrTableTrailingToBtn setPriority:100];
            
            [cell.contentView setNeedsUpdateConstraints];
            [cell.contentView layoutIfNeeded];
            
            
            [[[RACObserve(RowItem, IsDisabled) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSNumber *Disabled) {
                @strongify(cell);

                dispatch_async(dispatch_get_main_queue(), ^{
                    if([Disabled boolValue])
                    {
                        [cell setUserInteractionEnabled:NO];
                        [cell.contentView setAlpha:0.5];
                    }
                    else
                    {
                        [cell setUserInteractionEnabled:YES];
                        [cell.contentView setAlpha:1.0];
                    }
                });
                
            }];

        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(![[cell viewWithTag:100] isKindOfClass:[UIImageView class]])
        return;
    
    id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:indexPath.section];
    NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
    UiContactsListRowItemModel *RowItem = (UiContactsListRowItemModel *)[Rows objectAtIndex:indexPath.row];
    
    UIImageView *AvatarView = [cell viewWithTag:100];
    
    @weakify(AvatarView);
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(RowItem, AvatarPath) WithTakeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(AvatarView);
        AvatarView.image = Image;
    }];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.ViewModel.ThreadSafeSectionsKeys;
}

/*
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.ViewModel FindNearestNotEmptySectionIndex:index];
}
 */

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    /*
    if([self NumberOfRowsInSection:tableView InSection:section] == 0)
        return nil;
     */
    
    static NSString *CellIdentifier = @"UiContactsListSectionHeaderView";
    
    UITableViewCell *HeaderView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *HeaderViewTitle = (UILabel *)[HeaderView viewWithTag:100];
    
    HeaderViewTitle.text = (NSString *)[self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:section];
    
    return HeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if([self NumberOfRowsInSection:tableView InSection:section] == 0)
        return 0;
    
    else
        return 28/*tableView.sectionHeaderHeight*/;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if([self.ViewModel.Mode isEqualToString:UiContactsListModeMultySelectable] || ([self.ViewModel.Mode isEqualToString:UiContactsListModeMultySelectableForChat] && ![self.ViewModel.SelectionBlocked boolValue]))
    {
        id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:indexPath.section];
        NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
        UiContactsListRowItemModel *RowItem = (UiContactsListRowItemModel *)[Rows objectAtIndex:indexPath.row];
        
        [self.ViewModel RevertSelected:RowItem];
    }
    
    if([self.ViewModel.Mode isEqualToString:UiContactsListModeCallTransfer])
    {
        id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:indexPath.section];
        NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
        UiContactsListRowItemModel *RowItem = (UiContactsListRowItemModel *)[Rows objectAtIndex:indexPath.row];
        
        UiContactsListRowItemView *Cell = [tableView cellForRowAtIndexPath:indexPath];
        
        [self CallTransferAction:RowItem :Cell];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [theSearchBar resignFirstResponder];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if([self.ViewModel.Mode isEqualToString:UiContactsListModeCallTransfer])
    {
        return NO;
    }
    
    return YES;
}

#pragma mark UISearchBar delegates

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self._CurrentResponder = searchBar;
    
    [self HideAddContactButton];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [SearchDelayer invalidate], SearchDelayer = nil;
    
    SearchDelayer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                     target:self
                                                   selector:@selector(SearchBarTextDidChangeDelayed:)
                                                   userInfo:searchText
                                                    repeats:NO];
    
    
}

- (void) SearchBarTextDidChangeDelayed:(NSTimer *)Timer
{
    [self.ViewModel SetSearchTextFilter:SearchBar.text];
}

- (void)ResignOnTap:(id)iSender {
    [self._CurrentResponder resignFirstResponder];
    [self ShowAddContactButton];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    [self ResignOnTap:nil];
    
    return NO;
}

#pragma mark Add contact button
- (void) ShowAddContactButton
{
    
    
    if(![self.ViewModel.Mode isEqualToString:UiContactsListModeMultySelectable] && ![self.ViewModel.Mode isEqualToString:UiContactsListModeMultySelectableForChat] && ![self.ViewModel.Mode isEqualToString:UiContactsListModeCallTransfer])
    {
        self.AddContactButton.hidden = NO;
        [UIView animateWithDuration:0.3
                     animations:^{
                         self.AddContactButton.alpha = 1.0;
                     }];
    }
    
    
}

- (void) HideAddContactButton
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.AddContactButton.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         self.AddContactButton.hidden = YES;
                     }];
}

-(void) AddContactAction:(UIButton *) AddContactButton : (UiContactsListRowItemModel *) RowItem : (UiContactsListRowItemView *) cell
{
    [UiLogger WriteLogInfo:@"UiContactsListView: Add contact list button taped"];
    
    [AddContactButton setEnabled:NO];
    
    
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"Title_ContactWillBeCopiedAndSaved", nil)
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* AddAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_AddContact", nil) style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [UiLogger WriteLogInfo:@"UiContactsListView: Add action selected"];
                                                          
                                                          void (^Callback)(BOOL) = ^(BOOL Success){
                                                              
                                                              if(Success)
                                                              {
                                                                  [self performSegueWithIdentifier:UiContactsTabNavRouterSegueShowContactProfile sender:self];
                                                                  
                                                              }
                                                              else
                                                              {
                                                                  [AddContactButton setEnabled:YES];
                                                                  
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
                                                          
                                                          [self.ViewModel ExecuteSaveAction: RowItem.ContactData withCallback:Callback];
                                                          
                                                          
                                                      }];
    
    [alert addAction:AddAction];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [AddContactButton setEnabled:YES];
                                                             
                                                         }];
    
    [alert addAction:cancelAction];
    
    
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = cell.contentView;
    popPresenter.sourceRect = cell.contentView.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
}


-(void) CallTransferAction:(UiContactsListRowItemModel *) RowItem : (UiContactsListRowItemView *) cell
{
    [UiLogger WriteLogInfo:@"UiContactsListView: CallTransferAction menu"];
    
    
    UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:[NSString stringWithFormat:NSLocalizedString(@"Title_CallTransferToUser%@ToNumber", nil),RowItem.Title]
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSMutableArray <ObjC_ContactsContactModel *> *ContactContacts = [RowItem.ContactData.Contacts mutableCopy];
    
    NSSortDescriptor *SortDescriptorType = [[NSSortDescriptor alloc] initWithKey:@"Type" ascending:YES];
    NSSortDescriptor *SortDescriptorIdentity = [[NSSortDescriptor alloc] initWithKey:@"Identity" ascending:YES];
    
    NSArray *SortDescriptors = [NSArray arrayWithObjects:SortDescriptorType, SortDescriptorIdentity, nil];
    
    [ContactContacts sortUsingDescriptors:SortDescriptors];
    
    
    for (ObjC_ContactsContactModel *Number in ContactContacts)
    {
        
        if((Number.Type == ContactsContactSip || Number.Type == ContactsContactPhone) && Number.Identity && Number.Identity.length > 0)
        {
            
            NSString *Identity = [[Number.Identity componentsSeparatedByString:@"@"][0] stringByAppendingString:[NSString stringWithFormat:@" (%@)", Number.Type == ContactsContactSip ? NSLocalizedString(@"Title_CallTransferDSip", nil) : NSLocalizedString(@"Title_CallTransferAddNumber", nil)]];
            
            UIAlertAction* TransferToNumberAction =
            
            [UIAlertAction actionWithTitle:Identity
                                     style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
            {
                [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsListView: Transfer ToNumberAction selected: %@", Identity]];
                                                                               
                void (^Callback)(BOOL) = ^(BOOL Success){
                    
                    if(Success)
                    {
                        [UiCallsNavRouter CloseCallTransferTabPageView];
                        
                    }
                    else
                    {
                        UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                               message:nil
                                                                                        preferredStyle:UIAlertControllerStyleAlert];
                        
                        Alert.title = NSLocalizedString(@"Title_CallTransferError", nil);
                        
                        UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action) {}];
                        
                        [Alert addAction:OkAction];
                        
                        [self presentViewController:Alert animated:YES completion:nil];
                    }
                    
                };
                
                [self.ViewModel ExecuteTransferCallAction:Number.Identity withCallback:Callback];
                
                
            }];
            
            
            [Alert addAction:TransferToNumberAction];
        }
    }
    
    
    
    
    
    UIAlertAction* CancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [Alert addAction:CancelAction];
    
    
    UIPopoverPresentationController *popPresenter = [Alert popoverPresentationController];
    popPresenter.sourceView = cell.contentView;
    popPresenter.sourceRect = cell.contentView.bounds;
    
    [self presentViewController:Alert animated:YES completion:nil];
}



@end
