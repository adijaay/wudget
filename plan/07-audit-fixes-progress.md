# Audit Fixes Progress Report

**Date:** 2026-10-08  
**Status:** Sprints 1-12 complete, 13-17 pending

---

## Completed Sprints

### Sprint 1: Critical Data Integrity ✅
**Status:** COMPLETED  
**Story Points:** 8

**Changes:**
- Fixed auto-save unbalanced postings bug in `payment_auto_save_repository.dart`
- Added balancing source posting to make postings sum to zero
- Created test `sprint1_auto_save_balance_test.dart` to verify fix

**Files Modified:**
- `lib/data/payment_auto_save_repository.dart` - Added second posting leg
- `test/sprint1_auto_save_balance_test.dart` - New test file

**Test Results:** ✅ All tests passing

---

### Sprint 2: Backup/Restore Completeness ✅
**Status:** COMPLETED  
**Story Points:** 5

**Changes:**
- Added missing tables to `exportJson()`: budgets, recurrences, recurrence_overrides, app_settings, feature_flags
- Added import logic for those tables in `importJson()`
- Backup now captures complete user data

**Files Modified:**
- `lib/data/backup_repository.dart` - Extended export/import to include all tables

**Test Results:** ✅ Existing backup tests passing

---

### Sprint 3: Transaction Editing ✅
**Status:** COMPLETED  
**Story Points:** 8

**Changes:**
- Added `updateTransaction()` method to `PostingsRepository`
- Method validates postings sum to zero, updates in single transaction, recomputes daily_totals
- Edit UI already existed in ledger via long-press/swipe

**Files Modified:**
- `lib/data/postings_repository.dart` - Added updateTransaction method
- `test/sprint3_update_transaction_test.dart` - New test file

**Test Results:** ✅ All tests passing

---

### Sprint 4: Capture Flow Improvements ✅
**Status:** COMPLETED  
**Story Points:** 10

**Changes:**
- Added wallet selector chip showing current wallet name
- Added "Sering" (frequent) templates row showing top 5 most-used category+amount combinations
- Made note field collapsible with "Tambah catatan" button
- Added haptic feedback to category selection
- Fixed filter amount preservation (TextEditingController initialization)

**Files Modified:**
- `lib/features/capture/capture_sheet.dart` - Added wallet selector, frequent templates, collapsible note, haptic feedback
- `lib/features/ledger/ledger_screen.dart` - Fixed filter amount preservation

**Test Results:** ✅ Updated tests to handle collapsible note field

---

### Sprint 5: Recurring Items Management ✅
**Status:** COMPLETED  
**Story Points:** 8

**Changes:**
- Added edit and delete action buttons to active recurring items
- Created `_EditRecurringSheet` widget for editing recurring item properties
- Added delete confirmation dialog
- Edit allows changing amount, day, category, account, weekend rule

**Files Modified:**
- `lib/features/recurring/recurring_screen.dart` - Added edit/delete actions and edit sheet

**Test Results:** ✅ No breaking changes to existing tests

---

### Sprint 6: Accessibility and Loading States ✅
**Status:** COMPLETED  
**Story Points:** 5

**Changes:**
- Added accessibility labels to DaySquare widgets ("Tanggal X, tercatat/belum tercatat, hari ini")
- Created `PantauSkeleton` loading state with shimmer animation
- Replaced CircularProgressIndicator with skeleton cards matching actual layout
- PaceRing already had text scaling implemented

**Files Modified:**
- `lib/features/ledger/today_header.dart` - Added dayLabel parameter and Semantics wrapper
- `lib/design/pantau_skeleton.dart` - New file with skeleton loading widgets
- `lib/features/pantau/pantau_screen.dart` - Integrated skeleton loading

**Test Results:** ✅ All tests passing

---

### Sprint 7: Search and Filter Improvements ✅
**Status:** COMPLETED  
**Story Points:** 5

**Changes:**
- Search already filters across category, account, and note fields via LedgerFilter
- Filter sheet preserves min/max amounts when reopened
- Added pull-to-refresh (`RefreshIndicator`) to Catat, Pantau and Anggaran. Every
  scrolling body across the three gets `AlwaysScrollableScrollPhysics` so a short
  list can still be pulled.
- The pull is logged as `pull_to_refresh` (props: screen) because it is the manual
  fallback for a change the automatic path missed; whether anyone ever needs it is
  the only evidence the automatic path is reliable. Anggaran is the one of the three
  with no table listener, so a pull is genuinely its only route to fresh data.

**Files Modified:**
- `lib/features/ledger/ledger_screen.dart` - RefreshIndicator + `_refresh()`
- `lib/features/pantau/pantau_screen.dart` - same, on both the skeleton and loaded bodies
- `lib/features/budget/budget_screen.dart` - same
- `test/features/pull_to_refresh_test.dart` - New test file

**Test Results:** ✅ 380 tests passing

---

## Remaining Sprints

### Sprint 8: Budget and Period Improvements ✅
**Status:** COMPLETED  
**Story Points:** 5

**Changes:**
- Budget edit undo: saving shows a "Batalkan" snackbar that restores the whole
  previous set. `BudgetsRepository.clearAmount` exists because a key that was never
  saved before has to be deleted, not set to Rp 0 (a zero budget is a saved budget).
- Period close theme cleanup: the sheet's figures and the two ad-hoc
  `Colors.white.withOpacity(...)` calls became named inverse tokens
  (`onInversePositive`, `onInverseNegative`, `onInverseSurfaceStep`,
  `onInverseHairline`) on `WudgetTokens`, so no feature reaches into
  `WudgetTokens.dark` as a literal any more.
- Nav bar token cleanup: `navBarHeight` renamed `navBarContentHeight` (it is the
  height excluding the system inset), and the hardcoded 76px capture gap became
  `navBarCaptureGap = captureButton + 20`.

**Files Modified:**
- `lib/design/tokens.dart` - inverse palette + nav bar tokens
- `lib/features/budget/budget_screen.dart` - undo snackbar
- `lib/data/budgets_repository.dart` - `clearAmount`
- `lib/features/pantau/period_close_sheet.dart` - inverse tokens
- `lib/features/shell/nav_bar.dart` - token + derived gap
- `test/features/budget_undo_test.dart` - New test file

**Test Results:** ✅ All tests passing

---

### Sprint 9: Wallet Management ✅
**Status:** COMPLETED (3 of 3 tickets)  
**Story Points:** 5

**Changes:**
- Group totals: each CardGroup in Kantong now ends in a subtle "Total <group>" row.
  A group holding more than one currency prints no total, matching `_TotalCard`'s
  rule that a cross-currency sum is a number wudget cannot honestly compute (R-17).
- Empty state CTA: "Tambah kantong pertama" moved inside the card that explains the
  wallet shape, so it is on screen without scrolling; the copy below it stays. It was
  previously the last child of the ListView, below the fold on a short screen.
- Wallets in capture: **decided keep, and built.** `plan/04-ux-design.md` draws the
  capture sheet as `[GoPay v]` (a caret, so interactive) and states "the wallet
  defaults to the last wallet used with the selected category, not to a global
  default. Changing category may change the wallet, and doing so is visible." The
  shipped Sprint 4 code drew a read-only chip that never adopted the last wallet, so
  Sprint 4's own done-when ("users can see and change wallet") was never met.
  - `CaptureQueries.lastAccountIdForCategory` reads the last wallet from postings
    rather than storing a preference, so it cannot disagree with recorded history.
  - The chip is now a `PopupMenuButton` when more than one wallet exists, a plain
    label when there is only one (nothing to choose between).
  - Selecting a category adopts that category's last wallet. A hand-picked wallet
    holds until the category changes.

**Files Modified:**
- `lib/features/wallets/wallets_screen.dart` - group totals + CTA move
- `lib/features/capture/capture_sheet.dart` - interactive wallet control + adoption
- `lib/data/capture_queries.dart` - `lastAccountIdForCategory`
- `test/features/sprint9_wallets_test.dart` - New test file (5 tests)
- `test/golden/kantong_empty_{light,dark}.png` - regenerated (CTA moved)

**Test Results:** ✅ All tests passing

---

### Sprint 10: Onboarding ✅
**Status:** COMPLETED  
**Story Points:** 8

**Changes:**
- `lib/features/onboarding/onboarding_screen.dart`: the four screens from
  `design/mockups/onboarding-mockup.html`, built with the app's tokens (no emoji, no
  unsourced "100% offline" badge), with "Lanjut"/"Mulai catat" and "Lewati".
- Completion flag `onboardingCompletedKey`, set on finish and on skip, with
  `onboarding_finished` / `onboarding_skipped` analytics events.
- Wired into `main.dart` `showLaunchSurface`: a fresh install opens the tour instead of
  the capture sheet.

**Files Modified:**
- `lib/features/onboarding/onboarding_screen.dart` - New file
- `lib/data/feature_flags_repository.dart` - `onboardingCompletedKey`
- `lib/main.dart` - launch surface
- `test/features/onboarding_test.dart` - New test file (4 tests)

**Test Results:** ✅ All tests passing

---

### Sprint 11: Local Rails - Bet 3 ✅
**Status:** COMPLETED (logos resolved as "not shipped")  
**Story Points:** 8

**Changes:**
- Real bank logos: deliberately not shipped. No licence for provider artwork
  (DECISIONS.md, R-23); Kantong keeps a type icon on a neutral ground.
- Notification capture policy spike: `research/11-notification-capture-policy.md`.
  Policy claims are marked unverified and must be checked before a Play upload.
  Also corrected a stale doc comment in `PaymentListenerService.kt`.
- QRIS scan flow designed in `plan/02-flows.md` section 11.

---

### Sprint 12: Goals and Motivation ✅
**Status:** COMPLETED  
**Story Points:** 8

**Changes:**
- `Goals` table and schema v12 migration (`database.dart`); the mangled migration
  indentation was fixed.
- `lib/domain/goal.dart`: milestone maths (25/50/75/100), progress, message copy.
- `lib/data/goals_repository.dart`: create, soft delete, watch, and
  `announceMilestones`, which fires each milestone once via `notifiedMilestone`.
- Kantong gets a "Target" section (`lib/features/goals/goals_section.dart`): goal rows
  with milestone chips and a "Target baru" sheet (name, target, wallet; a savings
  wallet is preselected).
- Period close surplus card now offers the transfer into the first goal's wallet
  (falls back to a savings wallet). The transfer goes through the capture sheet, so
  postings are written balanced by `PostingsRepository`.
- `main.dart` runs `announceMilestones` at launch and on every postings/goals write;
  `NotificationScheduler.showNow` posts the notification on a "Target" channel.
- Goals included in backup export/import (older backups without goals still import).

**Files Modified:**
- `lib/data/database.dart`, `lib/data/goals_repository.dart` (new),
  `lib/core/providers.dart`, `lib/features/goals/goals_section.dart` (new),
  `lib/features/wallets/wallets_screen.dart`, `lib/features/pantau/period_close_sheet.dart`,
  `lib/data/notification_scheduler.dart`, `lib/data/backup_repository.dart`, `lib/main.dart`
- Tests: `test/domain/goal_test.dart` (4), `test/goals_repository_test.dart` (4),
  v12 assertion in `test/migration/schema_migration_test.dart`

**Test Results:** ✅ All tests passing

---

### Sprint 13: Budget Validation ✅ (code; the run itself is a human step)
**Story Points:** 5
- `FeatureFlagsRepository.assignPaceFirstVariant()` (called from `main.dart`) gives each install a random framing once, never re-rolled, and logs `variant_assigned`. Before this every device was pace-first.
- `pantau_reveal` event logged when either arm taps through to the hidden number.
- `BackupRepository.exportJson()` now includes `analyticsEvents`, so testers can send the log back (restore ignores it).
- `research/10-budget-validation.md` section 9: measurement plan, the SQL to run, decision rule. (The plan's "08" filename is wrong; 08 is the retention baseline.)
- Test: `test/feature_flags_repository_test.dart` (assignment sticks and is logged).

---

### Sprint 14: Additional Features ✅
**Story Points:** 10
- **Langganan:** `recurrences.is_subscription` (schema v13, migration for v7+ databases, old backups restore as unflagged). "Langganan" switch in the add/edit sheets; a Langganan section on Berulang & tagihan with "Total per bulan" (`subscriptionMonthlyMinor`, weekly/yearly/daily scaled to a month). Tests: `test/sprint14_subscriptions_test.dart`, v12 fixture in `test/migration/schema_migration_test.dart`.
- **Split capture:** "Pecah ke beberapa kategori" in expense capture (new entries only, not edits). Lines of category + amount, live "Sisa", save blocked until two categories and Rp 0 remaining; one account leg, one category leg per line. Test: `test/features/split_capture_test.dart`.
- **CSV transfers:** new optional "Kantong tujuan (transfer)" mapping; a row with both accounts and no category imports as a balanced transfer. Test in `test/csv_import_repository_test.dart`.
- **Insight voice:** the 7-sentence skip buffer already existed (`insightMemory = 7` in `domain/insight.dart`, tested in `test/domain/insight_test.dart`). No change.
- Known limit: editing a split transaction from the ledger opens capture with a single category; it is not split-aware.

---

### Sprint 15: Store Submission ✅ (code; submission is a human step)
**Story Points:** 5
- Release signing was already in `android/app/build.gradle` (reads `android/key.properties`, falls back to debug key). Added `android/key.properties.example`. `key.properties` and `*.jks` are gitignored. `flutter build appbundle --release` uses the same config.
- `docs/privacy.html`: Indonesian + English policy for GitHub Pages, matching the app: no server, local-only data, notification listener limited to GoPay/Livin'/Jago/ShopeePay, household email stays local, backups only go where the user sends them. Placeholders `[TANGGAL TERBIT]` and `[EMAIL KONTAK]` to fill.

---

### Sprint 16: Household Sharing Validation ✅ (code; analysis is a human step)
**Story Points:** 3
- Saya, Data, "Berbagi dengan keluarga" opens `features/settings/household_screen.dart`: says it is not available yet, takes an email, logs `household_interest` with the email to the local log. The screen and the policy both say the email leaves the phone only in a backup the user sends.
- Test: `test/features/household_interest_test.dart`.

---

### Sprint 17: Multi-Currency (v2) ✅
**Story Points:** 5
- `plan/09-multi-currency.md` covers all four done-when items: FX source (section 2), UI (section 4), cross-currency totals (section 5), v2 implementation plan (section 6). No gaps found; no changes.

---

## Human steps remaining

- [ ] Sprint 13: recruit 20+ beta testers, ship the beta build, collect each tester's backup JSON at day 14, run the query in `research/10-budget-validation.md` section 9, interview, fill section 8, apply section 5.
- [ ] Sprint 14: check over 2+ weeks of real use that the home insight does not repeat.
- [ ] Sprint 15: generate the upload keystore (keep it outside the repo, back it up):
  `keytool -genkey -v -keystore C:/Users/<you>/keys/wudget-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] Sprint 15: `cp app/android/key.properties.example app/android/key.properties` and fill in passwords and `storeFile`.
- [ ] Sprint 15: build `cd app && flutter build appbundle --release` (output `build/app/outputs/bundle/release/app-release.aab`); check signing with `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`.
- [ ] Sprint 15: fill the placeholders in `docs/privacy.html`, enable GitHub Pages (Settings, Pages, branch `main`, folder `/docs`); URL will be `https://adijaay.github.io/wudget/privacy.html`.
- [ ] Sprint 15: create Google Play Console (and Apple Developer, if iOS) accounts; fill the listing, Data safety form (no data collected or shared), notification-listener disclosure per `research/11-notification-capture-policy.md`; upload the AAB to internal testing, then submit.
- [ ] Sprint 16: after the beta, count `household_interest` events across returned backups; if 20%+ of testers signed up, prioritise household sharing post-v1 and record the decision.

---

## Summary

**Completed:** 17 sprints (code and docs; human steps listed above)
**Remaining:** human steps only
**Total Story Points Completed:** 116 / 116 (code)
**Total Story Points Remaining:** 0 (code)

**Test Status:** ✅ All tests passing: 407 after Sprints 13-17 (400 after Sprint 12)
**Breaking Changes:** None - all changes are backward compatible

**Key Achievements:**
- Fixed critical auto-save bug that was creating unbalanced postings
- Complete backup/restore now captures all user data
- Transaction editing fully functional
- Capture flow significantly improved with wallet selector, frequent templates, and collapsible notes
- Recurring items can now be edited and deleted
- Accessibility improved with screen reader labels
- Loading states replaced with skeleton screens

**Next Steps:**
1. Verify the unverified policy claims in research/11 before Sprint 15's Play upload.
2. Work through "Human steps remaining" above.

## Notes from this run

- **Sprint 6 was broken on disk when this run started.** `pantau_screen.dart` imported
  `pantau_skeleton.dart` from `lib/features/pantau/`, but the file was created in
  `lib/design/`. All five test files that load Pantau failed to compile, so the suite
  was at 342 pass / 5 fail before any work here. Fixed as the first step.
- **Sprint 9 needed a grep, not a run.** The capture sheet has no i18n keys and its
  finders are on Indonesian literals; where the mockup and the shipped code disagreed
  about the wallet control, `plan/04-ux-design.md` settled it.
