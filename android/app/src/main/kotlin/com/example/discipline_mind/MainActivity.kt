package com.discipline.mind

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.discipline_mind/app_lifecycle"
        private const val SMS_METHOD_CHANNEL = "sms_consent/method"
        private const val SMS_EVENT_CHANNEL = "sms_consent/event"
        private const val SMS_CONSENT_REQUEST = 200
    }

    private var appBlockPlugin: AppBlockPlugin? = null

    private var smsEventSink: EventChannel.EventSink? = null
    private var smsReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appBlockPlugin = AppBlockPlugin(this)
        appBlockPlugin!!.attachTo(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hideBlockOverlay") {
                val intent = Intent().apply {
                    setClassName(this@MainActivity, "com.discipline.mind.AppBlockingService")
                    action = "HIDE_OVERLAY"
                }
                startService(intent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        // ==================== SMS USER CONSENT ====================
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        startSmsRetriever()
                        result.success(null)
                    }
                    "stopListening" -> {
                        unregisterSmsReceiver()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    smsEventSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    smsEventSink = null
                }
            })
    }

    private fun startSmsRetriever() {
        val client = SmsRetriever.getClient(this)
        val task = client.startSmsUserConsent(null)

        task.addOnSuccessListener {
            registerSmsReceiver()
        }
        task.addOnFailureListener { e ->
            smsEventSink?.error("START_FAILED", e.message, null)
        }
    }

    private fun registerSmsReceiver() {
        unregisterSmsReceiver()

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (SmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {
                    val extras = intent.extras
                    val status = extras?.get(SmsRetriever.EXTRA_STATUS) as? Status

                    when (status?.statusCode) {
                        CommonStatusCodes.SUCCESS -> {
                            val consentIntent =
                                extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                            try {
                                consentIntent?.let {
                                    startActivityForResult(it, SMS_CONSENT_REQUEST)
                                }
                            } catch (e: Exception) {
                                smsEventSink?.error("LAUNCH_FAILED", e.message, null)
                            }
                        }
                        CommonStatusCodes.TIMEOUT -> {
                            smsEventSink?.error("TIMEOUT", "SMS का इंतज़ार खत्म (5 min)", null)
                        }
                    }
                }
            }
        }

        val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(smsReceiver, filter)
        }
    }

    private fun unregisterSmsReceiver() {
        smsReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        smsReceiver = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SMS_CONSENT_REQUEST) {
            if (resultCode == RESULT_OK && data != null) {
                val message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)
                smsEventSink?.success(message)
            } else {
                smsEventSink?.error("USER_DENIED", "User ने dialog पर Deny/Cancel किया", null)
            }
        }
    }

    override fun onDestroy() {
        unregisterSmsReceiver()
        super.onDestroy()
    }
}