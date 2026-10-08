import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../data/budget_history_queries.dart';
import '../data/budgets_repository.dart';
import '../data/categories_repository.dart';
import '../data/capture_queries.dart';
import '../data/category_rank_queries.dart';
import '../data/database.dart';
import '../data/feature_flags_repository.dart';
import '../data/goals_repository.dart';
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

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider));
});

final walletsRepositoryProvider = Provider<WalletsRepository>((ref) {
  return WalletsRepository(ref.watch(databaseProvider));
});

/// Kantong's balances joined across every posting in the ledger. It lives
/// here, not in a `StreamBuilder(stream: repo.watchWallets())`, because a
/// stream built inside `build` is a new stream on every rebuild: the
/// StreamBuilder drops back to "no data yet" each time, which on a device
/// holding 10,000 transactions left the tab on a spinner that never resolved.
///
/// ponytail: only the expensive stream is hoisted. The other
/// `StreamBuilder(stream: ...)` call sites in lib/features read categories
/// and accounts, tens of rows that resolve inside one frame, so the same
/// shape is invisible there. Hoist one if a table it reads ever grows.
final walletBalancesProvider = StreamProvider<List<WalletWithBalance>>((ref) {
  return ref.watch(walletsRepositoryProvider).watchWallets();
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(databaseProvider));
});

final _goalRowsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchGoals();
});

/// Goals with progress, loading until both goals and balances have arrived.
final goalsProvider = Provider<AsyncValue<List<GoalWithProgress>>>((ref) {
  final rows = ref.watch(_goalRowsProvider);
  final wallets = ref.watch(walletBalancesProvider);
  if (rows.hasError) return AsyncValue.error(rows.error!, rows.stackTrace!);
  if (wallets.hasError) return AsyncValue.error(wallets.error!, wallets.stackTrace!);
  if (!rows.hasValue || !wallets.hasValue) return const AsyncValue.loading();
  return AsyncValue.data(joinGoals(rows.value!, wallets.value!));
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

final categoryRankQueriesProvider = Provider<CategoryRankQueries>((ref) {
  return CategoryRankQueries(ref.watch(databaseProvider));
});

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return FeatureFlagsRepository(ref.watch(databaseProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(databaseProvider));
});

/// Pace-first (the plan's default) unless the user's device has the flag
/// flipped for the framing experiment — plan/05-sprints.md Sprint 11.
final paceFirstFramingProvider = StreamProvider<bool>((ref) {
  return ref.watch(featureFlagsRepositoryProvider).watchBool(paceFirstFlagKey, defaultValue: true);
});

final periodStartDayProvider = StreamProvider<int>((ref) {
  return ref.watch(settingsRepositoryProvider).watchPeriodStartDay();
});

final settingsRowProvider = StreamProvider<AppSetting?>((ref) {
  return ref.watch(settingsRepositoryProvider).watchRow();
});

/// How many periods forward (+) or back (-) from the one containing today.
/// The period selector on every governed surface reads and writes this.
final periodOffsetProvider = StateProvider<int>((ref) => 0);

/// The period every governed surface (Pantau, and later Catat) renders
/// against — see plan/05-sprints.md Sprint 8, "period selector control that
/// governs every surface below it".
final currentPeriodProvider = Provider<Period>((ref) {
  final startDay = ref.watch(periodStartDayProvider).valueOrNull ?? defaultPeriodStartDay;
  final row = ref.watch(settingsRowProvider).valueOrNull;
  final offset = ref.watch(periodOffsetProvider);
  var period = effectivePeriod(
    todayDayBucket(),
    monthStartDay: startDay,
    customStart: row?.customPeriodStart,
    customEndExclusive: row?.customPeriodEndExclusive,
  );
  for (var i = 0; i < offset; i++) {
    period = period.next;
  }
  for (var i = 0; i > offset; i--) {
    period = period.previous;
  }
  return period;
});
