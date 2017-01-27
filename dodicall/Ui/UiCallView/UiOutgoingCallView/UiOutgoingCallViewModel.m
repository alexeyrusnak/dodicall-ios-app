//
//  UiOutgoingCallViewModel.m
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

#import "UiOutgoingCallViewModel.h"
#import "UiCallsNavRouter.h"
#import "CallsManager.h"
#import "UiLogger.h"
#import "ContactsManager.h"

@interface UiOutgoingCallViewModel() {
    BOOL _IsBinded;
}
@end

@implementation UiOutgoingCallViewModel

- (instancetype)init {
    
    self = [super init];
    
    if(self) {
        _IsBinded = NO;
        
        self.IsSmallDevice = @([[AppManager Manager].Device IsSmallDevice]);
        [self BindAll];
    }
    return self;
    
    
}
- (void)BindAll {
    if(_IsBinded)
        return;
    
    @weakify(self);
    
    self.ShowComingSoon = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteShowComingSoon];
    }];
    
    self.DropCall = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [[CallsManager DropCallSignal:self.CallModel.Id] deliverOnMainThread];
    }];
    
    self.HideView = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteHideView];
    }];
    
    RACSignal *CallSignal =
    [[RACObserve(self, CallModel)
        ignore:nil]
        throttle:0.3 afterAllowing:2];
    
    RACSignal *ContactSignal =
    [[CallSignal
        map:^id(ObjC_CallModel *Call) {
            return Call.Contact;
        }]
        ignore:nil];
    
     [CallSignal subscribeNext:^(ObjC_CallModel *call) {
        @strongify(self);
        BOOL Dodicall = NO;
        BOOL ChatAllowed = NO;
        NSString *Name = [call.Identity componentsSeparatedByString:@"@"][0];
        
        if(call.Contact)
        {
            Name = [ContactsManager GetContactTitle:call.Contact];
            
            if(call.Contact.DodicallId && call.Contact.DodicallId.length)
                Dodicall = YES;
            
            ContactProfileType ContactType = [ContactsManager GetContactProfileType:call.Contact];
            
            if(ContactType == ContactProfileTypeDirectoryLocal)
            {
                if(![ContactsManager CheckContactIsRequest:call.Contact])
                    ChatAllowed = YES;
            }
        }
        
        self.Name = Name;
        self.Dodicall = @(Dodicall);
        self.MobileCall = call.AddressType == CallAddressPhone? @(YES) : @(NO);
        self.ChatAllowed = @(ChatAllowed);
     }];
    
    RAC(self, AvatarPath) = [[ContactsManager Manager] AvatarSignalForContactUpdate:ContactSignal WithDoNextBlock:^(NSString *Path) {
        @strongify(self);
        self.AvatarPath = Path;
    }];
    
    _IsBinded = YES;
}

- (RACSignal *)ExecuteShowComingSoon {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [UiCallsNavRouter ShowComingSoon];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}

- (RACSignal *)ExecuteHideView {
    
    return [RACSignal startLazilyWithScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh] block:^(id<RACSubscriber> subscriber) {
        
        [UiCallsNavRouter HideCallView];
        
        [subscriber sendCompleted];
    }];
    
}
@end
