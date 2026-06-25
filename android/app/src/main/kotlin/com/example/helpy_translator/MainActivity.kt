package com.example.helpy_translator

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "helpy_translator/background_execution"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    val title = call.argument<String>("title") ?: "Helpy Translator"
                    val message = call.argument<String>("message") ?: "Перевод выполняется в фоне"

                    val intent = Intent(this, AuditForegroundService::class.java).apply {
                        putExtra(AuditForegroundService.EXTRA_TITLE, title)
                        putExtra(AuditForegroundService.EXTRA_MESSAGE, message)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }

                    result.success(null)
                }

                "stopForegroundService" -> {
                    stopService(Intent(this, AuditForegroundService::class.java))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
