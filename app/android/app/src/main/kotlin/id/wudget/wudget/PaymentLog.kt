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
    private const val MAX = 300

    fun add(context: Context, p: Payment, title: String?, text: String?): String {
        val id = UUID.randomUUID().toString()
        val entry = JSONObject()
            .put("id", id)
            .put("at", System.currentTimeMillis())
            .put("app", p.appLabel)
            .put("amountMinor", p.amountMinor)
            .put("merchant", p.merchant ?: JSONObject.NULL)
            .put("title", title ?: JSONObject.NULL)
            .put("text", text ?: JSONObject.NULL)
            .put("inputted", false)
        val old = read(context)
        val next = JSONArray().put(entry)
        for (i in 0 until minOf(old.length(), MAX - 1)) next.put(old.get(i))
        write(context, next)
        return id
    }

    /** Overwrites the given fields of one entry; Flutter owns inputted, txId and processed. */
    fun patch(context: Context, id: String, fields: JSONObject) {
        val all = read(context)
        for (i in 0 until all.length()) {
            val e = all.getJSONObject(i)
            if (e.getString("id") != id) continue
            for (k in fields.keys()) e.put(k, fields.get(k))
        }
        write(context, all)
    }

    fun json(context: Context): String = read(context).toString()

    private fun read(context: Context): JSONArray =
        runCatching { JSONArray(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, "[]")) }
            .getOrDefault(JSONArray())

    private fun write(context: Context, all: JSONArray) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, all.toString()).apply()
    }
}
