import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// A demand check, not the feature: nothing is shared or sent. The email is
/// written to the local event log as `household_interest`.
class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final _email = TextEditingController();
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Alamat email belum lengkap.');
      return;
    }
    await ref.read(analyticsRepositoryProvider).logEvent('household_interest', props: {'email': email});
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Berbagi dengan keluarga')),
      body: ListView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        children: [
          Text('Belum tersedia', style: text.labelMedium),
          const SizedBox(height: WudgetTokens.space2),
          Text(
            'Kami sedang menimbang fitur untuk mencatat bersama pasangan atau keluarga: '
            'transaksi muncul di HP semua anggota, dan anggaran dipantau bersama. '
            'Kalau kamu mau memakainya, tinggalkan emailmu.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: WudgetTokens.space5),
          if (_done)
            WudgetCard(
              child: Text('Tercatat. Terima kasih sudah memberi tahu.', style: text.bodyLarge),
            )
          else ...[
            TextField(
              key: const Key('householdEmail'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(labelText: 'Email', errorText: _error),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: WudgetTokens.space3),
            FilledButton(onPressed: _submit, child: const Text('Saya tertarik')),
          ],
          const SizedBox(height: WudgetTokens.space4),
          Text(
            'Emailmu hanya disimpan di HP ini, tidak dikirim ke server mana pun. '
            'Ia ikut keluar hanya kalau kamu sendiri mengirim file cadangan ke tim beta.',
            style: text.bodySmall?.copyWith(color: tokens.ink2),
          ),
        ],
      ),
    );
  }
}
