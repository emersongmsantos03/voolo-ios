import '../models/goal.dart';
import '../models/monthly_dashboard.dart';

class WeeklyPlanItem {
  final String id;
  final String title;
  final String description;
  final String actionKey;
  final int priority;

  const WeeklyPlanItem({
    required this.id,
    required this.title,
    required this.description,
    required this.actionKey,
    required this.priority,
  });
}

class WeeklyPlanResult {
  final List<WeeklyPlanItem> items;

  const WeeklyPlanResult(this.items);

  WeeklyPlanItem? get nextBestAction {
    if (items.isEmpty) return null;
    final sorted = [...items]..sort((a, b) => a.priority.compareTo(b.priority));
    return sorted.first;
  }
}

class WeeklyPlanService {
  WeeklyPlanService._();

  static WeeklyPlanResult buildPlan({
    required MonthlyDashboard? currentDashboard,
    required List<Goal> goals,
    required int checkInDaysLast7,
    required String Function(String key, [Map<String, String>? vars]) tr,
  }) {
    final items = <WeeklyPlanItem>[];
    final d = currentDashboard;

    if (d == null || d.salary <= 0) {
      items.add(
        WeeklyPlanItem(
          id: 'add_income',
          title: tr('weekly_plan_add_income_title'),
          description: tr('weekly_plan_add_income_desc'),
          actionKey: 'profile_income',
          priority: 1,
        ),
      );
      return WeeklyPlanResult(items);
    }

    final income = d.salary;
    final variableRatio = income == 0 ? 0.0 : d.variableExpensesTotal / income;
    final investRatio = income == 0 ? 0.0 : d.investmentsTotal / income;
    final remaining = d.remainingSalary;

    if (remaining < 0) {
      items.add(
        WeeklyPlanItem(
          id: 'negative_balance',
          title: tr('weekly_plan_negative_balance_title'),
          description: tr('weekly_plan_negative_balance_desc'),
          actionKey: 'budgets',
          priority: 1,
        ),
      );
    }

    if (variableRatio > 0.30) {
      items.add(
        WeeklyPlanItem(
          id: 'trim_variable',
          title: tr('weekly_plan_trim_variable_title'),
          description: tr('weekly_plan_trim_variable_desc', {
            'pct': (variableRatio * 100).toStringAsFixed(0),
          }),
          actionKey: 'transactions',
          priority: 2,
        ),
      );
    }

    if (investRatio < 0.10) {
      items.add(
        WeeklyPlanItem(
          id: 'increase_invest',
          title: tr('weekly_plan_increase_invest_title'),
          description: tr('weekly_plan_increase_invest_desc'),
          actionKey: 'investment_plan',
          priority: 3,
        ),
      );
    }

    if (goals.isEmpty) {
      items.add(
        WeeklyPlanItem(
          id: 'create_goal',
          title: tr('weekly_plan_create_goal_title'),
          description: tr('weekly_plan_create_goal_desc'),
          actionKey: 'goals',
          priority: 2,
        ),
      );
    }

    if (checkInDaysLast7 < 4) {
      items.add(
        WeeklyPlanItem(
          id: 'checkin_consistency',
          title: tr('weekly_plan_checkin_consistency_title'),
          description: tr('weekly_plan_checkin_consistency_desc', {
            'days': '$checkInDaysLast7',
          }),
          actionKey: 'insights',
          priority: 4,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        WeeklyPlanItem(
          id: 'maintain_routine',
          title: tr('weekly_plan_maintain_routine_title'),
          description: tr('weekly_plan_maintain_routine_desc'),
          actionKey: 'insights',
          priority: 5,
        ),
      );
    }

    return WeeklyPlanResult(items);
  }
}
