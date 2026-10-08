package id.wudget.wudget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

// ponytail: sample wording is typical, not captured from the real apps; add each real notification here as a case.
class PaymentParserTest {
    private fun parse(pkg: String, title: String?, text: String?) = PaymentParser.parse(pkg, title, text)

    @Test fun gopayPayment() {
        val p = parse("com.gojek.app", "Pembayaran berhasil", "Pembayaran Rp25.000 ke Warung Bu Sri berhasil.")!!
        assertEquals(25000L, p.amountMinor)
        assertEquals("Warung Bu Sri", p.merchant)
        assertEquals("GoPay", p.appLabel)
    }

    @Test fun livinTransferWithDecimals() {
        val p = parse("id.bmri.livin", "Transfer Berhasil", "Transfer Rp 1.250.000,00 ke ANDI WIJAYA berhasil")!!
        assertEquals(1250000L, p.amountMinor)
        assertEquals("ANDI WIJAYA", p.merchant)
    }

    @Test fun jagoEnglishFormat() {
        val p = parse("com.jago.digitalBanking", "Payment successful", "You paid IDR 48,500.00 to Kopi Kenangan")!!
        assertEquals(48500L, p.amountMinor)
        assertEquals("Kopi Kenangan", p.merchant)
    }

    @Test fun shopeePayWithoutMerchant() {
        val p = parse("com.shopee.id", "ShopeePay", "Pembayaran sebesar Rp89.000 berhasil")!!
        assertEquals(89000L, p.amountMinor)
        assertNull(p.merchant)
    }

    @Test fun incomingMoneyIsNotSpending() {
        assertNull(parse("id.bmri.livin", "Dana masuk", "Transfer Rp500.000 dari BUDI telah diterima"))
    }

    @Test fun promoIsNotSpending() {
        assertNull(parse("com.shopee.id", "Flash sale!", "Diskon Rp50.000 untuk pembayaran pakai ShopeePay"))
        assertNull(parse("com.gojek.app", "Cashback", "Cashback Rp5.000 dari transaksi kamu"))
    }

    @Test fun otherAppsAndAmountlessTextAreIgnored() {
        assertNull(parse("com.whatsapp", "Ibu", "Sudah bayar Rp25.000 ke warung?"))
        assertNull(parse("com.gojek.app", "Pembayaran berhasil", "Driver kamu sedang menuju lokasi"))
    }

    @Test fun walletAndBankPostingTheSamePaymentIsOne() {
        val gopay = Payment(25000, "Kopi Kenangan", "GoPay")
        assertTrue(PaymentDedup.isDuplicate(gopay, 25000, null, 10_000))
        assertTrue(PaymentDedup.isDuplicate(gopay, 25000, "kopi kenangan", 10_000))
    }

    @Test fun sameAmountToTwoMerchantsIsTwoPayments() {
        assertFalse(PaymentDedup.isDuplicate(Payment(25000, "Kopi Kenangan", "GoPay"), 25000, "Indomaret", 10_000))
    }

    @Test fun sameAmountLaterIsANewPayment() {
        assertFalse(PaymentDedup.isDuplicate(Payment(25000, null, "Jago"), 25000, null, PaymentDedup.WINDOW_MS))
        assertFalse(PaymentDedup.isDuplicate(Payment(25000, null, "Jago"), 30000, null, 10_000))
    }

    @Test fun anyAppCanBeReadUnderItsOwnName() {
        val p = PaymentParser.parse("co.id.bankbsi.superapp", "Transaksi berhasil", "Pembayaran Rp45.000 ke Alfamart berhasil", appName = "BYOND")!!
        assertEquals(45000L, p.amountMinor)
        assertEquals("BYOND", p.appLabel)
    }

    @Test fun chatAppsAreNeverRead() {
        assertNull(parse("org.telegram.messenger", "Budi", "Pembayaran Rp25.000 ke Warung berhasil"))
    }
}
