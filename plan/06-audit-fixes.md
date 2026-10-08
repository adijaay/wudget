# Sprint Plan: Audit Fixes and Feature Completion

Based on UX, functional, and product audits conducted 2026-10-07. Organized by priority and dependency.

---

## Sprint 1: Critical Data Integrity (1 week)

**Goal:** Fix critical bugs that break core functionality or risk data loss.

**Tickets:**
1. **Fix auto-save unbalanced postings** - payment_auto_save_repository.dart creates one posting leg but ledger requires sum-to-zero. Add balancing category leg.
2. **Fix daily totals wrong column** - daily_totals_repository.dart line 107 sums amountMinor instead of baseAmountMinor, breaking multi-currency.
3. **Fix auto-save error handling** - Track which payments succeeded vs failed. Only clear successful payments from SharedPreferences.
4. **Fix payment dedup** - isDuplicate() only checks amount + 3-minute window. Include merchant name or use hash of (amount + merchant + timestamp).
5. **Fix SharedPreferences atomicity** - Use synchronized block or separate keys per payment to prevent race conditions.

**Done-when:**
- Auto-save successfully creates transactions with balanced postings
- Daily totals use baseAmountMinor
- Failed payments are logged and retried on next launch
- Two different Rp 50,000 payments within 3 minutes both save
- No race conditions in rapid notification handling

**Story points:** 8

---

## Sprint 2: Backup/Restore Completeness (1 week)

**Goal:** Ensure backup captures all user data and restore is safe.

**Tickets:**
1. **Complete backup export** - Add budgets, recurrences, recurrence_overrides, app_settings, feature_flags to exportJson().
2. **Add import validation** - Validate sum-to-zero invariant before inserting. Reject invalid backups with clear error.
3. **Fix recurrence template validation** - Add schema validation on templateJson after jsonDecode. Check required fields exist.

**Done-when:**
- Backup includes all tables
- Corrupt backup is rejected with error message, not imported
- Malformed recurrence template shows descriptive error

**Story points:** 5

---

## Sprint 3: Transaction Editing (1 week)

**Goal:** Allow users to edit saved transactions.

**Tickets:**
1. **Implement updateTransaction** - Add method to PostingsRepository that validates new postings sum to zero, updates in single transaction, recomputes daily_totals.
2. **Add edit UI to ledger** - Long-press or swipe action on transaction row opens edit sheet.
3. **Add undo for edit** - Snackbar with "Batalkan" action that restores previous values.

**Done-when:**
- Users can edit amount, category, account, note on saved transactions
- Edit preserves transaction ID or regenerates cleanly
- Daily totals recompute correctly after edit
- Undo restores previous state

**Story points:** 8

---

## Sprint 4: Capture Flow Improvements (1 week)

**Goal:** Reduce friction in the primary capture flow.

**Tickets:**
1. **Add wallet selector to capture** - Show current wallet as chip below category row. Allow override of auto-selection.
2. **Fix filter preserve amounts** - Initialize TextEditingController with current filter values when reopening sheet.
3. **Add Sering templates row** - Show top 5 most-used category+amount+note combinations above category tiles.
4. **Collapse note field** - Move below category selection or make collapsible with "Tambah catatan" button.
5. **Fix category label truncation** - Add Tooltip or increase tile width to show full name.
6. **Add haptic feedback** - Period navigation arrows, category selection, save button.

**Done-when:**
- Users can see and change wallet during capture
- Filter sheet shows current min/max values
- Repeat expenses capture in 2 taps via Sering row
- Note field doesn't block primary flow
- Category names fully visible
- Haptic feedback on key interactions

**Story points:** 10

---

## Sprint 5: Recurring Items Management (1 week)

**Goal:** Allow users to edit and delete recurring items.

**Tickets:**
1. **Add edit/delete actions** - Long-press or trailing icon on recurring item opens edit sheet or delete confirmation.
2. **Fix recurrence ID collision** - Use UUID for transaction IDs or add conflict handling (INSERT OR REPLACE).
3. **Add edit future from date** - Allow editing from a specific date forward, splitting the rule.

**Done-when:**
- Users can edit amount, frequency, category on recurring items
- Delete shows confirmation dialog
- editFutureFrom() doesn't cause ID collisions
- Changes apply to future occurrences only

**Story points:** 8

---

## Sprint 6: Accessibility and Loading States (1 week)

**Goal:** Improve accessibility and loading UX.

**Tickets:**
1. **Day squares accessibility** - Wrap _DaySquare in Semantics with label "Tanggal X, tercatat/belum tercatat, hari ini".
2. **Calculator expression announcement** - Update semanticsLabel to include full expression when _pendingExpression.isNotEmpty.
3. **Pantau skeleton loading** - Replace CircularProgressIndicator with skeleton cards matching pace ring, forecast, category list layout.
4. **Pace ring text scaling** - Use scaled dimension for font size calculations instead of fixed size parameter.

**Done-when:**
- Screen readers announce each day's status in logged days strip
- Calculator mode announces full expression to screen readers
- Pantau shows skeleton during initial load
- Pace ring text scales proportionally at 200% text size

**Story points:** 5

---

## Sprint 7: Search and Filter Improvements (1 week)

**Goal:** Expand search scope and add manual refresh.

**Tickets:**
1. **Expand search scope** - Filter across category, account, and note fields, not just notes.
2. **Add pull-to-refresh** - Wrap ListView in RefreshIndicator on ledger, Pantau, and Budget screens.

**Done-when:**
- Search matches category names, wallet names, amounts, and notes
- Pull-to-refresh works on all main screens
- Manual refresh fallback when automatic updates fail

**Story points:** 5

---

## Sprint 8: Budget and Period Improvements (1 week)

**Goal:** Improve budget editing and period navigation UX.

**Tickets:**
1. **Budget edit undo** - Add snackbar with "Batalkan" action after save that restores previous budget values.
2. **Period close theme cleanup** - Create dedicated periodCloseTheme extension or use Theme override instead of hardcoded dark tokens.
3. **Nav bar token cleanup** - Define navBarCaptureGap = captureButton + 20 in WudgetTokens. Rename navBarHeight to navBarContentHeight or document SafeArea behavior.

**Done-when:**
- Budget edits can be undone via snackbar
- Period close sheet uses Theme override, not hardcoded tokens
- Nav bar gap derived from tokens, not magic number
- Token naming is accurate

**Story points:** 5

---

## Sprint 9: Wallet Management (1 week)

**Goal:** Improve wallet list UX and make capture wallet decision.

**Tickets:**
1. **Add group totals** - Show subtle total row at bottom of each CardGroup with sum of wallets.
2. **Fix empty state CTA** - Move "Tambah kantong pertama" button immediately after explanatory text or add second CTA at top.
3. **Wallets in capture decision** - Decide: hide wallet picker (simpler, matches "one pool" model) or keep it (more flexible). Implement decision.

**Done-when:**
- Wallet groups show totals
- Empty wallet state CTA visible without scrolling
- Capture wallet behavior matches design decision
- Implementation consistent with decision

**Story points:** 5

---

## Sprint 10: Onboarding (1 week)

**Goal:** Guide first-time users through core concepts.

**Tickets:**
1. **Build onboarding flow** - 3-4 screens introducing: capture button and three-tap flow, four tabs and purposes, period concept in Pantau, privacy/local storage.
2. **Add skip option** - Allow users to skip onboarding.
3. **Track completion** - Store onboarding_completed flag in app_settings.

**Done-when:**
- First-time users see onboarding on first launch
- Onboarding covers core concepts in under 30 seconds
- Skip option works
- onboarding_completed flag prevents re-showing
- Returning users skip onboarding

**Story points:** 8

---

## Sprint 11: Local Rails - Bet 3 (1 week)

**Goal:** Strengthen local payment rail integration.

**Tickets:**
1. **Real bank/e-wallet logos** - Replace colored circles with initials with actual GoPay, OVO, DANA, ShopeePay, BCA, Mandiri logos.
2. **Notification capture policy spike** - Research Android notification-listener policy for sideloaded apps. Document findings and path forward.
3. **QRIS scan flow design** - Design QRIS scan-to-capture flow. Document in plan/02-flows.md.

**Done-when:**
- Wallet cards show real logos for major Indonesian payment providers
- Notification capture policy research documented
- QRIS scan flow designed and documented

**Story points:** 8

---

## Sprint 12: Goals and Motivation (1 week)

**Goal:** Add minimal goal model for retention.

**Tickets:**
1. **Build goal model** - Target amount, savings wallet, milestone chips at 25/50/75/100%.
2. **Surplus sweep** - When period closes with surplus, offer to sweep to savings goal.
3. **Milestone celebration** - Show milestone reached notification when goal hits 25/50/75/100%.

**Done-when:**
- Users can create savings goals with target amount
- Milestone chips show progress
- Period close offers surplus sweep to goal
- Milestone reached triggers notification

**Story points:** 8

---

## Sprint 13: Budget Validation (1 week)

**Goal:** Validate pace-first vs remaining-first bet with real users.

**Tickets:**
1. **Ship to beta with measurement** - Enable feature flag and analytics for beta users.
2. **Analyze results** - After 2 weeks, analyze pantau_viewed events with variant. Compare engagement patterns.
3. **Document findings** - Write up results in research/08-budget-validation.md.

**Done-when:**
- Beta users have pace-first or remaining-first variant
- Measurement hooks active
- 20+ beta users over 2 weeks
- Results documented with recommendation

**Story points:** 5

---

## Sprint 14: Additional Features (1 week)

**Goal:** Add high-value features identified in research.

**Tickets:**
1. **Subscription tracking** - Build "Langganan" view showing only recurring items marked as subscriptions with total.
2. **Split transactions** - Implement split capture: one amount divided across categories with live remainder.
3. **CSV import transfer support** - Detect transfers in CSV (two account columns, no category) and create transfer transactions.
4. **Insight voice validation** - Test with 2+ weeks of real data. If insight picker repeats, implement 7-sentence skip buffer.

**Done-when:**
- Subscription view exists with total
- Split capture works for multi-category expenses
- CSV import handles transfers
- Insight picker produces novel sentences daily

**Story points:** 10

---

## Sprint 15: Store Submission (1 week)

**Goal:** Prepare and submit to stores.

**Tickets:**
1. **Generate upload keystore** - Create release keystore and store securely.
2. **Host privacy policy** - Publish privacy policy to live URL (GitHub Pages works).
3. **Create store accounts** - Set up Google Play Console and Apple Developer accounts.
4. **Build release APK/AAB** - Generate signed release builds.
5. **Submit to stores** - Upload builds, fill in store listings, submit for review.

**Done-when:**
- Keystore generated and backed up
- Privacy policy live at URL
- Store accounts created
- Release builds signed
- Apps submitted to Google Play and App Store

**Story points:** 5

---

## Sprint 16: Household Sharing Validation (1 week)

**Goal:** Validate demand for household sharing feature.

**Tickets:**
1. **Add placeholder in Saya** - "Share with household" option that collects email interest.
2. **Track interest** - Log household_interest events with email.
3. **Analyze results** - If 20%+ of beta users express interest, prioritize as immediate post-v1 feature.

**Done-when:**
- Placeholder exists in Saya
- Email collection works
- Interest tracked and analyzed
- Decision documented based on results

**Story points:** 3

---

## Sprint 17: Multi-Currency (v2) (1 week)

**Goal:** Design multi-currency support for v2.

**Tickets:**
1. **FX rate source design** - Research and design FX rate source (API, caching, historical rates).
2. **Multi-currency UI** - Design wallet creation with currency choice, transaction currency selection.
3. **Cross-currency totals** - Design how to show totals across currencies (convert to base, show "reason" instead of number).

**Done-when:**
- FX rate source documented
- Multi-currency UI designed
- Cross-currency total strategy documented
- Implementation plan for v2

**Story points:** 5

---

## Summary

**Total sprints:** 17 weeks (roughly 4 months)

**Priority order:**
1. Sprints 1-3: Critical bugs and data integrity (must fix before anything else)
2. Sprints 4-5: Core UX improvements (capture flow, recurring items)
3. Sprints 6-9: Polish (accessibility, search, budget, wallets)
4. Sprint 10: Onboarding (first-time user experience)
5. Sprints 11-12: Strategic features (local rails, goals)
6. Sprint 13: Validation (budget bet)
7. Sprint 14: Additional features
8. Sprint 15: Store submission
9. Sprints 16-17: v2 features (household, multi-currency)

**Total story points:** 116

**Risk:** Sprint 13 (budget validation) depends on having beta users. Sprint 15 (store submission) depends on owner actions (keystore, accounts). Sprint 16 (household validation) depends on having active beta users.

**Cut list (if needed):**
- Sprint 14: Split transactions (can defer to v1.1)
- Sprint 16: Household validation (can defer to post-v1)
- Sprint 17: Multi-currency (can defer to v2)
