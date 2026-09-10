# App teardowns

Store metadata pulled 2026-09-10 from the iTunes Lookup API and Google Play listings.
Rating counts are per storefront, so a small app can look very different in the US and ID stores.

---

## Richual: Track Budget & Wallet

iOS only. Developer Jayvee Ballesteros. Paid up front at USD 2.99, no ads. Version 1.16,
first released 2026-07-30, updated 2026-09-08. One rating on the US store, so there is no
useful review signal yet.
[App Store](https://apps.apple.com/us/app/richual-track-budget-wallet/id6771552672) ·
[site](https://richual-app.vercel.app/)

Positioning is habit and identity, not accounting. The site tagline is "Your Rich Era Needs
a Ritual" and the store copy closes on making wealth a daily ritual. It states plainly that
it is manual and does not connect to banks.

Data model: wallets are the root object, typed as cash, bank, e-wallet, savings, credit
card, debt, or other, with a computed net worth above them. Alongside sit category budgets,
goals, recurring transactions, and interest accrual on savings wallets. Currency is per
wallet with a converted roll-up.

Screens observed from store screenshots: a four-item bottom nav (Wallet, Budgets, Goals,
Insights) plus a detached fifth button for transaction history. Wallet home is a stacked
deck of coloured wallet cards that collapses into a net worth card, with recent transactions
below. A persistent bar sits above the nav with three directional actions (expense down,
transfer sideways, income up), so capture is reachable from any tab without hunting for a
modal. A second dashboard variant shows a balance trend chart with 1M/3M/1Y toggles and an
interest forecast segmented Today/Month/Year/Custom. Insights shows a category donut, a
top-category callout, and a spending map built from geotagged transactions.

What stands out: interest earnings as a first-class tracked object, which is rare outside
banking apps, and the spending map. Both are read-only insight surfaces. That is a telling
allocation: the differentiation budget goes to review, not to capture.

Risks: dark-only in every screenshot, one green accent applied to nearly every element, and
a decorative sparkle in the wordmark. Paid up front with one review is a hard sell against
free competitors. Manual entry plus a price plus no bank sync means the entire value rests
on the review experience being worth the daily logging cost.

---

## Ollo: Budget & Money Manager

iOS and Android. Developer Trian Aprilianto. Free with an Ollo Premium tier. Version 1.6.1,
released 2026-05-12, updated 2026-08-17. 13 ratings on the ID store, none on US, and the
reviews mix Indonesian and English. Built for Indonesia first: GoPay and "Saku" wallets in
the screenshots, IDR amounts, and a `000` key on the numpad.
[App Store](https://apps.apple.com/id/app/ollo-budget-money-manager/id6763823803) ·
[Play](https://play.google.com/store/apps/details?id=com.ollo.ollo) ·
[site](https://ollowithyou.xyz/)

Positioning is speed of capture through voice. The site leads with logging an expense by
speaking it and claims roughly three seconds to process. Seven interface languages:
English, Indonesian, Spanish, Hindi, Japanese, Mandarin, Korean.

Data model: wallets (cash, bank, savings, e-wallet, credit card, crypto) with transfers
between them; transactions typed expense, income, or transfer, over a two-level category
tree; budgets per category. Then a wide surface of secondary objects: bills, recurring
payments, debts, reimbursements, a wishlist, and goals. Receipts and photo proofs attach to
transactions. Offline first, with cloud sync gated behind Premium.

Capture flow observed: the add screen is a single sheet. Segmented type control at the top,
a horizontally scrolling category row, then a second row of subcategory chips (Breakfast,
Lunch, Dinner under Food & Drink), then the amount with a currency dropdown, then optional
title, note, and wallet dropdown, over a custom numpad that includes a calculator toggle, a
date and time button, and `000`. Everything needed for one entry sits on one screen with no
navigation. This is the most efficient manual-entry layout in the set.

Home flow observed: greeting row with a level badge reading "Lvl 9", a period selector
(Day, Week, Month, Year, All), total balance with income and expense sub-tiles, a
horizontally scrolling menu of the secondary objects, one monthly budget progress bar, then
wallet cards. The transaction list groups by date with a per-day total.

What stands out: voice capture, receipt scan, and an AI assistant all inside a small indie
app, plus explicit gamification (levels) in a category that usually avoids it.
Reimbursements and a wishlist are unusual objects and both map to real behaviour: money you
are owed, and wants you have not committed to yet.

Bugs and gaps the reviewers name themselves: several ID reviewers report a missing back
button on the income and expense screens reached from the home widget, and a bug when
paying a credit card. One asked for a home screen widget. A screenshot shows the day total
in USD while the line items are in IDR, which suggests the multi-currency roll-up and the
list formatter disagree.

---

## Expensa: AI Expense Tracker

iOS only. Developer Andrii Sereda. Free tier plus Premium. Version 1.2, released 2026-04-29.
3.78 stars from 9 US ratings. Note the name collision: three unrelated Android apps and one
other iOS app also use "Expensa".
[App Store](https://apps.apple.com/us/app/expensa-ai-expense-tracker/id6758392205) ·
[site](https://getexpensa.com/)

Positioning is privacy as the wedge. The store copy opens on tracking money without handing
over a bank password, and names Plaid and data brokers as the thing it is not. iCloud sync
only.

Data model: "Spaces" (personal, household, business, trip) are isolated top-level
containers, each holding accounts, categories, tags, folders, and merchant rules. Category
budgets run on monthly, weekly, or custom cycles with auto-rollover. 150+ currencies with
the original amount and a per-transaction historical rate both stored. Net worth is computed
across accounts and currencies.

Capture flow, and the distinctive move: instead of bank sync, an Apple Shortcut fires on the
Wallet tap-to-pay event, so a card tap creates a transaction. AI then proposes a category
from history. In the screenshot the proposal is a card labelled "Suggested category" with
two buttons, Change category and Apply, so the user confirms rather than being silently
categorised. Receipt scanning exists but is framed as the fallback for paper.

Review flow: home shows total spent this period, a delta against the previous period, a line
chart with a dashed forecast continuing past today, and a pace ring paired with a sentence
of plain-language interpretation instead of a bare percentage. Category budgets draw a
target line on the same chart as actual spend.

Free tier limits: 1 space, 2 accounts, 3 recurring items, 5 receipt scans. Premium adds
unlimited spaces and accounts, 30 scans a month, AI categorisation, category budgets,
analytics, shared spaces, and multi-currency entry. Note that category budgets, the core of
the product story, sit behind the paywall.

What stands out: the pace ring with an interpreted sentence, the forecast line, and
per-transaction historical FX. Also the honest framing of automation. A Shortcut on
tap-to-pay covers card spend without an aggregator, and cash simply is not covered.

Gaps: localised in English and Ukrainian only, and one of the three-star reviews is
specifically about missing language support. Nine ratings in total.

---

## SyncSpend

iOS. Developer Toh Kar Le, published in the orbit of the Notion template creator Easlo.
Free with a paid upgrade. Version 1.0.3, released 2026-03-14, last updated 2026-03-25.
3.17 stars from 6 US ratings, 5 from 4 ID ratings. Two unrelated Android apps also use the
name, one of them a shared-expenses app.
[App Store](https://apps.apple.com/us/app/syncspend/id6759112033) ·
[a different app on Play](https://play.google.com/store/apps/details?id=com.GreenLeafTech.expense_tracker_v3)

Positioning is a capture client for a ledger that lives somewhere else. It writes into a
Notion database, adds home screen widgets, and automates logging from Apple Pay through
Shortcuts. No sign-in, no ads, no tracking.

Data model: deliberately thin, expenses only. Reviewers repeatedly ask for income, which
means the app has no concept of net position, only outflow.

What stands out: this is the clearest example in the set of an app that refuses to own the
data model. For the Notion crowd that is the feature, and a UK reviewer praises exactly
that, noting it links to their Notion and asks for little beyond what they spent.

What went wrong: all three negative US reviews are about monetisation rather than function.
A free app became paid, features they had been using were locked, and one reviewer reports
that the free tier retains a single month of history, so their older records became
unreadable. That last one is the most damaging pattern in the category, because it turns a
pricing change into what the user experiences as data loss.

---

## Money Manager Expense & Budget (Realbyte)

iOS and Android, Korean developer Realbyte. The incumbent here: first released 2012-11-05
and still shipping (updated 2026-09-07). 4.82 stars from 19,171 US ratings and 4.91 from
15,061 ID ratings. Free with ads, a paid ad-free version, and a sync subscription at USD
2.49 monthly or 19.99 yearly.
[App Store](https://apps.apple.com/us/app/money-manager-expense-budget/id560481810) ·
[Play](https://play.google.com/store/apps/details?id=com.realbyteapps.moneymanagerfree) ·
[site](https://www.realbyteapps.com/)

Positioning is household accounting done properly. Its own description says it applies
double entry bookkeeping, so income deposits into an account and an expense draws from one.
This is the accounting-first pole of the category.

Data model: accounts with groups; main and sub categories; budgets weekly, monthly and
annual; a configurable month start date; credit and debit card handling with future payment
dates and outstanding balances; automatic transfers with a frequency; payees; payment
profiles for repeated entries; multi-currency per entry with a chosen base; passcode lock;
and backup or restore over email, iTunes and iCloud. A desktop viewer works over Wi-Fi.

What stands out: the configurable month start date (payday cycles rather than calendar
months), payment profiles (a saved template as the answer to entry friction), and the card
payment-date model. All three answer real household problems that most modern competitors
skip.

Where it hurts: the one and two-star reviews cluster on ads covering tappable areas,
recurring transactions failing to appear and then appearing all at once, a budget system
that cannot express the categories a user actually has, and in the worst cases data
disappearing after an update. Long-time users also describe the app as having grown too
complex over the years.

---

## MELD: Sharing Money Tracker

Android via Google Play, package `id.my.meld.twa`, which means it ships as a Trusted Web
Activity: the store app wraps the web app at meld.my.id. Indonesian, with a store listing
written for an Indonesian audience. Not on the App Store under this name.
[Play](https://play.google.com/store/apps/details?id=id.my.meld.twa) ·
[site](https://meld.my.id/)

Positioning is a shared household and small-business ledger, with AI capture as the hook
and community as the retention loop. The listing expands the name as Money Evolve Linked
Dreams.

Feature set as listed by the developer: AI voice command and AI receipt capture, both free;
report generation by voice command; sharing groups with a spouse, friends, business partners
or an arisan group; a community stream between users; budgeting; goals; accounts payable and
receivable; auto-deposit of salary and auto-debit of debt; transfers between assets; icons
for Indonesian banks, digital banks and e-wallets; an audit trail on transactions;
subscription tracking; a push notification when a group member records a transaction; a
financial health view with recommended actions; note-taking from WhatsApp; custom themes;
and an AI assistant that analyses finances. A creator post lists PRO at IDR 100,000 a year.

What stands out, and none of the Western apps here do any of it. Arisan groups (rotating
savings associations) as a named use case. WhatsApp as a capture channel, which meets
Indonesian users where they already type. And a push notification when a group member logs
a transaction, which turns a shared ledger into a live feed and is the mechanic that makes
household tracking self-enforcing.

Structural caveat: a TWA inherits web performance, web gesture handling, and no real offline
story unless the web app caches aggressively. Against offline-first native competitors that
is a disadvantage on the capture path, which is exactly where speed matters most.

---

## Dastlycal

Not found. Searched the App Store US and ID storefronts, Google Play, and the open web on
2026-09-10 with no match and no near-miss that looks like a finance app. It needs a store
link or a corrected spelling before it can be added.

---

## Benchmarks

Fourteen apps pulled for comparison and review mining. Ratings are the US storefront on
2026-09-10.

| App | Developer | Rating (count) | Model |
|---|---|---|---|
| Rocket Money | Rocket Money | 4.48 (388,742) | Bill negotiation and subscription cancellation |
| Monarch: Budget & Track Money | Monarch Money | 4.89 (108,918) | Bank sync, subscription around USD 15 a month |
| EveryDollar | The Lampo Group | 4.74 (84,080) | Zero-based, Ramsey ecosystem |
| YNAB | You Need A Budget | 4.79 (61,487) | Envelope, give every dollar a job |
| Copilot: Track & Budget Money | Copilot Money | 4.75 (30,228) | Bank sync, AI categorisation, design led |
| Splitwise | Splitwise | 3.97 (27,768) | Group debt netting, not budgeting |
| Money Manager | Realbyte | 4.82 (19,171) | Manual, double entry |
| Goodbudget | Dayspring Technologies | 4.63 (13,437) | Digital envelopes shared across a household |
| Honeydue | WalletIQ | 4.49 (10,206) | Couples, bank sync, per-item visibility control |
| Buddy | Buddy Budgeting AB | 4.71 (9,457) | Budget first, bank sync |
| Monefy | Reflective Technologies | 4.72 (6,657) | Minimal, donut-first capture |
| Spendee | Cleevio | 4.61 (6,246) | Wallets, shared wallets, bank sync |
| Money Lover | Finsify | 4.61 (2,258) | Asia-first sync coverage |
| Cashew | James Kokoska | 4.93 (504) | Offline, open, highly customisable |

Note the shape of that table. The highest-rated apps are either large and bank-synced, or
small and manual with a devoted niche. The sag is in the middle: mid-size manual apps with
generic feature sets.
