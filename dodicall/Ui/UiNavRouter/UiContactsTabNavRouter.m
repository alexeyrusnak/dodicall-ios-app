//
//  UiContactsTabNavRouter.m
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

#import "UiContactsTabNavRouter.h"

#import "UiContactsListView.h"

#import "UiContactProfileView.h"
#import "UiContactProfileViewModel.h"

#import "UiContactProfileEditView.h"

#import "UiContactsDirectorySearchView.h"

#import "UiContactsRosterView.h"

#import <ObjC_ContactModel.h>

#import "UiLogger.h"

#import "UiPreferenceStatusSetView.h"

static UiContactsListView *ContactsListView;

static UiContactProfileView *ContactProfileView;

static UiContactProfileView *MyProfileView;

static UiContactProfileEditView *ProfileEditView;

static UiContactsDirectorySearchView *DirectorySearchView;

static UiContactsRosterView *ContactsRosterView;

@implementation UiContactsTabNavRouter

+ (void) Reset
{
    
    ContactsListView = nil;
    
    ContactProfileView = nil;
    
    ProfileEditView = nil;
    
    DirectorySearchView = nil;
    
    ContactsRosterView = nil;
    
    MyProfileView = nil;
    
}

+ (void)PrepareForSegue:(UIStoryboardSegue *)Segue sender:(id)Sender contactModel:(ObjC_ContactModel *) ContactModel
{
    
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowContactProfile])
    {
        
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show contact profile"];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactModel]]];
        
        ContactsListView = [Segue sourceViewController];
        
        ContactProfileView = (UiContactProfileView *)[[Segue destinationViewController] topViewController];
        
        if(ContactModel)
            [ContactProfileView.ViewModel setContactData:ContactModel];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowContactProfileEdit] || [[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowContactProfileEditNew])
    {

        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show contact profile edit"];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactModel]]];
        
        if([[Segue sourceViewController] isKindOfClass:[UiContactsListView class]])
        {
            ContactsListView = [Segue sourceViewController];
            
            ContactProfileView = (UiContactProfileView *)[[Segue destinationViewController] topViewController];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
            ProfileEditView = (UiContactProfileEditView *)[storyboard instantiateViewControllerWithIdentifier:@"UiContactProfileEditView"];
            
            [ContactProfileView.navigationController pushViewController:ProfileEditView animated:NO];
        }
        
        if([[Segue sourceViewController] isKindOfClass:[UiContactProfileView class]])
        {
            ContactProfileView = [Segue sourceViewController];
            
            ProfileEditView = [Segue destinationViewController];
            
            [ProfileEditView.ViewModel setContactData:ContactModel];
        }
        
    }
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowDirectorySearch])
    {
        
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show directory search view"];
        
        ContactsListView = [Segue sourceViewController];
        
        DirectorySearchView = (UiContactsDirectorySearchView *)[Segue destinationViewController];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowDirectorySearchContactProfile])
    {
        
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show contact profile"];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactModel]]];
        
        DirectorySearchView = [Segue sourceViewController];
        
        ContactProfileView = (UiContactProfileView *)[[Segue destinationViewController] topViewController];
        
        if(ContactModel)
            [ContactProfileView.ViewModel setContactData:ContactModel];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowContactsRoster])
    {
        
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show contacts roster search view"];
        
        ContactsListView = [Segue sourceViewController];
        
        ContactsRosterView = (UiContactsRosterView *)[Segue destinationViewController];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowRosterContactProfile])
    {
        
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show contact profile"];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactModel]]];
        
        ContactsRosterView = [Segue sourceViewController];
        
        ContactProfileView = (UiContactProfileView *)[[Segue destinationViewController] topViewController];
        
        if(ContactModel)
            [ContactProfileView.ViewModel setContactData:ContactModel];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowProfileStatusPreference])
    {
        
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show status set view"];
        
        //__weak UiContactProfileView *ContactProfileView = [Segue sourceViewController];
        
        __weak UiPreferenceStatusSetView *StatusSetView = (UiPreferenceStatusSetView *)[Segue destinationViewController];
        
        [StatusSetView setCallbackOnBackAction:^{
            
            [StatusSetView.navigationController popViewControllerAnimated:YES];
            
        }];
        
        
    }
    
    if ([[Segue identifier] isEqualToString:UiContactsTabNavRouterSegueShowPreferencesView])
    {
        
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Show preferences"];
        
        MyProfileView = (UiContactProfileView *)[Segue sourceViewController];
        
        [MyProfileView.navigationController setNavigationBarHidden:YES animated:NO];
        
    }
    
}

+ (void) CloseProfileViewWhenBackAction
{
    
    [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Contact profile view back action -> show contacts list"];
    
    [ContactsListView.navigationController popViewControllerAnimated:TRUE];
    ContactProfileView = nil;
    
}


+ (void) CloseProfileViewWhenSaveAction
{
    
    [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Contact profile view save action -> show contacts list"];
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ContactProfileView.ViewModel.ContactData]]];
    
    [ContactsListView.navigationController popViewControllerAnimated:TRUE];
    ContactProfileView = nil;
    
}

+ (void) CloseProfileEditViewWhenBackAction
{
    
    if(ProfileEditView.ViewModel.ContactData.Id == 0 && ProfileEditView.ViewModel.ContactData.PhonebookId == nil &&  ProfileEditView.ViewModel.ContactData.DodicallId == nil)
    {
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Contact profile edit view back action -> show contacts list"];
        
        [ContactsListView.navigationController popViewControllerAnimated:TRUE];
    }
    else
    {
        [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Contact profile edit view back action -> show contact profile view"];
        
        [ProfileEditView.navigationController popViewControllerAnimated:TRUE];
    }
    
    ProfileEditView = nil;
    
}

+ (void) CloseProfileEditViewWhenSaveAction
{
    [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Contact profile edit save action -> show contact profile view"];
    
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:ProfileEditView.ViewModel.ContactData]]];
    
    [ContactProfileView.ViewModel setContactData:ProfileEditView.ViewModel.ContactData];
    
    [ProfileEditView.navigationController popViewControllerAnimated:TRUE];
    
    ProfileEditView = nil;
}

+ (void) CloseProfileEditViewWhenDeleteAction
{
    [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Contact profile edit delete action -> show contacts list"];
    
    [ContactsListView.navigationController popToRootViewControllerAnimated:YES];
    
    ProfileEditView = nil;
    
    ContactProfileView = nil;
    
}

+ (void) CloseDirectorySearchViewWhenBackAction
{
    
    [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Directory search view back action -> show contacts list"];
    
    [ContactsListView.navigationController popToRootViewControllerAnimated:TRUE];
    
    DirectorySearchView = nil;
    
}


+ (void) CloseRosterViewWhenBackAction
{
    
    [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Contacts roster view back action -> show contacts list"];
    
    //[ContactsRosterView.navigationController popToRootViewControllerAnimated:YES];
    
    [ContactsListView.navigationController popToRootViewControllerAnimated:TRUE];
    
    
    
    ContactsRosterView = nil;
    
}

+ (void) ClosePreferencesViewWhenBackAction
{
    
    [UiLogger WriteLogInfo:@"UiContactsTabNavRouter: Preferences view back action -> show my profile"];
    
    [MyProfileView.navigationController setNavigationBarHidden:NO animated:NO];
    [MyProfileView.navigationController popToRootViewControllerAnimated:NO];
    
    MyProfileView = nil;
    
}

@end
