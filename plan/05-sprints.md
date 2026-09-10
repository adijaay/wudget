# Sprint plan

Solo, full time, one-week sprints, running to a v1.0 on both stores.

**Estimating unit.** 1 point is half a day of focused work. A one-week solo sprint carries
**8 points**, which assumes four focused days and one day absorbed by decisions, store
admin, device testing and the things that always appear. Sprints that come in at 10 points
are not ambitious, they are mis-estimated.

**Total: 21 sprints, roughly five months to v1.0.** Milestones fall at Sprint 7 (alpha),
Sprint 13 (beta) and Sprint 20 (release).

Phases referenced here are the ones in [PLAN.md](../PLAN.md). Feature detail is in
[01-features.md](01-features.md), flows in [02-flows.md](02-flows.md), technical decisions in
[03-architecture.md](03-architecture.md), design rules in [04-ux-design.md](04-ux-design.md).

---

## Global definition of done

A ticket is not done until all of these are true. No exceptions for "I will come back to it",
because solo work is where that promise goes to die.

1. Tests written for the behaviour, not after it, and green in CI.
2. Empty, loading and error states implemented for any surface that displays data.
3. Works offline, because offline is the normal case and not an edge case.
4. Light and dark both render correctly.
5. Amounts go through `MoneyFormatter`, never through a local format call.
6. No fabricated content, no placeholder data dressed up as real.
7. Merged behind a flag if it is not finished, rather than left on a branch.

---

## Milestone A: it captures (Sprints 0 to 7)

### Sprint 0: skeleton and rails

Goal: an empty app that builds, tests and ships on both platforms, so nothing later is
blocked by tooling.

| Ticket | Pts |
|---|---|
| Flutter project, flavors, folder layout per [03-architecture.md](03-architecture.md) | 2 |
| CI: analyze, test, and build both platforms on every push | 2 |
| Design token skeleton with placeholder values, light and dark ThemeExtension | 2 |
| Decision log with an ADR template, seeded with the locked decisions from PLAN.md | 1 |
| Set up the one mid-range Android device that all performance numbers are measured on | 1 |

Done when: CI is green and a token demo screen renders on both platforms in both themes.

### Sprint 1: money and the ledger core

Goal: the arithmetic can never be wrong.

| Ticket | Pts |
|---|---|
| `Money` value type, currency table with exponents, arithmetic, throws on mixed currency | 2 |
| `MoneyFormatter` plus golden tests for IDR, USD, JPY, zero, negative, very large | 2 |
| Drift schema: accounts, categories, transactions, postings | 2 |
| Postings-sum-to-zero invariant, with property tests over generated transactions | 2 |

Done when: the property suite is green and a guard test fails the build if a `double` or a
raw `NumberFormat` appears in the money path.

### Sprint 2: durability before features

Goal: the thing that killed the incumbents cannot happen here.

| Ticket | Pts |
|---|---|
| Migration harness, forward and backward, tested against a fixture from the prior version | 2 |
| Lossless JSON export and import, round-tripped on a 5,000 transaction fixture | 2 |
| Automatic local backup on a schedule, last-backup time exposed to the UI layer | 2 |
| Restore with a dry-run preview of what will be created and replaced | 1 |
| CSV export | 1 |

Done when: the 5,000 row round trip produces identical balances, and restore preview counts
match what restore actually does.

### Sprint 3: the capture sheet, structure

Goal: an expense can be saved. This is the sprint the product lives or dies on, so it gets
two sprints and no passengers.

| Ticket | Pts |
|---|---|
| Sheet shell, segmented type control, amount field focused with the numpad up on open | 2 |
| Custom numpad: digits, backspace, decimal, `000`, save | 2 |
| Category row plus subcategory chips filtered by the selected category | 3 |
| Save writes postings, sheet dismisses, undo affordance appears | 1 |

Done when: an expense is saved end to end, and a baseline time-to-save is recorded on the
measurement device.

### Sprint 4: the capture sheet, speed

Goal: the three-tap path exists and is measured.

| Ticket | Pts |
|---|---|
| Frequency templates row, top five from recent entries | 2 |
| Wallet selector with per-category last-used default | 2 |
| Calculator toggle in the numpad | 1 |
| In-sheet date and time button showing the current value | 1 |
| Collapsed note field, receipt photo attachment | 1 |
| Back affordance audit on every route reachable from the sheet | 1 |

Done when: a repeat expense takes three taps plus the amount, measured and written into the
decision log, and median save-to-dismissed is under 100ms.

### Sprint 5: wallets and cards

Goal: money lives somewhere, and a card payment behaves.

| Ticket | Pts |
|---|---|
| Wallet create, edit, archive; types; Indonesian bank and e-wallet provider logo set | 3 |
| Kantong tab: list, balances, cross-currency total with an explicit conversion label | 2 |
| Transfer flow between wallets | 2 |
| Card statement cycle and due date, with a prefilled payment transfer | 1 |

Done when: a test proves a card payment does not appear in spending statistics.

### Sprint 6: the ledger tab

Goal: yesterday is legible.

| Ticket | Pts |
|---|---|
| Daily aggregate table plus its maintenance path | 2 |
| Catat list with date grouping and per-day subtotals, read from the aggregate | 3 |
| Edit, soft delete, undo | 1 |
| Search and filter by category, wallet, period, amount, note | 2 |

Done when: 10,000 transactions render in under 300ms, and the filtered-empty state names the
filter that is excluding everything.

### Sprint 7: capture from outside the app, and the first performance gate

Goal: logging starts before the app opens.

| Ticket | Pts |
|---|---|
| Android app widget with one-tap add | 3 |
| iOS widget | 2 |
| App icon long-press shortcut and deep links into a prefilled sheet | 1 |
| Performance pass against the budget in [03-architecture.md](03-architecture.md) | 2 |

**Milestone A. Start using it yourself, every day, as your only tracker.** Everything after
this point is informed by that, and any sprint can be reordered by what dogfooding exposes.

---

## Milestone B: it explains (Sprints 8 to 13)

### Sprint 8: periods and aggregates

| Ticket | Pts |
|---|---|
| Period model with a configurable month start day, capped at 28 | 2 |
| Period selector control that governs every surface below it | 1 |
| Per-period aggregate queries, precomputed rather than computed on render | 3 |
| Pantau tab shell with the honest first-14-days waiting state | 2 |

### Sprint 9: pace and forecast

Goal: the screen that contradicts every competitor.

| Ticket | Pts |
|---|---|
| Pace computation, spend against elapsed time in the period | 2 |
| Pace ring plus the interpreted-sentence generator | 2 |
| Actual against forecast line, solid to today, dashed beyond, with a labelled legend | 3 |
| Remaining balance, one tap from the pace card and not on it | 1 |

Done when: the ten chart rules in [04-ux-design.md](04-ux-design.md) pass, and no projected
value is visually indistinguishable from a recorded one.

### Sprint 10: budgets, proposed rather than asked

| Ticket | Pts |
|---|---|
| Budget proposal engine built from the user's own 14 days of history | 3 |
| Budget review and edit screen, every number editable | 2 |
| Per-category budget rows showing pace, over-budget marked by sign and icon as well as hue | 2 |
| Irregular expense bucket as its own row | 1 |

Done when: no user is ever shown a blank budget field.

### Sprint 11: the framing experiment, and the rest of the review surface

| Ticket | Pts |
|---|---|
| Feature flag infrastructure | 1 |
| Pace-first against remaining-first variants behind the flag, with measurement hooks | 3 |
| Category ranked list with amount, share and transaction count | 2 |
| Week bar chart | 1 |
| Calendar activity heatmap | 1 |

This is the sprint that turns the plan's one contested bet into a measurement rather than a
belief. See [research/06-implications.md](../research/06-implications.md).

### Sprint 12: recurrence, done properly

Goal: the defect every audited competitor has.

| Ticket | Pts |
|---|---|
| Recurrence rules table, materialisation to a watermark, idempotent under repeated runs | 3 |
| Edge case suite: non-permanent month-end clamp, weekend rule, skip, move, amend | 3 |
| Shared `is_projected` exclusion predicate used by every aggregate | 1 |
| Variable-amount items with an expected range | 1 |

Done when the table-driven suite covers the 31st in a 30-day month, a Sunday due date, a
skipped instance, an early payment, and one-instance against all-future edits.

### Sprint 13: bills and reminders

| Ticket | Pts |
|---|---|
| Recurring and bills UI, split into upcoming and active | 2 |
| Local notification scheduling | 2 |
| Notification action deep-linking into a prefilled capture sheet | 2 |
| Reminder copy naming the specific expense and the shortfall | 1 |
| Timezone and DST correctness tests on scheduled delivery | 1 |

**Milestone B. Feature-complete for the core loop. Hand it to five real users.**

---

## Milestone C: it keeps people (Sprints 14 to 20)

### Sprint 14: period close

| Ticket | Pts |
|---|---|
| Trigger logic, fires once per period boundary, dismissible | 2 |
| Summary with the largest change against the previous period | 2 |
| Surplus sweep into a goal | 2 |
| Next period prefilled from this one | 1 |
| Interpreted sentence for the close | 1 |

### Sprint 15: goals

| Ticket | Pts |
|---|---|
| Goal model backed by real transfers into a savings wallet | 2 |
| Milestone chips that complete at intervals | 2 |
| Trajectory estimate at the current contribution rate | 2 |
| Behind-schedule state with one concrete suggestion | 1 |
| Empty state with one example framed in local terms | 1 |

### Sprint 16: import from competitors

| Ticket | Pts |
|---|---|
| CSV importer framework with a column mapping step | 3 |
| Money Manager profile, tested against a real export | 2 |
| Ollo profile, tested against a real export | 2 |
| Partial import: valid rows land, failures report row number and reason | 1 |

### Sprint 17: the states pass

Goal: the thing no competitor screenshot in the research even shows.

| Ticket | Pts |
|---|---|
| Implement every state in the table in [04-ux-design.md](04-ux-design.md) | 5 |
| Screenshot every state into a gallery, reviewed in one sitting | 2 |
| Lapse-and-return copy that invites rather than scolds | 1 |

### Sprint 18: accessibility, themes, craft

| Ticket | Pts |
|---|---|
| Dark theme complete, golden tests for both themes on the key screens | 2 |
| Contrast assertions on every token pair actually used | 1 |
| 200 per cent text scale on the capture sheet, the ledger row, the pace card | 2 |
| Semantics labels, screen reader traversal of the capture sheet with amounts announced | 2 |
| Reduce-motion fallbacks | 1 |

### Sprint 19: store readiness

| Ticket | Pts |
|---|---|
| Privacy policy and terms, Indonesian and English, published before submission | 2 |
| Store listings and ASO, including a name collision check across both stores | 2 |
| Screenshots showing the real UI with no invented numbers | 2 |
| Signing, release builds, submission prep for both stores | 2 |

The name collision check is not busywork: the research found three unrelated Android apps
sharing the Expensa name and two sharing SyncSpend
([research/01-app-teardowns.md](../research/01-app-teardowns.md)).

### Sprint 20: release

| Ticket | Pts |
|---|---|
| Closed beta with real users, feedback triaged into fix-now and backlog | 3 |
| Fix pass | 3 |
| Full antislop Delivery Gate with evidence recorded per item | 1 |
| Submit to both stores | 1 |

**Milestone C: v1.0.**

---

## Decision deadlines

Each of the `[CONFIRM]` items in [DESIGN.md](../DESIGN.md) blocks a specific sprint. Missing
these dates does not stop the build, it just means rework later.

| Decision | Needed by | What it blocks |
|---|---|---|
| Accent colour | Sprint 3 | Capture sheet visual, and every token after it |
| Typeface | Sprint 3 | Type scale, and the tabular-figures decision for amounts |
| Identity motif (the envelope candidate) | Sprint 5 | Wallet card design, and the period-close screen |
| Pricing model | Sprint 19 | Store listing only. The research is unambiguous that history is never gated |
| Logo | Sprint 19 | Store submission only. Wordmark in the display face until then |

---

## Cut list, in order

Solo work slips. Decide now what goes, so the decision is not made at 2am in Sprint 18.

1. iOS widget (Sprint 7). Android carries the market.
2. Calendar activity heatmap (Sprint 11).
3. Ollo import profile (Sprint 16). Ship the Money Manager one, since it has the larger
   installed base by a wide margin.
4. Goals entirely (Sprint 15), moved to 1.1. It is the most self-contained feature in the
   plan, which makes it the cheapest to defer.
5. The framing experiment's second variant (Sprint 11). Ship pace-first and measure it
   against nothing, accepting that the bet then goes untested.

Never cut: anything in Sprints 1 and 2, the states pass, the accessibility sprint, or the
performance gate. Those are the four places the incumbents lost their users.

---

## Weekly rhythm

- **Monday.** Pick the sprint goal in one sentence. If the tickets do not serve that sentence,
  they are not this week's tickets.
- **Daily.** One ticket in progress at a time. A blocked ticket goes back to the board rather
  than sitting half-done next to a second one.
- **Thursday.** Measure whatever this sprint claimed to improve, on the real device. Numbers
  into the decision log.
- **Friday.** Demo to yourself against the sprint goal, then a five-line retro: what shipped,
  what slipped, what the dogfooding exposed, what moves, what gets cut.
- **Every Friday from Sprint 7.** You are the user. Write down the one thing that annoyed you
  most this week. That list outranks this plan.

---

## After v1.0

Not scheduled here, in rough order. Household sharing is Phase 4 in
[PLAN.md](../PLAN.md) and is a five to six sprint block of its own: sync and outbox, the
household code and owner approval flow, per-item privacy, activity notifications, member
removal, and the two-device offline convergence test.

Ahead of it, three smaller candidates pulled from the research: reimbursements, subscription
tracking, and the QRIS or notification capture spike, that last one gated on the Android
notification-listener policy question in
[research/06-implications.md](../research/06-implications.md).
