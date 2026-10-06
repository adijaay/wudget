# Retention baseline: why someone opens wudget tomorrow

The baseline for the next round of UI and UX work. It combines a web search done on
2026-10-07 with the earlier research in this folder, and turns both into rules a screen can
be checked against. Where the new search and the older files disagree, this file says which
wins and why.

Mockups built from this file: [design/Retention.html](../design/Retention.html).
Sprint plan: [plan/06-retention-sprints.md](../plan/06-retention-sprints.md).

---

## 1. The problem in numbers

| Fact | Source quality |
|---|---|
| Finance apps keep about 4.2% of users at day 30. The all-category average is about 6% | Vendor blogs, direction only |
| Around 77% of daily users stop opening an app within three days of install | Vendor blog, direction only |
| Apps that log spending automatically (Monarch, Copilot) keep about 2x more busy users than manual apps | Vendor blog, direction only |
| Duolingo, Q2 2026: 58.7M daily users, 84% of daily users return the next day | Earnings report, reliable |
| Duolingo's Streak Revival: 15.4M users restored their longest streak after 3 lessons, about 8M of them had no active streak | Earnings report, reliable |

Reading: a manual expense tracker starts in the worst retention category, with the most
work per entry. Anything that does not make logging faster or more rewarding is decoration.

Do not quote the vendor percentages in the app, the store listing, or a pitch.

---

## 2. What wudget is, after this round

The owner's direction, checked against the research:

- **Spending is the goal.** Income is one input that fills the kantong, not a second ledger.
  Same model as Goodbudget and YNAB, where income is what gets divided into categories.
- **No separate wallets in the main flow.** One pool of money, budgeted per category.
  Monefy (11M+ downloads, 4.7 stars from 283k reviews) proves a large audience wants exactly
  this: no account setup, no bank linking.
- **Category budgets are the envelopes.** [05, section 4](05-behavioral-research.md) shows
  partitioning money slows spending (Cheema and Soman 2008). Kantong per category keeps that
  mechanism. Wallets were a second partition on top, and dropping them does not lose it.
- **Manual on purpose.** Writing a purchase down is the moment of noticing. The 2023
  *Consumer Interests Annual* paper links persistent tracking to a smaller share of
  discretionary spending. Vendor claims of "15 to 25% less spending" are unverified.

The cost of manual is effort per entry. So the whole baseline comes down to one trade:
**keep the moment of noticing, remove every other second.**

---

## 3. What the big apps do, and what wudget takes

| App | Mechanism | wudget takes | wudget skips |
|---|---|---|---|
| Duolingo | Streak, with freeze, repair and revival | A count that forgives a missed day (rule 4) | Leagues, XP, hearts |
| Monefy | Open the app, tap a category, type the amount | Capture as the first screen (rule 1) | Pie chart as the home screen |
| Goodbudget | Envelopes per category, filled from income | Kantong filled at gajian (rule 5) | Separate accounts |
| Monzo | Salary Sorter: detects salary, offers a one-tap split | The gajian split (rule 5) | Bank feed |
| Strava | Year in Sport, monthly stat cards, about 2 minutes in app per hour of activity | Monthly recap card (rule 6), short sessions | Social feed, kudos |
| Spotify | Wrapped, a yearly story worth sharing | Year recap, later | |
| Cleo | Chat-style AI with a personality, very strong with Gen Z | A voice in the one-line insight (rule 3) | A chatbot |
| Finku | Local competitor, about 1M users, links accounts | | Account linking. wudget competes on speed instead |

---

## 4. The rules

Every screen in the next round is checked against these. A screen that breaks one needs a
written reason.

### Rule 1. A repeat expense in under 3 seconds

- The app opens on capture, or capture is one tap from any screen.
- Category chips are ordered by time of day and frequency, so lunch at 12:00 puts Makan first.
- Amount keypad shows with the sheet; no extra tap to focus.
- A home screen widget logs without opening the app.
- A note line under the amount, optional, never required to save. Past notes with their
  category and amount become the quick chips on home, so a repeat expense is one tap.
- Expense and income share one sheet with a Pengeluaran / Pemasukan switch. Saving an
  income offers the gajian split (rule 5), with "Simpan saja" to skip it for small income like a refund or a side job.
- Save gives a haptic and the kantong's remaining amount, then closes.

Checked by: median time from launch to saved, measured on a mid-range Android device.

### Rule 2. One number on home: how much is okay today

- Home leads with **jatah hari ini**: what is left in the period divided by the days left.
- The monthly "sisa anggaran" sits one tap away, not on the hero.
  [05, section 11](05-behavioral-research.md) shows a big monthly remaining number licenses
  late-period spending. This rule overrides any competitor pattern.
- Today's spending is drawn against today's jatah as one bar.

### Rule 3. One new sentence every day

- Home carries one sentence that is different from yesterday's, in plain Indonesian,
  about the user's own data: "Makan minggu ini Rp 80rb lebih hemat dari minggu lalu."
- It comes from the Pola and Aliran calculations that already exist. Charts stay behind
  the sentence, one tap away.
- When there is nothing new to say, the line says nothing. No filler tips.
- Reason: [05, section 12](05-behavioral-research.md), feedback that repeats until it teaches
  nothing is one of the top reasons people stop tracking.

### Rule 4. Forgive the missed day

- Show **days logged this month** ("18 dari 23 hari tercatat"), not a consecutive streak.
- A missed day costs one dot, never the whole count.
- Coming back after a gap gets a welcome back, not a reset: "Lanjut lagi. Kemarin bisa
  dicatat sekarang."
- No levels, no XP, no badges. [DESIGN.md](../DESIGN.md) rules out gamified levels, and
  [05, section 13](05-behavioral-research.md) says to design for lapse and return.
- Open decision for the owner: whether a strict consecutive streak is ever shown. Duolingo's
  results argue for it; the abandonment research argues against it. Default: no.

### Rule 5. Payday is the big moment

Payday is when people care most about money and have the least patience for forms. Two
taps from payday to a working budget, no typing in the usual case.

- **The app asks, the user confirms.** On payday, home shows "Gaji Rp X sudah masuk?" with
  last salary's amount. Buttons: Sudah masuk, Beda jumlah (opens keypad), Belum (asks
  again tomorrow). A reminder carries the same question (rule 7).
- **Payday date.** The 25th of every month, fixed. No weekend or holiday shift, so no
  holiday list to maintain. The period runs from the 25th to the 24th.
- **One number, not a sum.** The review screen shows "Uang periode ini": new salary plus
  last period's leftover (all income minus all spending). The parts sit in one small line.
- **Every rupiah already placed.** Kantong are pre-filled with last period's budget, and the
  leftover goes to Tabungan by default. The rows are read-only; a row opens an editor only
  when tapped. No "belum dibagi" to bring to zero.
- **One tap accepts.** "Pakai anggaran ini". The period, the kantong and the jatah update.
- Income on other days (refund, side job) is saved with "Simpan saja"; it joins the
  leftover and does not open the split.
- **Set now, any day.** "Atur anggaran sekarang" in Kantong and on the first-run card. The
  user types the money on hand and picks the end: the coming 24th, or the 24th after it
  (pre-selected from the 15th on, for an early salary). Then the same review screen. With
  no previous budget, kantong are pre-filled from recent spending (existing BudgetProposal).
  The new period starts today; on the next 25th the normal payday card takes over.
- The total budget is the sum of the kantong. There is no separate total field.

### Rule 6. A recap people want to keep

- At period close, a recap card: total spent against plan, the kantong that held, the one
  that did not, and one sentence.
- Saved or shared as an image. No user count, no comparison with other people.
- A year recap follows the same format, later.

### Rule 7. Reminders that are about the user

- One evening reminder, at the time the user usually logs, only on days with nothing logged.
- One weekly recap notification.
- Copy names a fact, never guilt: "Belum ada catatan hari ini" rather than "Kamu lupa lagi!"
- Off by default for anything beyond these two.

### Rule 8. Short sessions are the goal

- Success is a 10-second visit that ends with a saved entry, not time in the app.
- No feed, no content tab, no infinite scroll.

---

## 5. What this changes in the current app

| Area | Today | After |
|---|---|---|
| Home (Catat hari ini) | Jatah per hari card, list | Jatah hero, logged-days strip, one insight line, list |
| Capture | Sheet from the nav button | Same sheet, smarter chip order, opens from widget and launch |
| Wallets | Separate screen, picked on capture | Hidden from capture. Kept in settings for people who already use them |
| Income | Same form as expense | Triggers the gajian split |
| Pantau | Tabs of charts | Starts with the sentence, charts below |
| Period close | Sheet | Shareable recap card |
| Notifications | None or generic | Two: evening nudge, weekly recap |

---

## 6. Open decisions

1. Strict streak shown anywhere? Default no (rule 4).
2. Wallets: hide them, or remove them? Default hide, because users already have data in them.
3. Does the app open on capture or on home? Default home, with capture one tap away and the
   widget for zero taps. Revisit after measuring rule 1.
4. Insight voice: neutral, or a little teasing like Cleo? Default neutral and friendly, per
   [DESIGN.md](../DESIGN.md) copy voice.

---

## Sources

New search, 2026-10-07:

- [Duolingo DAU 58.7M, retention 84% (Pulse 2.0)](https://pulse2.com/duolingo-daily-active-users-reach-58-7-million-as-retention-hits-record-84-and-social-accounts-top-1-billion-organic-impressions/)
- [Duolingo Q2 2026 earnings call](https://www.webull.com/news/15392596720296960)
- [App retention benchmarks 2026 (Appcues)](https://www.appcues.com/blog/app-retention-is-hard-heres-how-to-improve-it)
- [Retention benchmarks by industry 2026 (Growth-onomics)](https://growth-onomics.com/mobile-app-retention-benchmarks-by-industry-2026/)
- [Engagement strategies 2026 (StriveCloud)](https://www.strivecloud.io/blog/increase-mobile-app-engagement-optimized)
- [Personal finance apps, what users expect 2026 (WildNet)](https://www.wildnetedge.com/blogs/personal-finance-apps-what-users-expect)
- [Strava gamification case study 2026 (Trophy)](https://trophy.so/blog/strava-gamification-case-study)
- [Strava Year in Sport now paid (road.cc)](https://road.cc/content/news/strava-year-sport-now-only-subscribers-317425)
- [Neobank UX patterns: Monzo, Revolut (Flat Studio)](https://www.flatstudio.co/blog/neobank-ux-patterns-daily-banking)
- [Cleo growth (Sacra)](https://sacra.com/c/cleo/)
- [Finku (Promptloop)](https://www.promptloop.com/directory/what-does-finku-do)
- [Best budgeting apps for beginners 2026 (Inspire Fusion)](https://www.inspirefusion.com/best-budgeting-apps-beginners-2026/)
- [Best expense tracker apps 2026 (Finny)](https://getfinny.app/blog/best-expense-tracker-apps-2026)
- [Why tracking spending works (K24)](https://k24.digital/lifestyle/money/why-tracking-your-spending-is-the-money-habit-that-works/amp)

Earlier research: [05-behavioral-research.md](05-behavioral-research.md) sections 4, 11, 12, 13.
