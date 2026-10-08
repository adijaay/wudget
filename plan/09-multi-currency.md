# Multi-Currency (v2)

Design for Sprint 17 of [06-audit-fixes.md](06-audit-fixes.md), covering its three tickets:
FX rate source, multi-currency UI, and the cross-currency totals strategy. This is a design
document for a feature that is deliberately not in v1. Every claim about the current code is
cited by file and line; anything about a third party that could not be verified from a primary
source in this environment is marked unverified.

The three tickets and where each lands here:

| Ticket (06-audit-fixes.md:326-328) | Section |
|---|---|
| FX rate source design (API, caching, historical rates) | 2 |
| Multi-currency UI (wallet currency choice, transaction currency selection) | 4 |
| Cross-currency totals (convert to base, or show a reason instead of a number) | 5 |
| (the sprint's own "implementation plan for v2" done-when, line 334) | 6 |

---

## 1. Scope and non-goals

**What v2 means by multi-currency.** A wallet is denominated in exactly one currency, and a
user may hold wallets in more than one. Each transaction is denominated in the currency of the
wallet it touches, and each ledger row keeps the amount in its own currency alongside an amount
in the user's chosen base currency, so that totals and spending statistics remain computable
across the whole ledger. Currency is a property of a wallet and a posting, never of a
transaction as a whole: one transfer between an IDR wallet and a USD wallet is one transaction
whose two legs sit in two currencies.

**What stays out.**

- **No currency conversion of historical rows on a rate change.** A rate captured at write time
  stays as it was written (see section 3, historical rates).
- **No revaluation, no FX gain or loss line.** Converting an existing holding's value as the
  market moves is a portfolio concept. This is a personal ledger, and it records what happened,
  not what a balance is worth today.
- **No live rate feed in v2.0** (section 2 explains why, and what the honest fallback is).
- **No multi-currency budgets in this pass.** Budgets are keyed by category and hold one
  `amountMinor` with no currency column (`app/lib/data/database.dart:134-141`), so they are
  implicitly IDR like everything else today. Making a budget currency-aware is a follow-on, not
  a Sprint 17 design goal.

**v1 is single-currency and this document does not change that.** v1 ships one seeded wallet and
one currency. The capture sheet hardcodes it, `static const _currency = 'IDR'; // only currency
seeded so far; see Sprint 5` (`app/lib/features/capture/capture_sheet.dart:125`), the wallet
seed writes `currency: 'IDR'` (`app/lib/domain/default_categories.dart:42`), the CSV importer
passes `currency: 'IDR'` (`app/lib/features/import/import_screen.dart:110`), and the recurring
form does the same (`app/lib/features/recurring/recurring_screen.dart:241,383`). Nothing in
sections 2 to 6 is a v1 requirement.

**What is already currency-shaped in v1, and therefore costs nothing later.** The value type
carries a currency (`app/lib/core/money.dart:35-36`), it refuses to add two different currencies
and points the caller at the FX handling (`app/lib/core/money.dart:47-55`), an exponent table
already covers eight currencies so no code divides by a hardcoded 100
(`app/lib/core/currency.dart:22-31`), the numpad already conditions its decimal key on the
currency's exponent (`capture_sheet.dart:561-562`), the wallet table already has a `currency`
column and a `providerKey` column (`app/lib/data/database.dart:13-14`), the postings table
already has `currency`, `rate_to_base` and `base_amount_minor` (`database.dart:77-79`), and
`WalletsRepository.create` already takes a `currency` argument
(`app/lib/data/wallets_repository.dart:43-67`). v1's job was to avoid closing doors. Those doors
are open.

---

## 2. FX rate source design

The options, and what each actually costs. Prices, rate limits and terms of use are **not
verified here**; the "unverified" rows say what would confirm them, and no number in this
section should be relied on until that check is done.

### Option A: a free public rate API

Examples a reader would recognise: frankfurter.app, open.er-api.com, exchangerate.host.
**Unverified: current terms of use, rate limits, attribution requirements, whether a key is
now required, and whether historical rates are served.** Confirming means reading the
provider's own current pricing and terms page, and its documentation for the endpoint's
refresh cadence, before any code depends on it.

Runtime needs: a network dependency, an HTTP client in `pubspec.yaml` (there is none today, see
below), the `INTERNET` permission in the release manifest, a fetch-and-retry path, and error
handling for the offline case. Offline: does not work. Freshness: whatever the provider's
publication cadence is, which needs checking per provider; for a personal ledger a daily
granularity is enough, and any provider promising minute-level "live" rates is solving a problem
this app does not have. Caching: the fetched rates would have to be written to a local table
anyway, so the fetch is an optimisation on the cache, not the source of truth.

### Option B: a paid rate API

Examples: Open Exchange Rates, Fixer, Currencylayer, XE. **Unverified: plans, per-call pricing,
free-tier limits, licence terms for redistribution or for a shipped mobile app.** Confirming
means reading the vendor's current pricing page and its licence for mobile redistribution,
which is the part a free-tier comparison usually misses.

Everything Option A needs, plus a secret. A shipped local-first app with no server has nowhere
to keep an API key that a determined user cannot read out of the APK, so a paid key in a
client-side app is either a per-install key the user supplies (an account, which the product
does not have) or a public key, which is a liability. Realistically this option is only coherent
if a sync backend exists first (planned for v2, `plan/03-architecture.md:19`, `198-217`), which
puts it after this work, not in it.

### Option C: a manual, user-entered rate

The user types a rate. Cost: nothing. Runtime needs: a text field and a place to store the
number. Offline: works, fully. Freshness: exactly as fresh as the user cares to keep it, and the
app can show the date the rate was set so staleness is visible rather than silent. Caching: the
stored rate *is* the cache, dated. Accuracy: as good as the user's own source, and honest about
being theirs. This is the only option that does not change what the app is.

### Option D: Bank Indonesia published rates

Bank Indonesia publishes reference rates, including JISDOR for USD/IDR. **Unverified: whether a
stable machine-readable endpoint is offered, its update time, its terms of use for a mobile app,
and whether it covers anything other than USD/IDR.** Confirming means checking Bank Indonesia's
own published reference-rate page and its terms, not a third-party summary. Even if a usable
endpoint exists, it is a single pair against IDR, which does not generalise to "wallets in two
currencies" without two fetches and a cross-rate, and it still requires the network and the
permission. Its real value is as a **default value the user can accept** rather than a live feed:
a rate the user copies from a published reference is more defensible than one this app invented.

### Option E: no live source, per-transaction rates only

The weakest form of v2, and the honest floor: each transaction that crosses currencies asks for
a rate, or asks for both amounts, and records it on the posting (which the schema already
supports, `database.dart:78`). No currency table, no fetch, no staleness question, nothing to
keep fresh. The cost is that a *balance* in a second currency cannot be totalled alongside the
first, only listed beside it.

### Recommendation: Option C, manual rates, with no live fetch in v2.0

**Recommendation:** a manual, user-entered, date-stamped rate per currency pair, stored locally
and used for wallet and posting conversion, with **no live rate source in v2.0**; the
per-transaction rate already captured at write time stays the default for anything the user does
not override.

The reason is a constraint, not a preference. This app is local-first with no account and no
server, and it currently makes **zero network calls**. A grep across `lib/` for `http.`, `Dio(`,
`firebase` and `Sentry` found nothing (`DECISIONS.md:710-714`), the font is deliberately bundled
rather than fetched for exactly this reason (`app/pubspec.yaml:65-67`), and the release manifest
declares only `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` and `RECEIVE_BOOT_COMPLETED`, with
`INTERNET` present only in the debug and profile manifests that Flutter ships for tooling
(`app/android/app/src/main/AndroidManifest.xml:6-8`). Options A and D would each require adding
the `INTERNET` permission and a network call to a product whose drafted privacy policy says no
data is transmitted (`DECISIONS.md:706-714`), which turns a two-line rate lookup into a legal
and privacy change. Option B is not available without a server this app does not have. Option C
costs nothing that the app is not already paying, works offline as a local-first app must, and
keeps the promise the store listing and policy already make.

**How a live fetch would fit, if it is ever added.** Behind a feature flag (the pattern exists,
`FeatureFlags` at `database.dart:143-146`), off by default, opt-in, disclosed in plain Indonesian
in settings, and only *after* the privacy policy, the store listing and the manifest are updated
in the same change. When it is on, fetched rates land in the same local dated table a manual rate
would, so the manual path is the code path and the network is just a way to fill the field. That
ordering matters: it means the live source is an optional convenience, never something the ledger
depends on to render.

---

## 3. Data model

### What already carries the answer

Nothing here is proposed; it exists.

| Column | Location | What it does | Status |
|---|---|---|---|
| `accounts.currency` | `app/lib/data/database.dart:14` | Denomination of a wallet | Exists |
| `accounts.provider_key` | `database.dart:13` | Drives the logo; unrelated to currency but already nullable text | Exists |
| `postings.amount_minor` | `database.dart:76` | Signed amount in the posting's own currency | Exists |
| `postings.currency` | `database.dart:77` | The posting's currency | Exists |
| `postings.rate_to_base` | `database.dart:78` | Rate captured at write time, default `1.0` | Exists |
| `postings.base_amount_minor` | `database.dart:79` | The amount in base currency; what the sum-to-zero invariant reads | Exists |
| `daily_totals.net_minor` | `database.dart:90-96` | Per-day net, currently summed from `amount_minor` | Exists, see the gap below |

`PostingsRepository.insertTransaction` already validates the invariant on
`baseAmountMinor`, not on `amountMinor` (`app/lib/data/postings_repository.dart:30`), and
`updateTransaction` exists and does the same on rewrite (`postings_repository.dart:42-62`). So
the write path for a correct multi-currency transaction is already in place. What is missing is
that nobody writes a rate: `capture_sheet.dart` writes `baseAmountMinor: _amount.minor` with no
`rateToBase` at all (`capture_sheet.dart:362,370,403,411`), which is correct only because the
base currency is IDR and the posting currency is IDR, where the rate is 1.0 by definition
(`database.dart:78` default).

### What has to be added

1. **A stored base currency.** `AppSettings` is the single-row settings table
   (`database.dart:101-127`) and it has no base-currency column: it holds `periodStartDay`,
   `lastAcknowledgedPeriodClose`, the custom-period fields, `lastSalaryMinor`, the payday fields
   and `budgetSnapshotsJson`, and nothing else. Add `base_currency TEXT NOT NULL DEFAULT 'IDR'`.
   The default matters: it matches every existing row and every seeded wallet, so an upgrade is
   a no-op for a v1 user.

2. **A dated rate table.** The `@DriftDatabase` table list (`database.dart:220-232`) has no rate
   table, so one is genuinely new. Minimum shape:

   ```
   fx_rates(
     base       TEXT NOT NULL,   -- e.g. 'IDR'
     quote      TEXT NOT NULL,   -- e.g. 'USD'
     rate       REAL NOT NULL,   -- units of base per one unit of quote
     as_of_day  INTEGER NOT NULL,-- day bucket, same space as daily_totals.day
     source     TEXT NOT NULL,   -- 'manual' | 'bi-jisdor' | provider key
     updated_at INTEGER NOT NULL,
     PRIMARY KEY (base, quote, as_of_day)
   )
   ```

   `rate` is the one place a float is acceptable, and only as a stored fact, never inside a
   running balance: the base amount is computed once, rounded, and stored as an integer in
   `base_amount_minor`. `Money.toMajorForDisplayOnly` already documents this discipline
   (`app/lib/core/money.dart:104-108`).

   State the direction of the rate in the column and the code, because a rate with an implicit
   direction is a bug waiting for a reviewer: **multiply an amount in `quote` by `rate`,
   round once, and that is its value in `base`**.

### The migration path

Schema is at v11 (`database.dart:237`), and the migration hook is already a list of guarded
steps (`database.dart:242-296`), so this is a v12 bump in that pattern:

- `if (from < 12)` create `fx_rates` and `addColumn` the new `base_currency` to `app_settings`.
- Watch the gotcha this repo already hit and documented: `createTable` builds from the *current*
  Dart definition, so a table created at `from < 4` gets every column including ones added later,
  and only a database that already had the table needs an explicit `addColumn`
  (`database.dart:263-266`, `DECISIONS.md:497-512`). `app_settings` is created at `from < 4`, so
  `base_currency` needs the `from >= 4 && from < 12` guard, not an unguarded `addColumn`.
- Backfill: existing rows need no change. Their postings are all rate 1.0 in the same currency
  as the base, so their `base_amount_minor` is already correct. No data migration, only a column
  with a default.
- The forward-and-back migration test from the prior release is the repo's established pattern
  (`DECISIONS.md:81-85`, `235`), and this bump is a straightforward case for it.

### Historical rates: what happens when a rate is corrected

`plan/03-architecture.md:107` states the rule, `never recomputed`, and lines `129-131` state why.
A rate captured at write time cannot be re-derived later, because nothing records what the market
rate was on a past date: the app would need a historical rate feed to reconstruct it, which is one
of the things section 2 declines. So:

- **A correction affects future writes only.** If the user fixes a wrong rate in settings,
  already-written postings keep the rate they were written with. Their base amounts were correct
  relative to the rate in force at the time, which is the honest record of what the user knew.
- **Fixing a past transaction is an explicit per-row edit, not a recompute.** The path exists:
  `updateTransaction` rewrites a transaction's postings and re-runs the daily totals
  (`postings_repository.dart:42-62`), so a user who wants to correct one historical row can, by
  reopening that transaction and changing its currency or its amount. That is a deliberate,
  auditable action with an undo affordance, not a silent re-derivation of history.
- **Never re-derive on app open.** A bulk backfill on launch would silently change past reports,
  which is the exact failure `plan/03-architecture.md:129-131` exists to prevent, and would make
  a historical report depend on today's rate.
- **Show the rate on the row.** A converted amount is never rendered without the rate that made
  it available (`plan/04-ux-design.md:138-139`: "A total that mixes currencies is labelled as
  converted, with the rate reachable").

### Cross-currency transfers and the invariant

The invariant is that the sum of `base_amount_minor` across a transaction's postings is zero
(`plan/03-architecture.md:126-127`, enforced at `postings_repository.dart:30-31`). A transfer
between an IDR wallet and a USD wallet has two legs in two different currencies, so it is not one
amount times one rate. The design: the user supplies both amounts (what left the first wallet,
what arrived in the second), and the second leg's `rate_to_base` is derived from the two amounts
so the two base legs cancel exactly by construction. Each posting stores its own rate, which is
what makes this work; a single transaction-level rate would force one of the two amounts to be
wrong. Rounding at the boundary must be one rounding per leg onto an integer
`base_amount_minor`, never accumulated in floats.

---

## 4. UI design

### Wallet creation with a currency choice

`WalletsRepository.create` already takes `currency`
(`app/lib/data/wallets_repository.dart:47`), so this is a UI addition, not a data one. The
creation form gains a currency field, defaulting to the current base currency, listing the codes
`CurrencyInfo` already knows (`app/lib/core/currency.dart:22-31`) plus whatever the rate table
can source a rate for. Copy rule: name the currency, do not abbreviate it to a flag or a symbol,
since `$`, `A$` and `S$` are three different currencies with overlapping symbols
(`currency.dart:25,28,30`).

Constraints:

- **Changing a wallet's currency after it has postings is refused.** Every posting carries its own
  currency and its own base amount (`database.dart:77-79`), so a wallet holding a history in IDR
  cannot become a USD wallet without either re-writing history or lying about it. Offer the honest
  alternative: create a second wallet in the other currency. A wallet with no postings may still
  be corrected.
- **The currency is shown on the wallet row whenever more than one currency exists**, matching
  `plan/02-flows.md:71`'s existing rule for the amount field ("with the currency only shown when
  more than one currency exists"). Do not add a second currency label to a single-currency ledger.

### Transaction currency selection

The capture sheet's currency field is currently a hardcoded constant
(`capture_sheet.dart:125`), and every posting it writes uses it
(`capture_sheet.dart:362,370,403,411`). The v2 change:

- **The currency follows the selected wallet, and is not separately chosen.** A transaction in a
  USD wallet is in USD. Adding an independent currency picker would let a user record dollars
  against a rupiah wallet, which the balance query cannot represent. The wallet selector already
  exists (`plan/02-flows.md:72`), so this is a consequence of that choice, not a new control.
- **The numpad re-reads the exponent when the wallet changes.** The plumbing is there
  (`capture_sheet.dart:134,561-562`), but `_amountBuffer` is re-initialised on kind change
  (`capture_sheet.dart:253-255`); the same reset has to happen when a wallet with a different
  exponent is selected, or a USD amount typed after a JPY wallet would carry the wrong scale.
- **A cross-currency transfer asks for both amounts** (see section 3) and shows the rate it
  derives from them, stated with the leg it applies to.
- **A conversion the user has to make is stated, never guessed.** If the transaction's currency
  differs from the base currency, the row is written with the posting's own currency and its
  base amount, and the rate is stored on the posting.

### Display rules

These hold everywhere, and they are the same rules the shipped code already follows.

1. **A number that cannot be computed renders blank with a reason, never as zero**
   (`plan/04-ux-design.md:118`, chart rule 8). This applies to a cross-currency total with no
   usable rate exactly as it applies to a zero.
2. **A converted total is labelled as converted, with the rate reachable**
   (`plan/04-ux-design.md:138-139`).
3. **If it cannot be labelled, show each currency separately rather than one wrong number**
   (same lines), which is also the Kantong error-state rule in the states table
   (`plan/04-ux-design.md:154`: "Converted total falls back to per-currency lines").
4. **One precision per screen** (`plan/04-ux-design.md:109-110`): a converted total and the rows
   under it do not mix "Rp 7.691.700" with "Rp 8jt".
5. **Sign and label, never colour alone** (`plan/04-ux-design.md:117`), which is already how
   `MoneySign.explicit` is used (`app/lib/core/money_formatter.dart:8-12`).
6. **Nothing new calls `NumberFormat`.** All rendering stays behind `MoneyFormatter`
   (`money_formatter.dart:32`), per `plan/03-architecture.md:42-43`.

---

## 5. Cross-currency totals strategy

### What ships today, and why this design keeps it

The wallet-total card renders a reason, not a number, when wallets span more than one currency.
`_TotalCard` groups balances by currency
(`app/lib/features/wallets/wallets_screen.dart:179-187`); when there is more than one group it
prints `Belum bisa dijumlah` (`wallets_screen.dart:212`) with the reason "Beda mata uang butuh
kurs, dan wudget tidak mengambil kurs dari internet. Saldo per mata uang ada di bawah."
(`wallets_screen.dart:216-220`) and then lists each currency on its own line
(`wallets_screen.dart:222-240`). Each wallet group's inline total is likewise suppressed when the
group holds more than one currency, via `_singleCurrency`
(`wallets_screen.dart:109-117`, `126-127`). `DECISIONS.md:123-131` records the reasoning, and it
is the same one this document follows: a fabricated exchange rate is as much a fabricated number
as a made-up zero.

### The three candidate strategies

| Strategy | Renders | Honest when | Cost |
|---|---|---|---|
| Per-currency lines, no combined figure | One line per currency, plus a stated reason | Always, with no rate at all | The user never sees one number for "everything" |
| Converted total, with the rate named and reachable | One figure plus the rate and its date | A usable rate exists and is not stale | Needs the rate table and a staleness policy |
| Nothing, or zero | Blank or `0` | Never | Violates chart rule 8 |

### Recommendation: per-currency lines by default, a converted total only when a dated rate exists

**One deliberate recommendation:** keep the shipped behaviour as the default and make the
converted total the *conditional* case.

- **Default (no usable rate): per-currency lines with the reason.** This is what
  `wallets_screen.dart:210-241` already does. It is not a placeholder for the real feature; it is
  the correct rendering for a local-first app whose rate source is the user's own input.
- **When a dated, non-stale rate exists for every currency in the total: render the converted
  total, labelled with the rate and its date.** The label is not decoration; it is what
  `plan/04-ux-design.md:138-139` requires, and it is what separates this from the Ollo
  total-versus-rows inconsistency that `plan/02-flows.md:140-142` cites as the cautionary case.
- **A stale rate degrades to per-currency lines, not to a wrong number.** "Stale" is a stated
  policy, not a vibe: the design proposes a threshold measured in days (a personal ledger does not
  need an hourly rate) and requires that the threshold be written down in settings so the user can
  see why a total disappeared. The value of the threshold is a product call, deliberately left
  open in section 7.
- **One missing pair is enough to fall back.** A total spanning IDR, USD and SGD with no SGD rate
  shows three per-currency lines plus the reason naming SGD, rather than a figure that silently
  omits one currency or invents its rate.
- **Pantau's aggregates read `base_amount_minor`, never a converted-at-render figure.** Spending
  statistics are computed from the ledger, so they follow the same rule as a balance and do not
  need a live rate at render time at all. This is the reason to fill `base_amount_minor` on every
  write path rather than converting at read time: a total that is computed the same way twice is
  a total that cannot disagree with itself, which is the class of bug `plan/03-architecture.md:45-48`
  is written to make impossible.

---

## 6. Implementation plan for v2

**What has to be true before the first ticket starts.**

1. v1 ships and is in the stores. This is a v2 design; Sprint 17's own cut list places
   multi-currency after v1 (`06-audit-fixes.md:353,362`).
2. **Sprint 1's daily-totals fix has landed.** `daily_totals_repository.dart:107` still sums
   `amountMinor` into `netMinor`, which Sprint 1 ticket 2 names outright as "sums amountMinor
   instead of baseAmountMinor, breaking multi-currency" (`06-audit-fixes.md:13`). Multi-currency
   cannot begin on top of an aggregate that mixes currencies in a column that has no currency.
3. **Every aggregate that sums `amount_minor` is found, not guessed.** Ticket 4 below is that
   audit; it must run before the feature is switched on for anyone.
4. A product decision on the base currency at first run for an existing v1 user (the proposed
   default is `IDR`, matching the seeded wallet at `default_categories.dart:42`).
5. A product decision on the staleness threshold from section 5.

| # | Ticket | Size | Depends on |
|---|---|---|---|
| 1 | Schema v12: `fx_rates` table and `app_settings.base_currency`, with the guarded migration and the forward/back test | S | 1, 4 |
| 2 | `FxRatesRepository`: read the rate for a pair as of a day, write a manual dated rate, and the pair-to-pair lookup for the converted total | M | 1 |
| 3 | Base-currency setting in settings UI, defaulting to IDR, with the rate field beside it and the set date visible | S | 1 |
| 4 | Write `rate_to_base` and `base_amount_minor` on every posting write path: capture (including transfers, section 3), CSV import, recurrence materialisation, and the recurring/reminder paths that hardcode `'IDR'` (`import_screen.dart:110`, `recurring_screen.dart:241,383`) | M | 2 |
| 5 | Aggregate audit: switch every sum of `amount_minor` to `base_amount_minor`, starting with `daily_totals_repository.dart:107`, then period totals, budget history, category ranking and `WalletsRepository.watchWallets` | M | 4 |
| 6 | Wallet currency choice at creation, with the postings guard that refuses a currency change on a wallet that has history | S | 4 |
| 7 | Capture: currency follows the selected wallet, numpad exponent re-initialises on wallet change, and a cross-currency transfer asks for both amounts | M | 4, 6 |
| 8 | Cross-currency totals: per-currency lines by default, the labelled converted total when a non-stale rate exists, and the reason text naming the missing pair | M | 2, 5, 7 |
| 9 | Test matrix: property tests for the rounding-once rule and the sum-to-zero invariant across two currencies, golden tests for `MoneyFormatter` in a second currency, and a multi-currency migration test | M | 8 |

Sizes are relative (S, M) rather than day estimates, since v1's own sprint estimates in
`plan/06-audit-fixes.md` are story points per sprint and this plan is not a sprint schedule.

---

## 7. Risks and open questions

**Risks.**

- **The aggregate audit (ticket 5) is the real risk, not the schema.** `rate_to_base` and
  `base_amount_minor` have existed since v1 with nobody writing anything but the default 1.0, so
  every query that sums `amount_minor` has been correct only by accident. The one already-known
  instance is `daily_totals_repository.dart:107`; the danger is a sixth or tenth call site nobody
  checked. Mitigation: the audit ticket is explicit, and the sum-to-zero invariant plus a
  two-currency property test is the backstop that catches what a reading pass misses. If a shared
  predicate turns out to be needed rather than per-call-site edits, that signal is already
  documented (`DECISIONS.md:164-170`).
- **A rounding drift between `amount_minor` and `base_amount_minor`** on a 0-exponent base such as
  IDR, where the converted amount has no fractional minor unit to land on. The rule (round once,
  store the integer, never accumulate floats) must be stated in the repository and pinned by a
  property test, or two screens will disagree by one rupiah, which is exactly the class of bug
  `plan/03-architecture.md:45-48` exists to prevent.
- **Scope creep into budgets, Pantau charts and goals.** Each of those reads aggregates and each
  would want its own currency policy. Section 1 keeps them out of this pass; the risk is that the
  aggregate audit touches them anyway and a reviewer cannot tell an audit from a redesign.
- **The privacy posture is a one-way door.** Adding a live rate source later means editing the
  privacy policy, the store listing, the manifest and the drafted legal files in one change. If
  that change is made casually, the app's stated position (no data transmitted) becomes false
  (`DECISIONS.md:706-714`, `app/pubspec.yaml:65-67`).
- **Import correctness.** CSV import hardcodes `currency: 'IDR'` (`import_screen.dart:110`) and
  auto-creates accounts it does not recognise (`DECISIONS.md:536-541`). A competitor export
  containing a foreign currency would be recorded as rupiah with no warning. The mapping screen
  needs a currency column or an explicit refusal, and that decision is not made here.

**Open questions.**

1. **What is the staleness threshold** for a stored rate, in days, and where is it shown?
2. **Base currency at first run for an existing user:** is IDR the right silent default, or should
   the upgrade ask once? The proposal here is the silent default, since every existing row is IDR.
3. **Does a cross-currency transfer ask for both amounts, or for one amount and a rate?** Section 3
   proposes both amounts with the rate derived, but the one-amount-and-a-rate form may be what a
   user actually has in hand (a receipt showing the rate).
4. **Should a wallet with history ever be re-denominated?** Section 4 refuses it. If a user
   imported a USD wallet as IDR by mistake, refusal turns a fixable error into a data-entry
   problem with no in-app remedy.
5. **Are the third-party rate options in section 2 still viable at all?** Every price, limit and
   term there is unverified in this environment. Confirming each one against the provider's own
   current terms page is a prerequisite for revisiting the recommendation, not a formality.