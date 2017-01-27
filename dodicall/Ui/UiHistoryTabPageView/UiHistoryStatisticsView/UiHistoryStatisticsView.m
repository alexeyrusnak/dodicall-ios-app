//
//  UiHistoryStatisticsView.m
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

#import "UiHistoryStatisticsView.h"
#import "UiHistoryStatisticsViewModel.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "ObjC_ContactModel.h"

#import "UiHistoryStatisticsCellModel.h"

#import "NUIRenderer.h"

#import "UiHistoryTabNavRouter.h"
#import "UiHistoryCallsView.h"
#import "UiHistoryCallsViewModel.h"

#import "UiAlertControllerView.h"
#import "UiLogger.h"

#import "UiHistoryStatisticsCell.h"
#import "ContactsManager.h"

@class ObjC_ContactModel;
@class ObjC_HistoryStatisticsModel;

@interface UiHistoryStatisticsView () {
    BOOL _IsBinded;
}

@property (weak, nonatomic) IBOutlet UIButton *FilterButton;
@property (weak, nonatomic) IBOutlet UIButton *EditButton;
@property (weak, nonatomic) IBOutlet UITableView *HistoryTable;

@property (strong, nonatomic) UiHistoryStatisticsViewModel *ViewModel;

@end

@implementation UiHistoryStatisticsView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.ViewModel = [UiHistoryStatisticsViewModel new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UiHistoryTabNavRouter ShowStatisticsView:self];
    
    [self BindAll];
}

- (void)BindAll {
    if(_IsBinded)
        return;
    
    @weakify(self);
    [[[[RACObserve(self.ViewModel, DataReloaded)
        filter:^BOOL(NSNumber *Updated) {
            return [Updated boolValue];
        }]
        throttle:0.3 afterAllowing:1 withStrike:1.0]
        deliverOnMainThread]
        subscribeNext:^(id x) {
            @strongify(self);
            if(self.ViewModel.DataUpdateStages && self.ViewModel.DataUpdateStages.count) {
                if(self.ViewModel.DataUpdateStages.count > 1)
                    [self.ViewModel.DataUpdateStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.DataUpdateStages.count - 1)];
                
                self.ViewModel.ThreadSafeRows = [self.ViewModel.DataUpdateStages lastObject];
            }
            [UiLogger WriteLogDebug:@"UiHistoryStatisticsView - Reload data"];
            [self.HistoryTable reloadData];
        }];
    
    self.FilterButton.rac_command = [self.ViewModel ShowComingSoonCommand];
    self.EditButton.rac_command = [self.ViewModel ShowComingSoonCommand];
    
    
    _IsBinded = YES;
}

#pragma mark - TableView delegates
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.ViewModel.ThreadSafeRows count];
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UiHistoryStatisticsCell *Cell = (UiHistoryStatisticsCell *)cell;
    
    UiHistoryStatisticsCellModel *RowModel = [self.ViewModel.ThreadSafeRows objectAtIndex:indexPath.row];
    
    [Cell.TitleLabel setText:RowModel.Title];
    [Cell.TitleIndicatorLabel setText:RowModel.TitleIndicator];
    [Cell.DateLabel setText:RowModel.CallInfo];
    
    [Cell.IncomingSuccessfulLabel setText:[NSString stringWithFormat:@"%@",RowModel.NumberOfIncomingSuccessfulCalls]];
    [Cell.IncomingUnsuccessfulLabel setText:[NSString stringWithFormat:@"%@",RowModel.NumberOfIncomingUnsuccessfulCalls]];
    [Cell.OutgoingSuccessfulLabel setText:[NSString stringWithFormat:@"%@",RowModel.NumberOfOutgoingSuccessfulCalls]];
    [Cell.OutgoingUnsuccessfulLabel setText:[NSString stringWithFormat:@"%@",RowModel.NumberOfOutgoingUnsuccessfulCalls]];
    
    Cell.DodicallImage.hidden = ![RowModel.IsDodicall boolValue];
    
    if([RowModel.HasIncomingEncryptedCall boolValue])
    {
        [Cell.IncomingEncryptedImage setAlpha:1.0];
        [Cell.LeadingToNameLeft setPriority:998];
        [Cell.LeadingToLockLeft setPriority:999];
    }
    else
    {
        [Cell.IncomingEncryptedImage setAlpha:0.0];
        [Cell.LeadingToNameLeft setPriority:999];
        [Cell.LeadingToLockLeft setPriority:998];
    }
    
    if([RowModel.HasOutgoingEncryptedCall boolValue])
    {
        [Cell.OutgoingEncryptedImage setAlpha:1.0];
        [Cell.LeadingToNameRight setPriority:998];
        [Cell.LeadingToLockRight setPriority:999];
    }
    else
    {
        [Cell.OutgoingEncryptedImage setAlpha:0.0];
        [Cell.LeadingToNameRight setPriority:999];
        [Cell.LeadingToLockRight setPriority:998];
    }
    
    
    @weakify(self);
    @weakify(Cell);
    @weakify(RowModel);
    [[[Cell.CallButton rac_signalForControlEvents:UIControlEventTouchUpInside] takeUntil:Cell.rac_prepareForReuseSignal] subscribeNext:^(id x) {
        @strongify(self);
        @strongify(Cell);
        @strongify(RowModel);

        [Cell.CallButton setEnabled:NO];
        [[self.ViewModel.CallCommand execute:RowModel.HistoryModel] subscribeCompleted:^{
            [Cell.CallButton setEnabled:YES];
        }];
    }];
    
    if([RowModel.CellId isEqualToString: @"UiHistoryTableCellAproved"]) {
        
        [[[Cell.MessageButton rac_signalForControlEvents:UIControlEventTouchUpInside] takeUntil:Cell.rac_prepareForReuseSignal]subscribeNext:^(id x) {
            @strongify(self);
            @strongify(Cell);
            @strongify(RowModel);
            [Cell.MessageButton setEnabled:NO];
            [[self.ViewModel.ChatCommand execute:RowModel.HistoryModel] subscribeCompleted:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [Cell.MessageButton setEnabled:YES];
                });
            }];
        }];
        
        [[[RACObserve(RowModel, Status) takeUntil:Cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSString *StatusString) {
            @strongify(Cell);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [NUIRenderer renderButton:Cell.CallButton withClass:[NSString stringWithFormat:@"UiContactsListCellButton%@", StatusString]];

                [NUIRenderer renderButton:Cell.MessageButton withClass:[NSString stringWithFormat:@"UiContactsListCellButton%@", StatusString]];
                
            });
            
            
        }];
    }
    
    if([RowModel.CellId isEqualToString:@"UiHistoryTableCellExternalAdd"]) {
        
        [[[Cell.AddButton rac_signalForControlEvents:UIControlEventTouchUpInside] takeUntil:Cell.rac_prepareForReuseSignal] subscribeNext:^(id x) {
            @strongify(self);
            [self AddButtonPressedForIndexPath:indexPath];
        }];
        
        
        [Cell.AddButton setAlpha:1.0];
        [Cell.AddButton setEnabled:YES];
        
        [Cell.TrailingToSuperview setPriority:998];
        [Cell.TrailingToPlus setPriority:999];
        
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [NUIRenderer renderLabel:Cell.TitleLabel withClass:[NSString stringWithFormat:@"UiHistoryStatisticsViewTitle%@", RowModel.TitleIndicatorColor]];
        [NUIRenderer renderLabel:Cell.TitleIndicatorLabel withClass:[NSString stringWithFormat:@"UiHistoryStatisticsViewTitle%@", RowModel.TitleIndicatorColor]];
        
        [Cell.TitleLabel setNeedsDisplay];
        [Cell.TitleIndicatorLabel setNeedsDisplay];
        
    });
    
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(RowModel, AvatarPath) WithTakeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(Cell);
        Cell.AvatarImage.image = Image;
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UiHistoryStatisticsCellModel *RowModel = [self.ViewModel.ThreadSafeRows objectAtIndex:indexPath.row];
    UiHistoryStatisticsCell *Cell = [tableView dequeueReusableCellWithIdentifier:RowModel.CellId];
    
    
    [Cell.DodicallImage.layer setDrawsAsynchronously:YES];
    [Cell.AvatarImage.layer setDrawsAsynchronously:YES];
    [Cell.CallButton.imageView.layer setDrawsAsynchronously:YES];
    
    
    if([RowModel.CellId isEqualToString: @"UiHistoryTableCellAproved"]) {
        [Cell.MessageButton.imageView.layer setDrawsAsynchronously:YES];
    }
    if([RowModel.CellId isEqualToString:@"UiHistoryTableCellExternalAdd"]) {
        [Cell.AddButton.imageView.layer setDrawsAsynchronously:YES];
    }

    return Cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


 #pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     
     NSIndexPath *indexPath = [self.HistoryTable indexPathForSelectedRow];
     
     UiHistoryStatisticsCellModel *rowModel = [self.ViewModel.ThreadSafeRows objectAtIndex:indexPath.row];
     
     [UiHistoryTabNavRouter PrepareForSegue:segue WithStatistics:rowModel.HistoryModel];
 }


- (void) AddButtonPressedForIndexPath:(NSIndexPath *)IndexPath
{
    
    
    UiHistoryStatisticsCellModel *cellModel = [self.ViewModel.ThreadSafeRows objectAtIndex:IndexPath.row];
    UiHistoryStatisticsCell *cell = [self.HistoryTable cellForRowAtIndexPath:IndexPath];
    
    
    if(cellModel.HistoryModel.Contacts[0]) {
        
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
                                          
                                          [cell.AddButton setAlpha:0.0];
                                          [cell.AddButton setEnabled:NO];
                                          
                                          [cell.TrailingToSuperview setPriority:999];
                                          [cell.TrailingToPlus setPriority:998];
                                          
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
                                  
                                  
                                  [self.ViewModel SaveContactForIndexPath:IndexPath AndReturnInCallback:Callback];
                                  
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
                                            
                                            
                                            [self performSegueWithIdentifier:@"UiHistoryStatisticsShowCreateContact" sender:cell.AddButton];
                                            
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
