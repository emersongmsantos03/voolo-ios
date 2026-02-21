import '../../models/expense.dart';
import '../../models/monthly_dashboard.dart';
import '../../models/user_profile.dart';
import 'mission_progress.dart';

class FinancialLevel {
  final int level;
  final String name;
  final String mindset;
  final int minXp;
  final bool premiumRequired;
  final List<String> unlocks;

  const FinancialLevel({
    required this.level,
    required this.name,
    required this.mindset,
    required this.minXp,
    required this.premiumRequired,
    required this.unlocks,
  });
}

class Mission {
  final String code;
  final String title;
  final String desc;
  final String type; // daily, weekly, monthly
  final int xp;
  final int minLevel;
  final String category;
  final String completionMode; // auto, note, manual
  final Map<String, dynamic>? criteria;
  final int? scoreMin;
  final int? scoreMax;
  final String? notePrompt;
  final int? noteMinChars;

  const Mission({
    required this.code,
    required this.title,
    required this.desc,
    required this.type,
    required this.xp,
    this.minLevel = 1,
    this.category = 'habit',
    this.completionMode = 'manual',
    this.criteria,
    this.scoreMin,
    this.scoreMax,
    this.notePrompt,
    this.noteMinChars,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'];
    Map<String, dynamic>? parsedCriteria;
    if (rawCriteria is Map) {
      parsedCriteria = Map<String, dynamic>.from(rawCriteria as Map);
    }

    final rawMode = (json['completionMode'] as String?)?.trim();
    final normalizedMode =
        (rawMode == 'auto' || rawMode == 'manual' || rawMode == 'note')
            ? rawMode
            : null;
    final inferredMode = normalizedMode ??
        ((parsedCriteria?['kind'] != null) ? 'auto' : 'manual');

    return Mission(
      code: (json['code'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      desc: (json['desc'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'daily',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      minLevel: (json['minLevel'] as num?)?.toInt() ?? 1,
      category: (json['category'] as String?) ?? 'habit',
      completionMode: inferredMode,
      criteria: parsedCriteria,
      scoreMin: (json['scoreMin'] as num?)?.toInt(),
      scoreMax: (json['scoreMax'] as num?)?.toInt(),
      notePrompt: json['notePrompt'] as String?,
      noteMinChars: (json['noteMinChars'] as num?)?.toInt(),
    );
  }
}

class Badge {
  final String title;
  final String description;
  final String group;

  const Badge({
    required this.title,
    required this.description,
    required this.group,
  });
}

class MissionContext {
  final MonthlyDashboard? currentDashboard;
  final List<MonthlyDashboard> history;
  final List<Expense> expenses;
  final double salary;

  const MissionContext({
    required this.currentDashboard,
    required this.history,
    required this.expenses,
    required this.salary,
  });
}

class GamificationCatalog {
  GamificationCatalog._();

  static const levels = [
    FinancialLevel(
      level: 1,
      name: 'Iniciante',
      mindset: 'Estou dando o primeiro passo',
      minXp: 0,
      premiumRequired: false,
      unlocks: ['Painel inicial', 'Registro básico'],
    ),
    FinancialLevel(
      level: 2,
      name: 'Organizado',
      mindset: 'Eu enxergo para onde vai meu dinheiro',
      minXp: 300,
      premiumRequired: false,
      unlocks: ['Relatório mensal', 'Dashboard detalhado'],
    ),
    FinancialLevel(
      level: 3,
      name: 'Planejador',
      mindset: 'Eu planejo antes de gastar',
      minXp: 800,
      premiumRequired: false,
      unlocks: ['Metas inteligentes', 'Insights Premium'],
    ),
    FinancialLevel(
      level: 4,
      name: 'Investidor',
      mindset: 'Faço o dinheiro trabalhar para mim',
      minXp: 1500,
      premiumRequired: true,
      unlocks: ['Simulador avançado', 'Status VIP'],
    ),
  ];

  static const badges = [
    Badge(
      title: 'Primeiro Passo',
      description: 'Completou o onboarding',
      group: 'Educacao e Consciencia',
    ),
    Badge(
      title: 'Olhos Abertos',
      description: 'Analisou um relatorio pela 1a vez',
      group: 'Educacao e Consciencia',
    ),
    Badge(
      title: 'Entendi o Jogo',
      description: 'Concluiu 5 conteudos educativos',
      group: 'Educacao e Consciencia',
    ),
    Badge(
      title: 'Orcamento Criado',
      description: 'Definiu seu 1o orcamento',
      group: 'Organizacao',
    ),
    Badge(
      title: 'Semana Consciente',
      description: '7 dias seguindo o plano',
      group: 'Organizacao',
    ),
    Badge(
      title: 'Gasto Sob Controle',
      description: 'Revisou um gasto impulsivo',
      group: 'Organizacao',
    ),
    Badge(
      title: 'Objetivo Definido',
      description: 'Criou um objetivo financeiro',
      group: 'Objetivos',
    ),
    Badge(
      title: 'Primeiro Marco',
      description: 'Completou 25% do objetivo',
      group: 'Objetivos',
    ),
    Badge(
      title: 'Disciplina Constante',
      description: '3 meses ativos',
      group: 'Objetivos',
    ),
    Badge(
      title: 'Gasto Consciente',
      description: 'Refletiu antes de gastar',
      group: 'Mentalidade',
    ),
    Badge(
      title: 'Autoconhecimento',
      description: '10 entradas no diario',
      group: 'Mentalidade',
    ),
    Badge(
      title: 'Menos Impulso',
      description: 'Identificou padrao emocional',
      group: 'Mentalidade',
    ),
  ];
}

class GamificationEngine {
  GamificationEngine._();

  static const Mission _dailyReviewExpense = Mission(
    code: 'daily_review_expense',
    title: 'Review 1 expense',
    desc: 'Check if category and amount are right.',
    type: 'daily',
    xp: 10,
  );
  static const Mission _dailyLogExpense = Mission(
    code: 'daily_log_expense',
    title: 'Log an expense today',
    desc: 'Keep your records up to date.',
    type: 'daily',
    xp: 15,
  );
  static const Mission _dailyBalanceRepair = Mission(
    code: 'daily_balance_repair',
    title: 'Adjust the month to stay positive',
    desc: 'Revise your planning to avoid red.',
    type: 'daily',
    xp: 15,
  );
  static const Mission _dailyVariableReflect = Mission(
    code: 'daily_variable_reflect',
    title: 'List variable costs to review',
    desc: 'Identify where you can save.',
    type: 'daily',
    xp: 15,
  );
  static const Mission _dailyInvestReview = Mission(
    code: 'daily_invest_review',
    title: 'Check investments or insights',
    desc: 'Stay on top of your growth.',
    type: 'daily',
    xp: 15,
  );

  static const Mission _weeklyBudget = Mission(
    code: 'weekly_budget',
    title: 'Log expenses on 3 days this week',
    desc: 'Consistency is key to planning.',
    type: 'weekly',
    xp: 40,
  );
  static const Mission _weeklyVariableTrim = Mission(
    code: 'weekly_variable_trim',
    title: 'Set a lower limit for variable spending this week',
    desc: 'Reclaim your breathing room.',
    type: 'weekly',
    xp: 35,
  );
  static const Mission _weeklyInvestReview = Mission(
    code: 'weekly_invest_review',
    title: 'Review an investment or calculator insight this week',
    desc: 'Plan for the long term.',
    type: 'weekly',
    xp: 35,
  );
  static const Mission _weeklyDebtAction = Mission(
    code: 'weekly_debt_action',
    title: 'Sketch a move to tackle outstanding debt',
    desc: 'One step closer to freedom.',
    type: 'weekly',
    xp: 35,
  );

  static const Mission _monthlyCloseMonth = Mission(
    code: 'monthly_close_month',
    title: 'Close the month consciously',
    desc: 'Final review of your balance.',
    type: 'monthly',
    xp: 120,
  );
  static const Mission _monthlySimplePlan = Mission(
    code: 'monthly_simple_plan',
    title: 'Define a simple plan',
    desc: 'Basic goals for the month.',
    type: 'monthly',
    xp: 120,
  );
  static const Mission _monthlyReviewPrev = Mission(
    code: 'monthly_review_prev',
    title: 'Review the previous month',
    desc: 'Learn from your patterns.',
    type: 'monthly',
    xp: 120,
  );
  static const Mission _monthlyBalanceRepair = Mission(
    code: 'monthly_balance_repair',
    title: 'Re-plan the month to stay in the green',
    desc: 'Make adjustments early.',
    type: 'monthly',
    xp: 140,
  );
  static const Mission _monthlyVariableTrim = Mission(
    code: 'monthly_variable_trim',
    title: 'Cut variable spending to reclaim breathing room',
    desc: 'Focus on essentials.',
    type: 'monthly',
    xp: 140,
  );
  static const Mission _monthlyEmergencyBuild = Mission(
    code: 'monthly_emergency_build',
    title: 'Advance your emergency fund target',
    desc: 'Your safety net grows.',
    type: 'monthly',
    xp: 140,
  );
  static const Mission _monthlyGoalReview = Mission(
    code: 'monthly_goal_review',
    title: 'Review your goals and adjust the plan',
    desc: 'Keep your eyes on the prize.',
    type: 'monthly',
    xp: 140,
  );
  static const Mission _monthlyInvestHealth = Mission(
    code: 'monthly_invest_health',
    title: 'Check that investments keep pace with goals',
    desc: 'Align wealth with purpose.',
    type: 'monthly',
    xp: 140,
  );
  static const Mission _monthlyDebtClear = Mission(
    code: 'monthly_debt_clear',
    title: 'Outline a plan to lower the debt burden',
    desc: 'Clear the path forward.',
    type: 'monthly',
    xp: 140,
  );

  static FinancialLevel currentLevel({
    required int xp,
    required bool isPremium,
  }) {
    var level = GamificationCatalog.levels.first;
    for (final item in GamificationCatalog.levels) {
      if (!isPremium && item.premiumRequired) break;
      if (xp >= item.minXp) {
        level = item;
      }
    }
    return level;
  }

  static FinancialLevel? nextLevel({
    required int xp,
    required bool isPremium,
  }) {
    for (final item in GamificationCatalog.levels) {
      if (!isPremium && item.premiumRequired) {
        return item;
      }
      if (xp < item.minXp) return item;
    }
    return null;
  }

  static const List<Mission> HARDCODED_FALLBACK = [
    Mission(
        code: 'daily_log_expense',
        title: 'Registre um gasto',
        desc: 'Mantenha seu registro em dia.',
        xp: 15,
        type: 'daily',
        minLevel: 1,
        category: 'habit'),
    Mission(
        code: 'daily_review_expense',
        title: 'Revise 1 gasto',
        desc: 'Verifique se o valor está correto.',
        xp: 10,
        type: 'daily',
        minLevel: 1,
        category: 'curiosity'),
    Mission(
        code: 'weekly_budget',
        title: 'Foco no Orçamento',
        desc: 'Registre gastos em 3 dias da semana.',
        xp: 40,
        type: 'weekly',
        minLevel: 1,
        category: 'consistency'),
    Mission(
        code: 'monthly_simple_plan',
        title: 'Defina um Plano',
        desc: 'Crie seu primeiro plano de gastos.',
        xp: 120,
        type: 'monthly',
        minLevel: 1,
        category: 'planning'),
    Mission(
        code: 'daily_balance_repair',
        title: 'Ajuste o mês',
        desc: 'Saldo negativo? Ajuste para o azul.',
        xp: 15,
        type: 'daily',
        minLevel: 3,
        category: 'recovery'),
  ];

  static List<Mission> getRotatedMissions({
    required List<Mission> allMissions,
    required int userLevel,
    required List<String> objectives,
    required MissionContext context,
  }) {
    final now = DateTime.now();
    final list = allMissions.isEmpty ? HARDCODED_FALLBACK : allMissions;
    final available = list.where((m) => m.minLevel <= userLevel).toList();
    if (available.isEmpty) return [];

    // Strict integer comparison for dates (Parity with Web)
    final hasExpenseToday = context.expenses.any((e) =>
        e.date.year == now.year &&
        e.date.month == now.month &&
        e.date.day == now.day);

    final remaining = context.currentDashboard?.remainingSalary ?? 0;
    final income = context.salary;
    final variableTotal = context.currentDashboard?.variableExpensesTotal ?? 0;
    final variablePct = income > 0 ? variableTotal / income : 0;
    final hasNegativeBalance = remaining < 0;

    // DST-safe Day of Year logic (Parity with Web)
    final startOfYear = DateTime(now.year, 1, 1);
    final diff = now.difference(startOfYear);
    final dayOfYear = diff.inDays + 1;
    final weekNumber = (dayOfYear / 7).ceil();
    final monthIndex = now.month - 1; // 0-11

    Mission? findByCode(String code) {
      try {
        return available.firstWhere((m) => m.code == code);
      } catch (_) {
        return null;
      }
    }

    // --- DAILY (1 Mission) ---
    List<Mission> selectedDaily = [];
    final dailies = available.where((m) => m.type == 'daily').toList();
    dailies.sort((a, b) => a.code.compareTo(b.code));

    if (hasNegativeBalance) {
      final m = findByCode('daily_balance_repair');
      if (m != null) selectedDaily.add(m);
    } else if (variablePct > 0.4) {
      final m = findByCode('daily_variable_reflect');
      if (m != null) selectedDaily.add(m);
    } else if (!hasExpenseToday && userLevel <= 2) {
      final m = findByCode('daily_log_expense');
      if (m != null) selectedDaily.add(m);
    }

    if (selectedDaily.isEmpty && dailies.isNotEmpty) {
      // Logic: dayOfYear % dailies.length
      selectedDaily.add(dailies[dayOfYear % dailies.length]);
    } else if (selectedDaily.length > 1) {
      selectedDaily = [selectedDaily[0]];
    }

    // --- WEEKLY (2 Missions) ---
    List<Mission> selectedWeekly = [];
    final weeklies = available.where((m) => m.type == 'weekly').toList();
    weeklies.sort((a, b) => a.code.compareTo(b.code));

    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final distinctDays = context.expenses
        .where((e) => e.date.isAfter(oneWeekAgo))
        .map((e) => "${e.date.year}-${e.date.month}-${e.date.day}")
        .toSet()
        .length;

    if (distinctDays < 3) {
      final m = findByCode('weekly_budget');
      if (m != null) selectedWeekly.add(m);
    }

    if (weeklies.isNotEmpty) {
      int attempt = 0;
      while (selectedWeekly.length < 2 && attempt < weeklies.length) {
        // Logic: (weekNumber + attempt) % weeklies.length
        final rotated = weeklies[(weekNumber + attempt) % weeklies.length];
        if (!selectedWeekly.any((m) => m.code == rotated.code)) {
          selectedWeekly.add(rotated);
        }
        attempt++;
      }
    }

    // --- MONTHLY (2 Missions) ---
    List<Mission> selectedMonthly = [];
    final monthlies = available.where((m) => m.type == 'monthly').toList();
    monthlies.sort((a, b) => a.code.compareTo(b.code));

    if (context.expenses.length < 3) {
      final m = findByCode('monthly_simple_plan');
      if (m != null) selectedMonthly.add(m);
    }
    if (hasNegativeBalance) {
      final m = findByCode('monthly_debt_clear');
      if (m != null) selectedMonthly.add(m);
    }

    if (monthlies.isNotEmpty) {
      int attempt = 0;
      while (selectedMonthly.length < 2 && attempt < monthlies.length) {
        // Logic: (monthIndex + attempt) % monthlies.length
        final rotated = monthlies[(monthIndex + attempt) % monthlies.length];
        if (!selectedMonthly.any((m) => m.code == rotated.code)) {
          selectedMonthly.add(rotated);
        }
        attempt++;
      }
    }

    return [...selectedMonthly, ...selectedWeekly, ...selectedDaily];
  }

  static String _objectiveMission(String objective, int level) {
    switch (objective.toLowerCase()) {
      case 'debts':
        return level >= 3
            ? 'Renegocie 1 divida e registre o plano'
            : 'Liste todas as dividas e custos mensais';
      case 'property':
        return level >= 3
            ? 'Simule entrada e parcelas do imovel'
            : 'Defina o valor-alvo do imovel';
      case 'trip':
        return level >= 3
            ? 'Crie um fundo da viagem com meta mensal'
            : 'Defina o custo total da viagem';
      case 'save':
        return level >= 3
            ? 'Automatize um valor para reserva'
            : 'Defina um valor minimo para guardar';
      case 'security':
        return level >= 3
            ? 'Monte 1 mes de reserva de emergencia'
            : 'Defina sua meta de reserva';
      case 'dream':
        return level >= 3
            ? 'Quebre seu sonho em 3 marcos'
            : 'Defina o prazo do sonho';
      case 'invest':
        return level >= 3
            ? 'Ajuste sua alocacao de investimentos'
            : 'Defina quanto quer investir no mes';
      case 'emergency_fund':
        return level >= 3
            ? 'Cheque 2 meses de despesas na reserva'
            : 'Comece com 1 meta simples de reserva';
      default:
        return level >= 3
            ? 'Defina 1 acao concreta para o objetivo'
            : 'Escreva seu objetivo com prazo';
    }
  }

  static String _objectiveMissionCode(String objective, int level) {
    final suffix = level >= 3 ? 'high' : 'low';
    switch (objective.toLowerCase()) {
      case 'debts':
        return 'objective_debts_$suffix';
      case 'property':
        return 'objective_property_$suffix';
      case 'trip':
        return 'objective_trip_$suffix';
      case 'save':
        return 'objective_save_$suffix';
      case 'security':
        return 'objective_security_$suffix';
      case 'dream':
        return 'objective_dream_$suffix';
      case 'invest':
        return 'objective_invest_$suffix';
      case 'emergency_fund':
        return 'objective_emergency_fund_$suffix';
      default:
        return 'objective_generic_$suffix';
    }
  }

  static bool _hasExpenseOnDate(List<Expense> expenses, DateTime date) {
    return expenses.any(
      (expense) =>
          expense.date.year == date.year &&
          expense.date.month == date.month &&
          expense.date.day == date.day,
    );
  }

  static int _uniqueExpenseDays(
      List<Expense> expenses, int days, DateTime reference) {
    final start = reference.subtract(Duration(days: days - 1));
    final seen = <String>{};
    for (final expense in expenses) {
      if (expense.date.isBefore(start) || expense.date.isAfter(reference))
        continue;
      final key =
          '${expense.date.year}-${expense.date.month}-${expense.date.day}';
      seen.add(key);
    }
    return seen.length;
  }

  static double _expensePct(double value, double salary) {
    if (salary <= 0) return 0;
    return value / salary;
  }

  static bool _needsInvestmentNudge(MissionContext context, int level) {
    if (level < 4) return false;
    final current = context.currentDashboard;
    if (current == null || context.salary <= 0) return false;
    return current.investmentsTotal < context.salary * 0.08;
  }

  static bool _hasDebtObjective(List<String> objectives) {
    return objectives.any((objective) => objective.toLowerCase() == 'debts');
  }

  static MissionProgress getMissionProgress({
    required Mission mission,
    required MissionContext context,
    required FinancialLevel level,
    required int accountAgeDays,
    required List<String> objectives,
    UserProfile? user,
  }) {
    final now = DateTime.now();
    final dashboards = context.history;
    final current = context.currentDashboard;
    final expenses = context.expenses;

    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    bool withinDays(DateTime date, int days) {
      final start = DateTime(now.year, now.month, now.day).subtract(
        Duration(days: days - 1),
      );
      return date.isAfter(start.subtract(const Duration(seconds: 1)));
    }

    // Helper to count unique days with expenses in range
    int countUniqueExpenseDays(int days) {
      return expenses
          .where((e) => withinDays(e.date, days))
          .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
          .toSet()
          .length;
    }

    // Helper helpers
    bool hasExpenseToday = expenses.any((e) => isSameDay(e.date, now));

    // Logic per mission
    switch (mission.code) {
      case 'daily_review_expense': // "Revise 1 expense"
        return MissionProgress(current: hasExpenseToday ? 1 : 0, total: 1);

      case 'daily_log_expense': // "Log 1 expense"
        return MissionProgress(current: hasExpenseToday ? 1 : 0, total: 1);

      case 'weekly_budget': // "Log expenses on 3 days this week"
        final count = countUniqueExpenseDays(7);
        return MissionProgress(current: count, total: 3);

      case 'weekly_no_impulse_7': // "7 days without impulse"
        return MissionProgress(current: 0, total: 1);

      case 'weekly_no_impulse_3':
        return MissionProgress(current: 0, total: 1);

      default:
        return MissionProgress(current: 0, total: 1);
    }
  }
}
