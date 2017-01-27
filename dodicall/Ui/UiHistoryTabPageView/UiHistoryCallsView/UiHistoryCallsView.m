//
//  UiHistoryCallsView.m
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

#import "UiHistoryCallsView.h"
#import "UiHistoryTabNavRouter.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "UiHistoryCallsCallCellModel.h"
#import "UiHistoryCallsContactCellModel.h"

#import "NUIRenderer.h"

#import "UiAlertControllerView.h"
#import "UiLogger.h"
#import "ContactsManager.h"

@interface UiHistoryCallsView () {
    BOOL _IsBinded;
}
@property (weak, nonatomic) IBOutlet UITableView *CallsTable;
@property (weak, nonatomic) IBOutlet UITableView *ContactTable;
@property (weak, nonatomic) IBOutlet UIButton *FilterButton;
@property (weak, nonatomic) IBOutlet UIButton *EditButton;

@end

@implementation UiHistoryCallsView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self.ViewModel = [UiHistoryCallsViewModel new];
        [UiHistoryTabNavRouter ShowHistoryCallsView:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self BindAll];
}

- (void) BindAll {
    
    if(_IsBinded)
        return;
    
    @weakify(self);
    [[[[RACObserve(self.ViewModel, CallsRowsUpdated)
        filter:^BOOL(NSNumber *Updated) {
            return [Updated boolValue];
        }]
        throttle:0.3 afterAllowing:1 withStrike:1]
        deliverOnMainThread]
        subscribeNext:^(id x) {
            @strongify(self);
            if(self.ViewModel.CallsDataUpdateStages && self.ViewModel.CallsDataUpdateStages.count) {
                if(self.ViewModel.CallsDataUpdateStages.count > 1)
                    [self.ViewModel.CallsDataUpdateStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.CallsDataUpdateStages.count - 1)];
                
                self.ViewModel.ThreadSafeCallsRowsArray = [self.ViewModel.CallsDataUpdateStages lastObject];
            }
            
            [self.CallsTable reloadData];
        }];
    
    [[[RACObserve(self.ViewModel, ContactCellModel) ignore:nil] deliverOnMainThread] subscribeNext:^(id x) {
        @strongify(self);
        [self.ContactTable reloadData];
    }];
    
    self.FilterButton.rac_command = self.ViewModel.ShowComingSoonCommand;
    self.EditButton.rac_command = self.ViewModel.ShowComingSoonCommand;
    
    _IsBinded = YES;
}

- (IBAction)BackAction:(id)sender
{
    [self.ViewModel SetReaded];
    [UiHistoryTabNavRouter CloseHistoryCallsViewWhenBackAction];
}

#pragma mark - TableView Delegates
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableView == self.ContactTable)
        return 1;
    else
        return [self.ViewModel.ThreadSafeCallsRowsArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    @weakify(self);
    
    if(tableView == self.ContactTable) {
        
        UiHistoryCallsContactCellModel *cellModel = self.ViewModel.ContactCellModel;
        cell = [tableView dequeueReusableCellWithIdentifier:cellModel.CellId];
        
        UILabel *titleLabel = [cell viewWithTag:102];
        [titleLabel setText:cellModel.Title];
        
        UIButton *callButton = [cell viewWithTag:105];
        
        UIButton *messageButton;
        
        if([cellModel.CellId isEqualToString: @"UiHistoryCallsCellAproved"]) {
            
            UILabel *statusLabel = [cell viewWithTag:104];
            UIView *statusView = [cell viewWithTag:103];
            //UIButton *callButton = [cell viewWithTag:105];
            //UIButton *messageButton = [cell viewWithTag:106];
            
            [[[[RACObserve(cellModel, Description)
                takeUntil:cell.rac_prepareForReuseSignal]
                distinctUntilChanged]
                deliverOnMainThread]
                subscribeNext:^(NSString *StatusString) {
                    [statusLabel setText:StatusString];
                }];
            
            [[[[RACObserve(cellModel, Status)
                takeUntil:cell.rac_prepareForReuseSignal]
                distinctUntilChanged]
                deliverOnMainThread]
                subscribeNext:^(NSString *StatusString) {
                    [NUIRenderer renderView:statusView withClass:[NSString stringWithFormat:@"UiContactsListCellViewStatusIndicator%@", StatusString]];
                    [statusView setNeedsDisplay];
                }];
        }
        
        if([cellModel.CellId isEqualToString:@"UiHistoryCallsCellAproved"] ||
           [cellModel.CellId isEqualToString:@"UiHistoryCallsCellAprovedBlocked"])
        {
            messageButton = [cell viewWithTag:106];
            
            
            [[[[RACObserve(cellModel, Status)
                takeUntil:cell.rac_prepareForReuseSignal]
                distinctUntilChanged]
                deliverOnMainThread]
                subscribeNext:^(NSString *StatusString) {
                 
                    [NUIRenderer renderButtonAndSetNuiClass:callButton withClass:[NSString stringWithFormat:@"UiContactsListCellButton%@", StatusString]];
                 
                    [NUIRenderer renderButtonAndSetNuiClass:messageButton withClass:[NSString stringWithFormat:@"UiContactsListCellButton%@", StatusString]];
                 
                    [messageButton setNeedsDisplay];
                    [callButton setNeedsDisplay];
                 
                }];
            
            [[[messageButton rac_signalForControlEvents:UIControlEventTouchUpInside]
                takeUntil:cell.rac_prepareForReuseSignal]
                subscribeNext:^(id x) {
                    @strongify(self);
                    [self.ViewModel.MessageCommand execute:nil];
                }];
        }
        
        [[[callButton rac_signalForControlEvents:UIControlEventTouchUpInside]
            takeUntil:cell.rac_prepareForReuseSignal]
            subscribeNext:^(id x) {
                @strongify(self);
                [self.ViewModel.CallCommand execute:nil];
            }];
        
        if([cellModel.CellId isEqualToString:@"UiHistoryCallsCellExternalAdd"] || [cellModel.CellId isEqualToString:@"UiHistoryCallsCellExternalAddBlocked"]) {
            UIButton *addButton = [cell viewWithTag:106];
            
            [[[addButton rac_signalForControlEvents:UIControlEventTouchUpInside]
                takeUntil:cell.rac_prepareForReuseSignal]
                subscribeNext:^(id x) {
                    @strongify(self);
                    [self AddButtonPressed:addButton];
                }];
            
            NSLayoutConstraint *trailingToSuperview;
            NSLayoutConstraint *trailingToChat;
            
            for(NSLayoutConstraint *constraint in cell.contentView.constraints) {
                if([constraint.identifier isEqualToString:@"TrailingToSuperview"])
                    trailingToSuperview = constraint;
                if([constraint.identifier isEqualToString:@"TrailingToPlus"])
                    trailingToChat = constraint;
            }
            
            [addButton setAlpha:1.0];
            [addButton setEnabled:YES];
            
            [trailingToSuperview setPriority:998];
            [trailingToChat setPriority:999];
            
            [cell.contentView setNeedsUpdateConstraints];
            [cell.contentView layoutIfNeeded];
        }
    }
    else {
        UiHistoryCallsCallCellModel *cellModel = [self.ViewModel.ThreadSafeCallsRowsArray objectAtIndex:indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:cellModel.CellId];
        
        UIImageView *arrowImage = [cell viewWithTag:100];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NUIRenderer renderView:arrowImage withClass:[NSString stringWithFormat:@"UiHistoryCallsViewArrow%@", cellModel.ArrowColor]];
            
            [arrowImage setNeedsDisplay];
        });
        
        
        UIImageView *encryptionImage = [cell viewWithTag:101];
        encryptionImage.hidden = ![cellModel.Encrypted boolValue];
        
        
        UILabel *titleLabel = [cell viewWithTag:102];
        [titleLabel setText:cellModel.Title];
        
        UILabel *durationLabel = [cell viewWithTag:103];
        [durationLabel setText:cellModel.Duration];
        
        UILabel *dateLabel = [cell viewWithTag:104];
        [dateLabel setText:cellModel.Date];
        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(tableView == self.ContactTable) {
        ObjC_ContactModel *contact = [self.ViewModel.StatisticsModel.Contacts objectAtIndex:0];
        if(contact) {
            [UiHistoryTabNavRouter ShowContactProfileForContact:contact];
        }
        
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView != self.ContactTable)
        return;
    
    UiHistoryCallsContactCellModel *RowModel = self.ViewModel.ContactCellModel;
    UIImageView *AvatarView = [cell viewWithTag:100];
    
    @weakify(AvatarView);
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(RowModel, AvatarPath) WithTakeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(AvatarView);
        AvatarView.image = Image;
    }];
}


- (void) AddButtonPressed:(UIButton *)AddButton
{
    
            UITableViewCell *cell = [self.ContactTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if(self.ViewModel.StatisticsModel.Contacts[0]) {
        
        UiAlertControllerView* alert = [UiAlertControllerView
                                        alertControllerWithTitle:nil
                                        message:NSLocalizedString(@"Title_ContactWillBeCopiedAndSaved", nil)
                                        preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* AddAction = [UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Title_AddContact", nil)
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        
                                        void (^Callback)(BOOL) = ^(BOOL Success){
                                            
                                            if(Success) {
                                                NSLayoutConstraint *trailingToSuperview;
                                                NSLayoutConstraint *trailingToChat;
                                                
                                                for(NSLayoutConstraint *constraint in cell.contentView.constraints) {
                                                    if([constraint.identifier isEqualToString:@"TrailingToSuperview"])
                                                        trailingToSuperview = constraint;
                                                    if([constraint.identifier isEqualToString:@"TrailingToPlus"])
                                                        trailingToChat = constraint;
                                                }
                                                
                                                [AddButton setAlpha:0.0];
                                                [AddButton setEnabled:NO];
                                                
                                                [trailingToSuperview setPriority:999];
                                                [trailingToChat setPriority:998];
                                                
                                                [cell.contentView setNeedsUpdateConstraints];
                                                [cell.contentView layoutIfNeeded];
                                            }
                                                
                                            
                                            else {
                                                
                                                UiAlertControllerView* errorAlert = [UiAlertControllerView
                                                                                     alertControllerWithTitle:NSLocalizedString(@"ErrorAlert_ContactNotSaved", nil)
                                                                                     message:nil
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                
                                                
                                                
                                                UIAlertAction* OkAction = [UIAlertAction
                                                                           actionWithTitle:@"OK"
                                                                           style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction * action) {
                                                                               
                                                                           }];
                                                
                                                
                                                [errorAlert addAction:OkAction];
                                                [self presentViewController:errorAlert animated:YES completion:nil];
                                            }
                                            
                                        };
                                        
                                        
                                        [self.ViewModel SaveContactAndReturnInCallback:Callback];
                                        
                                    }];
        
        
        
        [alert addAction:AddAction];
        
        
        UIAlertAction* cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Title_Cancel", nil)
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction * action) {
                                           
                                       }];
        
        [alert addAction:cancelAction];
        
        
        UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
        popPresenter.sourceView = cell.contentView;
        popPresenter.sourceRect = cell.contentView.bounds;
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        
        UiAlertControllerView* alert = [UiAlertControllerView
                                        alertControllerWithTitle:nil
                                        message:NSLocalizedString(@"Title_SaveEmptyContact", nil)
                                        preferredStyle:UIAlertControllerStyleActionSheet];
        
        
        UIAlertAction* CreateNewAction = [UIAlertAction
                                          actionWithTitle:NSLocalizedString(@"Title_CreateNewContact", nil)
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * action) {
                                              
                                              
                                              //                                            void (^Callback)(BOOL) = ^(BOOL Success){
                                              //
                                              //                                                if(Success) {
                                              //                                                    [AddButton removeFromSuperview];
                                              //                                                }
                                              //                                                else {
                                              //
                                              //                                                    UiAlertControllerView* errorAlert = [UiAlertControllerView
                                              //                                                      alertControllerWithTitle:NSLocalizedString(@"ErrorAlert_ContactNotSaved", nil)
                                              //                                                                       message:nil
                                              //                                                                preferredStyle:UIAlertControllerStyleAlert];
                                              //
                                              //
                                              //
                                              //                                                    UIAlertAction* OkAction = [UIAlertAction
                                              //                                                                 actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                              //                                                                         handler:^(UIAlertAction * action) {
                                              //
                                              //                                                                         }];
                                              //
                                              //                                                    [errorAlert addAction:OkAction];
                                              //                                                    [self presentViewController:errorAlert animated:YES completion:nil];
                                              //                                                }
                                              //
                                              //                                            };
                                              
                                              
                                              [UiHistoryTabNavRouter ShowContactProfileEdit];
                                              
                                          }];
        
        
        
        
        
        
        UIAlertAction* AddToExistingAction = [UIAlertAction
                                              actionWithTitle:NSLocalizedString(@"Title_AddContactToExisting", nil)
                                              style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction * action) {
                                                  [self.ViewModel.ShowComingSoonCommand execute:nil];
                                              }];
        
        UIAlertAction* CancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Title_Cancel", nil)
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction * action) {
                                           
                                       }];
        
        [alert addAction:CancelAction];
        [alert addAction:AddToExistingAction];
        [alert addAction:CreateNewAction];
        
        
        UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
        popPresenter.sourceView = cell.contentView;
        popPresenter.sourceRect = cell.contentView.bounds;
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
}


@end
