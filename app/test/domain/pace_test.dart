import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/pace.dart';

String _fmt(int minor) => 'Rp${(minor / 1000).round()}rb';

void main() {
  group('computePace', () {
    test('forecast extrapolates linearly from elapsed fraction', () {
      final pace = computePace(daysElapsed: 10, totalDaysInPeriod: 30, spendMinor: 100000, baselineTotalMinor: null);
      expect(pace.elapsedFraction, closeTo(1 / 3, 0.0001));
      expect(pace.forecastTotalMinor, 300000);
    });

    test('day one of a period is elapsed fraction 1/totalDays, not zero', () {
      final pace = computePace(daysElapsed: 1, totalDaysInPeriod: 30, spendMinor: 10000, baselineTotalMinor: null);
      expect(pace.elapsedFraction, closeTo(1 / 30, 0.0001));
    });
  });

  group('status and spendFractionOfBaseline', () {
    test('null baseline means status and fraction are both null, not zero', () {
      final pace = computePace(daysElapsed: 15, totalDaysInPeriod: 30, spendMinor: 50000, baselineTotalMinor: null);
      expect(pace.spendFractionOfBaseline, isNull);
      expect(pace.status, isNull);
      expect(pace.sentence(_fmt), isNull);
    });

    test('spending faster than elapsed time, relative to baseline, is overBaseline', () {
      // 50% of days elapsed, but already 80% of last period's total spent.
      final pace = computePace(daysElapsed: 15, totalDaysInPeriod: 30, spendMinor: 80000, baselineTotalMinor: 100000);
      expect(pace.status, PaceStatus.overBaseline);
      expect(pace.sentence(_fmt), contains('lebih tinggi dari biasanya'));
    });

    test('spending slower than elapsed time, relative to baseline, is underBaseline', () {
      final pace = computePace(daysElapsed: 15, totalDaysInPeriod: 30, spendMinor: 20000, baselineTotalMinor: 100000);
      expect(pace.status, PaceStatus.underBaseline);
      expect(pace.sentence(_fmt), contains('lebih hemat'));
    });

    test('within the tolerance band is onBaseline', () {
      // 50% elapsed, 52% of baseline spent — inside the 10pp tolerance.
      final pace = computePace(daysElapsed: 15, totalDaysInPeriod: 30, spendMinor: 52000, baselineTotalMinor: 100000);
      expect(pace.status, PaceStatus.onBaseline);
    });

    test('spend beyond the entire baseline still reports a real fraction, over 1.0', () {
      final pace = computePace(daysElapsed: 15, totalDaysInPeriod: 30, spendMinor: 150000, baselineTotalMinor: 100000);
      expect(pace.spendFractionOfBaseline, 1.5);
      expect(pace.status, PaceStatus.overBaseline);
    });
  });
}
