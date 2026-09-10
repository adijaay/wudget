# Architecture

Flutter, local-first, one codebase for Android and iOS. Pin exact package versions at
implementation time rather than trusting the ones written here.

---

## Stack

| Layer | Choice | Reason |
|---|---|---|
| UI | Flutter | Both stores from one codebase, and Android is what Indonesia runs |
| State | Riverpod | Compile-time safe providers, testable without a widget tree, no BuildContext plumbing for repositories |
| Database | SQLite via Drift | Typed queries, real migrations, and SQL for the aggregate queries the review surfaces need |
| Routing | go_router | Deep links for the widget and notification entry points |
| Local notifications | flutter_local_notifications | Bill and period-close reminders with scheduled delivery |
| Home widgets | home_widget plus native widget code | The widget has to render without booting the Flutter engine |
| Formatting | intl, wrapped in one internal service | Never called directly from a widget, see Money below |
| Sync (v2) | Postgres with row-level security, local-first replication | MELD ships Supabase with RLS for the same job, so the pattern is proven in this market |

Deliberately not used in v1: any bank aggregation SDK, any analytics SDK that ships data off
device by default, and any state management that makes the capture screen rebuild more than it
must.

---

## Money

The single most important rule in the codebase.

```dart
// An amount is a count of the currency's smallest unit, never a double.
class Money {
  final int minor;        // 15000 IDR, or 1250 for USD 12.50
  final String currency;  // ISO 4217
}
```

- `int64` minor units. No `double`, no `float`, anywhere in the path from entry to balance.
- The exponent comes from a currency table (IDR 0, USD 2, JPY 0), not from a constant 100.
- Arithmetic lives on `Money`. Adding two different currencies throws rather than coercing.
- Rendering happens only in `MoneyFormatter`, one service, one rule, injected. A lint rule
  or a test forbids `NumberFormat` outside it.

Why this is written down first: three of the six apps audited render the same fact two
different ways on a single screen
([research/07-ui-audit.md](../research/07-ui-audit.md)). One formatter with golden tests
makes that class of bug structurally impossible.

**IDR specifics.** No decimal places. Thousands separated with `.` per Indonesian convention.
`Rp` prefix with a non-breaking space. Tabular figures so columns align.

---

## Data model

The shape is a postings ledger, which is what makes transfers and card payments correct.
Illustrative DDL, not final:

```sql
-- Accounts: wallets, cards, savings, debts
CREATE TABLE accounts (
  id            TEXT PRIMARY KEY,        -- uuid v7, sortable, sync friendly
  name          TEXT NOT NULL,
  type          TEXT NOT NULL,           -- cash|bank|ewallet|card|savings|debt|other
  provider_key  TEXT,                    -- 'gopay','bca',... drives the logo
  currency      TEXT NOT NULL,
  opening_minor INTEGER NOT NULL DEFAULT 0,
  -- card only
  statement_day INTEGER, due_day INTEGER, credit_limit_minor INTEGER,
  archived_at   INTEGER,
  -- sync columns, present from v1 even though sync ships in v2
  household_id  TEXT, visibility TEXT NOT NULL DEFAULT 'private',
  updated_at    INTEGER NOT NULL, deleted_at INTEGER, device_id TEXT
);

CREATE TABLE categories (
  id TEXT PRIMARY KEY, parent_id TEXT REFERENCES categories(id),
  name TEXT NOT NULL, kind TEXT NOT NULL,      -- expense|income
  icon_key TEXT NOT NULL, hue_index INTEGER NOT NULL,
  is_irregular INTEGER NOT NULL DEFAULT 0,     -- the exceptional-expense bucket
  sort_order INTEGER NOT NULL,
  updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,                          -- expense|income|transfer|adjustment
  occurred_at INTEGER NOT NULL,                -- utc millis
  tz_offset_minutes INTEGER NOT NULL,          -- so "which day" survives travel
  title TEXT, note TEXT,
  recurrence_id TEXT REFERENCES recurrences(id),
  is_projected INTEGER NOT NULL DEFAULT 0,     -- forecast, not fact
  lat REAL, lon REAL,                          -- opt in only
  household_id TEXT, visibility TEXT NOT NULL DEFAULT 'private',
  updated_at INTEGER NOT NULL, deleted_at INTEGER, device_id TEXT
);

-- Two or more per transaction. They must sum to zero in base currency.
CREATE TABLE postings (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL REFERENCES transactions(id),
  account_id  TEXT REFERENCES accounts(id),    -- null on the category leg
  category_id TEXT REFERENCES categories(id),  -- null on the account leg
  amount_minor INTEGER NOT NULL,               -- signed
  currency TEXT NOT NULL,
  rate_to_base REAL NOT NULL DEFAULT 1.0,      -- captured at write time, never recomputed
  base_amount_minor INTEGER NOT NULL
);
```

How the four kinds map to postings:

| Kind | Postings |
|---|---|
| Expense | account leg negative, category leg positive |
| Income | account leg positive, category leg negative |
| Transfer | from-account negative, to-account positive, no category leg |
| Adjustment | account leg signed, equity leg opposite, flagged as a correction |

A credit card purchase is an expense whose account is the card. A card payment is a transfer
from bank to card. Because the payment has no category leg, it cannot appear in spending
statistics, which is the specific defect reported against both Ollo and Money Manager
([research/04-user-reviews.md](../research/04-user-reviews.md)).

**Invariant, enforced by test and by a debug assertion.** For every transaction, the sum of
`base_amount_minor` across its postings is zero.

**FX.** Rate is captured when the row is written and stored on the posting, so a historical
report never changes because today's rate moved. Taken from Expensa, and it is impossible to
add correctly after the fact ([research/01-app-teardowns.md](../research/01-app-teardowns.md)).

**Balances.** Derived by summing postings, with a materialised per-account, per-day aggregate
table kept current by trigger or by the repository. The list and the pace card read the
aggregate; nothing recomputes the whole history to render a screen.

---

## Periods

A period is a half-open interval derived from a user setting, not a calendar month.

```
month_start_day = 1..28 (28 caps it so every month has the day)
period(n) = [start_n, start_{n+1})
```

Every aggregate query takes a period, and the period selector at the top of Pantau is the
single source of it. Payday alignment is why this is a first-class concept rather than a
`WHERE strftime('%m')` filter.

---

## Recurrence

Stored as a rule, materialised forward to a watermark, with per-instance overrides. This is
the area where every audited app has at least one defect, so the rules are explicit.

```sql
CREATE TABLE recurrences (
  id TEXT PRIMARY KEY,
  template_json TEXT NOT NULL,      -- the transaction to create
  freq TEXT NOT NULL,               -- daily|weekly|monthly|yearly
  interval_n INTEGER NOT NULL DEFAULT 1,
  by_month_day INTEGER,             -- 1..31, or -1 for last day
  by_weekday INTEGER,
  weekend_rule TEXT NOT NULL DEFAULT 'none',  -- none|before|after
  amount_mode TEXT NOT NULL DEFAULT 'fixed',  -- fixed|varies
  expected_min_minor INTEGER, expected_max_minor INTEGER,
  starts_on INTEGER NOT NULL, ends_on INTEGER,
  generated_until INTEGER NOT NULL,
  updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE recurrence_overrides (
  recurrence_id TEXT NOT NULL, instance_date INTEGER NOT NULL,
  action TEXT NOT NULL,            -- skip|move|amend
  new_date INTEGER, new_amount_minor INTEGER,
  PRIMARY KEY (recurrence_id, instance_date)
);
```

Rules that must hold:

- Day 31 in a 30-day month clamps to the last day, and the following month returns to 31. A
  clamp never becomes permanent, which is a reported Money Manager bug.
- `weekend_rule` shifts the due date without altering the underlying schedule.
- A generated instance is a real `transactions` row with `is_projected = 1`. Confirming it
  clears the flag. Projected rows are excluded from actual spending everywhere, by a shared
  query predicate rather than by each call site remembering.
- Editing an instance writes an override. Editing the series changes the rule, and the app
  asks which one the user meant.
- Materialisation runs on app open and on a background trigger, and is idempotent, so a
  missed run cannot produce the reported failure where a month of entries all appear at once.

---

## Sync (v2), designed for in v1

Every table already carries `id` as uuid v7, `updated_at`, `deleted_at`, `device_id`,
`household_id` and `visibility`. That is the entire cost of being sync-ready in v1.

**Model.** Local SQLite stays authoritative. Changes queue in an outbox and replicate to
Postgres. Row-level security scopes every row to its household, and to its owner for private
rows.

**Conflict rule, stated rather than left to chance.** Transactions and postings are
append-mostly: an edit writes a new version and supersedes the previous one, so nothing is
silently overwritten and the audit trail survives. For the mutable objects (accounts,
categories, budgets) resolution is last-writer-wins per field on `updated_at`, with the
device clock skew bounded by a server timestamp on receipt. Deletes are soft and always win
over a concurrent edit.

**Failure behaviour, which is the whole reason the benchmarks lost users.** Sync failing is
not an error state that blocks the app. The local ledger renders and accepts writes, and a
non-blocking indicator says when it last synced. A stale ledger is never presented as
current ([research/04-user-reviews.md](../research/04-user-reviews.md)).

---

## Backup, restore, import

- **Automatic local backup**, scheduled, keeping the last N snapshots, with the last backup
  time surfaced in the UI.
- **Export**: CSV for humans and spreadsheets, JSON for a lossless round trip including
  postings, recurrence rules and overrides.
- **Restore**: a dry run reporting what will be created and replaced, then an explicit
  confirmation.
- **Import**: Money Manager and Ollo CSV, with a column mapping step, per-row validation, and
  a partial import that keeps the valid rows and reports the failures with row numbers.
- **Never** gate export or history behind a paywall.

Migrations are versioned, tested in both directions, and every release ships a migration test
that runs against a fixture database built by the previous release. The Money Manager review
describing an update wiping categories and accounts is what this prevents.

---

## Performance budget

The capture path is the product, so it gets numeric targets and a release gate.

| Path | Target on a mid-range Android device |
|---|---|
| Cold start to interactive capture sheet | under 1.5 s |
| Widget tap to capture sheet | under 800 ms |
| Save to sheet dismissed | under 100 ms, and never blocking on I/O |
| Catat tab render, 10,000 transactions | under 300 ms from the daily aggregate |
| Pantau tab render | under 500 ms, all aggregates precomputed |

Measured on a real low-to-mid device, not on a simulator. A regression is a release blocker.
Spendee's redesign is the cautionary case: a better-looking app that people could not type
into fast enough ([research/04-user-reviews.md](../research/04-user-reviews.md)).

---

## Testing

| Kind | What it covers |
|---|---|
| Property | Postings sum to zero for every generated transaction; balances equal the sum of postings after any sequence of edits |
| Golden | `MoneyFormatter` across IDR, USD, JPY, negative, zero, and large values; the capture sheet in light and dark, at default and 200 per cent text scale |
| Migration | Every version pair, forward and back, against a fixture from the previous release |
| Recurrence | A table-driven suite of the edge cases listed above, month-end and weekend rules included |
| Integration | Import a real competitor CSV export and assert the resulting balances |
| Accessibility | Contrast assertions on the token pairs, and semantics labels present on every interactive element |

---

## Privacy and permissions

- No account, no email, no phone number in v1.
- Location is opt-in per user and off by default, and the geotag is stored locally only.
- No third-party analytics SDK in v1. If product measurement is needed, it is aggregate,
  on-device where possible, and disclosed in the settings screen in plain Indonesian.
- The privacy policy and terms exist before the first store submission, because a product
  that asks for money or an account without them is the pattern flagged in
  [research/03-flows-and-ux.md](../research/03-flows-and-ux.md).

---

## What gets measured

Engagement is not the outcome. Both budget experiments in the research raised engagement and
neither reduced spending
([research/05-behavioral-research.md](../research/05-behavioral-research.md), section 11).

| Metric | Why it is on the list |
|---|---|
| Median time-to-save per entry | The capture bet, stated numerically |
| Entries per active day, and days logged per period | Whether capture actually happens |
| Day 7 and day 30 retention | The category's known failure point |
| Lapse and return rate | Abandonment is normal, so recovery is the real number |
| Budget proposal acceptance and edit distance | Whether proposing beats asking |
| Pace framing against remaining-balance framing, behind a flag | The one contested bet in the plan |
| CFPB financial well-being scale at day 90, opt-in | The actual outcome, and the instrument is free and validated |

---

## Repository layout

```
lib/
  core/         money, periods, formatting, result types, clock
  data/         drift schema, daos, migrations, outbox, importers
  domain/       entities, invariants, recurrence engine, budget proposal
  features/
    capture/    the sheet, templates, numpad
    ledger/     Catat tab
    review/     Pantau tab, pace, forecast, rankings
    wallets/    Kantong tab
    goals/
    settings/   backup, restore, import, export
  design/       tokens, typography, components, charts
test/
  property/ golden/ migration/ recurrence/ integration/
```

`design/` is a real layer, not a folder of stray widgets. Tokens live there, the chart rules
from [04-ux-design.md](04-ux-design.md) are enforced there, and no feature defines a colour
or a text style of its own.
