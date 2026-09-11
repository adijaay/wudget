import 'package:drift/drift.dart';

import 'database.dart';

/// A transaction counts as real, recorded activity — not soft-deleted, and
/// not a recurrence engine's forecast of a future instance. Every balance,
/// spend total, budget pace and ranked list reads through this, per
/// plan/03-architecture.md: "Projected rows are excluded from actual
/// spending everywhere, by a shared query predicate rather than by each
/// call site remembering." Confirming a projected instance
/// (RecurrenceRepository.confirmInstance) clears `is_projected`, at which
/// point it starts counting here with no other code needing to change.
Expression<bool> isActualTransaction(Transactions t) => t.deletedAt.isNull() & t.isProjected.equals(false);
