//
//  UiCurrentConferenceViewModel.m
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

#import "UiCurrentConferenceViewModel.h"

#import "CallsManager.h"
#import "AudioManager.h"
#import "ContactsManager.h"

#import "UiCallsNavRouter.h"


@implementation UiCurrentConferenceViewModel

- (instancetype)init {
    if(self = [super init]) {
        
        self.UsersArray = [NSMutableArray new];
        self.ConferenceDuration = 0;
        self.IsMicEnabled = @(YES);
        self.ConferenceTitle = @"";
        
        [[AudioManager Manager] CheckMicrophone];
        [[AudioManager Manager] CheckMicrophonePermissions:YES];
        
        [self BindAll];
    }
    
    return self;
}

- (void) BindAll {
    
    RAC(self, IsMicEnabled) = [RACObserve([AudioManager Manager], MicrophoneEnabled) ignore:nil];
    
    RACSignal *ConferenceDurationSignal = [RACSignal interval:1.0 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh]];
    
    @weakify(self);
    
    [ConferenceDurationSignal subscribeNext:^(id x) {
        @strongify(self);
        self.ConferenceDuration+=1;
    }];

    
    [RACObserve(self, ConferenceModel) subscribeNext:^(id x) {
        @strongify(self);
        [self UpdateData];
    }];
    
    
    
    self.DropCall = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        //TODO: CREATE DROP_CONFERENCE_SIGNAL
        return [CallsManager DropCallSignal:self.ConferenceModel.Id];
    }];
    
    self.SwitchMic = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteSwitchMic];
    }];
    
    self.ShowComingSoon = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        return [self ExecuteShowComingSoon];
    }];
    
    
}

- (void) UpdateData {
    
    //TODO: CHECK VALUE
    self.ConferenceTitle = @"COOL CONFERENCE";
    self.ChatId = self.ConferenceModel.ChatId;
    
    NSMutableArray *NewUsersArray = [NSMutableArray new];
    
    for(ObjC_CallModel *Call in self.ConferenceModel.Calls) {
        
        UiCurrentConferenceUserCellModel *CellModel = [UiCurrentConferenceUserCellModel new];
    
        CellModel.Name = [ContactsManager GetContactTitle:Call.Contact];
        CellModel.IsActive = Call.State == CallStateConversation? @(YES) : @(NO);
        
        if(Call.Contact && Call.Contact.DodicallId && Call.Contact.DodicallId.length)
            CellModel.IsDodicall = @(YES);
        else
            CellModel.IsDodicall = @(NO);
        
        if(Call.Encription != CallEncryptionNone)
            CellModel.IsEncrypted  = @(YES);
        else
            CellModel.IsEncrypted = @(NO);
        
        [NewUsersArray addObject:CellModel];
    }
    
    self.UsersArray = NewUsersArray;
}



-(RACSignal *)ExecuteShowComingSoon {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [UiCallsNavRouter ShowComingSoon];
        [subscriber sendCompleted];
        
        return [RACDisposable new];
    }];
}

- (RACSignal *)ExecuteSwitchMic {
    
    return [RACSignal startLazilyWithScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh] block:^(id<RACSubscriber> subscriber) {
        
        [[AudioManager Manager] SwitchMicrophone];
        
        if(![[AudioManager Manager].MicrophonePermited boolValue])
        {
            [UiCallsNavRouter ShowMicrophoneDisabledInfo];
        }
        
        [subscriber sendCompleted];
    }];
    
}
@end
