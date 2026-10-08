# Continue Wudget Sprint Plan

## Context
You are continuing development on **wudget**, an Indonesian personal money tracker Flutter app at `D:\program\wudget`. A sprint plan was created from UX, functional, and product audits, and work has begun. Your job is to continue from where it left off.

## Read These First (in order)
1. `plan/07-audit-fixes-progress.md` — what's done, what's remaining, test status
2. `plan/06-audit-fixes.md` — full sprint plan with all tickets and done-when criteria
3. `design/mockups/README.md` — index of all hi-fi mockups
4. Open the relevant mockup HTML files in a browser for the sprint you're working on

## Where We Left Off
- **Sprints 1-6:** Complete (auto-save fix, backup completeness, transaction editing, capture flow improvements, recurring items management, accessibility/loading states)
- **Sprint 7:** Partially done (filter preservation fixed, pull-to-refresh NOT yet added)
- **Sprints 8-17:** Not started

## Next Immediate Tasks
1. **Finish Sprint 7:** Add `RefreshIndicator` (pull-to-refresh) to ledger, Pantau, and Budget screens
2. **Sprint 8:** Budget edit undo snackbar, period close theme cleanup, nav bar token cleanup
3. **Sprint 9:** Wallet group totals, empty state CTA fix, capture wallet decision
4. **Sprint 10:** Onboarding flow (use `design/mockups/onboarding-mockup.html` as reference)

## Hi-Fi Mockups Available
All in `design/mockups/`:
- `onboarding-mockup.html` — Sprint 10 onboarding flow
- `goals-mockup.html` — Sprint 12 goals and milestone chips
- `capture-flow-mockup.html` — Sprint 4 (already implemented, reference for consistency)
- `pantau-skeleton-mockup.html` — Sprint 6 (already implemented)
- `split-transaction-mockup.html` — Sprint 14 split transactions
- `household-sharing-mockup.html` — Sprint 16 household placeholder

## Coding Standards
- **ponytail mode:** Simplest solution that works. No over-engineering. Stdlib first, native platform features first, shortest diff.
- **antislop-code:** No decorative comments, no restating the obvious, no workflow narration. Comments only when they explain something the code doesn't already show.
- **antislop-ui:** Follow the design tokens in `lib/design/tokens.dart`. Use existing components from `lib/design/components.dart`. No generic fintech aesthetics.
- **Money:** Always use `Money`/`MoneyFormatter` from `core/money.dart`. Never use `double` for money amounts. The test `money_formatter_is_the_only_path_test.dart` enforces this — files in `lib/design/` are exempt from the double ban.
- **Language:** All UI strings in Indonesian (Bahasa Indonesia).

## Architecture Quick Reference
- **State:** Riverpod (`flutter_riverpod`)
- **Database:** Drift (SQLite), schema in `lib/data/database.dart`
- **Repositories:** `lib/data/` — one repo per concern
- **Features:** `lib/features/` — one folder per screen/feature
- **Domain:** `lib/domain/` — pure logic, no Flutter imports
- **Design:** `lib/design/tokens.dart` (tokens), `lib/design/components.dart` (reusable widgets)
- **Tests:** `test/` — run with `flutter test`

## Key Patterns
- **Posting invariant:** Every transaction's postings must sum to zero in `baseAmountMinor`. Enforced by `PostingsRepository.insertTransaction()`.
- **Soft delete:** Transactions use `deletedAt` timestamp, never hard-delete (except `undoInsert`).
- **Day buckets:** Local calendar days as integer offsets from epoch. See `domain/period.dart`.
- **Period:** Configurable start day (default 25th). See `SettingsRepository.effectivePeriodFor()`.

## Testing
- Run full suite: `cd D:/program/wudget/app && flutter test`
- New features should have at least one test covering the core behavior
- Use `NativeDatabase.memory()` for in-memory test databases
- Call `TestWidgetsFlutterBinding.ensureInitialized()` in widget tests
- Use `tester.ensureVisible()` before tapping widgets that may be off-screen (the capture sheet scrolls)

## Build & Deploy
- Debug APK: `flutter build apk --debug`
- Release APK: `flutter build apk --release`
- Pixel 4 connected via ADB: `adb -s 99061FFAZ00916 install -r <apk-path>`
- GitHub Releases: repo at `https://github.com/adijaay/wudget`

## Important Notes
- The capture sheet note field is now **collapsible** (hidden by default, tap "Tambah catatan" to expand). Tests that interact with the note field must tap "Tambah catatan" first.
- The wallet selector chip was added to capture for expense/income modes (not transfer, which has its own from/to dropdowns).
- Pantau skeleton loading uses shimmer animation, not a spinner.
- The `_frequentTemplates()` widget queries the database for top 5 category+amount+note combinations.

## When You Finish a Sprint
1. Write a test covering the done-when criteria
2. Update `plan/07-audit-fixes-progress.md` to mark the sprint complete
3. Run the full test suite to confirm nothing broke
4. Move to the next sprint
