//
//  UiChatMakeConferenceView.m
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

#import "UiChatMakeConferenceView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "UiNavRouter.h"
#import "UiChatsTabNavRouter.h"
#import "ContactsManager.h"
#import "NUIRenderer.h"

@interface UiChatMakeConferenceView ()


@property (weak, nonatomic) IBOutlet UILabel *Title;

@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property (weak, nonatomic) IBOutlet UITableView *ChatMembersList;

@property (weak, nonatomic) IBOutlet UIButton *CallButton;

@end

@implementation UiChatMakeConferenceView
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiChatMakeConferenceViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self BindAll];
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify (self);
    
    [[[RACObserve(self.ViewModel, Title) ignore:nil] deliverOnMainThread] subscribeNext:^(NSString *Title) {
        
        @strongify(self);
        
        [self.Title setText:Title];
        
    }];
    
    [[self.BackButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        [UiChatsTabNavRouter CloseChatMakeConference];
        
    }];
    
    [[self.CallButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        [UiNavRouter ShowComingSoon];
        
    }];
    
    [[[RACObserve(self.ViewModel, DataReloaded)
        filter:^BOOL(NSNumber *Reloaded) {
            return [Reloaded boolValue];
        }]
        deliverOnMainThread]
        subscribeNext:^(id x) {
            @strongify(self);
         
             if(self.ViewModel.DataReloadStages && self.ViewModel.DataReloadStages.count) {
                 if(self.ViewModel.DataReloadStages.count > 1)
                     [self.ViewModel.DataReloadStages removeObjectsInRange:NSMakeRange(0, self.ViewModel.DataReloadStages.count - 1)];
                 
                 self.ViewModel.ThreadSafeChatUsersRows = [self.ViewModel.DataReloadStages lastObject];
             }
            [self.ChatMembersList reloadData];
        }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [self.ViewModel.ThreadSafeChatUsersRows count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UiChatMakeConferenceUsersRowViewModel *CellVM = [self.ViewModel.ThreadSafeChatUsersRows objectAtIndex:indexPath.row];
    UITableViewCell *Cell = [tableView dequeueReusableCellWithIdentifier:CellVM.CellId];
    
    
    //ObjC_ContactModel *contact = [self.ViewModel.ChatData.Contacts objectAtIndex:indexPath.row];
    
    
    UILabel *headerLabel = (UILabel *)[Cell viewWithTag:101];
    headerLabel.text = CellVM.Title;
    
    if([CellVM.CellId isEqualToString:@"UiContactsListCellViewOldApproved"] || [CellVM.CellId isEqualToString:@"UiContactsListCellViewNew"]) {
        UILabel *descriptionLabel = (UILabel *)[Cell viewWithTag:102];
        UIView *statusIndicator = [Cell viewWithTag:103];
        
        
        [[[RACObserve(CellVM, Status) takeUntil:Cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSString *StatusString) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                statusIndicator.nuiClass = [NSString stringWithFormat:@"UiChatsListCellViewStatusIndicator%@", StatusString];
                
                [NUIRenderer renderView:statusIndicator withClass:statusIndicator.nuiClass];
                
                [statusIndicator setNeedsDisplay];
            });
        }];
        
        [[[RACObserve(CellVM, Description) takeUntil:Cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSString *Description) {
            dispatch_async(dispatch_get_main_queue(), ^{
                descriptionLabel.text = Description;
            });
        }];
        
    }
    
    UIImageView *CheckIcon = (UIImageView *)[Cell viewWithTag:110];
    
    [[[RACObserve(CellVM, IsSelected) takeUntil:Cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSNumber *Selected) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if([Selected boolValue])
                [CheckIcon setAlpha:1.0];
            else
                [CheckIcon setAlpha:0.0];
        });
        
    }];
    
    [[[RACObserve(CellVM, IsDisabled) takeUntil:Cell.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSNumber *Disabled) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if([Disabled boolValue])
            {
                [Cell setUserInteractionEnabled:NO];
                [Cell.contentView setAlpha:0.5];
            }
            else
            {
                [Cell setUserInteractionEnabled:YES];
                [Cell.contentView setAlpha:1.0];
            }
        });
        
    }];
    
    return Cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UiChatMakeConferenceUsersRowViewModel *CellVM = [self.ViewModel.ThreadSafeChatUsersRows objectAtIndex:indexPath.row];
    
    UIImageView *AvatarView = [cell viewWithTag:100];
    
    @weakify(AvatarView);
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(CellVM, AvatarPath) WithTakeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(AvatarView);
        AvatarView.image = Image;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UiChatMakeConferenceUsersRowViewModel *CellVM = [self.ViewModel.ThreadSafeChatUsersRows objectAtIndex:indexPath.row];
    
    [self.ViewModel RevertSelected:CellVM];
}

@end
