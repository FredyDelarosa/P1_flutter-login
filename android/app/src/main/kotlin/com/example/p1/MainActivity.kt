package com.example.p1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.p1/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isAdbEnabled") {
                val adbEnabled = isAdbEnabled()
                result.success(adbEnabled)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isAdbEnabled(): Boolean {
        return try {
            val adb = Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0)
            adb > 0
        } catch (e: Exception) {
            false
        }
    }
}

