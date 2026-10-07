package id.wudget.wudget

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Turns a payment notification from GoPay, Livin', Jago or ShopeePay into a
 * wudget suggestion. Nothing is saved here: tapping the suggestion opens the
 * capture sheet pre-filled, through the same deep link as the home widget.
 * Every other notification is ignored and nothing leaves the phone.
 */
class PaymentListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (sbn.packageName == packageName) return
        val n = sbn.notification
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val extras = n.extras
        val text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT) ?: extras.getCharSequence(Notification.EXTRA_TEXT)
        val payment = PaymentParser.parse(
            sbn.packageName,
            extras.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
            text?.toString(),
            // Debug builds also accept `adb shell cmd notification post`, so the flow is testable without paying.
            if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) mapOf("com.android.shell" to "Tes") else emptyMap(),
        ) ?: return
        if (isDuplicate(payment.amountMinor)) return
        suggest(payment)
    }

    // One payment often posts twice: the wallet and the bank, or an update of the same notification.
    private fun isDuplicate(amountMinor: Long): Boolean {
        val prefs = getSharedPreferences("payment_listener", MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val dup = prefs.getLong("last_amount", -1) == amountMinor && now - prefs.getLong("last_at", 0) < 3 * 60_000
        prefs.edit().putLong("last_amount", amountMinor).putLong("last_at", now).apply()
        return dup
    }

    private fun suggest(p: Payment) {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Pembayaran terbaca", NotificationManager.IMPORTANCE_DEFAULT),
            )
        }
        val note = p.merchant ?: p.appLabel
        val uri = Uri.Builder().scheme("wudget").authority("capture")
            .appendQueryParameter("kind", "expense")
            .appendQueryParameter("amountMinor", p.amountMinor.toString())
            .appendQueryParameter("note", note)
            .appendQueryParameter("src", "payment")
            .build()
        val rupiah = "%,d".format(p.amountMinor).replace(',', '.')
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        val notification = builder
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle("Catat Rp $rupiah?")
            .setContentText("$note, dari ${p.appLabel}. Ketuk untuk menyimpan.")
            .setContentIntent(HomeWidgetLaunchIntent.getActivity(this, MainActivity::class.java, uri))
            .setAutoCancel(true)
            .build()
        manager.notify((p.amountMinor % Int.MAX_VALUE).toInt(), notification)
    }

    companion object {
        private const val CHANNEL = "payments"
    }
}
