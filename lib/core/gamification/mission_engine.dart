import '../../models/expense.dart';
import '../../models/monthly_dashboard.dart';
import '../../models/user_profile.dart';
import '../../utils/finance_score_utils.dart';
import 'gamification.dart';
import 'mission_progress.dart';

class MissionEngineContext {
  final DateTime today;
  final UserProfile user;
  final MonthlyDashboard dashboard;
  final List<Expense> expenses;
  final List<dynamic> goals; // goals are optional; keep dynamic to avoid extra deps
  final bool budgetsDefinedThisMonth;
  final bool investmentProfileSet;
  final bool debtPlanGeneratedThisMonth;

  final HealthScoreResult scoreResult;
  final double remaining;
  final Map<String, double> ratios;

  MissionEngineContext({
    required this.today,
    required this.user,
    required this.dashboard,
    required this.expenses,
    required this.goals,
    this.budgetsDefinedThisMonth = false,
    this.investmentProfileSet = false,
    this.debtPlanGeneratedThisMonth = false,
  })  : scoreResult = FinanceScoreUtils.computeFinancialHealthScore(
          income: dashboard.salary,
          fixed: dashboard.fixedExpensesTotal,
          variable: dashboard.variableExpensesTotal,
          investContribution: dashboard.investmentsTotal,
          housing: dashboard.expenses
              .where((e) => e.category == ExpenseCategory.moradia && !e.isInvestment)
              .fold(0.0, (a, b) => a + b.amount),
        ),
        remaining = dashboard.salary -
            (dashboard.fixedExpensesTotal +
                dashboard.variableExpensesTotal +
                dashboard.investmentsTotal),
        ratios = (() {
          final income = dashboard.salary;
          if (income <= 0) {
            return const <String, double>{
              'fixed': 0.0,
              'variable': 0.0,
              'invest': 0.0,
              'housing': 0.0,
              'buffer': 0.0,
            };
          }
          final housing = dashboard.expenses
              .where((e) => e.category == ExpenseCategory.moradia && !e.isInvestment)
              .fold(0.0, (a, b) => a + b.amount);
          return {
            'fixed': dashboard.fixedExpensesTotal / income,
            'variable': dashboard.variableExpensesTotal / income,
            'invest': dashboard.investmentsTotal / income,
            'housing': housing / income,
            'buffer': (income -
                    (dashboard.fixedExpensesTotal +
                        dashboard.variableExpensesTotal +
                        dashboard.investmentsTotal)) /
                income,
          };
        })();
}

class MissionEngine {
  MissionEngine._();

  static ({int isoYear, int week}) _isoWeekYearAndWeek(DateTime today) {
    final d = DateTime.utc(today.year, today.month, today.day);
    final weekday = d.weekday; // 1..7 (Mon..Sun)

    // Thursday determines the ISO week-year.
    final thursday = d.add(Duration(days: 4 - weekday));
    final isoYear = thursday.year;

    // Week 1 is the week with Jan 4th.
    final jan4 = DateTime.utc(isoYear, 1, 4);
    final jan4Weekday = jan4.weekday;
    final jan4Thursday = jan4.add(Duration(days: 4 - jan4Weekday));

    final week = (thursday.difference(jan4Thursday).inDays ~/ 7) + 1;
    return (isoYear: isoYear, week: week);
  }

  static int _periodSeed(DateTime today, String type) {
    final y = today.year;
    final m = today.month.toString().padLeft(2, '0');
    final d = today.day.toString().padLeft(2, '0');
    if (type == 'daily') return int.parse('$y$m$d');
    if (type == 'weekly') {
      final iso = _isoWeekYearAndWeek(today);
      final w = iso.week.toString().padLeft(2, '0');
      return int.parse('${iso.isoYear}$w');
    }
    return int.parse('$y$m');
  }

  static DateTime periodStart(DateTime today, String type) {
    final t = DateTime(today.year, today.month, today.day);
    if (type == 'daily') return t;
    if (type == 'weekly') {
      // ISO week start (Monday).
      return t.subtract(Duration(days: t.weekday - 1));
    }
    return DateTime(today.year, today.month, 1);
  }

  static String missionIdFor(Mission mission, DateTime today) {
    final now = DateTime(today.year, today.month, today.day);
    late String periodKey;

    if (mission.type == 'daily') {
      periodKey =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    } else if (mission.type == 'weekly') {
      final iso = _isoWeekYearAndWeek(now);
      periodKey = '${iso.isoYear}W${iso.week.toString().padLeft(2, '0')}';
    } else {
      periodKey = '${now.year}${now.month.toString().padLeft(2, '0')}';
    }

    return '${mission.type}_${periodKey}_${mission.code}';
  }

  static MissionProgress progressFor(Mission mission, MissionEngineContext ctx) {
    final mode = mission.completionMode;
    final criteria = mission.criteria;

    if (criteria == null || criteria['kind'] == null) {
      if (mode == 'note') {
        final id = missionIdFor(mission, ctx.today);
        final note = ctx.user.missionNotes[id];
        final ok = note != null && note.trim().isNotEmpty;
        return MissionProgress(current: ok ? 1 : 0, total: 1);
      }
      return MissionProgress(current: mode == 'auto' ? 0 : 1, total: 1);
    }

    final kind = (criteria['kind'] as String?) ?? '';
    final type = mission.type;
    final start = periodStart(ctx.today, type);
    final end = DateTime(ctx.today.year, ctx.today.month, ctx.today.day, 23, 59, 59, 999);

    bool within(DateTime? d) {
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }

    bool matchExpense(Expense e) {
      final expenseType = criteria['expenseType'] as String?;
      if (expenseType != null && expenseType.isNotEmpty && e.type.name != expenseType) return false;
      final category = criteria['category'] as String?;
      if (category != null && category.isNotEmpty && e.category.name != category) return false;
      final isPaid = criteria['isPaid'];
      if (isPaid is bool && e.isPaid != isPaid) return false;
      return true;
    }

    final periodExpenses = ctx.expenses.where((e) {
      final d = e.date;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();

    int targetInt() => (criteria['target'] as num?)?.toInt() ?? 0;
    double targetDouble() => (criteria['target'] as num?)?.toDouble() ?? 0.0;

    if (kind == 'expense_count') {
      final target = targetInt();
      final current = periodExpenses.where(matchExpense).length;
      return MissionProgress(current: current, total: target);
    }

    if (kind == 'expense_distinct_days') {
      final target = targetInt();
      final days = periodExpenses
          .where(matchExpense)
          .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
          .toSet();
      return MissionProgress(current: days.length, total: target);
    }

    if (kind == 'paid_count') {
      final target = targetInt();
      final current = periodExpenses.where((e) => matchExpense(e) && e.isPaid).length;
      return MissionProgress(current: current, total: target);
    }

    if (kind == 'report_viewed') {
      return MissionProgress(current: within(ctx.user.lastReportViewedAt) ? 1 : 0, total: 1);
    }

    if (kind == 'calculator_opened') {
      return MissionProgress(current: within(ctx.user.lastCalculatorOpenedAt) ? 1 : 0, total: 1);
    }

    if (kind == 'goals_total') {
      final target = targetInt();
      return MissionProgress(current: ctx.goals.length, total: target);
    }

    if (kind == 'goals_completed') {
      final target = targetInt();
      final current = ctx.goals.where((g) => (g as dynamic).completed == true).length;
      return MissionProgress(current: current, total: target);
    }

    if (kind == 'remaining_non_negative') {
      return MissionProgress(current: ctx.remaining >= 0 ? 1 : 0, total: 1);
    }

    if (kind == 'remaining_at_least') {
      final target = targetDouble();
      final current = ctx.remaining;
      return MissionProgress(
        current: current.isFinite ? current.clamp(0, target).round() : 0,
        total: target.round(),
      );
    }

    if (kind == 'ratio_at_least') {
      final metric = (criteria['metric'] as String?) ?? '';
      final target = targetDouble();
      final current = ctx.ratios[metric] ?? 0.0;
      return MissionProgress(
        current: (current.clamp(0.0, target) * 1000).round(),
        total: (target * 1000).round(),
      );
    }

    if (kind == 'ratio_at_most') {
      final metric = (criteria['metric'] as String?) ?? '';
      final target = targetDouble();
      final current = ctx.ratios[metric] ?? 0.0;
      final remaining = (target - current).clamp(0.0, target);
      return MissionProgress(
        current: (remaining * 1000).round(),
        total: (target * 1000).round(),
      );
    }

    if (kind == 'budgets_defined') {
      return MissionProgress(
        current: ctx.budgetsDefinedThisMonth ? 1 : 0,
        total: 1,
      );
    }

    if (kind == 'investment_profile_set') {
      return MissionProgress(
        current: ctx.investmentProfileSet ? 1 : 0,
        total: 1,
      );
    }

    if (kind == 'debt_plan_generated') {
      return MissionProgress(
        current: ctx.debtPlanGeneratedThisMonth ? 1 : 0,
        total: 1,
      );
    }

    return const MissionProgress(current: 0, total: 1);
  }

  static bool eligible(Mission mission, MissionEngineContext ctx, int userLevel) {
    if (mission.minLevel > userLevel) return false;
    return true;
  }

  static RotatedMissions selectRotated({
    required List<Mission> defaults,
    required List<Mission> dbMissions,
    required MissionEngineContext ctx,
    required int userLevel,
    required int dailyCount,
    required int weeklyCount,
    required int monthlyCount,
  }) {
    final byKey = <String, Mission>{};
    for (final m in defaults) {
      byKey['${m.type}:${m.code}'] = m;
    }
    for (final m in dbMissions) {
      byKey['${m.type}:${m.code}'] = m;
    }

    final catalog = byKey.values.where((m) => eligible(m, ctx, userLevel)).toList();

    List<Mission> selectType(String type, int count) {
      final pool = catalog.where((m) => m.type == type).toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      if (pool.isEmpty) return const [];

      // IMPORTANT: Do NOT replace missions immediately after completion.
      // The active set is stable within the current cycle (day/week/month).
      final seed = _periodSeed(ctx.today, type);
      final start = seed % pool.length;

      final selected = <Mission>[];
      for (var i = 0; i < pool.length && selected.length < count; i++) {
        selected.add(pool[(start + i) % pool.length]);
      }
      return selected;
    }

    return RotatedMissions(
      daily: selectType('daily', dailyCount),
      weekly: selectType('weekly', weeklyCount),
      monthly: selectType('monthly', monthlyCount),
    );
  }
}

class RotatedMissions {
  final List<Mission> daily;
  final List<Mission> weekly;
  final List<Mission> monthly;

  const RotatedMissions({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });
}
