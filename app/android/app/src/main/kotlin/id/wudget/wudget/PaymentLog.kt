package id.wudget.wudget

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Every payment notification wudget recognised, newest first, with whether
 * it has been recorded yet. Lives on the phone only, so the owner can see
 * which payments they tapped through and which they still owe an entry.
 */
object PaymentLog {
    private const val PREFS = "payment_log"
    private const val KEY = "entries"
    private const val MAX = 400

    /** [pending] holds the entry out of the ledger until the owner says yes to [pkg]. */
    @Synchronized fun add(context: Context, pkg: String, p: Payment, title: String?, text: String?, pending: Boolean): String {
        val id = UUID.randomUUID().toString()
        val entry = JSONObject()
            .put("id", id)
            .put("pkg", pkg)
            .put("pending", pending)
            .put("at", System.currentTimeMillis())
            .put("app", p.appLabel)
            .put("amountMinor", p.amountMinor)
            .put("merchant", p.merchant ?: JSONObject.NULL)
            .put("title", title ?: JSONObject.NULL)
            .put("text", text ?: JSONObject.NULL)
            .put("inputted", false)
        prepend(context, entry, read(context))
        return id
    }

    /** Overwrites the given fields of one entry; Flutter owns inputted, txId and processed. */
    /**
     * A notification from a watched app that did not read as a payment, kept
     * so the owner can spot wording the parser misses. No amount, so it is
     * never recorded on its own.
     */
    @Synchronized fun addUnread(context: Context, pkg: String, app: String, title: String?, text: String?) {
        val old = read(context)
        // Apps re-post the same notification as it updates; one row is enough.
        if (old.length() > 0) {
            val last = old.getJSONObject(0)
            if (last.optString("kind") == "unread" && last.optString("app") == app &&
                last.optString("title") == (title ?: "") && last.optString("text") == (text ?: "")
            ) return
        }
        val entry = JSONObject()
            .put("id", UUID.randomUUID().toString())
            .put("kind", "unread")
            .put("pkg", pkg)
            .put("at", System.currentTimeMillis())
            .put("app", app)
            .put("title", title ?: "")
            .put("text", text ?: "")
            .put("inputted", false)
            .put("processed", true)
        prepend(context, entry, old)
    }

    @Synchronized fun patch(context: Context, id: String, fields: JSONObject) {
        val all = read(context)
        for (i in 0 until all.length()) {
            val e = all.getJSONObject(i)
            if (e.getString("id") != id) continue
            for (k in fields.keys()) e.put(k, fields.get(k))
        }
        write(context, all)
    }

    @Synchronized fun releasePending(context: Context, pkg: String) {
        val all = read(context)
        for (i in 0 until all.length()) {
            val e = all.getJSONObject(i)
            if (e.optString("pkg") == pkg && e.optBoolean("pending")) e.put("pending", false)
        }
        write(context, all)
    }

    @Synchronized fun dropPending(context: Context, pkg: String) {
        val all = read(context)
        val kept = JSONArray()
        for (i in 0 until all.length()) {
            val e = all.getJSONObject(i)
            if (!(e.optString("pkg") == pkg && e.optBoolean("pending"))) kept.put(e)
        }
        write(context, kept)
    }

    private fun prepend(context: Context, entry: JSONObject, old: JSONArray) {
        val next = JSONArray().put(entry)
        for (i in 0 until minOf(old.length(), MAX - 1)) next.put(old.get(i))
        write(context, next)
    }

    fun json(context: Context): String = read(context).toString()

    private fun read(context: Context): JSONArray =
        runCatching { JSONArray(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, "[]")) }
            .getOrDefault(JSONArray())

    private fun write(context: Context, all: JSONArray) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, all.toString()).apply()
    }
}
