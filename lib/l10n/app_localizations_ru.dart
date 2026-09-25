// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Голосовой Помощник';

  @override
  String get microphoneButtonLabel => 'Говорите';

  @override
  String get permissionsRequired =>
      'Для работы приложения необходимо предоставить все разрешения.';

  @override
  String get microphonePermission => 'Микрофон';

  @override
  String get contactsPermission => 'Контакты';

  @override
  String get phonePermission => 'Телефон';

  @override
  String get smsPermission => 'Отправка СМС';

  @override
  String get accessibilityPermission => 'Спец. возможности (Accessibility)';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get grantPermission => 'Разрешить';

  @override
  String get overlayPermission => 'Поверх других приложений';

  @override
  String get writeSettingsPermission =>
      'Изменение системных настроек (Яркость)';

  @override
  String get continueButton => 'Продолжить';

  @override
  String callConfirmationVoice(String name) {
    return 'Позвонить $name? (Да/Нет)';
  }

  @override
  String smsConfirmationVoice(String name, String message) {
    return 'Отправить \'$message\' контакту $name? (Да/Нет)';
  }

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get actionConfirmed => 'Выполняю.';

  @override
  String get actionCancelled => 'Отменено.';

  @override
  String get unknownTime => 'Не понял время, скажите \'разбуди в 7:30\'.';

  @override
  String get notUnderstood => 'Я не понял';

  @override
  String get listening => 'Слушаю...';

  @override
  String get statusReady => 'Готов';

  @override
  String get foregroundServiceRunning => 'Голосовой Помощник работает';

  @override
  String get offlineRecommendation =>
      'Для более быстрого и надежного распознавания без интернета, загрузите оффлайн пакет речи в настройках устройства.';

  @override
  String get offlineSettingsButton => 'Оффлайн Пакет Речи';
}
