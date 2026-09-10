# UI audit

A screen-level read of the interfaces, separate from [03-flows-and-ux.md](03-flows-and-ux.md),
which covers flows. This file is about what the pixels do: navigation, information
hierarchy, colour, typography, chart vocabulary, number formatting, and the specific craft
problems visible in each app.

## Evidence and its limits

Screens were read from App Store screenshots at 626px width (Richual 6, Ollo 6, Expensa 6,
Money Manager 5, SyncSpend 5) and from MELD's live web app landing page, opened in a browser
on 2026-09-11. Store screenshots are curated marketing assets, so they show the intended
best case. Empty, loading and error states are absent from all of them, which is expected
and also where the review evidence says these apps break. No app was installed, so nothing
here is a latency or tap-count measurement.

---

## Per-app read

### Richual: dark maximalist, insight-heavy

**Navigation.** Four-item bottom tab bar (Wallet, Budgets, Goals, Insights) plus a detached
circular fifth button outside the bar for transaction history, and a persistent "Log
Transaction" bar sitting above the tab bar on every screen with three directional glyphs
(down for expense, sideways for transfer, up for income). Two floating layers above the
content plus a tab bar is a lot of permanent chrome, roughly a quarter of the vertical space
on the Budgets screen, but it does mean capture is never more than one tap away.

**Visual language.** Dark ground, one saturated green applied to the wordmark, nav icons,
active tab, wallet cards, chart fills, accent text, buttons and the capture bar. A sparkle
glyph sits in the wordmark. Wallet cards are a stacked overlapping deck in green, cyan, navy
and amber, which reads well as a physical wallet metaphor and is the strongest single idea in
the interface.

**Chart vocabulary.** Balance trend area chart with 1M/3M/1Y segmented control. Category
donut with a legend showing six categories and percentages. A geographic spending map from
geotagged transactions. A semicircular gauge on Budgets.

**Craft problems, specifically.**

- The Budgets gauge reads 123% with a green-to-red arc. A gauge implies a bounded scale, so
  a value past the end of the arc has nowhere to point. The three tiles below it round to
  $6K, $8K and -$1K while the line above states $7,691.7 of $6,270, so the same screen
  carries two precisions of the same fact.
- The Categories bar packs roughly ten colour segments into one 300px-wide stacked bar. At
  that width the small segments are a few pixels each and carry no readable information.
  A stacked bar stops working past about four or five segments.
- The single green accent is applied to almost every element, which collapses hierarchy.
  When everything is the accent, nothing is the focal point (antislop R-01, R-29, and the
  one-deliberate-accent lever in the core skill).
- The green-to-red gauge gradient carries meaning by hue alone, which fails for red-green
  colour blindness unless the number or an icon carries the same signal.
- Dark only in every screenshot, with no light variant shown.

**What works.** The wallet deck. The persistent directional capture bar. The insight surfaces
are genuinely differentiated: interest forecast segmented Today/Month/Year/Custom, and the
spending map, which no other app here has.

### Ollo: dense but disciplined, and the best capture screen in the set

**Navigation.** Floating pill bottom nav with four icon-only items (home, statistics,
wallet, profile) and a separate circular plus button to its right. Home is organised
top-down as greeting and level badge, period selector, balance card, scrolling feature menu,
budget bar, wallets, then transactions.

**Theme.** Ships both. The home and capture screens are dark; the Statistics screen is
light with white cards on a pale ground. Worth noting because it is the only app in the
named set with visible proof of two working themes.

**Capture screen, the reason to study this app.** One sheet, no navigation. Segmented
Expense/Income/Transfer at the top with a camera button for receipts. A horizontally
scrolling row of coloured category icons. Below it, a second row of subcategory chips
filtered by the selected category (Breakfast, Lunch, Dinner under Food & Drink), with the
active chip filled in the category colour. Amount with a currency dropdown, rendered large.
Title and note fields, and a wallet dropdown on the same row as the note. Then a custom
numpad: digits, backspace, a calculator toggle, a date and time button showing the current
value, a decimal point, a `000` key, and a confirm check.

Three details in that layout are worth copying. The subcategory chips turn category
selection, normally the slowest step, into one tap on a short filtered row. The `000` key is
correct localisation for rupiah rather than a novelty. And putting the date button inside the
numpad means backdating never leaves the sheet.

**Chart vocabulary.** A GitHub-style activity heatmap laid out as a month calendar with the
day number and the amount in each cell and a Less-to-More legend. Top Spenders as a ranked
list with two dropdowns (Category, Top 5) showing rank, name, transaction count and amount.
Notably restrained: a ranked list instead of a second pie.

**Craft problems.**

- Currency roll-up disagrees with the line items. A transaction list screenshot shows the
  day total as `-$1.55` while every row below it reads `-Rp5.000,00`, `-Rp10.000,00`,
  `-Rp12.000,00`. Two formatters, two rules, one screen. In a money app that is the kind of
  inconsistency that makes users stop trusting every other number.
- The heatmap cells carry two numbers each (date and amount) at roughly 40px square, which
  is past the point where either is comfortably readable.
- The level badge rewards logging rather than any financial outcome. See
  [05, section 13](05-behavioral-research.md).
- Reviewers report the income and expense screens reached from the home widget have no
  visible back button, which is a navigation dead end rather than a styling issue.
- Icon-only bottom nav with no labels. Four unlabelled glyphs where the second and third
  (statistics, wallet) are not self-evident.

### Expensa: the most sophisticated data presentation, and the loudest marketing

**Navigation.** Top bar rather than a tab bar: a space switcher pill on the left showing the
active space ("Personal"), and three circular icon buttons on the right. A single scrolling
dashboard below. Category detail pushes a screen with back, a calendar button and an
overflow.

**Visual language.** Dark ground with a per-category accent colour applied as a large filled
circle badge and as the chart stroke, so the Groceries screen is green throughout and the
Restaurants screen is amber. Tying the accent to the data rather than to the brand is the
cleanest colour system in the set, because the accent means something.

**Chart vocabulary, and this is where it leads.**

- Actual against forecast on the same axis: solid line to today, dashed continuation past
  it, with an explicit `Actual / Forecast` legend. Nobody else here forecasts.
- A dashed horizontal target line labelled with the budget amount, so budget and spend live
  on one chart instead of a bar and a number.
- A pace ring showing percent plus a written sentence interpreting it, for example that the
  user is well under pace and has built a cushion. That is the only place in this entire
  study where an app does the inference instead of handing the user a chart.
- A cashflow view with weekly bars and a derived sentence stating roughly how much per day
  is available for the remaining days of the period.
- Period comparison as a delta with an arrow against the previous period.
- A category detail card with the AI category suggestion shown explicitly, with Change
  category and Apply buttons, so the guess is visible and one tap to accept.

**Craft problems.**

- Number formatting is inconsistent with the currency symbol. Amounts render as `$651,59`,
  `$237,29`, `$1 563,41`, so a comma decimal separator and a space thousands separator with
  a dollar sign. That is European formatting on a US symbol, and `$1 563,41` is ambiguous at
  a glance.
- The daily-allowance sentence is exactly the remaining-balance framing the strongest
  available evidence warns about, since it converts the remainder into a licence to spend
  ([05, section 11](05-behavioral-research.md)). It is the best-executed version of a
  possibly counterproductive idea.
- Store screenshots use a full-bleed electric blue with a glow behind giant type and pill
  badges reading "No bank login", "iCloud sync", "150+ currencies", "No sign up". The app
  interface is restrained; the marketing frame is not, and the two do not look like the same
  product.
- Category budgets, the thing the pace ring and the target line exist to serve, are behind
  the paywall on the free tier.

### Money Manager: a spreadsheet that fits in a hand

**Navigation.** Bottom tab bar of four labelled items (a date tab, Stats, Accounts,
Settings), and inside the transaction view a second row of five tabs
(Daily, Calendar, Weekly, Monthly, Summary) with a header strip showing Income, Expenses and
Total for the period. Two levels of tabs is unfashionable and it is honest about what the app
is: a ledger with several views.

**Visual language.** Light ground, near-white cards, a red brand colour on the header and
the active tab, and the accounting convention held throughout: income in blue, expenses in
red, zero in grey. Dense typography, small type, tight rows. It looks like software rather
than like a lifestyle product, and its 19,171 US ratings at 4.82 say the audience is fine
with that.

**Chart vocabulary.** A pie chart with external labels on leader lines and percentages, plus
a ranked category list underneath where each row carries a coloured percentage badge and an
amount. The leader-line pie is dated and it does something the modern donut usually does not:
it labels every slice with both name and share, so the chart is readable without a legend
lookup.

**Craft problems.**

- Information density is at the limit. Row height, type size and the double tab row leave
  little tap tolerance, which matters for the one-handed in-a-shop use case.
- The free tier's ad banner reportedly grew to cover tappable areas, which is a layout
  failure rather than a monetisation one.
- A dark variant exists (one screenshot shows the same ledger inverted), but the two themes
  are presented as a feature rather than as a system, and the review record includes
  complaints about the app being overcomplicated as it grew.

### SyncSpend: monochrome minimalism, and capture that happens outside the app

**Navigation.** No tab bar at all. A space switcher pill on the top left, three circular
icon buttons on the top right (search, filter, settings), one scrolling list, and a black
circular plus button floating bottom right.

**Visual language.** Pure monochrome. Black type on white, grey secondary type, black bars,
white cards, and a black FAB. Zero colour, including in the chart. The rounded square
category icons carry glyph-only meaning. It is the most restrained interface in the study
and it is a real position rather than an absence of one.

**Chart vocabulary.** One weekly bar chart with a y-axis in units of 20 and day-of-week
labels, then a list grouped as "Latest" and then by day.

**The interesting screen is not in the app.** One screenshot shows the iOS Shortcuts prompt
on the lock screen asking for the amount, with a numeric keypad and Cancel and Done. Capture
happens in the operating system; the app is only where the data lands. That is the logical
end point of reducing capture friction, and it is also why the app can afford to have no tab
bar: there is almost nothing to navigate.

**Craft problems.**

- The FAB sits directly over the last list row in the screenshot, obscuring an amount. A
  floating button needs bottom padding on the scroll container equal to its own height.
- Colour carries no information anywhere, so category, direction (in or out) and severity all
  have to be read from text. That is good for contrast and bad for scanning.
- Expenses only, so there is no income and no net position. Reviewers ask for it repeatedly.

### MELD: a web app wearing an Android app, and a landing page that overclaims

The only one of the seven with no App Store presence, so this read is from the live site at
meld.my.id rather than from store screenshots. iOS is listed as coming soon.

**Product UI.** The hero is a video, not a static mockup, and it demonstrates a QRIS scan
flow with `SCAN QR` and `INBOX` tabs and a running total, which means the capture story
includes scanning the QR payment itself. The documented capture channels are the web app, a
WhatsApp bot, a Telegram bot, and the Play Store app. Themes offered are dark, light, a cute
theme, and custom.

**The onboarding flow is documented in plain language on the page**, and it is the clearest
household-invite model in this study. On signup the owner receives a household code, shares
it with a partner, the partner joins with the code, and the owner approves the join from a
dashboard notification. Transactions then update in real time for all members. The approval
step is the part most apps skip, and it is what stops a code leak from becoming a stranger
reading your ledger.

**Other UX facts stated on the page.** Financial health score with recommended next actions.
Goal trajectory, meaning an estimate of how long a goal will take at the current rate.
Subscription tracking with reminders and a calendar. Auto-input of salary and auto-debit of
debt. 21+ currencies with a per-household preferred currency. CSV export from settings.
Offline capture with sync when back online. Bank, digital bank and e-wallet logos on every
transaction. The stack is named openly as Supabase with Row Level Security.

**The landing page is a useful negative example.** It triggers most of the trust-copy
failures at once, and it is worth writing down because it is the pattern to avoid rather than
to copy:

- A "Trusted by 10,000+ users" badge in the hero and a four-tile stat bar reading 10,000+
  active users, 500,000+ transactions tracked, $2M+ savings achieved, 4.9 user rating, with
  no source, no date and no method for any of them. The Play listing does not corroborate the
  scale (antislop R-17, R-36).
- Four testimonials with initial-circle avatars, full names and job titles (Family of 4,
  Homemaker, Software Engineer, Small Business Owner), presented as real customers with
  nothing verifiable attached (R-18).
- A competitor comparison table where the "competitor" column is Excel, with emoji in every
  row label, and where several competitor cells actually concede the point (noting Excel can
  share, has dark themes, can do offline) which makes the table argue against itself.
- One testimonial uses the phrase game-changer, which is the buzzword register the copy skill
  flags.

**The tone finding, which is genuinely valuable.** The Indonesian copy is casual Jakarta
slang, not corporate Bahasa: it jokes that recording your finances no longer has to be
old-fashioned like using Excel, and the voice-capture example is buying a batagor for five
thousand rupiah. Feature descriptions use "boncos", "satset", "gas terus". English headings
sit directly on top of that (Features, Reviews, How It Works, FAQ), so the page code-switches
between formal English structure and informal Indonesian body copy. For the Indonesian market
that mixed register reads as a real person rather than a translated product, and it is a
sharper differentiator than any of the fabricated statistics above it.

---

## Cross-app comparison

| | Richual | Ollo | Expensa | Money Manager | SyncSpend | MELD |
|---|---|---|---|---|---|---|
| Nav model | 4 tabs + 2 floating layers | Floating pill, 4 icons + FAB | Top bar only | 4 tabs + 5 sub-tabs | Top bar + FAB | Web app, sidebar or dashboard |
| Tab labels | Yes | No, icons only | n/a | Yes | n/a | n/a |
| Theme | Dark only shown | Dark and light | Dark only shown | Light and dark | Light only shown | Dark, light, cute, custom |
| Accent logic | One brand green everywhere | Per-category colour, one active accent | Per-category colour drives the screen | Blue income, red expense, red brand | None, monochrome | Bank and wallet brand logos |
| Capture affordance | Persistent bar, 3 directions | FAB | FAB or Shortcut | Tab plus entry screen | FAB or lock-screen Shortcut | Voice, photo, QR, WhatsApp, Telegram, web |
| Primary chart | Area trend | Calendar heatmap | Actual vs forecast line | Leader-line pie | Weekly bars | Charts and reports, unseen |
| Interpreted insight | No | No | Yes, written sentence | No | No | Financial health score |
| Number formatting issue | Rounded and precise on one screen | Currency mismatch total vs rows | Comma decimals with `$` | Consistent | Consistent | Not assessed |

## The craft problems ranked by how much they cost

1. **Number formatting that contradicts itself** (Ollo's total against its rows, Richual's
   rounded tiles against its precise line, Expensa's comma decimals under a dollar sign).
   This is the worst class of bug in a finance interface, because the product's only real
   asset is that the user believes the numbers.
2. **Charts past their readable limit** (Richual's ten-segment stacked bar, Richual's 123%
   gauge, Ollo's two-value heatmap cells). Each of these is a visualisation used past the
   point where it encodes anything.
3. **Colour doing work alone** (Richual's green-to-red gauge, blue and red for income and
   expense with no icon or sign). Fails for colour-blind users, and both are one glyph away
   from being fine.
4. **Accent inflation** (Richual). One colour on every element removes the focal point.
5. **Chrome eating the canvas** (Richual's tab bar plus capture bar plus floating button).
6. **Floating buttons over content** (SyncSpend's FAB obscuring an amount).
7. **Unlabelled icon navigation** (Ollo).
8. **Density past comfortable tap size** (Money Manager).

## What is worth copying

- Ollo's single-sheet capture screen, especially filtered subcategory chips, the numpad
  calculator, the in-numpad date button, and a `000` key for rupiah.
- Expensa's per-category accent, so colour means data rather than brand.
- Expensa's actual-against-forecast line with a dashed target, and its written interpretation
  of the pace number.
- Expensa's visible AI suggestion with Apply and Change, which makes automation correctable
  in one tap.
- Richual's stacked wallet deck as a physical metaphor for account balances.
- Money Manager's leader-line pie labelling every slice, so the chart needs no legend lookup.
- Ollo's ranked Top Spenders list, which answers the same question a second pie chart would
  and answers it faster.
- MELD's household code plus owner approval invite flow.
- SyncSpend's lock-screen Shortcut capture, which moves entry out of the app entirely.
- MELD's register of Indonesian copy, minus the invented statistics.

## What the screenshots cannot tell us, and should be checked

No empty, loading or error state appears in any of the 28 screenshots reviewed, which is
where the review record says these apps actually fail: failed syncs, blank recurring items,
vanished history. None of the apps shows a light-mode variant of its dark hero screen except
Ollo. Contrast ratios cannot be verified from compressed screenshots, and several are
suspect: Richual's grey secondary text on dark green cards, and Money Manager's small grey
zero values. Tap target sizes are inferred from proportion, not measured. And no app shows
keyboard, VoiceOver or Dynamic Type behaviour, though Expensa's store copy claims Dynamic
Type and VoiceOver support.
