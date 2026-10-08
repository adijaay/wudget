package id.wudget.wudget

/** An outgoing payment read from another app's notification. */
data class Payment(val amountMinor: Long, val merchant: String?, val appLabel: String)

/**
 * Reads payment notifications from any app, so a bank wudget has never heard
 * of is still found. Pure, so PaymentParserTest covers it without a device.
 * Wording varies by app and changes without notice, so this matches loosely;
 * the owner decides per app whether its payments are recorded (PaymentApps).
 */
object PaymentParser {
    // Display names for when the package manager cannot give one.
    val names = mapOf(
        "com.gojek.app" to "GoPay",
        "com.gojek.gopay" to "GoPay",
        "id.bmri.livin" to "Livin' by Mandiri",
        "com.jago.digitalBanking" to "Jago",
        "com.shopee.id" to "ShopeePay",
    )

    // People type amounts to each other here; "sudah bayar Rp25.000?" is not the owner's payment.
    private val neverRead = setOf(
        "com.whatsapp", "com.whatsapp.w4b", "org.telegram.messenger", "jp.naver.line.android",
        "com.facebook.orca", "com.facebook.katana", "com.instagram.android", "org.thoughtcrime.securesms",
        "com.discord", "com.twitter.android", "com.zhiliaoapp.musically", "com.ss.android.ugc.trill",
        "com.google.android.gm", "com.microsoft.office.outlook", "com.google.android.apps.messaging",
        "com.samsung.android.messaging", "com.android.mms", "com.google.android.youtube",
    )

    // Promos, money coming in, and wallet transfers also carry "Rp" amounts; they are not spending.
    private val skip = Regex(
        "masuk|diterima|menerima|received|top ?up|isi saldo|cashback|refund|dikembalikan|" +
            "promo|diskon|voucher|hemat|gratis|potongan|otp|kode verifikasi|jatuh tempo",
        RegexOption.IGNORE_CASE,
    )
    private val paid = Regex(
        "berhasil|sukses|pembayaran|bayar|transfer|kirim|terkirim|pembelian|transaksi|debit|payment|paid",
        RegexOption.IGNORE_CASE,
    )

    // "Rp25.000", "Rp 25.000,00", "IDR 25,000.00": group 1 is whole rupiah.
    private val amount = Regex(
        "(?:Rp|IDR)\\.?\\s?([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]+)(?:[.,][0-9]{2}(?![0-9]))?",
        RegexOption.IGNORE_CASE,
    )
    private val merchant = Regex(
        "\\b(?:ke|di|kepada|to|at)\\s+([A-Z0-9][^,.!\\n]{1,40}?)" +
            "(?=\\s+(?:berhasil|sukses|sebesar|senilai|telah|dengan|pada|via|sudah)\\b|[,.!\\n]|$)",
    )

    fun parse(
        packageName: String,
        title: String?,
        text: String?,
        appName: String? = null,
    ): Payment? {
        if (packageName in neverRead) return null
        val label = appName ?: names[packageName] ?: packageName
        val all = listOfNotNull(title, text).joinToString(" ").trim()
        if (all.isEmpty() || skip.containsMatchIn(all) || !paid.containsMatchIn(all)) return null
        val digits = amount.find(all)?.groupValues?.get(1)?.replace(Regex("[.,]"), "") ?: return null
        val value = digits.toLongOrNull()?.takeIf { it in 1..9_999_999_999 } ?: return null
        val shop = merchant.find(all)?.groupValues?.get(1)?.trim()
        return Payment(value, shop, label)
    }
}

/**
 * One payment often posts twice within seconds: the wallet and the bank, or
 * an update of the same notification. Two payments of the same amount to
 * two named merchants are two payments, though.
 */
object PaymentDedup {
    const val WINDOW_MS = 3 * 60_000L

    fun isDuplicate(p: Payment, lastAmount: Long, lastMerchant: String?, sinceLastMs: Long): Boolean {
        if (lastAmount != p.amountMinor || sinceLastMs !in 0 until WINDOW_MS) return false
        val a = p.merchant?.trim()?.lowercase()
        val b = lastMerchant?.trim()?.lowercase()
        return a == null || b == null || a == b
    }
}
