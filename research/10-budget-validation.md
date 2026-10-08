# Budget validation: the pace-first against remaining-first bet

The protocol for the one contested bet in the plan, and the empty template the run fills in.
The code that measures it already ships, behind a flag. What does not exist yet is a beta: no
real users have opened this build, so there are no results to report here and none are
invented. Everything below is how the run is done, what it records, and how its numbers would
be read.

The bet in one line: wudget puts spending pace against elapsed time on the Pantau hero and
tucks the remaining balance one tap away, which contradicts almost every app in the study
([01-features.md](../plan/01-features.md), "Pace and forecast, instead of remaining balance").

---

## 1. The question, and what each result would mean

Does the remaining-balance framing hurt in practice for this audience, or is the Pocheptsova
Ghosh and Huang result specific to their samples? That is the open question verbatim from
[06-implications.md](06-implications.md), "Open questions" bullet 1, and it is the question
Sprint 13 exists to answer. The evidence behind the bet is a working paper with three field
studies and two lab experiments that found access to budget information, and specifically a
precise remainder, licensed late-period spending, and a randomised field experiment with
9,035 users across 13 weeks that found no spending reduction from budget feedback at all
([05, section 11](05-behavioral-research.md)). It has never been tested on Indonesian
first-time manual trackers. So the design ships pace-first as a default while keeping both
framings behind a flag ([05-sprints.md](../plan/05-sprints.md), Sprint 11, and
[06-audit-fixes.md](../plan/06-audit-fixes.md) Sprint 13).

**A positive result** (remaining-first is measurably worse): people who saw the remaining
balance led spend more of their period in the last third of it, or score lower on the stated
outcome, or drop off faster. The bet holds, the working paper survives contact with this
audience, and pace-first ships as the default with evidence rather than a citation.

**A negative result** (remaining-first is the same or better): the licensing effect does not
transfer, and the plan's hero is wrong for the people it was designed for. The default
changes, and the review surface is rebuilt around the remainder.

**A null result** (no interpretable difference): the bet is untested rather than won. With the
sample this run can reach, a null is the most likely outcome and the least informative one, so
the flag stays and the default stays where the plan put it. A null is not permission to claim
the working paper was wrong.

---

## 2. Instrumentation: what the shipped build records, and what is missing

**The variant exists and is persisted (per device, not per session).** The flag key is
`pace_first_framing` (`app/lib/data/feature_flags_repository.dart` line 6). It lives in the
`FeatureFlags` key-value table, written with `insertOnConflictUpdate` (same file line 28), so
it survives restarts and is a row in the database: one variant per device, not per session.
Absent, it reads as true, pace-first (`app/lib/core/providers.dart` lines 88 to 90, and
`app/lib/features/pantau/pantau_screen.dart` line 322). The branch itself is presentation-only:
`_ReviewBody` reads `paceFirstFramingProvider` at `pantau_screen.dart` line 531 and swaps which
number is the hero, pace and forecast inline at lines 560 to 577 (remaining balance behind a
"Lihat sisa anggaran" tap), remaining balance inline at lines 578 to 619 (pace and forecast
behind a "Lihat laju & perkiraan" tap). Both arms compute the same `PaceResult` and
`PeriodTotals` from one load, confirmed in [DECISIONS.md](../DECISIONS.md) Sprint 11.

**The view event carries the variant.** `pantau_screen.dart` lines 320 to 326 read the flag
one-shot and then log `pantau_viewed` with `props: {'variant': paceFirst ? 'pace_first' :
'remaining_first'}`. That is the measurement hook the prototype asked for, and it fires once
per `_load()`, so a pull-to-refresh logs it again (`pull_to_refresh` is its own event,
`pantau_screen.dart` line 298).

**The log is local and append-only, with no reader for it.** `AnalyticsRepository` writes to
the `AnalyticsEvents` table (`id`, `name`, `propsJson`, `occurredAt`), and both the class doc
comment (`app/lib/data/analytics_repository.dart` lines 10 to 13) and the table doc comment
(`app/lib/data/database.dart` lines 155 to 159) say the same thing: there is no analytics
backend in a local-first, no-account app, so these are read back with a direct query during the
weekly dogfooding review, not shipped anywhere. `all()` exists for that purpose
(`analytics_repository.dart` lines 27 to 32) and is called by nothing in `lib/`.

**What a beta build actually records today**, from reading the call sites:

| Event | Props | Where |
|---|---|---|
| `app_open` | none | `app/lib/main.dart` line 88 |
| `pantau_viewed` | `variant` | `pantau_screen.dart` lines 323 to 326 |
| `capture_open` | `source` | `app/lib/features/capture/capture_sheet.dart` line 144 |
| `capture_save` | `ms`, and more at line 418 | `capture_sheet.dart` lines 418 onwards |
| `insight_shown` | `day`, `key` | `app/lib/features/ledger/ledger_screen.dart` line 267 |
| `comeback_shown` | `lastEntryDay` | `main.dart` line 132 |
| `payday_confirm`, `payday_snooze` | payday amount details | `app/lib/features/payday/payday_card.dart` lines 91, 164 |
| `budget_review_accept`, `set_now_open` | budget details | `app/lib/features/payday/budget_review_screen.dart` lines 24, 304 |
| `reminder_toggle` | `key`, `on` | `app/lib/features/settings/saya_screen.dart` line 202 |
| `recap_shared` | none | `app/lib/features/pantau/recap_card.dart` line 117 |
| `pull_to_refresh` | `screen` | `pantau_screen.dart` line 298, and three other tabs |
| `onboarding_finished` / `onboarding_skipped` | step | `app/lib/features/onboarding/onboarding_screen.dart` lines 122 to 123 |

**Update, Sprint 13 build:** assignment, the reveal-tap event and the export path below are now built; see section 9. The rest of this section describes the build before that.

**Is the current build sufficient to run the test? No.** Three things are missing, and each one
is a blocker on its own.

1. **Nothing assigns a variant.** There is no randomisation anywhere in `lib/`: no call site
   seeds `pace_first_framing`, no `dart:math` import feeds a coin flip, and the only writes to
   the flag are the test suite (`app/test/features/pantau_screen_test.dart` line 215,
   `app/test/feature_flags_repository_test.dart` lines 24 to 26) and the onboarding write of
   `onboarding_completed` (`onboarding_screen.dart` line 119). Left alone, every beta device
   renders pace-first, so the experiment has one arm and no comparison.
2. **Nothing lets a user or a tester flip the flag.** `Saya` exposes three reminder switches
   and nothing else through `_ReminderRow` (`saya_screen.dart` lines 91 to 111), and the only
   on-device readout is the capture debug screen, which reports median time-to-save and logged
   days and nothing about the framing (`app/lib/features/settings/capture_debug_screen.dart`
   lines 19 to 32).
3. **Nothing gets the log off the device.** `BackupRepository.exportJson()` selects accounts,
   categories, transactions, postings, budgets, recurrences, recurrence overrides, app
   settings and feature flags and writes exactly those keys
   (`app/lib/data/backup_repository.dart` lines 36 to 58). `analyticsEvents` is not in that list
   and not in the returned map, so the event log is excluded from the JSON export by
   construction. `exportCsv()` is one row per posting (same file lines 128 to 149), also not
   events. `createBackup()` copies the whole SQLite file (line 153), which does contain the
   events table, but as a binary the owner would have to open with a SQLite tool.

**What has to be added before a beta run**, in order of how hard it blocks:

- **Assignment.** A deterministic, documented split at first run (device hash or roster order,
  written once into `pace_first_framing`). Assignment must happen before the first Pantau view,
  and must not be re-rolled on later launches, or a user drifts between arms.
- **An arm label the reader can trust.** A pseudonymous participant id in every event's props,
  so events group by person rather than by device reinstall.
- **An off-device path for the event log.** Either add `analyticsEvents` to `exportJson()`, or
  add a screen that dumps the log as JSON or CSV to a shareable file. Without one, the results
  section below can never be filled from anything but a hand-copied readout.
- **The remaining-balance tap as its own event.** `_TapRow` at `pantau_screen.dart` lines 573
  to 577 has no `logEvent` call, so today there is no record of a pace-first user going to look
  at the remainder anyway. That is the single most interesting leak in the design and it is
  currently invisible.
- **The outcome instrument.** Section 4.

Everything above is additive and sits behind the existing flag. No Dart is changed by this
document; the additions are the run's precondition, not its result.

---

## 3. How the beta runs

**How a user gets a variant.** The plan wants the flag flipped for beta users
([06-audit-fixes.md](../plan/06-audit-fixes.md) Sprint 13 ticket 1). In practice each tester
gets the split written at install: half get `pace_first_framing = true` (the plan's default,
[01-features.md](../plan/01-features.md)), half get `false` (remaining-first). Because the flag
is a stored row, each device keeps its arm across every launch and across a backup restore
(the flag travels in the export, `backup_repository.dart` lines 44 and 57), so a tester who
restores a friend's backup inherits their arm. That is a contamination path to watch.

**How many and how long.** The plan's own done-when is 20 or more beta users over two weeks
([06-audit-fixes.md](../plan/06-audit-fixes.md) line 253). That is the ticket's number and it
is too small for the question as asked: split two ways it is roughly ten devices per arm, which
cannot support a spending or well-being claim, only a directional read plus qualitative
follow-up. Two weeks is also short against a period that opens on payday
([02-flows.md](../plan/02-flows.md), and rule 5 in [08-retention-baseline.md](08-retention-baseline.md)),
and the well-being instrument is specified at day 90, not day 14
([03-architecture.md](../plan/03-architecture.md) line 296). The honest shape of this run is 20
users as a pilot that proves the plumbing and gives a first signal, not a trial that settles
the bet. If the bet must be settled numerically, the run has to be longer and larger, and both
of those are the owner's call, not this document's.

**The hard part: local-only, no backend.** There is no server and no account, so nothing is
streamed and nothing aggregates itself. Results have to be read off a device by hand, or the
export in section 2 gets built and testers send back a file. Read off a device means the owner
sits with one phone at a time and transcribes `pantau_viewed` rows with their variants.

**What that makes possible:** a small pilot with real users, an honest check that the two arms
render as intended on real devices, per-person event sequences for qualitative interview, and a
direction of travel on the contested bet.

**What that makes impossible:** anything resembling the 9,035-user field experiment in
[05, section 11](05-behavioral-research.md). No significance testing worth the name, no
segmentation by category or income, no attrition measurement that is not confounded by the
people who stopped replying, no automatic detection of who actually ran for two weeks. Every
number in the readout below is a hand-collected count, and has to be labelled as one.

---

## 4. The outcome measure, not just engagement

Engagement is not the outcome. Both budget experiments raised engagement and neither reduced
spending ([06-implications.md](06-implications.md) item 4, [05, section 11](05-behavioral-research.md)),
and [03-architecture.md](../plan/03-architecture.md) lines 283 to 296 makes the same point in
the measurement table. Counting `pantau_viewed` per arm answers only whether people open the
screen, so it is the secondary read, not the primary one.

**The named instrument: the CFPB Financial Well-Being Scale.** Ten items, free, validated, and
the one instrument the research names for this
([05, section 10](05-behavioral-research.md): "the CFPB's ten-item financial well-being scale is
the practical instrument, free and validated, and it is a better outcome measure for a money app
than any engagement metric"). It is already on the plan's metric list at day 90, opt-in
([03-architecture.md](../plan/03-architecture.md) line 296). The Netemeyer and colleagues
current-stress and future-security split behind it is why it is the right shape for a framing
question about spending today ([05, section 10](05-behavioral-research.md) lines 222 to 230).

**How it is delivered with no server.** As a screen in the app, behind an opt-in prompt at the
end of the run. The ten items render with the CFPB's own response options, answers are scored
locally with the published scoring guide, and the result is written to the local event log as a
survey event with the participant id and the arm. The owner reads it back off the device the
same way as everything else, or the user screenshots the result screen. The items are public
and free to reproduce; nothing about this needs a network or an account.

**A shorter stated alternative, if the full scale is too much to ask of 20 people at day 90:**
a single item, "Saya merasa keuangan saya terkendali bulan ini", on a five point scale, plus
the behavioural measure below. Say plainly what it is: this shorter form is not the validated
instrument, it is a directional proxy, and a difference on it is weaker evidence than a
difference on the ten-item scale. It is offered because a run that collects nothing at day 90
is worse than a run that collects a proxy.

**The behavioural outcome the app already has.** Share of the period's spending that lands in
the last third of the period, per person, per arm. The licensing mechanism in
[05, section 11](05-behavioral-research.md) is specifically about late-period spending, and
the ledger already records every transaction with a day bucket, so this needs no new capture,
only the export path from section 2. Note the standing caveat from the same experiment: budget
arms set budgets well below their own spending and then spent above them, so spend against the
user's own budget is a second useful read and not a target.

**The limitation, stated for the readout.** The scale measures perceived well-being at one
moment, not spending, and with no baseline at install a single reading cannot show change
within a person; it can only compare the two arms. It is self-reported, opt-in, and answered by
the people who are still around at the end of the run, which is exactly the people least likely
to have been harmed by the framing. Twenty users make it directional. It is still the right
instrument, because it is the only one that measures the thing the product claims.

---

## 5. The decision rule

Written before the run, so the result cannot pick the rule.

**Ship pace-first** if the pace arm shows no worse late-period spending share, no worse stated
outcome, and no worse logging or retention than the remaining-first arm. A direction favouring
pace on any of the three is a stronger version of the same decision. This is the plan's default
([01-features.md](../plan/01-features.md)) confirmed rather than changed.

**Ship remaining-first** if the pace arm is worse on the stated outcome, or on late-period
spending share, and the direction is consistent across both arms' people rather than driven by
one or two. Because of the sample size, this should need a large, unambiguous gap, not a small
one.

**Keep both** if the result is null or mixed, which is the likely outcome at this size, or if
the qualitative follow-up shows different people want different heroes. Keeping both means
promoting `pace_first_framing` from an internal flag to a setting the user can change in `Saya`,
and leaving the default on pace-first per the plan.

**A fourth branch, and the honest one: the run is uninterpretable.** If the export path was
never built and the readout is three people's screenshots, or if the arms cannot be proven to
have rendered differently on real devices, then no decision is taken and the default does not
move. A forced reading of a broken run is worse than a null.

---

## 6. Status: protocol now, results later

**No beta users exist yet.** There has been no run, no participants, no dates, no findings, and
this document contains none, because inventing them would be the exact failure the research
folder is built to avoid ([README.md](README.md): every number is sourced). The plan's write-up
ticket ([06-audit-fixes.md](../plan/06-audit-fixes.md) Sprint 13 ticket 3) names a results file,
and the code is in place, but the file it names cannot be filled in until real people use the
build.

What this document is: the measurement protocol (sections 1 to 5 and 7) and the empty readout
template (section 8) that the run fills in. When the run happens, section 8 is copied, filled
from hand-collected exports, and the decision rule in section 5 is applied to it.

One housekeeping note: the plan's Sprint 13 ticket points at `research/08-budget-validation.md`
([06-audit-fixes.md](../plan/06-audit-fixes.md) line 248), but `08` is already the retention
baseline ([08-retention-baseline.md](08-retention-baseline.md)), so this file is `10`. The
plan's link should be corrected when the plan is next touched.

---

## 7. Risks, and what would make the run uninterpretable

| Risk | Why it bites | What it would do to the read |
|---|---|---|
| Small sample (about ten per arm) | No power for a spending or well-being difference | Turns every result into a direction, not a verdict |
| Hand-collected data | Transcription error, missing events, arm drift when the flag is edited on a device | Numbers that cannot be reconciled with a second reading of the same device |
| No baseline survey | A day-90 score has nothing to compare within a person | Only an arm-to-arm comparison, and only if both arms answered |
| Opt-in response bias | The people who answer are the people who stayed | Outcomes measured on the least likely to be harmed |
| Two weeks against a month-long period | Roughly one period per person, maybe not from payday | Late-period spending share has one or two observations per person |
| Variant travels in the backup file | A restore can hand someone the other arm | Breaks the assignment unless the restore path is checked |
| Re-rolling the flag | Editing the flag mid-run moves a person between arms | The `pantau_viewed` variant column then measures the edit, not the person |
| Confounding by everything else in the build | Logging speed, reminders, budget proposal timing all move in the same two weeks | Any difference may belong to another change, not the framing |
| No outcome instrument built in time | `pantau_viewed` counts get reported as if they were the outcome | The exact error [06-implications.md](06-implications.md) item 4 warns about |

The run is uninterpretable if any of these hold: the export path does not exist, the assignment
is not documented and fixed, the two arms are not confirmed to render differently on real
devices, or the only outcome collected is engagement. Any one of those should stop the run
being written up as a finding.

---

## 8. The readout template

Empty by design. Every field is filled by the run, and every field that cannot be filled is
left as a gap and named as one.

```
## Run

- Window (start, end):                    [not run]
- Build / version:                        [not run]
- Participants recruited:                 [n]
- Participants who completed:             [n]
- Assigned pace_first:                    [n]
- Assigned remaining_first:               [n]
- Assignment method:                      [described]
- Confirmed both arms rendered on device: [yes / no / not checked]

## Engagement (secondary)

- pantau_viewed per user, pace_first:      [n]
- pantau_viewed per user, remaining_first: [n]
- Distinct days with a Pantau view, per arm:            [n]
- Remaining-balance tap count, pace_first arm:          [n]

## Behavioural outcome (secondary)

- Late-period spend share (last third of period), pace_first:      [n / n]
- Late-period spend share (last third of period), remaining_first: [n / n]
- Spend against own budget, per arm:                               [n / n]

## Stated outcome (primary)

- Instrument:                     CFPB Financial Well-Being Scale, ten items (or the stated
                                   single-item proxy, labelled as such)
- Responses collected:            pace_first [n], remaining_first [n]
- Score, mean and range per arm:  [n]
- Baseline collected at install:  [yes / no]

## Qualitative

- Interviews or written follow-ups: [n]
- Themes reported:                  [none until run]

## Interpretation

- Direction of the result:            [pending]
- Consistent across people, or one or two: [pending]
- Competing explanations considered:  [pending]
- Where this reading is weak:         [pending]

## Decision

- Applied rule from section 5:        [pending]
- Outcome: ship pace-first / ship remaining-first / keep both / run again: [pending]
- Flag left in place:                 [yes / no]
- What would change this decision:    [pending]
```

---

## 9. Sprint 13 build: what now runs, and how to read it

**Built in the Sprint 13 pass** (closing three of the four gaps in section 2):

- **Assignment.** `FeatureFlagsRepository.assignPaceFirstVariant()` runs at every launch from
  `main.dart`. When no `pace_first_framing` row exists it flips a coin (`Random().nextBool()`),
  writes the row and logs `variant_assigned` with `{"variant": ...}`. Once the row exists it never
  re-rolls. A coin flip, not a hash: with 20 people the split can land 8/12; the readout reports
  the actual arm sizes. An install that already had a row (a tester who flipped it by hand) keeps it.
- **The reveal tap.** `pantau_reveal` with `{"variant": ...}` fires when a pace-first user taps
  "Lihat sisa anggaran" or a remaining-first user taps "Lihat laju & perkiraan".
- **Off-device path.** `BackupRepository.exportJson()` now includes `analyticsEvents`. A tester
  sends the backup JSON from Saya, Cadangan & pulihkan. Restore ignores the key, so one device's
  log never lands on another.
- **Still missing:** a pseudonymous participant id. The backup file itself is the participant;
  the owner names each file on receipt (P01, P02, ...). The stated-outcome instrument (section 4)
  stays a short interview at the end of the run.

**Measurement plan.**

1. Beta build to 20 or more testers. Day 0 is each tester's `variant_assigned` timestamp.
2. At day 14 each tester sends a backup JSON. Name it `P<nn>.json` on receipt.
3. Run the query below over every file, then fill section 8.
4. Interview each tester (section 4), blind to arm where possible.

**The query.** Load each backup's `analyticsEvents` into one SQLite table, then:

```sql
-- events(participant TEXT, name TEXT, props_json TEXT, occurred_at INTEGER)
WITH arm AS (
  SELECT participant, json_extract(props_json, '$.variant') AS variant, MIN(occurred_at) AS t0
  FROM events WHERE name = 'variant_assigned' GROUP BY participant
)
SELECT a.variant,
       COUNT(DISTINCT a.participant)                                        AS people,
       SUM(e.name = 'pantau_viewed') * 1.0 / COUNT(DISTINCT a.participant)  AS views_per_person,
       SUM(e.name = 'pantau_reveal') * 1.0 / NULLIF(SUM(e.name = 'pantau_viewed'), 0) AS reveal_rate,
       SUM(e.name = 'capture_save') * 1.0 / COUNT(DISTINCT a.participant)   AS saves_per_person,
       COUNT(DISTINCT CASE WHEN e.name = 'capture_save'
             THEN a.participant || ':' || (e.occurred_at - a.t0) / 86400000 END) * 1.0
         / COUNT(DISTINCT a.participant)                                    AS logged_days_per_person
FROM arm a JOIN events e ON e.participant = a.participant
WHERE e.occurred_at < a.t0 + 14 * 86400000
GROUP BY a.variant;
```

A Python loader, run once per file, is enough:
`for e in json.load(open(f))["analyticsEvents"]: db.execute("insert into events values (?,?,?,?)", (f.stem, e["name"], e["propsJson"], e["occurredAt"]))`.

**Decision rule.** Section 5 applies unchanged. In short: pace-first stays the default unless the
pace arm is clearly worse on the stated outcome or late-period spending; a null or mixed result
keeps both and promotes the flag to a Saya setting; fewer than 20 backups returned, or arms that
cannot be shown to have rendered differently, means no decision. A high `reveal_rate` in the pace
arm (people going to look at the remainder anyway) is read as a reason to keep both, not as a win
for either.

**Human steps:** recruit testers, ship the beta build, collect backups at day 14, run the query,
interview, fill section 8.

## Sources

Read to write this document, with the lines each claim came from:

- [08-retention-baseline.md](08-retention-baseline.md), the baseline this validation runs against,
  and the voice this file follows.
- [06-implications.md](06-implications.md), "Open questions" bullet 1 (the question),
  "Where the evidence contradicts the default design" item 1 (the bet) and item 4 (engagement
  is not the outcome, CFPB named).
- [05-behavioral-research.md](05-behavioral-research.md), section 10 (the instrument), section
  11 (the licensing finding and the 9,035-user null).
- [05-sprints.md](../plan/05-sprints.md), Sprint 11 (both framings behind a flag, with
  measurement hooks), the Thursday rhythm, and cut list item 5.
- [06-audit-fixes.md](../plan/06-audit-fixes.md), Sprint 13 (ship to beta, analyze, document,
  20 users over two weeks).
- [01-features.md](../plan/01-features.md), lines 96 to 103 (pace-first is the stated default).
- [02-flows.md](../plan/02-flows.md), "4. Pantau, the review surface".
- [03-architecture.md](../plan/03-architecture.md), lines 282 to 296 (the measurement table and
  the day-90 opt-in instrument).
- [DECISIONS.md](../DECISIONS.md), Sprint 11 (flags as a key-value table, the local-only event
  log, presentation-only variant swap, the one-shot flag read).

Shipped code, verified by reading it:

- `app/lib/data/feature_flags_repository.dart` line 6, line 28.
- `app/lib/core/providers.dart` lines 88 to 90.
- `app/lib/data/analytics_repository.dart` lines 10 to 13, 18 to 32.
- `app/lib/data/database.dart` lines 155 to 168.
- `app/lib/features/pantau/pantau_screen.dart` lines 298, 320 to 326, 531, 560 to 620.
- `app/lib/features/settings/saya_screen.dart` lines 91 to 111, 202.
- `app/lib/features/settings/capture_debug_screen.dart` lines 19 to 32.
- `app/lib/data/backup_repository.dart` lines 36 to 58, 128 to 149, 153.
- `app/lib/main.dart` line 88, line 132.