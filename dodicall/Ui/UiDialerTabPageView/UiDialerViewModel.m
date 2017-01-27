//
//  UiDialerViewModel.m
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

#import "UiDialerViewModel.h"
#import "AppManager.h"
#import "CallsManager.h"
#import "ContactsManager.h"

@interface UiDialerViewModel()

@property NSTimer *Delayer;

@end

@implementation UiDialerViewModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.IsSmallDevice = [[AppManager app].Device IsSmallDevice];
        
        self.InputText = [NSString new];
        self.InfoText = [NSAttributedString new];
        
        @weakify(self);
        
        [[RACObserve(self, InputText) distinctUntilChanged] subscribeNext:^(NSString *Text) {
           
            @strongify(self);
            
            [self.Delayer invalidate], self.Delayer = nil;
            
            self.Delayer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                             target:self
                                                           selector:@selector(ResolveContactName:)
                                                           userInfo:nil
                                                            repeats:NO];
            
        }];
        
        
        
    }
    
    return self;
}

- (void) AddCharacterToNumber:(NSString *)Character
{
    self.InputText = [self.InputText stringByAppendingString:Character];
}

- (void) DeleteLastCharacterFromNumber
{
    self.InputText = [self.InputText substringToIndex:self.InputText.length-(self.InputText.length>0)];
}

- (void) ReplaceLastCharacterInNumberWith:(NSString *)Character
{
    [self DeleteLastCharacterFromNumber];
    
    [self AddCharacterToNumber:Character];
}

- (void) ClearNumber
{
    self.InputText = @"";
}


- (void) StartCall
{
    if(self.InputText && self.InputText.length > 0) {
        [CallsManager StartOutgoingCallToNumber:self.InputText WithCallback:^(BOOL Result) {
            if(Result)
                [self ClearNumber];
        }];
    }
}

- (void) ResolveContactName:(NSTimer *)timer
{
    if(self.InputText.length < 3) {
        self.InfoText = nil;
        self.ResolvedContact = nil;
        return;
    }
    
    @weakify(self);
    
    NSString *WrittenNumber = [[self.InputText copy] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [ContactsManager RetriveContactByNumber:WrittenNumber AndReturnItInCallback:^(ObjC_ContactModel *Contact, NSString *Number) {
        
        @strongify(self);

        if(![WrittenNumber isEqualToString:[Number stringByReplacingOccurrencesOfString:@" " withString:@""]] || !Contact) {
            self.InfoText = nil;
            self.ResolvedContact = nil;
            return;
        }
        
        NSString *Title = [ContactsManager GetContactTitle:Contact];
        
        BOOL Found = NO;
        for(ObjC_ContactsContactModel *ContactsContact in [Contact Contacts]) {
            NSString *ContactNumber =[[[ContactsContact Identity] componentsSeparatedByString:@"@"][0] stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            if([ContactNumber isEqualToString:WrittenNumber]) {
                Found = YES;
                break;
            }
        }
        
        if(!Found || !Title || !Title.length) {
            self.InfoText = nil;
            self.ResolvedContact = nil;
            return;
        }
        
        

       if(Contact.DodicallId && Contact.DodicallId.length > 0) {
           //TODO: Move into NUI
           Title = [NSString stringWithFormat:@"<span style=\"font-family: 'ddcall'; color:#989898;\">\ue800</span><sup style=\"color:#989898;\">?</sup>&nbsp;&nbsp;&nbsp;d-sip&nbsp;&nbsp;&nbsp;%@",Title];
       }
        
        self.InfoText = [NSStringHelper PrepareHtmlFormatedString:Title WithNuiClass:@"UiDialerVieInfoLabel"];
        self.ResolvedContact = Contact;
        
    }];

    
}

- (void) PlayDtmf:(NSString *)Character
{
    [CallsManager PlayDtmf:Character];
}

- (void) StopDtmf
{
    [CallsManager StopDtmf];
}

@end
