import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/capture_queries.dart';
import '../data/database.dart';
import '../data/ledger_queries.dart';
import '../data/postings_repository.dart';
import '../data/wallets_repository.dart';

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
