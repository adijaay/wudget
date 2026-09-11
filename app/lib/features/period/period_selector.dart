import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../domain/period.dart';

/// Governs every surface below it (Pantau, and later Catat) by writing
/// [periodOffsetProvider]. See plan/05-sprints.md Sprint 8.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(currentPeriodProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(periodOffsetProvider.notifier).state--,
        ),
        Text(_label(period), style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => ref.read(periodOffsetProvider.notifier).state++,
        ),
      ],
    );
  }

  String _label(Period period) {
    final format = DateFormat('d MMM', 'id_ID');
    final yearFormat = DateFormat('d MMM yyyy', 'id_ID');
    if (period.monthStartDay == 1) {
      return DateFormat('MMMM yyyy', 'id_ID').format(period.startDate);
    }
    return '${format.format(period.startDate)} - ${yearFormat.format(period.lastDate)}';
  }
}
