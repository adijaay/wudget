package id.wudget.wudget

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Finds payment notifications from any app and puts them in [PaymentLog].
 * An app the owner said yes to is recorded in the ledger the next time
 * wudget opens or resumes; an app seen for the first time is asked about,
 * with its payments held until the answer. Nothing leaves the phone.
 */
class PaymentListenerService : NotificationListenerService() {
    override fun onListenerConnected() {
        getSharedPreferences(STATUS, MODE_PRIVATE).edit().putBoolean("connected", true).apply()
    }

    // Android drops the binding when it kills the process to save battery; ask for it back.
    override fun onListenerDisconnected() {
        getSharedPreferences(STATUS, MODE_PRIVATE).edit().putBoolean("connected", false).apply()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            requestRebind(ComponentName(this, PaymentListenerService::class.java))
        }
    }

    // Called for notifications Do Not Disturb hides too; only an app's own notifications switched off never arrive.
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName
        if (pkg == packageName) return
        // Debug builds also accept `adb shell cmd notification post`, so the flow is testable without paying.
        if (pkg == "com.android.shell" && applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        val n = sbn.notification
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val extras = n.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT) ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()
        val name = appName(pkg)
        val payment = PaymentParser.parse(pkg, title, text, name)
        if (payment == null) {
            // Only for apps the owner chose; every other app's notifications stay unread and unkept.
            if (PaymentApps.state(this, pkg) == PaymentApps.ON && (!title.isNullOrBlank() || !text.isNullOrBlank())) {
                PaymentLog.addUnread(this, pkg, name ?: pkg, title, text)
            }
            return
        }
        if (isDuplicate(payment)) return
        when (PaymentApps.seen(this, pkg, payment.appLabel)) {
            PaymentApps.ON -> recorded(payment, PaymentLog.add(this, pkg, payment, title, text, pending = false))
            PaymentApps.ASK -> {
                PaymentLog.add(this, pkg, payment, title, text, pending = true)
                ask(pkg, payment)
            }
        }
    }

    private fun appName(pkg: String): String? = runCatching {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
    }.getOrNull()

    private fun isDuplicate(p: Payment): Boolean {
        val prefs = getSharedPreferences("payment_listener", MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val dup = PaymentDedup.isDuplicate(
            p,
            prefs.getLong("last_amount", -1),
            prefs.getString("last_merchant", null),
            now - prefs.getLong("last_at", 0),
        )
        prefs.edit().putLong("last_amount", p.amountMinor).putString("last_merchant", p.merchant).putLong("last_at", now).apply()
        return dup
    }

    private fun recorded(p: Payment, logId: String) {
        val uri = Uri.Builder().scheme("wudget").authority("capture")
            .appendQueryParameter("kind", "expense")
            .appendQueryParameter("src", "payment")
            .appendQueryParameter("logId", logId)
            .build()
        val note = p.merchant ?: p.appLabel
        post(
            logId.hashCode(),
            builder()
                .setContentTitle("Rp ${rupiah(p)} tercatat")
                .setContentText("$note, dari ${p.appLabel}. Ketuk untuk ubah kategori.")
                .setContentIntent(HomeWidgetLaunchIntent.getActivity(this, MainActivity::class.java, uri)),
        )
    }

    /** First payment from an app: one notification per app, updated with the latest amount. */
    private fun ask(pkg: String, p: Payment) {
        val where = p.merchant?.let { " ke $it" } ?: ""
        post(
            PaymentApps.askId(pkg),
            builder()
                .setContentTitle("${p.appLabel}: Rp ${rupiah(p)}$where")
                .setContentText("Catat pembayaran dari ${p.appLabel} ke wudget?")
                .setContentIntent(HomeWidgetLaunchIntent.getActivity(this, MainActivity::class.java, Uri.parse("wudget://payment-apps")))
                .addAction(choice(pkg, p.appLabel, PaymentAppChoiceReceiver.ACTION_ON, "Ya, selalu catat"))
                .addAction(choice(pkg, p.appLabel, PaymentAppChoiceReceiver.ACTION_OFF, "Jangan")),
        )
    }

    private fun choice(pkg: String, label: String, action: String, title: String): Notification.Action {
        val intent = Intent(this, PaymentAppChoiceReceiver::class.java)
            .setAction(action)
            .putExtra(PaymentAppChoiceReceiver.EXTRA_PKG, pkg)
            .putExtra(PaymentAppChoiceReceiver.EXTRA_LABEL, label)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pending = PendingIntent.getBroadcast(this, (action + pkg).hashCode(), intent, flags)
        @Suppress("DEPRECATION")
        return Notification.Action.Builder(0, title, pending).build()
    }

    private fun builder(): Notification.Builder {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, "Pembayaran terbaca", NotificationManager.IMPORTANCE_DEFAULT),
            )
        }
        @Suppress("DEPRECATION")
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        return b.setSmallIcon(R.drawable.ic_launcher_monochrome).setAutoCancel(true)
    }

    private fun post(id: Int, b: Notification.Builder) {
        getSystemService(NotificationManager::class.java).notify(id, b.build())
    }

    private fun rupiah(p: Payment) = "%,d".format(p.amountMinor).replace(',', '.')

    companion object {
        private const val CHANNEL = "payments"
        const val STATUS = "payment_listener_status"
    }
}
