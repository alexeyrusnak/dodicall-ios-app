@primaryFontName: AppleGothic;
@secondaryFontName: HelveticaNeue-Light;
@secondaryFontNameBold: HelveticaNeue;
@secondaryFontNameStrong: HelveticaNeue-Medium;
@inputFontName: HelveticaNeue;
@primaryFontColor: #555555;
@secondaryFontColor: #888888;
@primaryBackgroundColor: #E6E6E6;
@primaryBackgroundTintColor: #ECECEC;
@primaryBackgroundColorTop: #F3F3F3;
@primaryBackgroundColorBottom: #E6E6E6;
@primaryBackgroundColorBottomStrong: #DDDDDD;
@secondaryBackgroundColorTop: #FCFCFC;
@secondaryBackgroundColorBottom: #F9F9F9;
@primaryBorderColor: #A2A2A2;
@primaryBorderWidth: 1;

@fontName: HelveticaNeue;
@fontNameLight: HelveticaNeue-Light;
@fontNameMedium: HelveticaNeue-Medium;
@fontNameBold: HelveticaNeue-Bold;

@colorBlack:#000000;
@colorRed:#e6001e;
@colorRedOpavity07:#ed4c61;
@colorBrown:#313131;
@colorWhite:#FFFFFF;
@colorWhiteOpavity07:#b3b3b3;
@colorGreyLight:#d1d1d1;
@colorGreyBeforeLight:#cdcdcd;
@colorGreyInfraLight:#f7f7f7;
@colorGreyPlaceholder:#989898;
@colorGreyDark:#2b2b2b;
@colorGreyBeforeDark:#b4b3b3;
@colorGreyInfraDark:#8f8f8f;
@colorGreyLightDark:#929292;
@colorGrey:#7d7d7d;
@colorGreyMiddle:#515151;
@colorGreen:#00b300;
@colorYellow:#eeb706;
@colorForViewSplit:#d3d3d3;

@imageBgRed:#e6001e,64,49;
@imageBgYellow:#eeb706,64,49;

/*
BarButton {
    background-color: @primaryBackgroundColor;
    background-color-highlighted: #CCCCCC;
    border-color: @primaryBorderColor;
    border-width: @primaryBorderWidth;
    corner-radius: 7;
    font-name: @secondaryFontNameBold;
    font-color: @primaryFontColor;
    font-color-disabled: @secondaryFontColor;
    font-size: 13;
    text-shadow-color: clear;
}
Button {
    background-color-top: #FFFFFF;
    background-color-bottom: @primaryBackgroundColorBottom;
    border-color: @primaryBorderColor;
    border-width: @primaryBorderWidth;
    font-color: @primaryFontColor;
    font-color-highlighted: @secondaryFontColor;
    font-name: @secondaryFontName;
    font-size: 18;
    height: 37;
    corner-radius: 7;
    exclude-views: UIAlertButton;
    exclude-subviews: UITableViewCell,UITextField;
}

LargeButton {
    height: 50;
    font-size: 20;
    corner-radius: 10;
}
SmallButton {
    height: 24;
    font-size: 14;
    corner-radius: 5;
}
Label {
    font-name: @secondaryFontName;
    font-size: 20;
    font-color: @primaryFontColor;
    text-auto-fit: false;
}
LargeLabel {
    font-size: 24;
}
SmallLabel {
    font-size: 15;
}
*/
NavigationBar {
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorRed;
    text-shadow-color: clear;
    background-color:@colorYellow;
    background-color-highlighted: @colorYellow;
    bottom-shadow-color:@colorForViewSplit;
}

NavigationBarButton {
    font-color: @colorRed;
    font-color-highlighted: @colorGrey;
    font-color-disabled: @colorGrey;
    font-name: @fontName;
    font-size: 19;
    image-color:@colorRed;
    image-color-highlighted:@colorGrey;
    image-color-disabled:@colorGrey;
}
NavigationBarButtonTextOnly {
    font-color: @colorRed;
    font-color-highlighted: @colorGrey;
    font-color-disabled: @colorGrey;
    font-name: @fontName;
    font-size: 19;
}

ViewSplitBorder{
    border-color:@colorForViewSplit;
    border-width:13;
}
ErrorRedBorder{
    border-color:@colorRed;
    border-width:1;
}
SearchBar {
    background-color:@colorWhite;
    scope-background-color: @colorWhite;
    place-holder-text-color:@colorGreyLight;
    place-holder-font-name:@fontNameLight;
    place-holder-font-size:15;
    place-holder-icon-image-name:search;
}
SegmentedControl {
    background-color: @primaryBackgroundColorTop;
    background-color-selected: @primaryBackgroundColorBottomStrong;
    border-color: @primaryBorderColor;
    border-width: @primaryBorderWidth;
    corner-radius: 7;
    font-name: @secondaryFontNameBold;
    font-size: 13;
    font-color: @primaryFontColor;
    text-shadow-color: clear;
}
Switch {
    on-tint-color: @colorRed;
    tint-color: @colorGreyInfraLight;
}
Slider {
    minimum-track-tint-color: @colorRed;
    maximum-track-tint-color: @colorGreyInfraLight;
}
TabBar {
    background-color:@colorBrown;
    background-tint-color:@colorWhite;
    selection-indicator-image:@imageBgYellow;
}
TabBarItem {
    font-name: @fontName;
    font-color: #FFFFFF;
    font-size: 12;
    text-offset: 0,0;
    image-original:TRUE;
    selected-image-original:TRUE;
}
TableCell {
    background-color:@colorWhite;
    font-color: @colorBlack;
    font-name: @fontNameMedium;
    font-size: 17;
    background-color-selected:@colorGreyInfraLight;
}
TableCellDetail {
    font-name: @secondaryFontName;
    font-size: 14;
    font-color: @secondaryFontColor;
}
/*
TextField {
    height: 37;
    font-name: @inputFontName;
    font-size: 18;
    border-style: rounded;
    vertical-align: center;
}
*/
LargeTextField {
    height: 50;
    font-size: 28;
}
/*
View {
    background-color: #FFFFFF;
}
*/
/* UiContactsList */
UiContactsListView {
    section-index-color:@colorRed;
}
UiContactsListSectionHeaderView {
    background-color: #FFFFFF;
}
UiContactsListSectionHeaderViewLabel {
    font-name: @fontNameMedium;
    font-size: 15;
    font-color: @colorRed;
}
UiContactsListCellViewAvatarImageView
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:24;
}
UiContactsListCellViewHeaderLabel {
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorBlack;
}
UiContactsListCellViewDescrLabel {
    font-name: @fontName;
    font-size: 13;
    font-color: @colorGrey;
}
UiContactsListCellViewStatusIndicator {
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:6;
    corner-radius:3;
}

UiContactsListCellViewStatusIndicatorOFFLINE {
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:6;
    corner-radius:3;
}

UiContactsListCellViewStatusIndicatorONLINE {
    background-color:@colorGreen;
    border-color:@colorGreen;
    border-width:6;
    corner-radius:3;
}

UiContactsListCellViewStatusIndicatorDND {
    background-color:@colorYellow;
    border-color:@colorYellow;
    border-width:6;
    corner-radius:3;
}

UiContactsListCellViewStatusIndicatorAWAY {
    background-color:@colorYellow;
    border-color:@colorYellow;
    border-width:6;
    corner-radius:3;
}

UiContactsListCellViewStatusIndicatorINVISIBLE {
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:6;
    corner-radius:3;
}

UiButtonWithBadgeView {
    badge-bg-color: @colorRed;
    badge-text-color: @colorWhite;
    badge-font-name: @fontNameBold;
    badge-font-size: 11;
}

UiNavigationBarButtonWithDropDownView {
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
    text-shadow-color: clear;
    /*background-color:@colorYellow;*/
}

UiCheckListButtonView {
    font-name: @fontName;
    font-size: 19;
    font-color: @colorGreyDark;
    font-color-selected: @colorRed;
    text-shadow-color: clear;
    background-color:@colorWhite;
}

/* UiContactProfile */
UiContactProfileAvatarImageView
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:51;
}
UiContactProfilePersonName
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorGreyDark;
}
UiContactProfilePersonLastName
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorGreyDark;
}
UiContactProfileStatusPanel
{
    background-color:@colorGreyInfraLight;
}
UiContactProfileStatusIndicatorView
{
    background-color:@colorGrey;
    corner-radius:3;
}
UiContactProfileStatusIndicatorViewOFFLINE
{
    background-color:@colorGrey;
    corner-radius:3;
}
UiContactProfileStatusIndicatorViewONLINE
{
    background-color:@colorGreen;
    corner-radius:3;
}
UiContactProfileStatusIndicatorViewDND
{
    background-color:@colorYellow;
    corner-radius:3;
}
UiContactProfileStatusIndicatorViewAWAY
{
    background-color:@colorYellow;
    corner-radius:3;
}
UiContactProfileStatusIndicatorViewINVISIBLE
{
    background-color:@colorGrey;
    corner-radius:3;
}
UiContactProfileStatusLabel
{
    font-name: @fontName;
    font-size: 13;
    font-color: @colorGrey;
}
UiContactProfileAddContactButton
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
    background-color:@colorRed;
    background-color-highlighted: @colorRedOpavity07;
    corners-radius:18,0,0,18;
}
UiContactProfileAddContactChatButton
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
    background-color:@colorRed;
    background-color-highlighted: @colorGrey;
    background-color-disabled: @colorGrey;
    corners-radius:0,18,18,0;
    image-color:@colorWhite;
    image-color-highlighted:@colorWhite;
    image-color-disabled:@colorWhite;
}
UiContactProfileInputInfoTextView
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorGrey;
}
UiContactProfileApplyContactRequestButton
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
    background-color:@colorRed;
    background-color-highlighted: @colorGrey;
    background-color-disabled: @colorGrey;
    corners-radius:0,18,18,0;
}
UiContactProfileRejectContactRequestButton
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorGrey;
    font-color-highlighted: @colorGreyLight;
    font-color-disabled: @colorGreyLight;
    background-color:@colorWhite;
    background-color-highlighted: @colorWhite;
    background-color-disabled: @colorWhite;
    corners-radius:18,0,0,18;
}

/* UiContactProfileEdit */
UiContactProfileEditAvatarImageView
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:24;
}
UiContactProfileEditFirstNameTextField
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorBrown;
}
UiContactProfileEditLastNameTextField
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorBrown;
}
UiContactProfileEditSectionHeaderLabel
{
    font-name: @fontNameMedium;
    font-size: 13;
    font-color: @colorRed;
}
UiContactProfileEditAddContactCellLabel
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorGreyMiddle;
}
UiContactProfileEditContactCellPhoneTextField
{
    font-name: @fontNameLight;
    font-size: 15;
    font-color: @colorBlack;
}
UiContactProfileEditContactCellPhoneTypeLabel
{
    font-name: @fontNameMedium;
    font-size: 12;
    font-color: @colorGreyLight;
}
UiContactProfileEditMenuTableGreyCellLabel
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorBrown;
}
UiContactProfileEditMenuTableRedLabel
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorRed;
}
UiContactProfileEditPickerDoneButton
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorRed;
}

/* UiLoginPageView */
UiLoginPageTextFieldView {
    height: 47;
    font-name: @fontNameLight;
    font-size: 18;
    fon-color:@colorBlack;
    place-holder-text-color:@colorGreyLight;
    place-holder-font-name:@fontNameLight;
    place-holder-font-size:18;
}

UiLoginPageLoginButtonView {
    background-color: @colorRed;
    background-color-highlighted: @colorRedOpavity07;
    background-color-disabled: @colorRedOpavity07;
    font-color: @colorWhite;
    font-name: @fontNameBold;
    font-size: 18;
    height: 41;
}

UiLoginPageLinkButtonView {
    font-color: @colorBlack;
    font-color-highlighted: @colorGrey;
    font-color-disabled: @colorGrey;
    font-name: @fontName;
    font-size: 12;
}

UiLoginPageAppVersionLabel {
    font-color: @colorGreyBeforeDark;
    font-name: @fontNameLight;
    font-size: 15;
}

UiLoginPageErrorLabel {
    font-color: @colorRed;
    font-name: @fontName;
    font-size: 15;
}

UiLoginPageUiLanguageLabel {
    font-color: @colorBlack;
    font-name: @fontName;
    font-size: 15;
}

/* UiPreferences */
UiNavigationBarButtonCenter {
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
    font-color-highlighted: @colorWhite;
    font-color-selected: @colorRed;
    text-shadow-color: clear;
    /*
    background-color:@colorYellow;
    background-color-highlighted: @colorYellow;
    */
}
UiPreferencesTabPageViewPreferencesList__SectionHeaderView
{
    background-color:@colorGreyInfraLight;
}
UiPreferencesTabPageViewPreferencesList__SectionHeaderView__Label
{
    font-name: @fontNameMedium;
    font-size: 15;
    font-color: @colorGreyInfraDark;
    text-shadow-color: clear;
}
UiPreferencesTabPageViewPreferencesList__CellView__Label
{
    font-name: @fontNameLight;
    font-size: 15;
    font-color: @colorBlack;
    text-shadow-color: clear;
}
UiPreferencesTabPageViewPreferencesList__CellView__LabelValue
{
    font-name: @fontNameLight;
    font-size: 15;
    font-color: @colorGreyMiddle;
    text-shadow-color: clear;
}
UiStatusViewONLINE
{
    background-color:@colorGreen;
    border-color:@colorGreen;
    border-width:18;
}
UiStatusViewOFFLINE
{
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:18;
}
UiStatusViewDND
{
    background-color:@colorYellow;
    border-color:@colorYellow;
    border-width:18;
}
UiStatusViewAWAY
{
    background-color:@colorYellow;
    border-color:@colorYellow;
    border-width:18;
}
UiStatusViewINVISIBLE
{
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:18;
}
UiStatusViewTextField
{
    font-name: @fontNameLight;
    font-size: 18;
    font-color:@colorBlack;
    place-holder-text-color:@colorGreyLight;
    place-holder-font-name:@fontNameLight;
    place-holder-font-size:18;
}
/*Action List*/
UiActionListTitleLabel
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color:@colorBrown;
}
UiActionListCancelLabel
{
    font-name: @fontNameMedium;
    font-size: 19;
    tint-color:@colorGrey;
    font-color:@colorGrey;
    font-color-highlighted:@colorGrey;
}
UiActionListDestructiveLabel
{
    font-name: @fontNameMedium;
    font-size: 19;
    tint-color:@colorRed;
    font-color:@colorRed;
    font-color-highlighted:@colorRed;
}
UiActionListDefaultLabel
{
    font-name: @fontNameMedium;
    font-size: 19;
    tint-color:@colorRed;
    font-color:@colorRed;
    font-color-highlighted:@colorRed;
}
/* UiContactsRoster */
UiContactsRosterSectionHeaderView {
    background-color: #FFFFFF;
}
UiContactsRosterSectionHeaderViewLabel {
    font-name: @fontNameMedium;
    font-size: 15;
    font-color: @colorGreyBeforeLight;
}
UiContactsRosterCellViewHeaderLabel {
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorBlack;
}
UiContactsRosterCellViewHeaderLabelNew {
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorRed;
}
UiContactsRosterCellViewRequestLabel {
    font-name: @fontNameLight;
    font-size: 9;
    font-color: @colorGreyBeforeLight;
}