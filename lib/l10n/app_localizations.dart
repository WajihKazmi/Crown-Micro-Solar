import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru')
  ];

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @tabs_home.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabs_home;

  /// No description provided for @tabs_plant.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get tabs_plant;

  /// No description provided for @tabs_device.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get tabs_device;

  /// No description provided for @tabs_user.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabs_user;

  /// No description provided for @plant_information.
  ///
  /// In en, this message translates to:
  /// **'Plant Information'**
  String get plant_information;

  /// No description provided for @about_us.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get about_us;

  /// No description provided for @interface_theme.
  ///
  /// In en, this message translates to:
  /// **'Interface Theme'**
  String get interface_theme;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @account_information.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get account_information;

  /// No description provided for @introduction.
  ///
  /// In en, this message translates to:
  /// **'INTRODUCTION'**
  String get introduction;

  /// No description provided for @about_us_introduction.
  ///
  /// In en, this message translates to:
  /// **'Crown Micro has been serving with its varied IT & Power Products, since 1992 established as a robust and trustworthy name in the city Los Angeles, California, USA. The thriving and back-defending team is hustling to serve you with innovative, environment-friendly, and valuable products. Dedication, is the first thing we set into our products, to supply you with the best. Our progressive hard work pays off and in 2006 we teamed as a member of the well-known name SADITA Holding LTD but Crown Micro is maintained the legacy of being prosperous and to takeover more power, keep on working and aimed to spread it to some more additional parts of the globe.Therefore within 20 years of establishment Crown micro marked its name in the market the United Arab Emirates, Russia, Kazakhstan, Ukraine, China, Germany, Kingdom Of Saudi Arabia, Kuwait, Pakistan, Nigeria, Kenya, Tunisia, Syria, Lebanon, Iraq, Morocco, and Ghana. We are now in collaboration with more than 75 businesses around the globe and recognized as Crown Micro an international brand. Crown Micro owns quality products in each unit of technology including an immersive range of computers, mobile accessories, innovative solar inverters, AVR, UPS, Solar panels, and much more'**
  String get about_us_introduction;

  /// No description provided for @company_name.
  ///
  /// In en, this message translates to:
  /// **'CROWN MICRO (PVT) LIMITED'**
  String get company_name;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @old_password.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get old_password;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password;

  /// No description provided for @confirm_new_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirm_new_password;

  /// No description provided for @enter_old_password.
  ///
  /// In en, this message translates to:
  /// **'Enter old password'**
  String get enter_old_password;

  /// No description provided for @password_must_be_6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get password_must_be_6;

  /// No description provided for @passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_do_not_match;

  /// No description provided for @password_changed_success.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get password_changed_success;

  /// No description provided for @password_change_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password. Please check your old password and try again.'**
  String get password_change_failed;

  /// No description provided for @drawer_download_report.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get drawer_download_report;

  /// No description provided for @drawer_plant_info.
  ///
  /// In en, this message translates to:
  /// **'Plant Info'**
  String get drawer_plant_info;

  /// No description provided for @drawer_contact_support.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get drawer_contact_support;

  /// No description provided for @drawer_logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get drawer_logout;

  /// No description provided for @current_power_generation.
  ///
  /// In en, this message translates to:
  /// **'Current Power Generation'**
  String get current_power_generation;

  /// No description provided for @total_installed_capacity.
  ///
  /// In en, this message translates to:
  /// **'Total Installed Capacity'**
  String get total_installed_capacity;

  /// No description provided for @output_power.
  ///
  /// In en, this message translates to:
  /// **'Output Power'**
  String get output_power;

  /// No description provided for @live_data.
  ///
  /// In en, this message translates to:
  /// **'Live Data'**
  String get live_data;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @location_details.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get location_details;

  /// No description provided for @range_day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get range_day;

  /// No description provided for @range_month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get range_month;

  /// No description provided for @range_year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get range_year;

  /// No description provided for @report_download_full_title.
  ///
  /// In en, this message translates to:
  /// **'Download Full Report'**
  String get report_download_full_title;

  /// No description provided for @report_no_collectors.
  ///
  /// In en, this message translates to:
  /// **'No collectors available for this plant.'**
  String get report_no_collectors;

  /// No description provided for @report_collector_label.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get report_collector_label;

  /// No description provided for @report_select_collector_hint.
  ///
  /// In en, this message translates to:
  /// **'Select a collector (PN)'**
  String get report_select_collector_hint;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get action_download;
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
      <String>['ar', 'en', 'es', 'fr', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
