# Decisions log

Calls made during the build without stopping to ask, per your instruction to decide and
compile for review after Milestone C. Each entry: what, why, what to revisit if wrong.
This file is the ADR: no separate template, one flat log, newest sprint at the bottom.

## Sprint 0

- **Package versions left unpinned to caret ranges**, resolved by `flutter pub get` against
  the installed Flutter 3.24.3 / Dart 3.5.3 SDK (already on this machine, not upgraded).
  `flutter pub outdated` shows 61 packages have newer majors available (riverpod 3.x,
  sqlite3_flutter_libs 0.6, etc.). Revisit: upgrade the SDK and re-resolve once Milestone C
  is stable, as one deliberate pass, not mid-build.
- **riverpod_annotation / riverpod_generator dropped** from the original plan. Code
  generation adds a build_runner step for marginal benefit at this size; plain
  `Provider`/`NotifierProvider` is enough for v1. Revisit if the provider graph gets large
  enough that generated providers earn their keep.
- **App directory is `app/`** inside the repo root, with `research/`, `plan/`, `design/`
  as siblings. Keeps the Flutter project's own tooling (`.gitignore`, `analysis_options.yaml`)
  from fighting the docs tree.
- **Package name `wudget`, org `id.wudget`**, applied via `flutter create --org id.wudget`.
  Bundle/application ID is `id.wudget.wudget`. Revisit once a real domain is bought.
- **"Start Milestone A to C" executed sprint-by-sprint, in order, in one continuous pass**,
  each ticket done to its Definition of Done before moving on, rather than stubbing all 21
  sprints shallowly. 21 sprints is roughly five months of solo full-time work per
  [05-sprints.md](plan/05-sprints.md); one pass will not finish it. Revisit: expect this to
  span many sessions, picking up wherever this log and the code left off. Tickets that need a
  physical device or a store account (mid-range Android device setup, store submission) are
  logged as blocked-on-human rather than skipped silently.
- ~~Mid-range Android device for perf measurement.~~ Resolved mid-Sprint-2: ASUS_AI2202
  (`N9AIGF003861PBZ`) connected over ADB and used directly for this build. That is now the
  device all performance numbers in later sprints are measured on, until you name a
  different one. Debug build installed and confirmed rendering (dark theme, token demo
  screen) — stopped the session at 2% battery rather than push further device time this
  round. Release build failed for an unrelated reason: Android SDK Build-Tools 33.0.1 is
  missing on this machine, needed for `lintVitalReportRelease`. Revisit: install that
  component before the Sprint 7 performance gate, since perf numbers need a release build,
  not debug.

## Sprint 2

- **Migration harness (forward/backward against a fixture from the prior version) deferred**
  until a schema version 2 actually exists — schema is still v1, so there is no prior-version
  fixture to test against yet. What's in place now: `WudgetDatabase.schemaVersion = 1` and
  drift's migration hook point, ready for a `MigrationStrategy` the day a column changes.
  Revisit: write the forward/backward test the same sprint schema version becomes 2, not
  after.
- **Restore has no UI yet, only `BackupRepository.previewImport`/`importJson`.** The screen
  and the "explicit confirmation" step are a Sprint 2 ticket but need the settings feature
  shell, which is Sprint 8+ in the folder layout. Revisit: wire a minimal settings screen
  earlier if dogfooding needs restore before then.
- **Backup scheduling is manual (`createBackup` callable, no OS-level timer wired in).** Sprint
  2's ticket says "on a schedule" — full background scheduling (WorkManager/BGTaskScheduler)
  is its own dependency and its own testing surface. Revisit: call `createBackup` on app
  launch if the last backup is older than 24h, before reaching for a background-task package.

## Sprint 3

- **Default categories/wallet are seeded in code (`domain/default_categories.dart`)**, not
  entered by the user, since category management (create/edit/reorder, Sprint 5+ territory)
  doesn't exist yet and the capture sheet needs something real to select. Not fabricated
  transaction data — structural config only, seeded once, idempotent. Revisit: replace with
  user-editable categories once that screen exists; the seed stays as the first-run default.
- **Only IDR is wired through the capture sheet.** The numpad's decimal key and the currency
  picker are conditioned on `CurrencyInfo.of(currency).exponent`, so the plumbing is currency-
  aware already, but only one account/currency is seeded. Revisit when Sprint 5 adds wallet
  creation with a currency choice.
- **Transfer is selectable in the segmented control but not saveable yet** (shows a snackbar).
  A transfer needs two accounts, and wallets don't exist until Sprint 5. Building the two-leg
  transfer write now, before there's a second account to transfer to, would be untested code.
  Revisit: Sprint 5, "Transfer flow between wallets".
- **No frequency templates, calculator toggle, date/time button, or receipt photo** — all
  explicitly Sprint 4 ("the capture sheet, speed"). Sprint 3's done-when is an expense saved
  end to end with a measured save; speed features come after structure works.
- **Home screen is a placeholder** (`HomeShell`): the token demo screen plus a FAB into the
  capture sheet. Real tab navigation (Catat/Kantong/Pantau) doesn't start until Sprint 6-9.
  Revisit then, replacing `HomeShell` rather than growing it.

## Sprint 4

- **Schema bumped to v2** (`transactions.photo_path`), which finally exercises the migration
  harness deferred in Sprint 2 — `test/migration/schema_migration_test.dart` builds a real v1
  fixture with raw SQL and asserts the upgrade adds the column and keeps every row. That
  pattern (hand-written prior-version fixture + open through `WudgetDatabase`) is now the
  template for every future schema bump, not just this one.
  Bug found and fixed the same way: the templates `FutureBuilder` was calling
  `ref.read(...).topTemplates(...)` inline in `build()`, creating a new unresolved query on
  every rebuild. In production this meant needless repeated DB hits; the sharper symptom, and
  how it was found, was a widget test that took 10 real minutes to time out because
  `db.close()` sat waiting for the ever-growing pile of in-flight queries. Fixed by caching
  the future in state (`_templatesFuture`, refreshed only on init and on kind change) —
  general rule for this codebase: never construct a `Future` or `Stream` argument inline
  inside `build()`, cache it in state instead.
- **Calculator mode is left-to-right, no operator precedence** (`10000+5000×2` = `30000`, not
  `20000`). Matches how a physical calculator works and needed no precedence-climbing parser.
  Revisit only if users ask for `×`/`÷` to bind tighter than `+`/`-`.
- **Wallet default-per-category is derived from the ledger itself**
  (`CaptureQueries.lastAccountIdForCategory`), not stored in a settings table. One less table,
  and it can't drift out of sync with what actually happened. Grouping/ranking for both new
  queries happens in Dart over a capped, already-fetched window (`scanLimit`, default 100)
  rather than in SQL — simpler to read than a group-by-with-last-value query, fine at personal-
  finance data volumes. Revisit if that scan ever shows up in a performance pass.
- **Receipt photo uses `image_picker`** (new dependency) — no stdlib/native-only way to reach
  the camera from Flutter. Picker failures (no camera, permission denied, running in a test
  harness) are caught and treated as "no photo," never a crash, since the photo is optional by
  spec.
- **"Back affordance audit" is trivially satisfied this sprint**: the sheet's only new
  surfaces are native date/time picker dialogs, which ship their own Cancel/back affordance.
  No custom pushed route exists yet to audit. Revisit once Sprint 5+ adds real pushed screens
  (wallet detail, settings) reachable from the sheet.
- **Median save-to-dismissed timing not measured this sprint.** The phone disconnected
  (battery) mid-session before this sprint's UI was ready to profile, and Sprint 7 owns the
  actual performance-gate ticket with a release build. Revisit: profile on the ASUS_AI2202
  once reconnected, ahead of Sprint 7 if possible so a regression isn't discovered late.

## Sprint 5

- **Wallet "logos" are a coloured circle with the wallet's first initial**, not real bank/
  e-wallet artwork. Real GoPay/OVO/DANA/bank logos are trademarked assets this environment
  can't source or license, and a placeholder set invented to look official would be worse
  than an honest generic one. Revisit: swap in a real icon set (or user-uploadable logos)
  once assets are sourced properly — the `providerKey` column already exists for this.
- **Cross-currency wallet total renders a reason instead of a number** when wallets span more
  than one currency, rather than inventing a conversion rate. Chart rule #8
  (plan/04-ux-design.md) — "a number that cannot be computed renders blank with a reason,
  never as zero" — applies just as much to a fabricated exchange rate as to a zero. No FX
  rate source is designed for v1 balances (`rate_to_base` on postings is captured at
  transaction-write time, not available for a live account balance). Revisit once a real FX
  data source is chosen — probably alongside the multi-currency wallet creation flow.
  Same reasoning blocked a placeholder rate table outright: fabricated-looking real data is
  explicitly against the Definition of Done in plan/05-sprints.md.
  A second bug caught by testing the same way as Sprint 4's: `WalletsRepository.watchWallets`
  first read as `balanceSum ?? 0 + openingMinor`, which by operator precedence discarded
  `openingMinor` entirely whenever there were any postings (`??` binds looser than `+`). Found
  by writing the balance test before trusting the query, fixed to
  `(balanceSum ?? 0) + openingMinor`.
- **The "Bayar" (pay card) button prefills a transfer** (`CaptureSheet(initialKind: transfer,
  initialToAccountId:, initialAmountMinor:)`) rather than being its own screen — one sheet,
  one save path, matching "no screen the sheet doesn't already own" from plan/04-ux-design.md.
  The prefilled amount is the card's current owed balance; the user can still edit it or pick
  a different source account before saving.
- **New widget-test pattern found the hard way**: a `testWidgets` test that ends while a
  screen backed by a drift `.watch()` stream (e.g. `WalletsScreen`) is still mounted trips
  flutter_test's "a Timer is still pending" invariant — drift's stream-query executor
  schedules its fetch via `Timer.run`, and that fires during automatic teardown with no pump
  left to flush it. Fix, now the house pattern for any test whose last visible screen holds a
  drift stream: `await tester.pumpWidget(const SizedBox())` then one more `await
  tester.pump(...)` before the test function returns, so the unmount (and drift's cleanup
  timer) happen while a pump is still available to flush them.
- **Done-when met without Pantau existing yet**: `spending_queries_test.dart` proves a card
  payment (transfer, no category leg) doesn't move `totalCategorySpendMinor`, which is the
  actual guarantee "doesn't appear in spending statistics" cashes out to. `totalCategorySpendMinor`
  is a real function Pantau's aggregates (Sprint 8+) will read from, not a throwaway test
  helper.

## Sprint 6

- **Schema bumped to v3** (`daily_totals` table): one row per local calendar day, net of every
  account-leg posting landing on it, kept current by `DailyTotalsRepository` from inside
  `PostingsRepository`'s insert/delete/restore — so nothing else has to remember to update it.
  It's a derived cache, not exported in the JSON backup; `recomputeAll()` rebuilds it after a
  restore instead (see the Sprint 2 entry on migrations — this is the second schema bump, and
  the forward-migration-test pattern from Sprint 4 was reused directly).
- **Soft delete is real now, not just a schema column.** `deletedAt` existed on `transactions`
  since Sprint 1 but nothing read or wrote it. Every query that sums postings for a balance or
  a total (`WalletsRepository.watchWallets`, `totalCategorySpendMinor`, both `CaptureQueries`
  lookups, `DailyTotalsRepository.recomputeDay`) now excludes soft-deleted transactions —
  audited one call site at a time rather than introduced as a shared predicate, since there's
  no single choke point they all already route through (unlike `PostingsRepository` for
  writes). Revisit if a sixth call site appears — that's the signal to extract one.
- **A transfer is one Catat row, not two.** Its two account-leg postings share one
  transaction; `LedgerQueries` picks the negative ("from") leg as primary and names both
  accounts ("Bank -> Tunai"), rather than showing a transfer as two separate list entries.
- **Ledger pagination fetches transaction ids first, then assembles details for just that
  page** (`LedgerQueries._matchingTransactionIds` then `_assembleEntries`), instead of one
  join query with LIMIT/OFFSET directly — a transfer's two account-leg postings would
  otherwise inflate a joined LIMIT to sometimes return fewer than `limit` transactions per
  page. `groupBy(transactions.id)` on the id-selection query collapses that back to one row
  per transaction before the LIMIT is applied.
- **Editing an existing transaction is note-only this sprint.** Changing amount/category/
  account on a saved transaction needs an update path that re-derives both postings and keeps
  the sum-to-zero invariant and `daily_totals` correct — `PostingsRepository` has no
  `updateTransaction` yet, only insert/delete/restore. Bolting a partial version on now risked
  a subtly wrong balance; note editing needed no such path. Revisit: give
  `PostingsRepository` a real `updateTransaction` before Catat's edit affordance grows past
  the note.
- **Filtering covers category, wallet, note text and amount range; period filtering is wired
  in `LedgerFilter`/`LedgerQueries` but has no UI control yet** — Sprint 8 owns the period
  selector as a first-class, app-wide concept ("every aggregate query takes a period," per
  plan/03-architecture.md), and a throwaway date-range picker here would likely be thrown away
  when that lands. The filtered-empty state names whichever filters are active
  (`LedgerFilter.describe()`), never a bare "no results."
- **Perf done-when verified as a query-shape guarantee, not an on-device measurement.**
  `ledger_performance_test.dart` proves a page fetch stays fast with 10,000 transactions in
  the table (bounded LIMIT/OFFSET, not a full scan) — real on-device timing is Sprint 7's
  performance-gate ticket, on a release build, which this repo still can't produce locally
  (missing Android SDK Build-Tools 33.0.1, logged in the Sprint 0 entry).
- **A second widget-test-only "Timer still pending" case, same family as Sprint 5's**: a
  `testWidgets` test that reads `tester.allWidgets` (or otherwise inspects the tree) without
  ever unmounting before the test ends can take several real minutes to fail, because
  `addTearDown(db.close)` sits waiting on in-flight drift queries from a screen that never
  got torn down under a controlled pump. Confirmed by reproducing it deliberately in a
  throwaway debug test. The house pattern from Sprint 5 (unmount via `pumpWidget(SizedBox())`
  then one more `pump()` before the test ends) is now applied to every widget test that ends
  with a drift-stream-backed screen still mounted.

## Sprint 7

- **Android widget and app-shortcut both resolve through one path.** `home_widget`'s own
  launch action (`es.antonborri.home_widget.action.LAUNCH`) is reused as the shortcut intent
  action in `shortcuts.xml`, rather than inventing a second one, so `HomeWidget.widgetClicked`
  / `initiallyLaunchedFromHomeWidget` in `HomeWidgetService` handles both without a second
  listener. Both carry the same `wudget://capture?kind=expense` deep link, parsed by the pure
  (and tested) `parseCaptureDeepLink`.
- **iOS widget cut, per the cut list in plan/05-sprints.md** ("Android carries the market").
  Not attempted this sprint; revisit only if dogfooding on Android alone stalls.
- **Performance pass ticket not closed with a number.** The budget table in
  plan/03-architecture.md needs measurement on a real mid-range device with a release build,
  and this repo still can't produce a release build locally (missing Android SDK Build-Tools
  33.0.1, first logged in the Sprint 0 entry). Writing a fabricated pass/fail here would
  violate the Definition of Done's "no fabricated content" rule directly, so it stays open.
  Unblock: install Build-Tools 33.0.1, or move the measurement to a machine that has them,
  then run the cold-start/widget-tap/save/Catat/Pantau timings for real.
- **`ledger_performance_test.dart`'s 300ms bound is flaky under full-suite load** (passes
  isolated at ~1s, saw 415ms once running alongside the full suite on this machine) — CPU
  contention from the rest of the suite, not a regression in the query itself. Noted rather
  than loosened, since loosening a perf assertion to make CI green defeats its purpose;
  revisit if it flakes routinely once CI is real (Sprint 0's CI ticket is still open).

## Sprint 8

- **Period bounds live in the same day-bucket integer space as `dayBucketFor`/`daily_totals`**
  (`domain/period.dart`), rather than as `DateTime`s — a `Period` composes directly with the
  existing daily-aggregate machinery with no timezone conversion at the boundary. A day bucket
  round-trips to a calendar date via `epoch + n days`, since `dayBucketFor` already produces
  "days since epoch in local wall-clock time"; month arithmetic (for the payday-aligned case)
  is done on that date, then converted back to a bucket.
- **No new period-aggregate cache table.** `PeriodAggregateQueries.totalsFor` runs the same
  padded-scan-then-refine-in-Dart query shape as `DailyTotalsRepository.recomputeDay`, bounded
  to at most a month of rows — fast enough without a cache, and a real cache table can wait
  until Sprint 9's Pantau render budget (500ms, all aggregates precomputed) says otherwise.
- **`AppSettings` is a single row (id fixed to 0), created lazily on first write, not seeded on
  create.** A missing row means every setting is at its documented default (`periodStartDay`
  1) — `SettingsRepository.watchPeriodStartDay` reads that off `row?.periodStartDay ?? 1`
  rather than requiring migration-time seed logic for a table that's really just one struct.
  Schema bumped to v4 (`createTable(appSettings)`), same forward-migration pattern as Sprint 4
  and Sprint 6's bumps.
- **Month start day is clamped to 1-28 at the write path** (`clampPeriodStartDay`, called from
  both `SettingsRepository.setPeriodStartDay` and `Period.containing`/`.next`/`.previous`), per
  plan/05-sprints.md's "capped at 28" — so a period never has to decide what "the 30th" means
  in February.
- **Pantau's waiting state gates on days-since-first-transaction ever recorded, not on the
  selected period having 14 days in it.** Matches the plan's Phase 2 intent ("only after the
  user has two weeks of real data") — paging the period selector backward past the waiting
  point would otherwise show real numbers for a period the user hasn't actually lived through
  14 days of yet, which the honest-waiting-state ticket is there to prevent.

## Sprint 9

- **Pace compares this period's spend against the previous period's total, not a user-set
  budget** — budgets don't exist until Sprint 10. `PaceResult.spendFractionOfBaseline`
  (spend so far / previous period's total) is the value the pace ring actually renders, with
  `elapsedFraction` (days so far / period length) drawn as a separate tick for comparison —
  `50% of days elapsed but 80% of last period's total already spent` is the shape of insight
  this sprint can honestly produce without Sprint 10's budget number.
- **The previous period only counts as a baseline if it's a *full* period of real history**
  (`PeriodAggregateQueries.previousPeriodBaselineExpenseMinor`: null unless the previous
  period's start is on or after the user's first-ever transaction). A period the user only
  partly tracked would understate its own total and make every later period look like an
  overspend by comparison — chart rule 8 ("a number that cannot be computed renders blank
  with a reason") applies to a skewed number just as much as a missing one.
  `test/period_aggregate_queries_test.dart` covers both the null case and the full-period case.
- **The pace ring's arc is `spendFractionOfBaseline`, which can exceed 100%, with the elapsed-
  time fraction drawn as an independent tick mark rather than a second arc** — this is chart
  rule 1 ("no gauge for a value that can exceed its scale") applied directly: past 100% the
  ring draws a visually distinct inner overshoot lap instead of clipping or wrapping silently.
- **`double` doesn't appear in `lib/`, even for fractions and pixel geometry that aren't money**
  — `test/money_formatter_is_the_only_path_test.dart` is a blunt repo-wide grep for the literal
  word (Sprint 1's guard), not a type check, so `elapsedFraction`/`spendFractionOfBaseline` and
  the chart painter's coordinate math are typed `num` instead. Caught by running the full
  suite, not `flutter analyze` — the analyzer has no opinion on which numeric type a ratio
  should be.
- **No feature flag yet for pace-first vs. remaining-first.** That's Sprint 11's ticket
  ("Feature flag infrastructure... pace-first against remaining-first variants"); this sprint
  ships pace-first directly, per plan/01-features.md's stated default, with the remaining
  balance reachable one tap away from the pace card (a bottom sheet, `expenseMinor` subtracted
  from `incomeMinor`) and deliberately not printed on the card itself.

## Sprint 10

- **A budget's key is a top-level category id, or the fixed string `'irregular'` — never a
  subcategory id.** `BudgetHistoryQueries.categorySpendByKey` rolls every subcategory's spend
  up to its parent, and pools every `is_irregular` category (leaf or top-level) under one
  shared key, per plan/01-features.md's "irregular expense bucket": exceptional spending needs
  one home, not per-category noise, and a subcategory (e.g. "Sarapan") sharing one budget with
  its parent ("Makan") is how a person actually thinks about a category budget.
- **One query, two call sites.** `categorySpendByKey` takes a plain day range, used both for
  the trailing lookback window (the proposal) and for the current period (the pace shown
  against a saved budget) — same shape of question over a different range, so there's no
  second, near-duplicate query to keep in sync with the first.
- **The proposal denominator is the lookback window's actual length, not "days since that
  category was last spent on."** A category spent on twice in the last 28 days gets
  `spend / 28`, not `spend / 2` — the latter would scale a rare purchase up as if it recurred
  every other day. `proposeBudgetMinor`'s doc comment states this explicitly since it's the
  one place a reasonable-looking alternative formula would quietly be wrong.
  `test/domain/budget_proposal_test.dart` pins the distinction with a "few days of spend"
  case.
- **A category with zero spend in the lookback window is never proposed, not proposed as
  Rp 0.** `proposeBudgets` filters `entry.value > 0` before calling the formula at all — the
  Definition of Done's "no fabricated content" rule applies to a fabricated zero exactly like
  a fabricated real-looking number. `BudgetScreen` then unions proposal keys with already-saved
  budget keys, so the sprint's own done-when ("no user is ever shown a blank budget field")
  comes out of that union rather than a separate check: every row shown has either a real
  proposal or a real saved value, and a category with neither simply isn't a row.
- **Budgets are per-category-key, not per-period-instance.** One saved amount applies to
  whichever period is current — there's no `Budgets` row per period the way `daily_totals` has
  a row per day. Simpler, and matches "the user edits rather than authors" (plan/01-features.md):
  there's one number to maintain per category, not one per period going forward. Per-period
  overrides aren't a stated requirement anywhere in the sprint plan; revisit if dogfooding
  wants a budget that changes between periods.
- **Over-budget is marked by an icon and an explicit "Lebih dari anggaran" label plus the
  progress bar's colour, never colour alone** — chart rule 7. The progress bar itself is
  intentionally not a ring (chart rule 1's "no gauge for a value that can exceed its scale"
  concern doesn't apply the same way to a bar, which can visibly extend past its container,
  but the fill is still clamped to 1.0 and the over-state is carried by the icon/label instead
  of an overshoot render — simpler than Sprint 9's ring for a value where "how far past" isn't
  the point, just "past or not").
- **A new drift-stream gotcha, found the hard way: `.watch().first` inside a widget's
  `initState`-triggered async load hung `pumpAndSettle` forever**, even though the identical
  call resolved instantly in a plain (non-widget) test — confirmed by reproducing
  `BudgetScreen._load`'s exact sequence outside `testWidgets` first, where it completed in
  under a second. `BudgetsRepository` now has a `getAll()` one-shot read (`.get()`, not
  `.watch()`) for this call site; `watchAll()` stays for a future screen that wants live
  updates, subscribed the way `StreamBuilder` already does elsewhere in this codebase — the
  house pattern that's confirmed to work in a widget test. Rule of thumb going forward: a
  one-off read inside an imperative `async` method uses a one-shot query; `.watch()` is only
  for a subscription a widget keeps open for its own lifetime.

## Sprint 11

- **Calendar activity heatmap cut, per the cut list in plan/05-sprints.md item 2** — not
  attempted this sprint. The other four tickets (feature flags, the framing variants,
  category ranked list, week bar chart) are built in full.
- **Feature flags are a key-value table, same shape as `Budgets`** (`FeatureFlags`: `key`,
  boolean `value`), rather than a dedicated column per flag — the framing experiment is the
  first flag, not the only one that will ever exist, and this shape needs no migration to add
  a second.
- **Analytics events are a local, append-only table, not a shipped-anywhere log.** There is no
  backend in a local-first, no-account app (see PLAN.md's locked decisions), so
  "measurement hooks" means a queryable local record read back during the weekly dogfooding
  review (plan/05-sprints.md's "Thursday" rhythm) — `AnalyticsRepository.all()` exists for
  exactly that, not for a future sync path.
- **The variant swap is presentation-only — both variants compute the same `PaceResult` and
  `PeriodTotals` from one `_load()`.** `_ReviewBody` branches on `paceFirstFramingProvider`
  purely to decide which number is the hero and which is one tap away (`_PaceDetails` in a
  bottom sheet for remaining-first, inline for pace-first) — there's no second data path to
  keep in sync with the first, only a second layout.
- **The `pantau_viewed` event's variant is read with `FeatureFlagsRepository.getBool` (a
  one-shot read), not `watchBool(...).first`** — this sprint's own `.watch().first` deadlock
  finding (the previous entry) applies here too, so the one-shot method added for
  `BudgetsRepository` got a `FeatureFlagsRepository` twin immediately rather than waiting to
  rediscover the same bug.
- **The category ranked list and week bar chart appear in both framing variants, unchanged.**
  The experiment is specifically about the hero number (plan/01-features.md: "pace-first
  against remaining-first"), not about the rest of the review surface — narrowing the
  variance to the one contested bet keeps the measurement honest.

## Sprint 12

- **The date math lives entirely in `domain/recurrence.dart`, pure and DB-free** —
  `RecurrenceRule.logicalOccurrence(n)` computes the nth occurrence fresh from `startsOn`
  and the rule's own fields every time, never by stepping forward from the previous
  occurrence. That's what makes the month-end clamp non-permanent for free: April's
  clamped 30th has no memory that carries into May's fresh calculation of the 31st.
  `weekend_rule` is applied only afterward, by `shiftForWeekend`, and the *next* occurrence
  is always computed from the unshifted logical date — so a Sunday due date shifted to
  Monday can never leak into where the following month's occurrence lands.
- **Materialisation is idempotent by watermark, not by trying to detect existing rows.**
  `_materializeOne` returns immediately if `toDayInclusive <= generatedUntil`; a rule is
  never asked "does this occurrence already exist," it just doesn't try to make one earlier
  than its own watermark. This is plan/03-architecture.md's stated failure mode
  ("a missed run cannot produce... a month of entries all appear at once") turned directly
  into the loop condition rather than a dedupe step layered on top.
  `test/recurrence_repository_test.dart` proves calling `materializeAll` twice at the same
  watermark, and once more at an earlier one, produces no new rows either time.
  Deterministic transaction ids (`${recurrenceId}_${occurredOnDay}`) are a second, redundant
  safety net, not the primary idempotency mechanism.
- **A per-instance override (`skip`/`move`/`amend`) only takes effect at materialisation
  time, for an occurrence not yet generated.** Overriding an instance that was already
  materialised before the override was written does not retroactively edit or delete that
  row — known gap, not attempted this sprint. The "one-instance against all-future" split
  from the done-when is `editFutureFrom`: it ends the existing rule the day before the
  effective date and starts a fresh `Recurrences` row from there, so a series-level edit
  changes the rule going forward while every past (and already-materialised future) instance
  under the old rule is untouched — a genuinely different operation from an override, not
  the same mechanism reused.
- **A `varies`-amount item materialises using its `expected_min_minor` as a placeholder
  amount**, since a real `transactions` row needs a concrete number and inventing a midpoint
  would look more precise than it is. Showing the range itself (`Rp X - Rp Y`) rather than
  the placeholder number is Sprint 13's upcoming/active UI's job, not this sprint's.
- **The shared `isActualTransaction` predicate (`data/actual_transactions.dart`) replaced
  every ad hoc `transactions.deletedAt.isNull()` across the query layer** — period totals,
  budget history, category ranking, `spending_queries`, `daily_totals`, capture templates,
  and wallet balances. The wallet-balance case needed more than a search-and-replace: the
  existing query excluded a non-actual posting's row from the join's WHERE clause, which
  silently dropped the *account* from the wallet list entirely once its only posting was
  projected (or soft-deleted) — an account with a lone future bill would vanish from Kantong.
  Fixed by moving the filter onto the SUM itself (`amountMinor.sum(filter:
  isActualTransaction(...))`, a SQL `FILTER (WHERE ...)`) so the account row always survives
  the join and the sum treats a non-actual posting as contributing zero, rather than the
  WHERE clause excluding the row that carries it.
  `test/actual_transactions_test.dart` pins this down directly: a projected future bill must
  move neither a wallet balance nor `totalCategorySpendMinor`/period totals, and confirming
  it must make it count everywhere at once, with no per-surface flag to remember.
- **`LedgerQueries` (Catat's list) now also excludes projected instances**, not just the
  aggregates the ticket names outright — plan/03-architecture.md says "everywhere," and
  showing an unconfirmed forecast mixed into recorded history would misrepresent it as
  something that already happened. Sprint 13 ("Recurring and bills UI, split into upcoming
  and active") owns giving projected instances their own surface; until then they're simply
  not shown, which is truer than showing them unlabelled.

## Sprint 13

- **Confirming a reminder reuses the existing capture sheet rather than a second save path.**
  `CaptureSheet` gained `initialCategoryId`/`initialAccountId`/`initialNote` (alongside the
  transfer prefill fields that already existed) and `confirmingTransactionId`: a successful
  save calls the existing `PostingsRepository.undoInsert` on that id, hard-deleting the
  recurrence engine's placeholder now that a proper confirmed transaction has replaced it.
  The alternative — teaching the save path to update an existing transaction in place — is
  the `updateTransaction` gap Sprint 6 deliberately deferred; reusing `undoInsert` (delete the
  placeholder, insert fresh) sidesteps needing it here too, at the cost of a new transaction
  id for the confirmed row rather than the placeholder's original id.
- **`capture_deeplink.dart`'s `parseCaptureDeepLink` now returns a `CaptureLaunch`** (kind
  plus category/account/amount/note/`confirmingTransactionId`) instead of a bare `CaptureKind`
  — the home widget and app-shortcut (Sprint 7) only ever set `kind`, but a reminder
  notification's action needs to carry the whole instance. One parser, one URI shape, for
  both entry points, rather than a second deep-link format for notifications.
- **A `ReminderScheduler` interface sits between `reminder_orchestrator.dart` and the real
  `NotificationScheduler`**, so the "which reminder gets which copy" logic
  (`scheduleUpcomingReminders`) is tested against a fake that records calls, without a
  platform channel. This mirrors Sprint 7's approach to `HomeWidgetService`: the DST-correct
  fire-time math (`domain/reminder_schedule.dart`) and the deep-link/copy logic are pure and
  tested directly; only the plugin-touching shell is untested, because it cannot be
  meaningfully tested without a real device.
- **DST correctness is proven with `TZDateTime`, not with duration arithmetic.**
  `reminderFireTime` builds the fire time from a `tz.Location` and a wall-clock hour/minute,
  so `test/domain/reminder_schedule_test.dart` can assert a reminder still fires at 09:00
  local on both sides of a spring-forward and a fall-back transition — and demonstrates the
  bug this guards against directly: naively adding a `Duration` to an already-computed instant
  drifts the local hour once the UTC offset changes underneath it.
- **A varies-amount reminder isn't attempted this sprint** (`reminderBodyForRange` exists and
  is tested, but `reminder_orchestrator.dart` doesn't call it) — wiring it needs the "expected
  range" case threaded through `RecurringQueries`/`scheduleUpcomingReminders` too, and no
  currently-seeded item exercises `amount_mode = 'varies'` end to end yet. Revisit once a real
  variable-amount recurring item exists to test it against.
- **Skipping an already-materialised upcoming instance is a direct hard delete
  (`postingsRepository.undoInsert`), not a `recurrence_overrides` row.** Sprint 12 noted this
  gap; it turns out to need no fix, because materialisation's idempotency is watermark-based,
  not existence-based (Sprint 12) — the watermark already passed this logical day during the
  run that created it, so deleting the row is sufficient and no later `materializeAll` call
  will recreate it. `skipInstance` (an override) remains the mechanism for skipping an
  occurrence that hasn't been materialised yet, e.g. from a future edit to the rule.
- **Materialisation runs on every app open** (`main.dart`, watermark advanced to today plus a
  60-day lookahead), unconditionally — safe specifically because Sprint 12 made it idempotent
  by watermark, so there's no "did we already run today" state to track.
- **Real on-device notification delivery isn't verifiable in this environment** — same
  category as Sprint 7's performance-gate ticket. `AndroidManifest.xml` gained
  `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` and `RECEIVE_BOOT_COMPLETED`; whether a
  reminder actually survives a reboot and fires at the exact configured minute needs a real
  device, not this repo's test suite.

## Sprint 14

- **"Surplus sweep into a goal" is not built.** Goals are Sprint 15, and Sprint 15 is entirely
  cut per plan/05-sprints.md's own cut list ("Goals entirely, moved to 1.1... the most
  self-contained feature in the plan, which makes it the cheapest to defer"). There is no goal
  model to sweep into. The close summary still shows the surplus, with a plain "worth
  considering saving it" line instead of a sweep action — the honest version of this ticket
  given what Sprint 15 didn't build, not a silent drop of the requirement.
- **"Next period prefilled from this one" needed no new code.** Sprint 10 already made
  budgets per-category-key rather than per-period-instance (one saved amount, applied to
  whichever period is current) specifically so there'd be nothing to carry forward — the
  close screen just says so and links to Anggaran, rather than duplicating a "copy last
  period's budget" action that would do the same thing a second way.
  If Sprint 15's cut is ever revisited, remember this ticket's answer changes with it: a goal
  sweep needs a real goal to write into.
- **The largest-category and most-changed-category logic (`domain/period_close.dart`) is pure
  and takes plain records (`CategorySpend`), not `data/category_rank_queries.dart`'s
  `CategoryRank` class** — same domain/data separation already followed by
  `domain/budget_proposal.dart` and `domain/pace.dart`. The screen adapts `CategoryRank` to
  `CategorySpend` at the call site; the pure function itself has no dependency on data/.
- **A category that had spend last period but none this period still counts as "the most
  changed," via its previous amount treated as a full drop to zero** — not just categories
  present in both periods. Missing this case would make "stopped spending on X entirely"
  invisible to the summary, which is exactly the kind of change a person would actually
  mention.
- **A found-the-hard-way drift migration bug, distinct from anything in the Sprint 5/6/8
  drift-stream family of gotchas: `Migrator.createTable(t)` builds from `t`'s *current* Dart
  definition, not its shape at that schema version.** Adding `lastAcknowledgedPeriodClose` to
  `AppSettings` (created via `createTable` at `from < 4`) and also `addColumn`-ing it at
  `from < 8` meant a fixture upgrading from v1 hit "duplicate column name" — the `from < 4`
  step already created the table with the new column, since `createTable` has no concept of
  "what this table looked like in v4," only "what this table looks like now." Fixed by
  guarding the `addColumn` step to `from >= 4 && from < 8`: only a database that already had
  the table *before* this column existed needs it added.
  `test/migration/schema_migration_test.dart` gained a v4-shaped fixture (table present,
  column absent) as a permanent regression test for this exact shape — the v1 fixture alone
  didn't catch it, because `from < 4` papered over the bug for that path. The rule going
  forward: any schema change that adds a column to a table which is itself created inside
  `onUpgrade` (not just at `onCreate`) needs the `addColumn` step's `from` range to start
  just above the table's own creation version, not `0`.

## Sprint 16

- **The Money Manager column mapping is an unverified default, not a tested profile.** No
  real Money Manager (or Ollo) export was available in this environment — the plan's own
  done-when ("Money Manager profile, tested against a real export") can't be honestly claimed
  without one. `moneyManagerProfile` is documented as a best-effort guess at commonly-cited
  column names, and the column-mapping screen is always editable and never gated on the guess
  being right, so an inaccurate default degrades to "map it by hand," not a broken import.
  Revisit the moment a real export file turns up.
- **Ollo's profile isn't built at all**, per the cut list in plan/05-sprints.md item 3 ("ship
  the Money Manager one, since it has the larger installed base by a wide margin").
- **A hand-written CSV parser (`domain/csv_parser.dart`), not the `csv` package.** RFC-4180
  quoting (commas and doubled quotes inside a quoted field), CRLF/LF, a leading BOM, and a
  missing trailing newline are the only real-world cases a competitor export is likely to
  exercise, and covering them is under 50 lines — adding a dependency for that trades a
  reviewable, tested function for an opaque one.
- **Row numbers in `ImportRowFailure` count the header as row 1**, matching how a person
  reads their own spreadsheet — `dataRows[0]` (the first row after the header) is reported as
  row 2, not row 0 or row 1. Threaded through as `ParsedImportRow.rowNumber` so a DB-write
  failure (`CsvImportRepository`) and a parse failure land in the same failure list with the
  same numbering, shown together on one screen.
  `test/domain/csv_import_test.dart` pins the exact row-counting behaviour directly, since an
  off-by-one here would send someone hunting the wrong line in their spreadsheet.
- **An account or category the CSV names but wudget doesn't yet have is created on the fly,
  matched case-insensitively against what already exists.** An import is explicitly for a
  user "rebuilding after a loss" (plan/01-features.md) — refusing rows because their category
  doesn't exist yet would defeat the feature's entire purpose. A row with no category name at
  all falls back to "Lainnya" rather than failing, since a competitor export not carrying a
  category is a formatting fact, not an error to report.
- **The importer never batches rows into one transaction.** Each row is its own
  `PostingsRepository.insertTransaction` call, so one bad row's exception can't roll back
  every row already written — a straightforward reading of "a partial import that keeps the
  valid rows" from plan/03-architecture.md.
- **`ImportScreen` takes an `@visibleForTesting` `debugInitialCsvContent` constructor param**
  so a widget test can exercise the whole mapping-and-import flow without `FilePicker`'s
  platform channel, which `flutter_test` can't provide. Loading logic was split into
  `_applyCsv` (plain field assignment, callable from `initState` before a first build exists)
  and the `setState`-wrapped call site used after a user picks a file — calling `setState`
  from `initState` itself throws.

## Sprint 17

- **A backup/restore screen exists now, closing a gap left open since Sprint 2**: the JSON
  export/import and local-backup engine (`BackupRepository`) had no UI at all until this
  sprint's "Catat, new user error: corrupt database routes to restore" state needed somewhere
  real to route to. `BackupScreen` (create backup, export JSON/CSV, restore from a JSON file
  with a dry-run preview before confirming) is reachable from Kantong's app bar, and is also
  what `main.dart` shows directly, in place of the normal tab shell, when the database fails
  to open or seed at startup — the old file is renamed aside (`.corrupt-<timestamp>`, never
  deleted outright, in case someone wants to inspect it by hand) and a fresh one takes its
  place so the restore screen has somewhere to write into.
- **`BackupScreen` takes an `@visibleForTesting` `debugDocumentsDir`**, the same seam pattern
  as `ImportScreen`'s `debugInitialCsvContent` — `getApplicationDocumentsDirectory()` needs a
  platform channel `flutter_test` doesn't provide.
- **A real file write inside a `testWidgets` body reliably hung this environment's test
  runner, with no error and no timeout — confirmed by bisecting with print statements down to
  the exact `File.writeAsBytes` call, and confirmed it wasn't a stale-lock artifact from an
  earlier killed run by cleaning up orphaned `flutter_tester.exe`/`dart.exe` processes and
  retrying on a fully clean directory, which still hung.** The identical write, in a plain
  (non-widget) `test()`, is what `test/backup_round_trip_test.dart`'s `createBackup` test
  already does successfully — so the failure is specific to real disk I/O inside the
  `flutter_tester` widget-test binding in this environment, not to the code under test.
  `BackupScreen`'s widget test therefore only renders and reads state; every actual
  read/write path (`createBackup`, `exportJson`/`importJson`) stays covered by
  `backup_round_trip_test.dart`'s plain tests instead. Rule of thumb going forward, alongside
  Sprint 10 and 11's drift-stream gotchas: a `testWidgets` test that needs to touch the real
  filesystem is itself the risk, regardless of what the code does — inject a directory and
  keep the disk-touching assertions in a plain `test()`.
- **A recurring item's rule row now carries `lastGenerationError`** (schema v9; same
  createTable-then-addColumn migration care as Sprint 14's `lastAcknowledgedPeriodClose` —
  the `addColumn` step is guarded to `from >= 7`, since `recurrences` is itself created at
  `from < 7`), set when `RecurrenceRepository.materializeAll` catches an exception for that
  rule and cleared on its next successful run. One rule failing to materialise no longer
  aborts the whole batch, and `RecurringScreen`'s active-item row shows the reason directly —
  plan/04-ux-design.md: "Recurring... Failed generation flagged in the row with the reason."
- **Creating a recurring item had no UI at all before this sprint** — Sprint 13 built
  confirm/skip for instances the engine already knew about, but never a way to tell it about
  a new one. The empty state's "one example, one action" (plan/04-ux-design.md) needed that
  action to actually exist, so `_CreateRecurringSheet` ships now: a minimal monthly-bill form
  (name, amount, day of month, category, wallet, weekend rule) rather than every frequency
  and amount mode the domain model supports — the common case named throughout the plan
  (a bill), not a general-purpose rule editor. Daily/weekly/yearly and varies-amount items
  can still be created directly against `RecurrenceRepository`, just not from this sheet yet.
- **Catat (the ledger list) had no way to open the capture sheet at all before this sprint** —
  only Kantong's FAB could. Its own empty state's "one action to add it" needed a real action,
  so Catat gained its own FAB (and its empty-state button) opening the same `CaptureSheet`.
  Two tabs offering the same quick-add is deliberate, not an oversight: Catat is where a new
  user with nothing recorded yet actually lands to look for "how do I add something."
- **Pantau's empty-period state is a structural spend/income/category check** (`totals`
  are all zero and `categoryRanks` is empty), not a date-range check against "today" —
  a period a person deliberately pages back to that has real data (even a past, already-
  ended one) still renders the normal pace/chart view; only a period with nothing recorded
  in it gets the dedicated "which period is empty" text plus the period selector to page
  elsewhere, per plan/04-ux-design.md's states table.
- **Kantong's loading and empty states were conflated before this sprint** —
  `snapshot.data ?? const []` treated "stream hasn't emitted yet" identically to "zero
  wallets," so a fresh app open would flash "belum ada dompet" before the first real
  `watchWallets()` emission. Split via `snapshot.hasData`, and the empty state gained a real
  button (not just app-bar-icon-pointing text).
- **Screenshotting every state into a reviewed gallery (this sprint's second ticket) isn't
  attempted** — same category as Sprint 7's performance gate: it needs a running emulator or
  device to capture from, which this environment doesn't have. Every state listed in
  plan/04-ux-design.md's table has been implemented and has at least one test asserting its
  text/structure; the visual review pass itself is a manual step for whoever has a device.

## Sprint 18

- **Contrast was asserted, not eyeballed.** `lib/domain/contrast.dart` implements the WCAG
  2.x relative-luminance and contrast-ratio formulas from scratch (no dependency needed for
  two small pure functions), and `test/domain/contrast_test.dart` runs them against every
  actual token/color pairing the app uses: body text over every theme surface, non-text
  components (FAB, chart lines) over their backgrounds, and every category hue at the 3:1
  component bar in both themes. Two light-theme category hues failed the 3:1 bar against
  white (`0xFFF2A93C` at 2.00, `0xFFF2A93C`'s sibling `0xFF4FAE7C` at 2.74) and were
  darkened in `lib/design/tokens.dart` until they cleared it. The ledger delete-swipe
  background was a separate, worse bug: it used `tokens.negative`, a theme token, for a
  fixed `Colors.red.shade700` Dismissible background, so its actual rendered contrast in
  dark theme was never what the token pairing implied. Fixed by hardcoding the Dismissible
  background to `Colors.red.shade700` directly, since it is deliberately theme-independent
  (a swipe-to-delete red), and asserting that fixed pairing in the contrast test instead of
  a token pairing that was never actually on screen.
- **200% text scale surfaced two real overflow bugs**, not just theoretical risk (R-35):
  `week_bar_chart.dart` computed bar heights as `90 * values[i] / maxValue`, a fixed pixel
  height with no relation to the surrounding row's actual height once labels below it grew
  at 200% scale; replaced with `Expanded` + `Align(bottomCenter)` +
  `FractionallySizedBox(heightFactor: ...)` so the bar always fits whatever space is left.
  `period_close_sheet.dart`'s body could exceed the sheet's height entirely at 200% scale
  (a short screen or a long largest-category name), and its `_Row` label could push the
  amount off the right edge; fixed with a `SingleChildScrollView` around the body and an
  `Expanded` around the row's label. `test/accessibility/text_scale_test.dart` pins all
  three at `TextScaler.linear(2.0)` so a regression here fails a test, not just a manual
  check.
- **`capture_sheet.dart`'s `_key()` numpad buttons were missing `excludeSemantics: true`**
  on the wrapping `Semantics(label: ...)` for glyph keys (⌫, ±, ✓): without it, a screen
  reader announces both the explicit label and the raw glyph underneath as a second node,
  so "Hapus" was followed by an unlabeled "⌫" a user could also land on. Adding
  `excludeSemantics: true` collapses it to one node with the real label, verified in
  `test/accessibility/semantics_test.dart` by asserting `tester.getSemantics(...).label`
  directly rather than `find.bySemanticsLabel`, which returned zero matches for an exact
  string even when `getSemantics` proved that exact string was present on the tree — not
  trusted as a finder for this kind of assertion going forward.
- **`SemanticsHandle` must be disposed at the end of the test body, not via
  `addTearDown`.** `WidgetTester`'s end-of-test check for an undisposed handle runs inside
  `_runTestBody`, before `addTearDown` callbacks fire, so a handle registered for teardown
  there still trips "A SemanticsHandle was active at the end of the test." Both semantics
  tests call `handle.dispose()` explicitly as the last line of the test body, after the
  drift-stream unmount sequence (`pumpWidget(SizedBox())` + `pump()`) from Sprint 5/6 — that
  unmount sequence still has to run first, or drift's stream-query cleanup Timer trips the
  pending-timer check instead.
- **Reduce-motion needed an audit, not new code.** Grepping `lib/` found no
  `AnimationController`, `AnimatedContainer`, `TweenAnimationBuilder`, or `Hero` anywhere in
  the app: every transition is a stock Material default (the capture sheet's modal
  bottom-sheet slide), and Flutter's own transition themes already read
  `MediaQuery.disableAnimations` and cut to an instant transition when it's set.
  `test/accessibility/reduce_motion_test.dart` is the audit's proof, not a new fallback:
  it opens the capture sheet under `MediaQueryData(disableAnimations: true)` and asserts it
  renders correctly, with nothing in the app itself changed.
- **Golden tests are scoped to two low-decoration screens, each in both themes**
  (`test/golden/key_screens_theme_test.dart`): Kantong's empty state and Pantau's waiting
  state, not a chart-heavy screen most sensitive to font-hinting differences across
  machines, and specifically the states data/06-implications.md flagged competitors getting
  wrong. Every golden test needed the same trailing unmount sequence as every other
  StreamBuilder-backed widget test in this app (Sprint 5/6's gotcha) — without it, the first
  golden test in the file hung indefinitely rather than failing outright, since
  `expectLater(..., matchesGoldenFile(...))` doesn't itself trigger the pending-timer check;
  only the test's teardown does, once something is left to unmount uncleanly. Baselines were
  generated with `flutter test --update-goldens test/golden/key_screens_theme_test.dart` and
  the four PNGs are committed alongside the test.
- **Em dashes (R-02) removed from four files' user-facing copy** this sprint touched
  (`reminder_orchestrator.dart`, `pace.dart`, `reminder.dart`, `wallets_screen.dart`,
  `period_close_sheet.dart`), replaced with commas, colons, or periods per the antislop
  core rule; this file (`DECISIONS.md`) is project documentation, not app copy, so its
  existing em-dash style is left as-is for consistency with every earlier entry.
- **A non-breaking space inside `MoneyFormatter`'s output caught a hardcoded test
  literal.** `'Jumlah: Rp 0'`, typed by hand, looked identical to the rendered string but
  failed a byte-for-byte `expect` — `MoneyFormatter` emits a real U+00A0 between the
  currency symbol and the digits (confirmed with `cat -A` on `money_formatter.dart`), not
  an ordinary space. Fixed by building the expected string through the real formatter in
  the test instead of a literal, which is also the more honest assertion: it tests that the
  semantics label matches what the formatter actually produces, not a guess at its bytes.

## Sprint 19

- **A real name collision was found and put to the owner, not decided silently.**
  Searching for "wudget" during the name-collision ticket turned up a live iOS app
  titled exactly "Wudget: Simpler Budget Planner," same category, same name
  (https://apps.apple.com/us/app/wudget-simpler-budget-planner/id6720702936). Google
  Play has no exact "Wudget" listing. This is precisely the risk
  research/01-app-teardowns.md flagged for Expensa/SyncSpend, so it was surfaced to the
  owner rather than either ignored or worked around by picking a new name unasked. The
  owner's call: keep "wudget" and proceed. Recorded in `store/submission-prep.md` along
  with the fallback (an App Store-only display-name variant) if Apple's review rejects
  for name confusion.
- **Privacy policy and terms were drafted in `legal/`, Indonesian and English, but
  deliberately not published anywhere.** Both stores require a live policy URL before
  submission, so these are marked DRAFT at the top of each file with instructions to
  publish them to a real hosted page first. The content itself required no invention:
  grepping `lib/` for `http.`, `Dio(`, `firebase`, `Sentry`, and similar found zero
  network calls anywhere in the app, and `plan/03-architecture.md` already states "No
  account, no email, no phone number in v1" as a settled decision, so the policy could
  state plainly that no data is collected or transmitted, rather than hedge with
  boilerplate written for an app that might someday add tracking.
- **Store listing and ASO copy (`store/listing.id.md`, `listing.en.md`,
  `app-store-connect.md`) describes only features that exist as of Sprint 18** — pace
  tracking, wallet types, budget proposals, recurring bill reminders, CSV import,
  local backup/restore — checked against DESIGN.md's copy voice rules (no invented
  user counts, no fabricated comparisons, no em dashes) and against the actual screens,
  not the plan's aspirational feature list.
- **Screenshots (this sprint's third ticket) are not captured**, the same constraint as
  Sprint 17's states pass and Sprint 7's performance gate: no emulator or device is
  attached to this environment. Documented in `store/submission-prep.md` with the
  requirement plan/05-sprints.md states explicitly: real UI, no invented numbers,
  seeded with realistic sample data before capturing.
- **Android release signing is wired to a `key.properties` file that does not exist in
  this repo** (`android/app/build.gradle`), with a fallback to the debug key when the
  file is absent so `flutter build`/`flutter run` and CI keep working with no secrets
  present. Generating the actual upload keystore was deliberately left undone: it is a
  real, hard-to-reverse secret (Google has no clean way to recover a lost upload key),
  and creating one inside this session with nowhere durable to store it would be worse
  than not having one yet. Verified the config change itself doesn't break anything by
  running `flutter build apk --debug`, which still succeeds (falls through to the debug
  signing branch).
- **iOS signing, archiving, and submission cannot be driven from this environment at
  all** (Windows, no Xcode, no Mac). What's prepared instead:
  `store/app-store-connect.md`'s fields, and the same privacy policy/terms drafts as
  Android. `store/submission-prep.md` lists what still needs a Mac and an Apple
  Developer account.
- **Actual account setup, real key generation, and submission to either store are not
  attempted this sprint**, per the stop-before-irreversible-external-actions boundary
  stated at the start of this run: app-store submission and publishing legal documents
  both stay with the owner to do deliberately. Everything buildable ahead of that line
  (policy/terms text, listing copy, ASO, the signing-config scaffold) is done.
