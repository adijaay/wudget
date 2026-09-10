# How people actually manage money: the research

Peer-reviewed work first, then working papers and industry experiments, then the things
that are commonly repeated and do not hold up. Anything traceable only to a vendor blog is
marked `[unverified]` and should not be used as evidence.

---

## 1. People budget in mental categories, and those categories distort choices

Mental accounting is the set of cognitive operations households use to organise, evaluate
and track financial activity: money gets sorted into categories, budgets get assigned to
them, and spending is charged against them. Thaler's work established the frame; Zhang and
Sussman's review is the current map of it.

Heath and Soll ran three studies showing that consumers really do set category budgets and
track expenses against them, and that budgeting can cause underconsumption. Because a budget
cannot anticipate every opportunity, a category ends up over or under funded, so people
skip purchases they would have valued (the category is spent) or buy things they would not
have (the category has room). The effect is larger for purchases that are highly typical of
their category, because a typical purchase both draws down the category and blocks other
typical items in it.

Practical reading for an app: the category structure you ship is not a neutral reporting
choice. It is the structure people will make decisions inside. Fewer, broader categories
mean fewer artificial blocks; more, narrower categories mean tighter control and more
distortion.

- Thaler, R. H. (1985). Mental Accounting and Consumer Choice. *Marketing Science* 4(3),
  199 to 214. And Thaler, R. H. (1999). Mental accounting matters. *Journal of Behavioral
  Decision Making* 12(3), 183 to 206.
- Heath, C. and Soll, J. B. (1996). Mental Budgeting and Consumer Decisions. *Journal of
  Consumer Research* 23(1), 40 to 52.
  [paper](https://academic.oup.com/jcr/article-abstract/23/1/40/1892763) ·
  [PDF](https://bear.warrington.ufl.edu/brenner/mar7588/Papers/heath-soll-jcr1996.pdf)
- Zhang, C. Y. and Sussman, A. B. (2018). Perspectives on mental accounting: an exploration
  of budgeting and investing. *Financial Planning Review*.
  [paper](https://onlinelibrary.wiley.com/doi/abs/10.1002/cfp2.1011)

---

## 2. Budgets set in advance are systematically too low

Peetz and Buehler show that people predict spending well below what they go on to spend,
and trace the gap to the savings goal held at the moment of prediction: a stronger desire to
save lowers the prediction without lowering actual spending. Two useful boundary conditions.
Predictions for a concrete, specific event are close to accurate; it is the open time frame
("next week", "next month") that produces the bias. And unpacking the expected expenses into
their components raises the prediction and can eliminate the underestimate.

Sussman and Alter add the other half. Across seven studies, people budget ordinary spending
reasonably well and badly underestimate exceptional spending, and they overspend on each
exceptional purchase, because each one is construed as a unique event rather than as a
member of a category. NYU Stern's release on the work reports participants spending close
to double what they expected on exceptional items. The proposed fix is to help people see
exceptional purchases as one set rather than a series of one-offs.

Practical reading: the blank budget field in onboarding is the worst possible moment to ask
for a number. Either propose one from observed spending, or make the user unpack the month
into named items before naming a total. And give exceptional spending a home, an annual or
irregular bucket, so gifts, repairs, travel and celebrations stop each looking like an
exception.

- Peetz, J. and Buehler, R. (2009). Is There a Budget Fallacy? The Role of Savings Goals in
  the Prediction of Personal Spending. *Personality and Social Psychology Bulletin*.
  [paper](https://journals.sagepub.com/doi/10.1177/0146167209345160)
- Sussman, A. B. and Alter, A. L. (2012). The Exception Is the Rule: Underestimating and
  Overspending on Exceptional Expenses. *Journal of Consumer Research* 39(4), 800 to 814.
  [paper](https://academic.oup.com/jcr/article-abstract/39/4/800/1798285) ·
  [NYU release](https://www.nyu.edu/about/news-publications/news/2012/september/stern-study-most-consumers-underestimate-their-exceptional-spending.html)

---

## 3. How you frame the period changes the estimate

Ülkümen, Thomas and Morwitz show that budget estimates move with how easy the estimate feels
and how confident the person is, and that framing the same span differently ("12 months"
against "a year") changes the number. Shorter, more concrete spans are easier to estimate.

Practical reading: the period selector is not just a filter. Defaulting to a month rather
than a year, or to a payday cycle rather than a calendar month, changes what people believe
about their own spending.

- Ülkümen, G., Thomas, M. and Morwitz, V. G. (2008). Will I Spend More in 12 Months or a
  Year? The Effect of Ease of Estimation and Confidence on Budget Estimates. *Journal of
  Consumer Research*. [SSRN](https://www.ssrn.com/abstract=1440421)

---

## 4. Payment friction is doing work that automation removes

Prelec and Loewenstein's decoupling account explains why cash restrains spending and cards
do not. Handing over notes is salient and immediate, so the cost is felt at the moment of
consumption. A card separates the two, which lowers the pain of paying and raises
willingness to spend.

Cheema and Soman show the constructive version of the same mechanism. Partitioning a
resource into smaller units slows consumption, because each partition inserts a small
transaction cost and therefore an extra decision point. Their field work with Soman on day
labourers in India is the cleanest demonstration: earmarked savings split across two
envelopes produced substantially higher saving than the same amount in one envelope.

Practical reading, and it cuts against the usual product instinct. Removing every trace of
friction from spending and from logging removes the moment of noticing too. Envelope and
wallet partitioning is not a legacy metaphor, it is the mechanism. And the argument for
manual capture is not nostalgia: the act of naming what you just bought is the intervention.

- Prelec, D. and Loewenstein, G. (1998). The Red and the Black: Mental Accounting of Savings
  and Debt. *Marketing Science*.
  [overview](https://www.behavioraleconomics.com/resources/mini-encyclopedia-of-be/pain-of-paying/)
- Cheema, A. and Soman, D. (2008). The Effect of Partitions on Controlling Consumption.
  *Journal of Marketing Research* 45(6), 665 to 675.
  [paper](https://journals.sagepub.com/doi/10.1509/jmkr.45.6.665)
- Soman, D. and Cheema, A. (2011). Earmarking and Partitioning: Increasing Saving by
  Low-Income Households. *Journal of Marketing Research* 48(SPL), S14 to S22.
  [paper](https://journals.sagepub.com/doi/10.1509/jmkr.48.SPL.S14) ·
  [PDF](http://www-2.rotman.utoronto.ca/dilip%20soman/EarmarkingSavingsMS.pdf)

---

## 5. Reminders work, and they work better when they are specific

Karlan, McConnell, Mullainathan and Zinman model saving as a problem of limited attention:
people attend to consumption but fail to attend to future lumpy expenditures. Three field
experiments with new savings account holders support two predictions, that reminders
increase saving, and that a reminder naming a specific expenditure works better than a
generic one.

Practical reading: "you have spent 80 per cent of your food budget" is a generic reminder
about a number. "Your insurance renewal is on the 14th and you are IDR 400,000 short" names
a specific expenditure. The literature says the second one moves behaviour.

- Karlan, D., McConnell, M., Mullainathan, S. and Zinman, J. (2016). Getting to the Top of
  Mind: How Reminders Increase Saving. *Management Science* 62(12), 3393 to 3411.
  [NBER version](https://www.nber.org/papers/w16205)

---

## 6. Temporal landmarks reset motivation

Dai, Milkman and Riis document the fresh start effect: goal-directed behaviour, gym visits,
diet searches, commitments, rises after temporal landmarks such as the start of a week,
month, year or semester, or a birthday. The landmark separates the person from their past
self and makes a new attempt feel viable.

Practical reading: the monthly boundary that expense apps already have is a motivational
asset most of them waste. A period close with a summary and an explicit re-commitment is
better timed than a mid-month nudge. The same logic applies to a lapse: a user who stopped
logging on the 12th is much more reachable on the 1st than on the 20th.

- Dai, H., Milkman, K. L. and Riis, J. (2014). The Fresh Start Effect: Temporal Landmarks
  Motivate Aspirational Behavior. *Management Science* 60(10), 2563 to 2582.
  [PDF](https://faculty.wharton.upenn.edu/wp-content/uploads/2014/06/Dai_Fresh_Start_2014_Mgmt_Sci.pdf)

---

## 7. Progress you can see beats progress that is optimal

Gal and McShane analysed data from a debt settlement firm and found that the fraction of
accounts a consumer had closed predicted eventual debt elimination, while the dollar balance
of the closed accounts did not. Completing discrete subtasks appears to sustain persistence.
This is the empirical backing for the debt snowball, and Hamilton and colleagues have since
quantified what that motivational gain costs in interest, so the honest presentation gives
the user both.

Practical reading: goals and debts should be structured so that something visibly completes
early. A single large progress bar that moves imperceptibly is the anti-pattern.

- Gal, D. and McShane, B. B. (2012). Can Small Victories Help Win the War? Evidence from
  Consumer Debt Management. *Journal of Marketing Research*.
  [PDF](https://www.blakemcshane.com/Papers/jmr_debt.pdf)
- Hamilton and colleagues (2023). Two steps forward, one step back? Quantifying the
  pecuniary costs of debt account aversion and the debt snowball. *Southern Economic
  Journal*. [paper](https://onlinelibrary.wiley.com/doi/full/10.1002/soej.12612)

---

## 8. Shared accounts change both spending and the relationship

Olson, Gladstone, Garbinsky and Mogilner report that couples who pool their money in joint
accounts show higher relationship satisfaction and are less likely to break up, and they
argue for a causal reading rather than a correlational one, with financial togetherness as
the mediator. Garbinsky and Gladstone show a spending consequence: money spent from a joint
account skews toward utilitarian rather than hedonic purchases, because spending shared
money creates a need to justify it.

Practical reading: a shared ledger is not only a convenience feature, it changes behaviour
through the need to justify. That is the same mechanism as MELD's notification on a group
member's entry: visibility to another person is the intervention. It also means the design
has to handle the dark side, since visibility can become surveillance, which is why per-item
privacy and a clean removal path are requirements and not extras.

- Olson, J. G., Gladstone, J. J., Garbinsky, E. N. and Mogilner, C. (2023). Common Cents:
  Bank Account Structure and Couples' Relationship Dynamics. *Journal of Consumer Research*
  50(4), 704. [paper](https://academic.oup.com/jcr/article/50/4/704/7077142)
- Garbinsky, E. N. and Gladstone, J. J. (2019). The Consumption Consequences of Couples
  Pooling Finances. *Journal of Consumer Psychology*.
  [paper](https://myscp.onlinelibrary.wiley.com/doi/abs/10.1002/jcpy.1083)

---

## 9. Financial education barely moves behaviour, advice at the decision point might

Fernandes, Lynch and Netemeyer meta-analysed 201 studies covering 585,168 participants and
found that interventions to improve financial literacy explain about 0.1 per cent of the
variance in the financial behaviours studied, with weaker effects in low-income samples, and
that effects decay: even large, many-hour interventions have negligible effect on behaviour
twenty months out. Their alternative is advice delivered just in time, at the moment of the
decision, and choice architecture that does not require expertise.

Practical reading: an education tab is close to worthless. The same content delivered as one
sentence at the moment a decision is being made is the version with evidence behind it.

- Fernandes, D., Lynch, J. G. and Netemeyer, R. G. (2014). Financial Literacy, Financial
  Education, and Downstream Financial Behaviors. *Management Science* 60(8), 1861 to 1883.
  [SSRN](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2333898)

---

## 10. What to measure, if the goal is well-being rather than logging

Netemeyer, Warmath, Fernandes and Lynch separate perceived financial well-being into
current money management stress and expected future financial security, and relate both to
overall well-being. The CFPB's ten-item financial well-being scale is the practical
instrument, free and validated, and it is a better outcome measure for a money app than any
engagement metric.

- Netemeyer, R. G., Warmath, D., Fernandes, D. and Lynch, J. G. (2018). How am I doing?
  Perceived financial well-being, its potential antecedents, and its relation to overall
  well-being. *Journal of Consumer Research* 45(1), 68 to 89.
- CFPB Financial Well-Being Scale.
  [guide](https://www.consumerfinance.gov/data-research/research-reports/financial-well-being-scale/)

---

## 11. The uncomfortable finding: budget feedback can increase spending

Two independent results point the same way, and both should be treated as provisional.

Pocheptsova Ghosh and Huang, in a technical report for the Think Forward Initiative (three
field studies and two lab experiments), report that access to budget information increased
spending, concentrated at the end of the budget period, while people who tracked by memory
did not overspend. The mechanism they propose is certainty: knowing precisely how much
remains in the category licenses spending it. They tested six mitigations and report that
five attenuated the effect, including prompting users to roll the remainder into savings. I
could not confirm a peer-reviewed publication of this paper, so it is a working paper, not
settled science.

Irrational Labs ran a randomised field experiment with a fintech partner: 9,035 users, 13
weeks, from 2019-09-30. Three arms, an informational control (n = 4,368), a one-number
weekly budget (n = 2,723), and a category budget (n = 1,944). Average spending came out at
USD 675.97, 681.08 and 673.25 respectively, with p greater than 0.4, so no detectable
difference. Two secondary findings matter more than the null: budgeters set budgets well
below their own recent spending and then spent 1.3 to 1.4 times the budget, and spending in
budgeted categories ran around USD 30 higher than in unbudgeted ones. Engagement went up in
both budget arms. Note this was a single fintech's user base and it has not been peer
reviewed.

Practical reading, stated carefully. There is no good evidence that shipping a budget
feature makes users spend less, and there is some evidence that a live remaining-balance
display makes them spend more. Engagement and behaviour change are not the same outcome, and
this category routinely reports the first as if it were the second. If the product claims to
help people spend less, that claim needs its own measurement, not a proxy.

- Pocheptsova Ghosh, A. and Huang, L. Dynamic Budget Monitoring: When Access to Budget
  Feedback Leads to Increase in Spending. Think Forward Initiative technical report.
  [summary](https://www.behavioraleconomics.com/the-budgeting-app-trap-when-spending-information-backfires/)
- Irrational Labs. Does Budgeting Help You Save Money?
  [write-up](https://irrationallabs.com/blog/money-budgeting-experiment/)

---

## 12. Why people stop tracking

Research on personal informatics abandonment (Epstein and colleagues surveyed 193 people and
interviewed 12) identifies several reasons people stop self-tracking, and the ones that
transfer directly to expense apps are: data without any suggested action, feedback that
repeats until it teaches nothing new, tools that assume prior tracking experience, and the
realisation that the tool does not fit the need. Rapp and Cena make the point about novices
specifically: instruments designed by and for experienced self-trackers lose beginners fast.

Practical reading: the review screen has to change over time. A category donut that looks
identical every month is a reason to stop opening the app. Abandonment is also normal rather
than a failure state, and Epstein's framing (life after tool use) suggests designing for
lapse and return instead of only for streaks.

- Epstein, D. A. and colleagues. Beyond Abandonment to Next Steps: Understanding and
  Designing for Life after Personal Informatics Tool Use.
  [paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5428074/)
- Rapp, A. and Cena, F. (2016). Personal informatics for everyday life: how users without
  prior self-tracking experience engage with personal data.
  [paper](https://www.sciencedirect.com/science/article/abs/pii/S107158191630060X)

---

## 13. Gamification: real but narrower than the marketing

Two peer-reviewed sources are worth reading, and both are about moderation rather than a
headline lift. Bayuk and Altobello find that gamification moderates the relationship between
financial planning and financial behaviour, and between financial self-efficacy and
behaviour, with app expertise as a moderator, so the effect depends on who is using it.
Agrawal's 2025 evaluation in Financial Planning Review looks at gamification and financial
conduct in relation to behavioural traits.

`[unverified]` A large set of specific numbers circulates on vendor blogs (engagement up 45
per cent, savings up 20 to 30 per cent, streak devices raising contributions by 41 per cent,
retention 78 against 31 per cent). None of these traced back to a primary source in this
search. Do not repeat them.

Practical reading, and the concern is design rather than efficacy. A level badge, as in
Ollo, rewards logging. Logging is the means. If the reward schedule is attached to data
entry rather than to the financial behaviour, the product optimises for a metric the user
does not care about, and it collapses the moment they miss a day.

- Bayuk, J. and Altobello, S. A. (2019). Can gamification improve financial behavior? The
  moderating role of app expertise. *International Journal of Bank Marketing* 37(4).
  [paper](https://www.emerald.com/ijbm/article/37/4/951/110545/Can-gamification-improve-financial-behavior-The)
- Agrawal (2025). An Evaluation of Gamification on Financial Conduct in Relation to the
  Effectiveness of Behavioral Traits. *Financial Planning Review*.
  [paper](https://onlinelibrary.wiley.com/doi/full/10.1002/cfp2.70016)

---

## 14. Frameworks with weaker evidence than their popularity suggests

**50/30/20.** Coined by Elizabeth Warren and Amelia Warren Tyagi in *All Your Worth* (2005)
as the Balanced Money Formula. Its merit is memorability, and a fixed allocation does
protect savings before discretionary spending. Its 50 per cent needs ceiling is not
reachable for many renters in expensive cities or for households carrying significant debt,
so shipping it as a default sets some users up to fail against a number that was never about
them.

**Zero-based and envelope budgeting.** Well grounded in the partitioning mechanism in
section 4, and the highest-friction model in practice. The complaints in
[04-user-reviews.md](04-user-reviews.md) are consistent: it works and it is exhausting,
and the exhaustion is what people quit over.

---

## 15. Indonesian context

Financial literacy and inclusion, from the OJK and BPS national survey (SNLIK 2025,
describing conditions in 2024): the financial literacy index reached 66.46 per cent and the
inclusion index 80.51 per cent, up from 65.43 and 75.02 per cent in SNLIK 2024. Sharia
financial literacy was 43.42 per cent, with sharia inclusion far lower, so there is a
sizeable gap between conventional and sharia coverage. Read together with the Fernandes
meta-analysis, that inclusion figure matters more than the literacy figure: people have
accounts, and knowledge alone will not change what they do with them.

Payment rails: QRIS is the dominant behavioural fact. Reported figures vary by source and
period, and Bank Indonesia's own releases are the ones to cite in any document that leaves
the team, but the direction is not in dispute: QRIS volume grew at triple-digit annual rates
through 2025, users are in the tens of millions, and merchants in the tens of millions,
predominantly micro and small businesses. Practically, that means a large share of everyday
Indonesian spending now happens through a QR scan from an e-wallet or a bank app, which is
both an opportunity (a machine-readable moment) and a design constraint (there is no
statement to import, the record lives inside each wallet app).

Aggregation: Indonesia has an open finance layer, with Bank Indonesia's SNAP payment open
API standard and providers including Brick, Ayoconnect and Finantier offering account
aggregation across banks and e-wallets. None of the seven named apps use it. For a
manual-first product it is worth knowing the option exists and that it carries cost,
compliance and the breakage the benchmark reviews describe.

- OJK and BPS, SNLIK 2025.
  [OJK page](https://ojk.go.id/id/Fungsi-Utama/Perilaku-Pelaku-Usaha-Jasa-Keuangan/SNLIK/Pages/SNLIK-2025.aspx) ·
  [joint press release](https://ojk.go.id/id/berita-dan-kegiatan/siaran-pers/Pages/OJK-dan-BPS-Umumkan-Hasil-Survei-Nasional-Literasi-Dan-Inklusi-Keuangan-SNLIK-Tahun-2025.aspx)
- Ayoconnect on Bank Indonesia's SNAP open API standard.
  [explainer](https://www.ayoconnect.com/blog/get-to-know-open-banking-open-finance-in-indonesia)
