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
  String get accessibilityPermission => 'Accessibility';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get grantPermission => 'Grant';

  @override
  String get continueButton => 'Continue';

  @override
  String callConfirmation(String name) {
    return 'Call $name?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get notUnderstood => 'I didn\'t understand';

  @override
  String get listening => 'Listening...';

  @override
  String get statusReady => 'Ready';
}
