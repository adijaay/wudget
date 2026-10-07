package id.wudget.wudget

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Saya's payment-notification row: is access on, and open the system screen to change it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wudget/payments").setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> {
                    val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    result.success(enabled?.contains(packageName) == true)
                }
                "openSettings" -> {
                    val detail = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                        Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                        ComponentName(this, PaymentListenerService::class.java).flattenToString(),
                    )
                    runCatching { startActivity(detail) }
                        .onFailure { startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
