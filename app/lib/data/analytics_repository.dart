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
}
