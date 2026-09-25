# Voice Assistant

A Flutter application showcasing a voice assistant integrated with Android Native APIs (AccessibilityService & Foreground Service) for complex command execution.

## Background Execution & Battery Optimization

On Android devices, especially those from manufacturers with aggressive battery management (like Xiaomi, Samsung, Huawei, Oppo, Vivo), continuous background operations may be killed by the OS even if a Foreground Service is active.

To ensure continuous uninterrupted voice command execution (e.g. "Swipe 100 times") when the app is minimized, the user may need to manually exempt the app from battery optimizations.

### Xiaomi (MIUI)
1. Go to **Settings > Apps > Manage Apps > Voice Assistant**.
2. Turn on **Autostart**.
3. Go to **Battery saver** and set it to **No restrictions**.

### Samsung (One UI)
1. Go to **Settings > Apps > Voice Assistant**.
2. Tap on **Battery** and select **Unrestricted**.

### Stock Android
1. Go to **Settings > Apps > Voice Assistant**.
2. Tap **App battery usage** and select **Unrestricted**.

If these permissions are not granted, the Foreground Service may still be killed shortly after the screen turns off or the app is moved to the background.
