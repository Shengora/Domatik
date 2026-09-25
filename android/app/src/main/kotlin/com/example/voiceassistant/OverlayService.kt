package com.example.voiceassistant

import android.annotation.SuppressLint
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class OverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: LinearLayout
    private lateinit var bubbleIcon: ImageView
    private lateinit var statusText: TextView
    private lateinit var layoutParams: WindowManager.LayoutParams

    private lateinit var speechRecognizer: SpeechRecognizer
    private lateinit var nativeCommandsHelper: NativeCommandsHelper
    private lateinit var methodChannel: MethodChannel
    private var isListening = false

    companion object {
        const val ENGINE_ID = "voice_assistant_engine"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate() {
        super.onCreate()

        nativeCommandsHelper = NativeCommandsHelper(this)
        setupFlutterEngine()
        setupSpeechRecognizer()

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        overlayView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.TRANSPARENT)
        }

        statusText = TextView(this).apply {
            text = ""
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#88000000"))
            setPadding(10, 5, 10, 5)
            visibility = View.GONE
        }

        bubbleIcon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_btn_speak_now) // Default Android mic icon
            setBackgroundResource(android.R.drawable.btn_default)
            layoutParams = LinearLayout.LayoutParams(150, 150)
        }

        overlayView.addView(statusText)
        overlayView.addView(bubbleIcon)

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 100
        }

        windowManager.addView(overlayView, layoutParams)

        setupDragAndClick()
    }

    private fun setupFlutterEngine() {
        var flutterEngine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (flutterEngine == null) {
            val flutterLoader = io.flutter.FlutterInjector.instance().flutterLoader()
            if (!flutterLoader.initialized()) {
                flutterLoader.startInitialization(this)
                flutterLoader.ensureInitializationComplete(this, null)
            }
            flutterEngine = FlutterEngine(this)
            flutterEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    flutterLoader.findAppBundlePath(),
                    "overlayMain"
                )
            )
            FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
        }
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.voiceassistant/overlay_channel")
    }

    private fun setupSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                updateStatus("Listening...")
            }
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {
                updateStatus("Processing...")
            }
            override fun onError(error: Int) {
                updateStatus("Error: $error")
                isListening = false
                resetIcon()
                hideStatusDelayed()
            }
            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    val text = matches[0]
                    updateStatus("🗣: $text")
                    parseAndExecute(text)
                }
                isListening = false
                resetIcon()
            }
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }

    private fun updateStatus(msg: String) {
        statusText.text = msg
        statusText.visibility = View.VISIBLE
    }

    private fun resetIcon() {
        bubbleIcon.setBackgroundResource(android.R.drawable.btn_default)
    }

    private fun hideStatusDelayed() {
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            if (!isListening) statusText.visibility = View.GONE
        }, 3000)
    }

    private fun parseAndExecute(text: String) {
        // Assume default locale as 'uz' for overlay unless specified
        val locale = Locale.getDefault().language
        val localeCode = if (locale in listOf("uz", "ru", "en")) locale else "uz"

        methodChannel.invokeMethod("parseCommand", mapOf("text" to text, "localeCode" to localeCode), object : MethodChannel.Result {
            override fun success(result: Any?) {
                val command = result as? Map<String, Any> ?: return
                executeParsedCommand(command)
            }
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                updateStatus("Parse error")
                hideStatusDelayed()
            }
            override fun notImplemented() {
                updateStatus("Not implemented")
                hideStatusDelayed()
            }
        })
    }

    private fun executeParsedCommand(command: Map<String, Any>) {
        val action = command["action"] as? String
        val params = command["params"] as? Map<String, Any> ?: emptyMap()

        when (action) {
            "open_app" -> {
                val appName = params["appName"] as? String
                if (appName != null) {
                    val matchedApp = nativeCommandsHelper.openAppByName(appName)
                    if (matchedApp != null) {
                        updateStatus("Opened: $matchedApp")
                    } else {
                        updateStatus("App not found")
                    }
                }
            }
            "call" -> {
                val name = params["name"] as? String
                if (name != null) {
                    val contactInfo = nativeCommandsHelper.getPhoneNumberByName(name)
                    if (contactInfo != null) {
                        nativeCommandsHelper.makeCall(contactInfo.second)
                        updateStatus("Calling: ${contactInfo.first}")
                    } else {
                        updateStatus("Contact not found")
                    }
                }
            }
            "swipe" -> {
                val direction = params["direction"] as? String ?: "up"
                val count = params["count"] as? Int ?: 1
                VoiceAccessibilityService.instance?.performSwipe(direction, count)
                updateStatus("Swiping $direction")
            }
            "stop_swipe" -> {
                VoiceAccessibilityService.instance?.stopSwiping()
                updateStatus("Stopped swiping")
            }
            else -> {
                updateStatus("Action unknown")
            }
        }
        hideStatusDelayed()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupDragAndClick() {
        bubbleIcon.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f
            private var isMoved = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        isMoved = false
                        initialX = layoutParams.x
                        initialY = layoutParams.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - initialTouchX).toInt()
                        val dy = (event.rawY - initialTouchY).toInt()

                        if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                            isMoved = true
                            layoutParams.x = initialX + dx
                            layoutParams.y = initialY + dy
                            windowManager.updateViewLayout(overlayView, layoutParams)
                        }
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!isMoved) {
                            // It's a click!
                            if (isListening) {
                                speechRecognizer.stopListening()
                            } else {
                                startListening()
                            }
                        }
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun startListening() {
        isListening = true
        bubbleIcon.setBackgroundColor(Color.RED)
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
        }
        speechRecognizer.startListening(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer.destroy()
        if (::overlayView.isInitialized) {
            windowManager.removeView(overlayView)
        }
    }
}
