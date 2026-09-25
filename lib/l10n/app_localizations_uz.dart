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
  String get smsPermission => 'SMS Yuborish';

  @override
  String get accessibilityPermission => 'Maxsus Imkoniyatlar (Accessibility)';

  @override
  String get openSettings => 'Sozlamalarni ochish';

  @override
  String get grantPermission => 'Ruxsat berish';

  @override
  String get overlayPermission => 'Boshqa ilovalar ustida chizish';

  @override
  String get writeSettingsPermission =>
      'Tizim sozlamalarini o\'zgartirish (Yorqinlik)';

  @override
  String get continueButton => 'Davom etish';

  @override
  String callConfirmationVoice(String name) {
    return '${name}ga qo\'ng\'iroq qilaymi? (Ha/Yo\'q)';
  }

  @override
  String smsConfirmationVoice(String name, String message) {
    return '${name}ga \'$message\' deb yozaymi? (Ha/Yo\'q)';
  }

  @override
  String get yes => 'Ha';

  @override
  String get no => 'Yo\'q';

  @override
  String get actionConfirmed => 'Bajarilmoqda.';

  @override
  String get actionCancelled => 'Bekor qilindi.';

  @override
  String get unknownTime =>
      'Vaqtni tushunmadim, masalan \'7:30 da uyg\'ot\' deb ayting.';

  @override
  String get notUnderstood => 'Tushunmadim';

  @override
  String get listening => 'Eshitmoqhaman...';

  @override
  String get statusReady => 'Tayyor';

  @override
  String get foregroundServiceRunning => 'Ovozli yordamchi ishlamoqda';

  @override
  String get offlineRecommendation =>
      'Yaxshiroq va tezroq ishlashi (hamda internet talab qilmasligi) uchun telefon sozlamalaridan offline nutq paketini yuklab oling.';

  @override
  String get offlineSettingsButton => 'Offline Nutq Sozlamalari';
}
