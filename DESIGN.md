# DESIGN.md

Style direction for wudget. This file is the source of design direction; `antislop.md` is the
filter applied on top of it. Where a decision is still the owner's to make it is marked
`[CONFIRM]` rather than filled in with an invented answer.

## Direction, as chosen by the owner

**Warm local personality.** Indonesian voice in the copy, friendly without being childish,
one confident accent colour plus a real identity motif. The reference register is MELD's
Indonesian copy without its fabricated statistics.

**Dial: ENERGY 2 / RHYTHM 2 / MOTION 2.**

- ENERGY 2, balanced. The app says hello and then gets out of the way. Not GOV.UK plain, not
  an agency portfolio.
- RHYTHM 2, consistent with a few deliberate breaks. Most screens share one composition;
  the capture sheet and the period-close screen are allowed to look different because they
  are different moments.
- MOTION 2, transitions and reveals that carry meaning. No endless loops, no floating
  decoration.

## Design Read

Reading this as: a personal money tracker for Indonesian users on Android and iOS, in a warm
local visual language, dial ENERGY 2 / RHYTHM 2 / MOTION 2.

## Identity

**Product name.** wudget.

**Logo.** `[CONFIRM]` Not designed. Until the owner supplies or commissions one, ship the
wordmark set in the display typeface. Do not generate a logo.

**Identity motif.** `[CONFIRM]` Candidate: the *amplop*, the paper envelope. It is the
correct metaphor for the wallet and budget model, it is culturally loaded in Indonesia
(THR, arisan, kondangan), and it gives one repeatable shape for wallet cards, budget
containers and the period-close screen. Needs the owner's decision before it is built,
because a motif applied half-heartedly is worse than none.

## Colour

Roles first, values second. Values are proposals pending `[CONFIRM]`.

| Role | Job | Rule |
|---|---|---|
| Surface | Page and card grounds | Light-first, with a real dark mode. Both must fully work |
| Ink | Text, three levels | Primary, secondary, and disabled. All at or above 4.5:1 on their surface |
| Accent | One brand colour | Used for the active state, the primary action, and nothing else |
| Positive | Income, goal progress | Never the only signal, always paired with a sign or icon |
| Negative | Expense, over budget | Never the only signal, always paired with a sign or icon |
| Category hues | Encoding data, not brand | A fixed set of 8, assigned per category, reused nowhere else |

Hard limits carried from the filter and the UI audit: 2 to 3 core colours plus one accent
(R-29); the accent appears at the key moment only, never on every element; hue alone never
carries meaning; and a stacked bar never exceeds five segments.

`[CONFIRM]` No hex values are set. The accent needs to survive being placed next to
Indonesian bank and e-wallet brand colours (GoPay blue, OVO purple, DANA blue, ShopeePay
orange, BCA blue, Mandiri gold) without clashing, because those logos will appear on wallet
cards. That constraint should drive the choice.

## Typography

`[CONFIRM]` Not fixed. Two requirements and one candidate with a real reason.

Requirements. The face must carry Indonesian text comfortably, which means good diacritic
handling and a wide enough set for the language. And amounts must be set in **tabular
figures** so digits align down a ledger column, either from the display face itself or from a
second face used only for amounts.

Candidate with a reason: Plus Jakarta Sans was commissioned for Jakarta's city identity, so
choosing it is a local brand argument rather than a default pick. That reason is the point;
if the owner prefers another face, the replacement needs its own one-line reason (R-06).

Do not use large monospace headings or uppercase labels with wide tracking.

## Copy voice

Indonesian body copy in the register the owner chose: casual, direct, the way a friend
explains money. English only where it is genuinely the word people use (budget, cashflow,
e-wallet). Section headings match the body language rather than code-switching into formal
English.

Never in the copy: fabricated user counts, invented savings totals, testimonials from people
who do not exist, or a comparison table against a competitor (R-17, R-18, R-36, R-38). The
research file on MELD's landing page records exactly what that looks like when it goes wrong.

No em dashes (R-02). Specific CTAs, so "Catat pengeluaran" rather than "Get Started" (R-15).

## What this direction rules out

Dark-only. One accent applied to every element. Gauges for values that can exceed 100 per
cent. A second pie chart where a ranked list answers faster. Gamified levels that reward
logging. An education tab. A community feed in v1.
