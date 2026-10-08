/// A savings goal's progress, and which quarter of the way there it has
/// reached. Pure so the milestone arithmetic is tested without a database.
library;

/// The four points a goal is announced at, as fractions of the target.
const milestonePercents = [25, 50, 75, 100];

/// The highest milestone already reached at [savedMinor] of
/// [targetMinor], or 0 when the first quarter has not been reached.
/// A target of zero has no milestones: there is no fraction of nothing.
int milestoneReached({required int savedMinor, required int targetMinor}) {
  if (targetMinor <= 0) return 0;
  var reached = 0;
  for (final percent in milestonePercents) {
    if (savedMinor * 100 >= targetMinor * percent) reached = percent;
  }
  return reached;
}

/// Progress as a whole percent, clamped to 0..100. A wallet that has
/// overshot its target reads 100 rather than more, because "how far past"
/// is not the question this answers.
int goalPercent({required int savedMinor, required int targetMinor}) {
  if (targetMinor <= 0) return 0;
  final percent = savedMinor * 100 ~/ targetMinor;
  return percent.clamp(0, 100);
}

/// The milestone to celebrate now: the highest reached that has not
/// already been announced. Null when there is nothing new to say, which
/// is the common case and must stay silent rather than repeat.
int? milestoneToAnnounce({required int reached, required int announced}) {
  if (reached <= announced || reached == 0) return null;
  return reached;
}

/// The sentence a milestone notification carries. Named here rather than
/// built at the call site so the wording is testable, and so a goal with a
/// blank name cannot produce a sentence with a hole in it.
String milestoneMessage({required String goalName, required int percent}) {
  final name = goalName.trim().isEmpty ? 'Targetmu' : goalName.trim();
  return percent >= 100
      ? '$name sudah penuh.'
      : 'Terkumpul $percent persen dari $name.';
}