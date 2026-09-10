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
