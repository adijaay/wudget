package id.wudget.wudget

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
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
                // Access granted is not the same as running: a battery saver can stop the listener and keep it stopped.
                "status" -> {
                    val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")?.contains(packageName) == true
                    val connected = getSharedPreferences(PaymentListenerService.STATUS, MODE_PRIVATE).getBoolean("connected", false)
                    val batteryFree = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                        (getSystemService(POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(packageName)
                    result.success(mapOf(
                        "enabled" to enabled,
                        "connected" to connected,
                        "batteryFree" to batteryFree,
                    ))
                }
                "openBatterySettings" -> {
                    val app = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                    runCatching { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) }
                        .onFailure { startActivity(app) }
                    result.success(null)
                }
                "getLog" -> result.success(PaymentLog.json(this))
                "patchLog" -> {
                    PaymentLog.patch(this, call.argument<String>("id")!!, org.json.JSONObject(call.argument<String>("fields")!!))
                    result.success(null)
                }
                "getApps" -> result.success(PaymentApps.json(this))
                "setApp" -> {
                    PaymentApps.set(this, call.argument<String>("pkg")!!, call.argument<String>("label")!!, call.argument<String>("state")!!)
                    result.success(null)
                }
                // Apps with a launcher icon only: visible without asking Play for every installed package.
                "installedApps" -> {
                    val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                    @Suppress("DEPRECATION")
                    val apps = packageManager.queryIntentActivities(launcher, 0)
                        .map { mapOf("pkg" to it.activityInfo.packageName, "label" to it.loadLabel(packageManager).toString()) }
                        .filter { it["pkg"] != packageName }
                        .distinctBy { it["pkg"] }
                        .sortedBy { it["label"]!!.lowercase() }
                    result.success(apps)
                }
                else -> result.notImplemented()
            }
        }
    }
}
