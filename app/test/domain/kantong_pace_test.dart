import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/domain/pace.dart';

String _fmt(int minor) => 'Rp$minor';

KantongSpend _k(String key, String name, int plan, int spent) =>
    (key: key, name: name, planMinor: plan, spentMinor: spent, hueIndex: 0);

void main() {
  // Screen 8, day 13 of 30: 43% of the period gone.
  const elapsed = 13 / 30;
  final mockup = [
    _k('cat_tagihan', 'Tagihan', 1650000, 1650000),
    _k('cat_transport', 'Transport', 900000, 356000),
    _k('cat_makan', 'Makan', 2400000, 1180000),
    _k('cat_hiburan', 'Hiburan', 450000, 225000),
    _k('cat_belanja', 'Belanja', 800000, 688000),
    _k('cat_tabungan', 'Tabungan', 400000, 0),
  ];

  test('sorted by spent share minus time share, Tagihan last, Tabungan left out', () {
    final sorted = sortKantongByPace(mockup, elapsed);
    expect(sorted.map((k) => k.kantong.name), ['Belanja', 'Hiburan', 'Makan', 'Transport', 'Tagihan']);
  });

  test('only a kantong clearly ahead of time is marked; a full Tagihan never is', () {
    final sorted = sortKantongByPace(mockup, elapsed);
    expect([for (final k in sorted) if (k.isAhead) k.kantong.name], ['Belanja']);
  });

  test('the sentence names the kantong ahead of time and the projected overrun', () {
    final sentence = kantongPaceSentence(sortKantongByPace(mockup, elapsed), _fmt);
    expect(sentence, 'Belanja sudah 86% padahal periode baru jalan 43%. '
        'Kalau begini terus, lewat sekitar Rp787692.');
  });

  test('no sentence when nothing is ahead of time', () {
    final calm = [_k('cat_makan', 'Makan', 2400000, 900000), _k('cat_tagihan', 'Tagihan', 100, 100)];
    expect(kantongPaceSentence(sortKantongByPace(calm, elapsed), _fmt), isNull);
    expect(kantongPaceSentence(const [], _fmt), isNull);
  });
}
