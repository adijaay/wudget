# Implications and open questions

The research and the reviews disagree with standard app design in a few specific places.
Those disagreements are the interesting part, so they are listed first. Nothing here is a
decision; it is a list of things that need deciding, with the evidence attached.

---

## Where the evidence contradicts the default design

**1. The "left to spend" number may be counterproductive.** It is the flagship screen in
almost every app in this study. The strongest available evidence says a live
remaining-balance display raises spending late in the period, because certainty about the
remainder licenses using it, and that budget arms in a controlled field experiment produced
no spending reduction at all
([05, section 11](05-behavioral-research.md)). Alternatives worth testing against it: pace
against elapsed time, a forecast of where the period lands, or an explicit prompt to move
the surplus out of reach rather than leaving it displayed and available.

**2. Asking for a budget during onboarding extracts a number the user cannot yet know.**
Budget predictions made for open time frames run well below actual spending, and the
mechanism is the savings goal held while predicting
([05, section 2](05-behavioral-research.md)). Observation first, budget at the first period
boundary, is both better evidence and better timed against the fresh start effect.

**3. Removing all friction from logging removes the intervention.** The pain of paying and
the partitioning results say the moment of noticing is where behaviour changes
([05, section 4](05-behavioral-research.md)). Full automation delivers a clean dataset and
no noticing. The design target is not zero friction, it is friction moved to the right
place: typing an amount is waste, naming what you bought may not be.

**4. Engagement is not the outcome.** Both budget experiments increased app engagement.
Neither reduced spending. A level badge that rewards logging streaks
(Ollo) rewards the means and not the end. If the product claims to help people spend less
or save more, that claim needs its own measurement, and the CFPB well-being scale is a
free, validated instrument for it ([05, section 10](05-behavioral-research.md)).

**5. An education tab is close to worthless.** 201 studies, 585,168 participants, roughly
0.1 per cent of variance in behaviour, decaying to negligible after twenty months. The same
content as one sentence at the decision point is the version with evidence
([05, section 9](05-behavioral-research.md)).

---

## What the market gap looks like

Across the seven named apps, nobody connects to a bank, so the whole cohort competes on
manual capture quality. Three gaps stand out.

**Sharing.** Only MELD treats shared money as the product, and it is Indonesian, web-wrapped
and outside the App Store. The behavioural case for shared visibility is strong (joint
accounts change both spending composition and relationship satisfaction), and the benchmark
reviews show the incumbents doing it badly: Honeydue's sync failures and its inability to
remove a former partner from shared bills, Splitwise's entry caps.

**Local rails as first-class objects.** Indonesian everyday spending runs through QRIS and
e-wallets, which means no statement to import and a record scattered across wallet apps.
Ollo and MELD both model e-wallets properly; the Western apps do not. Arisan, split bills,
and money owed to you (Ollo's reimbursements, MELD's payables and receivables) are real,
frequent objects that most category leaders lack entirely.

**Interpretation over visualisation.** Almost every review surface in this study is a chart.
One app (Expensa) writes a sentence interpreting the number. The abandonment literature says
repetitive, uninterpreted feedback is a named reason people quit
([05, section 12](05-behavioral-research.md)).

---

## Things to get right because the reviews say they are where users leave

Ranked by how often the failure appears in 622 negative reviews.

1. Never gate history behind a paywall or a plan change. It reads as data loss and produces
   the harshest reviews in the sample.
2. Backup, restore and import are core features. A user rebuilding after a loss is the most
   motivated user there is, and there is often no path for them.
3. Capture latency is the product. Spendee's redesign is the cautionary case: a nicer
   interface that people could not type into fast enough.
4. Make the automated guess visible and one tap to correct. An invisible wrong guess costs
   trust in every total.
5. Recurrence needs its edge cases handled: weekend shifts, month-end dates that do not
   exist, variable amounts, and whether a future instance is a forecast or a fact. Every app
   in this sample gets at least one wrong.
6. Let the period start on payday, not on the 1st. Money Manager has had this for years and
   most modern apps still do not.
7. Answer support mail. 15 per cent of negative reviews are about silence, and several of
   them are from people who said they wanted to stay.
8. Shared features need an unwind path. Relationships end, housemates move out, and the data
   model has to survive it.

---

## Open questions

These are the things this research cannot answer from the outside.

- Does the remaining-balance framing hurt in practice for this audience, or is the
  Pocheptsova Ghosh and Huang result specific to their samples? It is a working paper, and
  the question is testable in-product with two framings.
- Is voice capture actually faster than a well-designed one-screen numpad? Ollo ships both
  and claims roughly three seconds for voice. That is measurable, and worth measuring before
  building a voice pipeline.
- On Android in Indonesia, can notification listening cover QRIS and e-wallet spend reliably
  and within current Play policy? That policy question decides whether automatic capture is
  even available without an aggregator.
- What is the real retention curve for a manual tracker past day 30? Nothing in the public
  data answers this, and it is the number that determines whether capture speed or review
  quality deserves the next sprint.
- Does a shared ledger with activity notifications raise logging consistency, and at what
  point does visibility start to feel like surveillance? MELD has the mechanic in market and
  no published evidence either way.

---

## Where to look next, if this gets extended

Not covered here, and each would change the picture: actually installing and instrumenting
the seven apps to measure taps and latency on the capture path; Google Play review mining
for the Indonesian market, which the App Store feeds under-sample; the SNAP open API and
aggregator terms in detail if automatic capture is on the table; and the OJK and Bank
Indonesia primary releases for any figure that leaves the team, since the secondary
reporting on QRIS numbers is inconsistent.
