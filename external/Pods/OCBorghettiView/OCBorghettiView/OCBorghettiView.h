#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class OCBorghettiView;

#pragma mark - OCBorghettiViewDelegate

@protocol OCBorghettiViewDelegate <NSObject>

@optional

/**
 Tells the delegate that a section view is about to be displayed.
 
 @param accordion An accordion-view object informing the delegate about the action.
 @param view The view of the section about to be displayed.
 @param title The title of the section about to be displayed.
 */
- (void)accordion:(OCBorghettiView *)accordion
   willSelectView:(UIView *)view
        withTitle:(NSString *)title;

/**
 Asks the delegate if the section view should be shown.
 
 @param accordion An accordion-view object informing the delegate about the action.
 @param view The view of the section about to be displayed.
 @param title The title of the section about to be displayed.
 */
- (BOOL)accordion:(OCBorghettiView *)accordion
 shouldSelectView:(UIView *)view
        withTitle:(NSString *)title;

/**
 Tells the delegate that the section view is now active.
 
 @param accordion An accordion-view object informing the delegate about the action.
 @param view The view of the section which is now active.
 @param title The title of the section which is now active.
 */
- (void)accordion:(OCBorghettiView *)accordion
    didSelectView:(UIView *)view
        withTitle:(NSString *)title;

@end

#pragma mark - OCBorghettiView Class

@interface OCBorghettiView : UIView

/**
 This method will add a section with a given title and view to the accordion.
 
 @param sectionTitle The section title
 @param sectionView The section view
 */
- (void)addSectionWithTitle:(NSString *)sectionTitle
                    andView:(id)sectionView;

/**
 Sets the active section.
 */
@property (nonatomic, assign) NSInteger activeSection;

/**
 Sets section header height.
 */
@property (nonatomic, assign) NSInteger headerHeight;

/**
 Sets section header font.
 */
@property (nonatomic, strong) UIFont *headerFont;

/**
 Sets section header font color.
 */
@property (nonatomic, strong) UIColor *headerTitleColor;

/**
 Sets section header background color.
 */
@property (nonatomic, strong) UIColor *headerColor;

/**
 Sets section header border color.
 
 @warning Section title border is not visible by default. Set a color to display it.
 */
@property (nonatomic, strong) UIColor *headerBorderColor;

/**
 Sets the delegate.
 
 @see OCBorghettiViewDelegate protocol
 */
@property (nonatomic, weak) id <OCBorghettiViewDelegate> delegate;

@end