import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/budget_history_queries.dart';
import '../data/budgets_repository.dart';
import '../data/capture_queries.dart';
import '../data/database.dart';
import '../data/ledger_queries.dart';
import '../data/period_aggregate_queries.dart';
import '../data/postings_repository.dart';
import '../data/settings_repository.dart';
import '../data/wallets_repository.dart';
import '../domain/period.dart';

/// One database for the app's lifetime. Overridden in tests with an
/// in-memory instance; nothing else should construct a WudgetDatabase.
final databaseProvider = Provider<WudgetDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden at app root');
});

final postingsRepositoryProvider = Provider<PostingsRepository>((ref) {
  return PostingsRepository(ref.watch(databaseProvider));
});

final captureQueriesProvider = Provider<CaptureQueries>((ref) {
  return CaptureQueries(ref.watch(databaseProvider));
});

final walletsRepositoryProvider = Provider<WalletsRepository>((ref) {
  return WalletsRepository(ref.watch(databaseProvider));
});

final ledgerQueriesProvider = Provider<LedgerQueries>((ref) {
  return LedgerQueries(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final periodAggregateQueriesProvider = Provider<PeriodAggregateQueries>((ref) {
  return PeriodAggregateQueries(ref.watch(databaseProvider));
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(databaseProvider));
});

final budgetHistoryQueriesProvider = Provider<BudgetHistoryQueries>((ref) {
  return BudgetHistoryQueries(ref.watch(databaseProvider));
});

final periodStartDayProvider = StreamProvider<int>((ref) {
  return ref.watch(settingsRepositoryProvider).watchPeriodStartDay();
});

/// How many periods forward (+) or back (-) from the one containing today.
/// The period selector on every governed surface reads and writes this.
final periodOffsetProvider = StateProvider<int>((ref) => 0);

/// The period every governed surface (Pantau, and later Catat) renders
/// against — see plan/05-sprints.md Sprint 8, "period selector control that
/// governs every surface below it".
final currentPeriodProvider = Provider<Period>((ref) {
  final startDay = ref.watch(periodStartDayProvider).valueOrNull ?? 1;
  final offset = ref.watch(periodOffsetProvider);
  final today = DateTime.now();
  var period = Period.containing(
    DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(1970, 1, 1)).inDays,
    monthStartDay: startDay,
  );
  for (var i = 0; i < offset; i++) {
    period = period.next;
  }
  for (var i = 0; i > offset; i--) {
    period = period.previous;
  }
  return period;
});
