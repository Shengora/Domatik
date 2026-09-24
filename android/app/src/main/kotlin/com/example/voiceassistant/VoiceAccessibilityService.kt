package com.example.voiceassistant

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import kotlinx.coroutines.*

class VoiceAccessibilityService : AccessibilityService() {
    companion object {
        var instance: VoiceAccessibilityService? = null
    }

    private var swipeJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main)

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("VoiceAccessService", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for now
    }

    override fun onInterrupt() {
        // Not needed
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instance = null
        stopSwiping()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSwiping()
        serviceScope.cancel()
    }

    fun stopSwiping() {
        swipeJob?.cancel()
        swipeJob = null
        Log.d("VoiceAccessService", "Swiping stopped")
    }

    fun performSwipe(direction: String, count: Int = 1) {
        stopSwiping() // Stop any ongoing swipe

        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels.toFloat()
        val screenHeight = displayMetrics.heightPixels.toFloat()

        val startX = screenWidth / 2
        val startY = screenHeight / 2
        val endX = startX

        var targetY = startY
        if (direction == "up") { // Gesture up means scrolling down
            targetY = startY - (screenHeight / 3)
        } else if (direction == "down") {
            targetY = startY + (screenHeight / 3)
        }

        swipeJob = serviceScope.launch {
            for (i in 0 until count) {
                if (!isActive) break

                val path = Path()
                path.moveTo(startX, startY)
                path.lineTo(endX, targetY)

                val gestureBuilder = GestureDescription.Builder()
                gestureBuilder.addStroke(GestureDescription.StrokeDescription(path, 0, 500))

                dispatchGesture(gestureBuilder.build(), object : GestureResultCallback() {
                    override fun onCompleted(gestureDescription: GestureDescription?) {
                        super.onCompleted(gestureDescription)
                        Log.d("VoiceAccessService", "Swipe completed")
                    }

                    override fun onCancelled(gestureDescription: GestureDescription?) {
                        super.onCancelled(gestureDescription)
                        Log.d("VoiceAccessService", "Swipe cancelled")
                    }
                }, null)

                delay(700) // 700 ms pause between swipes
            }
        }
    }
}
