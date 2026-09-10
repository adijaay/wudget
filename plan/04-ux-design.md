# UX and design system

Direction and dials come from [DESIGN.md](../DESIGN.md): warm local personality,
ENERGY 2 / RHYTHM 2 / MOTION 2. This file turns that into rules a build can follow, and
records the reason for each one so it can be argued with later.

Anything the owner still has to decide is marked `[CONFIRM]` rather than filled in.

---

## Tokens

Defined once in `lib/design/`, and no feature declares its own.

**Colour roles.** Surface, ink at three levels, accent, positive, negative, and eight
category hues. Values `[CONFIRM]`, with the constraint from
[DESIGN.md](../DESIGN.md): the accent has to sit beside GoPay, OVO, DANA, ShopeePay and bank
brand colours on wallet cards without clashing.

Rules that hold whatever the values turn out to be:

- Light-first, with a dark theme that fully works. Both are exercised in golden tests, both
  ship, and neither is an afterthought.
- The accent marks the active state and the primary action, and nothing else. One deliberate
  accent, not an accent everywhere.
- Category hues encode data. They never appear as decoration, and the same hue means the same
  category everywhere in the app.
- Hue never carries meaning alone. Income and expense also carry a sign, over-budget also
  carries an icon.
- All text meets 4.5:1, large text 3:1, asserted in test rather than eyeballed.

**Type scale.** Five sizes, one display face, tabular figures for every amount. `[CONFIRM]`
on the face, with the reasoning and the Plus Jakarta Sans candidate in
[DESIGN.md](../DESIGN.md).

**Spacing.** A 4pt base with a six-step scale. Whitespace separates sections and sets the
rhythm; it is not leftover space. Section padding varies deliberately between the ledger
(tight, it is a list) and the period-close screen (open, it is a moment).

**Radius.** Three values: control, card, sheet. Not one pill radius on everything. Radius
variation carries hierarchy.

**Elevation.** Two levels. The FAB and the capture sheet lift. Nothing else does. No shadow
on every card.

---

## The capture sheet, specified

The one screen that decides whether the product works. Built from Ollo's layout with the four
changes noted in [01-features.md](01-features.md).

```
┌───────────────────────────────────────────┐
│  [Pengeluaran] Pemasukan  Transfer  [cam] │   segmented, receipt camera at right
├───────────────────────────────────────────┤
│  Sering: [Makan siang] [Grab] [Kopi] ...  │   up to 5, from recent frequency
├───────────────────────────────────────────┤
│  ⬤ Makan  ○ Transport  ○ Belanja  ...     │   category row, horizontal scroll
│  [Sarapan] ⬤Makan siang [Makan malam]     │   subcategory chips, filtered
├───────────────────────────────────────────┤
│                    Rp 15.000              │   amount, largest type on screen
├───────────────────────────────────────────┤
│  + Catatan                    [GoPay  ▾]  │   note collapsed, wallet defaulted
├───────────────────────────────────────────┤
│   1     2     3     ⌫                     │
│   4     5     6    +−×                    │   calculator toggle
│   7     8     9   11 Sep                  │   in-sheet date and time
│   .     0    000     ✓                    │   000 for rupiah, save
└───────────────────────────────────────────┘
```

Behaviour, precisely:

- The sheet opens with the amount field focused and the numpad up. No tap needed to start
  typing.
- A template tap fills type, category, subcategory, wallet and the last amount, leaving the
  amount selected so it can be overtyped. That is the three-tap path.
- The wallet defaults to the last wallet used with the selected category, not to a global
  default. Changing category may change the wallet, and doing so is visible.
- Subcategory chips are filtered by the selected category. This is the single most valuable
  detail borrowed from Ollo: it turns the slowest step into one tap on a short row.
- The date button shows the current value rather than a generic icon, so backdating never
  leaves the sheet.
- `000` is present whenever the active currency has no minor units.
- Save dismisses, returns the user where they were, and offers undo for a few seconds. No
  confirmation dialog, no success screen.
- Every route reachable from the sheet has a visible back affordance. Ollo's reviewers report
  a dead end here, and it is the cheapest possible bug to avoid.

**Accessibility on this screen specifically.** Every numpad key and chip has a semantics
label. The amount field announces the running value. Minimum target 48dp on Android and 44pt
on iOS, including the chips, which are the element most likely to end up too small. The layout
holds at 200 per cent text scale, with the numpad keeping its grid and the chip rows
scrolling rather than wrapping into the numpad.

---

## Chart rules

Written as rules because [research/07-ui-audit.md](../research/07-ui-audit.md) found the same
few failures repeatedly.

1. **No gauge for a value that can exceed its scale.** Richual's Budgets screen shows 123 per
   cent on a bounded arc with nowhere to point. Over-budget renders as a bar that overshoots
   into an over-region with the overshoot labelled.
2. **A stacked bar carries at most five segments**, with the rest grouped as "Lainnya". Ten
   segments in 300px encodes nothing.
3. **One precision per screen.** If the heading says `Rp 7.691.700`, the tiles below it do not
   say `Rp 8jt`. Round everywhere or nowhere, per screen.
4. **A ranked list beats a second pie.** One category breakdown per screen, and the ranking
   carries amount, share and transaction count.
5. **Forecast is always visually distinct and labelled.** Solid to today, dashed beyond, with
   an explicit legend. A projection that looks like a fact is a lie.
6. **Every insight carries one sentence.** The sentence states the conclusion the way a person
   would say it. If no honest sentence can be written, the chart does not earn its place.
7. **Colour is never the only encoding.** Also a sign, an icon, or a label.
8. **A number that cannot be computed renders blank with a reason**, never as zero.
9. **Axes are labelled with units.** A bar chart of rupiah says so.
10. **No chart animates on every render.** Motion on first appearance only.

Charts allowed in v1: the pace ring, the actual-against-forecast line with a dashed budget
target, the category ranked list, the daily bar for a week, and the calendar activity heatmap.
Nothing else without a written reason.

---

## Number formatting

One rule, one service, tested. This is a design rule as much as an engineering one because
three of the six audited apps break it on screen.

- `Rp` then a non-breaking space then the amount, thousands separated with `.`, no decimals.
- Sign is explicit on every transaction row. Expense negative, income positive.
- Tabular figures so ledger columns align.
- Abbreviation (`jt`, `rb`) is allowed only in chart axes and only when the full value appears
  elsewhere on screen.
- A total that mixes currencies is labelled as converted, with the rate reachable. If it
  cannot be labelled, show each currency separately rather than one wrong number.

---

## States

Every data surface ships three states, and they say the cause and the next action. "Tidak ada
data" on its own is not a state.

| Surface | Empty | Loading | Error |
|---|---|---|---|
| Catat, new user | What the first entry looks like, one action to add it | None, local | Corrupt database routes to restore |
| Catat, filtered | Which filter excludes everything, one action to clear | Skeleton rows only, headers from cache | n/a |
| Pantau, first 14 days | What it is collecting, and when the proposal arrives | Precomputed, so none | Uncomputable figures blank with a reason |
| Pantau, empty period | Which period is empty, how to reach one that is not | | |
| Kantong | Offer to add a wallet | | Converted total falls back to per-currency lines |
| Recurring | What a recurring item is for, one example, one action | | Failed generation flagged in the row with the reason |
| Goals | One example in local terms, one action | | Behind schedule shows the gap and one suggestion |
| Import | n/a | Progress with a row count | Row number and reason, valid rows still importable |
| Sync (v2) | n/a | Non-blocking indicator | Local ledger stays authoritative and writable |

First run, filtered-to-nothing, and permission denied are three different screens, not one
shared empty state.

---

## Motion

MOTION 2 means transitions that carry meaning, and nothing that loops.

Allowed: the capture sheet sliding up from the FAB with a shared axis; the undo affordance
appearing and fading; a chart drawing once on first appearance; the period-close screen
revealing its sections in sequence, which is the one place in the app allowed to feel like a
moment.

Not allowed: anything that pulses or floats without a trigger; a spinner where a skeleton
belongs; animation on every list render; a save animation that delays the dismissal.

Every animation respects the platform reduce-motion setting and falls back to a cut.

---

## Copy rules

Indonesian, in the register set in [DESIGN.md](../DESIGN.md). Specific rules:

- Actions name the action. "Catat pengeluaran", not "Mulai".
- Amounts in copy use the same formatter as the UI.
- Reminders name the specific expense and the shortfall, because
  [research/05-behavioral-research.md](../research/05-behavioral-research.md) section 5 shows
  specific beats generic.
- The period-close and lapsed-return copy does not scold. A user who stopped logging is being
  invited back, not audited.
- No fabricated numbers of any kind: no user counts, no savings totals, no ratings, no
  testimonials. The MELD landing page in
  [research/07-ui-audit.md](../research/07-ui-audit.md) is the recorded example of what that
  looks like when it goes wrong.
- No em dashes.

---

## What wudget deliberately does not copy

Each of these is a real pattern from a real competitor, rejected with a reason.

| Pattern | Seen in | Why not |
|---|---|---|
| "Left to spend" as the hero number | Nearly all of them | The evidence says it raises end-of-period spending |
| Budget question during onboarding | Ollo, Richual, Expensa | It extracts a guess the user cannot yet make |
| Levels and streaks | Ollo | Rewards logging, and logging is the means |
| Dark-only | Richual, Expensa | The app is used in daylight, one-handed, in a shop |
| One brand colour on every element | Richual | Removes the focal point |
| Unlabelled icon navigation | Ollo | Two of four glyphs are guesses |
| Gauge past 100 per cent | Richual | A bounded scale cannot show an unbounded value |
| Ten-segment stacked bar | Richual | Encodes nothing at that width |
| Ads in the free tier | Money Manager | Its own reviews report the banner covering tap targets |
| History behind the paywall | SyncSpend | Reads as data loss, produces the harshest reviews in the sample |
| Community feed | MELD | No evidence it retains anyone |
| Education tab | Common in the category | 0.1 per cent of variance in behaviour |

---

## Design gate before any release

Run the antislop Delivery Gate, and additionally assert these, with evidence recorded per
item:

- Both themes exercised in golden tests, including the capture sheet and Pantau.
- Contrast asserted on every token pair actually used.
- 200 per cent text scale on the capture sheet, the ledger row, and the pace card.
- Keyboard and screen reader traversal of the capture sheet, with amounts announced.
- Every empty, loading and error state in the table above implemented and screenshotted.
- The formatter golden tests pass for IDR, USD, JPY, zero, negative and large values.
- The performance budget in [03-architecture.md](03-architecture.md) measured on a real
  mid-range Android device.
- No fabricated content anywhere in the app or the store listing.
