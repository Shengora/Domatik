import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

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
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ovozli Yordamchi'**
  String get appTitle;

  /// No description provided for @microphoneButtonLabel.
  ///
  /// In uz, this message translates to:
  /// **'Gapiring'**
  String get microphoneButtonLabel;

  /// No description provided for @permissionsRequired.
  ///
  /// In uz, this message translates to:
  /// **'Ilova ishlashi uchun barcha ruxsatlarni berishingiz kerak.'**
  String get permissionsRequired;

  /// No description provided for @microphonePermission.
  ///
  /// In uz, this message translates to:
  /// **'Mikrofon'**
  String get microphonePermission;

  /// No description provided for @contactsPermission.
  ///
  /// In uz, this message translates to:
  /// **'Kontaktlar'**
  String get contactsPermission;

  /// No description provided for @phonePermission.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'ng\'iroq'**
  String get phonePermission;

  /// No description provided for @accessibilityPermission.
  ///
  /// In uz, this message translates to:
  /// **'Maxsus Imkoniyatlar (Accessibility)'**
  String get accessibilityPermission;

  /// No description provided for @openSettings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalarni ochish'**
  String get openSettings;

  /// No description provided for @grantPermission.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsat berish'**
  String get grantPermission;

  /// No description provided for @overlayPermission.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa ilovalar ustida chizish'**
  String get overlayPermission;

  /// No description provided for @continueButton.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueButton;

  /// No description provided for @callConfirmation.
  ///
  /// In uz, this message translates to:
  /// **'{name}ga qo\'ng\'iroq qilaymi?'**
  String callConfirmation(String name);

  /// No description provided for @yes.
  ///
  /// In uz, this message translates to:
  /// **'Ha'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'q'**
  String get no;

  /// No description provided for @notUnderstood.
  ///
  /// In uz, this message translates to:
  /// **'Tushunmadim'**
  String get notUnderstood;

  /// No description provided for @listening.
  ///
  /// In uz, this message translates to:
  /// **'Eshitmoqhaman...'**
  String get listening;

  /// No description provided for @statusReady.
  ///
  /// In uz, this message translates to:
  /// **'Tayyor'**
  String get statusReady;

  /// No description provided for @foregroundServiceRunning.
  ///
  /// In uz, this message translates to:
  /// **'Ovozli yordamchi ishlamoqda'**
  String get foregroundServiceRunning;

  /// No description provided for @offlineRecommendation.
  ///
  /// In uz, this message translates to:
  /// **'Yaxshiroq va tezroq ishlashi (hamda internet talab qilmasligi) uchun telefon sozlamalaridan offline nutq paketini yuklab oling.'**
  String get offlineRecommendation;

  /// No description provided for @offlineSettingsButton.
  ///
  /// In uz, this message translates to:
  /// **'Offline Nutq Sozlamalari'**
  String get offlineSettingsButton;
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
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
