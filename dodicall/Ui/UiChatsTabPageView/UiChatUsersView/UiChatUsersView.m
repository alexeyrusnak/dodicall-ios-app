//
//  UiChatUsersView.m
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

#import "UiChatUsersView.h"

#import "NUIRenderer.h"
#import "ChatsManager.h"
#import "ContactsManager.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UiChatUsersView ()

@property (weak, nonatomic) IBOutlet UITableView *MenuList;

@property (weak, nonatomic) IBOutlet UITableView *ChatUsersList;
@property (weak, nonatomic) IBOutlet UIButton *DoneButton;
@property (weak, nonatomic) IBOutlet UILabel *TitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *NavTitle;

@end

@implementation UiChatUsersView
{
    BOOL _IsAllBinded;
    NSTimer *_SearchDelayer;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel =  [[UiChatUsersViewModel alloc] init];
    }
    
    return self;
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

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify (self);
    

    [[[RACObserve(self.ViewModel, ChatName) ignore:nil] deliverOnMainThread] subscribeNext:^(NSString *ChatName) {
        @strongify(self);
        [self.TitleLabel setText:ChatName];
    }];

    [[[[RACObserve(self.ViewModel, ChatData) ignore:nil]
        combineLatestWith:RACObserve(self.ViewModel, IsNewChat)]
        deliverOnMainThread]
        subscribeNext:^(RACTuple *Tuple) {
            @strongify(self);

            RACTupleUnpack(ObjC_ChatModel *Chat, NSNumber *IsNewChat) = Tuple;
        
            if(Chat.Id && Chat.Id.length && [IsNewChat boolValue]) {
                [UiChatsTabNavRouter CloseChatUsersViewWithCallback:^{
                    [UiChatsTabNavRouter ShowChatView:Chat];
                }];
            }
            
            if([IsNewChat boolValue])
                [self.NavTitle setText:NSLocalizedString(@"ChatUsers_NewChat", nil)];
            else
                [self.NavTitle setText:NSLocalizedString(@"ChatUsers_ChatParticipants", nil)];
        }];
    
    
    
    [[[RACSignal combineLatest:@[RACObserve(self.ViewModel, IsActive),
                                 RACObserve(self.ViewModel, IsNewChat),
                                 RACObserve(self.ViewModel, NumberOfContacts)]]
        deliverOnMainThread]
        subscribeNext:^(RACTuple *Tuple) {
            RACTupleUnpack(NSNumber *IsActive, NSNumber *IsNewChat, NSNumber *NumberOfContacts) = Tuple;
            @strongify(self);
            
            if([IsNewChat boolValue]) {
                self.DoneButton.enabled = [self.ViewModel ChatChanged];
            }
            else {
                self.DoneButton.enabled = NO;
                self.DoneButton.hidden = YES;
            }
            
            [self.MenuList setAllowsSelection:[IsActive boolValue]||[IsNewChat boolValue]];

        }];
    
//    [RACObserve(self.ViewModel, IsActive) subscribeNext:^(id x) {
//        @strongify(self);
//        [self.ChatUsersList reloadData];
//    }];

    
    
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
            
            [self.ChatUsersList reloadData];
        }];
    

    
    
    _IsAllBinded = YES;
}

#pragma mark - Buttons actions

- (IBAction)BackButtonAction:(id)sender {
    [UiChatsTabNavRouter CloseChatUsersViewWhenBackAction];
}

- (IBAction)CreateChatAction:(id)sender {
    [self.ViewModel CreateChat];
}


#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger Sections = 0;
    
    if(tableView == self.MenuList)
        Sections = 1;
    
    if(tableView == self.ChatUsersList)
        Sections = 1;
    
    return Sections;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger Rows = 0;
    
    if(tableView == self.MenuList)
        Rows = 1;
    
    if(tableView == self.ChatUsersList)
        Rows = [self.ViewModel.ThreadSafeChatUsersRows count];
    
    return Rows;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(tableView == self.MenuList)
    {
        NSString *CellIdentifier = @"UiChatUsersMenuListAddUserBtnCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        return cell;
    }
    else if(tableView == self.ChatUsersList) {
        
        UiChatUsersRowViewModel *cellVM = [self.ViewModel.ThreadSafeChatUsersRows objectAtIndex:indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellVM.CellId];
        
        //ObjC_ContactModel *contact = [self.ViewModel.NewChatData.Contacts objectAtIndex:indexPath.row];
        
        
        UILabel *headerLabel = (UILabel *)[cell viewWithTag:101];
        headerLabel.text = cellVM.Title;
        
        
        
        if([cellVM.CellId isEqualToString:@"UiContactsListCellViewOldApproved"] || [cellVM.CellId isEqualToString:@"UiContactsListCellViewNew"]) {
            UILabel *descriptionLabel = (UILabel *)[cell viewWithTag:102];
            UIView *statusIndicator = [cell viewWithTag:103];
            
            @weakify(statusIndicator);
            
            [[[[RACObserve(cellVM, Status) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSString *StatusString) {
                
                //dispatch_async(dispatch_get_main_queue(), ^{
                    
                @strongify(statusIndicator);
                
                statusIndicator.nuiClass = [NSString stringWithFormat:@"UiChatsListCellViewStatusIndicator%@", StatusString];
                    
                [NUIRenderer renderView:statusIndicator withClass:statusIndicator.nuiClass];
                    
                [statusIndicator setNeedsDisplay];
                //});
            }];
            
            
            @weakify(descriptionLabel);
            [[[[RACObserve(cellVM, Description) takeUntil:cell.rac_prepareForReuseSignal] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSString *Description) {
                //dispatch_async(dispatch_get_main_queue(), ^{
                
                @strongify(descriptionLabel);
                
                descriptionLabel.text = Description;
                
                //});
            }];

        }
        
        if([self.ViewModel.IsNewChat boolValue]) {
            UIButton *deleteButton = (UIButton *)[cell viewWithTag:105];
            
            @weakify(self);
            @weakify(cellVM);
            
            [[[deleteButton rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext: ^(id value) {
                
                @strongify(self);
                @strongify(cellVM);

                [self.ViewModel.ThreadSafeChatUsersRows removeObject:cellVM];
                [self.ViewModel.NewChatData.Contacts removeObject:cellVM.ContactData];
                self.ViewModel.NumberOfContacts = [NSNumber numberWithInteger:[self.ViewModel.NewChatData.Contacts count]];
                
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[tableView indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationLeft];
            }];

        }
        
        return cell;
    }
    
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableView != self.ChatUsersList)
        return;
    
    UiChatUsersRowViewModel *CellVM = [self.ViewModel.ThreadSafeChatUsersRows objectAtIndex:indexPath.row];
    
    UIImageView *AvatarView = [cell viewWithTag:100];
    @weakify(AvatarView);
    [[[ContactsManager AvatarImageSignalForPathSignal:RACObserve(CellVM, AvatarPath) WithTakeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(UIImage *Image) {
        @strongify(AvatarView);
        AvatarView.image = Image;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(tableView == self.ChatUsersList) {
        ObjC_ContactModel *contact = [self.ViewModel.ThreadSafeChatUsersRows objectAtIndex:indexPath.row].ContactData;
        [UiChatsTabNavRouter ShowContactProfileForContact:contact];
    }

}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if(![self.ViewModel.IsActive boolValue])
        return nil;
    
    if(tableView == self.ChatUsersList) {
        
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Title_Delete", nil)  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            NSInteger RowToRemove = indexPath.row;
            
            [self.ViewModel RemoveContact:RowToRemove];
            
            UITableViewRowAnimation RemoveAnimation = UITableViewRowAnimationBottom;
            
            NSMutableArray *IndexPathsToRemove = [[NSMutableArray alloc] init];
            [IndexPathsToRemove addObject:[NSIndexPath indexPathForRow:RowToRemove inSection:0]];
            
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:IndexPathsToRemove withRowAnimation:RemoveAnimation];
            [tableView endUpdates];
            
        }];
        
        // TODO: Add font and background color to NUIRenderer
        deleteAction.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:0.0 blue:30.0/255.0 alpha:1.0];
        
        return @[deleteAction];
        
    }
    
    return nil;
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if(![[[self ViewModel] IsActive] boolValue] || [[[self ViewModel] IsP2P]boolValue])
        return NO;
    
    if(tableView == [self ChatUsersList])
        return YES;
    
    return NO;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [UiChatsTabNavRouter PrepareForSegue:segue sender:sender chatModel:self.ViewModel.NewChatData];
}

@end
