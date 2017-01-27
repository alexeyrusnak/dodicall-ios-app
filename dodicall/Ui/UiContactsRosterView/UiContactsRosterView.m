//
//  UiContactsRosterView.m
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

#import "UiContactsRosterView.h"

#import <NUI/NUIRenderer.h>

#import "UiLogger.h"

#import "UiAlertControllerView.h"

#import "UiContactsTabNavRouter.h"

#import "ContactsManager.h"

@interface UiContactsRosterView ()

@property (weak, nonatomic) IBOutlet UITableView *List;

@end

@implementation UiContactsRosterView
{
    BOOL _IsAllBinded;
}



- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        
        self.ViewModel =  [[UiContactsRosterViewModel alloc] init];
        
        @weakify(self);
        
        [[[self.ViewModel.DataReloadedSignal
            deliverOnMainThread]
            filter:^BOOL(NSNumber *Value) {
                return [Value boolValue];
            }]
            subscribeNext:^(NSNumber *Value) {
                @strongify(self);
            
                if(self.ViewModel.DataUpdateStages && self.ViewModel.DataUpdateStages.count) {
                    
                    if(self.ViewModel.DataUpdateStages.count > 1)
                         [self.ViewModel.DataUpdateStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.DataUpdateStages.count-1)];
                    
                    
                    NSDictionary *DataUpdateStage = [self.ViewModel.DataUpdateStages lastObject];
                    
                    self.ViewModel.ThreadSafeSections = [[DataUpdateStage objectForKey:@"Sections"] copy];
                    
                    self.ViewModel.ThreadSafeSectionsKeys = [[DataUpdateStage objectForKey:@"SectionsKeys"] copy];
                }
                
                [self.List reloadData];
                
            }];

        
    }
    return self;
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    
    
    _IsAllBinded = TRUE;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    [self BindAll];
    
}

- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    
}

- (IBAction)BackAction:(id)sender
{
    if(self.CallbackOnBackAction)
        self.CallbackOnBackAction();
    
    else
        [UiContactsTabNavRouter CloseRosterViewWhenBackAction];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UiContactsRosterRowItemViewModel *RowItem;
    
    if ([self.ViewModel.ThreadSafeSectionsKeys count] > 0 &&  [self.ViewModel.ThreadSafeSections count] > 0)
    {
        NSIndexPath *IndexPath = [self.List indexPathForSelectedRow];
        id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:IndexPath.section];
        NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
        
        RowItem = (UiContactsRosterRowItemViewModel *)[Rows objectAtIndex:IndexPath.row];
        
        [UiLogger WriteLogInfo:[NSString stringWithFormat:@"UiContactsRosterView: User did select row at index path %li %li", (long)IndexPath.section, (long)IndexPath.row]];
    }
    
    
    [UiContactsTabNavRouter PrepareForSegue:segue sender:sender contactModel:RowItem ? RowItem.ContactData : nil];
    
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    
    return [self.ViewModel.ThreadSafeSectionsKeys count];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    id Key = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:section];
    
    NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:Key];
    
    return [Rows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:indexPath.section];
    NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
    UiContactsRosterRowItemViewModel *RowItem = (UiContactsRosterRowItemViewModel *)[Rows objectAtIndex:indexPath.row];
    
    NSString *CellIdentifier = @"UiContactsRosterInviteCellView";
    
    if([RowItem.RequestType isEqualToString:UiContactsRosterRequestTypeRequest])
        CellIdentifier = @"UiContactsRosterRequestCellView";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *TitleLabel = (UILabel *)[cell viewWithTag:101];
    TitleLabel.text = RowItem.Title;
    
    if(RowItem.IsNew)
        [NUIRenderer renderLabelAndSetNuiClass:TitleLabel withClass:@"UiContactsRosterCellViewHeaderLabelNew"];
    else
        [NUIRenderer renderLabelAndSetNuiClass:TitleLabel withClass:@"UiContactsRosterCellViewHeaderLabel"];
    
    /*
    if([CellIdentifier isEqualToString: @"UiContactsRosterInviteCellView"])
    {
        UILabel *DescrLabel = (UILabel *)[cell viewWithTag:102];
        [[[RACObserve(RowItem, Description) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSString *StatusString) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [DescrLabel setText:StatusString];
            });
            
        }];
        
        UIView *Status = (UIView *)[cell viewWithTag:103];
        [[[RACObserve(RowItem, Status) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSString *StatusString) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NUIRenderer renderView:Status withClass:[NSString stringWithFormat:@"UiContactsListCellViewStatusIndicator%@", StatusString]];
                [Status setNeedsDisplay];
            });
            
            
        }];
    }
    */
    
    if([RowItem.RequestType isEqualToString:UiContactsRosterRequestTypeInvite])
    {
        UIButton *AcceptContactButton = (UIButton *)[cell viewWithTag:104];
        
        @weakify(self);
        
        [[[AcceptContactButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
            
            @strongify(self);
            
            [self AcceptAction: AcceptContactButton: RowItem: cell];
            
        }];
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id SectionKey = [self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:indexPath.section];
    NSArray *Rows = [self.ViewModel.ThreadSafeSections objectForKey:SectionKey];
    UiContactsRosterRowItemViewModel *RowItem = (UiContactsRosterRowItemViewModel *)[Rows objectAtIndex:indexPath.row];
    

    UIImageView *AvatarView = [cell viewWithTag:100];
    
    @weakify(AvatarView);
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(RowItem, AvatarPath) WithTakeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(AvatarView);
        AvatarView.image = Image;
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 28;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    static NSString *CellIdentifier = @"UiContactsRostertSectionHeaderView";
    
    UITableViewCell *HeaderView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *HeaderViewTitle = (UILabel *)[HeaderView viewWithTag:100];
    
    HeaderViewTitle.text = (NSString *)[self.ViewModel.ThreadSafeSectionsKeys objectAtIndex:section];
    
    return HeaderView;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

-(void) AcceptAction:(UIButton *) AcceptContactButton : (UiContactsRosterRowItemViewModel *) RowItem : (UITableViewCell *) cell
{
    [UiLogger WriteLogInfo:@"UiContactsRosterView: Apply contact button tapped"];
    
    [AcceptContactButton setEnabled:NO];
    
    
    UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"Title_DefaultInviteRequestText", nil)
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* AddAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Accept", nil) style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [UiLogger WriteLogInfo:@"UiContactsRosterView: Accept action selected"];
                                                          
                                                          void (^Callback)(BOOL) = ^(BOOL Success){
                                                              
                                                              if(Success)
                                                              {
                                                                  [AcceptContactButton setEnabled:YES];
                                                                  
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
                                                                  [AcceptContactButton setEnabled:YES];
                                                                  
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
                                                          
                                                          [self.ViewModel ExecuteAcceptAction: RowItem.ContactData withAccept:YES withCallback:Callback];
                                                          
                                                          
                                                      }];
    
    [alert addAction:AddAction];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [AcceptContactButton setEnabled:YES];
                                                             
                                                         }];
    
    [alert addAction:cancelAction];
    
    
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = cell.contentView;
    popPresenter.sourceRect = cell.contentView.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
