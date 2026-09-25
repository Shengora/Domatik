package com.example.voiceassistant

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract
import android.provider.Settings
import android.text.TextUtils
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.voiceassistant/channel"
    private lateinit var nativeCommandsHelper: NativeCommandsHelper

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeCommandsHelper = NativeCommandsHelper(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "canWriteSettings" -> {
                    result.success(android.provider.Settings.System.canWrite(this))
                }
                "requestWriteSettingsPermission" -> {
                    val intent = Intent(
                        android.provider.Settings.ACTION_MANAGE_WRITE_SETTINGS,
                        android.net.Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                }
                "openVoiceSettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_VOICE_INPUT_SETTINGS)
                        startActivity(intent)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_INPUT_METHOD_SETTINGS)
                            startActivity(intent)
                        } catch (e2: Exception) {
                            val intent = Intent(android.provider.Settings.ACTION_SETTINGS)
                            startActivity(intent)
                        }
                    }
                    result.success(true)
                }
                "isAccessibilityEnabled" -> {
                    val start = System.currentTimeMillis()
                    Log.d("VoiceAssistant", "isAccessibilityEnabled check started")
                    val isEnabled = isAccessibilityServiceEnabled()
                    Log.d("VoiceAssistant", "isAccessibilityEnabled check ended, took ${System.currentTimeMillis() - start}ms, result: $isEnabled")
                    result.success(isEnabled)
                }
                "startForegroundIfNeeded" -> {
                    val title = call.argument<String>("title") ?: "Voice Assistant"
                    val text = call.argument<String>("text") ?: "Running in background"

                    if (VoiceAccessibilityService.instance?.isSwipingActive() == true) {
                        Log.d("VoiceAssistant", "Swipe is active, starting ForegroundService")
                        val serviceIntent = Intent(this, ForegroundService::class.java).apply {
                            putExtra("title", title)
                            putExtra("text", text)
                        }
                        ContextCompat.startForegroundService(this, serviceIntent)
                        result.success(true)
                    } else {
                        Log.d("VoiceAssistant", "Swipe is not active, skipping ForegroundService")
                        result.success(false)
                    }
                }
                "stopForegroundService" -> {
                    val serviceIntent = Intent(this, ForegroundService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }
                "canDrawOverlays" -> {
                    result.success(android.provider.Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(
                        android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        android.net.Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                }
                "startOverlayService" -> {
                    if (android.provider.Settings.canDrawOverlays(this)) {
                        try {
                            val intent = Intent(this, OverlayService::class.java)
                            startService(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("VoiceAssistant", "Failed to start OverlayService", e)
                            result.error("SERVICE_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "stopOverlayService" -> {
                    val intent = Intent(this, OverlayService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "executeCommand" -> {
                    val command = call.arguments as Map<String, Any>
                    handleCommand(command, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun handleCommand(command: Map<String, Any>, result: MethodChannel.Result) {
        val action = command["action"] as? String
        val params = command["params"] as? Map<String, Any> ?: emptyMap()

        when (action) {
            "open_app" -> {
                val appName = params["appName"] as? String
                if (appName != null) {
                    val matchedApp = nativeCommandsHelper.openAppByName(appName)
                    if (matchedApp != null) {
                        result.success(mapOf("matchedApp" to matchedApp))
                    } else {
                        result.error("APP_NOT_FOUND", "Could not find app with name: $appName", null)
                    }
                } else {
                    result.error("INVALID_ARGS", "App name is required", null)
                }
            }
            "call" -> {
                val name = params["name"] as? String
                if (name != null) {
                    val contactInfo = nativeCommandsHelper.getPhoneNumberByName(name)
                    if (contactInfo != null) {
                        nativeCommandsHelper.makeCall(contactInfo.second)
                        result.success(mapOf("matchedName" to contactInfo.first))
                    } else {
                        result.error("CONTACT_NOT_FOUND", "Could not find contact: $name", null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Contact name is required", null)
                }
            }
            "swipe" -> {
                val direction = params["direction"] as? String ?: "up"
                val count = params["count"] as? Int ?: 1

                if (VoiceAccessibilityService.instance != null) {
                    VoiceAccessibilityService.instance?.performSwipe(direction, count)
                    result.success(true)
                } else {
                    result.error("SERVICE_NOT_RUNNING", "Accessibility Service is not running", null)
                }
            }
            "stop_swipe" -> {
                if (VoiceAccessibilityService.instance != null) {
                    VoiceAccessibilityService.instance?.stopSwiping()
                    result.success(true)
                } else {
                    result.error("SERVICE_NOT_RUNNING", "Accessibility Service is not running", null)
                }
            }
            "sms" -> {
                val name = params["name"] as? String
                val message = params["message"] as? String
                if (name != null && message != null) {
                    val contactInfo = nativeCommandsHelper.getPhoneNumberByName(name)
                    if (contactInfo != null) {
                        nativeCommandsHelper.sendSms(contactInfo.second, message)
                        result.success(mapOf("matchedName" to contactInfo.first))
                    } else {
                        result.error("CONTACT_NOT_FOUND", "Could not find contact: $name", null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Contact name and message are required", null)
                }
            }
            "control_wifi" -> {
                nativeCommandsHelper.controlWifi()
                result.success(true)
            }
            "control_bluetooth" -> {
                val turnOn = params["turnOn"] as? Boolean ?: true
                nativeCommandsHelper.controlBluetooth(turnOn)
                result.success(true)
            }
            "control_flashlight" -> {
                val turnOn = params["turnOn"] as? Boolean ?: true
                nativeCommandsHelper.controlFlashlight(turnOn)
                result.success(true)
            }
            "control_volume" -> {
                val stream = params["stream"] as? String ?: "music"
                val direction = params["direction"] as? String ?: "up"
                val level = params["level"] as? Int
                nativeCommandsHelper.controlVolume(stream, direction, level)
                result.success(true)
            }
            "control_brightness" -> {
                val direction = params["direction"] as? String ?: "up"
                val level = params["level"] as? Int
                nativeCommandsHelper.controlBrightness(direction, level)
                result.success(true)
            }
            "set_alarm" -> {
                val hour = params["hour"] as? Int ?: 7
                val minute = params["minute"] as? Int ?: 0
                nativeCommandsHelper.setAlarm(hour, minute)
                result.success(true)
            }
            "set_timer" -> {
                val minutes = params["minutes"] as? Int ?: 5
                nativeCommandsHelper.setTimer(minutes)
                result.success(true)
            }
            "web_search" -> {
                val query = params["query"] as? String ?: ""
                nativeCommandsHelper.webSearch(query)
                result.success(true)
            }
            else -> {
                result.error("UNKNOWN_ACTION", "Action not supported", null)
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        var accessibilityEnabled = 0
        val service = packageName + "/" + VoiceAccessibilityService::class.java.canonicalName
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                applicationContext.contentResolver,
                android.provider.Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            // Ignored
        }

        val mStringColonSplitter = TextUtils.SimpleStringSplitter(':')

        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                applicationContext.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                mStringColonSplitter.setString(settingValue)
                while (mStringColonSplitter.hasNext()) {
                    val accessibilityService = mStringColonSplitter.next()
                    if (accessibilityService.equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
