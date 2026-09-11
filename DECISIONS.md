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
