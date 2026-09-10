# Expense tracker research

Desk research on personal expense and budget tracking apps: what they ship, how their
systems are modelled, how the flows and screens work, what users complain about, and what
the behavioural science says about budgeting.

Pulled 2026-09-10. Every number and quote in these files is sourced. Where a figure came
from a marketing blog or an aggregator and could not be traced to a primary source, it is
marked `[unverified]` and should not be reused.

## Files

| File | What is in it |
|---|---|
| [01-app-teardowns.md](01-app-teardowns.md) | Per-app breakdown of the seven named apps plus twelve benchmarks: data model, features, pricing, flows |
| [02-feature-matrix.md](02-feature-matrix.md) | Side-by-side matrix and a feature taxonomy (what is table stakes, what is differentiating) |
| [03-flows-and-ux.md](03-flows-and-ux.md) | The canonical flows (onboarding, capture, budget, review, shared ledger) with the design trade-offs at each step |
| [07-ui-audit.md](07-ui-audit.md) | Screen-level UI read of all six findable apps: navigation, colour, charts, number formatting, and the craft problems ranked |
| [04-user-reviews.md](04-user-reviews.md) | Review themes across 300+ App Store reviews, ranked by how often they kill retention |
| [05-behavioral-research.md](05-behavioral-research.md) | Peer-reviewed work on mental accounting, budget bias, payment friction, reminders, gamification, abandonment |
| [06-implications.md](06-implications.md) | Where the research contradicts standard app design, and the open questions it leaves |

## Method and its limits

App facts come from the iTunes Search and Lookup APIs, App Store review feeds, Google Play
listings, and the apps' own marketing sites. Screens were read from 28 App Store screenshots
at 626px, plus a browser visit to MELD's live web app, which has no App Store listing. Store
screenshots are curated marketing assets: they show the intended flow, not necessarily the
shipped one, and none of them shows an empty, loading or error state. No app was installed or driven end to end, so anything about tap counts, latency, or
error handling is inferred from screenshots and reviews rather than measured.

Review feeds return the most recent pages only (roughly 50 per country page), and reviewers
skew toward the frustrated and the delighted. Treat the review themes as a map of where
things break, not as a share-of-voice measurement.

## Two names could not be verified

`Dastlycal` returned nothing on the App Store (US and ID storefronts), nothing on Google
Play, and nothing on the open web. `Richual` exists but is tiny and brand new, so the review
signal for it is one rating. If Dastlycal is spelled differently or is a Play-only or
regional release, send the exact store link and it can be added.
