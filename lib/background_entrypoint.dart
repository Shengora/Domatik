import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:voice_assistant/core/command_parser.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();

  const platform = MethodChannel('com.example.voiceassistant/overlay_channel');

  platform.setMethodCallHandler((call) async {
    if (call.method == 'parseCommand') {
      final String text = call.arguments['text'];
      final String localeCode = call.arguments['localeCode'];

      try {
        final result = CommandParser.parse(text, localeCode);
        return result;
      } catch (e) {
        return {'action': 'unknown', 'params': {}};
      }
    }
    return null;
  });
}
