# Flows and UX patterns

Five flows carry the whole category. Everything else is decoration on top of these. For
each one: what the apps in this study actually do, and where the trade-off sits.

---

## 1. Onboarding

**What the apps do.** Two shapes appear. The accounting-first shape (Money Manager) drops
you into a working default configuration and lets you reconfigure later; its own description
sells this as the point, that defaults get you started and the flexible settings come once
you are used to it. The setup-first shape (Expensa, Ollo, Richual) asks you to name wallets
and starting balances, pick or accept categories, and set a budget before you have logged
anything.

**The trade-off.** Setup-first produces a correct ledger and a high drop-off, because the
user is asked to make decisions (which categories? what budget?) that they do not yet have
the data to answer. This is not a hypothetical: the budget-prediction literature shows that
budgets set before you have evidence are systematically too low, by around a quarter to a
third of eventual spend
(see [05-behavioral-research.md](05-behavioral-research.md)). So the setup-first flow
extracts a guess and then holds the user to it.

Expensa's answer is worth noting: AI proposes a first budget split across categories from
the user's region and habits, so the user edits rather than authors. That converts a blank
page into a review task, which is a much easier ask.

**Monarch's reviews give the counter-example.** A long two-star review argues that a
seven-day trial is too short for a monthly-cycle product, because you need a full cycle to
see how transactions, rules, rollovers and recurring items behave. Another reviewer, who has
budgeted for 25 years, says the initial setup instructions were fine and everything after
them was not. Onboarding is not the tutorial. The first full cycle is.

**Pattern worth stealing.** Let the first week be observation only. Capture, no budget.
Then set budgets from what actually happened, at the first month boundary, which is also the
moment the fresh-start literature says motivation peaks.

---

## 2. Capture

This is the flow that decides retention in a manual app, and the one place where a few
hundred milliseconds and one extra tap really matter.

**The best layout observed, Ollo.** Everything on one sheet: type segmented control,
scrolling category row, subcategory chips, amount with currency picker, title, note, wallet
picker, and a custom numpad carrying a calculator toggle, a date and time button, and a
`000` key. Nothing pushes a new screen. The subcategory chips are the clever part: they
turn the slowest step (finding the right category in a long list) into one tap on a short
row, because the row is filtered by the category already selected.

**Cheap capture accelerators, ranked by what they cost to build.**

| Accelerator | Seen in | Cost | Coverage |
|---|---|---|---|
| Calculator numpad and `000` | Ollo | Low | Every entry |
| Saved templates for repeated spends | Money Manager (payment profiles) | Low | Frequent, identical spends |
| Home screen widget | SyncSpend, Money Manager | Low | Starts capture outside the app |
| Subcategory chips filtered by category | Ollo | Low | Every entry |
| Receipt photo with OCR | Ollo, MELD | Medium | Paper receipts only |
| Voice entry | Ollo, MELD | Medium | Fast, needs a quiet moment |
| Chat capture over a messenger | MELD (WhatsApp) | Medium | Where the user already is |
| Card tap via platform Shortcut | Expensa, SyncSpend | Low to build, fiddly to set up | Card spend only, no cash |
| SMS or notification parsing | Common in India, not in this set | Medium, permission-heavy | Bank-alerting markets |
| Bank aggregation | None of the seven | High | Broad, and it breaks (see reviews) |

**On SMS and notification parsing.** In India a whole generation of apps was built on
parsing bank SMS alerts, and the pattern persists because the alerts are reliable and
detailed. In Indonesia the equivalent surface is the push notification from bank and
e-wallet apps rather than SMS, which makes an Android notification listener the analogous
route. It is worth checking against current Play policy on notification access before
designing around it, because that permission is heavily restricted.

**The friction paradox.** Manual entry is the thing users complain about most, and the
literature on payment friction says the friction is doing work. Cash hurts to spend and
cards do not (Prelec and Loewenstein's decoupling), and physically partitioning money
raises self-control by inserting a small decision cost (Cheema and Soman). Fully automatic
capture removes the moment of noticing along with the typing. The design question is not
"how do we remove friction" but "which friction earns its keep": the typing does not, the
pause to name what you just bought might.

---

## 3. Budget setup and the budget surface

**Four models in the wild.**

1. Category limits with a progress bar. The default, used by Ollo, Richual, Expensa,
   Money Manager. Easy to build, easy to understand, and weakly connected to behaviour.
2. Envelope or zero-based, where every unit of income is assigned before it is spent. YNAB,
   EveryDollar, Goodbudget. Stronger behavioural grounding, much higher cognitive load, and
   the source of the sharpest complaints. One Copilot reviewer switching from YNAB says
   directly that they disliked the give-every-dollar-a-job model and wanted flexibility
   without constant reallocation. Another YNAB reviewer calls planning the next month
   mentally exhausting.
3. Percentage frameworks, 50/30/20 and its variants. Coined by Warren and Warren Tyagi in
   All Your Worth (2005) as the Balanced Money Formula. Simple, memorable, and its 50 per
   cent needs ceiling is unrealistic for many households in high-rent cities.
4. Pace and forecast, where the app does not enforce a limit but tells you whether the
   current rate lands inside it. Expensa's pace ring with an interpreted sentence, plus a
   dashed forecast line past today.

**Where the surface goes wrong, from reviews.** Money Manager users hit a budget system
that cannot express the categories they have. Monarch users describe category and budget
organisation as confusing and restrictive, and rule priority as opaque. Goodbudget users
call the envelope maths harder than it should be. The recurring theme is that the budget
model is rigid in a place where real life is not: irregular income, variable bills like
power and water, and one-off large expenses.

**The finding that should change the design.** A working paper by Pocheptsova Ghosh and
Huang (three field studies, two lab experiments) reports that access to live budget feedback
increased spending, concentrated at the end of the budget period, and that people tracking
by memory did not overspend. The proposed mechanism is certainty: knowing exactly how much
is left licenses spending it. A separate field experiment with 9,035 users over 13 weeks
found no spending difference between one-number budgets, category budgets and an
informational control, and that budgeters spent 1.3 to 1.4 times what they had budgeted.
Details and citations in [05-behavioral-research.md](05-behavioral-research.md).

The design implication is uncomfortable for a category whose flagship screen is a "left to
spend" number. A remaining-balance display is not neutral. Framings worth testing against
it: pace against elapsed time rather than remaining total, a forecast of where the period
lands, or an explicit prompt to move the surplus out rather than leaving it visible and
spendable.

---

## 4. Review and insight

**What is on the screens.** A category donut or pie (all of them). A trend line with period
toggles (Richual, Expensa). A calendar heatmap (Expensa, Money Manager's calendar view).
Top-category callouts. A geographic spending map (Richual). Period comparison against the
previous period (Expensa).

**What the abandonment literature says about this screen.** Studies of self-tracking
abandonment find that abstract visualisation without suggested action, and feedback that
repeats without telling the user anything new, are among the reasons people stop. A donut
that looks the same every month is a reason to close the app, not to open it.

**The one pattern that survives that critique.** Expensa's pace card does not just show a
number, it writes a sentence interpreting it. That is the difference between a chart and an
insight: the chart asks the user to do the inference, the sentence does the inference and
can be wrong in a way the user can correct. Everything else in the review surfaces observed
here is a chart.

**Comparison framings ranked by how much they can mislead.** Against your own past
(defensible), against your budget (see the caution above), against other users
(unverifiable and easy to make demoralising), against a generic rule like 50/30/20 (fine as
a starting point, wrong for many households).

---

## 5. Shared and group money

**MELD is the only app in the named set that treats this as the product.** Sharing groups
for a spouse, friends, business partners, or an arisan group; a push notification when a
group member records a transaction; an audit trail on transactions; accounts payable and
receivable. The notification is the mechanism that matters: it makes the ledger visible in
near real time to someone who will notice if you stop logging, which is social enforcement
rather than a reminder from an app.

**What the benchmarks get wrong here, from their reviews.** Honeydue reviewers report bank
sync failing every few days, support not replying, and, in one striking case, no way to
separate a former partner from shared bills after a breakup. That last one is a real
requirements gap: shared-money features need an unwind path, because relationships end and
housemates move out, and the data model has to survive it.

Splitwise sits in an adjacent category (netting group debts, not budgeting) and its 3.97
rating is largely about entry limits pushing users to subscribe, plus confusion about
settling payments made outside the app. Group expense splitting and personal budgeting are
usually different products; the reviews suggest people want them joined, and nobody in this
set has joined them well.

**Design requirements a shared ledger needs and most apps skip.** Per-item visibility (some
spending is private). A clean invite and, more importantly, a clean removal. A conflict
story for two people editing offline. Clarity on who pays for the subscription, which one
Monarch reviewer raises directly as an unanswered question.

---

## Interface craft notes from the screenshots

**Persistent capture affordance.** Richual keeps a capture bar above the tab bar on every
tab, with three directional actions. Ollo uses a floating plus. The persistent bar is the
stronger pattern for a manual app because it removes the discovery step entirely, at the
cost of permanent vertical space.

**Period selector placement.** Ollo puts Day/Week/Month/Year/All at the very top of home,
above the balance. That makes period the primary lens on everything below it, which is
correct for a tracker and worth copying.

**Date-grouped list with per-day totals.** Ollo, and it is the right default: the daily
subtotal is the number people actually check, and it turns a flat list into a rhythm.

**Currency display consistency.** In an Ollo screenshot the daily total renders in USD while
each line renders in IDR. Multi-currency roll-ups need one rule applied in every formatter,
or the numbers stop being trustworthy, and trust is the whole product.

**Dark-first design.** Richual and Expensa present dark only in their store screenshots.
Ollo leads dark but its Statistics screen is light, so it ships both. MELD advertises dark,
light, a cute theme and custom themes. In a finance app used in daylight, in a shop,
one-handed, dark-only is a choice worth revisiting rather than inheriting. Full per-app
detail in [07-ui-audit.md](07-ui-audit.md).

**Icon and colour load.** Ollo assigns a coloured icon per category and uses one accent for
the active state, which reads well. Richual applies a single green to wallet cards, charts,
nav, accent text and the wordmark at once, which flattens the hierarchy: when everything is
the accent, nothing is.

**Empty, loading and error states.** Not visible in any store screenshot, which is expected
(marketing shows the full state) and also the most common place these apps break. The
review evidence is indirect but consistent: sync failures, blank recurring items, and
vanished history all show up as unexplained empty screens rather than as messages that say
what happened and what to do next.
