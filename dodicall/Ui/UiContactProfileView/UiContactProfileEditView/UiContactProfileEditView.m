//
//  UiContactProfileEditView.m
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

#import "UiContactProfileEditView.h"
#import "AppManager.h"
#import "UiAlertControllerView.h"

#import "UiContactsTabNavRouter.h"
#import "ContactsManager.h"

@interface UiContactProfileEditView ()

@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@property (weak, nonatomic) IBOutlet UIButton *DoneButton;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarLogoMark;

@property (weak, nonatomic) IBOutlet UITextField *FirstNameTextField;

@property (weak, nonatomic) IBOutlet UITextField *LastNameTextField;

@property (weak, nonatomic) IBOutlet UITableView *ContactsTable;

@property (weak, nonatomic) IBOutlet UITableView *MenuTable;

@property (weak, nonatomic) IBOutlet UIView *ContacTypePickerView;

@property (weak, nonatomic) IBOutlet UIPickerView *ContacTypePicker;


@property (weak, nonatomic) IBOutlet UIScrollView *ScrollView;


@property (weak, nonatomic) IBOutlet UIButton *ContactTypePickerDoneButton;

@property (weak, nonatomic) IBOutlet UIImageView *AvatarImageView;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *ContactTypePickerOverlayViewTapGesture;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *ViewTapGesture;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ContactsTableHeightConstraint;


@property (nonatomic, assign) id _CurrentResponder;


@end

@implementation UiContactProfileEditView
{
    BOOL _IsAllBinded;
    
    bool shouldDisplayDropShape;
    float fadeAlpha;
    float trianglePlacement;
    
    CGPoint CurrentScrollViewOffset;
}

@synthesize MasterView;

@synthesize ViewModel;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.ViewModel = [[UiContactProfileEditViewModel alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self BindAll];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.ContactsTable setEditing:YES];
    
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.ContactsTable setEditing:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
   
    if(range.length + range.location > textField.text.length)
        return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if(textField == self.FirstNameTextField || textField == self.LastNameTextField)
        return newLength <= 40;

    
    if(textField.tag == 102)
        return newLength <= 20;
    
    return YES;
}

- (void) BindAll
{
    if(_IsAllBinded)
        return;
    
    @weakify(self);
    
    [[self.ViewModel.ContactDataSignal deliverOnMainThread] subscribeNext:^(ObjC_ContactModel *Data) {

        @strongify(self);
        
        [self SetViewsVisibility];
        
    }];
    
    
    RAC(self.FirstNameTextField,text) = [RACObserve(self.ViewModel, FirstNameTextFieldText) deliverOnMainThread];
    RAC(self.ViewModel, FirstNameTextFieldText) = self.FirstNameTextField.rac_textSignal;
    
    RAC(self.LastNameTextField,text) = [RACObserve(self.ViewModel, LastNameTextFieldText) deliverOnMainThread];
    RAC(self.ViewModel, LastNameTextFieldText) = self.LastNameTextField.rac_textSignal;
    
    RACSignal *ContactsTableSignal = RACObserve(self.ViewModel, ContactsTable);
    
    [[ContactsTableSignal deliverOnMainThread] subscribeNext:^(id x)
    {
        @strongify(self);
        
        [self.ContactsTable reloadData];
        
        [self AdjustContactsTableViewHeight];
        
    }];
    
    RACSignal *MenuTableSignal = RACObserve(self.ViewModel, MenuTable);
    
    [[MenuTableSignal deliverOnMainThread] subscribeNext:^(id x)
    {
        @strongify(self);
        
        [self.MenuTable reloadData];
        
    }];
    
    [[self.ContactTypePickerOverlayViewTapGesture rac_gestureSignal] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [self HideContacTypePickerView];
        
    }];
    
    [[self.ContactTypePickerDoneButton rac_signalForControlEvents: UIControlEventTouchUpInside] subscribeNext: ^(id value) {
        
        @strongify(self);
        
        [self HideContacTypePickerView];
        
    }];
    
    [[RACObserve(self.ViewModel, SavingProcessState) deliverOnMainThread] subscribeNext:^(NSNumber *Value) {
        
        @strongify(self);
        
        if([Value intValue] == UiContactProfileEditSavingStateStart)
            [[AppManager app].NavRouter ShowPageProcessWithView:self.view];
        
        if([Value intValue] == UiContactProfileEditSavingStateCompleteWithSuccess || [Value intValue] ==UiContactProfileEditSavingStateCompleteWithError)
            [[AppManager app].NavRouter HidePageProcessWithView:self.view];
        
        if([Value intValue] == UiContactProfileEditSavingStateCompleteWithSuccess)
           [self CompleteSaveActionWithSuccess:YES];
        
        if([Value intValue] == UiContactProfileEditSavingStateCompleteWithError)
            [self CompleteSaveActionWithSuccess:NO];
    }];
    
    
    [[[self.ViewModel.IsDataValidSignal
        combineLatestWith:RACObserve(self.ViewModel, DataChanged)]
        deliverOnMainThread]
        subscribeNext:^(RACTuple *Tuple) {
        
            @strongify(self);
            
            RACTupleUnpack(NSNumber *Valid, NSNumber *Changed) = Tuple;
            
            if([Changed boolValue]) {
                if([Valid boolValue])
                    [self.DoneButton setEnabled:YES];
                else
                    [self.DoneButton setEnabled:NO];
            }
            else
                [self.DoneButton setEnabled:NO];
            
            
            [self.DoneButton setNeedsDisplay];
        
        }];
    

    RAC(self.AvatarImageView, image) = [[ContactsManager AvatarImageSignalForPathSignal:RACObserve(self.ViewModel, AvatarPath) WithTakeUntil:[RACSignal never]] deliverOnMainThread];
    
    
    _IsAllBinded = TRUE;
}

- (IBAction)BackButtonAction:(id)sender {
    
    //[UiContactsTabNavRouter CloseProfileEditViewWhenBackAction];
    self.ViewModel.BackViewAction();
    
    /*
    if(self.ViewModel.ContactData.Id == 0 && self.ViewModel.ContactData.PhonebookId == nil &&  self.ViewModel.ContactData.DodicallId == nil)
        [self.MasterView.navigationController popViewControllerAnimated:TRUE];
    else
        [self.navigationController popViewControllerAnimated:TRUE];
     */
    
}

- (IBAction)DoneButtonAction:(id)sender {
    
    [self.DoneButton setEnabled:NO];
    [self.ViewModel ExecuteSaveAction];

}

- (void) CompleteSaveActionWithSuccess:(BOOL) Success
{
    [self.DoneButton setEnabled:YES];
    
    if(Success)
    {
        
        self.ViewModel.SaveViewAction();
        //[UiContactsTabNavRouter CloseProfileEditViewWhenSaveAction];
        
        /*
        if([NSStringFromClass([self.MasterView class]) isEqualToString:@"UiContactProfileView"])
        {
            [self.MasterView setValue:self.ViewModel.ContactData forKeyPath:@"ViewModel.ContactData"];
        }
        else
        {
            [[[self.navigationController viewControllers] objectAtIndex:0] setValue:self.ViewModel.ContactData forKeyPath:@"ViewModel.ContactData"];
        }
            
        
        [self.navigationController popViewControllerAnimated:TRUE];
         */
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ErrorAlert_ContactNotSaved", nil)
                                           message:nil
                                          delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [alert show];
    }
    
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(tableView == self.ContactsTable)
    {
        return [self.ViewModel.ContactsTable count];
    }
    
    else if(tableView == self.MenuTable)
        return [self.ViewModel.MenuTable count];
    
    else
        return 0;
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableView == self.ContactsTable)
    {
        NSString *CellIdentifier;
        
        UITableViewCell *cell;
        
        if(indexPath.row < [self.ViewModel.ContactsTable count] - 1)
        {
            CellIdentifier = @"UiContactProfileEditContactsTableCellView";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            UiContactProfileEditContactsTableCellViewModel *RowItem = (UiContactProfileEditContactsTableCellViewModel *)[self.ViewModel.ContactsTable objectAtIndex:indexPath.row];
            
            UIButton *TypeButtonLabel = (UIButton *)[cell viewWithTag:101];
            
            @weakify(self);

            
            
            UITextField *PhoneTextField = (UITextField *)[cell viewWithTag:102];
            
            PhoneTextField.text = RowItem.PhoneTextFieldText;
            
            /*
             
            DMC-2287 delayed
            
             [[RACObserve(RowItem, PhoneTextFieldText) takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(NSString* Value) {
                PhoneTextField.text = Value;
            }];
             */
            
            UIView *ErrorRedBorder = (UIView *)[cell viewWithTag:103];
            
            RAC(RowItem, PhoneTextFieldText) = [PhoneTextField.rac_textSignal takeUntil:cell.rac_prepareForReuseSignal];
            
            
            [[[RACObserve(RowItem, TypeLabelText) takeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(NSString* Value) {
                
                @strongify(self);
                
                [TypeButtonLabel setTitle:Value forState:UIControlStateNormal];
                
                [PhoneTextField setKeyboardType:[RowItem.TypeLabelValue intValue] == ContactsContactSip ? UIKeyboardTypeEmailAddress : UIKeyboardTypePhonePad];
                
                [PhoneTextField setPlaceholder:[RowItem.TypeLabelValue intValue] == ContactsContactSip ? NSLocalizedString(@"Title_SipNumber", nil) : NSLocalizedString(@"Title_PhoneNumber", nil)];
                
                [self.ViewModel ValidateAndFormatContactsTableCell:RowItem];
                
            }];
            
            [[[RACObserve(RowItem, IsValid) takeUntil:cell.rac_prepareForReuseSignal] deliverOnMainThread] subscribeNext:^(NSNumber* Value) {
                
                if(![Value boolValue])
                {
                    [ErrorRedBorder setAlpha:1.0];
                }
                else
                {
                    [ErrorRedBorder setAlpha:0.0];
                }
                
            }];
            @weakify(RowItem);
            [[[TypeButtonLabel rac_signalForControlEvents: UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal]subscribeNext: ^(id value) {
                
                @strongify(self);
                @strongify(RowItem);
                self.ViewModel.TypePickerCellModel = RowItem;
                [self.ContacTypePicker selectRow:[RowItem.TypeLabelPickerRow integerValue] inComponent:0 animated:YES];
                [self ShowContacTypePickerView];
                
            }];
            

        }
        else
        {
            UiContactProfileEditMenuTableCellViewModel *RowItem = (UiContactProfileEditMenuTableCellViewModel *)[self.ViewModel.ContactsTable objectAtIndex:indexPath.row];
            
            CellIdentifier = RowItem.CellIdenty;
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            UILabel *TitleLabel = (UILabel *)[cell viewWithTag:101];
            TitleLabel.text = RowItem.TitleLabelText;
            
        }
        
        return cell;
        
    }
    
    if(tableView == self.MenuTable)
    {
        UiContactProfileEditMenuTableCellViewModel *RowItem = (UiContactProfileEditMenuTableCellViewModel *)[self.ViewModel.MenuTable objectAtIndex:indexPath.row];
        
        NSString *CellIdentifier = RowItem.CellIdenty;
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        UILabel *TitleLabel = (UILabel *)[cell viewWithTag:101];
        TitleLabel.text = RowItem.TitleLabelText;
        
        return cell;
    }
    
    return nil;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(tableView == self.ContactsTable)
    {
        if(indexPath.row == [self.ViewModel.ContactsTable count] - 1)
        {
            NSInteger InsertedRow = [self.ViewModel AddEmptyContact];
            
            UITableViewRowAnimation InsertAnimation = UITableViewRowAnimationTop;
            
            NSMutableArray *IndexPathsToInsert = [[NSMutableArray alloc] init];
            [IndexPathsToInsert addObject:[NSIndexPath indexPathForRow:InsertedRow inSection:0]];
            
            // Apply the updates
            //[CATransaction begin];
            [self AdjustContactsTableViewHeight:YES];
            [tableView beginUpdates];
            /*
            [CATransaction setCompletionBlock: ^{
                
                
                
            }];
             */
            [tableView insertRowsAtIndexPaths:IndexPathsToInsert withRowAnimation:InsertAnimation];
            [tableView endUpdates];
            //[CATransaction commit];
            
        }
    }
    
    if(tableView == self.MenuTable)
    {
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if([cell.reuseIdentifier isEqualToString:@"UiContactProfileEditMenuTableBlockContactCell"])
        {
            UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleActionSheet];
            
            NSString *BlockActionTitle;
            
            if(![self.ViewModel.IsBlocked boolValue])
                BlockActionTitle = NSLocalizedString(@"Title_Block", nil);
            else
                BlockActionTitle = NSLocalizedString(@"Title_UnBlock", nil);
            
            
            UIAlertAction* BlockAction = [UIAlertAction actionWithTitle:BlockActionTitle style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     
                                                                     
                                                                     [[[AppManager app] NavRouter] ShowPageProcess];
                                                                     
                                                                     self.ViewModel.ContactData.Blocked = [NSNumber numberWithBool:![self.ViewModel.IsBlocked boolValue]];
                                                                     
                                                                     if([self.ViewModel.ContactData.Blocked boolValue])
                                                                         self.ViewModel.ContactData.White = [NSNumber numberWithBool:NO];
                                                                     
                                                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                         
                                                                         ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:self.ViewModel.ContactData];
                                                                         
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             
                                                                             [[[AppManager app] NavRouter] HidePageProcess];
                                                                             
                                                                             if(ResultContact && ResultContact.Id > 0)
                                                                             {
                                                                                 
                                                                                 [UiContactsTabNavRouter CloseProfileEditViewWhenSaveAction];
                                                                                 
                                                                                 
                                                                             }
                                                                             else
                                                                             {
                                                                                 
                                                                                 UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                                                                                        message:nil
                                                                                                                                                 preferredStyle:UIAlertControllerStyleAlert];
                                                                                 
                                                                                 
                                                                                 if(!self.ViewModel.IsBlocked)
                                                                                     Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotBlocked", nil);
                                                                                 else
                                                                                     Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotUnBlocked", nil);
                                                                                 
                                                                                 UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                                                  handler:^(UIAlertAction * action) {}];
                                                                                 
                                                                                 [Alert addAction:OkAction];
                                                                                 
                                                                                 
                                                                                 [self presentViewController:Alert animated:YES completion:nil];
                                                                             }
                                                                             
                                                                             
                                                                         });
                                                                     });
                                                                     
                                                                     
                                                                 }];
            
            [alert addAction:BlockAction];
            
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            
            [alert addAction:cancelAction];
            
            
            UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
            popPresenter.sourceView = cell.contentView;
            popPresenter.sourceRect = cell.contentView.bounds;
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        else if([cell.reuseIdentifier isEqualToString:@"UiContactProfileEditMenuTableWhiteContactCell"])
        {
            UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleActionSheet];
            
            NSString *WhiteActionTitle;
            
            if(![self.ViewModel.IsWhite boolValue])
                WhiteActionTitle = NSLocalizedString(@"Title_Add", nil);
            else
                WhiteActionTitle = NSLocalizedString(@"Title_Delete", nil);
            
            
            UIAlertAction* WhiteAction = [UIAlertAction actionWithTitle:WhiteActionTitle style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    
                                                                    
                                                                    [[[AppManager app] NavRouter] ShowPageProcess];
                                                                    
                                                                    self.ViewModel.ContactData.White = [NSNumber numberWithBool:![self.ViewModel.IsWhite boolValue]];
                                                                    
                                                                    if([self.ViewModel.ContactData.White boolValue])
                                                                        self.ViewModel.ContactData.Blocked = [NSNumber numberWithBool:NO];
                                                                    
                                                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                        
                                                                        ObjC_ContactModel *ResultContact = [[AppManager app].Core SaveContact:self.ViewModel.ContactData];
                                                                        
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            
                                                                            [[[AppManager app] NavRouter] HidePageProcess];
                                                                            
                                                                            if(ResultContact && ResultContact.Id)
                                                                            {
                                                                                
                                                                                [UiContactsTabNavRouter CloseProfileEditViewWhenSaveAction];
                                                                                
                                                                                
                                                                            }
                                                                            else
                                                                            {
                                                                                
                                                                                UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                                                                                       message:nil
                                                                                                                                                preferredStyle:UIAlertControllerStyleAlert];
                                                                                
                                                                                
                                                                                if(!self.ViewModel.IsBlocked)
                                                                                    Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotAddedToWhite", nil);
                                                                                else
                                                                                    Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotRemovedFromWhite", nil);
                                                                                
                                                                                UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                                                 handler:^(UIAlertAction * action) {}];
                                                                                
                                                                                [Alert addAction:OkAction];
                                                                                
                                                                                
                                                                                [self presentViewController:Alert animated:YES completion:nil];
                                                                            }
                                                                            
                                                                            
                                                                        });
                                                                    });
                                                                    
                                                                    
                                                                }];
            
            [alert addAction:WhiteAction];
            
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            
            [alert addAction:cancelAction];
            
            
            UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
            popPresenter.sourceView = cell.contentView;
            popPresenter.sourceRect = cell.contentView.bounds;
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        else if([cell.reuseIdentifier isEqualToString:@"UiContactProfileEditMenuTableDeleteContactCell"])
        {

            UiAlertControllerView* alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];

            UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Delete", nil) style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                  

                                                                      
                                                                      [[[AppManager app] NavRouter] ShowPageProcess];
                                                                      
                                                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                          
                                                                          BOOL Result = [[AppManager app].Core DeleteContact:self.ViewModel.ContactData];
                                                                          
                                                                          
                                                                          
                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                              
                                                                              [[[AppManager app] NavRouter] HidePageProcess];
                                                                              
                                                                              if(Result)
                                                                              {
                                                                                  
                                                                                  //[self.navigationController.navigationController popViewControllerAnimated:TRUE];
                                                                                  [UiContactsTabNavRouter CloseProfileEditViewWhenDeleteAction];
                                                                                  
                                                                              }
                                                                              else
                                                                              {
                                                                                  
                                                                                  UiAlertControllerView* Alert = [UiAlertControllerView alertControllerWithTitle:nil
                                                                                                                                                         message:nil
                                                                                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                                                                                  
                                                                                  Alert.title = NSLocalizedString(@"ErrorAlert_ContactNotDeleted", nil);
                                                                                  
                                                                                  UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                                                   handler:^(UIAlertAction * action) {}];
                                                                                  
                                                                                  [Alert addAction:OkAction];
                                                                                  
                                                                                  
                                                                                  [self presentViewController:Alert animated:YES completion:nil];
                                                                              }

                                                                              
                                                                          });
                                                                      });
                                                                    
                                                                  
                                                                  }];
            
            [alert addAction:deleteAction];
            
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Title_Cancel", nil) style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            
            [alert addAction:cancelAction];
            

            UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
            popPresenter.sourceView = cell.contentView;
            popPresenter.sourceRect = cell.contentView.bounds;
            
            [self presentViewController:alert animated:YES completion:nil];

            
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Coming soon..."
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == self.ContactsTable)
    {
        if(indexPath.row < [self.ViewModel.ContactsTable count] - 1)
        {
            return UITableViewCellEditingStyleDelete;
        }
        else
        {
            return  UITableViewCellEditingStyleInsert;
        }
    }
    
    return UITableViewCellEditingStyleNone;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(tableView == self.ContactsTable)
    {
        
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Title_Delete", nil)  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            NSInteger RowToRemove = indexPath.row;
            
            if([self.ViewModel RemoveContact:RowToRemove])
            {
                UITableViewRowAnimation RemoveAnimation = UITableViewRowAnimationBottom;
                
                NSMutableArray *IndexPathsToRemove = [[NSMutableArray alloc] init];
                [IndexPathsToRemove addObject:[NSIndexPath indexPathForRow:RowToRemove inSection:0]];
                
                // Apply the updates
                //[CATransaction begin];
                [self AdjustContactsTableViewHeight:YES];
                [tableView beginUpdates];
                /*
                [CATransaction setCompletionBlock: ^{
                    
                    [self AdjustContactsTableViewHeight];
                    
                }];
                 */
                [tableView deleteRowsAtIndexPaths:IndexPathsToRemove withRowAnimation:RemoveAnimation];
                [tableView endUpdates];
                //[CATransaction commit];
                
                
                
            }
            
        }];
        
        // TODO: Add font and background color to NUIRenderer
        deleteAction.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:0.0 blue:30.0/255.0 alpha:1.0];
        
        return @[deleteAction];
    
    }
    
    return nil;
}

- (void) AdjustContactsTableViewHeight
{
    [self AdjustContactsTableViewHeight:NO];
}

- (void) AdjustContactsTableViewHeight:(BOOL) Animation
{
    
    float CellHeight = self.ContactsTable.rowHeight;
    
    self.ContactsTableHeightConstraint.constant = CellHeight * [self.ViewModel.ContactsTable count];

    float AnimationDuration = 0.3;
    
    if(!Animation)
        AnimationDuration = 0.0;
    
    [UIView animateWithDuration:AnimationDuration animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        float SizeOfContent = 0;
        int i;
        for (i = 0; i < [self.ScrollView.subviews count]; i++) {
            UIView *view =[self.ScrollView.subviews objectAtIndex:i];
            
            if([view class] != [UIImageView class] && !view.hidden)
                SizeOfContent += view.frame.size.height;
        }
        
        // Set content size for scroll view
        [self.ScrollView setContentSize:CGSizeMake(self.ScrollView.frame.size.width, SizeOfContent)];
        
        [self.ScrollView setNeedsDisplay];
        
    }];
    
}

#pragma mark UISearchBar delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    self._CurrentResponder = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    /*
    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]])
    {
        [self.ScrollView setContentOffset:CurrentScrollViewOffset animated:YES];
    }
     */
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self ResignOnTap:nil];
    
    return NO;
}

- (void)ResignOnTap:(id)iSender {
    
    [self._CurrentResponder resignFirstResponder];
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if(touch.view != self._CurrentResponder && touch.view.superview != self._CurrentResponder)
        [self ResignOnTap:nil];
    
    
    
    return NO;
}

#pragma mark Keyboard delegates

- (void)KeyboardWillShow:(NSNotification*)Notification {
    
    [self AdjustingHeightWhenKeyboard:TRUE withNotification:Notification];
}

- (void)KeyboardWillHide:(NSNotification*)Notification {
    
    [self AdjustingHeightWhenKeyboard:FALSE withNotification:Notification];
}

- (void)AdjustingHeightWhenKeyboard:(BOOL) Show withNotification:(NSNotification*)Notification  {
    
    
    NSDictionary *userInfo = Notification.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
    
    UITextField *textField = (UITextField *) self._CurrentResponder;
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        
        //self.view.frame = CGRectMake(0, 0, keyboardFrameEnd.size.width, keyboardFrameEnd.origin.y);
        
        
    } completion:^(BOOL finished) {

        if (Show && [textField.superview.superview isKindOfClass:[UITableViewCell class]])
        {
            
            CurrentScrollViewOffset = self.ScrollView.contentOffset;
            
            CGPoint TfPoint;
            CGRect TfBounds = [textField.superview.superview bounds];
            TfBounds = [textField convertRect:TfBounds toView:self.ScrollView];
            TfPoint = TfBounds.origin;
            TfPoint.x = 0;
            
            TfPoint.y = (TfPoint.y + TfBounds.size.height) - (self.ScrollView.bounds.size.height - keyboardFrameEnd.size.height);
            if(TfPoint.y < 0)
                TfPoint.y = 0;
            [self.ScrollView setContentOffset:TfPoint animated:YES];
        }
        
    }];
    
}

#pragma mark - Picker view delegates

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component

{
    
    return [self.ViewModel.TypePickerRows count];
    
}



- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component

{
    
    return self.ViewModel.TypePickerRows[row][@"title"];
    
}



- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component

{
    [self.ViewModel SetContactsTableCellTypeLabelText:self.ViewModel.TypePickerCellModel withType:[self.ViewModel.TypePickerRows[row][@"value"] intValue]];
    
}

#pragma mark Filter menu delegates

- (void) ShowContacTypePickerView {
    
    [self.ContacTypePickerView setAlpha:0.0f];
    self.ContacTypePickerView.hidden = NO;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.ContacTypePickerView setAlpha:1.0f];
                     }
                     completion:^(BOOL finished){
                     }];
    
    [UIView commitAnimations];
    
}

- (void) HideContacTypePickerView {
    
    [UIView animateWithDuration:0.3f
                          delay:0.05f
         usingSpringWithDamping:1.0
          initialSpringVelocity:4.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.ContacTypePickerView setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         self.ContacTypePickerView.hidden = YES;
                     }];
    
    [UIView commitAnimations];
    
}

- (void) ToggleContacTypePickerView {
    if(self.ContacTypePickerView.hidden) {
        [self ShowContacTypePickerView];
    } else {
        [self HideContacTypePickerView];
    }
}


- (void) SetViewsVisibility
{
    if(self.ViewModel.IsDirectoryLocalType || self.ViewModel.IsDirectoryRemoteType)
    {
        [self.FirstNameTextField setEnabled:NO];
        //[self.FirstNameTextField setAlpha:0.5];
        
        [self.LastNameTextField setEnabled:NO];
        //[self.LastNameTextField setAlpha:0.5];
        
        [self.AvatarLogoMark setAlpha:1.0];
    }
    else
    {
        [self.FirstNameTextField setEnabled:YES];
        //[self.FirstNameTextField setAlpha:1.0];
        
        [self.LastNameTextField setEnabled:YES];
        //[self.LastNameTextField setAlpha:1.0];
        
        [self.AvatarLogoMark setAlpha:0.0];
    }
    
}




@end
