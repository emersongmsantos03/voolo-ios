import '../core/plans/user_plan.dart';
import '../models/expense.dart';
import '../models/financial_insight.dart';
import '../models/goal.dart';
import '../models/monthly_dashboard.dart';
import '../utils/finance_overview_utils.dart';

class FinancialInsightService {
  List<FinancialInsight> generateInsights(
    MonthlyDashboard dashboard,
    List<Goal> goals,
    UserPlan plan, {
    required String Function(String key, [Map<String, String>? vars]) tr,
  }) {
    final insights = <FinancialInsight>[];
    final overview = buildFinanceOverview(
      salary: dashboard.salary,
      expenses: dashboard.expenses,
      creditCardPayments: dashboard.creditCardPayments,
    );

    if (plan.hasPersonalizedInsights && dashboard.salary > 0) {
      final spendingRatio = overview.totalCommitted / dashboard.salary;
      if (spendingRatio > 0.8) {
        insights.add(
          FinancialInsight(
            message: tr('insight_high_commitment_message'),
            action: NextBestAction.adjustSpend,
            actionLabel: tr('insight_action_review_spend'),
          ),
        );
      }
    }

    if (plan.hasPersonalizedInsights &&
        overview.creditSpent > 0 &&
        overview.projectedAfterInvoices < 0) {
      insights.add(
        FinancialInsight(
          message: tr('insight_credit_red_message'),
          action: NextBestAction.adjustSpend,
          actionLabel: tr('insight_action_view_bill'),
        ),
      );
    }

    if (plan.hasPersonalizedInsights &&
        overview.creditSpent > overview.debitSpent &&
        overview.creditSpent > 0) {
      insights.add(
        FinancialInsight(
          message: tr('insight_credit_over_debit_message'),
          action: NextBestAction.adjustSpend,
          actionLabel: tr('insight_action_view_entries'),
        ),
      );
    }

    if (plan.hasPersonalizedInsights &&
        overview.installmentBurden > 0 &&
        overview.creditSpent > 0 &&
        (overview.installmentBurden / overview.creditSpent) >= 0.5) {
      insights.add(
        FinancialInsight(
          message: tr('insight_installments_weight_message'),
          action: NextBestAction.adjustSpend,
          actionLabel: tr('insight_action_review_installments'),
        ),
      );
    }

    final nonInvestmentSpent = dashboard.expenses
        .where((e) => !e.isInvestment)
        .fold(0.0, (a, b) => a + b.amount);
    if (plan.hasPersonalizedInsights && nonInvestmentSpent > 0) {
      final grouped = <ExpenseCategory, double>{};
      for (final expense in dashboard.expenses.where((e) => !e.isInvestment)) {
        grouped[expense.category] =
            (grouped[expense.category] ?? 0) + expense.amount;
      }
      final topEntry = grouped.entries.isEmpty
          ? null
          : (grouped.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;
      if (topEntry != null && (topEntry.value / nonInvestmentSpent) >= 0.40) {
        insights.add(
          FinancialInsight(
            message: tr('insight_category_concentration_message'),
            action: NextBestAction.adjustSpend,
            actionLabel: tr('insight_action_review_category'),
          ),
        );
      }
    }

    final now = DateTime.now();
    final isCurrentMonth =
        dashboard.month == now.month && dashboard.year == now.year;
    if (plan.hasPersonalizedInsights &&
        dashboard.salary > 0 &&
        isCurrentMonth) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final monthProgress = now.day / daysInMonth;
      final commitmentRatio = overview.totalCommitted / dashboard.salary;
      if (commitmentRatio > (monthProgress + 0.15)) {
        insights.add(
          FinancialInsight(
            message: tr('insight_spending_speed_message'),
            action: NextBestAction.adjustSpend,
            actionLabel: tr('insight_action_hold_spending'),
          ),
        );
      }
    }

    final foodExpenses = dashboard.expenses
        .where((e) => e.category == ExpenseCategory.alimentacao)
        .fold(0.0, (a, b) => a + b.amount);
    if (plan.hasPersonalizedInsights &&
        dashboard.salary > 0 &&
        (foodExpenses / dashboard.salary) > 0.25) {
      insights.add(
        FinancialInsight(
          message: tr('insight_food_high_message'),
          action: NextBestAction.adjustSpend,
          actionLabel: tr('insight_action_see_expenses'),
        ),
      );
    }

    final hasEmergencyGoal = goals.any(
      (g) =>
          g.title.toLowerCase().contains('emergencia') ||
          g.description.toLowerCase().contains('emergencia'),
    );
    if (!hasEmergencyGoal) {
      insights.add(
        FinancialInsight(
          message: tr('insight_emergency_goal_message'),
          action: NextBestAction.createGoal,
          actionLabel: tr('insight_action_create_reserve'),
        ),
      );
    }

    if (plan.hasPersonalizedInsights &&
        dashboard.investmentsTotal == 0 &&
        overview.availableNow > 0) {
      insights.add(
        FinancialInsight(
          message: tr('insight_invest_free_cash_message'),
          action: NextBestAction.simulateInvestment,
          actionLabel: tr('insight_action_simulate_now'),
        ),
      );
    }

    if (dashboard.expenses.isEmpty) {
      insights.add(
        FinancialInsight(
          message: tr('insight_empty_dashboard_message'),
          action: NextBestAction.addExpense,
          actionLabel: tr('insight_action_add_expense'),
        ),
      );
    }

    return insights;
  }
}
