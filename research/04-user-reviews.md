# What users actually complain about

## How this was measured

1,515 unique App Store reviews pulled 2026-09-10 from the public review feeds of eighteen
apps (the seven named apps where reviews exist, plus twelve benchmarks), across the US, ID
and GB storefronts, most recent pages only. 622 of them are one, two or three stars.

The percentages below are keyword frequency inside those 622 negative reviews, not coded
qualitative analysis. A single review often hits several themes, so the column does not sum
to 100. Read it as a ranking of where the pain is, not as a measurement of share.

Reviews are paraphrased rather than quoted, and every claim below is a user's report, not a
verified fact about the app.

| Theme | Share of negative reviews mentioning it |
|---|---|
| Pricing and paywall | 30% |
| Sync and connection | 18% |
| Performance, crashes, bugs | 18% |
| Support silence | 15% |
| Categorisation | 10% |
| Complexity and learnability | 10% |
| Data loss or lost history | 7% |
| Regression after an update or redesign | 7% |
| Ads | 6% |
| Recurring items and bills | 6% |

## The themes, in order

### 1. Pricing changes read as betrayal, not as price

The single largest cluster, and it is rarely about the amount. Reviewers object to the
change, not the number. Recurring shapes: a free app becomes paid and previously used
features lock (SyncSpend); a one-time purchase is followed by a subscription for the next
tranche of features, which a Money Lover reviewer of many years describes as being asked to
pay twice; a free tier is capped so tightly that the app cannot be evaluated (Splitwise's
entry limit); a trial converts before the user has finished setting up (Monefy).

The worst variant is history behind the paywall. A SyncSpend reviewer reports that the free
tier keeps one month, so when the month turned their earlier records became unreadable, and
they describe that as losing their records. Functionally the data may still exist. That is
not what the user experienced.

The second-worst is trial length against cycle length. A Monarch reviewer makes the argument
cleanly: a seven-day trial cannot evaluate a monthly-cycle product, because rollovers,
recurring items and rules only reveal themselves over a full cycle.

### 2. Sync and bank connections break, and that breaks trust in everything

Almost entirely a benchmark problem, because none of the seven named apps connect to banks.
Honeydue, Buddy, Copilot, Monarch, YNAB and Goodbudget reviewers all describe the same arc:
connections drop after days or weeks, reconnecting sometimes works, re-syncs bring back
already-reviewed transactions, duplicate them, or recategorise them.

The consequence is worse than the inconvenience. One Buddy reviewer says the resyncs mean
they cannot trust the data, and they moved to another product. A YNAB reviewer asks what the
point of a budget app is if it does not consistently track cash flow. A Goodbudget reviewer
complains that the app shows them the money they had three days ago. For a ledger, stale is
close to useless, and silently wrong is worse than empty.

### 3. Performance regressions after a redesign

Spendee is the case study. Multiple reviews after the version 6 redesign describe the app
freezing, the add button taking a long time to open, needing several attempts to enter one
transaction, and number buttons that look bigger but respond worse. Monarch reviewers
describe degradation over time that a delete and reinstall fixes, and taps that open a dozen
copies of a screen because the first tap did not respond.

Capture latency is not a polish issue in this category. It is the product. A tracker you
cannot type into in the checkout queue is a tracker you stop using.

### 4. Support silence turns a bug into a departure

15% of negative reviews mention getting no answer. Honeydue reviewers report being locked
out by two-factor tied to an old phone number with no reply to repeated requests. A Buddy
reviewer reports a credit card sign bug acknowledged by support and still unfixed three
months later. Several reviewers say explicitly that they wanted to keep using the app.
Support is a retention feature, and reviewers use the App Store as the escalation channel of
last resort.

### 5. Auto-categorisation that is not good enough to trust

The paradox: manual apps are criticised for having no suggestions, and automatic apps are
criticised because the suggestions are wrong. A Money Manager review notes the absence of
category suggestions from the transaction note. A Copilot reviewer says that after three
months they still recategorised nearly everything and cancelled over it. Monarch reviewers
call categorisation unreliable and rule priority opaque.

What the better designs do is refuse to hide the guess. Expensa's screenshot shows the
suggested category as a card with Apply and Change category, so the user's job is to confirm
in one tap. A visible guess that is wrong costs one tap; an invisible guess that is wrong
costs trust in the totals.

### 6. Complexity, in two opposite directions

Some reviewers want less. A long-time Money Manager user says it used to be simple and has
been overcomplicated. Goodbudget reviewers call the envelope model harder than it needs to
be. A YNAB reviewer says planning next month is exhausting.

Others want more, in one specific place. Money Manager reviewers ask for budgets on
categories the system will not allow, an Apple Watch app for entry at the moment of
spending, split categories on a single transaction, and time on income entries. Ollo's
reviewers ask for income tracking and a widget.

These are not contradictory. Nobody asks for a broader app. They ask for the one thing that
unblocks their situation, and for everything else to get out of the way. Progressive
disclosure, not fewer features.

### 7. Data loss, the reputation killer

7% of negative reviews, and the most damaging 7%. A Money Manager reviewer reports that an
update wiped their transactions, categories and accounts. A Buddy reviewer reports a year of
data collapsing into a single month. A Rocket Money reviewer reports that after almost five
years, an account unlink lost their categorised history with no import path to rebuild it.
Spendee and Monefy reviewers report records simply gone.

Three things follow. Backup and restore is a core feature and not a settings-screen
afterthought. Migrations need to be reversible. And import matters as much as export,
because a user rebuilding after a loss is the most motivated user you will ever have, and
turning them away converts a bug into a one-star review with a story attached.

### 8. Recurring items that do not behave

A specific, repeated failure. A Money Manager reviewer entered monthly recurring items, saw
them vanish, re-entered them repeatedly, and then a month later all the attempts appeared at
once. Another reports repeating transactions not being visible ahead of time, which defeats
the purpose of planning. Money Lover reviewers report recurring dates landing on the wrong
day. Monarch reviewers report bills of variable amount, power and water, not being trackable
at all.

Recurrence has more edge cases than it looks: weekend shifting, month-end dates that do not
exist in every month, variable amounts, and the question of whether a future instance is a
forecast or a fact. Every app in this sample gets at least one of them wrong.

### 9. Ads that eat the interface

Money Manager reviewers describe the banner growing until it covered tappable areas of the
screen, which is a fully self-inflicted wound: the free tier stopped working, so the review
score paid for the impressions.

## What the positive reviews praise

Worth reading as a spec. Across the named apps the compliments are consistently about
speed and clarity rather than features: easy to use, clear, good-looking, the interface is
nice. Ollo's ID reviewers praise ease of use and the interface, and then immediately request
a widget and report a missing back button, which is the profile of a product people want to
like. Ollo's strongest review names the specific objects that made it work for them (goals,
bills, wishlist, assets) and says the subscription price is reasonable, which suggests the
secondary objects are doing real work rather than padding a feature list.

The SyncSpend positive review is instructive for a different reason: the reviewer praises it
for asking almost nothing beyond the amount, and for putting the data where they already
keep it. That is the whole value proposition of a thin client, and it is a legitimate
position to take.
