import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/payment_log_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../capture/capture_sheet.dart';
import '../widget/capture_deeplink.dart';

enum _Filter { pending, all, done }

/// Every payment notification wudget read, and whether it made it into the
/// ledger. Tap one to record it; the box marks it done by hand, for a
/// payment recorded some other way.
class PaymentLogScreen extends StatefulWidget {
  const PaymentLogScreen({super.key});

  @override
  State<PaymentLogScreen> createState() => _PaymentLogScreenState();
}

class _PaymentLogScreenState extends State<PaymentLogScreen> {
  static final _when = DateFormat('d MMM, HH:mm', 'id_ID');
  List<PaymentLogEntry>? _entries;
  _Filter _filter = _Filter.pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await PaymentLogRepository.all();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _toggle(PaymentLogEntry e) async {
    await PaymentLogRepository.setInputted(e.id, !e.inputted);
    await _load();
  }

  Future<void> _record(PaymentLogEntry e) async {
    await showCaptureLaunch(
      context,
      CaptureLaunch(
        kind: CaptureKind.expense,
        amountMinor: e.amountMinor,
        note: e.merchant ?? e.app,
        paymentLogId: e.id,
      ),
      source: CaptureSource.payment,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final entries = _entries;
    final pending = entries?.where((e) => !e.inputted).length ?? 0;
    final shown = entries
        ?.where((e) => switch (_filter) {
              _Filter.pending => !e.inputted,
              _Filter.done => e.inputted,
              _Filter.all => true,
            })
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Log notifikasi pembayaran')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(WudgetTokens.space4),
          children: [
            SegmentedTray<_Filter>(
              segments: {
                _Filter.pending: 'Belum dicatat ($pending)',
                _Filter.all: 'Semua',
                _Filter.done: 'Sudah',
              },
              value: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: WudgetTokens.space4),
            if (shown == null)
              const Center(child: CircularProgressIndicator())
            else if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: WudgetTokens.space5),
                child: Text(
                  switch (_filter) {
                    _Filter.pending when entries!.isNotEmpty => 'Semua pembayaran sudah tercatat.',
                    _Filter.done => 'Belum ada yang ditandai tercatat.',
                    _ => 'Belum ada notifikasi pembayaran. Yang terbaca dari GoPay, Livin’, Jago dan ShopeePay muncul di sini.',
                  },
                  style: text.bodyMedium?.copyWith(color: tokens.ink2),
                  textAlign: TextAlign.center,
                ),
              )
            else
              CardGroup(
                dividerIndent: WudgetTokens.space3,
                children: [
                  for (final e in shown)
                    CardRow(
                      leading: Checkbox(
                        value: e.inputted,
                        onChanged: (_) => _toggle(e),
                        semanticLabel: e.inputted ? 'Tandai belum dicatat' : 'Tandai sudah dicatat',
                      ),
                      title: e.merchant ?? e.app,
                      subtitle: '${e.app} · ${_when.format(e.at)}${e.inputted ? ' · tercatat' : ''}',
                      trailing: AmountText(minor: e.amountMinor),
                      onTap: () => _record(e),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
