import 'dart:io';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.voiceassistant/channel');
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  String _localeId = 'uz_UZ';
  final List<String> _history = [];
  bool _isOverlayEnabled = false;

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
    WidgetsBinding.instance.addObserver(this);
    _loadOverlayState();
  }

  void _loadOverlayState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOverlayEnabled = prefs.getBool('overlay_enabled') ?? false;
    });
    if (_isOverlayEnabled) {
      _startOverlay();
    }
  }

  void _toggleOverlay(bool value) async {
    setState(() {
      _isOverlayEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('overlay_enabled', value);

    if (value) {
      _startOverlay();
    } else {
      _stopOverlay();
    }
  }

  void _startOverlay() async {
    try {
      final bool? hasPermission = await platform.invokeMethod('canDrawOverlays');
      if (hasPermission == true) {
        await platform.invokeMethod('startOverlayService');
        debugPrint("Overlay service started");
      } else {
        debugPrint("Missing overlay permissions.");
        // Try to request permission natively via the settings intent
        try {
          await platform.invokeMethod('requestOverlayPermission');
        } catch (_) {}

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Ruxsat berilgach, tugmani qayta yoqing.")),
           );
           setState(() {
             _isOverlayEnabled = false;
           });
           final prefs = await SharedPreferences.getInstance();
           await prefs.setBool('overlay_enabled', false);
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to start overlay: '${e.message}'.");
      if (mounted) {
         setState(() {
           _isOverlayEnabled = false;
         });
      }
    }
  }

  void _stopOverlay() async {
    try {
      await platform.invokeMethod('stopOverlayService');
      debugPrint("Overlay service stopped");
    } on PlatformException catch (e) {
      debugPrint("Failed to stop overlay: '${e.message}'.");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _startForegroundIfNeeded();
    } else if (state == AppLifecycleState.resumed) {
      _stopForegroundService();
    }
  }

  void _startForegroundIfNeeded() async {
    try {
      final l10n = AppLocalizations.of(context);
      final text = l10n?.foregroundServiceRunning ?? "Voice Assistant is running";
      await platform.invokeMethod('startForegroundIfNeeded', {
        'title': l10n?.appTitle ?? 'Voice Assistant',
        'text': text,
      });
      debugPrint("Checked if Foreground service is needed.");
    } on PlatformException catch (e) {
      debugPrint("Failed to start foreground service conditionally: '${e.message}'.");
    }
  }

  void _stopForegroundService() async {
    try {
      await platform.invokeMethod('stopForegroundService');
      debugPrint("Foreground service stopped (App resumed).");
    } on PlatformException catch (e) {
      debugPrint("Failed to stop foreground service: '${e.message}'.");
    }
  }

  Map<String, dynamic>? _pendingAction;

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  void _listen({bool forceOnline = false}) async {
    debugPrint('Mic button pressed: forceOnline=$forceOnline, _isListening=$_isListening');

    if (forceOnline) {
      debugPrint('Checking internet connection for online fallback...');
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        debugPrint('No internet connection available. Aborting online fallback.');
        if (mounted) setState(() => _isListening = false);
        _addToHistory("Xatolik", "Internet aloqasi yo'q, online tanish ishlamaydi.");
        return;
      }
    }

    if (!_isListening || forceOnline) { // Allow starting if we are explicitly forcing online
      debugPrint('Initializing SpeechToText...');
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('SpeechToText Status: $status (forceOnline=$forceOnline)');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            if (_text.isNotEmpty && _speech.isNotListening) {
               // The STT stopped naturally (e.g. timeout or silence). Process what we have.
               _processCommand(_text);
               _text = '';
            } else if (_text.isEmpty && _speech.isNotListening) {
               debugPrint('SpeechToText stopped silently without recognizing any text.');
               // We only want to log it for now to avoid spam, unless debugging requires it
            }
          }
        },
        onError: (errorNotification) async {
          debugPrint('SpeechToText Error: ${errorNotification.errorMsg} (forceOnline=$forceOnline)');

          if (errorNotification.errorMsg.contains('error_language_not_supported') || errorNotification.errorMsg.contains('language_not_supported') || errorNotification.errorMsg.contains('error_server_disconnected') || errorNotification.errorMsg.contains('error_speech_timeout')) {
             if (!forceOnline) {
                // Auto fallback to online recognition
                debugPrint('Falling back to online recognition due to offline package missing or server disconnect.');
                _addToHistory("Xabar", "Offline paket topilmadi, online rejimda ishlamoqda...");

                debugPrint('Canceling previous speech session...');
                try {
                  await _speech.cancel(); // Completely stop the previous session
                  debugPrint('Previous session canceled successfully.');
                } catch (e) {
                  debugPrint('Error canceling previous session: $e');
                }
                await Future.delayed(const Duration(milliseconds: 200)); // Small wait for plugin cleanup

                debugPrint('Starting new session with forceOnline=true');
                if (mounted) setState(() => _isListening = true); // Maintain UI listening state
                _listen(forceOnline: true);
                return;
             }
          }

          if (mounted) setState(() => _isListening = false);
          _addToHistory("Xatolik", "Mikrofon xatosi: ${errorNotification.errorMsg}");
        },
      );

      debugPrint('SpeechToText initialize available: $available');

      if (available) {
        if (mounted) {
          setState(() {
            _isListening = true;
            _text = '';
          });
        }

        debugPrint('Calling _speech.listen with onDevice: ${!forceOnline}');
        _speech.listen(
          onResult: (val) {
            debugPrint('SpeechToText Result: ${val.recognizedWords} (isFinal=${val.finalResult})');
            if (mounted) {
              setState(() {
                _text = val.recognizedWords;
              });
            }
            if (val.finalResult) {
              _processCommand(val.recognizedWords);
              _text = '';
            }
          },
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          localeId: _localeId,
          onDevice: !forceOnline, // Use onDevice only if not forced online
        );
      } else {
         debugPrint('SpeechToText is NOT available on this device.');
         _addToHistory("Xatolik", "Bu qurilmada nutqni tanish xizmati topilmadi yoki cheklangan. Google ilovasi o'rnatilganini va ruxsat berilganini tekshiring.");
         if (mounted) setState(() => _isListening = false);
      }
    } else {
      debugPrint('Stopping SpeechToText manually...');
      if (mounted) setState(() => _isListening = false);
      try {
        _speech.stop();
      } catch (e) {
        debugPrint('Error stopping manually: $e');
      }
      if (_text.isNotEmpty) {
        _processCommand(_text);
        _text = '';
      }
    }
  }

  void _processCommand(String text) async {
    if (text.isEmpty) return;

    final lowerText = text.toLowerCase().trim();

    // Check if we are waiting for a confirmation (state machine)
    if (_pendingAction != null) {
      if (lowerText == 'ha' || lowerText == 'yes' || lowerText == 'да') {
        _addToHistory(text, AppLocalizations.of(context)!.actionConfirmed);
        _executeCommandNative(text, _pendingAction!);
      } else {
        _addToHistory(text, AppLocalizations.of(context)!.actionCancelled);
      }
      _pendingAction = null;
      return;
    }

    final command = CommandParser.parse(text, _localeId.split('_')[0]);

    if (command['action'] == 'unknown') {
      _addToHistory(text, AppLocalizations.of(context)!.notUnderstood);
      return;
    } else if (command['action'] == 'unknown_time') {
      _addToHistory(text, AppLocalizations.of(context)!.unknownTime);
      return;
    }

    if (command['action'] == 'call') {
      final name = command['params']['name'];
      _pendingAction = command;
      _addToHistory(text, AppLocalizations.of(context)!.callConfirmationVoice(name));
    } else if (command['action'] == 'sms') {
      final name = command['params']['name'];
      final message = command['params']['message'];
      _pendingAction = command;
      _addToHistory(text, AppLocalizations.of(context)!.smsConfirmationVoice(name, message));
    } else {
      _executeCommandNative(text, command);
    }
  }

  void _executeCommandNative(String originalText, Map<String, dynamic> command) async {
    try {
      final result = await platform.invokeMethod('executeCommand', command);
      if (result is Map) {
        // Successful match might return exact matched name
        if (command['action'] == 'call' || command['action'] == 'sms') {
           final matchedName = result['matchedName'] ?? command['params']['name'];
           _addToHistory(originalText, "Bajarildi: $matchedName");
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
          Row(
            children: [
              const Icon(Icons.bubble_chart),
              Switch(
                value: _isOverlayEnabled,
                onChanged: _toggleOverlay,
                activeColor: Colors.white,
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'offline_settings') {
                try {
                  await platform.invokeMethod('openVoiceSettings');
                } on PlatformException catch (e) {
                  debugPrint("Failed to open voice settings: '${e.message}'.");
                }
              } else {
                setState(() {
                  _localeId = value;
                  String langCode = value.split('_')[0];
                  MyApp.setLocale(context, Locale(langCode));
                });
              }
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
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'offline_settings',
                child: Text(AppLocalizations.of(context)!.offlineSettingsButton),
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
