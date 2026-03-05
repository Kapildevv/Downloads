import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get categoryFood;

  /// No description provided for @categoryTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit & Auto'**
  String get categoryTransit;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities & Bills'**
  String get categoryUtilities;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping & Groceries'**
  String get categoryShopping;

  /// No description provided for @categoryInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get categoryInvestments;

  /// No description provided for @categoryMandap.
  ///
  /// In en, this message translates to:
  /// **'Mandap & Venue'**
  String get categoryMandap;

  /// No description provided for @categoryFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival & Puja'**
  String get categoryFestival;

  /// No description provided for @categoryGold.
  ///
  /// In en, this message translates to:
  /// **'Gold & Jewellery'**
  String get categoryGold;

  /// No description provided for @categoryTuition.
  ///
  /// In en, this message translates to:
  /// **'Tuition & Coaching'**
  String get categoryTuition;

  /// No description provided for @categoryDomesticHelp.
  ///
  /// In en, this message translates to:
  /// **'Domestic Help'**
  String get categoryDomesticHelp;

  /// No description provided for @categoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical & Pharma'**
  String get categoryMedical;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categoryEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI & Loans'**
  String get categoryEmi;

  /// No description provided for @categoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance Premium'**
  String get categoryInsurance;

  /// No description provided for @categoryUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get categoryUncategorized;

  /// No description provided for @alertAdded.
  ///
  /// In en, this message translates to:
  /// **'Alert Added'**
  String get alertAdded;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @budgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget Alerts'**
  String get budgetAlerts;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @repeatOnDays.
  ///
  /// In en, this message translates to:
  /// **'Repeat on Days'**
  String get repeatOnDays;

  /// No description provided for @limitAmount.
  ///
  /// In en, this message translates to:
  /// **'Limit Amount'**
  String get limitAmount;

  /// No description provided for @amountBlank.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be blank'**
  String get amountBlank;

  /// No description provided for @numbersOnly.
  ///
  /// In en, this message translates to:
  /// **'Numbers only'**
  String get numbersOnly;

  /// No description provided for @setAlert.
  ///
  /// In en, this message translates to:
  /// **'Set Alert'**
  String get setAlert;

  /// No description provided for @noActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get noActiveAlerts;

  /// No description provided for @theOracle.
  ///
  /// In en, this message translates to:
  /// **'The Oracle'**
  String get theOracle;

  /// No description provided for @howealthyOracle.
  ///
  /// In en, this message translates to:
  /// **'Howealthy Oracle'**
  String get howealthyOracle;

  /// No description provided for @operatorProfile.
  ///
  /// In en, this message translates to:
  /// **'Operator Profile'**
  String get operatorProfile;

  /// No description provided for @alertMatrix.
  ///
  /// In en, this message translates to:
  /// **'Alert Matrix'**
  String get alertMatrix;

  /// No description provided for @generateReports.
  ///
  /// In en, this message translates to:
  /// **'Generate Reports'**
  String get generateReports;

  /// No description provided for @environmentalControls.
  ///
  /// In en, this message translates to:
  /// **'Environmental Controls'**
  String get environmentalControls;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tabPnl.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get tabPnl;

  /// No description provided for @tabTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get tabTimeline;

  /// No description provided for @tabWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get tabWeek;

  /// No description provided for @tabMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get tabMonth;

  /// No description provided for @weekViewSandbox.
  ///
  /// In en, this message translates to:
  /// **'Week View Sandbox'**
  String get weekViewSandbox;

  /// No description provided for @monthViewSandbox.
  ///
  /// In en, this message translates to:
  /// **'Month View Sandbox'**
  String get monthViewSandbox;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsTitle;

  /// No description provided for @sms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sms;

  /// No description provided for @smsDesc.
  ///
  /// In en, this message translates to:
  /// **'To read financial transactions'**
  String get smsDesc;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationDesc.
  ///
  /// In en, this message translates to:
  /// **'To tag transaction locations'**
  String get locationDesc;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'To send you budget alerts'**
  String get notificationsDesc;

  /// No description provided for @privacyConsent.
  ///
  /// In en, this message translates to:
  /// **'Privacy Consent'**
  String get privacyConsent;

  /// No description provided for @iDisagree.
  ///
  /// In en, this message translates to:
  /// **'I Disagree'**
  String get iDisagree;

  /// No description provided for @iAgree.
  ///
  /// In en, this message translates to:
  /// **'I Agree'**
  String get iAgree;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated'**
  String get profileUpdated;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @customerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer ID: {id}'**
  String customerIdLabel(String id);

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @nameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameEmpty;

  /// No description provided for @emailId.
  ///
  /// In en, this message translates to:
  /// **'Email ID'**
  String get emailId;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @mobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileRequired;

  /// No description provided for @mobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid mobile number'**
  String get mobileInvalid;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @fileType.
  ///
  /// In en, this message translates to:
  /// **'File Type'**
  String get fileType;

  /// No description provided for @generateAndSend.
  ///
  /// In en, this message translates to:
  /// **'Generate and Send'**
  String get generateAndSend;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @noExpenseDataYet.
  ///
  /// In en, this message translates to:
  /// **'No expense data yet'**
  String get noExpenseDataYet;

  /// No description provided for @spendBreakdownAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your spend breakdown will appear here'**
  String get spendBreakdownAppearHere;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get expenseBreakdown;

  /// No description provided for @oracleInsights.
  ///
  /// In en, this message translates to:
  /// **'Oracle Insights'**
  String get oracleInsights;

  /// No description provided for @findingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} findings'**
  String findingsCount(int count);

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @transactionsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your financial timeline will appear here'**
  String get transactionsAppearHere;

  /// Label for the Cash Flow tab in the dashboard
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get tabCashflow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'kn', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
