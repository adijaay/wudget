# Decisions log

Calls made during the build without stopping to ask, per your instruction to decide and
compile for review after Milestone C. Each entry: what, why, what to revisit if wrong.
This file is the ADR: no separate template, one flat log, newest sprint at the bottom.

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

## Blocked on you

- ~~Mid-range Android device for perf measurement (Sprint 0).~~ Resolved: ASUS_AI2202
  (`N9AIGF003861PBZ`) connected over ADB and used directly for this build. That is now the
  device all performance numbers in later sprints are measured on, until you name a
  different one.

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
