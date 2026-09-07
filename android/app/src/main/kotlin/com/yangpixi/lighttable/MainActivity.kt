package com.yangpixi.lighttable

import com.yangpixi.lighttable.widget.LightTableWidget
import androidx.glance.appwidget.updateAll
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val widgetScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != REFRESH_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            widgetScope.launch {
                runCatching {
                    LightTableWidget().updateAll(applicationContext)
                }.onSuccess {
                    result.success(null)
                }.onFailure { error ->
                    result.error("widget_refresh_failed", error.message, null)
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).setMethodCallHandler(null)
        widgetScope.cancel()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private companion object {
        const val WIDGET_CHANNEL = "com.yangpixi.lighttable/widget"
        const val REFRESH_METHOD = "refresh"
    }
}
