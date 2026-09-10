# Feature matrix and taxonomy

## The seven named apps, side by side

Y means shipped, N means absent, P means partial or paywalled, ? means not verifiable from
the store listing and marketing site. Dastlycal is omitted because it could not be found.

| Capability | Richual | Ollo | Expensa | SyncSpend | Money Manager | MELD |
|---|---|---|---|---|---|---|
| Manual entry | Y | Y | Y | Y | Y | Y |
| Income tracked | Y | Y | Y | N | Y | Y |
| Transfers between accounts | Y | Y | Y | N | Y | Y |
| Multiple accounts or wallets | Y | Y | Y | N | Y | Y |
| Typed accounts (cash, card, e-wallet) | Y | Y | Y | N | Y | Y |
| Credit card payment-date model | P | P | ? | N | Y | ? |
| Subcategories | ? | Y | Y | N | Y | ? |
| Category budgets | Y | Y | P | N | Y | Y |
| Budget rollover | ? | ? | Y | N | ? | ? |
| Custom period start (payday) | ? | ? | Y | N | Y | ? |
| Goals or savings targets | Y | Y | ? | N | N | Y |
| Recurring transactions | Y | Y | Y | N | Y | Y |
| Bill reminders | ? | Y | ? | N | P | Y |
| Debt tracking | Y | Y | ? | N | P | Y |
| Money owed to you | N | Y | N | N | N | Y |
| Wishlist of intended purchases | N | Y | N | N | N | N |
| Interest earnings tracking | Y | N | N | N | N | N |
| Subscription tracking | Y | Y | Y | N | P | Y |
| Bank or e-wallet sync | N | N | N | N | N | N |
| Card tap auto-capture | N | N | Y | Y | N | N |
| Receipt scan | N | Y | P | N | N | Y |
| Voice capture | N | Y | N | N | N | Y |
| Chat or messaging capture | N | Y | N | N | N | Y (WhatsApp) |
| AI categorisation | N | Y | P | N | N | Y |
| AI assistant or chat over data | N | Y | N | N | N | Y |
| Multi-currency | Y | Y | Y | N | Y | ? |
| Per-transaction historical FX rate | ? | N | Y | N | N | ? |
| Shared ledger with another person | N | N | P | N | N | Y |
| Notification on partner activity | N | N | N | N | N | Y |
| Community or social feed | N | N | N | N | N | Y |
| Gamification (levels, streaks) | N | Y | N | N | N | N |
| Offline first | Y | Y | Y | Y | Y | Weak (TWA) |
| Cloud sync | Y (iCloud) | P | Y (iCloud) | Y (iCloud) | P | Y |
| Export (CSV or PDF) | ? | P | Y | ? | Y | ? |
| Desktop or web access | N | N | N | N | Y (Wi-Fi viewer) | Y |
| Home screen widget | ? | Requested | ? | Y | Y | ? |
| Spending map or geolocation | Y | N | N | N | N | N |
| Forecast or pace projection | Y (interest) | Y | Y | N | N | ? |
| Net worth | Y | Y | Y | N | Y | ? |
| Audit trail | N | N | N | N | N | Y |

## What this says

Nobody in the named set connects to a bank. Every one of the seven is manual-first, and
they compete on how fast and how pleasant the manual path is. That is a real strategic
signal: for a solo developer, aggregation is expensive, breaks constantly (see the review
themes), and in Indonesia the aggregation layer is a separate build entirely.

The two automation strategies that a small team can actually ship are card tap-to-pay via
platform Shortcuts (Expensa, SyncSpend) and conversational capture: voice, receipt photo,
chat (Ollo, MELD). Neither needs a banking partner. Neither covers everything: Shortcuts
miss cash and non-Wallet payments, and voice needs the user to remember to speak.

Sharing is the largest capability gap in the set. Only MELD really has it, and it is
Indonesian, which suggests household and group money is under-served in this cohort even
though the behavioural literature says shared money is where the leverage is
(see [05-behavioral-research.md](05-behavioral-research.md)).

## Feature taxonomy

**Table stakes.** Ship these or the app is not competitive: manual entry with income,
expense and transfer; multiple typed accounts; two levels of category; category budgets on
a period the user can define; recurring items; a date-grouped transaction list with running
totals; a category breakdown; offline operation; export; and a working backup and restore.
The last one is not glamorous and it is where incumbents lose their angriest users.

**Retention machinery.** These are what make someone open the app on day 30: fast capture
(one screen, calculator numpad, recent and frequent items surfaced), a widget or a Shortcut
so capture starts outside the app, a review surface that says something the user did not
already know, a reminder tied to a specific expected event rather than a generic nudge, and
period boundaries that line up with the user's payday.

**Differentiators, roughly in order of how hard they are to copy.** A shared ledger with
live notification of the other person's entries. Conversational capture in the user's own
language and idiom. A pace or forecast surface that interprets rather than just plots.
Local payment rails as first-class objects, meaning e-wallets, QRIS, arisan, split bills.
Per-transaction historical FX for people who live across currencies. Anything social.

**Traps.** Features that look good in a screenshot and cost more than they return: a
sixth chart nobody reads, an AI assistant that answers questions the user was not asking, a
bento dashboard of tiles that each need their own explanation, and gamification that rewards
logging rather than the behaviour the user actually wants to change. On that last one, note
that a level badge rewards data entry, and data entry is a means, not the goal.

## Pricing patterns observed

| App | Model | Note |
|---|---|---|
| Richual | USD 2.99 up front | No ads, no subscription |
| Ollo | Free with Premium | Sync, AI limits, themes, unlimited objects |
| Expensa | Free with Premium | Category budgets are premium |
| SyncSpend | Was free, became paid | Free tier reportedly retains one month of history |
| Money Manager | Free with ads, paid ad-free, sync subscription | USD 2.49 a month or 19.99 a year for sync |
| MELD | Free with PRO | IDR 100,000 a year per a creator post |
| Monarch | Subscription | Around USD 15 a month per reviews |

Two lessons from the reviews rather than the price sheets. First, gating history behind the
paywall reads as data loss and produces the harshest reviews in the sample. Second, moving
an existing free user behind a paywall costs more goodwill than launching paid, and
reviewers name it directly as a switch they did not agree to.
