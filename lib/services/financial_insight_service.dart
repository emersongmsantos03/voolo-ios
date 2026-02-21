import '../models/expense.dart';
import '../models/monthly_dashboard.dart';
import '../models/goal.dart';
import '../models/financial_insight.dart';
import '../core/plans/user_plan.dart';

class FinancialInsightService {
  List<FinancialInsight> generateInsights(
      MonthlyDashboard dashboard, List<Goal> goals, UserPlan plan) {
    final List<FinancialInsight> insights = [];

    // 1. Overspending check (more than 80% of salary spent) - PREMIUM
    if (plan.hasPersonalizedInsights && dashboard.salary > 0) {
      final spendingRatio = dashboard.totalExpenses / dashboard.salary;
      if (spendingRatio > 0.8) {
        insights.add(FinancialInsight(
          message:
              "Você já comprometeu mais de 80% da sua renda este mês. Atenção aos próximos gastos!",
          action: NextBestAction.adjustSpend,
          actionLabel: "Revisar Gastos",
        ));
      }
    }

    // 2. High Food spending check - PREMIUM
    final foodExpenses = dashboard.expenses
        .where((e) => e.category == ExpenseCategory.alimentacao)
        .fold(0.0, (a, b) => a + b.amount);
    if (plan.hasPersonalizedInsights &&
        dashboard.salary > 0 &&
        (foodExpenses / dashboard.salary) > 0.25) {
      insights.add(FinancialInsight(
        message:
            "Seus gastos com alimentação estão acima da média (25% da renda). Que tal cozinhar mais em casa?",
        action: NextBestAction.adjustSpend,
        actionLabel: "Ver Gastos",
      ));
    }

    // 3. Emergency Fund nudge
    final hasEmergencyGoal = goals.any((g) =>
        g.title.toLowerCase().contains('emergência') ||
        g.description.toLowerCase().contains('emergência'));
    if (!hasEmergencyGoal) {
      insights.add(FinancialInsight(
        message: "Ainda não identificamos uma meta de Reserva de Emergência. Esse é o primeiro passo para sua segurança!",
        action: NextBestAction.createGoal,
        actionLabel: "Criar Reserva",
      ));
    }

    // 4. Investment nudge - PREMIUM
    if (plan.hasPersonalizedInsights &&
        dashboard.investmentsTotal == 0 &&
        dashboard.remainingSalary > 0) {
      insights.add(FinancialInsight(
        message:
            "Sobrou um pouco este mês! Que tal começar a investir ao invés de deixar parado?",
        action: NextBestAction.simulateInvestment,
        actionLabel: "Simular Agora",
      ));
    }

    // 5. Empty check
    if (dashboard.expenses.isEmpty) {
      insights.add(FinancialInsight(
        message: "Seu dashboard está vazio. Registre seu primeiro gasto para começarmos a análise!",
        action: NextBestAction.addExpense,
        actionLabel: "Adicionar Gasto",
      ));
    }

    return insights;
  }
}
