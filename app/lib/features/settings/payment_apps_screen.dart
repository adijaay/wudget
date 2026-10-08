import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/payment_apps_repository.dart';
import '../../data/payment_log_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// Which apps' payments go into Catat. Apps arrive here on their own, the
/// first time they post a payment notification; adding one by hand is the
/// fallback for setting up ahead.
class PaymentAppsScreen extends ConsumerStatefulWidget {
  const PaymentAppsScreen({super.key});

  @override
  ConsumerState<PaymentAppsScreen> createState() => _PaymentAppsScreenState();
}

class _PaymentAppsScreenState extends ConsumerState<PaymentAppsScreen> {
  List<PaymentApp>? _apps;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await PaymentAppsRepository.all();
    if (mounted) setState(() => _apps = apps);
  }

  Future<void> _set(String pkg, String label, PaymentAppState state) async {
    await PaymentAppsRepository.set(pkg, label, state);
    // Saying yes releases the payments that waited for the answer; record them now, not on next resume.
    if (state == PaymentAppState.on) await PaymentLogRepository(ref.read(databaseProvider)).recordNew();
    await _load();
  }

  Future<void> _add() async {
    final picked = await Navigator.of(context).push<InstalledApp>(
      MaterialPageRoute(builder: (_) => _AddAppScreen(chosen: {for (final a in _apps ?? const <PaymentApp>[]) if (a.state == PaymentAppState.on) a.pkg})),
    );
    if (picked != null) await _set(picked.pkg, picked.label, PaymentAppState.on);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final apps = _apps;
    final ask = apps?.where((a) => a.state == PaymentAppState.ask).toList() ?? const [];
    final on = apps?.where((a) => a.state == PaymentAppState.on).toList() ?? const [];
    final off = apps?.where((a) => a.state == PaymentAppState.off).toList() ?? const [];

    Widget section(String label, List<PaymentApp> list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: WudgetTokens.space4),
            SectionLabel(label),
            CardGroup(
              dividerIndent: WudgetTokens.space3,
              children: [
                for (final a in list)
                  MergeSemantics(
                    child: CardRow(
                      title: a.label,
                      subtitle: switch (a.state) {
                        PaymentAppState.ask => '${a.count} pembayaran menunggu jawabanmu',
                        _ => '${a.count} pembayaran terdeteksi',
                      },
                      trailing: Switch(
                        value: a.state == PaymentAppState.on,
                        onChanged: (v) => _set(a.pkg, a.label, v ? PaymentAppState.on : PaymentAppState.off),
                      ),
                      onTap: () => _set(a.pkg, a.label, a.state == PaymentAppState.on ? PaymentAppState.off : PaymentAppState.on),
                    ),
                  ),
              ],
            ),
          ],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Aplikasi pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        children: [
          Text(
            'Aplikasi muncul di sini setelah mengirim notifikasi pembayaran. '
            'Yang dinyalakan, pembayarannya langsung masuk Catat.',
            style: text.bodyMedium?.copyWith(color: tokens.ink2),
          ),
          if (apps == null)
            const Padding(
              padding: EdgeInsets.all(WudgetTokens.space5),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (apps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space5),
              child: Text(
                'Belum ada pembayaran terdeteksi. Bayar seperti biasa, aplikasinya akan muncul di sini.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          if (ask.isNotEmpty) section('Belum dijawab', ask),
          if (on.isNotEmpty) section('Dicatat', on),
          if (off.isNotEmpty) section('Diabaikan', off),
          const SizedBox(height: WudgetTokens.space4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Tambah aplikasi lain'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every app with a launcher icon, searchable, for choosing one before it has paid.
class _AddAppScreen extends StatefulWidget {
  const _AddAppScreen({required this.chosen});
  final Set<String> chosen;

  @override
  State<_AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends State<_AddAppScreen> {
  List<InstalledApp>? _apps;
  String _query = '';

  @override
  void initState() {
    super.initState();
    PaymentAppsRepository.installed().then((apps) {
      if (mounted) setState(() => _apps = apps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final q = _query.trim().toLowerCase();
    final shown = _apps?.where((a) => !widget.chosen.contains(a.pkg) && (q.isEmpty || a.label.toLowerCase().contains(q))).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah aplikasi')),
      body: ListView(
        padding: const EdgeInsets.all(WudgetTokens.space4),
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari aplikasi'),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: WudgetTokens.space4),
          if (shown == null)
            const Center(child: CircularProgressIndicator())
          else if (shown.isNotEmpty)
            CardGroup(
              dividerIndent: WudgetTokens.space3,
              children: [
                for (final a in shown)
                  CardRow(
                    title: a.label,
                    trailing: Icon(Icons.add, color: tokens.ink2),
                    onTap: () => Navigator.of(context).pop(a),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space4),
            child: Text(
              'Tidak ketemu? Aplikasi akan muncul sendiri setelah kamu bayar pakai aplikasi itu.',
              style: text.bodySmall?.copyWith(color: tokens.ink2),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
