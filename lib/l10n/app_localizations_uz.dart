// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Ovozli Yordamchi';

  @override
  String get microphoneButtonLabel => 'Gapiring';

  @override
  String get permissionsRequired =>
      'Ilova ishlashi uchun barcha ruxsatlarni berishingiz kerak.';

  @override
  String get microphonePermission => 'Mikrofon';

  @override
  String get contactsPermission => 'Kontaktlar';

  @override
  String get phonePermission => 'Qo\'ng\'iroq';

  @override
  String get accessibilityPermission => 'Maxsus Imkoniyatlar (Accessibility)';

  @override
  String get openSettings => 'Sozlamalarni ochish';

  @override
  String get grantPermission => 'Ruxsat berish';

  @override
  String get overlayPermission => 'Boshqa ilovalar ustida chizish';

  @override
  String get continueButton => 'Davom etish';

  @override
  String callConfirmation(String name) {
    return '${name}ga qo\'ng\'iroq qilaymi?';
  }

  @override
  String get yes => 'Ha';

  @override
  String get no => 'Yo\'q';

  @override
  String get notUnderstood => 'Tushunmadim';

  @override
  String get listening => 'Eshitmoqhaman...';

  @override
  String get statusReady => 'Tayyor';

  @override
  String get foregroundServiceRunning => 'Ovozli yordamchi ishlamoqda';
}
