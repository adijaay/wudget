# Feature scope

Each feature carries the research that justifies it. `[R-##]` refers to research files;
citations like `[04]` mean [research/04-user-reviews.md](../research/04-user-reviews.md).

---

## Phase 0: foundation

No user-visible surface. These exist because the benchmark reviews show they cannot be
retrofitted.

**Money as integer minor units.** Every amount is an int64 count of the currency's smallest
unit plus a currency code. No floating point anywhere near a balance. `[04]` Goodbudget
reviewers report the app getting arithmetic wrong as envelopes multiplied.

**Postings ledger (double-entry-lite).** A transaction owns two or more postings that sum to
zero. This is what makes a credit card payment behave correctly, which is a specific reported
bug in both Ollo and Money Manager. `[01]`, `[04]`

**One money formatter.** A single service, one rule, used by every widget that renders an
amount. `[07]` Ollo shows a day total in USD above rows in IDR on the same screen; Richual
shows `$7,691.7 / $6,270` and then tiles it as `$6K / $8K / -$1K`; Expensa renders
`$1 563,41`. All three are formatter inconsistencies, and they are the worst class of defect
in a money app.

**Backup, restore, export and import.** CSV and JSON out, restore in, and a migration path
that can roll back. `[04]` Data loss appears in 7 per cent of negative reviews and is the
most damaging 7 per cent: an update wiping categories and accounts (Money Manager), a year of
data collapsing into one month (Buddy), five years of categorised history lost with no import
path to rebuild (Rocket Money).

---

## Phase 1: capture

### The one-sheet entry screen

Modelled on Ollo's, which is the best in the market, with four changes. `[07]`

Carried over: single sheet with no navigation; type segmented control; scrolling category
row; **subcategory chips filtered by the selected category**, which turns the slowest step
into one tap; large amount field; custom numpad with a calculator toggle, an in-sheet date
button, and a `000` key for rupiah.

Changed: the wallet defaults to the last one used for this category rather than to a global
default. The five most frequent recent entries appear as one-tap templates above the category
row (Money Manager's payment profiles, which is its most under-copied feature). Every screen
reachable from the sheet has a visible back affordance, which is a reported dead end in Ollo.
And the note field is optional and collapsed by default, because it is the field people skip.

Target, measured not asserted: a repeat expense in three taps plus the amount.

### Wallets

Typed accounts: cash, bank, e-wallet, credit card, savings, debt, other. Indonesian bank,
digital bank and e-wallet logos on the card, which MELD calls out explicitly and which makes
a wallet identifiable at a glance. `[01]`

Credit cards carry a statement cycle and a due date, so a purchase draws from the card and a
payment is a transfer from a bank account. `[01]` Money Manager has had this since 2012 and
most modern competitors still do not.

### Transactions

Expense, income and transfer. Split across categories on one transaction, which Money Manager
reviewers ask for directly. `[04]` Optional photo attachment. Optional geotag, off by
default.

### Categories

Two levels, with a small default set rather than a large one. `[05, section 1]` Heath and
Soll show that category structure changes decisions rather than just reporting them, and that
narrow categories create artificial blocks. Users can add and rename, and the default set is
Indonesian in naming and in composition (kos, transport online, pulsa dan data, kondangan).

### Period model

Month start date is configurable, defaulting to the 1st. `[01]` Payday cycles are how
salaried users actually think, and shorter concrete periods produce better estimates
`[05, section 3]`.

### List and daily totals

Date-grouped list with a per-day subtotal, which is the number people check. `[07]`

### Home widget

Android app widget and iOS widget, both with one-tap add. `[04]` Ollo's own reviewers request
it, and SyncSpend and Money Manager both ship it.

---

## Phase 2: understanding

### Pace and forecast, instead of remaining balance

The hero number is spending pace against elapsed time, with a forecast of where the period
lands. The remaining balance is one tap away, not on the hero. `[05, section 11]` and
`[06, item 1]`

Built behind a flag so both framings can be measured, because the evidence is a working
paper rather than settled science.

### The interpreted sentence

Every insight surface states its conclusion in one sentence a person would say out loud, next
to the number. `[07]` Expensa is the only app in the study that does this, and
`[05, section 12]` says uninterpreted repetitive feedback is a named reason people abandon
self-tracking.

### Budgets, and when they appear

Not in onboarding. The app observes for the first two weeks, then proposes a budget from the
user's own history at the first period boundary, and the user edits rather than authors.
`[05, section 2]` Budget predictions made against an open time frame run well below actual
spending, and the mechanism is the savings goal held while predicting, so asking for a number
on day one extracts a guess and then holds the user to it. `[03]` Expensa already proposes
rather than asks, which is the pattern worth taking.

### The irregular expense bucket

A named container for exceptional spending: repairs, gifts, kondangan, travel, THR.
`[05, section 2]` Sussman and Alter show people budget ordinary spending well and badly
underestimate exceptional spending, because each item is construed as a one-off. Giving them
one home is the intervention the authors propose.

### Recurring items and bills

Recurrence with the edge cases handled: weekend shifting, month-end dates that do not exist
in every month, variable amounts, and an explicit distinction between a projected instance
and a recorded one. `[04]` Every app in the sample gets at least one of these wrong, and
Money Manager's reviews describe recurring entries vanishing and then appearing all at once.

Reminders name the specific expected expense and the shortfall, not a generic percentage.
`[05, section 5]` Karlan and colleagues find reminders work better when they raise the
salience of a specific expenditure.

### Category ranked list

A ranked list with transaction counts, not a second pie chart. `[07]` Ollo's Top Spenders
answers the same question faster than a pie does.

---

## Phase 3: retention

### Period close

At the period boundary: a summary, an explicit re-commitment, and an offer to move the
surplus into a goal. `[05, section 6]` Temporal landmarks raise motivation, and the monthly
boundary these apps already have is a motivational asset most of them waste.
`[05, section 11]` Prompting a rollover into savings is one of the mitigations reported to
attenuate the overspending effect.

### Goals with visible milestones

Milestone chips that complete early rather than one long bar that barely moves.
`[05, section 7]` Gal and McShane find that the fraction of accounts closed predicts debt
elimination while the balance closed does not, so visible completion sustains persistence.

### Lapse and return

A user who stopped logging on the 12th is reachable on the 1st, not on the 20th.
`[05, sections 6 and 12]` Abandonment is normal rather than a failure state, so the design
handles lapse and return instead of only rewarding streaks. No streak counter that resets to
zero and shames the user out of the app.

### Import from competitors

CSV import for Money Manager and Ollo exports. `[04]` A user rebuilding after a loss is the
most motivated user there is, and no incumbent serves them.

---

## Phase 4: household (v2)

### Invite by code with owner approval

Owner receives a household code, shares it, the joiner enters it, the owner approves from a
notification. `[07]` This is MELD's flow and it is the clearest in the study. The approval
step is what stops a leaked code from becoming a stranger reading the ledger.

### Activity notification

A push when a household member records a transaction. `[01]` This is MELD's retention
mechanic and `[05, section 8]` explains why it works: spending shared money creates a need to
justify it, and visibility to another person is the intervention.

### Per-item privacy and a clean removal path

Some spending is private. And relationships end. `[03]`, `[04]` A Honeydue reviewer reports
no way to separate a former partner from shared bills, which is a requirements gap rather
than a bug.

---

## Non-goals, and what would have to change

| Deferred | Re-entry condition |
|---|---|
| Bank aggregation | Day-30 retention proves the product and manual capture is the binding constraint. Note that sync failure is the single largest source of one-star reviews in the benchmarks `[04]` |
| QRIS or notification capture | The Android notification-listener policy question is answered, and manual capture is measurably the reason users churn `[03]`, `[06]` |
| WhatsApp or Telegram capture | Phase 4 ships and household users ask for capture outside the app. MELD proves the demand exists |
| Investments and full net worth | Users ask for it repeatedly, and the account model already supports balances |
| AI chat assistant | There is a question users actually ask that the ranked list and the interpreted sentence cannot answer |
| Community feed | Never, on current evidence. MELD has one and nothing suggests it retains anyone |
| Gamified levels and streaks | Never as specified elsewhere. `[05, section 13]` A level badge rewards logging, and logging is the means, not the goal |
| Education tab | Never. `[05, section 9]` 201 studies, 585,168 participants, roughly 0.1 per cent of variance in behaviour. The same content as one sentence at the decision point is the version with evidence |
| Web and desktop | Phase 4 ships and households want a shared screen |
| Payables, receivables, arisan | A separate decision about serving small businesses, because it pulls the data model toward accounting `[PLAN risks]` |

## Feature ideas from the research not yet placed

Recorded so they are not lost, each with the app that proved the idea.

- Reimbursements, money you are owed (Ollo). Real behaviour, common in Indonesia, small model
  change.
- Wishlist of intended purchases (Ollo). Sits between a goal and nothing, and gives wants a
  place before they become spending.
- Goal trajectory, an estimate of how long a goal takes at the current rate (MELD).
- Subscription tracking with reminders (Ollo, Expensa, MELD, Richual). Cheap, and the one
  category where users consistently do not know their own totals.
- Activity heatmap laid out as a calendar (Ollo). Answers "did I log this month" better than
  a streak counter, without the shaming.
- Per-transaction historical FX rate (Expensa). Only matters for users living across
  currencies, and impossible to add correctly after the fact.
- Financial health score with recommended next actions (MELD). Attractive and risky: it is a
  score, so it needs a defensible formula or it is theatre.
