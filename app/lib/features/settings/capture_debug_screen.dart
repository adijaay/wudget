import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/analytics_repository.dart';
import '../../data/daily_totals_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/period.dart';

/// On in debug and profile builds; a release build needs the flag set by hand.
const captureDebugFlagKey = 'capture_debug';

final captureDebugFlagProvider = StreamProvider<bool>((ref) {
  return ref.watch(featureFlagsRepositoryProvider).watchBool(captureDebugFlagKey, defaultValue: !kReleaseMode);
});

typedef CaptureDebugStats = ({int? medianMs, int saves, int loggedDays, int periodDays});

final captureDebugStatsProvider = FutureProvider.autoDispose<CaptureDebugStats>((ref) async {
  final period = ref.watch(currentPeriodProvider);
  final db = ref.watch(databaseProvider);
  final ms = await ref.watch(analyticsRepositoryProvider).recentCaptureSaveMs();
  final days = await DailyTotalsRepository(db).entryDays(period.startDay, period.endDayExclusive);
  return (
    medianMs: medianMs(ms),
    saves: ms.length,
    loggedDays: loggedDays(period, days),
    periodDays: period.endDayExclusive - period.startDay,
  );
});

class CaptureDebugScreen extends ConsumerWidget {
  const CaptureDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final stats = ref.watch(captureDebugStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Angka pencatatan')),
      body: ListView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        children: [
          switch (stats) {
            AsyncData(:final value) => CardGroup(
                dividerIndent: WudgetTokens.space3,
                children: [
                  CardRow(
                    title: 'Median buka sampai simpan',
                    subtitle: value.medianMs == null
                        ? 'Belum ada catatan tersimpan'
                        : '${value.medianMs} ms, dari ${value.saves} simpanan terakhir',
                  ),
                  CardRow(
                    title: 'Hari tercatat periode ini',
                    subtitle: '${value.loggedDays} dari ${value.periodDays} hari',
                  ),
                ],
              ),
            AsyncError() => Text(
                'Angka belum bisa dibaca. Tutup halaman ini lalu buka lagi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tokens.ink2),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}
