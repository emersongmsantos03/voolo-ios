import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/models/income_source.dart';

void main() {
  group('IncomeSource month scope', () {
    test('income without an explicit window only counts in its creation month',
        () {
      final income = IncomeSource(
        id: '1',
        title: 'Salário',
        amount: 50000,
        type: 'salary',
        createdAt: DateTime(2026, 4, 8),
      );

      expect(income.appliesToMonthKey('2026-04'), isTrue);
      expect(income.appliesToMonthKey('2026-05'), isFalse);
    });

    test('income respects explicit active range and exclusions', () {
      final income = IncomeSource(
        id: '2',
        title: 'Prestação de serviço',
        amount: 12000,
        type: 'service',
        createdAt: DateTime(2026, 4, 8),
        activeFrom: '2026-04',
        activeUntil: '2026-06',
        excludedMonths: const ['2026-05'],
      );

      expect(income.appliesToMonthKey('2026-04'), isTrue);
      expect(income.appliesToMonthKey('2026-05'), isFalse);
      expect(income.appliesToMonthKey('2026-07'), isFalse);
    });
  });
}
