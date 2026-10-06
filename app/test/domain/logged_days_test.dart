import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/period.dart';

void main() {
  // 25 Sep to 24 Oct 2026, today 7 Oct.
  final period = Period.containing(DateTime.utc(2026, 10, 7).difference(DateTime.utc(1970)).inDays, monthStartDay: 25);
  final start = period.startDay;
  final today = DateTime.utc(2026, 10, 7).difference(DateTime.utc(1970)).inDays;

  test('empty period counts zero', () {
    expect(loggedDays(period, const []), 0);
  });

  test('every day logged counts every day, duplicates once', () {
    final days = [for (var d = start; d < period.endDayExclusive; d++) ...[d, d]];
    expect(loggedDays(period, days), 30);
  });

  test('gaps are not counted, nor days outside the period', () {
    expect(loggedDays(period, [start - 1, start, start + 2, start + 5, period.endDayExclusive]), 3);
  });

  test('today not yet logged counts only the days before it', () {
    expect(loggedDays(period, [for (var d = start; d < today; d++) d]), today - start);
  });
}
