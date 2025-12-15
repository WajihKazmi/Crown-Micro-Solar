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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enter_username.
  ///
  /// In en, this message translates to:
  /// **'Enter Username'**
  String get enter_username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enter_password;

  /// No description provided for @remember_me.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get remember_me;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @toggle_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get toggle_user;

  /// No description provided for @toggle_installer.
  ///
  /// In en, this message translates to:
  /// **'Installer'**
  String get toggle_installer;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @wifi_config.
  ///
  /// In en, this message translates to:
  /// **'Wifi Configuration'**
  String get wifi_config;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @get_otp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get get_otp;

  /// No description provided for @technical_support_tap.
  ///
  /// In en, this message translates to:
  /// **'Technical Support Tap '**
  String get technical_support_tap;

  /// No description provided for @technical_support_icon.
  ///
  /// In en, this message translates to:
  /// **' Icon '**
  String get technical_support_icon;

  /// No description provided for @enter_your_email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enter_your_email;

  /// No description provided for @recieve_your_six_digit_code_change_password.
  ///
  /// In en, this message translates to:
  /// **'You\'ll recieve a 6 digit code to verify and proceed to changing password'**
  String get recieve_your_six_digit_code_change_password;

  /// No description provided for @recieve_your_six_digit_code_proceed.
  ///
  /// In en, this message translates to:
  /// **'You\'ll recieve a 6 digit code to verify and proceed'**
  String get recieve_your_six_digit_code_proceed;

  /// No description provided for @tap_register_to_agree.
  ///
  /// In en, this message translates to:
  /// **'By tapping \'Register\' you agree to '**
  String get tap_register_to_agree;

  /// No description provided for @term_condition_and_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions & Privacy Policy'**
  String get term_condition_and_privacy_policy;

  /// No description provided for @current_power_generation.
  ///
  /// In en, this message translates to:
  /// **'Current Power Generation'**
  String get current_power_generation;

  /// No description provided for @all_powerstations.
  ///
  /// In en, this message translates to:
  /// **'ALL POWERSTATIONS'**
  String get all_powerstations;

  /// No description provided for @total_plants.
  ///
  /// In en, this message translates to:
  /// **'Total Plants: '**
  String get total_plants;

  /// No description provided for @total_devices.
  ///
  /// In en, this message translates to:
  /// **'Total Devices: '**
  String get total_devices;

  /// No description provided for @total_alarms.
  ///
  /// In en, this message translates to:
  /// **'Total Alarms: '**
  String get total_alarms;

  /// No description provided for @total_output_power.
  ///
  /// In en, this message translates to:
  /// **'TOTAL OUTPUT POWER'**
  String get total_output_power;

  /// No description provided for @installed_capacity.
  ///
  /// In en, this message translates to:
  /// **'INSTALLED CAPACITY'**
  String get installed_capacity;

  /// No description provided for @msg_no_data.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get msg_no_data;

  /// No description provided for @power_today.
  ///
  /// In en, this message translates to:
  /// **'Power Today'**
  String get power_today;

  /// No description provided for @total_power.
  ///
  /// In en, this message translates to:
  /// **'Total Power'**
  String get total_power;

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

  /// No description provided for @reduce_co2_today.
  ///
  /// In en, this message translates to:
  /// **'Reduce CO2 Today'**
  String get reduce_co2_today;

  /// No description provided for @total_reduce_co2.
  ///
  /// In en, this message translates to:
  /// **'Total Reduce CO2'**
  String get total_reduce_co2;

  /// No description provided for @reduce_so2_today.
  ///
  /// In en, this message translates to:
  /// **'Reduce SO2 Today'**
  String get reduce_so2_today;

  /// No description provided for @total_reduce_so2.
  ///
  /// In en, this message translates to:
  /// **'Total Reduce SO2'**
  String get total_reduce_so2;

  /// No description provided for @coal_saved_today.
  ///
  /// In en, this message translates to:
  /// **'Coal Saved Today'**
  String get coal_saved_today;

  /// No description provided for @total_coal_saved.
  ///
  /// In en, this message translates to:
  /// **'Total Coal Saved'**
  String get total_coal_saved;

  /// No description provided for @powersation_information_updated.
  ///
  /// In en, this message translates to:
  /// **'Powersation information Updated'**
  String get powersation_information_updated;

  /// No description provided for @data_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Data Updated Successfully...'**
  String get data_updated_successfully;

  /// No description provided for @msg_no_record_found.
  ///
  /// In en, this message translates to:
  /// **'No Record Found...'**
  String get msg_no_record_found;

  /// No description provided for @msg_not_available.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get msg_not_available;

  /// No description provided for @power_station_owner.
  ///
  /// In en, this message translates to:
  /// **'Power station owner'**
  String get power_station_owner;

  /// No description provided for @manufacturer_account.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer account'**
  String get manufacturer_account;

  /// No description provided for @dealer.
  ///
  /// In en, this message translates to:
  /// **'Dealer'**
  String get dealer;

  /// No description provided for @group_account_number.
  ///
  /// In en, this message translates to:
  /// **'Group account number'**
  String get group_account_number;

  /// No description provided for @power_station_browsing_account.
  ///
  /// In en, this message translates to:
  /// **'Power station browsing account'**
  String get power_station_browsing_account;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @msg_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get msg_loading;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @account_security.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get account_security;

  /// No description provided for @interface_theme.
  ///
  /// In en, this message translates to:
  /// **'Interface theme'**
  String get interface_theme;

  /// No description provided for @contact_information.
  ///
  /// In en, this message translates to:
  /// **'Contact information'**
  String get contact_information;

  /// No description provided for @about_us.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get about_us;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @btn_add_installer.
  ///
  /// In en, this message translates to:
  /// **'Add Installer'**
  String get btn_add_installer;

  /// No description provided for @btn_signout.
  ///
  /// In en, this message translates to:
  /// **'SIGNOUT'**
  String get btn_signout;

  /// No description provided for @dialogue_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get dialogue_confirmation;

  /// No description provided for @dialogue_msg_signout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to signout?'**
  String get dialogue_msg_signout;

  /// No description provided for @dialogue_btn_cancle.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogue_btn_cancle;

  /// No description provided for @dialogue_btn_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get dialogue_btn_yes;

  /// No description provided for @btn_delete_acccount.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get btn_delete_acccount;

  /// No description provided for @dialogue_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get dialogue_delete_account;

  /// No description provided for @dialogue_msg_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get dialogue_msg_delete_account;

  /// No description provided for @dialogue_btn_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogue_btn_delete;

  /// No description provided for @version_text.
  ///
  /// In en, this message translates to:
  /// **'VERSION'**
  String get version_text;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @theme_red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get theme_red;

  /// No description provided for @theme_yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get theme_yellow;

  /// No description provided for @theme_green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get theme_green;

  /// No description provided for @theme_blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get theme_blue;

  /// No description provided for @theme_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply '**
  String get theme_apply;

  /// No description provided for @about_us_introduction.
  ///
  /// In en, this message translates to:
  /// **'Crown Micro has been serving with its varied IT & Power Products, since 1992 established as a robust and trustworthy name in the city Los Angeles, California, USA. The thriving and back-defending team is hustling to serve you with innovative, environment-friendly, and valuable products. Dedication, is the first thing we set into our products, to supply you with the best. Our progressive hard work pays off and in 2006 we teamed as a member of the well-known name SADITA Holding LTD but Crown Micro is maintained the legacy of being prosperous and to takeover more power, keep on working and aimed to spread it to some more additional parts of the globe.Therefore within 20 years of establishment Crown micro marked its name in the market the United Arab Emirates, Russia, Kazakhstan, Ukraine, China, Germany, Kingdom Of Saudi Arabia, Kuwait, Pakistan, Nigeria, Kenya, Tunisia, Syria, Lebanon, Iraq, Morocco, and Ghana. We are now in collaboration with more than 75 businesses around the globe and recognized as Crown Micro an international brand. Crown Micro owns quality products in each unit of technology including an immersive range of computers, mobile accessories, innovative solar inverters, AVR, UPS, Solar panels, and much more'**
  String get about_us_introduction;

  /// No description provided for @introduction.
  ///
  /// In en, this message translates to:
  /// **'INTRODUCTION'**
  String get introduction;

  /// No description provided for @company_name.
  ///
  /// In en, this message translates to:
  /// **'CROWN MICRO (PVT) LIMITED'**
  String get company_name;

  /// No description provided for @account_information.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get account_information;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @registerion_date.
  ///
  /// In en, this message translates to:
  /// **'Registerion Date'**
  String get registerion_date;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @tabs_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabs_home;

  /// No description provided for @tabs_plant.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get tabs_plant;

  /// No description provided for @tabs_device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get tabs_device;

  /// No description provided for @tabs_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get tabs_user;

  /// No description provided for @plant_information.
  ///
  /// In en, this message translates to:
  /// **'Plant Information'**
  String get plant_information;

  /// No description provided for @edit_plant.
  ///
  /// In en, this message translates to:
  /// **'EDIT PLANT'**
  String get edit_plant;

  /// No description provided for @delete_plant.
  ///
  /// In en, this message translates to:
  /// **'DELETE PLANT'**
  String get delete_plant;

  /// No description provided for @plant_name.
  ///
  /// In en, this message translates to:
  /// **'Plant Name'**
  String get plant_name;

  /// No description provided for @design_company.
  ///
  /// In en, this message translates to:
  /// **'Design Company'**
  String get design_company;

  /// No description provided for @installed_capacity_kw.
  ///
  /// In en, this message translates to:
  /// **'Installed Capacity(kW)'**
  String get installed_capacity_kw;

  /// No description provided for @annual_planned_power.
  ///
  /// In en, this message translates to:
  /// **'Annual Planned Power'**
  String get annual_planned_power;

  /// No description provided for @plant_establishment_date.
  ///
  /// In en, this message translates to:
  /// **'Plant establishment Date'**
  String get plant_establishment_date;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @district_county.
  ///
  /// In en, this message translates to:
  /// **'District (County)'**
  String get district_county;

  /// No description provided for @town.
  ///
  /// In en, this message translates to:
  /// **'Town'**
  String get town;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @timezone_space.
  ///
  /// In en, this message translates to:
  /// **'Timezone '**
  String get timezone_space;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @lattitude.
  ///
  /// In en, this message translates to:
  /// **'Lattitude'**
  String get lattitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @income_formula.
  ///
  /// In en, this message translates to:
  /// **'Income formula'**
  String get income_formula;

  /// No description provided for @capital_gain_unit.
  ///
  /// In en, this message translates to:
  /// **'Capital Gain Unit'**
  String get capital_gain_unit;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @capital_gain_currency.
  ///
  /// In en, this message translates to:
  /// **'Capital gains {currency}'**
  String capital_gain_currency(Object currency);

  /// No description provided for @standard_coal_saved.
  ///
  /// In en, this message translates to:
  /// **'Standard coal saved'**
  String get standard_coal_saved;

  /// No description provided for @co2_emission_reduction_kg.
  ///
  /// In en, this message translates to:
  /// **'CO2 emission reduction(kg)'**
  String get co2_emission_reduction_kg;

  /// No description provided for @so2_emission_reduction_kg.
  ///
  /// In en, this message translates to:
  /// **'SO2 emission reduction(kg)'**
  String get so2_emission_reduction_kg;

  /// No description provided for @update_plant_information.
  ///
  /// In en, this message translates to:
  /// **'UPDATE PLANT INFORMATION'**
  String get update_plant_information;

  /// No description provided for @msg_plant_info_updated.
  ///
  /// In en, this message translates to:
  /// **'Plant information updated successfully!'**
  String get msg_plant_info_updated;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirm_delete;

  /// No description provided for @btn_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btn_cancel;

  /// No description provided for @msg_plant_deleted.
  ///
  /// In en, this message translates to:
  /// **'Plant Deleted Successfully!'**
  String get msg_plant_deleted;

  /// No description provided for @are_you_sure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get are_you_sure;

  /// No description provided for @this_will_delete_plant.
  ///
  /// In en, this message translates to:
  /// **'This will Delete the Plant.'**
  String get this_will_delete_plant;

  /// No description provided for @all_type.
  ///
  /// In en, this message translates to:
  /// **'All Type'**
  String get all_type;

  /// No description provided for @inverter.
  ///
  /// In en, this message translates to:
  /// **'Inverter'**
  String get inverter;

  /// No description provided for @datalogger.
  ///
  /// In en, this message translates to:
  /// **'Datalogger'**
  String get datalogger;

  /// No description provided for @env_monitor.
  ///
  /// In en, this message translates to:
  /// **'Env-monitor'**
  String get env_monitor;

  /// No description provided for @smart_meters.
  ///
  /// In en, this message translates to:
  /// **'Smart meters'**
  String get smart_meters;

  /// No description provided for @energy_storage_machine.
  ///
  /// In en, this message translates to:
  /// **'Energy Storage Machine'**
  String get energy_storage_machine;

  /// No description provided for @all_types.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get all_types;

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

  /// No description provided for @fault.
  ///
  /// In en, this message translates to:
  /// **'Fault'**
  String get fault;

  /// No description provided for @standby.
  ///
  /// In en, this message translates to:
  /// **'Standby'**
  String get standby;

  /// No description provided for @alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// No description provided for @btn_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btn_add;

  /// No description provided for @parameter_error.
  ///
  /// In en, this message translates to:
  /// **'Parameter Error'**
  String get parameter_error;

  /// No description provided for @invalid_pn.
  ///
  /// In en, this message translates to:
  /// **'Invalid PN'**
  String get invalid_pn;

  /// No description provided for @error_system_exception.
  ///
  /// In en, this message translates to:
  /// **'Error System Exception'**
  String get error_system_exception;

  /// No description provided for @no_permissions_possible_reason_only_the_plant_owner_can_add.
  ///
  /// In en, this message translates to:
  /// **'No permissions (possible reason only the plant owner can add)'**
  String get no_permissions_possible_reason_only_the_plant_owner_can_add;

  /// No description provided for @power_station_not_found.
  ///
  /// In en, this message translates to:
  /// **'Power station not found'**
  String get power_station_not_found;

  /// No description provided for @signature_error.
  ///
  /// In en, this message translates to:
  /// **'Signature Error'**
  String get signature_error;

  /// No description provided for @datalogger_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Datalogger Added Successfully'**
  String get datalogger_added_successfully;

  /// No description provided for @enter_datalogger_name_and_pn_number.
  ///
  /// In en, this message translates to:
  /// **'Enter Datalogger Name and PN number'**
  String get enter_datalogger_name_and_pn_number;

  /// No description provided for @enter_datalogger_name.
  ///
  /// In en, this message translates to:
  /// **'Enter Datalogger Name'**
  String get enter_datalogger_name;

  /// No description provided for @enter_pn_number_14_digits.
  ///
  /// In en, this message translates to:
  /// **'Enter Pn Number ( 14 digits )'**
  String get enter_pn_number_14_digits;

  /// No description provided for @add_datalogger.
  ///
  /// In en, this message translates to:
  /// **'Add Datalogger'**
  String get add_datalogger;

  /// No description provided for @no_response_from_server.
  ///
  /// In en, this message translates to:
  /// **'No Response From Server'**
  String get no_response_from_server;

  /// No description provided for @device_not_found.
  ///
  /// In en, this message translates to:
  /// **'The Device Could Not Be Found'**
  String get device_not_found;

  /// No description provided for @collector_not_found.
  ///
  /// In en, this message translates to:
  /// **'The Collector Could Not Be Found'**
  String get collector_not_found;

  /// No description provided for @no_record_found.
  ///
  /// In en, this message translates to:
  /// **'No RECORD FOUND'**
  String get no_record_found;

  /// No description provided for @device_type.
  ///
  /// In en, this message translates to:
  /// **'DEVICE TYPE'**
  String get device_type;

  /// No description provided for @alias.
  ///
  /// In en, this message translates to:
  /// **'ALIAS: '**
  String get alias;

  /// No description provided for @address_upper.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS: '**
  String get address_upper;

  /// No description provided for @status_upper.
  ///
  /// In en, this message translates to:
  /// **'STATUS: '**
  String get status_upper;

  /// No description provided for @plant_upper.
  ///
  /// In en, this message translates to:
  /// **'PLANT: '**
  String get plant_upper;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load: {load}'**
  String load(Object load);

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @signal_upper.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL: '**
  String get signal_upper;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @mobile_no.
  ///
  /// In en, this message translates to:
  /// **'Mobile No.'**
  String get mobile_no;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @wifi_module_pn.
  ///
  /// In en, this message translates to:
  /// **'WiFi Module PN'**
  String get wifi_module_pn;

  /// No description provided for @password_does_not_match.
  ///
  /// In en, this message translates to:
  /// **'Password does not match.'**
  String get password_does_not_match;

  /// No description provided for @confirm_password_require.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password required'**
  String get confirm_password_require;

  /// No description provided for @enter_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Enter Confirm Password'**
  String get enter_confirm_password;

  /// No description provided for @datalogger_details.
  ///
  /// In en, this message translates to:
  /// **'Datalogger Details'**
  String get datalogger_details;

  /// No description provided for @datalogger_details_upper.
  ///
  /// In en, this message translates to:
  /// **'DATALOGGER DETAILS'**
  String get datalogger_details_upper;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @edit_alias.
  ///
  /// In en, this message translates to:
  /// **'EDIT ALIAS'**
  String get edit_alias;

  /// No description provided for @update_alias.
  ///
  /// In en, this message translates to:
  /// **'Update Alias'**
  String get update_alias;

  /// No description provided for @datalogger_deleted.
  ///
  /// In en, this message translates to:
  /// **'Datalogger Deleted.'**
  String get datalogger_deleted;

  /// No description provided for @alias_changed_sucessfully.
  ///
  /// In en, this message translates to:
  /// **'Alias Changed Successfully'**
  String get alias_changed_sucessfully;

  /// No description provided for @confirm_restart.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restart'**
  String get confirm_restart;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'RESTART'**
  String get restart;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @rebooting_datalogger.
  ///
  /// In en, this message translates to:
  /// **'Rebooting Datalogger'**
  String get rebooting_datalogger;

  /// No description provided for @instruction_issued_msg.
  ///
  /// In en, this message translates to:
  /// **'Instructions have been issued to the data collector'**
  String get instruction_issued_msg;

  /// No description provided for @instruction_failed_msg.
  ///
  /// In en, this message translates to:
  /// **'The instruction has failed, and the collector may be offline'**
  String get instruction_failed_msg;

  /// No description provided for @this_remove_datalogger_ps.
  ///
  /// In en, this message translates to:
  /// **'This will Remove the Datalogger from the Powerstation.'**
  String get this_remove_datalogger_ps;

  /// No description provided for @restart_collector.
  ///
  /// In en, this message translates to:
  /// **'Restart Collector'**
  String get restart_collector;

  /// No description provided for @sure_restart_device.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restart this device?'**
  String get sure_restart_device;

  /// No description provided for @enter_new_alias.
  ///
  /// In en, this message translates to:
  /// **'Enter New Alias'**
  String get enter_new_alias;

  /// No description provided for @current_alias.
  ///
  /// In en, this message translates to:
  /// **'Current Alias: {alias}'**
  String current_alias(Object alias);

  /// No description provided for @not_available.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get not_available;

  /// No description provided for @pn.
  ///
  /// In en, this message translates to:
  /// **'PN: '**
  String get pn;

  /// No description provided for @load_colon.
  ///
  /// In en, this message translates to:
  /// **'Load: '**
  String get load_colon;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description: '**
  String get description;

  /// No description provided for @signal.
  ///
  /// In en, this message translates to:
  /// **'Signal: '**
  String get signal;

  /// No description provided for @firmware_version.
  ///
  /// In en, this message translates to:
  /// **'Firmware version: : '**
  String get firmware_version;

  /// No description provided for @devices_under_equipment.
  ///
  /// In en, this message translates to:
  /// **'Devices Under This Equipment'**
  String get devices_under_equipment;

  /// No description provided for @device_type_colon.
  ///
  /// In en, this message translates to:
  /// **'DEVICE TYPE: '**
  String get device_type_colon;

  /// No description provided for @power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// No description provided for @time_hrs.
  ///
  /// In en, this message translates to:
  /// **'Time ( Hours )'**
  String get time_hrs;

  /// No description provided for @device_delete.
  ///
  /// In en, this message translates to:
  /// **'Device Deleted.'**
  String get device_delete;

  /// No description provided for @this_will_delete_device_data.
  ///
  /// In en, this message translates to:
  /// **'This will delete the device with all of its Data!'**
  String get this_will_delete_device_data;

  /// No description provided for @current_name.
  ///
  /// In en, this message translates to:
  /// **'Current name : ({alias})'**
  String current_name(Object alias);

  /// No description provided for @download_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get download_report;

  /// No description provided for @setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get setting;

  /// No description provided for @alarm_with_space.
  ///
  /// In en, this message translates to:
  /// **' Alarms '**
  String get alarm_with_space;

  /// No description provided for @alias_with_val.
  ///
  /// In en, this message translates to:
  /// **'Alias: {alias}'**
  String alias_with_val(Object alias);

  /// No description provided for @diagram.
  ///
  /// In en, this message translates to:
  /// **'Diagram'**
  String get diagram;

  /// No description provided for @realtime_status.
  ///
  /// In en, this message translates to:
  /// **'Realtime Status'**
  String get realtime_status;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @fetching_data.
  ///
  /// In en, this message translates to:
  /// **'Fetching data '**
  String get fetching_data;

  /// No description provided for @device_offline.
  ///
  /// In en, this message translates to:
  /// **'DEVICE OFFLINE'**
  String get device_offline;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @requesting_data.
  ///
  /// In en, this message translates to:
  /// **'Requesting Data...'**
  String get requesting_data;

  /// No description provided for @current_batt_voltage.
  ///
  /// In en, this message translates to:
  /// **'Current Battery Voltage'**
  String get current_batt_voltage;

  /// No description provided for @current_power.
  ///
  /// In en, this message translates to:
  /// **'Current Power'**
  String get current_power;

  /// No description provided for @year_power.
  ///
  /// In en, this message translates to:
  /// **'Year Power'**
  String get year_power;

  /// No description provided for @month_power.
  ///
  /// In en, this message translates to:
  /// **'Month Power'**
  String get month_power;

  /// No description provided for @device_param_analysis.
  ///
  /// In en, this message translates to:
  /// **'Device Parameters Data Analysis'**
  String get device_param_analysis;

  /// No description provided for @battery_capacity.
  ///
  /// In en, this message translates to:
  /// **'BATTERY CAPACITY'**
  String get battery_capacity;

  /// No description provided for @battery_voltage.
  ///
  /// In en, this message translates to:
  /// **'CURRENT BATTERY VOLTAGE: '**
  String get battery_voltage;

  /// No description provided for @charging_status.
  ///
  /// In en, this message translates to:
  /// **'CHARGING STATUS: '**
  String get charging_status;

  /// No description provided for @data_control.
  ///
  /// In en, this message translates to:
  /// **'Data Control>'**
  String get data_control;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @failed_no_device.
  ///
  /// In en, this message translates to:
  /// **'failed (no device protocol)'**
  String get failed_no_device;

  /// No description provided for @device_could_not_found.
  ///
  /// In en, this message translates to:
  /// **'THE DEVICE COULD NOT BE FOUND'**
  String get device_could_not_found;

  /// No description provided for @alarm_management.
  ///
  /// In en, this message translates to:
  /// **'Alarm Management>'**
  String get alarm_management;

  /// No description provided for @total_alarms_heading.
  ///
  /// In en, this message translates to:
  /// **'Total Alarms'**
  String get total_alarms_heading;

  /// No description provided for @alarm_today.
  ///
  /// In en, this message translates to:
  /// **'Alarms Today'**
  String get alarm_today;

  /// No description provided for @alarm_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Alarms Yesterday'**
  String get alarm_yesterday;

  /// No description provided for @alarm_week.
  ///
  /// In en, this message translates to:
  /// **'\'Alarms in a Week'**
  String get alarm_week;

  /// No description provided for @alarm_month.
  ///
  /// In en, this message translates to:
  /// **'Alarms in a Month'**
  String get alarm_month;

  /// No description provided for @alarm_year.
  ///
  /// In en, this message translates to:
  /// **'Alarms in a Year'**
  String get alarm_year;

  /// No description provided for @alarm_deleted.
  ///
  /// In en, this message translates to:
  /// **'ALARM DELETED'**
  String get alarm_deleted;

  /// No description provided for @delete_alarm.
  ///
  /// In en, this message translates to:
  /// **'Delete Alarm'**
  String get delete_alarm;

  /// No description provided for @no_permission_to_operate_power_station.
  ///
  /// In en, this message translates to:
  /// **'No permission (You do not have permission to operate the power station)'**
  String get no_permission_to_operate_power_station;

  /// No description provided for @device_alarm_not_found.
  ///
  /// In en, this message translates to:
  /// **'DEVICE ALARM NOT FOUND'**
  String get device_alarm_not_found;

  /// No description provided for @this_will_remove_alarm_list.
  ///
  /// In en, this message translates to:
  /// **' This will remove the Alarm from the Alarm list.'**
  String get this_will_remove_alarm_list;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// No description provided for @untreated.
  ///
  /// In en, this message translates to:
  /// **'Untreated'**
  String get untreated;

  /// No description provided for @device_pn.
  ///
  /// In en, this message translates to:
  /// **'Device PN: '**
  String get device_pn;

  /// No description provided for @occurence_time.
  ///
  /// In en, this message translates to:
  /// **'Occurence time: '**
  String get occurence_time;

  /// No description provided for @warning_upper.
  ///
  /// In en, this message translates to:
  /// **'WARNING'**
  String get warning_upper;

  /// No description provided for @error_upper.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get error_upper;

  /// No description provided for @fault_upper.
  ///
  /// In en, this message translates to:
  /// **'FAULT'**
  String get fault_upper;

  /// No description provided for @offline_upper.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get offline_upper;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password;

  /// No description provided for @enter_new_password.
  ///
  /// In en, this message translates to:
  /// **'Enter New Password'**
  String get enter_new_password;
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
    'that was used.',
  );
}
