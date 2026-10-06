import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

const _uuid = Uuid();

/// Local, append-only event log — the framing experiment's measurement
/// hooks (plan/05-sprints.md Sprint 11). No analytics backend exists in a
/// local-first, no-account app, so these are read back with a direct query
/// during the weekly dogfooding review, not shipped anywhere.
class AnalyticsRepository {
  AnalyticsRepository(this._db);
  final WudgetDatabase _db;

  Future<void> logEvent(String name, {Map<String, Object?>? props}) {
    return _db.into(_db.analyticsEvents).insert(AnalyticsEventsCompanion.insert(
          id: _uuid.v4(),
          name: name,
          propsJson: Value(props == null ? null : jsonEncode(props)),
          occurredAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ));
  }

  /// All logged events, oldest first — for the weekly review, or a test.
  Future<List<AnalyticsEvent>> all() {
    return (_db.select(_db.analyticsEvents)
          ..orderBy([(e) => OrderingTerm.asc(e.occurredAt)]))
        .get();
  }

  /// The last [count] home insights shown, newest first; the picker's memory.
  Future<List<({int day, String key})>> recentInsights({int count = 7}) async {
    final rows = await (_db.select(_db.analyticsEvents)
          ..where((e) => e.name.equals('insight_shown'))
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])
          ..limit(count))
        .get();
    return [
      for (final r in rows)
        if (jsonDecode(r.propsJson ?? '{}') case {'day': final int day, 'key': final String key})
          (day: day, key: key),
    ];
  }

  /// Local times of capture saves since [since]; the reminder's usual hour.
  Future<List<DateTime>> captureSaveTimesSince(DateTime since) async {
    final rows = await (_db.select(_db.analyticsEvents)
          ..where((e) =>
              e.name.equals('capture_save') & e.occurredAt.isBiggerOrEqualValue(since.toUtc().millisecondsSinceEpoch)))
        .get();
    return [for (final r in rows) DateTime.fromMillisecondsSinceEpoch(r.occurredAt)];
  }

  /// Whether the comeback screen was already shown for the gap that began
  /// after [lastEntryDay]; one gap, one welcome.
  Future<bool> comebackShownFor(int lastEntryDay) async {
    final rows = await (_db.select(_db.analyticsEvents)..where((e) => e.name.equals('comeback_shown'))).get();
    return rows.any((r) => (jsonDecode(r.propsJson ?? '{}') as Map)['lastEntryDay'] == lastEntryDay);
  }

  /// Open-to-save milliseconds of the last [count] captures, newest first.
  Future<List<int>> recentCaptureSaveMs({int count = 20}) async {
    final rows = await (_db.select(_db.analyticsEvents)
          ..where((e) => e.name.equals('capture_save'))
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])
          ..limit(count))
        .get();
    return [
      for (final r in rows)
        if ((jsonDecode(r.propsJson ?? '{}') as Map)['ms'] case final int ms) ms,
    ];
  }
}

int? medianMs(List<int> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) ~/ 2;
}
