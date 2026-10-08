import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/goal.dart';

void main() {
  test('milestoneReached picks the highest quarter reached', () {
    expect(milestoneReached(savedMinor: 0, targetMinor: 1000), 0);
    expect(milestoneReached(savedMinor: 249, targetMinor: 1000), 0);
    expect(milestoneReached(savedMinor: 250, targetMinor: 1000), 25);
    expect(milestoneReached(savedMinor: 760, targetMinor: 1000), 75);
    expect(milestoneReached(savedMinor: 5000, targetMinor: 1000), 100);
    expect(milestoneReached(savedMinor: 5000, targetMinor: 0), 0);
  });

  test('goalPercent clamps to 0..100', () {
    expect(goalPercent(savedMinor: 333, targetMinor: 1000), 33);
    expect(goalPercent(savedMinor: -50, targetMinor: 1000), 0);
    expect(goalPercent(savedMinor: 2000, targetMinor: 1000), 100);
  });

  test('milestoneToAnnounce only reports something new', () {
    expect(milestoneToAnnounce(reached: 50, announced: 25), 50);
    expect(milestoneToAnnounce(reached: 50, announced: 50), isNull);
    expect(milestoneToAnnounce(reached: 25, announced: 50), isNull);
    expect(milestoneToAnnounce(reached: 0, announced: 0), isNull);
  });

  test('milestoneMessage never leaves a hole for a blank name', () {
    expect(milestoneMessage(goalName: 'Dana darurat', percent: 50), 'Terkumpul 50 persen dari Dana darurat.');
    expect(milestoneMessage(goalName: ' ', percent: 100), 'Targetmu sudah penuh.');
  });
}
