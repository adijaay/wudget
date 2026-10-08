package id.wudget.wudget

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
                    // Open general notification listener settings since PaymentListenerService
                    // is not declared in manifest (to pass Play Protect). User must manually
                    // find wudget in the list and enable it.
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "getLog" -> result.success(PaymentLog.json(this))
                "setInputted" -> {
                    PaymentLog.setInputted(this, call.argument<String>("id")!!, call.argument<Boolean>("inputted")!!)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
