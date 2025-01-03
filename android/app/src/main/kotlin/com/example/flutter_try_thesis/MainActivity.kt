package com.book.todago

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.flutter_try_thesis/api_key"

     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getApiKey") {
                val apiKey = BuildConfig.MAPS_API_KEY
                result.success(apiKey)
            } else {
                result.notImplemented()
            }
     }
     }
}
