//
//  UiAppLeftMenu.m
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

#import "UiAppLeftMenu.h"

#import "UiNavRouter.h"

#import "NUIRenderer.h"

#import "UiContactProfileView.h"

#import "UiLogger.h"
#import "ContactsManager.h"
#import <ObjC_ContactModel.h>


@interface UiAppLeftMenu ()

@property (weak, nonatomic) IBOutlet UITableView *BalanceStatusTable;

@property (weak, nonatomic) IBOutlet UILabel *AppVersionLabel;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarImageView;

@end

@implementation UiAppLeftMenu
{
    BOOL _IsAllBinded;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel = [[UiAppLeftMenuModel alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self BindAll];
}

- (void)menuDidOpened:(NSNotification*)Notification
{
    // Update balance
    [[AppManager app].UserSession UpdateBalance];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify(self);
    
    [[[RACObserve([AppManager app].UserSession, IsBalanceAvailable) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self.BalanceStatusTable reloadData];
        
    }];
    
    RAC(self.AppVersionLabel, text) = [RACObserve(self.ViewModel, AppVersionText) deliverOnMainThread];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidOpened:) name:SlideNavigationControllerDidOpen object:nil];
    
    RAC(self.AvatarImageView, image) = [[ContactsManager AvatarImageSignalForPathSignal:RACObserve(self.ViewModel, AvatarPath) WithTakeUntil:[RACSignal never]] deliverOnMainThread];

    _IsAllBinded = TRUE;
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(tableView == self.BalanceStatusTable)
    {
        if([AppManager app].UserSession.IsBalanceAvailable)
            return 2;
        else
            return 1;
    }
    
    return 0;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableView == self.BalanceStatusTable)
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
        
        if([CellIdentifier isEqualToString: @"UiContactProfileStatusCellView"])
        {
            UILabel *MyProfileStatusLabel = (UILabel *)[cell viewWithTag:105];
            
            [[RACObserve(self.ViewModel, MyProfileStatusLabelText) takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(NSString *StatusString) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [MyProfileStatusLabel setText:StatusString];
                    
                });
                
            }];
            
            UIView *MyProfileStatusIndicator = (UIView *)[cell viewWithTag:104];
            
            [[RACObserve(self.ViewModel, MyProfileStatus) takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(NSString *StatusString) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [NUIRenderer renderView:MyProfileStatusIndicator withClass:[NSString stringWithFormat:@"UiContactProfileStatusIndicatorView%@", StatusString]];
                    [MyProfileStatusIndicator setNeedsDisplay];
                    
                });
                
                
            }];
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
        
        if(([tableView numberOfRowsInSection:indexPath.section] > 1 && indexPath.row == 1) || ([tableView numberOfRowsInSection:indexPath.section] == 1 && indexPath.row == 0))
        {
            [[UiNavRouter NavRouter] ShowPreferenceStatusSetView];
        }
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(tableView == self.BalanceStatusTable)
    {
        if([AppManager app].UserSession.IsBalanceAvailable && indexPath.row == 1)
        {
            return 80;
        }
        else if(![AppManager app].UserSession.IsBalanceAvailable && indexPath.row == 0)
        {
            return 80;
        }
    }
    
    return tableView.rowHeight;
}

/*
#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    
    if([segue.identifier isEqualToString:UiPreferencesTabNavRouterSeguesShowPreferenceStatusSetView])
    {
        __weak UiPreferenceStatusSetView *StatusSetView = (UiPreferenceStatusSetView *)[segue destinationViewController];
        
        [StatusSetView setCallbackOnBackAction:^{
            
            [StatusSetView.navigationController popViewControllerAnimated:YES];
            
            [StatusSetView.navigationController setNavigationBarHidden:YES animated:YES];
            
        }];
        
        [UiPreferencesTabNavRouter PrepareForSegue:segue sender:sender];
    }
    
    else if([segue.identifier isEqualToString:UiPreferencesTabNavRouterMyProfile])
    {
        //[UiPreferencesTabNavRouter PrepareForSegue:segue sender:sender];
        
        [UiLogger WriteLogInfo:@"UiAppLeftMenu: Show preference my profile"];
        
        __weak UiContactProfileView *ContactProfileView = (UiContactProfileView *)[(UINavigationController *)[segue destinationViewController] topViewController];
        
        [ContactProfileView setCallbackOnBackAction:^{
            
            [ContactProfileView.navigationController popViewControllerAnimated:YES];
            
            //[ContactProfileView.navigationController setNavigationBarHidden:YES animated:YES];
            
        }];
        
        if((ObjC_ContactModel *) sender)
        {
            [UiLogger WriteLogDebug:[NSString stringWithFormat:@"UiAppLeftMenu: %@", [CoreHelper ContactModelDescription:(ObjC_ContactModel *) sender]]];
            
            [ContactProfileView.ViewModel setContactData:(ObjC_ContactModel *) sender];
        }
        
        //[[segue sourceViewController].navigationController setNavigationBarHidden:NO animated:NO];
    }
    
    
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if( [identifier isEqualToString:UiPreferencesTabNavRouterMyProfile] )
    {
        return NO;
    }
    
    
    return NO;
}
*/

- (IBAction) ShowMyProfile
{
    [[[AppManager app] NavRouter] ShowMyProfileView];
    
    /*
    @weakify(self);
    
    void (^Callback)(ObjC_ContactModel *) = ^(ObjC_ContactModel * MyProfile)
    {
        @strongify(self);
        
        [[[AppManager app] NavRouter] HidePageProcess];
        
        [self performSegueWithIdentifier:UiPreferencesTabNavRouterMyProfile sender:MyProfile];
    };
    
    [[[AppManager app] NavRouter] ShowPageProcess];
    
    [[AppManager app].UserSession GetMyProfile:Callback];
     */
    
}

- (IBAction)ServicesButtonAction:(id)sender
{
    [UiNavRouter ShowComingSoon];
}


@end
