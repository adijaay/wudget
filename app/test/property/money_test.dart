import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/core/money.dart';

// Property tests over randomly generated amounts, not a fixed example list —
// the invariants below must hold for every value, not just the ones a human
// thought to type. This is the guard for Sprint 1's "the arithmetic can
// never be wrong" goal (plan/05-sprints.md).
void main() {
  final rand = Random(20260911); // fixed seed: failures must reproduce

  Money randomIdr() => Money.fromMinor(rand.nextInt(2000000000) - 1000000000, 'IDR');

  group('Money arithmetic invariants (property, 500 random cases)', () {
    test('addition is commutative', () {
      for (var i = 0; i < 500; i++) {
        final a = randomIdr();
        final b = randomIdr();
        expect(a + b, b + a, reason: 'a=$a b=$b');
      }
    });

    test('addition is associative', () {
      for (var i = 0; i < 500; i++) {
        final a = randomIdr();
        final b = randomIdr();
        final c = randomIdr();
        expect((a + b) + c, a + (b + c), reason: 'a=$a b=$b c=$c');
      }
    });

    test('a - a is always zero', () {
      for (var i = 0; i < 500; i++) {
        final a = randomIdr();
        expect((a - a).isZero, isTrue, reason: 'a=$a');
      }
    });

    test('a + (-a) is always zero', () {
      for (var i = 0; i < 500; i++) {
        final a = randomIdr();
        expect((a + a.negated).isZero, isTrue, reason: 'a=$a');
      }
    });

    test('splitEvenly parts sum back to the original exactly', () {
      for (var i = 0; i < 500; i++) {
        final a = randomIdr();
        final n = 1 + rand.nextInt(9); // 1..9 parts
        final parts = a.splitEvenly(n);
        expect(parts.length, n);
        expect(sumMoney(parts), a, reason: 'a=$a n=$n parts=$parts');
      }
    });

    test('splitEvenly never produces parts differing by more than 1 minor unit', () {
      for (var i = 0; i < 500; i++) {
        final a = Money.fromMinor(rand.nextInt(1000000), 'IDR'); // non-negative only
        final n = 1 + rand.nextInt(9);
        final parts = a.splitEvenly(n).map((m) => m.minor).toList();
        final spread = parts.reduce(max) - parts.reduce(min);
        expect(spread <= 1, isTrue, reason: 'a=$a n=$n parts=$parts');
      }
    });

    test('mixed-currency addition always throws, never coerces', () {
      final idr = Money.fromMinor(1000, 'IDR');
      final usd = Money.fromMinor(1000, 'USD');
      expect(() => idr + usd, throwsStateError);
      expect(() => idr - usd, throwsStateError);
      expect(() => idr < usd, throwsStateError);
    });

    test('fromMajor rounds to the nearest minor unit, not truncates', () {
      // 12.505 USD -> 1251 cents (round), not 1250 (truncate).
      expect(Money.fromMajor(12.505, 'USD').minor, 1251);
    });

    test('unknown currency code is rejected at construction, not silently accepted', () {
      expect(() => Money.fromMinor(1000, 'XXX'), throwsArgumentError);
    });
  });

  group('sumMoney', () {
    test('empty list is a programmer error, not a silent zero', () {
      expect(() => sumMoney(const []), throwsArgumentError);
    });

    test('mixed currencies in the list throw, not silently drop the rest', () {
      final list = [Money.fromMinor(100, 'IDR'), Money.fromMinor(100, 'USD')];
      expect(() => sumMoney(list), throwsStateError);
    });
  });
}
