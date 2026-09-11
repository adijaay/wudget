/// Proposes a per-period budget from a trailing average daily rate, per
/// plan/01-features.md: "the app observes for the first two weeks, then
/// proposes a budget from the user's own history... the user edits rather
/// than authors." [historyWindowDays] is the number of days the lookback
/// actually covers (which may be less than the requested window near the
/// start of the user's history) — the denominator, not the numerator, so a
/// category spent on only twice in 28 days still gets an honest average
/// rather than one scaled as if every day had spend.
int proposeBudgetMinor({
  required int spendMinor,
  required int historyWindowDays,
  required int periodLengthDays,
}) {
  if (historyWindowDays <= 0) return 0;
  return (spendMinor / historyWindowDays * periodLengthDays).round();
}

/// Proposals for every category key with real spend in the lookback
/// window. A key absent from [spendByKey] has no history to propose from
/// and is omitted entirely — plan/05-sprints.md Sprint 10's "no user is
/// ever shown a blank budget field" means never proposed, never fabricated
/// as zero, not shown with an empty field.
Map<String, int> proposeBudgets({
  required Map<String, int> spendByKey,
  required int historyWindowDays,
  required int periodLengthDays,
}) {
  return {
    for (final entry in spendByKey.entries)
      if (entry.value > 0)
        entry.key: proposeBudgetMinor(
          spendMinor: entry.value,
          historyWindowDays: historyWindowDays,
          periodLengthDays: periodLengthDays,
        ),
  };
}
