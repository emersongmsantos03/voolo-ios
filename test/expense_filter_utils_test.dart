import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/models/expense.dart';
import 'package:jetx/utils/expense_filter_utils.dart';

void main() {
  group('filterExpenses', () {
    DateTime dueDateFor(Expense e) => e.date;

    test('filters by paid and pending using isPaid', () {
      final items = [
        Expense(
          id: '1',
          name: 'A',
          type: ExpenseType.fixed,
          category: ExpenseCategory.moradia,
          amount: 10,
          date: DateTime(2026, 2, 2),
          isPaid: true,
        ),
        Expense(
          id: '2',
          name: 'B',
          type: ExpenseType.fixed,
          category: ExpenseCategory.moradia,
          amount: 10,
          date: DateTime(2026, 2, 2),
          isPaid: false,
        ),
      ];

      expect(
        filterExpenses(items, dueDateFor: dueDateFor, isPaid: true)
            .map((e) => e.id),
        ['1'],
      );
      expect(
        filterExpenses(items, dueDateFor: dueDateFor, isPaid: false)
            .map((e) => e.id),
        ['2'],
      );
    });

    test('treats variable and investment as always paid', () {
      final items = [
        Expense(
          id: 'v',
          name: 'Var',
          type: ExpenseType.variable,
          category: ExpenseCategory.moradia,
          amount: 10,
          date: DateTime(2026, 2, 2),
          isPaid: false,
        ),
        Expense(
          id: 'i',
          name: 'Inv',
          type: ExpenseType.investment,
          category: ExpenseCategory.investment,
          amount: 10,
          date: DateTime(2026, 2, 2),
          isPaid: false,
        ),
      ];

      expect(
        filterExpenses(items, dueDateFor: dueDateFor, isPaid: true)
            .map((e) => e.id),
        ['v', 'i'],
      );
      expect(
        filterExpenses(items, dueDateFor: dueDateFor, isPaid: false)
            .map((e) => e.id),
        <String>[],
      );
    });

    test('filters by due date range inclusively', () {
      final items = [
        Expense(
          id: '1',
          name: 'A',
          type: ExpenseType.variable,
          category: ExpenseCategory.moradia,
          amount: 10,
          date: DateTime(2026, 2, 1),
        ),
        Expense(
          id: '2',
          name: 'B',
          type: ExpenseType.variable,
          category: ExpenseCategory.moradia,
          amount: 10,
          date: DateTime(2026, 2, 2),
        ),
        Expense(
          id: '3',
          name: 'C',
          type: ExpenseType.variable,
          category: ExpenseCategory.moradia,
          amount: 10,
          date: DateTime(2026, 2, 3),
        ),
      ];

      final filtered = filterExpenses(
        items,
        dueDateFor: dueDateFor,
        dueFrom: DateTime(2026, 2, 2),
        dueTo: DateTime(2026, 2, 2),
      );

      expect(filtered.map((e) => e.id), ['2']);
    });

    test('filters by categories', () {
      final items = [
        Expense(
          id: '1',
          name: 'A',
          type: ExpenseType.variable,
          category: ExpenseCategory.moradia,
          amount: 10,
          date: DateTime(2026, 2, 2),
        ),
        Expense(
          id: '2',
          name: 'B',
          type: ExpenseType.variable,
          category: ExpenseCategory.alimentacao,
          amount: 10,
          date: DateTime(2026, 2, 2),
        ),
      ];

      final filtered = filterExpenses(
        items,
        dueDateFor: dueDateFor,
        categories: {ExpenseCategory.alimentacao},
      );

      expect(filtered.map((e) => e.id), ['2']);
    });

    test('returns a mutable list even when empty input', () {
      final filtered = filterExpenses(
        const [],
        dueDateFor: dueDateFor,
        dueFrom: DateTime(2026, 2, 2),
        dueTo: DateTime(2026, 2, 2),
        isPaid: true,
      );

      expect(() => filtered.sort((a, b) => 0), returnsNormally);
    });
  });
}
