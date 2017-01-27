//
//  UiChatsTabNavRouter.m
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

#import "UiChatsTabNavRouter.h"

#import "UiChatsListView.h"
#import "UiChatView.h"
#import "UiChatUsersView.h"
#import "UiChatMakeConferenceView.h"
#import "UiChatUsersSelectView.h"
#import "UiContactsListView.h"
#import "UiChatSettingsView.h"
#import "UiChatTitleSettingsView.h"
#import "UiChatMessageEditView.h"
#import "UiLogger.h"

#import "UiNavRouter.h"

#import "ChatsManager.h"

#import "UiAlertControllerView.h"

static UiChatsListView *ChatsListView;
static UiChatView *ChatView;
static UiChatUsersView *ChatUsersView;
static UiChatUsersSelectView *ChatUsersSelectView;
static UiContactProfileView *ProfileView;
static UiChatMakeConferenceView *ChatMakeConferenceView;
//static UiChatNameSettingView *NameSetting;

@implementation UiChatsTabNavRouter

+ (void) Reset
{
    ChatsListView = nil;
    ChatView = nil;
    ChatUsersView = nil;
    ChatUsersSelectView = nil;
    ProfileView = nil;
    ChatMakeConferenceView = nil;
}

+ (void)PrepareForSegue:(UIStoryboardSegue *)Segue sender:(id)Sender chatModel:(ObjC_ChatModel *) ChatModel
{
    
    if ([[Segue identifier] isEqualToString:UiChatsTabNavRouterSegueShowChat])
    {
        
        [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show chat view"];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ChatModel: %@", @"TODO"]];
        
        ChatsListView = [Segue sourceViewController];
        
        ChatView = (UiChatView *)[[Segue destinationViewController] topViewController];
        
        ChatView.ViewModel.ChatData = [ChatsManager CopyChat:ChatModel];
        
        //ChatView.hidesBottomBarWhenPushed = YES;
        
    }
    
    if ([[Segue identifier] isEqualToString:UiChatsTabNavRouterSegueShowChatUsers])
    {
        
        [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show chat users view"];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ChatModel: %@", @"TODO"]];
        
        ChatsListView = [Segue sourceViewController];
        
        ChatUsersView = (UiChatUsersView *)[Segue destinationViewController];
        
        ChatUsersView.ViewModel.ChatData = [ChatsManager CopyChat:ChatModel];
        
    }
    
    if ([[Segue identifier] isEqualToString:UiChatsTabNavRouterSegueShowChatSelectUsers])
    {
        
        [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show chat select users view"];
        
        [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ChatModel: %@", @"TODO"]];
        
        ChatUsersSelectView = (UiChatUsersSelectView *)[Segue destinationViewController];
        
        ChatUsersSelectView.ViewModel.ChatData = ChatModel;//[ChatsManager CopyChat:ChatModel]; //DMC-5802
        
    }
}

+ (void) ShowChatView:(ObjC_ChatModel *) ChatModel
{
    /*
    if(ChatView)
    {
        if(![ChatView.ViewModel.ChatData.Id isEqualToString:ChatModel.Id])
        {
            //[self CloseChatViewWhenBackAction:NO];
            //ChatView.ViewModel.ChatData = ChatModel;
            //return;
            
            //[[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:YES];
            
            //ChatView = nil;
            
        }
        else
        {
            return;
        }
    }
     */
    
    if(ChatModel)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiChatsTabPageView" bundle:nil];
    
        ChatView = [storyboard instantiateViewControllerWithIdentifier:@"UiChatView"];
        
        ChatView.ViewModel.ChatData = [ChatsManager CopyChat:ChatModel];
        
        [[UiNavRouter NavRouter].AppMainNavigationView pushViewController:ChatView animated:YES];

        [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:NO animated:YES];
    }
    
}

+ (void) ShowChatViewByChatIdOrWaitChat:(NSString *) ChatId
{
    RACSignal *LoadChatSignal = [RACSignal
         createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[ChatsManager Chats] GetOrLoadFromCoreChatById:ChatId AndReturnItInCallback:^(ObjC_ChatModel *ChatModel) {
                 if(ChatModel && ChatModel.Id && ChatModel.Id.length)
                     [subscriber sendNext:ChatModel];
                 else
                     [subscriber sendError:[NSError errorWithDomain:@"ChatNotCreated" code:-1 userInfo:nil]];
             }];
             
             return [RACDisposable new];
         }];
    
    
    [[[LoadChatSignal
        take:1] deliverOnMainThread]
        subscribeError:^(NSError *error) {
            [UiLogger WriteLogDebug:@"UiChatsTabNavRouter: Error chat load - Show Chats Tab Page"];
            [[UiNavRouter NavRouter] ShowChatsTabPage];
        }];

    
    
    RACSignal *DelayedLoadChatSignal =
        [LoadChatSignal
         catch:^RACSignal *(NSError *error) {
             [UiLogger WriteLogDebug:@"UiChatsTabNavRouter: Error chat load - Try again"];
             return [[[RACSignal
                        empty]
                        delay:0.6]
                        concat:[RACSignal error:error]];
         }];
        


    @weakify(self);
    
    [[[DelayedLoadChatSignal
        retry:10]
        deliverOnMainThread]
        subscribeNext:^(ObjC_ChatModel *ChatModel) {
              
            [UiLogger WriteLogDebug:@"UiChatsTabNavRouter: Success chat load"];

            @strongify(self);
            
            if(ChatView)
            {
              if(![ChatView.ViewModel.ChatData.Id isEqualToString:ChatModel.Id])
              {
                  [self CloseChatViewWhenBackAction:YES WithCallback:^{
                      
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          [self ShowChatView:ChatModel];
                          
                      });
                      
                  }];
              }
            }
            else
            {
              [self ShowChatView:ChatModel];
            }
        }];

    
}

+ (void) CreateAndShowChatViewWithContact:(ObjC_ContactModel *) ContactModel
{
    [[ChatsManager Chats] GetOrCreateP2PChatWithContact:ContactModel AndReturnItInCallback:^(ObjC_ChatModel *ChatModel) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(ChatModel)
                [self ShowChatView:ChatModel];
            else
                [UiNavRouter ShowUnknownError];
            
        });
    }];
}

+ (void) CloseChatViewWhenBackAction:(BOOL) Animated
{
    
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Chat view back action -> show chats list"];
    
    //[[UiNavRouter NavRouter].AppMainNavigationView popViewControllerAnimated:Animated];
    
    
    //[ChatView UnBindAll];
    
    [[[AppManager app] NavRouter].AppMainNavigationView popViewControllerAnimated:YES];
    ChatView = nil;
    
    //Try to find previous chat view
    UiChatView *PreviousChatView;
    
    NSArray *NavViewControllers = [[AppManager app] NavRouter].AppMainNavigationView.viewControllers;
    
    for(UIViewController *Controller in NavViewControllers) {
        if([Controller isKindOfClass:[UiChatView class]])
            PreviousChatView = (UiChatView *)Controller;
    }
    
    if(PreviousChatView)
        ChatView = PreviousChatView;
    else
        [[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:Animated];
    
    //[[[AppManager app] NavRouter].AppMainNavigationView popToRootViewControllerAnimated:YES];
    //[[[AppManager app] NavRouter].AppMainNavigationView setNavigationBarHidden:YES animated:YES];
    
}

+ (void) CloseChatViewAndAllChatSubviewsWithChatId:(NSString *) ChatId
{
    NSArray *NavViewControllers = [[[AppManager app] NavRouter].AppMainNavigationView.viewControllers copy];
    
    NSMutableArray *ChatSubViewControllers;
    
    for(UIViewController *Controller in NavViewControllers)
    {
        
        if(ChatSubViewControllers && [ChatSubViewControllers count])
        {
            [ChatSubViewControllers addObject:Controller];
        }
        
        if([Controller isKindOfClass:[UiChatView class]])
        {
            UiChatView *ChatView = (UiChatView *)Controller;
            
            if(ChatView.ViewModel && ChatView.ViewModel.ChatData && ChatView.ViewModel.ChatData.Id && [ChatView.ViewModel.ChatData.Id isEqualToString:ChatId])
            {
                
                ChatSubViewControllers = [NSMutableArray new];
                
                [ChatSubViewControllers addObject:ChatView];
                
                //[[[AppManager app] NavRouter].AppMainNavigationView popToViewController:ChatView animated:YES];
                
                //[self CloseChatViewWhenBackAction];
            }
        }
    }
    
    if(ChatSubViewControllers && [ChatSubViewControllers count])
    {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            float i = 0;
            
            while ([ChatSubViewControllers count])
            {
                UIViewController *Controller = [ChatSubViewControllers lastObject];
                
                i += 0.3;
                
                dispatch_time_t PopTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * NSEC_PER_SEC));
                
                dispatch_after(PopTime,dispatch_get_main_queue(), ^{
                    
                    if([Controller isKindOfClass:[UiChatTitleSettingsView class]])
                    {
                        [self CloseChatTitleSettings:NO];
                    }
                    
                    if([Controller isKindOfClass:[UiChatUsersSelectView class]])
                    {
                        [self CloseChatUsersSelectViewWhenBackAction:NO];
                    }
                    
                    
                    if([Controller isKindOfClass:[UiChatUsersView class]])
                    {
                        [self CloseChatUsersViewWhenBackAction:NO];
                    }
                    
                    
                    if([Controller isKindOfClass:[UiChatSettingsView class]])
                    {
                        [self CloseChatSettingsWhenBackAction:NO];
                    }
                    
                    if([Controller isKindOfClass:[UiChatMakeConferenceView class]])
                    {
                        [self CloseChatMakeConference:NO];
                    }
                    
                    if([Controller isKindOfClass:[ProfileView class]])
                    {
                        [self CloseProfile:NO];
                    }
                    
                    if([Controller isKindOfClass:[UiChatView class]])
                    {
                        if([ChatSubViewControllers count] == 1)
                        {
                            [self CloseChatViewWhenBackAction];
                        }
                        else
                        {
                            [self CloseChatViewWhenBackAction:NO];
                        }
                        
                        
                    }
                    
                });
                
                [ChatSubViewControllers removeLastObject];
            }
            
        });
    }
}

+ (void) CloseChatViewWhenBackAction:(BOOL) Animated WithCallback:(void (^)()) Callback
{
    [CATransaction begin];
    [CATransaction setCompletionBlock:Callback];
    
    [self CloseChatViewWhenBackAction:Animated];
    
    [CATransaction commit];
}

+ (void) CloseChatViewWhenBackAction
{
    [self CloseChatViewWhenBackAction:YES];
}

+ (void) CloseChatUsersViewWhenBackAction:(BOOL) Animated
{
    
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Chat users view back action -> show chats list"];
    
    [ChatUsersView.navigationController popViewControllerAnimated:Animated];
    
    ChatUsersView = nil;
    
    //Try to find previous chat user view
    UiChatUsersView *PreviousChatUsersView;
    
    NSArray *NavViewControllers = [[AppManager app] NavRouter].AppMainNavigationView.viewControllers;
    
    for(UIViewController *Controller in NavViewControllers) {
        if([Controller isKindOfClass:[UiChatUsersView class]])
            PreviousChatUsersView = (UiChatUsersView *)Controller;
    }
    
    if(PreviousChatUsersView)
        ChatUsersView = PreviousChatUsersView;
}

+ (void) CloseChatUsersViewWhenBackAction
{
    [self CloseChatUsersViewWhenBackAction:YES];
}

+ (void) CloseChatUsersViewWithCallback: (void (^)()) Callback {
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:Callback];
    [self CloseChatUsersViewWhenBackAction];
    [CATransaction commit];
}

+ (void) CloseChatUsersSelectViewWhenBackAction:(BOOL) Animated
{
    
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Chat users select view back action -> show chats users view"];
    
    [ChatUsersView.navigationController popViewControllerAnimated:Animated];
    
    ChatUsersSelectView = nil;
}

+ (void) CloseChatUsersSelectViewWhenBackAction
{
    
    [self CloseChatUsersSelectViewWhenBackAction:YES];
}

+ (void) ShowChatCreateErrorAlert {
    [UiLogger WriteLogInfo: @"UiChatsTabNavRouter: Chat not created alert"];
    
    UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
    
    
    Alert.title = NSLocalizedString(@"ChatCreationError", nil);
    
    UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         
                                                     }];
    
    [Alert addAction:OkAction];
    
    [[UiNavRouter NavRouter].AppMainNavigationView presentViewController:Alert animated:YES completion:nil];
}

+ (void) ShowChatSettings {
    [UiLogger WriteLogInfo: @"UiChatsTabNavRouter: Chat settings"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiChatsTabPageView" bundle:nil];
    
    UiChatSettingsView *settingsView = [storyboard instantiateViewControllerWithIdentifier:@"UiChatSettingsView"];
    
    settingsView.ViewModel.ChatData = [ChatsManager CopyChat:ChatView.ViewModel.ChatData];
    
    [ChatView.navigationController pushViewController:settingsView animated:YES];
    
    //[[UiNavRouter NavRouter].AppMainNavigationView setNavigationBarHidden:NO animated:YES];
}

+ (void)CloseChatSettingsWhenBackAction:(BOOL) Animated
{
    
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Chat setings back action -> show chat"];
    
    [ChatView.navigationController popViewControllerAnimated:Animated];
}

+ (void)CloseChatSettingsWhenBackAction
{
    
    [self CloseChatSettingsWhenBackAction:YES];
}

+ (void) ShowChatUserSettingsForChat:(ObjC_ChatModel *)ChatModel {
    
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show chat users settings"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiChatsTabPageView" bundle:nil];
    
    ChatUsersView = [storyboard instantiateViewControllerWithIdentifier:@"UiChatUsersView"];
    ChatUsersView.ViewModel.ChatData = [ChatsManager CopyChat:ChatModel];
    
    [ChatView.navigationController pushViewController:ChatUsersView animated:YES];
}

+ (void) ShowContactProfileForContact:(ObjC_ContactModel *)Contact {
    
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show contact profile"];
    
    [UiLogger WriteLogDebug:[NSString stringWithFormat:@"ContactModel: %@", [CoreHelper ContactModelDescription:Contact]]];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiContactsTabPage" bundle:nil];
    ProfileView = (UiContactProfileView *)[storyboard instantiateViewControllerWithIdentifier:@"UiContactProfileView"];
    ProfileView.ViewModel.ContactData = Contact;
    
    ProfileView.CallbackOnBackAction = ^ {
        [UiChatsTabNavRouter CloseProfile];
    };
    
    [ChatUsersView.navigationController pushViewController:ProfileView animated:YES];
}

+ (void) CloseProfile:(BOOL) Animated
{
    [ProfileView.navigationController popViewControllerAnimated:Animated];
    ProfileView = nil;
    
    //Try to find previous chat profileview
    UiContactProfileView *PreviousChatUsersView;
    
    NSArray *NavViewControllers = [[AppManager app] NavRouter].AppMainNavigationView.viewControllers;
    
    for(UIViewController *Controller in NavViewControllers) {
        if([Controller isKindOfClass:[UiContactProfileView class]])
            PreviousChatUsersView = (UiContactProfileView *)Controller;
    }
    
    if(PreviousChatUsersView)
        ProfileView = PreviousChatUsersView;

}

+ (void) CloseProfile
{
    [self CloseProfile:YES];
}

+ (void) ShowChatTitleSettingsForChat:(ObjC_ChatModel *)ChatModel {
    
    
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show chat title settings"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiChatsTabPageView" bundle:nil];
    
    UiChatTitleSettingsView *titleSettingsView = [storyboard instantiateViewControllerWithIdentifier:@"UiChatTitleSettingsView"];
    titleSettingsView.ViewModel.ChatModel = ChatModel;
    
    [ChatView.navigationController pushViewController:titleSettingsView animated:YES];
}

+ (void) CloseChatTitleSettings:(BOOL) Animated
{
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Chat title setings back action -> show chat settings"];
    
    [ChatView.navigationController popViewControllerAnimated:Animated];
}

+ (void) CloseChatTitleSettings
{
    [self CloseChatTitleSettings:YES];
}

+ (void) ShowChatMakeConferenceForChat:(ObjC_ChatModel *)ChatModel;
{
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show chat make conference view"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiChatsTabPageView" bundle:nil];
    
    ChatMakeConferenceView = [storyboard instantiateViewControllerWithIdentifier:@"UiChatMakeConferenceView"];
    ChatMakeConferenceView.ViewModel.ChatData = [ChatsManager CopyChat:ChatModel];
    
    [ChatView.navigationController pushViewController:ChatMakeConferenceView animated:YES];
}

+ (void) CloseChatMakeConference:(BOOL) Animated
{
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Close chat make conference view"];
    
    [ChatView.navigationController popViewControllerAnimated:Animated];
    
    ChatMakeConferenceView = nil;
}

+ (void) CloseChatMakeConference
{
    [self CloseChatMakeConference:YES];
}

+ (void) ShowEditMessageViewForMessage:(ObjC_ChatMessageModel *)ChatMessageModel
{

    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Show chat message edit view"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UiChatsTabPageView" bundle:nil];
    
    UiChatMessageEditView *ChatMessageEditView = [storyboard instantiateViewControllerWithIdentifier:@"UiChatMessageEditView"];
    ChatMessageEditView.ViewModel.ChatMessageModel = ChatMessageModel;
    
    [ChatView.navigationController pushViewController:ChatMessageEditView animated:YES];
}

+ (void) CloseEditMessageView:(BOOL) Animated
{
    [UiLogger WriteLogInfo:@"UiChatsTabNavRouter: Chat message edit back action -> show chat view"];
    
    [ChatView.navigationController popViewControllerAnimated:Animated];
}

+ (void) CloseEditMessageView
{
    [self CloseEditMessageView:YES];
}
@end
