//
//  UiHistoryTabNavRouter.m
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

#import "UiHistoryTabNavRouter.h"
#import "UiHistoryCallsViewModel.h"

#import "UiContactProfileView.h"
#import "UiContactProfileViewModel.h"
#import "UiContactProfileEditView.h"
#import "UiContactProfileEditViewModel.h"
#import "UiContactProfileEditContactsTableCellViewModel.h"

#import "ObjC_HistoryCallModel.h"
#import "ObjC_HistoryStatisticsModel.h"

static UiHistoryStatisticsView *HistoryStatisticsView;
static UiHistoryCallsView *HistoryCalls;
static UiContactProfileEditView *ProfileEdit;
static UiContactProfileView *Profile;

@implementation UiHistoryTabNavRouter

+ (void)Reset {
    HistoryStatisticsView = nil;
    HistoryCalls = nil;
    ProfileEdit = nil;
    Profile = nil;
}
+ (void)ShowStatisticsView:(UiHistoryStatisticsView *)View {
    HistoryStatisticsView = View;
}
+ (void)ShowHistoryCallsView:(UiHistoryCallsView *)View {
    HistoryCalls = View;
}
+ (void)CloseHistoryCallsViewWhenBackAction {
    [HistoryStatisticsView.navigationController popViewControllerAnimated:YES];
    HistoryCalls = nil;
}
+ (void) PrepareForSegue:(UIStoryboardSegue *) Segue WithStatistics:(ObjC_HistoryStatisticsModel *) StatisticsModel {
    
    if([Segue.identifier isEqualToString:@"UiHistoryStatisticsShowCalls"]) {
        
        HistoryStatisticsView = [Segue sourceViewController];
        
        HistoryCalls = (UiHistoryCallsView *)[[Segue destinationViewController] topViewController];
        
        HistoryCalls.ViewModel.StatisticsModel = StatisticsModel;
    }
    else if([Segue.identifier isEqualToString:@"UiHistoryStatisticsShowCreateContact"]) {
        HistoryStatisticsView = [Segue sourceViewController];
        
        HistoryCalls = (UiHistoryCallsView *)[[Segue destinationViewController] topViewController];
        HistoryCalls.ViewModel.StatisticsModel = StatisticsModel;
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
        ProfileEdit = (UiContactProfileEditView *)[storyboard instantiateViewControllerWithIdentifier:@"UiContactProfileEditView"];
        
        
        

        
        UiContactProfileEditViewModel *profileVM = ProfileEdit.ViewModel;
        
        
        
        

        [profileVM AddEmptyContact];
        [[profileVM.ContactsTable objectAtIndex:0] setPhoneTextFieldText:StatisticsModel.Identity];
        
        profileVM.BackViewAction = ^ {
            [UiHistoryTabNavRouter CloseProfileEdit];
        };
        profileVM.SaveViewAction = ^ {
            [UiHistoryTabNavRouter CloseProfileEdit];
        };
        
        [HistoryCalls.navigationController pushViewController:ProfileEdit animated:NO];
    }

}

+ (void) ShowContactProfileEdit {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
    ProfileEdit = (UiContactProfileEditView *)[storyboard instantiateViewControllerWithIdentifier:@"UiContactProfileEditView"];
    
    ObjC_HistoryStatisticsModel *StatisticsModel = HistoryCalls.ViewModel.StatisticsModel;


    
    UiContactProfileEditViewModel *profileVM = ProfileEdit.ViewModel;
    
    
    
    [profileVM AddEmptyContact];
    [[profileVM.ContactsTable objectAtIndex:0] setPhoneTextFieldText:StatisticsModel.Identity];
    
    profileVM.BackViewAction = ^ {
        [UiHistoryTabNavRouter CloseProfileEdit];
    };
    profileVM.SaveViewAction = ^ {
        [UiHistoryTabNavRouter CloseProfileEdit];
    };
    
    [HistoryCalls.navigationController pushViewController:ProfileEdit animated:YES];

    
}

+ (void) CloseProfileEdit {
    [ProfileEdit.navigationController popViewControllerAnimated:YES];
    ProfileEdit = nil;
}

+ (void) ShowContactProfileForContact:(ObjC_ContactModel *)Contact {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
    Profile = (UiContactProfileView *)[storyboard instantiateViewControllerWithIdentifier:@"UiContactProfileView"];
    Profile.ViewModel.ContactData = Contact;
    
    Profile.CallbackOnBackAction = ^ {
        [UiHistoryTabNavRouter CloseProfile];
    };
    
    [HistoryCalls.navigationController pushViewController:Profile animated:YES];
}

+ (void) CloseProfile {
    [Profile.navigationController popViewControllerAnimated:YES];
    Profile = nil;
}


@end
