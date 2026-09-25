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
  late bool _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _onboardingCompleted = widget.onboardingCompleted;
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void completeOnboarding() {
    setState(() {
      _onboardingCompleted = true;
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
      home: _onboardingCompleted ? const MainScreen() : OnboardingScreen(
        onComplete: completeOnboarding,
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
  final List<String> _history = [];

  void _addToHistory(String rawText, String result) {
    setState(() {
      _history.insert(0, "🗣: $rawText\n🤖: $result");
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Start Foreground Service to keep app alive in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startForegroundService();
    });
  }

  void _startForegroundService() async {
    try {
      final l10n = AppLocalizations.of(context);
      final text = l10n?.foregroundServiceRunning ?? "Voice Assistant is running";
      await platform.invokeMethod('startForegroundService', {
        'title': l10n?.appTitle ?? 'Voice Assistant',
        'text': text,
      });
      debugPrint("Foreground service started successfully.");
    } on PlatformException catch (e) {
      debugPrint("Failed to start foreground service: '${e.message}'.");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
            if (val.finalResult) {
              _processCommand(val.recognizedWords);
            }
          },
          localeId: _localeId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_text.isNotEmpty) {
        _processCommand(_text);
      }
    }
  }

  void _processCommand(String text) async {
    if (text.isEmpty) return;

    final command = CommandParser.parse(text, _localeId.split('_')[0]);

    if (command['action'] == 'unknown') {
      _addToHistory(text, AppLocalizations.of(context)!.notUnderstood);
      return;
    }

    if (command['action'] == 'call') {
      final name = command['params']['name'];
      _showCallConfirmationDialog(text, name);
    } else {
      _executeCommandNative(text, command);
    }
  }

  void _showCallConfirmationDialog(String originalText, String name) {
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
                _addToHistory(originalText, "Qo'ng'iroq bekor qilindi");
              },
            ),
            TextButton(
              child: Text(l10n.yes),
              onPressed: () {
                Navigator.of(context).pop();
                _executeCommandNative(originalText, {"action": "call", "params": {"name": name}});
              },
            ),
          ],
        );
      },
    );
  }

  void _executeCommandNative(String originalText, Map<String, dynamic> command) async {
    try {
      final result = await platform.invokeMethod('executeCommand', command);
      if (result is Map) {
        // Successful match might return exact matched name
        if (command['action'] == 'call') {
           final matchedName = result['matchedName'] ?? command['params']['name'];
           _addToHistory(originalText, "Qo'ng'iroq qilinmoqda: $matchedName");
        } else if (command['action'] == 'open_app') {
           final matchedApp = result['matchedApp'] ?? command['params']['appName'];
           _addToHistory(originalText, "Ochilmoqda: $matchedApp");
        } else {
           _addToHistory(originalText, "Bajarildi: ${command['action']}");
        }
      } else {
        _addToHistory(originalText, "Bajarildi: ${command['action']}");
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to execute command: '${e.message}'. Code: ${e.code}");
      String errorMessage = "Xatolik: ${e.message}";
      if (e.code == "APP_NOT_FOUND") {
        errorMessage = "Ilova topilmadi: ${command['params']['appName']}";
      } else if (e.code == "CONTACT_NOT_FOUND") {
        errorMessage = "Kontakt topilmadi: ${command['params']['name']}";
      }
      _addToHistory(originalText, errorMessage);
    } catch (e) {
      _addToHistory(originalText, "Xatolik yuz berdi");
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Show newest at the bottom, or false to show at top
              padding: const EdgeInsets.all(16.0),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _history[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text(
                  _text.isNotEmpty ? _text : (_isListening ? l10n.listening : l10n.statusReady),
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _listen,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(30),
                    backgroundColor: _isListening ? Colors.red : Colors.blue,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
