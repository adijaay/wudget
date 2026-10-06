import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../domain/period.dart';
import 'actual_transactions.dart';
import 'category_rank_queries.dart';
import 'database.dart';

const _millisPerDay = 86400000;
const _lookbackDays = 90;

/// Below this many entries a ranking is mostly noise, so callers keep the
/// default order (plan/06-retention-sprints.md, R1 risk).
const minEntriesForRanking = 10;

/// A past entry worth repeating in one tap: the home quick chips.
class QuickChip {
  const QuickChip({
    required this.note,
    required this.categoryId,
    required this.topCategoryId,
    required this.categoryName,
    required this.hueIndex,
    required this.amountMinor,
  });
  final String note;

  /// The category the entry was recorded against, possibly a subcategory.
  final String categoryId;
  final String topCategoryId;
  final String categoryName;
  final int hueIndex;
  final int amountMinor;

  String? get subcategoryId => categoryId == topCategoryId ? null : categoryId;
}

class _Entry {
  _Entry(this.hour, this.note, this.category, this.amountMinor);
  final int hour;
  final String? note;
  final Category category;
  final int amountMinor;

  String get topKey => category.parentId ?? category.id;
}

/// Read-only queries behind the capture sheet's category order and the home
/// quick chips. Scoring happens in Dart over 90 days of entries, which at
/// personal-finance volumes is a few thousand rows at most.
class CaptureQueries {
  CaptureQueries(this._db);
  final WudgetDatabase _db;

  /// An entry within an hour of [now]'s hour counts three times, so lunch
  /// history puts Makan first at 12:00 and Transport first at 07:00.
  /// ponytail: fixed 3x weight, tune once real capture logs exist.
  static int _weight(int entryHour, DateTime now) {
    final d = (entryHour - now.hour).abs();
    return math.min(d, 24 - d) <= 1 ? 3 : 1;
  }

  Future<List<_Entry>> _recent(String kind, DateTime now) async {
    final since = now.toUtc().millisecondsSinceEpoch - _lookbackDays * _millisPerDay;
    final rows = await (_db.select(_db.postings).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.postings.transactionId)),
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.postings.categoryId)),
    ])
          ..where(_db.transactions.kind.equals(kind) &
              isActualTransaction(_db.transactions) &
              _db.transactions.occurredAt.isBiggerOrEqualValue(since)))
        .get();
    return [
      for (final row in rows)
        () {
          final tx = row.readTable(_db.transactions);
          final local = DateTime.fromMillisecondsSinceEpoch(
            tx.occurredAt + tx.tzOffsetMinutes * 60000,
            isUtc: true,
          );
          return _Entry(
            local.hour,
            tx.note,
            row.readTable(_db.categories),
            row.readTable(_db.postings).amountMinor.abs(),
          );
        }(),
    ];
  }

  /// Top-level category ids of [kind], best first for the hour of [now].
  /// Empty below [minEntriesForRanking] entries: the caller keeps its
  /// default order.
  Future<List<String>> rankedCategoryIds(String kind, DateTime now) async {
    final entries = await _recent(kind, now);
    if (entries.length < minEntriesForRanking) return const [];
    final score = <String, int>{};
    for (final e in entries) {
      score[e.topKey] = (score[e.topKey] ?? 0) + _weight(e.hour, now);
    }
    return (score.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!)));
  }

  /// Past expenses with a note, grouped by note, category and amount, ranked
  /// the same way as [rankedCategoryIds].
  Future<List<QuickChip>> quickChips(DateTime now, {int limit = 3}) async {
    final entries = await _recent('expense', now);
    final score = <String, int>{};
    final chips = <String, _Entry>{};
    for (final e in entries) {
      final note = e.note?.trim() ?? '';
      if (note.isEmpty) continue;
      final key = '$note|${e.category.id}|${e.amountMinor}';
      score[key] = (score[key] ?? 0) + _weight(e.hour, now);
      chips[key] = e;
    }
    final keys = score.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!));
    final topIds = {for (final k in keys.take(limit)) chips[k]!.topKey};
    final tops = {
      for (final c in await (_db.select(_db.categories)..where((c) => c.id.isIn(topIds))).get()) c.id: c,
    };
    return [
      for (final k in keys.take(limit))
        QuickChip(
          note: chips[k]!.note!.trim(),
          categoryId: chips[k]!.category.id,
          topCategoryId: chips[k]!.topKey,
          categoryName: chips[k]!.category.name,
          hueIndex: tops[chips[k]!.topKey]?.hueIndex ?? chips[k]!.category.hueIndex,
          amountMinor: chips[k]!.amountMinor,
        ),
    ];
  }

  /// Where an entry goes when the sheet does not name a wallet: the oldest
  /// wallet still in use. Wallets stay in the data, just not in capture.
  Future<String> defaultAccountId() async {
    final row = await (_db.select(_db.accounts)
          ..where((a) => a.archivedAt.isNull() & a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.rowId)])
          ..limit(1))
        .getSingle();
    return row.id;
  }

  /// The kantong's budget minus this period's spend in it, or null when the
  /// category has no budget.
  Future<int?> kantongRemaining(String topCategoryId, Period period) async {
    final budget = await (_db.select(_db.budgets)..where((b) => b.key.equals(topCategoryId))).getSingleOrNull();
    if (budget == null) return null;
    final ranks = await CategoryRankQueries(_db).rankedSpend(period.startDay, period.endDayExclusive);
    final spent = ranks.where((r) => r.key == topCategoryId).firstOrNull?.amountMinor ?? 0;
    return budget.amountMinor - spent;
  }
}
