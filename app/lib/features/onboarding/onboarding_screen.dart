import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/feature_flags_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// First run, four screens, drawn to design/mockups/onboarding-mockup.html.
/// It teaches only what someone cannot work out by tapping: the three-tap
/// capture, what each tab is for, that a period follows payday rather than
/// the calendar, and that nothing leaves the phone. Every screen is
/// skippable at any point, and skipping counts as done, because onboarding
/// that traps you is worse than none.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  static const _steps = [
    _Step(
      title: 'Catat dalam tiga ketukan',
      subtitle: 'Isi jumlahnya, pilih kategori, simpan. Tidak ada formulir panjang.',
      rows: [
        (
          icon: Icons.dialpad_outlined,
          title: 'Ketik jumlahnya',
          subtitle: 'Numpad besar, dan kalkulator kalau perlu ditotal dulu',
        ),
        (
          icon: Icons.category_outlined,
          title: 'Pilih kategori',
          subtitle: 'Yang sering kamu pakai naik sendiri ke depan',
        ),
        (
          icon: Icons.check_circle_outline,
          title: 'Simpan',
          subtitle: 'Satu ketukan, langsung masuk catatan',
        ),
      ],
    ),
    _Step(
      title: 'Empat tab, satu alur',
      subtitle: 'Tiap tab punya satu tugas, dan tabnya sama di seluruh aplikasi.',
      // The nav bar's own icons, so the tour matches what is in the bar.
      rows: [
        (
          icon: Icons.receipt_long_outlined,
          title: 'Catat',
          subtitle: 'Semua yang sudah kamu catat, rapi per hari',
        ),
        (
          icon: Icons.insights_outlined,
          title: 'Pantau',
          subtitle: 'Ke mana uangmu pergi di periode ini',
        ),
        (
          icon: Icons.account_balance_wallet_outlined,
          title: 'Kantong',
          subtitle: 'Isi dompet, rekening dan e-wallet',
        ),
        (
          icon: Icons.person_outline,
          title: 'Saya',
          subtitle: 'Pengingat, cadangan, dan awal periode',
        ),
      ],
    ),
    _Step(
      title: 'Satu periode, bukan satu bulan',
      subtitle: 'wudget menghitung per periode gajian, jadi angkanya cocok dengan '
          'uang yang benar-benar kamu pegang.',
      rows: [
        (
          icon: Icons.event_repeat_outlined,
          title: 'Awal periode',
          subtitle: 'Tanggal 25 secara bawaan, ubah ke tanggal gajianmu',
        ),
        (
          icon: Icons.today_outlined,
          title: 'Jatah harian',
          subtitle: 'Berapa yang masih boleh keluar hari ini',
        ),
        (
          icon: Icons.speed_outlined,
          title: 'Laju belanja',
          subtitle: 'Lebih cepat atau lebih lambat dari biasanya',
        ),
      ],
    ),
    _Step(
      title: 'Catatanmu tinggal di HP ini',
      subtitle: 'Tidak ada akun dan tidak ada server. Tidak ada yang bisa kami '
          'lihat, karena tidak ada yang dikirim.',
      rows: [
        (
          icon: Icons.save_alt_outlined,
          title: 'Cadangan & pulihkan',
          subtitle: 'Simpan salinan ke file, pulihkan kapan saja',
        ),
        (
          icon: Icons.block_outlined,
          title: 'Tanpa iklan dan pelacak',
          subtitle: 'Tidak ada yang mengintip kebiasaan belanjamu',
        ),
      ],
    ),
  ];

  bool get _last => _step == _steps.length - 1;

  Future<void> _finish({required bool skipped}) async {
    final flags = ref.read(featureFlagsRepositoryProvider);
    await flags.setBool(onboardingCompletedKey, true);
    final analytics = ref.read(analyticsRepositoryProvider);
    await (skipped
        ? analytics.logEvent('onboarding_skipped', props: {'screen': _step + 1})
        : analytics.logEvent('onboarding_finished'));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final step = _steps[_step];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(WudgetTokens.space5),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: WudgetTokens.space1),
                    // One segment per screen, the same countable progress
                    // the waiting state uses, rather than a percentage.
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? tokens.accent : tokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  WudgetTokens.space5,
                  0,
                  WudgetTokens.space5,
                  WudgetTokens.space5,
                ),
                children: [
                  Text(step.title, style: text.headlineMedium),
                  const SizedBox(height: WudgetTokens.space2),
                  Text(step.subtitle, style: text.bodyMedium),
                  const SizedBox(height: WudgetTokens.space5),
                  CardGroup(
                    dividerIndent: WudgetTokens.space3,
                    children: [
                      for (final row in step.rows)
                        CardRow(
                          leading: IconChip(
                            icon: row.icon,
                            background: tokens.surfaceMuted,
                            foreground: tokens.ink2,
                          ),
                          title: row.title,
                          subtitle: row.subtitle,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WudgetTokens.space5,
                0,
                WudgetTokens.space5,
                WudgetTokens.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () => _last ? _finish(skipped: false) : setState(() => _step++),
                    child: Text(_last ? 'Mulai catat' : 'Lanjut'),
                  ),
                  if (!_last)
                    TextButton(
                      onPressed: () => _finish(skipped: true),
                      child: const Text('Lewati'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Row = ({IconData icon, String title, String subtitle});

class _Step {
  const _Step({required this.title, required this.subtitle, required this.rows});
  final String title;
  final String subtitle;
  final List<_Row> rows;
}