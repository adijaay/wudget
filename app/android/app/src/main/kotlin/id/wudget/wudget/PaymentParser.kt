package id.wudget.wudget

/** An outgoing payment read from another app's notification. */
data class Payment(val amountMinor: Long, val merchant: String?, val appLabel: String)

/**
 * Reads payment notifications from the apps the owner pays with. Pure, so
 * PaymentParserTest covers it without a device. Wording varies by app and
 * changes without notice, so this matches loosely and the owner confirms
 * every suggestion before anything is saved.
 */
object PaymentParser {
    val apps = mapOf(
        "com.gojek.app" to "GoPay",
        "com.gojek.gopay" to "GoPay",
        "id.bmri.livin" to "Livin' by Mandiri",
        "com.jago.digitalBanking" to "Jago",
        "com.shopee.id" to "ShopeePay",
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
        extraApps: Map<String, String> = emptyMap(),
    ): Payment? {
        val label = apps[packageName] ?: extraApps[packageName] ?: return null
        val all = listOfNotNull(title, text).joinToString(" ").trim()
        if (all.isEmpty() || skip.containsMatchIn(all) || !paid.containsMatchIn(all)) return null
        val digits = amount.find(all)?.groupValues?.get(1)?.replace(Regex("[.,]"), "") ?: return null
        val value = digits.toLongOrNull()?.takeIf { it in 1..9_999_999_999 } ?: return null
        val shop = merchant.find(all)?.groupValues?.get(1)?.trim()
        return Payment(value, shop, label)
    }
}
