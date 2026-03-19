import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/models/expense.dart';
import 'package:jetx/utils/budget_rule_utils.dart';

void main() {
  group('budgetRuleForEntry', () {
    test('prefers housing and leisure category rules over generic type', () {
      expect(
        budgetRuleForEntry(
          type: ExpenseType.fixed,
          category: ExpenseCategory.moradia,
        ),
        housingBudgetRule,
      );
      expect(
        budgetRuleForEntry(
          type: ExpenseType.variable,
          category: ExpenseCategory.lazer,
        ),
        leisureBudgetRule,
      );
    });

    test('uses fixed, variable and investment business rules', () {
      expect(
        budgetRuleForEntry(
          type: ExpenseType.fixed,
          category: ExpenseCategory.saude,
        ),
        fixedBudgetRule,
      );
      expect(
        budgetRuleForEntry(
          type: ExpenseType.variable,
          category: ExpenseCategory.saude,
        ),
        variableBudgetRule,
      );
      expect(
        budgetRuleForEntry(
          type: ExpenseType.investment,
          category: ExpenseCategory.investment,
        ),
        investmentBudgetRule,
      );
    });
  });

  group('trackedTotalForBudgetRule', () {
    final expenses = [
      Expense(
        id: 'f1',
        name: 'Plano de saude',
        type: ExpenseType.fixed,
        category: ExpenseCategory.saude,
        amount: 900,
        date: DateTime(2026, 3, 18),
      ),
      Expense(
        id: 'f2',
        name: 'Aluguel',
        type: ExpenseType.fixed,
        category: ExpenseCategory.moradia,
        amount: 2500,
        date: DateTime(2026, 3, 18),
      ),
      Expense(
        id: 'v1',
        name: 'Cinema',
        type: ExpenseType.variable,
        category: ExpenseCategory.lazer,
        amount: 300,
        date: DateTime(2026, 3, 18),
      ),
      Expense(
        id: 'i1',
        name: 'Tesouro',
        type: ExpenseType.investment,
        category: ExpenseCategory.investment,
        amount: 700,
        date: DateTime(2026, 3, 18),
      ),
    ];

    test('tracks totals by the same scope used in the UI tips', () {
      expect(
        trackedTotalForBudgetRule(
          expenses,
          type: ExpenseType.fixed,
          category: ExpenseCategory.saude,
        ),
        3400,
      );
      expect(
        trackedTotalForBudgetRule(
          expenses,
          type: ExpenseType.fixed,
          category: ExpenseCategory.moradia,
        ),
        2500,
      );
      expect(
        trackedTotalForBudgetRule(
          expenses,
          type: ExpenseType.variable,
          category: ExpenseCategory.lazer,
        ),
        300,
      );
      expect(
        trackedTotalForBudgetRule(
          expenses,
          type: ExpenseType.investment,
          category: ExpenseCategory.investment,
        ),
        700,
      );
    });
  });

  group('budget tip thresholds', () {
    test('distinguishes ideal threshold from alert threshold', () {
      expect(shouldShowBudgetTip(fixedBudgetRule, 0.50), isTrue);
      expect(isBudgetAlert(fixedBudgetRule, 0.50), isFalse);
      expect(isBudgetAlert(fixedBudgetRule, 0.60), isTrue);

      expect(shouldShowBudgetTip(investmentBudgetRule, 0.14), isTrue);
      expect(isBudgetAlert(investmentBudgetRule, 0.14), isFalse);
      expect(isBudgetAlert(investmentBudgetRule, 0.09), isTrue);
    });
  });
}
