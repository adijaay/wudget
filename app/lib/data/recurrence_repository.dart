import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/recurrence.dart';
import 'database.dart';
import 'postings_repository.dart';

const _uuid = Uuid();

/// The transaction a recurrence materialises each occurrence — everything
/// `PostingsRepository.insertTransaction` needs except the amount and date,
/// which the recurrence rule and (for a `varies` item) its expected range
/// supply. Stored as `Recurrences.templateJson`.
class RecurrenceTemplate {
  const RecurrenceTemplate({
    required this.kind,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    required this.currency,
    this.fixedAmountMinor,
  });

  final String kind; // expense|income|transfer
  final String? accountId;
  final String? toAccountId; // transfer only
  final String? categoryId; // null for a transfer
  final String? note;
  final String currency;

  /// Used when the recurrence's `amountMode` is `fixed`; ignored (and
  /// typically null) for `varies`.
  final int? fixedAmountMinor;

  Map<String, Object?> toJson() => {
        'kind': kind,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'categoryId': categoryId,
        'note': note,
        'currency': currency,
        'fixedAmountMinor': fixedAmountMinor,
      };

  factory RecurrenceTemplate.fromJson(Map<String, Object?> json) => RecurrenceTemplate(
        kind: json['kind'] as String,
        accountId: json['accountId'] as String?,
        toAccountId: json['toAccountId'] as String?,
        categoryId: json['categoryId'] as String?,
        note: json['note'] as String?,
        currency: json['currency'] as String,
        fixedAmountMinor: json['fixedAmountMinor'] as int?,
      );
}

/// Creates, edits and materialises recurring items — plan/05-sprints.md
/// Sprint 12. The date math lives in domain/recurrence.dart, pure and
/// tested on its own; this class is the DB-touching half: turning a rule
/// plus its overrides into real `transactions` rows.
class RecurrenceRepository {
  RecurrenceRepository(this._db) : _postings = PostingsRepository(_db);
  final WudgetDatabase _db;
  final PostingsRepository _postings;

  Future<String> create({
    required RecurrenceTemplate template,
    required RecurrenceRule rule,
    String amountMode = 'fixed',
    int? expectedMinMinor,
    int? expectedMaxMinor,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.into(_db.recurrences).insert(RecurrencesCompanion.insert(
          id: id,
          templateJson: jsonEncode(template.toJson()),
          freq: rule.freq.name,
          intervalN: Value(rule.intervalN),
          byMonthDay: Value(rule.byMonthDay),
          byWeekday: Value(rule.byWeekday),
          weekendRule: Value(rule.weekendRule.name),
          amountMode: Value(amountMode),
          expectedMinMinor: Value(expectedMinMinor),
          expectedMaxMinor: Value(expectedMaxMinor),
          startsOn: rule.startsOn,
          endsOn: Value(rule.endsOn),
          // Nothing is generated yet — materialisation starts strictly
          // after this watermark.
          generatedUntil: rule.startsOn - 1,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> skipInstance(String recurrenceId, int logicalInstanceDate) {
    return _db.into(_db.recurrenceOverrides).insertOnConflictUpdate(
          RecurrenceOverridesCompanion.insert(
            recurrenceId: recurrenceId,
            instanceDate: logicalInstanceDate,
            action: 'skip',
          ),
        );
  }

  Future<void> moveInstance(String recurrenceId, int logicalInstanceDate, int newDate) {
    return _db.into(_db.recurrenceOverrides).insertOnConflictUpdate(
          RecurrenceOverridesCompanion.insert(
            recurrenceId: recurrenceId,
            instanceDate: logicalInstanceDate,
            action: 'move',
            newDate: Value(newDate),
          ),
        );
  }

  Future<void> amendInstance(String recurrenceId, int logicalInstanceDate, int newAmountMinor) {
    return _db.into(_db.recurrenceOverrides).insertOnConflictUpdate(
          RecurrenceOverridesCompanion.insert(
            recurrenceId: recurrenceId,
            instanceDate: logicalInstanceDate,
            action: 'amend',
            newAmountMinor: Value(newAmountMinor),
          ),
        );
  }

  /// Materialises every active recurrence forward to [toDayInclusive].
  /// Idempotent: a rule whose watermark already covers [toDayInclusive]
  /// generates nothing on this call, so a missed run followed by a catch-up
  /// run — or two overlapping runs — can never generate the same month of
  /// entries twice at once (plan/03-architecture.md's stated failure mode).
  Future<void> materializeAll({required int toDayInclusive}) async {
    final rows = await (_db.select(_db.recurrences)..where((r) => r.deletedAt.isNull())).get();
    for (final row in rows) {
      await _materializeOne(row, toDayInclusive);
    }
  }

  Future<void> _materializeOne(Recurrence row, int toDayInclusive) async {
    if (toDayInclusive <= row.generatedUntil) return;

    final rule = RecurrenceRule(
      freq: RecurrenceFreq.values.byName(row.freq),
      intervalN: row.intervalN,
      byMonthDay: row.byMonthDay,
      byWeekday: row.byWeekday,
      weekendRule: WeekendRule.values.byName(row.weekendRule),
      startsOn: row.startsOn,
      endsOn: row.endsOn,
    );
    final template = RecurrenceTemplate.fromJson(jsonDecode(row.templateJson) as Map<String, Object?>);

    final logicalDays =
        rule.logicalOccurrencesThrough(toDayInclusive).where((d) => d > row.generatedUntil).toList();

    if (logicalDays.isNotEmpty) {
      final overrides = await (_db.select(_db.recurrenceOverrides)
            ..where((o) => o.recurrenceId.equals(row.id) & o.instanceDate.isIn(logicalDays)))
          .get();
      final overrideByDate = {for (final o in overrides) o.instanceDate: o};

      for (final logicalDay in logicalDays) {
        final override = overrideByDate[logicalDay];
        if (override?.action == 'skip') continue;

        final actualDay = (override?.action == 'move' ? override?.newDate : null) ??
            rule.shiftForWeekend(logicalDay);
        final amountMinor = (override?.action == 'amend' ? override?.newAmountMinor : null) ??
            template.fixedAmountMinor ??
            row.expectedMinMinor ??
            0;

        await _insertProjectedInstance(
          recurrenceId: row.id,
          template: template,
          occurredOnDay: actualDay,
          amountMinor: amountMinor,
        );
      }
    }

    await (_db.update(_db.recurrences)..where((r) => r.id.equals(row.id)))
        .write(RecurrencesCompanion(generatedUntil: Value(toDayInclusive)));
  }

  Future<void> _insertProjectedInstance({
    required String recurrenceId,
    required RecurrenceTemplate template,
    required int occurredOnDay,
    required int amountMinor,
  }) async {
    final id = '${recurrenceId}_$occurredOnDay';
    final occurredAtMillis = occurredOnDay * 86400000;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final postings = <PostingsCompanion>[];
    if (template.kind == 'transfer') {
      postings.add(PostingsCompanion.insert(
        id: '${id}_from',
        transactionId: id,
        accountId: Value(template.accountId),
        amountMinor: -amountMinor,
        currency: template.currency,
        baseAmountMinor: -amountMinor,
      ));
      postings.add(PostingsCompanion.insert(
        id: '${id}_to',
        transactionId: id,
        accountId: Value(template.toAccountId),
        amountMinor: amountMinor,
        currency: template.currency,
        baseAmountMinor: amountMinor,
      ));
    } else {
      final sign = template.kind == 'expense' ? -1 : 1;
      postings.add(PostingsCompanion.insert(
        id: '${id}_a',
        transactionId: id,
        accountId: Value(template.accountId),
        amountMinor: sign * amountMinor,
        currency: template.currency,
        baseAmountMinor: sign * amountMinor,
      ));
      postings.add(PostingsCompanion.insert(
        id: '${id}_c',
        transactionId: id,
        categoryId: Value(template.categoryId),
        amountMinor: -sign * amountMinor,
        currency: template.currency,
        baseAmountMinor: -sign * amountMinor,
      ));
    }

    await _postings.insertTransaction(
      transaction: TransactionsCompanion.insert(
        id: id,
        kind: template.kind,
        occurredAt: occurredAtMillis,
        tzOffsetMinutes: 0,
        note: Value(template.note),
        recurrenceId: Value(recurrenceId),
        isProjected: const Value(true),
        updatedAt: now,
      ),
      postings: postings,
    );
  }

  /// "This and all future" edit: ends the existing rule the day before
  /// [effectiveFrom] and starts a new one there with [newTemplate]/[newRule]
  /// — plan/03-architecture.md: "Editing the series changes the rule."
  /// Past instances (already materialised, or governed by the old rule
  /// before [effectiveFrom]) are untouched; this is what distinguishes a
  /// series edit from [amendInstance]/[moveInstance], which change exactly
  /// one occurrence and leave the rule alone.
  Future<String> editFutureFrom({
    required String recurrenceId,
    required int effectiveFrom,
    required RecurrenceTemplate newTemplate,
    required RecurrenceRule newRule,
    String amountMode = 'fixed',
    int? expectedMinMinor,
    int? expectedMaxMinor,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.recurrences)..where((r) => r.id.equals(recurrenceId))).write(
      RecurrencesCompanion(
        endsOn: Value(effectiveFrom - 1),
        generatedUntil: Value(effectiveFrom - 1),
        updatedAt: Value(now),
      ),
    );
    return create(
      template: newTemplate,
      rule: newRule,
      amountMode: amountMode,
      expectedMinMinor: expectedMinMinor,
      expectedMaxMinor: expectedMaxMinor,
    );
  }

  /// Clears `is_projected` on a materialised instance — the user confirmed
  /// it happened as forecast. From then on it's an actual transaction,
  /// counted everywhere `isActualTransaction` is (data/actual_transactions.dart).
  Future<void> confirmInstance(String transactionId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
        .write(TransactionsCompanion(isProjected: const Value(false), updatedAt: Value(now)));
  }
}
