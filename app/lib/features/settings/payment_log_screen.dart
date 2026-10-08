import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/payment_log_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../capture/capture_sheet.dart';
import '../widget/capture_deeplink.dart';

/// Opens what a payment notification became: the saved entry for editing,
/// or, when it was never recorded or has since been deleted, a fresh
/// capture pre-filled from the notification.
Future<void> openPaymentEntry(BuildContext context, WudgetDatabase db, String logId) async {
  final repo = PaymentLogRepository(db);
  final saved = await repo.savedFor(logId);
  if (!context.mounted) return;
  if (saved != null) {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureSheet(
        initialAmountMinor: saved.entry.amountMinor,
        initialCategoryId: saved.categoryId,
        initialAccountId: saved.accountId,
        initialNote: saved.entry.note,
        initialOccurredAt: saved.entry.at,
        editingTransactionId: saved.entry.txId,
        paymentLogId: logId,
        source: CaptureSource.payment,
      ),
    );
    return;
  }
  final entry = (await PaymentLogRepository.all()).where((e) => e.id == logId).firstOrNull;
  if (entry == null || !context.mounted) return;
  await showCaptureLaunch(
    context,
    CaptureLaunch(
      kind: CaptureKind.expense,
      amountMinor: entry.unread ? null : entry.amountMinor,
      note: entry.note,
      paymentLogId: entry.id,
    ),
    source: CaptureSource.payment,
  );
}

enum _Filter { all, pending, done, unread }

/// Every payment notification wudget read, and whether it is in Catat.
/// New ones are recorded automatically; the box adds one by hand, or takes
/// out the entry wudget wrote, and a tap opens it to change the category.
class PaymentLogScreen extends ConsumerStatefulWidget {
  const PaymentLogScreen({super.key});

  @override
  ConsumerState<PaymentLogScreen> createState() => _PaymentLogScreenState();
}

class _PaymentLogScreenState extends ConsumerState<PaymentLogScreen> {
  static final _when = DateFormat('d MMM, HH:mm', 'id_ID');
  List<PaymentLogEntry>? _entries;
  _Filter _filter = _Filter.all;

  PaymentLogRepository get _repo => PaymentLogRepository(ref.read(databaseProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _repo.recordNew();
    final entries = await PaymentLogRepository.all();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _toggle(PaymentLogEntry e) async {
    await _repo.setRecorded(e, !e.inputted);
    await _load();
  }

  Future<void> _open(PaymentLogEntry e) async {
    await openPaymentEntry(context, ref.read(databaseProvider), e.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final entries = _entries;
    final pending = entries?.where((e) => !e.unread && !e.inputted).length ?? 0;
    final unread = entries?.where((e) => e.unread && !e.inputted).length ?? 0;
    final shown = entries
        ?.where((e) => switch (_filter) {
              _Filter.pending => !e.unread && !e.inputted,
              _Filter.done => e.inputted,
              _Filter.all => !e.unread,
              _Filter.unread => e.unread,
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
                _Filter.all: 'Semua',
                _Filter.pending: 'Belum ($pending)',
                _Filter.done: 'Tercatat',
                _Filter.unread: 'Lainnya ($unread)',
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
                    _Filter.done when entries!.isNotEmpty => 'Belum ada yang tercatat.',
                    _Filter.unread => 'Notifikasi lain dari aplikasi pembayaranmu yang tidak terbaca sebagai pembayaran muncul di sini. Kalau ternyata pembayaran, ketuk untuk mencatatnya.',
                    _ => 'Belum ada notifikasi pembayaran. Bayar seperti biasa, pembayarannya muncul di sini.',
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
                    if (e.unread)
                      CardRow(
                        leading: Icon(e.inputted ? Icons.check_circle_outline : Icons.help_outline, color: tokens.ink2),
                        title: e.note,
                        subtitle: [
                          '${e.app} · ${_when.format(e.at)}${e.inputted ? ' · di Catat' : ''}',
                          if (e.text?.trim().isNotEmpty == true) e.text!.trim(),
                        ].join('\n'),
                        onTap: () => _open(e),
                      )
                    else
                      CardRow(
                      leading: Checkbox(
                        value: e.inputted,
                        onChanged: (_) => _toggle(e),
                        semanticLabel: e.inputted ? 'Hapus dari Catat' : 'Masukkan ke Catat',
                      ),
                      title: e.note,
                      subtitle: '${e.app} · ${_when.format(e.at)}'
                          '${e.inputted ? ' · di Catat' : e.pending ? ' · menunggu jawaban' : ''}',
                      trailing: AmountText(minor: e.amountMinor),
                      onTap: () => _open(e),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
