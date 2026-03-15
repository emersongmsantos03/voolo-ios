import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/models/expense.dart';
import 'package:jetx/models/goal.dart';
import 'package:jetx/models/monthly_dashboard.dart';
import 'package:jetx/services/weekly_plan_service.dart';

void main() {
  group('WeeklyPlanService', () {
    test('returns add_income when dashboard is missing', () {
      final result = WeeklyPlanService.buildPlan(
        currentDashboard: null,
        goals: const [],
        checkInDaysLast7: 0,
      );

      expect(result.items, isNotEmpty);
      expect(result.nextBestAction?.id, 'add_income');
    });

    test('prioritizes negative balance first', () {
      final d = MonthlyDashboard(
        month: 2,
        year: 2026,
        salary: 1000,
        expenses: [
          _expense(amount: 800, type: ExpenseType.fixed),
          _expense(amount: 500, type: ExpenseType.variable),
        ],
      );

      final result = WeeklyPlanService.buildPlan(
        currentDashboard: d,
        goals: const [],
        checkInDaysLast7: 1,
      );

      expect(result.nextBestAction?.id, 'negative_balance');
    });

    test('returns maintain_routine on healthy scenario', () {
      final d = MonthlyDashboard(
        month: 2,
        year: 2026,
        salary: 5000,
        expenses: [
          _expense(amount: 1500, type: ExpenseType.fixed),
          _expense(amount: 1000, type: ExpenseType.variable),
          _expense(amount: 700, type: ExpenseType.investment),
        ],
      );

      final result = WeeklyPlanService.buildPlan(
        currentDashboard: d,
        goals: [
          Goal(
            id: 'g1',
            title: 'Meta',
            type: GoalType.personal,
            targetYear: 2026,
            description: '',
            completed: true,
          ),
        ],
        checkInDaysLast7: 6,
      );

      expect(result.nextBestAction?.id, 'maintain_routine');
    });
  });
}

Expense _expense({required double amount, required ExpenseType type}) {
  final category = type == ExpenseType.investment
      ? ExpenseCategory.investment
      : ExpenseCategory.outros;

  return Expense(
    id: '${type.name}_${amount.toStringAsFixed(0)}_${DateTime.now().microsecondsSinceEpoch}',
    name: 'x',
    type: type,
    category: category,
    amount: amount,
    date: DateTime(2026, 2, 10),
  );
}
