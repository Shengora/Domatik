package com.example.voiceassistant

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract
import android.provider.Settings
import android.telephony.SmsManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.provider.AlarmClock
import android.os.Build

class NativeCommandsHelper(private val context: Context) {

    fun openAppByName(appName: String): String? {
        val pm = context.packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        var bestMatch: android.content.pm.ApplicationInfo? = null
        var bestMatchLabel = ""

        for (app in packages) {
            val label = pm.getApplicationLabel(app).toString()
            // 1. Check exact match
            if (label.equals(appName, ignoreCase = true)) {
                val intent = pm.getLaunchIntentForPackage(app.packageName)
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    return label
                }
            }
            // 2. Check partial match (contains or startsWith)
            if (label.contains(appName, ignoreCase = true)) {
                if (bestMatch == null) {
                    val intent = pm.getLaunchIntentForPackage(app.packageName)
                    if (intent != null) {
                        bestMatch = app
                        bestMatchLabel = label
                    }
                }
            }
        }

        if (bestMatch != null) {
            val intent = pm.getLaunchIntentForPackage(bestMatch.packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                return bestMatchLabel
            }
        }

        return null
    }

    fun getPhoneNumberByName(name: String): Pair<String, String>? {
        var resultInfo: Pair<String, String>? = null
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )

        val cursor = context.contentResolver.query(uri, projection, null, null, null)

        if (cursor != null) {
            val nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

            while (cursor.moveToNext()) {
                val contactName = cursor.getString(nameIndex)
                val contactNumber = cursor.getString(numberIndex)

                if (contactName != null && contactName.contains(name, ignoreCase = true)) {
                    resultInfo = Pair(contactName, contactNumber)
                    break // Take the first match
                }
            }
            cursor.close()
        }
        return resultInfo
    }

    fun makeCall(phoneNumber: String) {
        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$phoneNumber")
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun sendSms(phoneNumber: String, message: String) {
        val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }
        smsManager.sendTextMessage(phoneNumber, null, message, null, null)
    }

    fun controlWifi() {
        val intent = Intent(Settings.Panel.ACTION_WIFI)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun controlBluetooth(turnOn: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+: Direct enable/disable is restricted. We must launch intent.
            val intent = if (turnOn) {
                Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            } else {
                Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } else {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val bluetoothAdapter = bluetoothManager.adapter
            if (turnOn) {
                @Suppress("DEPRECATION")
                bluetoothAdapter?.enable()
            } else {
                @Suppress("DEPRECATION")
                bluetoothAdapter?.disable()
            }
        }
    }

    fun controlFlashlight(turnOn: Boolean) {
        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList[0] // Typically the back camera
            cameraManager.setTorchMode(cameraId, turnOn)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun controlVolume(stream: String, direction: String, level: Int?) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val streamType = when (stream) {
            "ring" -> AudioManager.STREAM_RING
            "alarm" -> AudioManager.STREAM_ALARM
            else -> AudioManager.STREAM_MUSIC
        }

        when (direction) {
            "up" -> audioManager.adjustStreamVolume(streamType, AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI)
            "down" -> audioManager.adjustStreamVolume(streamType, AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI)
            "set" -> {
                if (level != null) {
                    val maxVolume = audioManager.getStreamMaxVolume(streamType)
                    // if user says "50", assume 50% if level > maxVolume
                    var targetLevel = level
                    if (targetLevel > maxVolume) {
                        targetLevel = (maxVolume * (level / 100.0)).toInt()
                    }
                    audioManager.setStreamVolume(streamType, targetLevel, AudioManager.FLAG_SHOW_UI)
                }
            }
        }
    }

    fun controlBrightness(direction: String, level: Int?) {
        if (!Settings.System.canWrite(context)) return

        try {
            // Ensure manual mode is set before changing brightness
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
            )

            val currentBrightness = Settings.System.getInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS
            )

            var targetBrightness = currentBrightness
            when (direction) {
                "up" -> targetBrightness = Math.min(255, currentBrightness + 25)
                "down" -> targetBrightness = Math.max(0, currentBrightness - 25)
                "set" -> {
                    if (level != null) {
                        // User specifies 0-100 percent typically
                        targetBrightness = if (level <= 100) {
                            (255 * (level / 100.0)).toInt()
                        } else {
                            Math.min(255, level)
                        }
                    }
                }
            }

            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                targetBrightness
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun setAlarm(hour: Int, minute: Int) {
        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
            putExtra(AlarmClock.EXTRA_HOUR, hour)
            putExtra(AlarmClock.EXTRA_MINUTES, minute)
            putExtra(AlarmClock.EXTRA_SKIP_UI, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun setTimer(minutes: Int) {
        val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
            putExtra(AlarmClock.EXTRA_LENGTH, minutes * 60)
            putExtra(AlarmClock.EXTRA_SKIP_UI, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun webSearch(query: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/search?q=${Uri.encode(query)}"))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}