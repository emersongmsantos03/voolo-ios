import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/responsive.dart';
import '../../models/expense.dart';
import '../../models/monthly_dashboard.dart';
import '../../services/engagement_analytics_service.dart';
import '../../services/habits_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/premium_tour_widgets.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late DateTime _currentMonth;
  MonthlyDashboard? _dashboard;
  List<Expense> _currentExpenses = const [];
  List<Expense> _prevExpenses = const [];
  StreamSubscription<List<Expense>>? _transactionsSub;
  HabitState? _habitState;
  bool _habitLoading = false;
  late final VoidCallback _habitsListener;
  bool _tourMode = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    unawaited(EngagementAnalyticsService.trackScreenView(surface: 'insights'));

    _habitsListener = () {
      if (!mounted) return;
      setState(() => _habitState = HabitsService.notifier.value);
    };
    HabitsService.notifier.addListener(_habitsListener);

    _loadDashboard();
    _listenTransactions();
    _loadPrevExpenses();
    _loadHabits();
    final user = LocalStorageService.getUserProfile();
    if (user != null && user.isPremium) {
      LocalStorageService.markReportViewed();
    }
  }

  @override
  void dispose() {
    _transactionsSub?.cancel();
    HabitsService.notifier.removeListener(_habitsListener);
    super.dispose();
  }

  void _loadDashboard() {
    _dashboard = LocalStorageService.getDashboard(
      _currentMonth.month,
      _currentMonth.year,
    );
    setState(() {});
  }

  void _listenTransactions() {
    _transactionsSub?.cancel();
    _transactionsSub = LocalStorageService.watchTransactions(
      _currentMonth.month,
      _currentMonth.year,
    ).listen((items) {
      final deduped = _dedupeExpenses(items);
      if (!mounted) return;
      setState(() {
        _currentExpenses = deduped;
      });
    });
  }

  Future<void> _loadPrevExpenses() async {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    try {
      final items = await LocalStorageService.watchTransactions(
        prev.month,
        prev.year,
      ).first;
      if (!mounted) return;
      setState(() => _prevExpenses = _dedupeExpenses(items));
    } catch (_) {
      if (!mounted) return;
      setState(() => _prevExpenses = const []);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final enable = args is Map &&
        args['premiumTour'] == true &&
        args['tourStep'] == 'insights';
    if (enable != _tourMode) {
      setState(() => _tourMode = enable);
    }
  }

  Future<void> _loadHabits() async {
    setState(() => _habitLoading = true);
    final state = await HabitsService.load();
    if (!mounted) return;
    setState(() {
      _habitState = state;
      _habitLoading = false;
    });
  }

  Future<void> _toggleHabit(String habitId, int total) async {
    setState(() => _habitLoading = true);
    final next = await HabitsService.toggleHabit(
      habitId: habitId,
      totalHabits: total,
    );
    if (!mounted) return;
    setState(() {
      _habitState = next;
      _habitLoading = false;
    });
  }

  MonthlyDashboard? _previousMonthDashboard() {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final base = LocalStorageService.getDashboard(prev.month, prev.year);
    final salaryFallback = LocalStorageService.incomeTotalForMonth(prev);
    if (base == null && salaryFallback <= 0 && _prevExpenses.isEmpty) {
      return null;
    }
    final salary = base?.salary ?? salaryFallback;
    return MonthlyDashboard(
      month: prev.month,
      year: prev.year,
      salary: salary,
      expenses: _prevExpenses,
      creditCardPayments: base?.creditCardPayments ?? const {},
    );
  }

  MonthlyDashboard? _currentView() {
    final base = _dashboard;
    final salaryFallback =
        LocalStorageService.incomeTotalForMonth(_currentMonth);
    if (base == null && salaryFallback <= 0 && _currentExpenses.isEmpty) {
      return null;
    }
    final salary = base?.salary ?? salaryFallback;
    return MonthlyDashboard(
      month: _currentMonth.month,
      year: _currentMonth.year,
      salary: salary,
      expenses: _currentExpenses,
      creditCardPayments: base?.creditCardPayments ?? const {},
    );
  }

  List<Expense> _dedupeExpenses(List<Expense> items) {
    final seen = <String>{};
    final deduped = <Expense>[];

    String normalizeName(String? val) {
      return (val ?? '').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    }

    String dateKeyFor(Expense tx) {
      final year = tx.date.year;
      final month = tx.date.month.toString().padLeft(2, '0');
      if (tx.type == ExpenseType.fixed && tx.dueDay != null) {
        final day = tx.dueDay!.toString().padLeft(2, '0');
        return '$year-$month-$day';
      }
      return '$year-$month-${tx.date.day.toString().padLeft(2, '0')}';
    }

    for (final tx in items) {
      final key = [
        normalizeName(tx.name),
        tx.amount.toStringAsFixed(2),
        dateKeyFor(tx),
        tx.type.name,
        tx.isCreditCard ? 'cc' : 'no',
        tx.installments?.toString() ?? '',
        tx.installmentIndex?.toString() ?? '',
      ].join('|');
      if (seen.contains(key)) continue;
      seen.add(key);
      deduped.add(tx);
    }
    return deduped;
  }

  List<String> _budgetAdvice(MonthlyDashboard d) {
    if (d.salary <= 0) {
      return [AppStrings.t(context, 'alert_add_income')];
    }

    final fixedPct = (d.fixedExpensesTotal / d.salary) * 100;
    final variablePct = (d.variableExpensesTotal / d.salary) * 100;
    final investPct = (d.investmentsTotal / d.salary) * 100;
    final housingPct = d.expenses
            .where(
                (e) => e.category == ExpenseCategory.moradia && !e.isInvestment)
            .fold(0.0, (a, b) => a + b.amount) /
        d.salary *
        100;

    final tips = <String>[];

    if (fixedPct > 50) {
      tips.add(AppStrings.t(context, 'alert_fixed_high'));
    } else {
      tips.add(AppStrings.t(context, 'plan_action_ok'));
    }

    if (variablePct > 30) {
      tips.add(AppStrings.t(context, 'alert_variable_high'));
    }

    if (investPct < 15) {
      tips.add(AppStrings.t(context, 'alert_invest_low'));
    }

    if (housingPct > 35) {
      tips.add(AppStrings.t(context, 'tip_housing_high'));
    }

    return tips;
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textPrimary(context),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );
  }

  Widget _alertsCard(MonthlyDashboard d) {
    final salary = d.salary;
    final alerts = <String>[];
    if (salary <= 0) {
      alerts.add(AppStrings.t(context, 'alert_add_income'));
    } else {
      final fixedPct = (d.fixedExpensesTotal / salary) * 100;
      final variablePct = (d.variableExpensesTotal / salary) * 100;
      final investPct = (d.investmentsTotal / salary) * 100;
      if (fixedPct > 55) alerts.add(AppStrings.t(context, 'alert_fixed_high'));
      if (variablePct > 35) {
        alerts.add(AppStrings.t(context, 'alert_variable_high'));
      }
      if (investPct < 10) alerts.add(AppStrings.t(context, 'alert_invest_low'));
      if (d.remainingSalary < 0) {
        alerts.add(AppStrings.t(context, 'alert_negative_balance'));
      }
    }
    if (alerts.isEmpty) alerts.add(AppStrings.t(context, 'alert_ok'));

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.t(context, 'alert_title')),
          const SizedBox(height: 8),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert,
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(MonthlyDashboard d) {
    final salary = d.salary;
    final fixedPct = salary > 0 ? (d.fixedExpensesTotal / salary) * 100 : 0.0;
    final variablePct =
        salary > 0 ? (d.variableExpensesTotal / salary) * 100 : 0.0;
    final investPct = salary > 0 ? (d.investmentsTotal / salary) * 100 : 0.0;

    String action;
    if (salary <= 0) {
      action = AppStrings.t(context, 'score_add_income');
    } else if (variablePct > 30) {
      action = AppStrings.t(context, 'plan_action_variable');
    } else if (fixedPct > 50) {
      action = AppStrings.t(context, 'plan_action_fixed');
    } else if (investPct < 15) {
      final target = (salary * 0.15) - d.investmentsTotal;
      final value =
          target > 0 ? CurrencyUtils.format(target) : CurrencyUtils.format(0);
      action = AppStrings.tr(context, 'plan_action_invest', {'value': value});
    } else {
      action = AppStrings.t(context, 'plan_action_ok');
    }

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.t(context, 'plan_title')),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, 'plan_subtitle'),
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _planMetric(AppStrings.t(context, 'summary_fixed'), fixedPct,
                  AppTheme.danger),
              _planMetric(AppStrings.t(context, 'summary_variable'),
                  variablePct, AppTheme.warning),
              _planMetric(AppStrings.t(context, 'summary_invest'), investPct,
                  AppTheme.info),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t(context, 'plan_next_action'),
            style:
                TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            action,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardStatementsInsight(MonthlyDashboard d) {
    final cardExpenses = d.expenses.where((e) => e.isCreditCard).toList();
    if (cardExpenses.isEmpty) return const SizedBox.shrink();
    final total = cardExpenses.fold(0.0, (a, b) => a + b.amount);
    if (total <= 0) return const SizedBox.shrink();

    final salary = d.salary;
    final pct = salary > 0 ? (total / salary) * 100 : 0.0;
    final message = pct >= 30
        ? AppStrings.tr(
            context,
            'card_insight_high',
            {
              'value': CurrencyUtils.format(total),
              'pct': pct.toStringAsFixed(0),
            },
          )
        : AppStrings.tr(
            context,
            'card_insight_ok',
            {
              'value': CurrencyUtils.format(total),
              'pct': pct.toStringAsFixed(0),
            },
          );

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.t(context, 'card_insight_title')),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _planMetric(String label, double pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style:
                TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonCard(MonthlyDashboard d) {
    final prev = _previousMonthDashboard();
    if (prev == null) {
      return _cardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.t(context, 'compare_title')),
            const SizedBox(height: 6),
            Text(
              AppStrings.t(context, 'compare_no_data'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      );
    }

    Widget row(String label, double current, double previous, Color color) {
      final diff = current - previous;
      final up = diff > 0;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary(context))),
          Row(
            children: [
              Icon(
                up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: up ? AppTheme.danger : AppTheme.success,
              ),
              const SizedBox(width: 4),
              Text(
                CurrencyUtils.format(diff.abs()),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      );
    }

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.t(context, 'compare_title')),
          const SizedBox(height: 10),
          row(AppStrings.t(context, 'summary_fixed'), d.fixedExpensesTotal,
              prev.fixedExpensesTotal, AppTheme.danger),
          const SizedBox(height: 6),
          row(
              AppStrings.t(context, 'summary_variable'),
              d.variableExpensesTotal,
              prev.variableExpensesTotal,
              AppTheme.warning),
          const SizedBox(height: 6),
          row(AppStrings.t(context, 'summary_invest'), d.investmentsTotal,
              prev.investmentsTotal, AppTheme.info),
          const SizedBox(height: 6),
          row(AppStrings.t(context, 'summary_free'), d.remainingSalary,
              prev.remainingSalary, AppTheme.success),
        ],
      ),
    );
  }

  Widget _tipsCard(MonthlyDashboard d) {
    final tips = _budgetAdvice(d);
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.t(context, 'tips_title')),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $tip',
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _habitsCard() {
    final habits = [
      _HabitDefinition(
        id: 'log_expense',
        title: AppStrings.t(context, 'habit_log_expense'),
        subtitle: AppStrings.t(context, 'habit_log_expense_subtitle'),
        icon: Icons.edit_note,
      ),
      _HabitDefinition(
        id: 'check_budget',
        title: AppStrings.t(context, 'habit_check_budget'),
        subtitle: AppStrings.t(context, 'habit_check_budget_subtitle'),
        icon: Icons.task_alt,
      ),
      _HabitDefinition(
        id: 'invest_week',
        title: AppStrings.t(context, 'habit_invest'),
        subtitle: AppStrings.t(context, 'habit_invest_subtitle'),
        icon: Icons.savings,
      ),
    ];

    final done = _habitState?.done ?? [];
    final streak = _habitState?.streak ?? 0;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(AppStrings.t(context, 'habit_title')),
              const Spacer(),
              Text(
                AppStrings.tr(context, 'habit_streak', {'days': '$streak'}),
                style: TextStyle(
                    color: AppTheme.textSecondary(context), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...habits.map(
            (habit) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(habit.icon, color: AppTheme.textSecondary(context)),
              title: Text(
                habit.title,
                style: TextStyle(color: AppTheme.textPrimary(context)),
              ),
              subtitle: Text(
                habit.subtitle,
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              trailing: _habitLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Checkbox(
                      value: done.contains(habit.id),
                      onChanged: (_) => _toggleHabit(habit.id, habits.length),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalStorageService.getUserProfile();
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t(context, 'insights_title'))),
        body: Center(
          child: Text(
            AppStrings.t(context, 'login_required_reports'),
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      );
    }

    final d = _currentView();
    if (d == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t(context, 'insights_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final hasCardExpenses = d.expenses.any((e) => e.isCreditCard);

    final content = Padding(
      padding: Responsive.pagePadding(context),
      child: ListView(
        children: [
          Text(
            AppStrings.t(context, 'insights_subtitle'),
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          PremiumTourHighlight(active: _tourMode, child: _alertsCard(d)),
          const SizedBox(height: 16),
          _planCard(d),
          if (hasCardExpenses) ...[
            const SizedBox(height: 16),
            _cardStatementsInsight(d),
          ],
          _comparisonCard(d),
          const SizedBox(height: 16),
          _tipsCard(d),
          const SizedBox(height: 16),
          _habitsCard(),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'insights_title')),
      ),
      body: PremiumTourOverlay(
        active: _tourMode,
        spotlight: PremiumTourSpotlight(
          icon: Icons.lightbulb_rounded,
          title: AppStrings.t(context, 'premium_tour_insights_title'),
          body: AppStrings.t(context, 'premium_tour_insights_body'),
          location: AppStrings.t(context, 'premium_tour_insights_location'),
          tip: AppStrings.t(context, 'premium_tour_insights_tip'),
        ),
        child: content,
      ),
    );
  }
}

class _HabitDefinition {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _HabitDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
