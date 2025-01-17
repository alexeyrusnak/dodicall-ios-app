//
//  UiChatsTabNavRouter.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define UiChatsTabNavRouterSegueShowChatsList           @"UiChatsTabNavRouterSegueShowChatsList"
#define UiChatsTabNavRouterSegueShowChat                @"UiChatsTabNavRouterSegueShowChat"
#define UiChatsTabNavRouterSegueShowChatUsers           @"UiChatsTabNavRouterSegueShowChatUsers"
#define UiChatsTabNavRouterSegueShowChatSelectUsers     @"UiChatsTabNavRouterSegueShowChatSelectUsers"
typedef NSString*                               UiChatsTabNavRouterSegue;

@class ObjC_ChatModel;

@class ObjC_ContactModel;

@class ObjC_ChatMessageModel;

@interface UiChatsTabNavRouter : NSObject

+ (void) Reset;

+ (void)PrepareForSegue:(UIStoryboardSegue *)Segue sender:(id)Sender chatModel:(ObjC_ChatModel *) ContactModel;

+ (void) ShowChatView:(ObjC_ChatModel *) ChatModel;

+ (void) ShowChatViewByChatIdOrWaitChat:(NSString *) ChatId;

+ (void) CreateAndShowChatViewWithContact:(ObjC_ContactModel *) ContactModel;

+ (void) CloseChatViewWhenBackAction;

+ (void) CloseChatUsersViewWhenBackAction;

+ (void) CloseChatViewAndAllChatSubviewsWithChatId:(NSString *) ChatId;

+ (void) CloseChatUsersViewWithCallback: (void (^)()) Callback;

+ (void) CloseChatUsersSelectViewWhenBackAction;

+ (void) ShowChatCreateErrorAlert;

+ (void) ShowChatSettings;

+ (void) CloseChatSettingsWhenBackAction;

+ (void) ShowChatUserSettingsForChat:(ObjC_ChatModel *)ChatModel;

+ (void) ShowContactProfileForContact:(ObjC_ContactModel *)Contact;

+ (void) ShowChatTitleSettingsForChat:(ObjC_ChatModel *)ChatModel;

+ (void) CloseChatTitleSettings;

+ (void) ShowChatMakeConferenceForChat:(ObjC_ChatModel *)ChatModel;

+ (void) CloseChatMakeConference;

+ (void) ShowEditMessageViewForMessage:(ObjC_ChatMessageModel *)ChatMessageModel;

+ (void) CloseEditMessageView;
    

@end
