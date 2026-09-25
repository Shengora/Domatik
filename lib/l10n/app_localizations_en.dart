// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Voice Assistant';

  @override
  String get microphoneButtonLabel => 'Speak';

  @override
  String get permissionsRequired =>
      'You need to grant all permissions for the app to work.';

  @override
  String get microphonePermission => 'Microphone';

  @override
  String get contactsPermission => 'Contacts';

  @override
  String get phonePermission => 'Phone Call';

  @override
  String get smsPermission => 'Send SMS';

  @override
  String get accessibilityPermission => 'Accessibility';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get grantPermission => 'Grant';

  @override
  String get overlayPermission => 'Display over other apps';

  @override
  String get writeSettingsPermission => 'Modify system settings (Brightness)';

  @override
  String get continueButton => 'Continue';

  @override
  String callConfirmationVoice(String name) {
    return 'Should I call $name? (Yes/No)';
  }

  @override
  String smsConfirmationVoice(String name, String message) {
    return 'Should I send \'$message\' to $name? (Yes/No)';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get actionConfirmed => 'Confirmed.';

  @override
  String get actionCancelled => 'Cancelled.';

  @override
  String get unknownTime =>
      'I couldn\'t understand the time. Try \'wake me at 7:30\'.';

  @override
  String get notUnderstood => 'I didn\'t understand';

  @override
  String get listening => 'Listening...';

  @override
  String get statusReady => 'Ready';

  @override
  String get foregroundServiceRunning => 'Voice Assistant is running';

  @override
  String get offlineRecommendation =>
      'For faster and more reliable recognition without the internet, please download an offline speech package from your device settings.';

  @override
  String get offlineSettingsButton => 'Offline Speech Settings';
}
