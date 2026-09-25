import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const platform = MethodChannel('com.example.voiceassistant/channel');

  bool _micGranted = false;
  bool _contactsGranted = false;
  bool _phoneGranted = false;
  bool _accessibilityGranted = false;
  bool _overlayGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    final contactsStatus = await Permission.contacts.status;
    final phoneStatus = await Permission.phone.status;

    bool accessibilityStatus = false;
    try {
      debugPrint("OnboardingScreen: Calling isAccessibilityEnabled native method...");
      final startTime = DateTime.now();

      final bool? result = await platform.invokeMethod<bool>('isAccessibilityEnabled').timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint("OnboardingScreen: isAccessibilityEnabled timed out after 3 seconds.");
          return false;
        },
      );

      final endTime = DateTime.now();
      debugPrint("OnboardingScreen: isAccessibilityEnabled returned $result, took ${endTime.difference(startTime).inMilliseconds} ms.");

      accessibilityStatus = result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check accessibility: '${e.message}'.");
    } catch (e) {
      debugPrint("Unexpected error during accessibility check: $e");
    }

    bool overlayStatus = false;
    try {
      final bool? result = await platform.invokeMethod<bool>('canDrawOverlays');
      overlayStatus = result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check overlay permission: '${e.message}'.");
    }

    setState(() {
      _micGranted = micStatus.isGranted;
      _contactsGranted = contactsStatus.isGranted;
      _phoneGranted = phoneStatus.isGranted;
      _accessibilityGranted = accessibilityStatus;
      _overlayGranted = overlayStatus;
    });

    debugPrint("OnboardingScreen Permissions -> Mic: $_micGranted, Contacts: $_contactsGranted, Phone: $_phoneGranted, Accessibility: $_accessibilityGranted, Overlay: $_overlayGranted");
  }

  Future<void> _requestMicrophone() async {
    final status = await Permission.microphone.request();
    setState(() {
      _micGranted = status.isGranted;
    });
  }

  Future<void> _requestContacts() async {
    final status = await Permission.contacts.request();
    setState(() {
      _contactsGranted = status.isGranted;
    });
  }

  Future<void> _requestPhone() async {
    final status = await Permission.phone.request();
    setState(() {
      _phoneGranted = status.isGranted;
    });
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open accessibility settings: '${e.message}'.");
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      debugPrint("Failed to request overlay permission: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Consider accessibility and overlay as granted if explicitly enabled or allowed to bypass
    final coreGranted = _micGranted && _contactsGranted && _phoneGranted;
    final allGranted = coreGranted && _accessibilityGranted && _overlayGranted;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.permissionsRequired,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              title: l10n.microphonePermission,
              isGranted: _micGranted,
              onRequest: _requestMicrophone,
              buttonText: l10n.grantPermission,
            ),
            _buildPermissionItem(
              title: l10n.contactsPermission,
              isGranted: _contactsGranted,
              onRequest: _requestContacts,
              buttonText: l10n.grantPermission,
            ),
            _buildPermissionItem(
              title: l10n.phonePermission,
              isGranted: _phoneGranted,
              onRequest: _requestPhone,
              buttonText: l10n.grantPermission,
            ),
            _buildPermissionItem(
              title: l10n.accessibilityPermission,
              isGranted: _accessibilityGranted,
              onRequest: _openAccessibilitySettings,
              buttonText: l10n.openSettings,
            ),
            _buildPermissionItem(
              title: l10n.overlayPermission,
              isGranted: _overlayGranted,
              onRequest: _requestOverlayPermission,
              buttonText: l10n.openSettings,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: coreGranted
                    ? () async {
                        debugPrint("OnboardingScreen: Continue button pressed. Core permissions are true. Accessibility: $_accessibilityGranted, Overlay: $_overlayGranted");
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('onboarding_completed', true);
                          debugPrint("OnboardingScreen: Saved onboarding_completed = true. Calling widget.onComplete()...");
                          widget.onComplete();
                        } catch (e) {
                          debugPrint("OnboardingScreen: Error while saving prefs or calling onComplete: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Xatolik: $e")),
                            );
                          }
                        }
                      }
                    : null,
                child: Text(l10n.continueButton),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => _checkPermissions(),
                child: const Text("Yangilash / Обновить / Refresh"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required bool isGranted,
    required VoidCallback onRequest,
    required String buttonText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.error,
            color: isGranted ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (!isGranted)
            ElevatedButton(
              onPressed: onRequest,
              child: Text(buttonText),
            ),
        ],
      ),
    );
  }
}
