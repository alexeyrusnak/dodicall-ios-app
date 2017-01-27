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
@fontNameDdcall: ddcall;

@colorBlack:#000000;
@colorRed:#e6001e;
@colorRedOpavity07:#ed4c61;
@colorBrown:#313131;
@colorBrownLight:#d9d9d9;
@colorWhite:#FFFFFF;
@colorWhiteOpavity07:#b3b3b3;
@colorGreyLight:#d1d1d1;
@colorGreyBeforeLight:#cdcdcd;
@colorGreyInfraLight:#f7f7f7;
@colorGreyPlaceholder:#989898;
@colorGreyLightThenPlaceholder:#a1a1a1;
@colorGreyDark:#2b2b2b;
@colorGreyBeforeDark:#b4b3b3;
@colorGreyInfraDark:#8f8f8f;
@colorGreyLightDark:#929292;
@colorGrey:#7d7d7d;
@colorGreyMiddle:#515151;
@colorGreen:#00b300;
@colorYellow:#eeb706;
@colorForViewSplit:#d3d3d3;
@colorChatIncomingBuble:#dbd4d5;
@colorChatOugoingBuble:#aca4a6;
@colorWhiteOpacity0:RGBA(255,255,255,0.0);
@colorWhiteOpacity07:RGBA(255,255,255,0.7);

@imageBgRed:#e6001e,64,49;
@imageBgYellow:#eeb706,64,49;
@imageBgBlack:#000000,64,49;

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
*/
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
NavigationBar {
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorRed;
    text-shadow-color: clear;
    background-color:@colorWhite;
    background-tint-color:@colorWhite;
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
    selection-indicator-image:@imageBgRed;
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
UiPlaceholderLabel
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorGrey;
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
    font-color: @colorRed;
    text-shadow-color: clear;
    /*background-color:@colorWhite;*/
}

UiCheckListButtonView {
    font-name: @fontName;
    font-size: 19;
    font-color: @colorGreyDark;
    font-color-selected: @colorRed;
    text-shadow-color: clear;
    background-color:@colorWhite;
}
UiContactsListCellButton
{
    image-color:@colorGrey;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactsListCellButtonOFFLINE
{
    image-color:@colorGrey;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactsListCellButtonINVISIBLE
{
    image-color:@colorGrey;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactsListCellButtonONLINE
{
    image-color:@colorGreen;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactsListCellButtonDND
{
    image-color:@colorYellow;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactsListCellButtonAWAY
{
    image-color:@colorYellow;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
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
    background-color-disabled: @colorRedOpavity07;
    corners-radius:18,0,0,18;
}
UiContactProfileAddContactAndChatButton
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
    background-color:@colorRed;
    background-color-highlighted: @colorRedOpavity07;
    background-color-disabled: @colorRedOpavity07;
    corners-radius:18,18,18,18;
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
    font-size: 17;
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
    corners-radius:18,18,18,18;
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
    corners-radius:18,18,18,18;
}
UiContactProfileInviteInfoTextView
{
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorGrey;
}
UiContactProfileInviteTextLabel
{
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorGrey;
}
UiContactProfileRequestSendedLabel
{
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorGrey;
}
UiContactProfileUnblockContactButton
{
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorWhite;
    background-color:@colorRed;
    background-color-highlighted: @colorGrey;
    background-color-disabled: @colorGrey;
    corners-radius:18,18,18,18;
}
UiContactProfileUserBlockedLabel
{
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorGreyPlaceholder;
}
UiContactProfileBalanceStatusLabel
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorGrey;
}
UiContactProfileBalanceValueLabel
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorBrown;
}
UiContactProfileButton
{
    image-color:@colorGrey;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactProfileButtonOFFLINE
{
    image-color:@colorGrey;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactProfileButtonINVISIBLE
{
    image-color:@colorGrey;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactProfileButtonONLINE
{
    image-color:@colorGreen;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactProfileButtonDND
{
    image-color:@colorYellow;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactProfileButtonAWAY
{
    image-color:@colorYellow;
    image-color-highlighted:@colorGreyLight;
    image-color-disabled:@colorGreyLight;
}
UiContactProfileButtonLogout
{
    font-name: @fontName;
    font-size: 15;
    font-color: @colorBrown;
    background-color-highlighted:@colorGreyInfraLight;
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
    background-color-highlighted: @colorGrey;
    background-color-disabled: @colorGrey;
    font-color: @colorWhite;
    font-color-highlighted: @colorWhite;
    font-color-disabled: @colorWhite;
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
    font-color: @colorRed;
    font-color-highlighted: @colorRed;
    font-color-selected: @colorRed;
    text-shadow-color: clear;
    /*
    background-color:@colorWhite;
    background-color-highlighted: @colorWhite;
    */
}
UiNavigationBarBlackButtonCenter {
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorBlack;
    font-color-highlighted: @colorBlack;
    font-color-selected: @colorBlack;
    text-shadow-color: clear;
    /*
    background-color:@colorWhite;
    background-color-highlighted: @colorWhite;
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

/* UiChatsTabPageView */
UiChatsListTableView
{
    tint-color:@colorRed;
}
UiChatsListCellViewAvatarImageView
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:24;
}
UiChatsListCellViewStatusIndicator {
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:6;
    corner-radius:3;
}

UiChatsListCellViewStatusIndicatorOFFLINE {
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:6;
    corner-radius:3;
}

UiChatsListCellViewStatusIndicatorONLINE {
    background-color:@colorGreen;
    border-color:@colorGreen;
    border-width:6;
    corner-radius:3;
}

UiChatsListCellViewStatusIndicatorDND {
    background-color:@colorYellow;
    border-color:@colorYellow;
    border-width:6;
    corner-radius:3;
}

UiChatsListCellViewStatusIndicatorAWAY {
    background-color:@colorYellow;
    border-color:@colorYellow;
    border-width:6;
    corner-radius:3;
}

UiChatsListCellViewStatusIndicatorINVISIBLE {
    background-color:@colorGrey;
    border-color:@colorGrey;
    border-width:6;
    corner-radius:3;
}
UiChatsListCellViewHeaderLabel
{
    font-name: @fontNameMedium;
    font-size: 17;
    font-color: @colorBlack;
}
UiChatsListCellViewDateTimeLabel
{
    font-name: @fontName;
    font-size: 11;
    font-color: @colorGreyBeforeLight;
}
UiChatsListCellViewAddInfoLabel
{
    font-name: @fontName;
    font-size: 10;
    font-color: @colorGreyBeforeDark;
}
UiChatsListCellViewDescrLabel 
{
    font-name: @fontName;
    font-size: 11;
    font-color: @colorBlack;
    text-align: left;
}
UiChatsListCellViewDescrLabelReaded 
{
    font-name: @fontName;
    font-size: 11;
    font-color: @colorGreyLightThenPlaceholder;
    text-align: left;
}
UiChatsListCellViewCountLabel
{
    font-name: @fontNameBold;
    font-color: @colorWhite;
    font-size:11;
}
UiChatsListCellViewCountLabelBgView
{
    border-color:@colorRed;
    border-width:8;
    corner-radius:8;
    background-color:@colorRed;
}
UiChatsListToolBarButtonLeft {
    font-color: @colorGrey;
    font-color-highlighted: @colorGreyLight;
    font-color-disabled: @colorGreyLight;
    font-name: @fontName;
    font-size: 15;
}
UiChatsListToolBarButtonRight {
    font-color: @colorRed;
    font-color-highlighted: @colorGrey;
    font-color-disabled: @colorGrey;
    font-name: @fontName;
    font-size: 15;
}

/* UiChatView */
UiChatViewHeaderLabel
{
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorBlack;
}
UiChatViewHeaderDesriptionLabel
{
    font-name: @fontName;
    font-size: 10;
    font-color: @colorGreyInfraDark;
    text-align: left;
}
UiChatViewNavigationBarButton
{
    image-color:@colorRed;
    image-color-highlighted:@colorGrey;
    image-color-disabled:@colorGrey;
}
UiChatFooterView
{
    background-color:@colorGreyInfraLight;
}
UiChatFooterMessageInputTextView
{
    text-padding:7 3 7 3;
    corner-radius:12;
    border-color:@colorForViewSplit;
    border-width:1;
    font-name: @fontName;
    /*font-size: 14;*/
    font-color:@colorBlack;
}
UiChatViewFooterSendButton
{
    font-color:@colorRed;
    font-color-highlighted:@colorGrey;
    font-color-disabled:@colorGrey;
    font-name: @fontNameMedium;
    font-size: 14;
}
UiChatViewMenuTitle {
    font-color:@colorGrey;
    font-size:18;
    font-name:@fontNameLight;
}
UiChatViewMenuTopSeparator {
    image-color:@colorGrey;
}
UiChatViewSettingsFieldNameLabel {
    font-name:@fontNameLight;
    font-color:@colorBlack;
    font-size:15;
}
UiChatViewSettingsFieldValueLabel {
    font-name:@fontNameLight;
    font-color:@colorGrey;
    font-size:15;
}
UiChatViewSettingsTitle {
    font-name:@fontNameLight;
    font-color:@colorGrey;
    font-size:10;
}
UiChatMakeConferenceViewTitle {
    font-name:@fontNameLight;
    font-color:@colorGrey;
    font-size:10;
}
UiChatMakeConferenceViewNavigationBarButton
{
    image-color:@colorRed;
    image-color-highlighted:@colorGrey;
    image-color-disabled:@colorGrey;
}

UiChatViewEditToolBarButton
{
    font-color: @colorRed;
    font-color-highlighted: @colorGrey;
    font-color-disabled: @colorGrey;
    font-name: @fontName;
    font-size: 15;
}

UiChatViewEditToolBarLabel
{
    font-color: @colorBlack;
    font-name: @fontName;
    font-size: 15;
}

/*UiChatViewMessages*/
UiChatViewMessagesTableView
{
    tint-color:@colorRed;
}
UiChatViewMessagesAvatar
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:20;
}
UiChatViewMessagesBubbleContainerView
{
}
UiChatViewMessagesIncomingBubbleView
{
    image-color:@colorChatIncomingBuble;
    image-stretchable:TRUE;
    image-leftCap:16;
    image-topCap:16;
    image-rotate:1;
    alpha:0.8;
}
UiChatViewMessagesOutgoingBubbleView
{
    image-color:@colorChatOugoingBuble;
    image-stretchable:TRUE;
    image-leftCap:16;
    image-topCap:16;
    alpha:0.8;
    flip-vertical:TRUE;
}
UiChatViewMessagesBubbleContainerTextView
{
    font-color:@colorBrown;
    font-name: @fontName;
    /*font-size: 15;*/
    text-padding:0 0 0 0;
    text-align: left;
}
UiChatViewMessagesBubbleContainerOutgoingTextView
{
    font-color:@colorBrown;
    font-name: @fontName;
    /*font-size: 15;*/
    text-padding:0 0 0 0;
    text-align: left;
}
UiChatViewMessagesBubbleContainerDeletedMessageTextView
{
    font-color:@colorBrown;
    font-name: @fontName;
    /*font-size: 15;*/
    text-padding:0 0 0 0;
    text-align: left;
    font-style: italic;
}
UiChatViewMessagesBubbleContainerTimeLabel
{
    font-color:@colorGreyMiddle;
    font-name: @fontName;
    font-size: 10;
}
UiChatViewMessagesHeaderCellDateLabel
{
    corner-radius:7;
    font-color:@colorGreyMiddle;
    font-name:@fontName;
    font-size:10;
    background-color:@colorGreyInfraLight;
}
UiChatViewMessagesHeaderCellNewMessagesLabel
{
    font-color:@colorGreyMiddle;
    font-name:@fontNameMedium;
    font-size:14;
}
UiChatViewMessagesContactLabel
{
    font-color:@colorGreyBeforeLight;
    font-name:@fontNameMedium;
    font-size:11;
}
UiChatViewMessagesDeliveryLabel
{
    font-color:@colorWhite;
    font-name:@fontName;
    font-size:10;
}
UiChatViewMessagesDeliveryStatusIndicatorOff
{
    image-color:@colorGreyLightDark;
}
UiChatViewMessagesDeliveryStatusIndicatorOn
{
    image-color:@colorWhite;
}
UiChatViewMessagesInfoTextView
{
    font-color:@colorBrownLight;
    font-name: @fontName;
    /*font-size: 15;*/
    text-padding:0 0 0 0;
    text-align: center;
}
UiChatViewMessagesEditedImageView
{
    image-color:@colorGrey;
}
/*UiChatViewUsers*/
UiChatViewUsersAddUserButtonView
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:24;
}
UiChatViewUsersAddUserButtonLabel
{
    font-name: @fontNameMedium;
    font-size: 16;
    font-color: @colorGreyBeforeDark;
}
/*UiChatTitleSettings*/
UiChatTitleSettingsBackgroundView {
    background-color: @colorGreyInfraLight;
}
UiChatTitleSettingsTextFieldWrapper{
    background-color: @colorWhite;
}
UiChatTitleSettingsTextField {
    font-name: @fontName;
    font-color: @colorBlack;
    tint-color: @colorRed;
}

/* Global left menu */
UiAppLeftMenuView
{
    background-color:@colorRed;
}
UiAppLeftMenuTopRedPanel
{
    border-color:@colorRed;
    border-width:20;
}
UiAppLeftMenuViewProfileAvatarImageView
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:19;
}
/*UIPhoneCall*/
UiCallButton
{   image-color:@colorWhite;
    image-color-highlighted:@colorGreyLight;
    border-color:@colorWhite;
    border-width:2;
    corner-radius:34;
}
UiCallButtonNoImage
{
    image-color:@colorWhite;
    border-color:@colorWhite;
    border-width:2;
    corner-radius:34;
}
UiCallAudioRouteButton
{
    image-size:38,38;
    border-width:2;
    border-color:@colorWhite;
    corner-radius:34;

}
UiCallMicButton {
    image: mic_call;
    image-color:@colorWhite;
    image-color-highlighted:@colorGreyLight;
    border-color:@colorWhite;
    border-width:2;
    corner-radius:34;
    content-insets:15 15 15 15;
}
UiCallMicButtonDisabled {
    image: mic_disabled_call;
    image-color:@colorRed;
    image-color-highlighted:rgb(180,0,30);
    border-color:@colorRed;
    border-width:2;
    corner-radius:34;
    content-insets:10 10 10 10;
}
UiCallButtonDisabled
{   image-color:rgb(87,84,84);
    image-color-disabled:rgb(87,84,84);
    border-color:rgb(87,84,84);
    border-width:2;
    corner-radius:34;
}
UiCallNavigationBar {
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
    background-color:clear;
    bottom-shadow-color:clear;
}
UiCallAvatarImage {
    border-color:@colorWhite;
    border-width:1;
    corner-radius:51;
}
UiCallAvatarImageCompact {
    border-color:@colorWhite;
    border-width:1;
    corner-radius:40;
}
UiCallButtonLabel {
    font-name: @fontName;
    font-size: 11;
    font-color: @colorWhite;
}
UiCallButtonLabelDisabled {
    font-name: @fontName;
    font-size: 11;
    font-color: rgb(87,84,84);
}
UiCallStatusLabel {
    font-name: @fontName;
    font-size: 16;
    font-color: @colorWhite;
}
UiCallNameLabel {
    font-name: @fontNameMedium;
    font-size: 19;
    font-color: @colorWhite;
}
UiCallLockImage {
    corner-radius: 13;
    backgroud-color:@colorWhite;
}
UiCallChatButton {
    image-color:@colorWhite;
}
UiCallChatButtonDisabled {
    image-color:rgb(87,84,84);
    image-disabled:rgb(87,84,84);
}

/*CallNum*/
UiCallViewNumButtonSuperView {
    border-color:@colorWhite;
    border-width:1;
    corner-radius: 34;
}
UiCallViewNumButtonSuperViewCompact {
    border-color:@colorWhite;
    border-width:1;
    corner-radius: 30;
}

UiCallViewNumButtonTopLabel {
    font-name: @fontNameLight;
    font-size: 30;
    font-color: @colorWhite;
    font-color-highlited:@colorWhiteOpavity07;
}
UiCallViewNumButtonBotLabel {
    font-name: @fontName;
    font-size: 11;
    font-color: @colorWhite;
    font-color-highlited:@colorWhiteOpavity07;
}

UiCallViewNumSymbolsLabel {
    font-name: @fontName;
    font-size: 19;
    font-color: @colorWhite;
}
UiCallViewNumTextButton {
    font-name: @fontName;
    font-size: 15;
    font-color: @colorWhite;
    font-color-highlited:@colorWhiteOpavity07;
}
UiCallViewNumTextButtonCompact {
    font-name: @fontName;
    font-size: 13;
    font-color: @colorWhite;
    font-color-highlited:@colorWhiteOpavity07;
}

/*UiDialerView*/
UiDialerViewPhoneTextField
{
    font-name: @fontNameLight;
    font-size: 24;
    font-color: @colorBlack;
}
UiDialerVieInfoLabel
{
    font-name: @fontName;
    font-size: 11;
    font-color: @colorGreyBeforeLight;
    text-align: center;
}
UiDialerViewNumButton
{
    border-color:@colorRed;
    border-width:1;
    corner-radius: 35;
    background-color:@colorWhite;
    background-color-highlighted:@colorRed;
}
UiDialerViewNumButtonSuperView
{
    border-color:@colorRed;
    border-width:1;
    corner-radius: 35;
    background-color:@colorWhite;
}
UiDialerViewNumButtonSuperViewHighlighted
{
    border-color:@colorRed;
    border-width:1;
    corner-radius: 35;
    background-color:@colorRed;
}
UiDialerViewNumButtonSuperViewCompact
{
    border-color:@colorRed;
    border-width:1;
    corner-radius: 30;
    background-color:@colorWhite;
}
UiDialerViewNumButtonSuperViewCompactHighlighted
{
    border-color:@colorRed;
    border-width:1;
    corner-radius: 30;
    background-color:@colorRed;
}
UiDialerViewNumButtonTopLabel
{
    font-name: @fontNameLight;
    font-size: 30;
    font-color: @colorRed;
    font-color-highlighted: @colorWhite;
}
UiDialerViewNumButtonBotLabel
{
    font-name: @fontName;
    font-size: 11;
    font-color: @colorRed;
    font-color-highlighted: @colorWhite;
}
UiDialerViewCallButton
{
    background-color:@colorGreen;
    image-color:@colorWhite;
    corner-radius: 35;
}
UiDialerViewCallButtonCompact
{
    background-color:@colorGreen;
    image-color:@colorWhite;
    corner-radius: 30;
}
UiDialerViewConferenceButtonLabel
{
    font-size: 10;
    font-color: @colorGreyLight;
}
UiDialerViewTaxButtonLabel
{
    font-size: 10;
    font-color: @colorGreyLight;
}
UiDialerContactsTopView {
    background-color: @primaryBackgroundColorTop;
}
UiDialerContactsNameLabel {
    font-size: 17;
    font-color: @colorBlack;
    font-name:@fontNameMedium;
}
UiDialerContactsInfoLabel {
    font-size: 13;
    font-color: #838282;
    font-name:@fontName;
}
UiDialerContactsAvatarImage {
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:21;
}
UiDialerContactCellTypeLabel {
    font-size: 10;
    font-color: #afafaf;
    font-name:@fontName;
}
UiDialerContactCellNumberLabel {
    font-size: 15;
    font-color: #5b5b5b;
    font-name:@fontNameLight;
}
UiDialerContactCellSeparator {
    border-color:@colorForViewSplit;
    border-width:13;
}
/*History Statistics*/
UiHistoryStatisticsViewTitleBlack 
{
    font-size: 16;
    font-color:@colorBlack;
    font-name:@fontName;
    background-color:@colorWhite;
}
UiHistoryStatisticsViewTitleRed 
{
    font-size: 16;
    font-color:@colorRed;
    font-name:@fontName;
    background-color:@colorWhite;
}
UiHistoryStatisticsViewTime 
{
    font-size: 11;
    font-color:@colorGrey;
    font-name:@fontName;
    background-color:@colorWhite;
}
UiHistoryStatisticsViewCallsNumberRed 
{
    font-size: 9;
    font-color:@colorRed;
    font-name:@fontNameLight;
    background-color:@colorWhite;
}
UiHistoryStatisticsViewCallsNumberGreen 
{
    font-size: 9;
    font-color:@colorGreen;
    font-name:@fontNameLight;
    background-color:@colorWhite;
}
UiHistoryStatisticsViewGreenArrow 
{
    image-color:@colorGreen;
}
UiHistoryStatisticsViewRedArrow 
{
    image-color:@colorRed;
}
UiHistoryStatisticsViewAvatar 
{
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:23;
}
UiHistoryCallsStatus 
{
    font-size: 14;
    font-color:@colorGrey;
    font-name:@fontName;
}
UiHistoryCallsInfo 
{
    font-size: 11;
    font-color:@colorGrey;
    font-name:@fontName;
}
UiHistoryCallsType 
{
    font-size: 14;
    font-color:@colorBlack;
    font-name:@fontName;
}
UiHistoryCallsViewArrowRed 
{
    image-color:@colorRed;
}
UiHistoryCallsViewArrowGreen 
{
    image-color:@colorGreen;
}
UiConferenceCallAvatarImage {
    border-color:@colorGreyLight;
    border-width:1;
    corner-radius:24;
}
UiConferenceCallUserName {
    font-size: 10;
    font-color:@colorWhite;
    font-name:@fontName;
}
/*NEEDS UPDATE*/
UiConferenceCallTitle {
    font-size: 16;
    font-color:@colorWhite;
    font-name:@fontName;
}
/*NEEDS UPDATE*/
UiConferenceCallStatus {
    font-size: 12;
    font-color:@colorWhite;
    font-name:@fontName;
}
UiConferenceSeparator {
    border-color:@colorWhiteOpacity07;
    border-width:1;
}
UiConferenceCallUserLock {
    corner-radius: 9;
    backgroud-color:@colorWhite;
}
UiInCallStatusBarLabel {
    font-size: 13;
    font-color:@colorWhite;
    font-name:@fontName;
}
