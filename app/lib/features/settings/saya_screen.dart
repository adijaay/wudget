import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../budget/budget_screen.dart';
import '../categories/categories_screen.dart';
import '../import/import_screen.dart';
import '../recurring/recurring_screen.dart';
import 'backup_screen.dart';
import 'capture_debug_screen.dart';

/// Saya: the fourth tab in the mockups' bottom bar. Everything here already
/// existed but was only reachable from an icon in another screen's app bar
/// (backup, CSV import, recurring items, budget), or had no UI at all (the
/// day the period starts on, which every period boundary in the app is
/// measured from). Only rows that lead somewhere real are listed (R-24).
class SayaScreen extends ConsumerWidget {
  const SayaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final startDay = ref.watch(periodStartDayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saya')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WudgetTokens.space4,
          0,
          WudgetTokens.space4,
          WudgetTokens.space6,
        ),
        children: [
          const SectionLabel('Anggaran & tagihan'),
          CardGroup(
            dividerIndent: WudgetTokens.space3,
            children: [
              CardRow(
                title: 'Anggaran',
                subtitle: 'Batas per kategori untuk periode ini',
                trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BudgetScreen()),
                ),
              ),
              CardRow(
                title: 'Kategori',
                subtitle: 'Tambah, ubah nama, ganti ikon dan warnanya',
                trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
              CardRow(
                title: 'Berulang & tagihan',
                subtitle: 'Tagihan bulanan dan pengingatnya',
                trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecurringScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: WudgetTokens.space5),
          const SectionLabel('Periode'),
          CardGroup(
            dividerIndent: WudgetTokens.space3,
            children: [
              CardRow(
                title: 'Awal periode',
                subtitle: switch (startDay.valueOrNull) {
                  null => 'Memuat...',
                  1 => 'Tanggal 1, mengikuti bulan kalender',
                  final day => 'Tanggal $day, mengikuti tanggal gajian',
                },
                trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                onTap: startDay.valueOrNull == null
                    ? null
                    : () => _pickPeriodStartDay(context, ref, startDay.value!),
              ),
            ],
          ),
          const SizedBox(height: WudgetTokens.space5),
          const SectionLabel('Data'),
          CardGroup(
            dividerIndent: WudgetTokens.space3,
            children: [
              CardRow(
                title: 'Cadangan & pulihkan',
                subtitle: 'Simpan salinan, atau kembalikan dari salinan',
                trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                ),
              ),
              CardRow(
                title: 'Impor dari CSV',
                subtitle: 'Pindahkan catatan dari aplikasi lain',
                trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportScreen()),
                ),
              ),
            ],
          ),
          if (ref.watch(captureDebugFlagProvider).valueOrNull ?? false) ...[
            const SizedBox(height: WudgetTokens.space5),
            CardGroup(
              dividerIndent: WudgetTokens.space3,
              children: [
                CardRow(
                  title: 'Angka pencatatan',
                  subtitle: 'Waktu sampai simpan dan hari tercatat',
                  trailing: Icon(Icons.chevron_right, color: tokens.ink2),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CaptureDebugScreen()),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: WudgetTokens.space5),
          // Stated because it is the product's actual promise, and because
          // it is what makes the backup row above matter: nothing is stored
          // anywhere else, so a copy is the user's only copy.
          WudgetCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phonelink_lock_outlined, size: 20, color: tokens.ink2),
                const SizedBox(width: WudgetTokens.space3),
                Expanded(
                  child: Text(
                    'Semua catatanmu tersimpan di HP ini saja. Tidak ada akun, '
                    'tidak dikirim ke mana pun. Buat cadangan kalau mau pindah HP.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPeriodStartDay(BuildContext context, WidgetRef ref, int current) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PeriodStartDaySheet(current: current),
    );
    if (picked == null) return;
    await ref.read(settingsRepositoryProvider).setPeriodStartDay(picked);
  }
}

/// 1 to 28 only, matching what the repository clamps to: a period that
/// started on the 30th would skip February entirely.
class _PeriodStartDaySheet extends StatelessWidget {
  const _PeriodStartDaySheet({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Awal periode', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: WudgetTokens.space2),
            Text(
              'Pilih tanggal gajianmu, biar periode di Pantau mengikuti uang '
              'masuk, bukan tanggal 1.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: WudgetTokens.space4),
            SizedBox(
              height: 220,
              child: GridView.count(
                crossAxisCount: 7,
                mainAxisSpacing: WudgetTokens.space2,
                crossAxisSpacing: WudgetTokens.space2,
                children: [
                  for (var day = 1; day <= 28; day++)
                    _DayCell(
                      day: day,
                      selected: day == current,
                      onTap: () => Navigator.of(context).pop(day),
                    ),
                ],
              ),
            ),
            const SizedBox(height: WudgetTokens.space2),
            Text(
              'Tanggal 29 sampai 31 tidak ada di setiap bulan, jadi tidak bisa dipakai.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.onTap});
  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Semantics(
      selected: selected,
      button: true,
      label: 'Tanggal $day',
      excludeSemantics: true,
      child: Material(
        color: selected ? tokens.accent : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontFamily: WudgetTokens.fontFamily,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? tokens.inkOnAccent : tokens.ink1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
