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

  /// No description provided for @location_details.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get location_details;

  /// No description provided for @action_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get action_download;

  /// No description provided for @energy_statistics.
  ///
  /// In en, this message translates to:
  /// **'Energy Statistics'**
  String get energy_statistics;

  /// No description provided for @income_formula.
  ///
  /// In en, this message translates to:
  /// **'Income Formula'**
  String get income_formula;

  /// No description provided for @today_power_generation.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Power Generation'**
  String get today_power_generation;

  /// No description provided for @total_plant.
  ///
  /// In en, this message translates to:
  /// **'Total Plant'**
  String get total_plant;

  /// No description provided for @total_device.
  ///
  /// In en, this message translates to:
  /// **'Total Device'**
  String get total_device;

  /// No description provided for @total_alarm.
  ///
  /// In en, this message translates to:
  /// **'Total Alarm'**
  String get total_alarm;

  /// No description provided for @profit_today.
  ///
  /// In en, this message translates to:
  /// **'Profit Today'**
  String get profit_today;

  /// No description provided for @total_profit.
  ///
  /// In en, this message translates to:
  /// **'Total Profit'**
  String get total_profit;

  /// No description provided for @last_updated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get last_updated;

  /// No description provided for @all_power_stations.
  ///
  /// In en, this message translates to:
  /// **'All Power Stations'**
  String get all_power_stations;

  /// No description provided for @sn_device_detail.
  ///
  /// In en, this message translates to:
  /// **'SN Device Detail'**
  String get sn_device_detail;

  /// No description provided for @tooltip_power_report.
  ///
  /// In en, this message translates to:
  /// **'Power Generation Report'**
  String get tooltip_power_report;

  /// No description provided for @tooltip_device_report.
  ///
  /// In en, this message translates to:
  /// **'Device Data Report'**
  String get tooltip_device_report;

  /// No description provided for @tooltip_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltip_settings;

  /// No description provided for @action_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get action_retry;

  /// No description provided for @label_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get label_error;

  /// No description provided for @msg_generating_report.
  ///
  /// In en, this message translates to:
  /// **'Generating device data report...'**
  String get msg_generating_report;

  /// No description provided for @msg_report_saved.
  ///
  /// In en, this message translates to:
  /// **'Device report saved to Downloads'**
  String get msg_report_saved;

  /// No description provided for @msg_download_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download'**
  String get msg_download_failed;

  /// No description provided for @header_device_settings.
  ///
  /// In en, this message translates to:
  /// **'Device Settings'**
  String get header_device_settings;

  /// No description provided for @no_settings_available.
  ///
  /// In en, this message translates to:
  /// **'No settings available'**
  String get no_settings_available;

  /// No description provided for @header_alarm_management.
  ///
  /// In en, this message translates to:
  /// **'Alarm Management > Plant'**
  String get header_alarm_management;

  /// No description provided for @msg_no_alarms.
  ///
  /// In en, this message translates to:
  /// **'No alarms found'**
  String get msg_no_alarms;

  /// No description provided for @status_processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get status_processed;

  /// No description provided for @status_untreated.
  ///
  /// In en, this message translates to:
  /// **'Untreated'**
  String get status_untreated;

  /// No description provided for @label_sn_colon.
  ///
  /// In en, this message translates to:
  /// **'SN: '**
  String get label_sn_colon;

  /// No description provided for @label_code_colon.
  ///
  /// In en, this message translates to:
  /// **'Code: '**
  String get label_code_colon;

  /// No description provided for @label_occurrence_time.
  ///
  /// In en, this message translates to:
  /// **'Occurrence time: '**
  String get label_occurrence_time;

  /// No description provided for @label_device_pn.
  ///
  /// In en, this message translates to:
  /// **'Device PN: '**
  String get label_device_pn;

  /// No description provided for @label_device_type.
  ///
  /// In en, this message translates to:
  /// **'Device Type: '**
  String get label_device_type;

  /// No description provided for @label_description.
  ///
  /// In en, this message translates to:
  /// **'Description: '**
  String get label_description;

  /// No description provided for @tooltip_mark_processed.
  ///
  /// In en, this message translates to:
  /// **'Mark as processed'**
  String get tooltip_mark_processed;

  /// No description provided for @tooltip_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tooltip_delete;

  /// No description provided for @msg_alarm_deleted.
  ///
  /// In en, this message translates to:
  /// **'Alarm deleted'**
  String get msg_alarm_deleted;

  /// No description provided for @msg_failed_delete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete alarm'**
  String get msg_failed_delete;

  /// No description provided for @dialog_title_delete_alarm.
  ///
  /// In en, this message translates to:
  /// **'Delete Alarm'**
  String get dialog_title_delete_alarm;

  /// No description provided for @dialog_msg_delete_alarm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this alarm?'**
  String get dialog_msg_delete_alarm;

  /// No description provided for @action_yes_delete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get action_yes_delete;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @report_select_collector_hint.
  ///
  /// In en, this message translates to:
  /// **'Select a collector (PN)'**
  String get report_select_collector_hint;

  /// No description provided for @report_download_full_title.
  ///
  /// In en, this message translates to:
  /// **'Download Full Report'**
  String get report_download_full_title;

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

  /// No description provided for @plant_create_time.
  ///
  /// In en, this message translates to:
  /// **'Create Time'**
  String get plant_create_time;

  /// No description provided for @plant_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get plant_location;

  /// No description provided for @live_data.
  ///
  /// In en, this message translates to:
  /// **'Live Data'**
  String get live_data;

  /// No description provided for @status_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get status_normal;

  /// No description provided for @status_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get status_offline;

  /// No description provided for @status_alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get status_alarm;

  /// No description provided for @current_power_generation.
  ///
  /// In en, this message translates to:
  /// **'Current Power Generation'**
  String get current_power_generation;

  /// No description provided for @total_power_generation.
  ///
  /// In en, this message translates to:
  /// **'Total Power Generation'**
  String get total_power_generation;

  /// No description provided for @total_installed_capacity.
  ///
  /// In en, this message translates to:
  /// **'Total Installed Capacity'**
  String get total_installed_capacity;

  /// No description provided for @drawer_plant_info.
  ///
  /// In en, this message translates to:
  /// **'Plant Info'**
  String get drawer_plant_info;

  /// No description provided for @drawer_download_report.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get drawer_download_report;

  /// No description provided for @drawer_contact_support.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get drawer_contact_support;

  /// No description provided for @drawer_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawer_logout;

  /// No description provided for @report_no_collectors.
  ///
  /// In en, this message translates to:
  /// **'No collectors found'**
  String get report_no_collectors;

  /// No description provided for @report_collector_label.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get report_collector_label;
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
