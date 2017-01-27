//
//  UiContactsDirectorySearchView.m
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

#import "UiContactsDirectorySearchView.h"
#import "UiContactsTabNavRouter.h"
#import "UiContactsDirectorySearchListRowItemView.h"
#import "UiContactsDirectorySearchListRowItemViewModel.h"
#import "AppManager.h"

#import "UiLogger.h"

#import "UiAlertControllerView.h"

#import "ContactsManager.h"

@interface UiContactsDirectorySearchView ()

@property (nonatomic, assign) id _CurrentResponder;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;


@property (weak, nonatomic) IBOutlet UISearchBar *SearchBar;

@property (weak, nonatomic) IBOutlet UITableView *List;

@end

@implementation UiContactsDirectorySearchView
{
    BOOL _IsAllBinded;
    NSTimer *SearchDelayer;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        
        self.ViewModel =  [[UiContactsDirectorySearchViewModel alloc] init];
        
        @weakify(self);
        
        [[self.ViewModel.SearchStateSignal deliverOnMainThread] subscribeNext:^(NSNumber *Value) {
            
            @strongify(self);
            
            if([Value intValue] == UiContactsDirectorySearchLoadingStateInProgress)
                [[[AppManager app] NavRouter] ShowPageProcessWithView:self.view];
            
            else if([Value intValue] == UiContactsDirectorySearchLoadingStateFinishedSuccess || [Value intValue] == UiContactsDirectorySearchLoadingStateFinishedFail)
                [[[AppManager app] NavRouter] HidePageProcessWithView:self.view];
            
        }];
        
        [[self.ViewModel.DataReloadedSignal deliverOnMainThread] subscribeNext:^(NSNumber *Value) {
            
            @strongify(self);
            
            if([Value boolValue])
            {
                if(self.ViewModel.RowsUpdateStages && [self.ViewModel.RowsUpdateStages count] > 0)
                {
                    if([self.ViewModel.RowsUpdateStages count] > 1)
                    {
                        [self.ViewModel.RowsUpdateStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.RowsUpdateStages.count - 1)];
                    }
                    
                    self.ViewModel.ThreadSafeRows = [self.ViewModel.RowsUpdateStages lastObject];
                    
                }
                
                [self.List reloadData];
            }
        }];
        
    }
    return self;
}

- (IBAction)BackAction:(id)sender {
    
    //[self.navigationController popToRootViewControllerAnimated:YES];
    
    [UiContactsTabNavRouter CloseDirectorySearchViewWhenBackAction];
    
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
    
    _IsAllBinded = TRUE;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UiContactsDirectorySearchListRowItemViewModel *RowItem;
    
    if ([self.ViewModel.ThreadSafeRows count] > 0)
    {
        NSIndexPath *IndexPath = [self.List indexPathForSelectedRow];
        
        RowItem = (UiContactsDirectorySearchListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:IndexPath.row];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsDirectorySearchView: User did select row at index path %li %li", (long)IndexPath.section, (long)IndexPath.row]];
    }
    
    
    [UiContactsTabNavRouter PrepareForSegue:segue sender:sender contactModel:RowItem ? RowItem.ContactData : nil];
    
}

#pragma mark UISearchBar delegates

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self._CurrentResponder = searchBar;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [SearchDelayer invalidate], SearchDelayer = nil;
    
    SearchDelayer = [NSTimer scheduledTimerWithTimeInterval:1
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

- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [theSearchBar resignFirstResponder];
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.ViewModel.ThreadSafeRows count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = @"UiContactsSearchDirectoryListCellView";
    
    UiContactsDirectorySearchListRowItemView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UiContactsDirectorySearchListRowItemViewModel *RowItem = (UiContactsDirectorySearchListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:indexPath.row];
    
    UILabel *TitleLabel = (UILabel *)[cell viewWithTag:101];
    TitleLabel.text = RowItem.Title;
    
    UIButton *AddContactButton = (UIButton *)[cell viewWithTag:102];
    
    if([RowItem.IsInLocalDirectory boolValue] || [RowItem.IsIam boolValue])
    {
        [AddContactButton setEnabled:NO];
    }
    else
    {
        [AddContactButton setEnabled:YES];
    }
    
    // Bindings
    
    @weakify(self);
    
    @weakify(RowItem);
    
    @weakify(cell);
    
    [[[AddContactButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        @strongify(RowItem);
        
        @strongify(cell);
        
        [self AddContactAction:AddContactButton :RowItem :cell];
        
    }];

    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UiContactsDirectorySearchListRowItemViewModel *RowItem = (UiContactsDirectorySearchListRowItemViewModel *)[self.ViewModel.ThreadSafeRows objectAtIndex:indexPath.row];
    
    [[ContactsManager Manager] DownloadAvatarForContactWithDodicallId:RowItem.ContactData.DodicallId];
    
    UIImageView *AvatarView = [cell viewWithTag:100];
    
    @weakify(AvatarView);
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(RowItem, AvatarPath) WithTakeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(AvatarView);
        AvatarView.image = Image;

    }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) AddContactAction:(UIButton *) AddContactButton : (UiContactsDirectorySearchListRowItemViewModel *) RowItem : (UiContactsDirectorySearchListRowItemView *) cell
{
    [UiLogger WriteLogInfo:@"UiContactsDirectorySearchView: Add contact button taped"];
    
    [AddContactButton setEnabled:NO];
    
    
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"Title_ContactWillBeAddedToYourContacts", nil)
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* AddAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_AddContact", nil) style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [UiLogger WriteLogInfo:@"UiContactsDirectorySearchView: Add action selected"];
                                                          
                                                          void (^Callback)(BOOL) = ^(BOOL Success){
                                                              
                                                              if(Success)
                                                              {
                                                                  [AddContactButton setEnabled:YES];
                                                                  
                                                                  UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                                                                         message:nil
                                                                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                                                                  
                                                                  Alert.title = NSLocalizedString(@"OkAlert_ContactSaved", nil);
                                                                  
                                                                  UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                                   handler:^(UIAlertAction * action) {
                                                                                                                       
                                                                                                                   }];
                                                                  
                                                                  [Alert addAction:OkAction];
                                                                  
                                                                  [self presentViewController:Alert animated:YES completion:nil];
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

@end
