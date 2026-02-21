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
  }) {
    final items = <WeeklyPlanItem>[];
    final d = currentDashboard;

    if (d == null || d.salary <= 0) {
      items.add(
        const WeeklyPlanItem(
          id: 'add_income',
          title: 'Cadastrar renda base',
          description: 'Sem renda ativa o plano perde precisão.',
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
        const WeeklyPlanItem(
          id: 'negative_balance',
          title: 'Voltar para saldo positivo',
          description:
              'Seu mês está no vermelho. Priorize corte de variáveis e renegociação de fixos.',
          actionKey: 'budgets',
          priority: 1,
        ),
      );
    }

    if (variableRatio > 0.30) {
      items.add(
        WeeklyPlanItem(
          id: 'trim_variable',
          title: 'Reduzir gastos variáveis',
          description:
              'Variáveis em ${(variableRatio * 100).toStringAsFixed(0)}% da renda. Defina teto semanal.',
          actionKey: 'transactions',
          priority: 2,
        ),
      );
    }

    if (investRatio < 0.10) {
      items.add(
        WeeklyPlanItem(
          id: 'increase_invest',
          title: 'Aumentar aporte de investimento',
          description:
              'Seu aporte está abaixo de 10% da renda. Simule um valor inicial sustentável.',
          actionKey: 'investment_plan',
          priority: 3,
        ),
      );
    }

    if (goals.isEmpty) {
      items.add(
        const WeeklyPlanItem(
          id: 'create_goal',
          title: 'Criar uma meta principal',
          description:
              'Uma meta clara direciona decisões da semana e aumenta consistência.',
          actionKey: 'goals',
          priority: 2,
        ),
      );
    }

    if (checkInDaysLast7 < 4) {
      items.add(
        WeeklyPlanItem(
          id: 'checkin_consistency',
          title: 'Subir consistência do check-in',
          description:
              'Você fez $checkInDaysLast7/7 check-ins. Meta da semana: pelo menos 5 dias.',
          actionKey: 'insights',
          priority: 4,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const WeeklyPlanItem(
          id: 'maintain_routine',
          title: 'Manter rotina e revisar categorias',
          description:
              'Seu plano está saudável. Revise categorias 1x na semana para prevenir desvios.',
          actionKey: 'insights',
          priority: 5,
        ),
      );
    }

    return WeeklyPlanResult(items);
  }
}
