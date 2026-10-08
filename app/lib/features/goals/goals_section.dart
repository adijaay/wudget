import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/money.dart';
import '../../core/money_formatter.dart';
import '../../core/providers.dart';
import '../../data/goals_repository.dart';
import '../../data/wallets_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../domain/goal.dart';

const _uuid = Uuid();
const _formatter = MoneyFormatter();

/// Savings goals, drawn inside Kantong because a goal is a wallet with a
/// number to reach, not a place of its own. Built from
/// design/mockups/goals-mockup.html with the app's own rows and tokens.
class GoalsSection extends ConsumerWidget {
  const GoalsSection({super.key, required this.wallets});
  final List<WalletWithBalance> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <GoalWithProgress>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Target'),
        CardGroup(
          children: [
            for (final g in goals) _GoalRow(goal: g),
            CardRow(
              leading: const Icon(Icons.flag_outlined),
              title: 'Target baru',
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => CreateGoalSheet(
                    repo: ref.read(goalsRepositoryProvider), wallets: wallets),
              ),
            ),
          ],
        ),
        const SizedBox(height: WudgetTokens.space4),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});
  final GoalWithProgress goal;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    String fmt(int minor) => _formatter.format(Money.fromMinor(minor, 'IDR'));

    return Padding(
      padding: const EdgeInsets.all(WudgetTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.goal.name, style: text.titleMedium),
          const SizedBox(height: WudgetTokens.space1),
          Text('${fmt(goal.savedMinor)} dari ${fmt(goal.goal.targetMinor)}',
              style: text.bodyMedium),
          const SizedBox(height: WudgetTokens.space2),
          Wrap(
            spacing: WudgetTokens.space2,
            children: [
              for (final p in milestonePercents)
                Chip(
                  label: Text('$p%'),
                  labelStyle: text.labelMedium?.copyWith(
                      color: goal.reached >= p ? tokens.inkOnAccent : tokens.ink2),
                  backgroundColor:
                      goal.reached >= p ? tokens.accent : tokens.surfaceMuted,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateGoalSheet extends StatefulWidget {
  const CreateGoalSheet({super.key, required this.repo, required this.wallets});
  final GoalsRepository repo;
  final List<WalletWithBalance> wallets;

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String? _accountId;

  @override
  void initState() {
    super.initState();
    // A savings wallet is the natural home for a goal, so it starts chosen.
    final savings = widget.wallets.where((w) => w.account.type == 'savings');
    _accountId = (savings.isNotEmpty ? savings.first : widget.wallets.firstOrNull)?.account.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: WudgetTokens.space4,
        right: WudgetTokens.space4,
        top: WudgetTokens.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Target baru', style: text.titleLarge),
            const SizedBox(height: WudgetTokens.space4),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Nama target, misal Dana darurat'),
            ),
            const SizedBox(height: WudgetTokens.space3),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Jumlah target'),
            ),
            const SizedBox(height: WudgetTokens.space3),
            const SectionLabel('Kantong tujuan'),
            Wrap(
              spacing: WudgetTokens.space2,
              runSpacing: WudgetTokens.space2,
              children: [
                for (final w in widget.wallets)
                  ChoiceChip(
                    label: Text(w.account.name),
                    selected: _accountId == w.account.id,
                    onSelected: (_) => setState(() => _accountId = w.account.id),
                  ),
              ],
            ),
            const SizedBox(height: WudgetTokens.space4),
            FilledButton(onPressed: _save, child: const Text('Buat target')),
            const SizedBox(height: WudgetTokens.space4),
          ],
        ),
      ),
    );
  }

  void _save() {
    final target = int.tryParse(_targetController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (_nameController.text.trim().isEmpty || target == null || target <= 0 || _accountId == null) {
      return;
    }
    widget.repo.create(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      targetMinor: target,
      accountId: _accountId!,
    );
    Navigator.of(context).pop();
  }
}
