package com.discipline.mind

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.discipline_mind/app_lifecycle"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hideBlockOverlay") {
                val intent = Intent().apply {
                    setClassName(this@MainActivity, "com.block_app.AppBlockingService")
                    action = "HIDE_OVERLAY"
                }
                startService(intent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
