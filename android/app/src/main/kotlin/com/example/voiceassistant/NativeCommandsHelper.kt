package com.example.voiceassistant

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract

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
}