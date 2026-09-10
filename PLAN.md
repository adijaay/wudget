# wudget: build plan

A personal expense and income tracker for Indonesia. Flutter, both stores, local-first,
manual capture done faster than anyone else in the category, and a review surface that
interprets instead of just plotting.

Written 2026-09-11 from the research in [research/](research/README.md). Every design
decision below cites the file that justifies it, so anything can be re-argued later against
the same evidence.

## Locked decisions

| Decision | Choice | Why |
|---|---|---|
| Platform | Flutter, Android and iOS from one codebase | Android carries Indonesia; Ollo proves a solo developer can ship both |
| v1 audience | Indonesia-first, solo user | Fastest path to proving retention |
| Sharing | v2, on a data model built for it from day one | Biggest gap in the competitive set, too big for v1 |
| Direction | Warm local personality, ENERGY 2 / RHYTHM 2 / MOTION 2 | See [DESIGN.md](DESIGN.md) |
| Bank sync | Not in v1, possibly never | None of the seven researched apps have it, and it is the top source of one-star reviews in the benchmarks |
| Account required | No | Local-first, no signup, until sharing arrives in v2 |

## The three bets

**1. Capture is the product.** In a manual tracker, everything else is downstream of whether
logging a warung lunch takes two seconds or fifteen. Ollo already has the best capture screen
in the market and it is still beatable ([07-ui-audit.md](research/07-ui-audit.md)). wudget
wins here or it does not win.

**2. Budget feedback gets reframed, not copied.** The strongest available evidence says a
live "left to spend" number increases spending late in the period, and that budgets in a
controlled field experiment produced no spending reduction at all
([05, section 11](research/05-behavioral-research.md)). wudget leads with pace and forecast,
and puts the remaining balance one tap away instead of on the hero. This is the one place
where the plan deliberately contradicts every competitor.

**3. Local rails are first-class.** QRIS, e-wallets, arisan, split bills, money owed to you.
Ollo and MELD model these and the Western apps do not
([02-feature-matrix.md](research/02-feature-matrix.md)). That is the moat that is hard to
copy from outside Indonesia.

## Roadmap

Phases are ordered by what de-risks the product soonest, not by what is easiest.

### Phase 0: foundation (before any screen)

Money as integers, the postings ledger, the formatter, migrations, and backup and restore.
These four are the things the review record shows incumbents got wrong and could not fix
later ([04-user-reviews.md](research/04-user-reviews.md)). Doing them first is cheaper than
retrofitting them.

Exit criteria: property test proving every transaction's postings sum to zero; one money
formatter with golden tests; a migration that can roll forward and back; export and import
round-trip on a 5,000 transaction fixture.

### Phase 1: capture (the alpha)

The one-sheet entry screen, wallets, categories, the date-grouped list, and the home widget.
No budgets. No charts beyond a daily total.

Exit criteria: a repeat expense logged in three taps plus the amount, measured; median
time-to-save under three seconds on a mid-range Android device; the app usable with no
account and no network.

### Phase 2: understanding (the beta)

Period model with payday alignment, pace and forecast, category ranked list, the interpreted
sentence, recurring items and bills with specific reminders, and the irregular expense
bucket. Budgets appear here, and only after the user has two weeks of real data.

Exit criteria: budget proposal generated from the user's own history rather than a blank
field; every insight surface carries one sentence a human would say out loud.

### Phase 3: retention (v1.0 launch)

Period close ritual, goals with visible milestones, surplus sweep, CSV import from Money
Manager and Ollo, and the full state matrix (empty, loading, error) reviewed screen by
screen.

Exit criteria: the antislop Delivery Gate passes with evidence; day-30 retention instrumented;
import tested against real exports from two competitors.

### Phase 4: household (v2)

Sync, household code plus owner approval, per-item privacy, activity notifications, and a
clean removal path. The data model from Phase 0 already carries the columns for this.

Exit criteria: two devices editing offline then converging; a member removed with their
private items intact and their shared items retained.

### Deliberately deferred

Bank aggregation. Investment and net worth beyond simple account balances. A chat assistant.
A community feed. Gamified levels. An education tab. Web and desktop. WhatsApp and Telegram
capture. Small business payables and receivables. Each of these has a note in
[plan/01-features.md](plan/01-features.md) explaining what would have to be true to pull it
forward.

## The detail

| File | Contents |
|---|---|
| [plan/01-features.md](plan/01-features.md) | Feature scope per phase, with the research citation for each, and the non-goals with their re-entry conditions |
| [plan/02-flows.md](plan/02-flows.md) | Screen-by-screen flows including the empty, loading and error states |
| [plan/03-architecture.md](plan/03-architecture.md) | Flutter stack, schema, money handling, recurrence, FX, sync design, testing, measurement |
| [plan/04-ux-design.md](plan/04-ux-design.md) | Design system, capture screen specification, chart rules, number formatting, accessibility, motion |
| [plan/05-sprints.md](plan/05-sprints.md) | 21 one-week solo sprints to v1.0, with point estimates, decision deadlines, cut list and weekly rhythm |
| [DESIGN.md](DESIGN.md) | Visual direction and the decisions still needing owner sign-off |

## Open decisions blocking work

Four things need the owner, and three of them block Phase 1 rather than Phase 0, so work can
start now.

1. **Accent colour and typeface** ([DESIGN.md](DESIGN.md)). Blocks Phase 1 polish, not Phase
   1 structure. The accent has to sit next to GoPay, OVO, DANA, ShopeePay and bank brand
   colours without clashing.
2. **Identity motif**, the envelope candidate. Blocks the wallet card and period-close
   designs.
3. **Logo.** Blocks store submission only. Wordmark in the display face until then.
4. **Pricing model.** Blocks nothing until Phase 3, but the research is unambiguous on one
   point: never gate transaction history, and never move existing free users behind a
   paywall ([04-user-reviews.md](research/04-user-reviews.md)).

## Risks worth naming now

**The pace-instead-of-remaining bet could be wrong for this audience.** The evidence behind
it is a working paper, not settled science. Mitigation: build both framings behind a flag and
measure, rather than committing on faith. Recorded as an open question in
[06-implications.md](research/06-implications.md).

**Capture speed on low-end Android.** The whole product rests on it, and Flutter's startup
cost on cheap devices is real. Mitigation: measure on a mid-range device from Phase 1, treat
a regression as a release blocker, and keep the widget and quick-add paths native where they
have to be.

**Manual entry fatigue is the category's structural problem.** Every competitor's reviews say
so. wudget's answer is speed plus templates plus the widget, not automation. If retention
still collapses at day 30, the QRIS and notification capture spike moves from deferred to
urgent.

**Scope creep toward accounting.** Ollo and MELD both carry a wide surface of secondary
objects (wishlist, reimbursements, payables). They are genuinely useful and they are how a
tracker turns into a bookkeeping app nobody finishes. Each one has to earn a place against
the capture and review path, not beside it.
