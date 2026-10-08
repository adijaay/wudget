package id.wudget.wudget

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

/**
 * Which apps' payments the owner wants recorded. An app appears here the
 * first time it posts a payment notification, as "ask"; the owner answers
 * once, from that notification or from the Aplikasi pembayaran screen.
 * Kept per package with its name and how many payments it has sent.
 */
object PaymentApps {
    const val ON = "on"
    const val OFF = "off"
    const val ASK = "ask"
    private const val PREFS = "payment_apps"
    private const val KEY = "apps"

    fun state(context: Context, pkg: String): String? = read(context).optJSONObject(pkg)?.optString("state")

    /** Counts one payment from [pkg], adding it as "ask" if it is new; returns its state. */
    @Synchronized fun seen(context: Context, pkg: String, label: String): String {
        val all = read(context)
        val app = all.optJSONObject(pkg) ?: JSONObject().put("state", ASK).put("count", 0)
        app.put("label", label).put("count", app.optInt("count") + 1).put("lastAt", System.currentTimeMillis())
        all.put(pkg, app)
        write(context, all)
        return app.getString("state")
    }

    /** The owner's answer: "on" releases the payments waiting in the log, "off" drops them. */
    @Synchronized fun set(context: Context, pkg: String, label: String, state: String) {
        val all = read(context)
        val app = all.optJSONObject(pkg) ?: JSONObject().put("count", 0)
        all.put(pkg, app.put("state", state).put("label", label))
        write(context, all)
        if (state == ON) PaymentLog.releasePending(context, pkg)
        if (state == OFF) PaymentLog.dropPending(context, pkg)
        context.getSystemService(NotificationManager::class.java).cancel(askId(pkg))
    }

    fun json(context: Context): String = read(context).toString()

    fun askId(pkg: String) = ("ask:$pkg").hashCode()

    private fun read(context: Context): JSONObject =
        runCatching { JSONObject(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, "{}")!!) }
            .getOrDefault(JSONObject())

    private fun write(context: Context, all: JSONObject) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, all.toString()).apply()
    }
}

/** The two buttons on "Catat pembayaran dari X?". */
class PaymentAppChoiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pkg = intent.getStringExtra(EXTRA_PKG) ?: return
        val label = intent.getStringExtra(EXTRA_LABEL) ?: pkg
        PaymentApps.set(context, pkg, label, if (intent.action == ACTION_ON) PaymentApps.ON else PaymentApps.OFF)
    }

    companion object {
        const val ACTION_ON = "id.wudget.wudget.PAYMENT_APP_ON"
        const val ACTION_OFF = "id.wudget.wudget.PAYMENT_APP_OFF"
        const val EXTRA_PKG = "pkg"
        const val EXTRA_LABEL = "label"
    }
}
