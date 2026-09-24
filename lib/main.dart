import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:voice_assistant/l10n/app_localizations.dart';
import 'package:voice_assistant/onboarding_screen.dart';
import 'package:voice_assistant/core/command_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatefulWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Assistant',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz'),
        Locale('ru'),
        Locale('en'),
      ],
      home: widget.onboardingCompleted ? const MainScreen() : OnboardingScreen(
        onComplete: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const platform = MethodChannel('com.example.voiceassistant/channel');
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  String _localeId = 'uz_UZ';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              if (_speech.isNotListening || val.finalResult) {
                _processCommand(_text);
              }
            }
          }),
          localeId: _localeId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _processCommand(_text);
    }
  }

  void _processCommand(String text) async {
    if (text.isEmpty) return;

    final command = CommandParser.parse(text);

    if (command['action'] == 'unknown') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notUnderstood)),
        );
      }
      return;
    }

    if (command['action'] == 'call') {
      final name = command['params']['name'];
      _showCallConfirmationDialog(name);
    } else {
      _executeCommandNative(command);
    }
  }

  void _showCallConfirmationDialog(String name) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.callConfirmation(name)),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.no),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.yes),
              onPressed: () {
                Navigator.of(context).pop();
                _executeCommandNative({"action": "call", "params": {"name": name}});
              },
            ),
          ],
        );
      },
    );
  }

  void _executeCommandNative(Map<String, dynamic> command) async {
    try {
      await platform.invokeMethod('executeCommand', command);
    } on PlatformException catch (e) {
      debugPrint("Failed to execute command: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _localeId = value;
                String langCode = value.split('_')[0];
                MyApp.setLocale(context, Locale(langCode));
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'uz_UZ',
                child: Text('O\'zbek'),
              ),
              const PopupMenuItem<String>(
                value: 'ru_RU',
                child: Text('Русский'),
              ),
              const PopupMenuItem<String>(
                value: 'en_US',
                child: Text('English'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _text.isNotEmpty ? _text : (_isListening ? l10n.listening : l10n.statusReady),
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _listen,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(40),
                backgroundColor: _isListening ? Colors.red : Colors.blue,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 50,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
