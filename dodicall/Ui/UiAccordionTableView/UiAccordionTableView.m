//
//  UiAccordionTableView.m
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

#import "UiAccordionTableView.h"

static NSString *SectionHeaderViewIdentifier = @"UiAccordionTableSectionHeaderView";

@interface UiAccordionTableView ()

@property (nonatomic) IBOutlet UiAccordionTableSectionHeaderView *sectionHeaderView;

@property (nonatomic) NSMutableArray *sectionInfoArray;
@property (nonatomic) NSIndexPath *pinchedIndexPath;
@property (nonatomic) NSInteger openSectionIndex;
@property (nonatomic) CGFloat initialPinchHeight;

@property BOOL IsDataPrepared;

@end

@implementation UiAccordionTableView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    
    NSLog(@"My object value %@", coder);
    self = [super initWithCoder:coder];
    if (self) {
        
        self.AccordionTableViewModel =  [[UiAccordionTableViewModel alloc] init];
        
        self.openSectionIndex = NSNotFound;
        
        

        
    }
    return self;
}

- (void)PrepareData
{
    
    for (int section = 0; section < [self numberOfSectionsInTableView:self.tableView]; section++)
    {
        UiAccordionTableSectionHeaderViewModel *SectionHeaderViewModel = [[UiAccordionTableSectionHeaderViewModel alloc] init];
        
        NSString *SectionTitle = [self.tableView.dataSource tableView:self.tableView titleForHeaderInSection:section];
        
        
        if(SectionTitle)
            SectionHeaderViewModel.Title = SectionTitle;
        else
            SectionHeaderViewModel.Title = @"";
        
        
        SectionHeaderViewModel.NumOfRows = [self.tableView numberOfRowsInSection:section];
        
        [self.AccordionTableViewModel.SectionsModelsArray addObject:SectionHeaderViewModel];
    }
    
    self.IsDataPrepared = TRUE;
    
    
    /*
    Class class = [self class];
    
    SEL originalSelector = @selector(tableView:numberOfRowsInSection:);
    SEL swizzledSelector = @selector(tableView:numberOfRowsInSectionAlt:);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        
        //method_exchangeImplementations(originalMethod, swizzledMethod);
        
        method_setImplementation(originalMethod, method_getImplementation(swizzledMethod));
        
        //IMP imp1 = method_getImplementation(m1);
        //IMP imp2 = method_getImplementation(m2);
        //method_setImplementation(m1, imp2);
        //method_setImplementation(m2, imp1);
    }
     */
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self PrepareData];
    
    UINib *sectionHeaderNib = [UINib nibWithNibName:@"UiAccordionTableSectionHeaderView" bundle:nil];
    [self.tableView registerNib:sectionHeaderNib forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(self.IsDataPrepared)
    {
        return [self tableView: tableView numberOfRowsInSectionAlt:section];
    }
    else
    {
        return [self tableView: tableView numberOfRowsInSectionDynamicData:section];
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSectionDynamicData:(NSInteger)section {
    
    return [super tableView: tableView numberOfRowsInSection:section];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSectionAlt:(NSInteger)section {

    UiAccordionTableSectionHeaderViewModel *SectionHeaderViewModel = (self.AccordionTableViewModel.SectionsModelsArray)[section];
    
    if(SectionHeaderViewModel.Open)
    {
        return SectionHeaderViewModel.NumOfRows;
    }
    
    return 0;
    
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
    
    UiAccordionTableSectionHeaderView *SectionHeaderView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderViewIdentifier];
    
    SectionHeaderView.ViewModel = [self.AccordionTableViewModel.SectionsModelsArray objectAtIndex:section];
    
    SectionHeaderView.titleLabel.text = sectionTitle;
    SectionHeaderView.section = section;
    SectionHeaderView.delegate = self;
    
    return SectionHeaderView;
}

#pragma mark - SectionHeaderViewDelegate

- (void)sectionHeaderView:(UiAccordionTableSectionHeaderView *)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
    
    UiAccordionTableSectionHeaderViewModel *sectionInfo = (self.AccordionTableViewModel.SectionsModelsArray)[sectionOpened];
    
    sectionInfo.headerView = sectionHeaderView;
    
    sectionInfo.Open = YES;
    
    /*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSInteger countOfRowsToInsert = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:sectionOpened];
    
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < countOfRowsToInsert; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
    }
    
    /*
     Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    
    
    NSInteger previousOpenSectionIndex = self.openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {
        
        UiAccordionTableSectionHeaderViewModel *previousOpenSection = (self.AccordionTableViewModel.SectionsModelsArray)[previousOpenSectionIndex];
        
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        NSInteger countOfRowsToDelete = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:previousOpenSectionIndex];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
        
        previousOpenSection.Open = NO;
    }
    
    // style the animation so that there's a smooth flow in either direction
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    }
    else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }
    
    // apply the updates
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [self.tableView endUpdates];
    
    self.openSectionIndex = sectionOpened;
}


- (void)sectionHeaderView:(UiAccordionTableSectionHeaderViewModel *)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
    
    /*
     Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
     */
    
    UiAccordionTableSectionHeaderViewModel *sectionInfo = (self.AccordionTableViewModel.SectionsModelsArray)[sectionClosed];
    
    sectionInfo.Open = NO;
    NSInteger countOfRowsToDelete = [self.tableView numberOfRowsInSection:sectionClosed];
    
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    }
    self.openSectionIndex = NSNotFound;
}


@end
