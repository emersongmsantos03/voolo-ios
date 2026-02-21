import 'dart:async';
import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../models/expense.dart';
import '../models/monthly_dashboard.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/finance_score_utils.dart';

class DashboardState extends ChangeNotifier {
  late int _month;
  late int _year;

  MonthlyDashboard? _dashboard;

  StreamSubscription<List<Expense>>? _transactionsSubscription;
  late final VoidCallback _incomeListener;
  String? _fixedEnsuredMonthYear;
  int _fixedEnsureRunId = 0;

  DashboardState() {
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _incomeListener = () {
      final salary =
          LocalStorageService.incomeTotalForMonth(DateTime(_year, _month, 1));
      if (_dashboard == null) return;
      _dashboard = _dashboard?.copyWith(salary: salary);
      notifyListeners();
    };
    LocalStorageService.incomeNotifier.addListener(_incomeListener);
    loadDashboard();
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    LocalStorageService.incomeNotifier.removeListener(_incomeListener);
    super.dispose();
  }

  MonthlyDashboard? get dashboard => _dashboard;

  int get month => _month;
  int get year => _year;

  double get totalExpenses => _dashboard?.totalExpenses ?? 0;
  double get totalInvested => _dashboard?.investmentsTotal ?? 0;
  double get balance => _dashboard?.remainingSalary ?? 0;

  // New Analytical Getters
  HealthScoreResult get healthResult {
    final d = _dashboard;
    if (d == null || d.salary <= 0) {
      return HealthScoreResult(
        score: 0,
        status: 'critical',
        tip: 'Add your income to calculate your financial health.',
        tipKey: 'score_tip_add_income',
        needsIncome: true,
      );
    }

    final user = LocalStorageService.getUserProfile();
    final housing = d.expenses
        .where((e) => e.category == ExpenseCategory.moradia && !e.isInvestment)
        .fold(0.0, (a, b) => a + b.amount);

    return FinanceScoreUtils.computeFinancialHealthScore(
      income: d.salary,
      fixed: d.fixedExpensesTotal,
      variable: d.variableExpensesTotal,
      investContribution: d.investmentsTotal,
      housing: housing,
      propertyValue: user?.propertyValue ?? 0.0,
      investBalance: user?.investBalance,
    );
  }

  int get financialScore => healthResult.score;

  bool _ignoreCreditInstallments(Expense e) {
    if (!e.isFixed) return false;
    if (!e.isCreditCard) return false;
    final count = e.installments ?? 0;
    return count > 0 && count <= 3;
  }

  String get scoreTip => healthResult.tip;

  String scoreTipFor(BuildContext context) {
    return FinanceScoreUtils.localizeTip(
      healthResult,
      tr: (key, params) => AppStrings.tr(context, key, params),
    );
  }

  List<String> getTimelineItems(BuildContext context) {
    final d = _dashboard;
    if (d == null) return [];

    final dashboards = List<MonthlyDashboard>.from(
      LocalStorageService.getAllDashboards(),
    );
    if (dashboards.isEmpty) return [];
    dashboards.sort((a, b) {
      final aKey = a.year * 12 + a.month;
      final bKey = b.year * 12 + b.month;
      return aKey.compareTo(bKey);
    });

    final items = <String>[];
    final currentKey = _year * 12 + _month;
    final prev = dashboards.lastWhere(
      (x) => x.year * 12 + x.month < currentKey,
      orElse: () => d,
    );

    if (prev.variableExpensesTotal > 0 && prev != d) {
      final change = ((d.variableExpensesTotal - prev.variableExpensesTotal) /
              prev.variableExpensesTotal) *
          100;
      if (change.abs() >= 10) {
        final direction = change > 0
            ? AppStrings.t(context, 'timeline_more')
            : AppStrings.t(context, 'timeline_less');
        items.add(
          AppStrings.tr(
            context,
            'timeline_variable_change',
            {
              'pct': change.abs().toStringAsFixed(0),
              'direction': direction,
            },
          ),
        );
      }
    }

    if (prev.fixedExpensesTotal > 0 && prev != d) {
      final change = ((d.fixedExpensesTotal - prev.fixedExpensesTotal) /
              prev.fixedExpensesTotal) *
          100;
      if (change.abs() >= 10) {
        final direction = change > 0
            ? AppStrings.t(context, 'timeline_more')
            : AppStrings.t(context, 'timeline_less');
        items.add(
          AppStrings.tr(
            context,
            'timeline_fixed_change',
            {
              'pct': change.abs().toStringAsFixed(0),
              'direction': direction,
            },
          ),
        );
      }
    }

    int streak = 0;
    for (var i = dashboards.length - 1; i > 0; i--) {
      if (dashboards[i].investmentsTotal > dashboards[i - 1].investmentsTotal) {
        streak++;
      } else {
        break;
      }
    }
    if (streak >= 2) {
      items.add(
        AppStrings.tr(
          context,
          'timeline_invest_streak',
          {'months': '$streak'},
        ),
      );
    }
    return items;
  }

  // ================= LOAD =================

  void loadDashboard() {
    final base = LocalStorageService.getDashboard(_month, _year);
    final salary =
        LocalStorageService.incomeTotalForMonth(DateTime(_year, _month, 1));
    _dashboard = base != null
        ? base.copyWith(
            salary: salary > 0 ? salary : base.salary,
          )
        : MonthlyDashboard(
            month: _month,
            year: _year,
            salary: salary,
            expenses: [],
          );

    // Subscribe to transactions for real-time updates
    _transactionsSubscription?.cancel();
    final runId = ++_fixedEnsureRunId;
    _transactionsSubscription =
        LocalStorageService.watchTransactions(_month, _year).listen((txs) {
      _dashboard = _dashboard?.copyWith(expenses: txs);
      notifyListeners();

      final monthYear =
          '${_year.toString().padLeft(4, '0')}-${_month.toString().padLeft(2, '0')}';
      if (_fixedEnsuredMonthYear == monthYear) return;
      _fixedEnsuredMonthYear = monthYear;

      // Fire-and-forget: ensure recurring fixed expenses for this month (web parity).
      () async {
        if (runId != _fixedEnsureRunId) return;
        await LocalStorageService.ensureFixedExpensesForMonth(
          month: _month,
          year: _year,
          monthTransactions: txs,
        );
      }();
    });

    notifyListeners();
  }

  // ================= DATE =================

  void changeMonth(int month, int year) {
    _month = month;
    _year = year;
    loadDashboard();
  }

  // ================= EXPENSES =================

  double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  Future<void> _addCreditInstallments(Expense expense) async {
    final installments = expense.installments ?? 0;
    if (installments <= 1) {
      await LocalStorageService.saveExpense(expense);
      return;
    }

    final user = LocalStorageService.getUserProfile();
    final baseAmount = _roundMoney(expense.amount / installments);
    for (var i = 0; i < installments; i++) {
      // ... (same logic for generation)
      final isLast = i == installments - 1;
      final amountPer = isLast
          ? _roundMoney(expense.amount - baseAmount * (installments - 1))
          : baseAmount;

      final targetMonth = _month + i;
      final yearOffset = (targetMonth - 1) ~/ 12;
      final month = ((targetMonth - 1) % 12) + 1;
      final year = _year + yearOffset;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final safeDay = expense.dueDay == null
          ? 1
          : (expense.dueDay! > daysInMonth ? daysInMonth : expense.dueDay!);
      final date = DateTime(year, month, safeDay);

      final perExpense = Expense(
        id: '${expense.id}-$i',
        name: expense.name,
        type: expense.type,
        category: expense.category,
        amount: amountPer,
        date: date,
        dueDay: expense.dueDay,
        isCreditCard: true,
        creditCardId: expense.creditCardId,
        isCardRecurring: false,
        installments: installments,
        installmentIndex: i + 1,
      );

      await LocalStorageService.saveExpense(perExpense);
    }
  }

  Future<void> addExpense(Expense expense) async {
    if (expense.isFixed &&
        expense.isCreditCard &&
        (expense.installments ?? 0) > 1) {
      await _addCreditInstallments(expense);
      return;
    }

    await LocalStorageService.saveExpense(expense);

    if (expense.isFixed && !expense.isCreditCard) {
      NotificationService.scheduleExpenseReminder(expense);
    }
  }

  Future<void> removeExpense(String expenseId) async {
    await LocalStorageService.deleteExpense(expenseId);
  }

  // ================= SAVE =================

  void save() {
    if (_dashboard == null) return;
    LocalStorageService.saveDashboard(_dashboard!);
    notifyListeners();
  }
}
