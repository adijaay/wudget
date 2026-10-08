# Flows

Screen by screen, including the states. Every flow lists its empty, loading and error
behaviour, because none of the 28 competitor screenshots reviewed shows any of them and the
review record says that is exactly where these apps break
([research/07-ui-audit.md](../research/07-ui-audit.md)).

Copy in this file is written as intent, in English. Shipped strings are Indonesian, in the
register set by [DESIGN.md](../DESIGN.md).

---

## Navigation shell

Four labelled bottom tabs, plus a capture affordance.

| Tab | Job | The one decision made here |
|---|---|---|
| Catat | Today's list, daily totals, running balance | Is what I spent today what I thought? |
| Pantau | Pace, forecast, category ranking, budgets | Am I on track, and where is it going? |
| Kantong | Wallets, balances, transfers, cards due | How much do I have, and where? |
| Saya | Goals, recurring, settings, backup | What am I working toward, and is my data safe? |

Labels stay on the tabs. `[07]` Ollo's four unlabelled glyphs are not self-evident and the
second and third are guesses.

Capture is a single floating action button, bottom right, with bottom padding on every scroll
container equal to the button's height plus a gutter. `[07]` SyncSpend's FAB sits on top of a
transaction amount. Richual's alternative, a persistent capture bar plus a tab bar plus a
floating button, eats roughly a quarter of the screen height, so wudget takes the affordance
and not the chrome.

---

## 1. First run

The principle: capture before configuration. `[05, section 2]`

1. One screen explaining what the app does and that it works with no account and no network.
   One action: start.
2. Wallet setup, minimum viable. Ask for one wallet and its current balance, with cash
   preselected. Offer to add an e-wallet or bank from a list of Indonesian providers, and let
   the user skip it.
3. Straight into the capture sheet with a prompt to log one thing.
4. No budget question. No category configuration. No goal setup. `[03]` Setup-first
   onboarding extracts guesses the user cannot yet make.

Days 1 to 14: the app captures and shows daily and weekly totals. The Pantau tab exists and
says plainly that it is still watching, and how many days remain before it can propose
something.

Day 14 or the first period boundary, whichever is later: the budget proposal appears, built
from the user's own history, with every number editable. `[05, section 2]`

**States.** Empty: the Catat tab with no transactions shows what the first entry will look
like and one action to add it, not the phrase "no data". Error on wallet creation: the sheet
stays open with the entered values intact.

---

## 2. Capture

The core flow. Full visual specification in
[04-ux-design.md](04-ux-design.md).

**Entry points.** FAB from any tab. Home screen widget. Long-press app icon shortcut.
Notification action on a bill reminder.

**The sheet, top to bottom.** Type control (Pengeluaran, Pemasukan, Transfer). A row of up to
five one-tap templates built from recent frequency. Scrolling category row. Subcategory chips
filtered by the selected category. Amount, large, with the currency only shown when more than
one currency exists. Collapsed note. Wallet selector, defaulted to the last wallet used with
this category. Numpad with calculator toggle, in-sheet date and time, `000`, and save.

**Save behaviour.** Save closes the sheet, returns to where the user was, and shows an undo
affordance for a few seconds. No confirmation dialog. No success screen.

**Transfer variant.** The category row is replaced by a from-wallet and to-wallet pair. A
credit card payment is this flow, and it must not appear in spending statistics. `[01]`,
`[04]` This is a reported bug in both Ollo and Money Manager.

**Split variant.** From the sheet's overflow, one amount divided across categories, with the
remainder shown live so it cannot silently not add up.

**States.** Loading: none, the sheet is local and instant. Error on save: the sheet stays
open, the values stay, and the message names what failed. Offline: not an error state, this
is the normal case.

---

## 3. Catat, the daily list

Date-grouped list, per-day subtotal, newest first. Row: category icon in the category hue,
title or category name, wallet name, amount with an explicit sign, time.

Swipe a row for edit and delete. Delete is undoable, and a deleted transaction is soft
deleted so a restore can bring it back. `[04]`

Search and filter by category, wallet, period, amount range and note text.

**States.** Empty for a new user: what the first entry looks like plus one action. Empty for
a filtered view: which filter is excluding everything, plus one action to clear it. These are
two different screens. `[07]` Loading on a large history: skeleton rows only for the list, the
day headers and totals render from a cached aggregate. Error: the list renders from local
data, so the only real error is a corrupt database, which routes to restore-from-backup rather
than to a generic message.

---

## 4. Pantau, the review surface

Ordered by what answers the user's question soonest.

1. **Pace.** Spending against elapsed time in the period, as a ring plus a written sentence.
   The sentence is the point. `[07]`, `[05, section 12]`
2. **Forecast.** A line, solid to today and dashed beyond it, with the budget as a labelled
   dashed horizontal. `[07]` This is Expensa's pattern and nobody else has it.
3. **Remaining balance.** One tap from the pace card, not on it. `[05, section 11]`,
   `[06, item 1]`
4. **Category ranking.** Ranked list with amount, share and transaction count. No second pie.
   `[07]`
5. **Budgets.** Per category, each showing pace rather than a bare percentage. Over-budget is
   shown with a sign and an icon, never by hue alone. `[07]`
6. **Irregular bucket.** Its own row, so exceptional spending is visible as a set.
   `[05, section 2]`

Period navigation is a single control at the top of the tab, applying to everything below it.
`[07]` Ollo puts the period selector above the balance, which is the correct hierarchy for a
tracker.

**States.** During the first 14 days: an honest waiting state saying what it is collecting and
when the proposal arrives. Empty period: which period is empty and how to move to one that is
not. Error: any figure that cannot be computed is blank with a reason, never zero. A zero and
an unknown are different facts and a money app must not conflate them.

---

## 5. Kantong, wallets

Wallet list with balance, type, and the provider logo where one exists. Total across wallets,
with an explicit label when currencies were converted and at what rate. `[07]` A mixed
currency total with no label is how Ollo's total-versus-rows inconsistency reads to a user.

Card rows show the statement cycle and the amount due, with the due date. Tapping a card
offers the payment transfer prefilled.

Transfer between wallets from this tab. Balance adjustment as an explicit, labelled
correction rather than a silent edit, so the ledger keeps an honest trail.

**States.** Empty: one wallet is created in onboarding, so this is only reachable if the user
deletes all of them, and it offers to add one. Error on a converted total: show each currency
separately rather than a wrong single number.

---

## 6. Recurring and bills

List split into upcoming and active. Each item: name, amount or "varies", schedule in plain
language, next date, and the wallet it draws from.

A projected instance is visually distinct from a recorded one and never counts toward actual
spending until confirmed. `[04]` This distinction is the fix for the most specific repeated
complaint in the sample.

Reminder copy names the expense and the shortfall. `[05, section 5]`

Variable-amount bills (power, water) are supported as an item with an expected range, because
Monarch reviewers report they cannot be tracked at all. `[04]`

**Edge cases that must be handled explicitly.** The 31st in a 30-day month. A due date on a
Sunday. A skipped instance. An instance paid early. Changing the amount for one instance
against changing it for all future ones.

**States.** Empty: what a recurring item is for, with one example and one action. Error on
generation: the item is flagged in the list with the reason, not silently absent.

---

## 7. Period close

Fires at the period boundary, once, and is dismissible. `[05, section 6]`

1. What happened: total in, total out, the largest category, and the one thing that differed
   most from the previous period.
2. One interpreted sentence.
3. The surplus, if any, with an offer to move it into a goal. `[05, section 11]`
4. Next period's budget, prefilled from this period, editable.
5. One action to confirm.

**States.** No data for the closing period: skip the ritual entirely rather than showing an
empty ceremony. A lapsed user returning: a shortened version that does not scold, offering to
resume from today. `[05, section 12]`

---

## 8. Goals

Goal with a target, a deadline, and milestone chips that complete at intervals rather than a
single long bar. `[05, section 7]` Contributions are transfers into a savings wallet, so a
goal is backed by real money rather than by a number.

Trajectory line: at the current rate, the expected completion date. Recorded from MELD.

**States.** Empty: one example goal framed in local terms, and one action. Behind schedule:
the trajectory, the gap, and one concrete suggestion, never a red screen alone.

---

## 9. Backup, restore, import and export

In Saya, not buried in an advanced screen. `[04]`

- Automatic local backup on a schedule, with the last backup time visible.
- Manual export to CSV and JSON, shareable to any target the OS offers.
- Restore from a file, with a preview of what will be replaced and an explicit confirmation.
- Import from Money Manager and Ollo CSV, with a column mapping step and a dry-run count of
  what will be created before anything is written.

**States.** Import error: which row failed and why, with the valid rows still importable.
Never all-or-nothing with a generic failure.

---

## 10. Household (v2)

**Owner.** Create household, receive a code, share it, approve a join request from a
notification, manage members, remove a member. `[07]`

**Joiner.** Enter the code, wait for approval with a visible pending state, then see shared
data.

**Privacy.** Each transaction is household-visible or private, defaulting to household
inside a shared wallet and private inside a personal one. Changing the default is one
setting, not a per-entry decision every time.

**Removal.** Removing a member retains shared history, returns their private items to them,
and revokes their access immediately. `[04]` This is the Honeydue gap.

**Conflict.** Two members editing the same transaction offline is a real case, and the
resolution rule is stated in [03-architecture.md](03-architecture.md) rather than left to
whichever device syncs last.

**States.** Pending approval: what the joiner sees and how long it has been waiting. Sync
failure: the local ledger stays authoritative and usable, with a visible, non-blocking
indicator of when it last synced. `[04]` A stale ledger presented as current is the failure
mode that destroyed trust in the bank-synced benchmarks.

---

## 11. QRIS and payment capture

The principle: an automatic guess earns its place only when it is visible and one tap from
being corrected. `[06, item 4]` An invisible wrong guess costs trust in every total. A QRIS
payment is made in a wallet or bank app, so this is a capture flow and not a payment flow:
wudget never holds the money and never sees the payment succeed.

This is a design, not built code. The notification parsing it would lean on exists in the
repo, in `app/android/app/src/main/kotlin/id/wudget/wudget/PaymentParser.kt` and
`PaymentListenerService.kt`, with `app/lib/data/payment_auto_save_repository.dart`, but there
is no scan, no suggestion surface and no confirm step wired to any screen. The whole flow sits
behind the same unresolved question as the notification-capture policy spike: whether a
distributed Android app may hold a notification listener for this at all. `[01]`, `[06]`

**wudget does not scan the QRIS code.** A merchant-presented QRIS is either static, the same
code on the counter every time with no amount in it, or dynamic, with the amount embedded and
generated per transaction. The dynamic code is scanned by the paying app in the user's hand,
so the amount lands inside GoPay or the bank app and wudget cannot see it. The static code
carries no amount, so decoding it recovers at most a merchant identity that the notification
already supplies. The amount and the merchant are therefore read from the payment notification
the wallet or bank app posts, which is text already on the device with no server involved.
Camera scanning and screenshot reading are both out of this design, because each adds a
permission and a decode step to recover fields the notification already gives, and neither
confirms that the payment succeeded.

1. A payment happens in a shop. The user scans the merchant's QRIS with GoPay, Livin' by
   Mandiri, Jago, ShopeePay or a bank app and pays. wudget is not in this loop.
2. The paying app posts a notification, and often the receiving bank posts one too. If the
   notification listener is running and the package is one of the known labels, the parser
   reads an amount (an `Rp` or `IDR` figure with separators stripped), a loose merchant string
   after `ke`, `di`, `kepada`, `to` or `at`, and the app label. Anything matching the skip list
   is dropped: money in, top-ups, cashback, promos, and OTP or verification codes are not
   spending.
3. wudget holds the parse as a suggestion, not as a transaction. The suggestion appears as a
   row in Catat marked unconfirmed and, when the user has allowed it, as a wudget notification.
   Nothing reaches the ledger until the user acts, which is the contract the parser states:
   the owner confirms every suggestion before anything is saved.
4. The suggestion shows what was guessed and where each field came from. Amount and merchant
   come from the notification. The wallet is mapped from the app label to a wallet with that
   provider where one exists. The category is the guess, and a notification carries a merchant
   name, not a category.
5. Accept is one tap and writes the expense, with the same undo affordance as any other save
   and no dialog. Correct is one tap that opens the capture sheet already filled through the
   `CaptureLaunch` prefill, where the wrong field is changed and the sheet saved.
6. An unacted suggestion expires and is never written. A phantom ledger row the user did not
   accept is worse than no automation at all. `[06, item 4]`

**Taps, counted from the steps above.** Accept-the-guess is one tap. Correct-one-field is
three: open the suggestion, change the field, save, and if the field is the amount, one tap
per digit typed. No notification, which is the case for cash and for any app outside the known
labels, is the plain sheet: a category tap, the amount digits, and save, unchanged.

The manual baseline is the same three taps plus the amount digits that `capture_sheet.dart`
builds. `[07]` Against that baseline, honestly:

- A correct guess saves two taps and every amount digit. This is the whole prize, and it only
  exists when the category guess is right.
- A wrong guess saves the amount digits only, and adds a suggestion to the screen that a plain
  manual capture did not have.
- No notification saves nothing at all.

So the automation buys the amount and the merchant, never the category. The category stays a
real decision, because knowing a merchant is not knowing what the purchase was: a Tokopedia
notification could be Belanja, Transport or anything else. The shipped code guesses the first
expense category and the first wallet, which is arbitrary rather than useful. Making the guess
good means learning a merchant-to-category and merchant-to-wallet map from the user's own
history, and that is a design item, not a built one. The capture sheet already ranks categories
by hour and remembers the last wallet used per category, so the machinery exists, it is just
not wired to the parser.

**Wrong guess.** The guess is never saved invisibly. Accepting is a deliberate tap, and an
accepted auto-guess keeps a marker on its ledger row naming the app it came from. Tapping that
row offers correct and delete, and the delete is the same undoable soft delete the ledger
already uses. `[04]`

**Two notifications for one payment.** One payment often posts twice, from the paying app and
from the receiving bank. `PaymentListenerService` drops a second parse with the same amount
inside a three-minute window, which covers that shape. Two limits are open: a genuine second
payment of the same amount within three minutes is merged and lost, and a pair of notifications
for one payment that report different amounts both survive and produce two entries. The guard
compares amounts only, never the merchant or the app, so it cannot tell those cases apart.

**States.** Empty: no pending suggestion renders nothing, not an empty inbox. Loading: none,
all of it is on-device. Unconfirmed suggestion: a distinct row treatment plus the parsed app
label, so the user can see this came from a wallet app and not from their own typing. Error
parsing: an unparseable notification is silently ignored rather than shown as a broken
suggestion. `[07]`

**Would it be built.** The re-entry condition is the one already recorded: the
notification-listener policy question answered, and manual capture measurably the reason users
churn. `[01]`, `[03]`, `[06]` If the policy answer is no, the alternative is the SNAP open API
and the aggregators that implement it, which carry cost, compliance and the breakage the
benchmark reviews describe. `[04]`, `[05, section 15]`

**Open questions inside this design.**

- The static-versus-dynamic QRIS split is stated here from the shape of merchant-presented
  QRIS rather than from a specification read in this repo, so it should be checked against Bank
  Indonesia's QRIS merchant-presented specification before it is treated as settled.
- `payment_auto_save_repository.dart` inserts a transaction for every parsed payment with no
  confirmation, which is what `PaymentParser.kt` and `PaymentListenerService.kt` say does not
  happen. The design in this section follows the Kotlin comments; the repository contradicts
  them and is an implementation gap to close, not a behaviour to trust.
- Whether notification listening covers QRIS spend reliably on the devices this audience uses,
  and whether the two-notification dedup holds across apps whose wording changes without
  notice, are both unverified from the outside. `[06]`
