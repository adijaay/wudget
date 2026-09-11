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
  with a drift-stream-backed screen still mounted.
