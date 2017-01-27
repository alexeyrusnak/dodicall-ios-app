//
//  UiContactsListModel.h
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
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UiContactsSkeleton.h"

#define UiContactsListSectionsIndexRU                  @"А,Б,В,Г,Д,Е,Ё,Ж,З,И,Й,К,Л,М,Н,О,П,Р,С,Т,У,Ф,Х,Ц,Ч,Ш,Щ,Ъ,Ы,Ь,Э,Ю,Я"
#define UiContactsListSectionsIndexEN                  @"A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z"
#define UiContactsListSectionsIndexDefault             @"A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z"
#define UiContactsListSectionsIndexAll                 @"#"

#define UiContactsListSectionsIndexTranslitRUEN        @{@"А":@"A",@"Б":@"B",@"В":@"V",@"Г":@"G",@"Д":@"D",@"Е":@"E",@"Ё":@"E",@"Ж":@"Z",@"З":@"Z",@"И":@"I",@"Й":@"Y",@"К":@"K",@"Л":@"L",@"М":@"M",@"Н":@"N",@"О":@"O",@"П":@"P",@"Р":@"R",@"С":@"S",@"Т":@"T",@"У":@"U",@"Ф":@"F",@"Х":@"K",@"Ц":@"T",@"Ч":@"C",@"Ш":@"S",@"Щ":@"S",@"Ъ":@"#",@"Ы":@"#",@"Ь":@"#",@"Э":@"E",@"Ю":@"Y",@"Я":@"Y"}



@class ObjC_ContactModel;
@class ObjC_ContactsContactModel;

@class UiContactsListRowItemModel;

@interface UiContactsListModel : NSObject

@property NSMutableArray *Data;

@property NSMutableArray *DataUpdateStages;

@property NSMutableDictionary *Sections;

@property NSMutableDictionary *ThreadSafeSections;

@property NSMutableArray *SectionsKeys;

@property NSMutableArray *ThreadSafeSectionsKeys;

@property NSNumber *DataReloaded;

@property RACSignal *DataReloadedSignal;

@property NSString *SearchText;

@property (nonatomic, assign) ObjC_ContactModel *TempContactData;

@property UiContactsFilter Filter;

@property NSMutableArray *DisposableRacArr;

@property UiContactsListMode Mode;

@property NSMutableArray<ObjC_ContactModel *> *SelectedContacts;

@property NSMutableArray<ObjC_ContactModel *> *DisabledContacts;

@property NSNumber *SelectedContactsCount;

@property NSNumber *SelectionBlocked;

//@property RACSignal *XmppStatusesSignal;

- (void) SetSearchTextFilter:(NSString *)Search;

- (void) SetFilter:(UiContactsFilter) Filter;

- (void) SetMode:(UiContactsListMode) Mode;

- (void) RevertSelected:(UiContactsListRowItemModel *) RowModel;

- (void) ExecuteSaveAction:(ObjC_ContactModel *)ContactData withCallback:(void (^)(BOOL))Callback;

- (void) ExecuteTransferCallAction:(NSString *) ContactIdentity withCallback:(void (^)(BOOL))Callback;

- (NSInteger) FindNearestNotEmptySectionIndex:(NSInteger) SectionIndex;

@end
