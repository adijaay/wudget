import 'package:drift/drift.dart';

import '../domain/goal.dart';
import 'database.dart';
import 'wallets_repository.dart';

/// A goal with its progress, read from its wallet's balance.
class GoalWithProgress {
  const GoalWithProgress({required this.goal, required this.savedMinor});
  final Goal goal;
  final int savedMinor;

  int get percent => goalPercent(savedMinor: savedMinor, targetMinor: goal.targetMinor);
  int get reached => milestoneReached(savedMinor: savedMinor, targetMinor: goal.targetMinor);
}

class GoalsRepository {
  GoalsRepository(this._db);
  final WudgetDatabase _db;

  Future<void> create({
    required String id,
    required String name,
    required int targetMinor,
    required String accountId,
  }) {
    return _db.into(_db.goals).insert(GoalsCompanion.insert(
          id: id,
          name: name,
          targetMinor: targetMinor,
          accountId: accountId,
          updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ));
  }

  Future<void> delete(String id) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return (_db.update(_db.goals)..where((g) => g.id.equals(id)))
        .write(GoalsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Stream<List<Goal>> watchGoals() =>
      (_db.select(_db.goals)..where((g) => g.deletedAt.isNull())).watch();

  /// Announces each milestone once: anything reached above the stored
  /// [Goal.notifiedMilestone] is passed to [notify], then recorded.
  Future<void> announceMilestones(Future<void> Function(int id, String body) notify) async {
    final balances = await WalletsRepository(_db).watchWallets().first;
    final rows = await (_db.select(_db.goals)..where((g) => g.deletedAt.isNull())).get();
    for (final g in joinGoals(rows, balances)) {
      final percent = milestoneToAnnounce(reached: g.reached, announced: g.goal.notifiedMilestone);
      if (percent == null) continue;
      await (_db.update(_db.goals)..where((r) => r.id.equals(g.goal.id)))
          .write(GoalsCompanion(notifiedMilestone: Value(percent)));
      await notify(g.goal.id.hashCode & 0x7fffffff, milestoneMessage(goalName: g.goal.name, percent: percent));
    }
  }
}

/// Pairs each goal with its wallet's balance.
List<GoalWithProgress> joinGoals(List<Goal> rows, List<WalletWithBalance> balances) {
  final byId = {for (final w in balances) w.account.id: w.balanceMinor};
  return [for (final g in rows) GoalWithProgress(goal: g, savedMinor: byId[g.accountId] ?? 0)];
}
