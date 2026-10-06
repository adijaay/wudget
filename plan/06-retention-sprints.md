# Retention round: sprint plan

Turns [research/08-retention-baseline.md](../research/08-retention-baseline.md) into work.
Screens are in [design/Retention.html](../design/Retention.html); screen numbers below match
the captions there.

Same unit as [05-sprints.md](05-sprints.md): 1 point is half a day, a solo sprint carries 8.
The global definition of done in that file applies to every ticket here, plus the additions
below.

**Total: 6 sprints, about six weeks.** Ordered so what moves retention most ships first:
measure, then capture speed, then home, then payday, then the moments that bring people
back, then a hardening pass.

| Milestone | After | What a user notices |
|---|---|---|
| M1 Fast capture | R1 | Logging a repeat expense takes under 3 seconds |
| M2 New home | R2 | Home answers "how much is okay today" and says one new thing |
| M3 Payday | R3 | A month's budget set in two taps, any day |
| M4 Come back | R5 | Recap, reminders, and a kind return after a gap; ready to ship |

---

## Decisions

Locked in this round (do not reopen without new evidence):

| Decision | Choice | Source |
|---|---|---|
| Payday | The 25th of every month, fixed, no weekend or holiday shift | Owner, 2026-10-07 |
| Period | 25th to 24th | Follows payday |
| Set now, default end | Before the 15th: the coming 24th. From the 15th on: the 24th after it | Owner, 2026-10-07 |
| Leftover at payday | Goes to Tabungan by default, editable | Baseline rule 5 |
| Total budget | The sum of the kantong. No separate total field | Baseline rule 5 |
| Habit display | Days logged this period, missed days shown hollow. No consecutive streak, no levels | Baseline rule 4 |
| Wallets in capture | Not shown. Entries go to a default wallet | Baseline section 2 |
| Income | Same sheet as expense, Pemasukan switch. Only payday opens the split | Baseline rules 1 and 5 |

Open, with the sprint each one blocks:

| Decision | Default if not answered | Needed by |
|---|---|---|
| Wallets: hide in settings, or remove | Hide | R1 |
| App opens on home or straight into capture | Home | R1 |
| Insight voice: neutral or a little teasing | Neutral, friendly | R2 |
| Strict streak shown anywhere | No | R5 |

## Definition of done, additions for this round

1. Every new screen has a design-review PNG in `app/test/design_review/`, light and dark.
2. Every new user action logs one event through `AnalyticsRepository`, so the metrics at
   the end can be computed.
3. Copy passes the antislop copywriting checklist: no em dashes, no guilt, specific buttons.
4. Every number shown on a new screen is traceable to a query with a test.

## What already exists and gets reused

| Need | Already in the app | Gap |
|---|---|---|
| Event log | `data/analytics_repository.dart` | Event names for capture timing |
| Feature flags | `data/feature_flags_repository.dart` | None |
| Period start day | `data/settings_repository.dart`, `domain/period.dart` | Default is not 25; no period that starts on an arbitrary day |
| Budget suggestion | `domain/budget_proposal.dart`, `features/budget/budget_screen.dart` | Not reachable from payday |
| Period close | `domain/period_close.dart`, `features/pantau/period_close_sheet.dart` | No image or share |
| Pace | `domain/pace.dart` | Not used for sorting |
| Insight source | `domain/pola.dart`, `domain/flow.dart` | No "one sentence per day" picker |
| Notifications | `data/notification_scheduler.dart`, `data/reminder_orchestrator.dart` | Only bill reminders |
| Home widget | `features/widget/home_widget_service.dart`, `capture_deeplink.dart` | Does not pre-fill |
| Haptics, sharing | None | Flutter `HapticFeedback` is built in; one share package, to be approved |

---

## Sprint R0: measure before changing

**Goal:** know today's numbers, so every later sprint proves it helped.

| ID | Ticket | Pts | Done when |
|---|---|---|---|
| R0.1 | Capture timing events: `app_open`, `capture_open`, `capture_save`, with source (nav, widget, chip) | 1 | Events appear in `AnalyticsRepository.all()` in a test |
| R0.2 | Time-to-save and days-logged readout on a debug screen in Saya, behind a flag | 2 | Shows the median of the last 20 saves and logged days this period |
| R0.3 | `loggedDays(period)` in `domain/`, counting days with at least one entry | 1 | Tests: empty period, every day, gaps, today not yet logged |
| R0.4 | Baseline run: 20 repeat captures on a mid-range Android device | 1 | Median written under Metrics |
| R0.5 | Answer the two open decisions R1 needs | 1 | Recorded in the Decisions table |
| R0.6 | Pick and approve the share package for R4 | 1 | Name and reason recorded here |
| R0.7 | Buffer | 1 | |

**Exit:** a real median time-to-save. Pixel 4, machine-speed: 1,525 ms (see Metrics).

## Sprint R1: capture under 3 seconds (screens 2, 3)

**Goal:** the repeat expense is the fastest thing in the app.

| ID | Ticket | Pts | Done when |
|---|---|---|---|
| R1.1 | Category chips ranked by hour of day and frequency over the last 90 days | 2 | Test: lunch-hour history puts Makan first at 12:00; a new user gets the default order |
| R1.2 | Remove the wallet picker from `capture_sheet.dart`; save to the default wallet | 1 | Old wallets still readable; widget test finds no wallet picker |
| R1.3 | Keypad open when the sheet opens; save button reads "Simpan Rp X ke Kategori" | 1 | Widget test on the label; no tap needed before typing |
| R1.4 | Note line under the amount, optional; Pengeluaran / Pemasukan switch at the top | 1 | Save works with an empty note; income on a normal day saves with "Simpan saja" |
| R1.5 | Save feedback: `HapticFeedback`, toast with the kantong's remaining amount, 5 second undo | 2 | Undo removes the entry and its postings; toast amount matches the kantong query |
| R1.6 | Widget and home chips open a pre-filled sheet (note, category, amount) | 1 | `capture_deeplink_test.dart` covers the pre-fill |

**Exit:** the R0.4 run, repeated, shows a median under 3 seconds. If not, fix before R2.

**Risk:** chip ranking feels random with little history. Mitigation: below 10 entries, use
the default order.

## Sprint R2: home leads with today (screens 1, 7)

**Goal:** home answers one question, and says one new thing a day.

| ID | Ticket | Pts | Done when |
|---|---|---|---|
| R2.1 | Jatah hari ini hero in `today_header.dart`: period remainder divided by days left, today included | 2 | Test with the mockup numbers: Rp 2.394.000 over 18 days is Rp 133.000 |
| R2.2 | Period remainder becomes a link under the hero, to Kantong | 1 | Tapping opens Kantong |
| R2.3 | Logged-days strip from R0.3: filled, hollow for missed, outlined for today, muted for future | 1 | Golden test light and dark; screen reader reads "11 dari 13 hari tercatat" |
| R2.4 | Daily insight picker: one sentence from Pola and Flow results, changes daily, empty when nothing is new | 2 | The same sentence never shows two days running; no sentence beats a stale one |
| R2.5 | First-run home: jatah card explains itself and links to Atur sekarang; one "Catat pengeluaran" task | 1 | Empty-state test with no entries and no budget |
| R2.6 | Loading and error states for jatah, strip and insight | 1 | Each block fails on its own without blanking home |

**Exit:** home tests cover empty, loading, error, and a day with no new insight.

**Risk:** the insight picker repeats itself within a week. Mitigation: store the last 7
sentences shown and skip them.

## Sprint R3: payday (screens 4a, 4b, 4c)

**Goal:** from payday to a working budget in two taps, and the same flow on any day.

| ID | Ticket | Pts | Done when |
|---|---|---|---|
| R3.1 | Default period start day 25 for new installs; existing users keep theirs | 1 | Migration test: existing setting untouched |
| R3.2 | Payday card on home from the 25th: last salary amount; Sudah masuk, Beda jumlah, Belum (asks again the next day) | 2 | Shows on the 25th, hides once confirmed; Belum hides it until tomorrow |
| R3.3 | Review screen: "Uang periode ini" is new money plus last period's leftover (all income minus all spending); kantong pre-filled from the last budget, or from `budget_proposal.dart` when there is none; leftover to Tabungan; rows read-only, tap to edit | 2 | Test with the mockup numbers: 7.500.000 plus 420.000 is 7.920.000, every rupiah placed |
| R3.4 | A period that starts on any day: one stored custom start, ending on the chosen 24th; the next 25th returns to the normal cycle | 2 | `period_test.dart`: set on 7 Oct ends 24 Oct; set on 20 Oct ends 24 Nov; 25 Nov starts a normal period |
| R3.5 | Atur sekarang sheet: money on hand, end-date chips with the 15th default, then R3.3 | 1 | Default chip test on the 14th and on the 15th |

**Exit:** payday card to saved budget in two taps, measured from events.

**Risk:** R3.4 touches `Period`, which every aggregate query uses. Mitigation: leave
`Period.containing` as it is for normal periods, check the one stored override first, and
keep the existing period tests running unchanged.

## Sprint R4: recap and Pantau (screens 5, 8)

**Goal:** the period ends with something worth keeping, and Pantau leads with a sentence.

| ID | Ticket | Pts | Done when |
|---|---|---|---|
| R4.1 | Recap card from `PeriodCloseSummary`: spent against plan, the best-held kantong, the one over, one sentence | 2 | Numbers match the summary; no comparison with anyone else |
| R4.2 | Recap rendered to an image and shared with the package approved in R0.6 | 2 | Image renders in light and dark; share opens the system sheet |
| R4.3 | Pantau opens with the pace sentence from `pace.dart` | 1 | Sentence only when a kantong is ahead of time; otherwise none |
| R4.4 | Kantong sorted by spent share minus time share; Tagihan, paid once a period, is left out of pace and listed last; over-pace marked by colour and number | 2 | Test: the mockup order Belanja, Hiburan, Makan, Transport, Tagihan |
| R4.5 | Pola and Aliran move under one "Lihat pola dan aliran" link | 1 | Existing Pantau view tests still pass |

**Exit:** a recap image from a real closed period, shared from a device.

## Sprint R5: come back, and harden (screen 6, rule 7)

**Goal:** a gap does not end the habit, reminders are few and specific, and everything new
holds up in every state.

| ID | Ticket | Pts | Done when |
|---|---|---|---|
| R5.1 | Comeback screen after 3 or more days without entries: Mulai dari hari ini, or Isi hari yang lewat | 1 | Shows once per gap; the count is kept, nothing reset |
| R5.2 | Backfill: one day at a time, skip allowed | 1 | Entries dated to the chosen day |
| R5.3 | Evening reminder at the user's usual logging hour, only on days with no entries | 2 | Usual hour from the last 30 days of saves; nothing sent on a logged day |
| R5.4 | Payday reminder on the 25th, same question as the card; weekly recap notification | 1 | Both can be turned off in Saya; nothing else on by default |
| R5.5 | States pass on every new surface: empty, loading, error, text at 200%, screen reader labels | 2 | `text_scale_test.dart` and `semantics_test.dart` extended |
| R5.6 | Design-review PNGs for all new screens, light and dark, compared with the mockup | 1 | PNGs committed; differences listed and accepted or fixed |

**Exit:** the antislop Delivery Gate passes with evidence for every new screen.

---

## Metrics

Measured from the event log, R0 against the end of R5. No targets until R0 gives a
baseline.

| Metric | R0 | After R5 |
|---|---|---|
| Median open-to-save, machine-speed taps, Pixel 4 (app cost, not human time) | 1,525 ms | 1,523 ms after R1 |
| Taps for a repeat expense | 4 plus digits (open, category, wallet, save) | 2 plus digits after R1, or 1 tap on a home chip then save |
| Median time-to-save, real user | `[REAL DATA]`, from capture_save events | |
| Share of days in a period with at least one entry | `[REAL DATA]` | |
| Share of gaps of 3 or more days followed by a return | `[REAL DATA]` | |
| Taps from payday card to saved budget | n/a | |

## Dependencies

- R2.3 needs R0.3.
- R2.5 links to Atur sekarang (R3.5). Until R3 ships, the link opens the existing budget
  screen.
- R3.3 reuses `budget_proposal.dart` unchanged.
- R4.2 needs the package chosen in R0.6.
- R5.3 needs the R0.1 save events to find the usual hour.

## Cut list, in order

If time runs out, cut from the top first:

1. Weekly recap notification (in R5.4; keep the payday reminder).
2. Backfill (R5.2); the comeback screen then offers only "Mulai dari hari ini".
3. Recap sharing (R4.2); the card stays in the app.
4. Moving Pola and Aliran (R4.5).

Never cut R1, R3.3, or R5.5.

## Weekly rhythm

Same as [05-sprints.md](05-sprints.md): plan on Monday, build Tuesday to Thursday, and keep
Friday for device testing, the design-review PNGs, and reading the week's events.
