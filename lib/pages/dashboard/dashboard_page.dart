import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetx/core/gamification/gamification.dart';
import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/models/credit_card.dart';
import 'package:jetx/models/debt_v2.dart';
import 'package:jetx/models/expense.dart';
import 'package:jetx/models/income_source.dart';
import 'package:jetx/models/monthly_dashboard.dart';
import 'package:jetx/models/user_profile.dart';
import 'package:jetx/core/plans/user_plan.dart';
import 'package:jetx/pages/onboarding/premium_onboarding_page.dart';
import 'package:jetx/models/financial_insight.dart';
import 'package:jetx/routes/app_routes.dart';
import 'package:jetx/services/financial_insight_service.dart';
import 'package:jetx/services/engagement_analytics_service.dart';
import 'package:jetx/services/firestore_service.dart';
import 'package:jetx/services/local_storage_service.dart';
import 'package:jetx/services/habits_service.dart';
import 'package:jetx/services/notification_service.dart';
import 'package:jetx/services/weekly_action_service.dart';
import 'package:jetx/services/weekly_plan_service.dart';
import 'package:jetx/state/locale_state.dart';
import 'package:jetx/state/theme_state.dart';
import 'package:jetx/core/theme/app_theme.dart';
import 'package:jetx/core/ui/formatters/money_text_input_formatter.dart';
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/core/utils/sensitive_display.dart';
import 'package:jetx/utils/money_input.dart';
import 'package:jetx/utils/date_utils.dart';
import 'package:jetx/utils/budget_rule_utils.dart';
import 'package:jetx/utils/finance_score_utils.dart';
import 'package:jetx/utils/finance_overview_utils.dart';
import 'package:jetx/utils/income_category_utils.dart';
import 'package:jetx/widgets/educational_empty_state.dart';
import 'package:jetx/widgets/money_visibility_button.dart';
import 'package:jetx/widgets/modals/income_modal.dart';
import 'package:jetx/widgets/premium_gate.dart';
import 'package:provider/provider.dart';
import '../../utils/recurring_expense_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _currentMonth;
  UserProfile? _user;
  MonthlyDashboard? _dashboard;
  HabitState? _habitState;
  bool _habitLoading = false;
  late final VoidCallback _habitsListener;
  late final VoidCallback _userListener;
  late final VoidCallback _dashboardListener;
  bool _wasPremium = false;
  final _insightService = FinancialInsightService();
  List<FinancialInsight> _insights = [];
  int _score = 0;
  String _scoreStatus = 'critical';
  HealthScoreResult? _scoreResult;
  List<String> _timeline = [];
  StreamSubscription<List<Expense>>? _transactionsSubscription;
  StreamSubscription<List<DebtV2>>? _debtsSubscription;
  bool _hasOpenDebts = false;
  bool _essentialGuideHandledInSession = false;
  String? _selectedBillCardId;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _wasPremium = LocalStorageService.getUserProfile()?.isPremium ?? false;
    unawaited(EngagementAnalyticsService.trackScreenView(surface: 'dashboard'));

    _habitsListener = () {
      if (!mounted) return;
      setState(() => _habitState = HabitsService.notifier.value);
    };
    HabitsService.notifier.addListener(_habitsListener);

    _userListener = () {
      if (mounted) _load();
    };
    LocalStorageService.userNotifier.addListener(_userListener);
    _dashboardListener = () {
      if (mounted) _load();
    };
    LocalStorageService.dashboardNotifier.addListener(_dashboardListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
    _loadHabits();
  }

  @override
  void dispose() {
    LocalStorageService.userNotifier.removeListener(_userListener);
    LocalStorageService.dashboardNotifier.removeListener(_dashboardListener);
    HabitsService.notifier.removeListener(_habitsListener);
    _transactionsSubscription?.cancel();
    _debtsSubscription?.cancel();
    super.dispose();
  }

  void _load() {
    _user = LocalStorageService.getUserProfile();

    if (_user == null) {
      setState(() {
        _dashboard = null;
      });
      _wasPremium = false;
      return;
    }

    _checkPremiumActivation(_user!);

    final uid = LocalStorageService.currentUserId;
    _debtsSubscription?.cancel();
    if (uid != null && uid.isNotEmpty) {
      _debtsSubscription = FirestoreService.watchDebts(uid).listen((debts) {
        final hasOpen = debts.any(
          (d) => d.status == 'ACTIVE' || d.status == 'NEGOTIATING',
        );
        if (!mounted) return;
        if (hasOpen == _hasOpenDebts) return;
        setState(() {
          _hasOpenDebts = hasOpen;
          if (_dashboard == null || _user == null) return;
          final housing = _dashboard!.expenses
              .where(
                (e) => e.category == ExpenseCategory.moradia && !e.isInvestment,
              )
              .fold(0.0, (sum, e) => sum + e.amount);
          final result = FinanceScoreUtils.computeFinancialHealthScore(
            income: _dashboard!.salary,
            fixed: _dashboard!.fixedExpensesTotal,
            variable: _dashboard!.variableExpensesTotal,
            investContribution: _dashboard!.investmentsTotal,
            hasOpenDebts: _hasOpenDebts,
            housing: housing,
            propertyValue: _user?.propertyValue ?? 0.0,
            investBalance: _user?.investBalance,
          );
          _score = result.score;
          _scoreStatus = result.status;
          _scoreResult = result;
        });
      });
    }

    final existing = LocalStorageService.getDashboard(
      _currentMonth.month,
      _currentMonth.year,
    );

    final replicated = existing == null
        ? _replicateFixedExpenses(_currentMonth.month, _currentMonth.year)
        : const <Expense>[];

    final base = existing ??
        MonthlyDashboard(
          month: _currentMonth.month,
          year: _currentMonth.year,
          salary: LocalStorageService.incomeTotalForMonth(_currentMonth),
          expenses: const [],
        );

    // Use the existing dashboard salary without trying to force-sync with profile on every load.
    // This prevents race conditions where stale profile data might overwrite a fresh dashboard update from Web.
    _dashboard = base;

    if (existing == null) {
      if (replicated.isNotEmpty) {
        for (final exp in replicated) {
          LocalStorageService.saveExpense(exp);
        }
      }
      LocalStorageService.saveDashboard(_dashboard!);
    }

    // Subscribe to transactions for real-time updates
    _transactionsSubscription?.cancel();
    _transactionsSubscription = LocalStorageService.watchTransactions(
      _currentMonth.month,
      _currentMonth.year,
    ).listen((txs) {
      if (!mounted) return;
      setState(() {
        _dashboard = _dashboard!.copyWith(expenses: txs);

        final plan = UserPlan.fromProfile(_user);
        final goals = LocalStorageService.getGoals();
        _insights = _insightService.generateInsights(
          _dashboard!,
          goals,
          plan,
          tr: (key, [vars]) => vars == null
              ? AppStrings.t(context, key)
              : AppStrings.tr(context, key, vars),
        );

        final housing = _dashboard!.expenses
            .where(
              (e) => e.category == ExpenseCategory.moradia && !e.isInvestment,
            )
            .fold(0.0, (sum, e) => sum + e.amount);

        final result = FinanceScoreUtils.computeFinancialHealthScore(
          income: _dashboard!.salary,
          fixed: _dashboard!.fixedExpensesTotal,
          variable: _dashboard!.variableExpensesTotal,
          investContribution: _dashboard!.investmentsTotal,
          hasOpenDebts: _hasOpenDebts,
          housing: housing,
          propertyValue: _user?.propertyValue ?? 0.0,
          investBalance: _user?.investBalance,
        );
        _score = result.score;
        _scoreStatus = result.status;
        _scoreResult = result;
        _timeline = _getTimelineItems(_dashboard!);
      });
    });

    final plan = UserPlan.fromProfile(_user);
    final goals = LocalStorageService.getGoals();
    _insights = _insightService.generateInsights(
      _dashboard!,
      goals,
      plan,
      tr: (key, [vars]) => vars == null
          ? AppStrings.t(context, key)
          : AppStrings.tr(context, key, vars),
    );

    final housingInit = _dashboard!.expenses
        .where((e) => e.category == ExpenseCategory.moradia && !e.isInvestment)
        .fold(0.0, (sum, e) => sum + e.amount);

    final result = FinanceScoreUtils.computeFinancialHealthScore(
      income: _dashboard!.salary,
      fixed: _dashboard!.fixedExpensesTotal,
      variable: _dashboard!.variableExpensesTotal,
      investContribution: _dashboard!.investmentsTotal,
      hasOpenDebts: _hasOpenDebts,
      housing: housingInit,
      propertyValue: _user?.propertyValue ?? 0.0,
      investBalance: _user?.investBalance,
    );
    _score = result.score;
    _scoreStatus = result.status;
    _scoreResult = result;
    _timeline = _getTimelineItems(_dashboard!);
    unawaited(_syncDueReminders());

    setState(() {});
    if (!_essentialGuideHandledInSession) {
      _essentialGuideHandledInSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeShowEssentialGuide();
      });
    }
  }

  void _checkPremiumActivation(UserProfile profile) {
    final nowPremium = profile.isPremium;
    if (nowPremium && !_wasPremium) {
      _wasPremium = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPremiumWelcome();
      });
      return;
    }
    _wasPremium = nowPremium;
  }

  Future<void> _showPremiumWelcome() async {
    final scheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(AppStrings.t(context, 'premium_welcome_title')),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(context, 'premium_welcome_body'),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppStrings.t(context, 'premium_welcome_tip'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.t(context, 'premium_welcome_no'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PremiumOnboardingPage(),
                ),
              );
            },
            child: Text(AppStrings.t(context, 'premium_welcome_yes')),
          ),
        ],
      ),
    );
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

  Future<void> _toggleHabit(String habitId, int totalHabits) async {
    setState(() => _habitLoading = true);
    final previous = _habitState;
    final next = await HabitsService.toggleHabit(
      habitId: habitId,
      totalHabits: totalHabits,
    );
    final reward = _habitXpReward(
      previous: previous,
      next: next,
      totalHabits: totalHabits,
    );
    if (reward > 0) {
      await LocalStorageService.addXp(reward);
    }
    if (!mounted) return;
    setState(() {
      _habitState = next;
      _habitLoading = false;
    });
  }

  List<Expense> _replicateFixedExpenses(int month, int year) {
    final dashboards = LocalStorageService.getAllDashboards();
    final previous = dashboards.where((d) {
      return d.year < year || (d.year == year && d.month < month);
    }).toList();

    if (previous.isEmpty) return [];

    previous.sort((a, b) {
      final aKey = a.year * 12 + a.month;
      final bKey = b.year * 12 + b.month;
      return aKey.compareTo(bKey);
    });

    final latest = previous.last;
    final fixed = latest.expenses
        .where((e) => e.isFixed && (!e.isCreditCard || e.isCardRecurring))
        .toList();
    if (fixed.isEmpty) return [];

    return fixed.map((e) => copyExpenseForMonth(e, year, month)).toList();
  }

  int _monthKey(DateTime date) => date.year * 12 + date.month;

  DateTime _accountStartMonth() {
    final createdAt = _user?.createdAt;
    if (createdAt == null) {
      return DateTime(_currentMonth.year, _currentMonth.month, 1);
    }
    return DateTime(createdAt.year, createdAt.month, 1);
  }

  void _changeMonth(int delta) {
    final next = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    if (!_isWithinWindow(next)) return;
    _currentMonth = next;
    _load();
  }

  bool _isWithinWindow(DateTime month) {
    final current = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final start = _accountStartMonth();
    final key = _monthKey(month);
    return key >= _monthKey(start) && key <= _monthKey(current);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openPremium() {
    showPremiumDialog(context);
  }

  void _openInsights() {
    Navigator.pushNamed(context, AppRoutes.insights);
  }

  Future<void> _syncDueReminders() async {
    final user = _user;
    if (user == null) return;

    for (final card in user.creditCards) {
      unawaited(NotificationService.scheduleCreditCardBillReminder(card));
    }

    final uid = LocalStorageService.currentUserId;
    if (uid != null && uid.trim().isNotEmpty) {
      try {
        final seriesList = await FirestoreService.getFixedSeries(uid.trim());
        for (final series in seriesList) {
          if (!series.isActive ||
              series.isCreditCard ||
              series.dueDay == null) {
            continue;
          }
          unawaited(NotificationService.scheduleFixedSeriesReminder(series));
        }
        return;
      } catch (_) {
        // Fallback below
      }
    }

    final d = _dashboard;
    if (d == null) return;
    for (final expense in d.expenses) {
      if (expense.isFixed && !expense.isCreditCard && expense.dueDay != null) {
        unawaited(NotificationService.scheduleExpenseReminder(expense));
      }
    }
  }

  Widget _lockedFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _openPremium,
            child: Text(AppStrings.t(context, 'premium_cta')),
          ),
        ],
      ),
    );
  }

  Future<bool> _saveDashboard() async {
    if (_dashboard == null) return false;
    final ok = await LocalStorageService.saveDashboard(_dashboard!);
    if (!ok && mounted) {
      _snack(
        'Tivemos um problema ao sincronizar, mas seus dados estão salvos localmente.',
      );
    }
    setState(() {});
    return ok;
  }

  Future<void> _toggleExpensePaid(Expense expense, bool isPaid) async {
    if (_dashboard == null) return;

    final previous = _dashboard!;
    final updatedExpense = expense.copyWith(isPaid: isPaid);

    // Optimistic UI update (stream will re-hydrate from Firestore).
    setState(() {
      _dashboard = previous.copyWith(
        expenses: previous.expenses.map((e) {
          if (e.id != expense.id) return e;
          return updatedExpense;
        }).toList(),
      );
    });

    final ok = await LocalStorageService.saveExpense(updatedExpense);
    if (!ok && mounted) {
      setState(() => _dashboard = previous);
      _snack('Não foi possível marcar como pago agora.');
    }
  }

  Future<void> _editExpense(Expense expense) async {
    String categoryLabel(ExpenseCategory c) {
      switch (c) {
        case ExpenseCategory.moradia:
          return 'Moradia';
        case ExpenseCategory.alimentacao:
          return 'Alimentação';
        case ExpenseCategory.transporte:
          return 'Transporte';
        case ExpenseCategory.educacao:
          return 'Educação';
        case ExpenseCategory.saude:
          return 'Saúde';
        case ExpenseCategory.lazer:
          return 'Lazer';
        case ExpenseCategory.assinaturas:
          return 'Assinaturas';
        case ExpenseCategory.investment:
          return 'Investimento';
        case ExpenseCategory.dividas:
          return 'Dívidas';
        case ExpenseCategory.outros:
          return 'Outros';
      }
    }

    final nameController = TextEditingController(text: expense.name);
    final amountController = TextEditingController(
      text: formatMoneyInput(expense.amount),
    );

    ExpenseType type = expense.type;
    ExpenseCategory category = expense.category;
    var lastNonInvestmentCategory = category == ExpenseCategory.investment
        ? ExpenseCategory.outros
        : category;
    var isCard = expense.isCreditCard;
    int? billDueDay =
        (!expense.isCreditCard && expense.type == ExpenseType.fixed)
            ? expense.dueDay
            : null;
    int? cardDueDay = expense.isCreditCard ? expense.dueDay : null;
    final cards = LocalStorageService.getUserProfile()?.creditCards ??
        const <CreditCard>[];
    String? creditCardId = expense.creditCardId;
    if (isCard && cards.isNotEmpty) {
      if (creditCardId == null || creditCardId.isEmpty) {
        creditCardId = cards.first.id;
      }
      final selected = cards.firstWhere(
        (c) => c.id == creditCardId,
        orElse: () => cards.first,
      );
      creditCardId = selected.id;
      cardDueDay = selected.dueDay;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.t(context, 'edit_entry')),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            final isInvestment = type == ExpenseType.investment;
            if (isInvestment) {
              if (category != ExpenseCategory.investment) {
                lastNonInvestmentCategory = category;
              }
              category = ExpenseCategory.investment;
              isCard = false;
              creditCardId = null;
              billDueDay = null;
              cardDueDay = null;
            } else if (category == ExpenseCategory.investment) {
              category = lastNonInvestmentCategory;
            }

            if (type != ExpenseType.fixed) {
              billDueDay = null;
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: ExpenseType.fixed,
                        child: Text('Gasto fixo'),
                      ),
                      DropdownMenuItem(
                        value: ExpenseType.variable,
                        child: Text('Gasto variável'),
                      ),
                      DropdownMenuItem(
                        value: ExpenseType.investment,
                        child: Text('Investimento'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        type = v;
                        if (type == ExpenseType.investment) {
                          if (category != ExpenseCategory.investment) {
                            lastNonInvestmentCategory = category;
                          }
                          category = ExpenseCategory.investment;
                          isCard = false;
                          creditCardId = null;
                          billDueDay = null;
                          cardDueDay = null;
                        } else {
                          if (category == ExpenseCategory.investment) {
                            category = lastNonInvestmentCategory;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (!isInvestment) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          AppStrings.t(context, 'monthly_report_card_credit')),
                      value: isCard,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      activeTrackColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.35),
                      inactiveThumbColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                      inactiveTrackColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.20),
                      onChanged: (v) {
                        if (v && cards.isEmpty) {
                          _snack('Cadastre um cartão primeiro.');
                          return;
                        }
                        setDialogState(() {
                          isCard = v;
                          if (isCard && cards.isNotEmpty) {
                            creditCardId = creditCardId ?? cards.first.id;
                            final selected = cards.firstWhere(
                              (c) => c.id == creditCardId,
                              orElse: () => cards.first,
                            );
                            creditCardId = selected.id;
                            cardDueDay = selected.dueDay;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!isInvestment) ...[
                    DropdownButtonFormField<ExpenseCategory>(
                      isExpanded: true,
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: ExpenseCategory.values
                          .where(
                            (c) =>
                                c != ExpenseCategory.investment &&
                                (type == ExpenseType.fixed ||
                                    c != ExpenseCategory.assinaturas ||
                                    category == ExpenseCategory.assinaturas),
                          )
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                categoryLabel(c),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => category = v ?? category),
                    ),
                    const SizedBox(height: 12),
                  ] else if (isInvestment)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Categoria: Investimento',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  if (!isInvestment) ...[
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: cards.isEmpty ? null : creditCardId,
                      decoration: const InputDecoration(labelText: 'Cartão'),
                      items: cards.isEmpty
                          ? [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  AppStrings.t(
                                      context, 'monthly_report_no_card'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]
                          : cards
                              .map(
                                (c) => DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (!isCard || cards.isEmpty)
                          ? null
                          : (v) {
                              if (v == null) return;
                              setDialogState(() {
                                creditCardId = v;
                                final selected = cards.firstWhere(
                                  (c) => c.id == v,
                                );
                                cardDueDay = selected.dueDay;
                              });
                            },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.tr(context, 'monthly_report_card_due_day', {
                        'day': '${cardDueDay ?? '-'}',
                      }),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!isInvestment && type == ExpenseType.fixed) ...[
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      initialValue: billDueDay,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(
                          context,
                          'monthly_report_due_day_optional',
                        ),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(AppStrings.t(context, 'no_due_date')),
                        ),
                        ...List.generate(
                          31,
                          (i) => DropdownMenuItem<int?>(
                            value: i + 1,
                            child: Text(
                              'Dia ${i + 1}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: isCard
                          ? null
                          : (v) => setDialogState(() => billDueDay = v),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t(context, 'save')),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameController.text.trim();
    final amount = parseMoneyInput(amountController.text);
    if (name.isEmpty || amount <= 0) return;

    if (type == ExpenseType.investment) {
      category = ExpenseCategory.investment;
      isCard = false;
      creditCardId = null;
      billDueDay = null;
      cardDueDay = null;
    }

    if (isCard) {
      if (cards.isEmpty) {
        _snack('Cadastre um cartão primeiro.');
        return;
      }
      final selected = cards.firstWhere(
        (c) => c.id == creditCardId,
        orElse: () => cards.first,
      );
      creditCardId = selected.id;
      cardDueDay = selected.dueDay;
    } else {
      creditCardId = null;
      cardDueDay = null;
      if (type != ExpenseType.fixed) billDueDay = null;
    }

    final mustBePaid = type != ExpenseType.fixed || isCard;
    final effectiveDueDay =
        isCard ? cardDueDay : (type == ExpenseType.fixed ? billDueDay : null);
    final updated = expense.copyWith(
      name: name,
      amount: amount,
      type: type,
      category: category,
      isCreditCard: isCard,
      creditCardId: creditCardId,
      dueDay: effectiveDueDay,
      isPaid: mustBePaid ? true : expense.isPaid,
    );

    final okSave = await LocalStorageService.saveExpense(updated);
    if (!okSave && mounted) {
      _snack('Não foi possível atualizar o lançamento agora.');
    }
  }

  Future<String?> _askFixedDeleteScope() async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Apagar conta fixa'),
        content: const Text(
          'Deseja remover apenas este mês ou apagar para todos os meses seguintes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'month'),
            child: Text(
                AppStrings.t(context, 'profile_income_delete_scope_month')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: Text(
                AppStrings.t(context, 'profile_income_delete_scope_future')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final isInstallment = (expense.installments ?? 0) > 1;
    if (expense.isFixed && !isInstallment) {
      final scope = await _askFixedDeleteScope();
      if (scope == null) return;
      if (scope == 'month') {
        await LocalStorageService.deleteFixedExpenseOnlyThisMonth(
          expense: expense,
          month: _currentMonth,
        );
        return;
      }
      if (scope == 'all') {
        await LocalStorageService.deleteFixedExpenseFromThisMonthForward(
          expense: expense,
          fromMonth: _currentMonth,
        );
        return;
      }
    }
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.t(context, 'delete_entry')),
        content: Text('Deseja remover "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t(context, 'confirm')),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final okDelete = await LocalStorageService.deleteExpense(expense.id);
    if (!okDelete && mounted) {
      _snack('Não foi possível remover o lançamento agora.');
    }
  }

  Future<void> _setCardPayment(String cardId, bool isPaid) async {
    if (_dashboard == null) return;
    final updated = Map<String, bool>.from(_dashboard!.creditCardPayments);
    updated[cardId] = isPaid;
    setState(() {
      _dashboard = MonthlyDashboard(
        month: _dashboard!.month,
        year: _dashboard!.year,
        salary: _dashboard!.salary,
        expenses: List.of(_dashboard!.expenses),
        creditCardPayments: updated,
      );
    });
    await _saveDashboard();
  }

  Future<void> _addCard() async {
    final nameController = TextEditingController();
    int? dueDay;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.t(context, 'card_add')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppStrings.t(context, 'card_name'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: dueDay,
              decoration: InputDecoration(
                labelText: AppStrings.t(context, 'card_due_day'),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(AppStrings.t(context, 'select')),
                ),
                ...List.generate(
                  31,
                  (i) => DropdownMenuItem<int?>(
                    value: i + 1,
                    child: Text('Dia ${i + 1}'),
                  ),
                ),
              ],
              onChanged: (v) => dueDay = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t(context, 'save')),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty || dueDay == null || dueDay! <= 0) return;

    final newCard = CreditCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dueDay: dueDay!,
    );

    if (_user != null) {
      final updatedCards = List<CreditCard>.from(_user!.creditCards)
        ..add(newCard);
      final newUser = _user!.copyWith(creditCards: updatedCards);
      final ok = await LocalStorageService.updateUserProfile(
        previous: _user!,
        updated: newUser,
      );
      if (ok) {
        await NotificationService.scheduleCreditCardBillReminder(newCard);
      }
      _user = newUser;
      setState(() {});
    }
  }

  void _openGoalsFromEssential() {
    if (_user == null || !_user!.isPremium) {
      _openPremium();
      return;
    }
    Navigator.pushNamed(context, AppRoutes.goals);
  }

  ImageProvider? _profilePhotoProvider() {
    final current = LocalStorageService.getUserProfile() ?? _user;
    final path = current?.photoPath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    final file = File(path);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, AppRoutes.profile);
    if (!mounted) return;
    _load();
  }

  int _habitXpReward({
    required HabitState? previous,
    required HabitState next,
    required int totalHabits,
  }) {
    final previousDone = previous?.done.length ?? 0;
    final nextDone = next.done.length;
    if (nextDone <= previousDone) return 0;

    var reward = 6;
    if (nextDone == totalHabits && previousDone < totalHabits) {
      reward += 14 + ((next.streak - 1).clamp(0, 5) * 2);
    }
    return reward;
  }

  int _expenseXpReward(Expense expense, {int installments = 1}) {
    var reward = switch (expense.type) {
      ExpenseType.fixed => 14,
      ExpenseType.variable => 12,
      ExpenseType.investment => 18,
    };
    if (expense.isCreditCard) reward += 2;
    if (installments > 1) reward += installments.clamp(2, 6);
    return reward;
  }

  Future<void> _openIncomeEditorPopup() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ValueListenableBuilder<int>(
              valueListenable: LocalStorageService.incomeNotifier,
              builder: (context, _, __) {
                final month = _currentMonth;
                final incomes = LocalStorageService.getIncomes()
                    .where((income) => income.appliesToMonth(month))
                    .toList()
                  ..sort((a, b) =>
                      a.title.toLowerCase().compareTo(b.title.toLowerCase()));

                return SizedBox(
                  height: maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'income_modal_edit_title'),
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toque em uma entrada para editar.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      Expanded(
                        child: incomes.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhuma entrada cadastrada.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: incomes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (_, index) {
                                  final income = incomes[index];
                                  return Material(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: Text(
                                        _displayIncomeTitle(income),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        IncomeCategoryUtils.label(
                                          context,
                                          income.type,
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.textSecondary(
                                            context,
                                          ),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            SensitiveDisplay.money(
                                              context,
                                              income.amount,
                                            ),
                                            style: TextStyle(
                                              color: AppTheme.textPrimary(
                                                context,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: AppTheme.textSecondary(
                                              context,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        await IncomeModal.show(
                                          context,
                                          income: income,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    _load();
  }

  void _showMonthBalanceDialog(MonthlyDashboard d) {
    final entries = d.salary;
    final exits =
        d.fixedExpensesTotal + d.variableExpensesTotal + d.investmentsTotal;
    final monthBalance = d.monthBalance;
    final accumulated = d.totalBalance;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t(context, 'essential_balance_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tr(context, 'essential_balance_entries', {
                'value': SensitiveDisplay.money(context, entries),
              }),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.tr(context, 'essential_balance_exits', {
                'value': SensitiveDisplay.money(context, exits),
              }),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.tr(context, 'essential_balance_free', {
                'value': SensitiveDisplay.money(context, monthBalance),
              }),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Saldo acumulado: ${SensitiveDisplay.money(context, accumulated)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.t(context, 'close')),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeShowEssentialGuide() async {
    final user = _user;
    final dashboard = _dashboard;
    if (user == null || dashboard == null) return;
    final seen = await LocalStorageService.hasSeenDashboardEssentialGuide();
    if (seen || !mounted) return;
    final actions = <_GuideAction>[
      _GuideAction(
        id: 'expense',
        icon: Icons.add_circle_outline,
        titleKey: 'essential_guide_action_expense_title',
        subtitleKey: 'essential_guide_action_expense_subtitle',
        helpKey: 'essential_guide_action_expense_help',
        onTap: _openAddMenu,
      ),
      _GuideAction(
        id: 'card',
        icon: Icons.add_card,
        titleKey: 'essential_guide_action_card_title',
        subtitleKey: 'essential_guide_action_card_subtitle',
        helpKey: 'essential_guide_action_card_help',
        canSkip: true,
        onTap: _addCard,
      ),
      _GuideAction(
        id: 'balance',
        icon: Icons.account_balance_wallet_outlined,
        titleKey: 'essential_guide_action_balance_title',
        subtitleKey: 'essential_guide_action_balance_subtitle',
        helpKey: 'essential_guide_action_balance_help',
        onTap: () => _showMonthBalanceDialog(dashboard),
      ),
    ];
    if (user.isPremium) {
      actions.insert(
        1,
        _GuideAction(
          id: 'goal',
          icon: Icons.flag_outlined,
          titleKey: 'essential_guide_action_goal_title',
          subtitleKey: 'essential_guide_action_goal_subtitle',
          helpKey: 'essential_guide_action_goal_help',
          canSkip: true,
          onTap: _openGoalsFromEssential,
        ),
      );
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final status = <String, _GuideActionStatus>{
          for (final action in actions) action.id: _GuideActionStatus.pending,
        };
        return StatefulBuilder(
          builder: (context, setModalState) {
            final doneCount = status.values
                .where(
                  (s) =>
                      s == _GuideActionStatus.done ||
                      s == _GuideActionStatus.skipped,
                )
                .length;
            final allResolved = doneCount == actions.length;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(context, 'essential_guide_title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.isPremium
                          ? AppStrings.t(
                              context,
                              'essential_guide_subtitle_premium',
                            )
                          : AppStrings.t(
                              context,
                              'essential_guide_subtitle_free',
                            ),
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tr(context, 'essential_guide_progress', {
                        'done': '$doneCount',
                        'total': '${actions.length}',
                      }),
                      style: TextStyle(color: AppTheme.textMuted(context)),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: actions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final action = actions[index];
                          final currentStatus = status[action.id]!;
                          final done = currentStatus == _GuideActionStatus.done;
                          final skipped =
                              currentStatus == _GuideActionStatus.skipped;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(action.icon, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppStrings.t(context, action.titleKey),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (done)
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      )
                                    else if (skipped)
                                      Icon(
                                        Icons.fast_forward_rounded,
                                        size: 18,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.t(context, action.subtitleKey),
                                  style: TextStyle(
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text(
                                              AppStrings.t(
                                                context,
                                                action.titleKey,
                                              ),
                                            ),
                                            content: Text(
                                              AppStrings.t(
                                                context,
                                                action.helpKey,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  AppStrings.t(
                                                    context,
                                                    'close',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Text(
                                        AppStrings.t(
                                          context,
                                          'essential_guide_how',
                                        ),
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        setModalState(() {
                                          status[action.id] =
                                              _GuideActionStatus.done;
                                        });
                                        action.onTap();
                                      },
                                      child: Text(
                                        AppStrings.t(
                                          context,
                                          'essential_guide_do_now',
                                        ),
                                      ),
                                    ),
                                    if (action.canSkip)
                                      TextButton(
                                        onPressed: () {
                                          setModalState(() {
                                            status[action.id] =
                                                _GuideActionStatus.skipped;
                                          });
                                        },
                                        child: Text(
                                          AppStrings.t(
                                            context,
                                            'essential_guide_skip',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: allResolved
                            ? () async {
                                await LocalStorageService
                                    .markDashboardEssentialGuideSeen();
                                if (context.mounted) Navigator.pop(ctx);
                              }
                            : null,
                        child: Text(
                          AppStrings.t(context, 'essential_guide_finish'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              AppStrings.t(context, 'essential_guide_later'),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await LocalStorageService
                                  .markDashboardEssentialGuideSeen();
                              if (context.mounted) Navigator.pop(ctx);
                            },
                            child: Text(
                              AppStrings.t(
                                context,
                                'essential_guide_never_again',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<String> _getTimelineItems(MonthlyDashboard d) {
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
    final currentKey = _currentMonth.year * 12 + _currentMonth.month;
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
          AppStrings.tr(context, 'timeline_variable_change', {
            'pct': change.abs().toStringAsFixed(0),
            'direction': direction,
          }),
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
          AppStrings.tr(context, 'timeline_fixed_change', {
            'pct': change.abs().toStringAsFixed(0),
            'direction': direction,
          }),
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
        AppStrings.tr(context, 'timeline_invest_streak', {'months': '$streak'}),
      );
    }

    if (items.isEmpty) {
      items.add(AppStrings.t(context, 'timeline_balanced'));
    }

    return items;
  }

  Color _scoreColor(String status) {
    switch (status) {
      case 'excellent':
        return AppTheme.success;
      case 'good':
        return AppTheme.goodStatus;
      case 'attention':
        return AppTheme.warning;
      case 'critical':
      default:
        return AppTheme.danger;
    }
  }

  Widget _insightList() {
    if (_insights.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 140, // Height for insight cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final insight = _insights[index];
              return _builtInsightCard(insight);
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _builtInsightCard(FinancialInsight insight) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              insight.message,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _handleInsightAction(insight.action),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      insight.actionLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleInsightAction(NextBestAction action) {
    switch (action) {
      case NextBestAction.createGoal:
        Navigator.pushNamed(context, AppRoutes.goals);
        break;
      case NextBestAction.adjustSpend:
      case NextBestAction.addExpense:
        _openAddMenu();
        break;
      case NextBestAction.simulateInvestment:
        Navigator.pushNamed(context, AppRoutes.investmentCalculator);
        break;
      case NextBestAction.none:
        break;
    }
  }

  WeeklyPlanResult _buildWeeklyPlan(MonthlyDashboard dashboard) {
    final streak = (_habitState?.streak ?? 0).clamp(0, 7);
    final goals = LocalStorageService.getGoals();
    return WeeklyPlanService.buildPlan(
      currentDashboard: dashboard,
      goals: goals,
      checkInDaysLast7: streak,
      tr: (key, [vars]) => vars == null
          ? AppStrings.t(context, key)
          : AppStrings.tr(context, key, vars),
    );
  }

  void _openWeeklyAction(String actionKey) {
    final route = WeeklyActionService.resolveRoute(actionKey);
    if (WeeklyActionService.isPremiumOnlyRoute(route) &&
        !(_user?.isPremium ?? false)) {
      _openPremium();
      return;
    }
    Navigator.pushNamed(context, route);
  }

  Widget _compactMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
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
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
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

  Widget _weeklyFocusCard(MonthlyDashboard dashboard) {
    final plan = _buildWeeklyPlan(dashboard);
    final next = plan.nextBestAction;
    if (next == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'weekly_plan_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, 'weekly_plan_subtitle'),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.track_changes_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next.title,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next.description,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _compactMetricChip(
                AppStrings.t(context, 'weekly_plan_actions_label'),
                '${plan.items.length}',
                AppTheme.info,
              ),
              _compactMetricChip(
                AppStrings.t(context, 'weekly_plan_streak_label'),
                '${_habitState?.streak ?? 0}',
                AppTheme.success,
              ),
              _compactMetricChip(
                AppStrings.t(context, 'weekly_plan_insights_label'),
                '${_insights.length}',
                AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openWeeklyAction(next.actionKey),
              child: Text(AppStrings.t(context, 'weekly_plan_follow_cta')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertsCard(MonthlyDashboard d) {
    final salaryFallback = LocalStorageService.incomeTotalForMonth(
      _currentMonth,
    );
    final salary = salaryFallback > 0 ? salaryFallback : d.salary;
    final alerts = <String>[];
    if (salary <= 0) {
      alerts.add(AppStrings.t(context, 'alert_add_income'));
    } else {
      final fixedPct = (d.fixedExpensesTotal / salary) * 100;
      final variablePct = (d.variableExpensesTotal / salary) * 100;
      final investPct = (d.investmentsTotal / salary) * 100;
      if (fixedPct > 55) {
        alerts.add(AppStrings.t(context, 'alert_fixed_high'));
      }
      if (variablePct > 35) {
        alerts.add(AppStrings.t(context, 'alert_variable_high'));
      }
      if (investPct < 10) {
        alerts.add(AppStrings.t(context, 'alert_invest_low'));
      }
      if (d.remainingSalary < 0) {
        alerts.add(AppStrings.t(context, 'alert_negative_balance'));
      }
    }

    if (alerts.isEmpty) {
      alerts.add(AppStrings.t(context, 'alert_ok'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'alert_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w800,
            ),
          ),
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
      final value = target > 0
          ? SensitiveDisplay.money(context, target)
          : SensitiveDisplay.money(context, 0);
      action = AppStrings.tr(context, 'plan_action_invest', {'value': value});
    } else {
      action = AppStrings.t(context, 'plan_action_ok');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCardDecoration(
        context,
        borderColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'plan_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w800,
            ),
          ),
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
              _planMetric(
                label: AppStrings.t(context, 'summary_fixed'),
                pct: fixedPct,
                color: AppTheme.danger,
              ),
              _planMetric(
                label: AppStrings.t(context, 'summary_variable'),
                pct: variablePct,
                color: AppTheme.warning,
              ),
              _planMetric(
                label: AppStrings.t(context, 'summary_invest'),
                pct: investPct,
                color: AppTheme.info,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t(context, 'plan_next_action'),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
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

  Widget _planMetric({
    required String label,
    required double pct,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
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
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
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

  String _displayIncomeTitle(IncomeSource income) {
    final title = income.title.trim();
    if (title.isEmpty ||
        title.toLowerCase() == 'renda principal' ||
        income.id == 'main_income') {
      return IncomeCategoryUtils.label(context, income.type);
    }
    return title;
  }

  Widget _financialPositionCard(FinanceOverview overview) {
    final scheme = Theme.of(context).colorScheme;
    final currentMonthBalance = _dashboard?.monthBalance ?? overview.availableNow;
    final accumulatedBalance =
        _dashboard?.totalBalance ?? currentMonthBalance;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(context, 'financial_position_paid_out'),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SensitiveDisplay.money(context, overview.totalCommitted),
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(context, 'financial_position_available'),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  SensitiveDisplay.money(context, currentMonthBalance),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  overview.currentInvoice > 0
                      ? AppStrings.tr(
                          context, 'financial_position_with_invoice', {
                          'value': SensitiveDisplay.money(
                            context,
                            currentMonthBalance,
                          ),
                        })
                      : AppStrings.t(
                          context,
                          'financial_position_without_invoice',
                        ),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _moneyFlowChip(
                label: AppStrings.t(context, 'financial_position_paid_out'),
                value: overview.totalCommitted,
                color: AppTheme.warning,
                icon: Icons.south_west_rounded,
                onInfoTap: () => _showConceptInfo(
                  AppStrings.t(
                    context,
                    'financial_position_committed_help_title',
                  ),
                  AppStrings.t(
                    context,
                    'financial_position_committed_help_body',
                  ),
                ),
              ),
              _moneyFlowChip(
                label: AppStrings.t(
                  context,
                  'financial_position_current_invoice',
                ),
                value: overview.currentInvoice,
                color: scheme.primary,
                icon: Icons.credit_card_rounded,
                onInfoTap: () => _showConceptInfo(
                  AppStrings.t(
                    context,
                    'financial_position_current_invoice_help_title',
                  ),
                  AppStrings.t(
                    context,
                    'financial_position_current_invoice_help_body',
                  ),
                ),
              ),
              _moneyFlowChip(
                label: AppStrings.t(context, 'financial_position_invested'),
                value: overview.invested,
                color: AppTheme.info,
                icon: Icons.trending_up_rounded,
                onInfoTap: () => _showConceptInfo(
                  AppStrings.t(
                    context,
                    'financial_position_invested_help_title',
                  ),
                  AppStrings.t(
                    context,
                    'financial_position_invested_help_body',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo acumulado',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  SensitiveDisplay.money(context, accumulatedBalance),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpBadge(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          '?',
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showConceptInfo(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.t(context, 'confirm')),
          ),
        ],
      ),
    );
  }

  Widget _moneyFlowChip({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    VoidCallback? onInfoTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                  if (onInfoTap != null) ...[
                    const SizedBox(width: 6),
                    _helpBadge(onInfoTap),
                  ],
                ],
              ),
              Text(
                SensitiveDisplay.money(context, value),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _creditCardBillsSection(FinanceOverview overview) {
    final cards = [...overview.cards]..sort((a, b) {
        final dueCompare = (a.dueDay ?? 99).compareTo(b.dueDay ?? 99);
        if (dueCompare != 0) return dueCompare;
        return a.name.compareTo(b.name);
      });

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.premiumCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'bills_compact_title'),
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _helpBadge(
                        () => _showConceptInfo(
                          AppStrings.t(context, 'bills_help_title'),
                          AppStrings.t(context, 'bills_help_body'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.t(context, 'bills_empty_subtitle'),
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, 'bills_empty_title'),
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _addCard,
                      icon: const Icon(Icons.credit_card_rounded),
                      label: Text(AppStrings.t(context, 'bills_add_card')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(context, 'bills_compact_title'),
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _helpBadge(
                      () => _showConceptInfo(
                        AppStrings.t(context, 'bills_help_title'),
                        AppStrings.t(context, 'bills_help_body'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.t(context, 'bills_compact_subtitle'),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _addCard,
                icon: const Icon(Icons.add_rounded),
                tooltip: AppStrings.t(context, 'bills_add_card'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...cards.asMap().entries.expand((entry) sync* {
            if (entry.key > 0) {
              yield const SizedBox(height: 10);
            }
            yield _creditCardBillTile(entry.value);
          }),
        ],
      ),
    );
  }

  Widget _creditCardBillTile(FinanceCardOverview card) {
    final primary = Theme.of(context).colorScheme.primary;
    final statusColor = card.isPaid ? AppTheme.success : primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  card.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.credit_card_rounded,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (card.dueDay != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.tr(context, 'bills_selected_due', {
                          'day': '${card.dueDay}',
                        }),
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  card.isPaid
                      ? AppStrings.t(context, 'bills_paid_badge')
                      : AppStrings.t(context, 'bills_selected_open'),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SensitiveDisplay.money(context, card.invoiceTotal),
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.invoiceTotal > 0
                          ? AppStrings.t(
                              context,
                              'financial_position_current_invoice',
                            )
                          : AppStrings.t(context, 'bills_selected_clear'),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: card.invoiceTotal <= 0
                        ? null
                        : () => _showPayBillPopup(card),
                    child: Text(
                      AppStrings.t(
                        context,
                        card.isPaid ? 'bills_reopen_cta' : 'bills_pay_cta',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (card.installmentsInInvoice > 0) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.tr(context, 'bills_installments', {
                'value': SensitiveDisplay.money(
                  context,
                  card.installmentsInInvoice,
                ),
              }),
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPayBillPopup(FinanceCardOverview card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.t(context, 'bills_pay_popup_title')),
        content: Text(
          AppStrings.tr(context, 'bills_pay_popup_body', {
            'card': card.name,
            'value': SensitiveDisplay.money(context, card.invoiceTotal),
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t(context, 'confirm')),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _setCardPayment(card.cardId, !card.isPaid);
    }
  }

  MonthlyDashboard? _previousMonthDashboard() {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    return LocalStorageService.getDashboard(prev.month, prev.year);
  }

  Widget _buildProgressCard(
    FinancialLevel level,
    double progress,
    FinancialLevel? nextLevel,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final currentXp = _user?.totalXp ?? 0;
    final isMaxLevel = nextLevel == null;
    final nextTargetXp = nextLevel?.minXp;
    final percent = (progress * 100).clamp(0.0, 100.0).round();
    final levelName = AppStrings.t(context, 'financial_level_${level.level}');
    final streak = _habitState?.streak ?? 0;
    final streakBonus = streak <= 0 ? 20 : 14 + ((streak - 1).clamp(0, 5) * 2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  AppStrings.tr(context, 'level_label', {
                    'level': '${level.level}',
                  }),
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  levelName,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currentXp',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isMaxLevel ? 'XP' : '/ $nextTargetXp XP',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tr(context, 'level_progress_next', {'pct': '$percent'}),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _xpHintPill(
                icon: Icons.local_fire_department_outlined,
                text: 'Check-in completo: +$streakBonus XP',
              ),
              _xpHintPill(
                icon: Icons.add_card_rounded,
                text: 'Registrar gasto: +12 XP',
              ),
              _xpHintPill(
                icon: Icons.track_changes_outlined,
                text: 'Missao semanal: +35 XP',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _xpHintPill({
    required IconData icon,
    required String text,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonCard(MonthlyDashboard d) {
    final prev = _previousMonthDashboard();
    if (prev == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.premiumCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(context, 'compare_title'),
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
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
                SensitiveDisplay.money(context, diff.abs()),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'compare_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          row(
            AppStrings.t(context, 'summary_fixed'),
            d.fixedExpensesTotal,
            prev.fixedExpensesTotal,
            AppTheme.danger,
          ),
          const SizedBox(height: 6),
          row(
            AppStrings.t(context, 'summary_variable'),
            d.variableExpensesTotal,
            prev.variableExpensesTotal,
            AppTheme.warning,
          ),
          const SizedBox(height: 6),
          row(
            AppStrings.t(context, 'summary_invest'),
            d.investmentsTotal,
            prev.investmentsTotal,
            AppTheme.info,
          ),
          const SizedBox(height: 6),
          row(
            AppStrings.t(context, 'summary_free'),
            d.remainingSalary,
            prev.remainingSalary,
            AppTheme.success,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.t(context, 'habit_title'),
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                AppStrings.tr(context, 'habit_streak', {'days': '$streak'}),
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                ),
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

  // ====== ADD MENU ======

  Future<void> _openAddMenu() async {
    if (_user == null || _dashboard == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetItem(
                icon: Icons.add_circle_outline,
                title: AppStrings.t(context, 'add_extra_income'),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      IncomeModal.show(context);
                    }
                  });
                },
              ),
              _sheetItem(
                icon: Icons.lock_outline,
                title: 'Adicionar gasto fixo',
                onTap: () {
                  Navigator.pop(context);
                  _openAddExpenseDialog(type: ExpenseType.fixed);
                },
              ),
              _sheetItem(
                icon: Icons.shopping_cart_outlined,
                title: 'Adicionar gasto variável',
                onTap: () {
                  Navigator.pop(context);
                  _openAddExpenseDialog(type: ExpenseType.variable);
                },
              ),
              _sheetItem(
                icon: Icons.trending_up,
                title: 'Adicionar investimento',
                onTap: () {
                  Navigator.pop(context);
                  _openAddExpenseDialog(type: ExpenseType.investment);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(color: AppTheme.textPrimary(context)),
      ),
      onTap: onTap,
    );
  }

  double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  Future<void> _addCreditInstallments({
    required Expense template,
    required int installments,
  }) async {
    if (_user == null) return;
    final baseAmount = _roundMoney(template.amount / installments);
    final baseMonth = _currentMonth.month;
    final baseYear = _currentMonth.year;

    for (var i = 0; i < installments; i++) {
      final isLast = i == installments - 1;
      final amountPer = isLast
          ? _roundMoney(template.amount - baseAmount * (installments - 1))
          : baseAmount;
      final targetMonth = baseMonth + i;
      final yearOffset = (targetMonth - 1) ~/ 12;
      final month = ((targetMonth - 1) % 12) + 1;
      final year = baseYear + yearOffset;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final date = DateTime(
        year,
        month,
        clampDueDay(template.dueDay, daysInMonth),
      );

      final installmentExpense = Expense(
        id: '${template.id}-$i',
        name: template.name,
        type: template.type,
        category: template.category,
        amount: amountPer,
        date: date,
        dueDay: template.dueDay,
        isCreditCard: true,
        creditCardId: template.creditCardId,
        isCardRecurring: false,
        installments: installments,
        installmentIndex: i + 1,
      );

      await LocalStorageService.saveExpense(installmentExpense);
    }
  }

  Future<void> _openAddExpenseDialog({
    required ExpenseType type,
    ExpenseCategory? category,
  }) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    int? dueDay;
    int? cardDueDay;
    bool isCreditCard = false;
    bool isInstallment = false;
    int? installments;
    String? creditCardId;

    final isFixed = type == ExpenseType.fixed;
    final isInvestment = type == ExpenseType.investment;
    ExpenseCategory selectedCategory = category ??
        (isInvestment ? ExpenseCategory.investment : ExpenseCategory.outros);
    final cards = _user?.creditCards ?? [];
    if (cards.isNotEmpty) {
      creditCardId = cards.first.id;
    }

    Widget contextTip(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary(context), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget? highExpenseTip() {
      final income = _dashboard?.salary ??
          LocalStorageService.incomeTotalForMonth(
            _currentMonth,
          );
      if (income <= 0) return null;
      final amount = parseMoneyInput(amountController.text);
      if (amount <= 0) return null;
      final existingExpenses = _dashboard?.expenses ?? const <Expense>[];
      final rule = budgetRuleForEntry(
        type: type,
        category: selectedCategory,
      );
      final projectedTotal = trackedTotalForBudgetRule(
            existingExpenses,
            type: type,
            category: selectedCategory,
          ) +
          amount;
      final share = projectedTotal / income;
      final pct = share * 100;
      final idealPct = (rule.idealShare * 100).round();
      if (!shouldShowBudgetTip(rule, share)) return null;

      return contextTip(
        Icons.report_problem_outlined,
        AppStrings.tr(
          context,
          rule.direction == BudgetRuleDirection.min
              ? 'expense_low_tip'
              : 'expense_high_tip',
          {
            'pct': pct.toStringAsFixed(0),
            'ideal': idealPct.toString(),
          },
        ),
      );
    }

    Widget paymentMethodCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final scheme = Theme.of(context).colorScheme;
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.10)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: selected ? scheme.primary : scheme.onSurface),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          type == ExpenseType.fixed
              ? 'Novo gasto fixo'
              : type == ExpenseType.variable
                  ? 'Novo gasto variável'
                  : 'Novo investimento',
          style: TextStyle(color: AppTheme.textPrimary(context)),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            final showBillDueDay = isFixed && !isCreditCard;
            final hasCards = cards.isNotEmpty;
            final selectedCard = (hasCards && creditCardId != null)
                ? cards.firstWhere(
                    (c) => c.id == creditCardId,
                    orElse: () => cards.first,
                  )
                : null;
            final selectedCardDueDay = selectedCard?.dueDay ?? cardDueDay;

            return SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isInvestment
                          ? 'Nome do investimento'
                          : 'Nome do gasto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isInvestment) ...[
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: ExpenseCategory.values
                          .where(
                            (c) =>
                                c != ExpenseCategory.investment &&
                                (isFixed || c != ExpenseCategory.assinaturas),
                          )
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_categoryLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => selectedCategory = v ?? ExpenseCategory.outros,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  if (highExpenseTip() != null) highExpenseTip()!,
                  if (!isInvestment) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Como esse valor deve aparecer?',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        paymentMethodCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Debito / saldo',
                          subtitle: 'Sai do saldo no momento do lancamento.',
                          selected: !isCreditCard,
                          onTap: () {
                            setState(() {
                              isCreditCard = false;
                              creditCardId = null;
                              cardDueDay = null;
                              isInstallment = false;
                              installments = null;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        paymentMethodCard(
                          icon: Icons.credit_card_rounded,
                          title: 'Credito / fatura',
                          subtitle:
                              'Entra na fatura e compromete o orcamento do mes agora.',
                          selected: isCreditCard,
                          onTap: () {
                            if (cards.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cadastre um cartao primeiro.'),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              isCreditCard = true;
                              creditCardId = creditCardId ?? cards.first.id;
                              final selected = cards.firstWhere(
                                (c) => c.id == creditCardId,
                                orElse: () => cards.first,
                              );
                              creditCardId = selected.id;
                              cardDueDay = selected.dueDay;
                              dueDay = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    contextTip(
                      isCreditCard
                          ? Icons.credit_score_outlined
                          : Icons.check_circle_outline_rounded,
                      isCreditCard
                          ? 'Credito entra na fatura atual e ja conta no comprometido do mes.'
                          : 'Debito reduz o saldo disponivel imediatamente e nao aparece na fatura.',
                    ),
                  ],
                  if (showBillDueDay) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      initialValue: dueDay,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(
                          context,
                          'monthly_report_due_day_optional',
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sem vencimento'),
                        ),
                        ...List.generate(
                          31,
                          (i) => DropdownMenuItem<int?>(
                            value: i + 1,
                            child: Text(
                              'Dia ${i + 1}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: isCreditCard
                          ? null
                          : (v) => setState(() => dueDay = v),
                    ),
                  ],
                  if (!isInvestment && isCreditCard) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: hasCards ? creditCardId : null,
                      decoration: InputDecoration(
                        labelText:
                            AppStrings.t(context, 'monthly_report_card_credit'),
                      ),
                      items: hasCards
                          ? cards
                              .map(
                                (c) => DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList()
                          : [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  AppStrings.t(
                                      context, 'monthly_report_no_card'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                      onChanged: (!isCreditCard || !hasCards)
                          ? null
                          : (v) {
                              if (v == null) return;
                              setState(() {
                                creditCardId = v;
                                final card = cards.firstWhere((c) => c.id == v);
                                cardDueDay = card.dueDay;
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tr(context, 'monthly_report_card_due_day', {
                        'day': '${selectedCardDueDay ?? '-'}',
                      }),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (!isInvestment) ...[
                    if (isFixed && isCreditCard) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isInstallment,
                        onChanged: (v) {
                          setState(() {
                            isInstallment = v;
                            if (!isInstallment) {
                              installments = null;
                              return;
                            }
                            installments = installments ?? 10;
                          });
                        },
                        title: const Text('Parcelar (fixo temporário)?'),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.35),
                        inactiveThumbColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.55),
                        inactiveTrackColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.20),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (isInstallment)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: contextTip(
                            Icons.layers_outlined,
                            'Cada parcela entra em uma fatura. Assim o valor nao parece descontado duas vezes no app.',
                          ),
                        ),
                      if (isInstallment)
                        DropdownButtonFormField<int>(
                          initialValue: (installments ?? 10).clamp(2, 24),
                          decoration: const InputDecoration(
                            labelText: 'Número de parcelas',
                          ),
                          items: List.generate(23, (i) => i + 2)
                              .map(
                                (n) => DropdownMenuItem<int>(
                                  value: n,
                                  child: Text('${n}x'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => installments = v),
                        ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final amount = parseMoneyInput(amountController.text);

              if (name.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha nome e valor corretamente.'),
                  ),
                );
                return;
              }

              if (isFixed &&
                  isCreditCard &&
                  isInstallment &&
                  (installments == null ||
                      installments! < 2 ||
                      installments! > 24)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe a quantidade de parcelas.'),
                  ),
                );
                return;
              }
              if (isFixed && isCreditCard && isInstallment) {
                final cents = (amount * 100).round();
                if (installments != null && cents < installments!) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'O valor ? muito baixo para parcelar em tantas vezes.',
                      ),
                    ),
                  );
                  return;
                }
              }

              if (!isFixed) {
                dueDay = null;
              }

              if (isCreditCard) {
                if (cards.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cadastre um cartão primeiro.'),
                    ),
                  );
                  return;
                }
                final selected = cards.firstWhere(
                  (c) => c.id == creditCardId,
                  orElse: () => cards.first,
                );
                creditCardId = selected.id;
                cardDueDay = selected.dueDay;
              }

              final resolvedCategory = type == ExpenseType.investment
                  ? ExpenseCategory.investment
                  : selectedCategory;

              final now = DateTime.now();
              final effectiveDueDay = isCreditCard ? cardDueDay : dueDay;
              final expense = Expense(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                type: type,
                category: resolvedCategory,
                amount: amount,
                date: resolveExpenseDate(
                  type: type,
                  baseDate: now,
                  dueDay: effectiveDueDay,
                ),
                dueDay: effectiveDueDay,
                isCreditCard: isCreditCard,
                creditCardId: creditCardId,
                isCardRecurring: isFixed && isCreditCard && !isInstallment,
                installments: isFixed && isCreditCard && isInstallment
                    ? installments
                    : null,
              );

              if (expense.isFixed &&
                  expense.isCreditCard &&
                  isInstallment &&
                  (installments ?? 0) > 1) {
                await _addCreditInstallments(
                  template: expense,
                  installments: installments!,
                );
                await LocalStorageService.addXp(
                  _expenseXpReward(
                    expense,
                    installments: installments!,
                  ),
                );
              } else {
                await LocalStorageService.saveExpense(expense);
                await LocalStorageService.addXp(_expenseXpReward(expense));

                if (expense.isFixed &&
                    !expense.isCreditCard &&
                    expense.dueDay != null) {
                  NotificationService.scheduleExpenseReminder(expense);
                }

                if (expense.isFixed) {
                  _propagateFixedToFuture(expense);
                }
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(ExpenseCategory c) {
    if (c == ExpenseCategory.dividas) return 'Dividas';
    switch (c) {
      case ExpenseCategory.moradia:
        return 'Moradia';
      case ExpenseCategory.alimentacao:
        return 'Alimentacao';
      case ExpenseCategory.transporte:
        return 'Transporte';
      case ExpenseCategory.educacao:
        return 'Educacao';
      case ExpenseCategory.saude:
        return 'Saude';
      case ExpenseCategory.lazer:
        return 'Lazer';
      case ExpenseCategory.assinaturas:
        return 'Assinaturas';
      case ExpenseCategory.investment:
        return 'Investimento';
      case ExpenseCategory.dividas:
        return 'Dividas';
      case ExpenseCategory.outros:
        return 'Outros';
    }
  }

  int _distributionFlex(double value, double total) {
    if (value <= 0 || total <= 0) return 0;
    final flex = ((value / total) * 1000).round();
    return flex.clamp(1, 1000);
  }

  Widget _distributionBar({
    required BuildContext context,
    required double fixedSpent,
    required double variableSpent,
    required double invested,
    required double free,
  }) {
    final available = free > 0 ? free : 0.0;
    final total = fixedSpent + variableSpent + invested + available;
    final segments = <Widget>[];

    void addSegment(double value, Color color) {
      final flex = _distributionFlex(value, total);
      if (flex == 0) return;
      segments.add(
        Expanded(
          flex: flex,
          child: ColoredBox(color: color),
        ),
      );
    }

    addSegment(fixedSpent, AppTheme.danger);
    addSegment(variableSpent, AppTheme.warning);
    addSegment(invested, AppTheme.info);
    addSegment(available, AppTheme.success);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.t(context, 'ratio_distribution_title'),
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                total > 0
                    ? SensitiveDisplay.money(context, total)
                    : 'Sem dados',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: segments.isEmpty
                  ? ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    )
                  : Row(children: segments),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.t(context, 'ratio_distribution_subtitle'),
            style: TextStyle(
              color: AppTheme.textMuted(context),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  void _propagateFixedToFuture(Expense expense) {
    if (expense.isCreditCard && !expense.isCardRecurring) return;
    final dashboards = LocalStorageService.getAllDashboards();
    final currentKey = _currentMonth.year * 12 + _currentMonth.month;

    for (final d in dashboards) {
      final key = d.year * 12 + d.month;
      if (key <= currentKey) continue;

      final baseId = recurringBaseExpenseId(expense.id);
      final monthlyId = recurringExpenseId(baseId, d.year, d.month);
      final exists = d.expenses.any((e) => e.id == monthlyId);
      if (exists) continue;

      final replicated = copyExpenseForMonth(expense, d.year, d.month);
      LocalStorageService.saveExpense(replicated);
    }
  }

  Widget _premiumLockedPreview({
    required Widget child,
    required List<String> perks,
    String? title,
    String? subtitle,
    bool usePreview = false,
  }) {
    if (_user?.isPremium ?? false) return child;

    final upsell = Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: PremiumUpsellCard(
          perks: perks,
          title: title,
          subtitle: subtitle,
          onCta: _openPremium,
        ),
      ),
    );

    if (!usePreview) return upsell;

    return Stack(
      children: [
        IgnorePointer(
          ignoring: true,
          child: Opacity(opacity: 0.24, child: child),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.22),
            alignment: Alignment.center,
            child: upsell,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sem usuario
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t(context, 'dashboard'))),
        body: Padding(
          padding: Responsive.pagePadding(context),
          child: Center(
            child: Text(
              'Nenhum usuário cadastrado.\\nCrie uma conta para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
        ),
      );
    }

    // Enquanto carrega dashboard (evita _dashboard! null)
    if (_dashboard == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final d = _dashboard!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = DateUtilsJetx.monthYear(_currentMonth, locale: locale);

    final level = GamificationEngine.currentLevel(
      xp: _user!.totalXp,
      isPremium: _user!.isPremium,
    );
    final nextLevel = GamificationEngine.nextLevel(
      xp: _user!.totalXp,
      isPremium: _user!.isPremium,
    );

    final progress = nextLevel == null
        ? 1.0
        : ((_user!.totalXp - level.minXp) / (nextLevel.minXp - level.minXp))
            .clamp(0.0, 1.0);
    final overview = buildFinanceOverview(
      salary: d.salary,
      expenses: d.expenses,
      cards: _user?.creditCards ?? const [],
      creditCardPayments: d.creditCardPayments,
    );
    final fixedSpent = d.expenses
        .where((e) => e.type == ExpenseType.fixed && !e.isInvestment)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final variableSpent = d.expenses
        .where((e) => e.type == ExpenseType.variable && !e.isInvestment)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final investedTotal = overview.invested;
    final freeAmount = overview.availableNow;
    final recentExpenses = List<Expense>.from(d.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final visibleExpenses = recentExpenses.take(5).toList();
    final premiumHealthSection = Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _user!.isPremium ? _openInsights : null,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _scoreColor(_scoreStatus).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_score',
                      style: TextStyle(
                        color: _scoreColor(_scoreStatus),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(context, 'score_health_label'),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FinanceScoreUtils.localizeTip(
                            _scoreResult ??
                                HealthScoreResult(
                                  score: 0,
                                  status: 'critical',
                                  tip: '',
                                  tipKey: 'score_tip_add_income',
                                  needsIncome: true,
                                ),
                            tr: (key, params) =>
                                AppStrings.tr(context, key, params),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _distributionBar(
            context: context,
            fixedSpent: fixedSpent,
            variableSpent: variableSpent,
            invested: investedTotal,
            free: freeAmount,
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            debit: fixedSpent,
            credit: variableSpent,
            invest: investedTotal,
            free: freeAmount,
            salary: d.salary,
          ),
        ],
      ),
    );
    final premiumActionSection = Column(
      children: [
        _weeklyFocusCard(d),
        if (_insights.isNotEmpty) ...[
          const SizedBox(height: 18),
          _insightList(),
        ],
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        drawer: Responsive.width(context) >= 1024
            ? null
            : _JetxDrawer(
                user: _user!,
                timeline: _timeline,
                onLocaleChanged: () {
                  unawaited(_syncDueReminders());
                },
              ),
        appBar: AppBar(
          title: Text(title),
          actions: [
            const MoneyVisibilityButton(),
            IconButton(
              onPressed: _isWithinWindow(
                DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                  1,
                ),
              )
                  ? () => _changeMonth(-1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: _isWithinWindow(
                DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                  1,
                ),
              )
                  ? () => _changeMonth(1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _openProfile,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: _profilePhotoProvider(),
                    child: _profilePhotoProvider() == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.black,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: _BottomActionRow(
            onGoals: () {
              if (_user == null || !_user!.isPremium) {
                _openPremium();
                return;
              }
              Navigator.pushNamed(context, AppRoutes.goals);
            },
            onAdd: _openAddMenu,
            onCalculator: () {
              if (_user == null || !_user!.isPremium) {
                _openPremium();
                return;
              }
              Navigator.pushNamed(context, AppRoutes.investmentCalculator);
            },
          ),
        ),
        body: Padding(
          padding: Responsive.pagePadding(context),
          child: ListView(
            children: [
              Text(
                AppStrings.t(context, 'dashboard_base_income'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final wide = MediaQuery.sizeOf(context).width >= 680;
                  final buttonStyle = OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.yellow,
                    side: BorderSide(
                      color: AppTheme.yellow.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    visualDensity: VisualDensity.compact,
                  );

                  final actions = [
                    OutlinedButton.icon(
                      style: buttonStyle,
                      onPressed: _openIncomeEditorPopup,
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(AppStrings.t(context, 'edit_short')),
                    ),
                  ];

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            SensitiveDisplay.money(context, d.salary),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions,
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SensitiveDisplay.money(context, d.salary),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: actions,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              _financialPositionCard(overview),
              const SizedBox(height: 18),
              _creditCardBillsSection(overview),
              const SizedBox(height: 18),
              _premiumLockedPreview(
                title: AppStrings.t(context, 'dashboard_premium_health_title'),
                subtitle: AppStrings.t(
                  context,
                  'dashboard_premium_health_subtitle',
                ),
                perks: [
                  AppStrings.t(context, 'score_health_label'),
                  AppStrings.t(context, 'ratio_distribution_title'),
                  AppStrings.t(context, 'investment_premium_perk2'),
                ],
                usePreview: false,
                child: premiumHealthSection,
              ),
              const SizedBox(height: 18),
              _premiumLockedPreview(
                title: AppStrings.t(context, 'dashboard_premium_plan_title'),
                subtitle: AppStrings.t(
                  context,
                  'dashboard_premium_plan_subtitle',
                ),
                perks: [
                  AppStrings.t(context, 'weekly_plan_title'),
                  AppStrings.t(context, 'insights_title'),
                  AppStrings.t(context, 'investment_premium_perk2'),
                ],
                usePreview: false,
                child: premiumActionSection,
              ),
              const SizedBox(height: 18),
              /*
              /*
              if (false)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.premiumCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_user!.isPremium)
                        InkWell(
                          onTap: _openInsights,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _scoreColor(_scoreStatus)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_score',
                                    style: TextStyle(
                                      color: _scoreColor(_scoreStatus),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.t(
                                          context,
                                          'score_health_label',
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        FinanceScoreUtils.localizeTip(
                                          _scoreResult ??
                                              HealthScoreResult(
                                                score: 0,
                                                status: 'critical',
                                                tip: '',
                                                tipKey: 'score_tip_add_income',
                                                needsIncome: true,
                                              ),
                                          tr: (key, params) => AppStrings.tr(
                                            context,
                                            key,
                                            params,
                                          ),
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                          fontSize: 11,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.textSecondary(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_user!.isPremium) const SizedBox(height: 14),
                      if (false)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 112,
                                    height: 112,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 34,
                                        sections: _sections(
                                          fixedSpent: fixedSpent,
                                          variableSpent: variableSpent,
                                          invested: investedTotal,
                                          free: freeAmount,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Mix',
                                        style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'mês',
                                        style: TextStyle(
                                          color: AppTheme.textMuted(context),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryRow(
                                debit: fixedSpent,
                                credit: variableSpent,
                                invest: investedTotal,
                                free: freeAmount,
                                salary: d.salary,
                              ),
                            ),
                          ],
                        ),
                      _distributionBar(
                        context: context,
                        fixedSpent: fixedSpent,
                        variableSpent: variableSpent,
                        invested: investedTotal,
                        free: freeAmount,
                      ),
                      const SizedBox(height: 14),
                      _SummaryRow(
                        debit: fixedSpent,
                        credit: variableSpent,
                        invest: investedTotal,
                        free: freeAmount,
                        salary: d.salary,
                      ),
                    ],
                  ),
                ),
              if (false) const SizedBox(height: 18),
              if (false) _weeklyFocusCard(d),
              if (false) const SizedBox(height: 18),
              if (false && _user!.isPremium && _insights.isNotEmpty) ...[
                _insightList(),
                const SizedBox(height: 18),
              ],
              */
              if (false)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.premiumCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'ratio_distribution_title'),
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.t(context, 'ratio_distribution_subtitle'),
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 42,
                            sections: _sections(
                              fixedSpent: fixedSpent,
                              variableSpent: variableSpent,
                              invested: investedTotal,
                              free: freeAmount,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        debit: fixedSpent,
                        credit: variableSpent,
                        invest: investedTotal,
                        free: freeAmount,
                        salary: d.salary,
                      ),
                    ],
                  ),
                ),
              */
              const SizedBox(height: 18),
              Text(
                AppStrings.t(context, 'month_entries'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 10),
              if (visibleExpenses.isEmpty)
                EducationalEmptyState(
                  title: AppStrings.t(context, 'dashboard_empty_title'),
                  message: AppStrings.t(context, 'dashboard_empty_message'),
                  icon: Icons.receipt_long_outlined,
                  action: ElevatedButton(
                    onPressed: _openAddMenu,
                    child: Text(AppStrings.t(context, 'dashboard_empty_cta')),
                  ),
                )
              else
                for (var i = 0; i < visibleExpenses.length; i++) ...[
                  _DashboardExpenseTile(
                    expense: visibleExpenses[i],
                    onTogglePaid: (visibleExpenses[i].isFixed &&
                            !visibleExpenses[i].isCreditCard)
                        ? () => _toggleExpensePaid(
                              visibleExpenses[i],
                              !visibleExpenses[i].isPaid,
                            )
                        : null,
                    onEdit: () => _editExpense(visibleExpenses[i]),
                    onDelete: () => _deleteExpense(visibleExpenses[i]),
                  ),
                  if (i != visibleExpenses.length - 1)
                    const SizedBox(height: 10),
                ],
              if (d.expenses.length > visibleExpenses.length) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.transactions,
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text(AppStrings.t(context, 'view_all_entries')),
                  ),
                ),
              ],
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Drawer =================

class _JetxDrawer extends StatelessWidget {
  final UserProfile user;
  final List<String> timeline;
  final VoidCallback? onLocaleChanged;
  const _JetxDrawer({
    required this.user,
    required this.timeline,
    this.onLocaleChanged,
  });

  ImageProvider? _photoProvider() {
    final current = LocalStorageService.getUserProfile() ?? user;
    final path = current.photoPath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    final f = File(path);
    if (!f.existsSync()) return null;
    return FileImage(f);
  }

  @override
  Widget build(BuildContext context) {
    final current = LocalStorageService.getUserProfile() ?? user;
    final img = _photoProvider();
    final isPremium = current.isPremium;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget proBadge() {
      final primary = Theme.of(context).colorScheme.primary;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: primary.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 12, color: primary),
            const SizedBox(width: 5),
            Text(
              'PRO',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.2,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    Widget drawerCard(List<Widget> children) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.06),
          ),
        ),
        child: Column(children: children),
      );
    }

    Widget sectionLabel(String text) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    void openDrawerRoute(String route, {bool premiumOnly = false}) {
      Navigator.pop(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (premiumOnly && !isPremium) {
          showPremiumDialog(context);
          return;
        }
        Navigator.of(context).pushNamed(route);
      });
    }

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              scheme.surfaceContainerLowest,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListTileTheme(
                data: ListTileThemeData(
                  iconColor: AppTheme.textPrimary(context),
                  textColor: AppTheme.textPrimary(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => openDrawerRoute(AppRoutes.profile),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.premiumCardDecoration(
                            context,
                            borderColor: scheme.outline.withValues(alpha: 0.05),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: scheme.primary,
                                      backgroundImage: img,
                                      child: img == null
                                          ? const Icon(
                                              Icons.person,
                                              color: Colors.black,
                                              size: 28,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          current.fullName,
                                          style: TextStyle(
                                            color:
                                                AppTheme.textPrimary(context),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              isPremium
                                                  ? AppStrings.t(
                                                      context,
                                                      'drawer_premium_active',
                                                    )
                                                  : AppStrings.t(
                                                      context,
                                                      'drawer_essential_plan',
                                                    ),
                                              style: TextStyle(
                                                color: AppTheme.textSecondary(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            if (isPremium) proBadge(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHigh
                                          .withValues(alpha: 0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.textSecondary(context),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh
                                      .withValues(alpha: 0.32),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: scheme.outline.withValues(
                                      alpha: 0.06,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.t(
                                        context,
                                        'profile_edit_short',
                                      ),
                                      style: TextStyle(
                                        color: AppTheme.textSecondary(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    sectionLabel(AppStrings.t(context, 'drawer_shortcuts')),
                    drawerCard([
                      ListTile(
                        leading: Icon(
                          Icons.dashboard_outlined,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'dashboard'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'insights'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        onTap: () {
                          openDrawerRoute(AppRoutes.insights);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.list_alt_rounded,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'transactions'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        onTap: () {
                          openDrawerRoute(AppRoutes.transactions);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.track_changes_rounded,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'missions'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        trailing: !isPremium ? proBadge() : null,
                        onTap: () {
                          openDrawerRoute(
                            AppRoutes.missions,
                            premiumOnly: true,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.rocket_launch_outlined,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'goals'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        trailing: !isPremium ? proBadge() : null,
                        onTap: () {
                          openDrawerRoute(
                            AppRoutes.goals,
                            premiumOnly: true,
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 14),
                    sectionLabel(AppStrings.t(context, 'planning')),
                    drawerCard([
                      ListTile(
                        leading: Icon(
                          Icons.pie_chart_outline_rounded,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'reports'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        trailing: !isPremium ? proBadge() : null,
                        onTap: () {
                          openDrawerRoute(
                            AppRoutes.monthlyReport,
                            premiumOnly: true,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'budgets'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        trailing: !isPremium ? proBadge() : null,
                        onTap: () {
                          openDrawerRoute(
                            AppRoutes.budgets,
                            premiumOnly: true,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.trending_up_rounded,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'investments_plan'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        trailing: !isPremium ? proBadge() : null,
                        onTap: () {
                          openDrawerRoute(
                            AppRoutes.investmentPlan,
                            premiumOnly: true,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.calculate_outlined,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'simulator'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        trailing: !isPremium ? proBadge() : null,
                        onTap: () {
                          openDrawerRoute(
                            AppRoutes.investmentCalculator,
                            premiumOnly: true,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.payments_outlined,
                          color: AppTheme.textPrimary(context),
                        ),
                        title: Text(
                          AppStrings.t(context, 'debts_exit'),
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        trailing: !isPremium ? proBadge() : null,
                        onTap: () {
                          openDrawerRoute(
                            AppRoutes.debts,
                            premiumOnly: true,
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 14),
                    sectionLabel(AppStrings.t(context, 'drawer_preferences')),
                    drawerCard([
                      if (!isPremium)
                        ListTile(
                          leading: const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          title: Text(
                            AppStrings.t(context, 'premium_cta'),
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            AppStrings.t(context, 'premium_subtitle_short'),
                            style: TextStyle(
                              color: AppTheme.textMuted(context),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => showPremiumDialog(context),
                        ),
                      Consumer<ThemeState>(
                        builder: (context, themeState, _) => SwitchListTile(
                          value: themeState.mode == ThemeMode.system
                              ? Theme.of(context).brightness == Brightness.dark
                              : themeState.isDark,
                          onChanged: (v) => themeState.setMode(
                            v ? ThemeMode.dark : ThemeMode.light,
                          ),
                          title: Text(
                            AppStrings.t(context, 'dark_theme'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          secondary: const Icon(Icons.contrast),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _LanguageSwitcher(
                      onLocaleChanged: onLocaleChanged,
                    ),
                    if (isPremium && timeline.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      sectionLabel(AppStrings.t(context, 'timeline_title')),
                      drawerCard([
                        ...timeline.map(
                          (t) => ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.auto_awesome,
                              color: AppTheme.textMuted(context),
                              size: 18,
                            ),
                            title: Text(
                              t,
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            // Footer pinned to bottom
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Container(
                  decoration: AppTheme.premiumCardDecoration(context),
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: AppTheme.textSecondary(context),
                    ),
                    title: Text(
                      AppStrings.t(context, 'logout'),
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await LocalStorageService.logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({this.onLocaleChanged});

  final VoidCallback? onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final localeState = context.read<LocaleState>();
    final current = localeState.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(context, 'language'),
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _LangOption(
                  label: AppStrings.t(context, 'language_pt'),
                  code: 'pt',
                  selected: current == 'pt',
                  onTap: () {
                    localeState.setLocale(const Locale('pt', 'BR'));
                    onLocaleChanged?.call();
                  },
                ),
                const SizedBox(width: 8),
                _LangOption(
                  label: AppStrings.t(context, 'language_en'),
                  code: 'en',
                  selected: current == 'en',
                  onTap: () {
                    localeState.setLocale(const Locale('en'));
                    onLocaleChanged?.call();
                  },
                ),
                const SizedBox(width: 8),
                _LangOption(
                  label: AppStrings.t(context, 'language_es'),
                  code: 'es',
                  selected: current == 'es',
                  onTap: () {
                    localeState.setLocale(const Locale('es'));
                    onLocaleChanged?.call();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        selected ? Theme.of(context).colorScheme.primary : Colors.white10;
    final fg = selected ? Colors.black : AppTheme.textSecondary(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Text(
                code.toUpperCase(),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(label, style: TextStyle(color: fg, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============== Bottom action row ===============

class _BottomActionRow extends StatelessWidget {
  final VoidCallback onGoals;
  final VoidCallback onAdd;
  final VoidCallback onCalculator;

  const _BottomActionRow({
    required this.onGoals,
    required this.onAdd,
    required this.onCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 72,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: 'goals',
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: AppTheme.textPrimary(context),
            onPressed: onGoals,
            child: const Icon(Icons.flag),
          ),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: 'calc',
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: AppTheme.textPrimary(context),
            onPressed: onCalculator,
            child: const Icon(Icons.calculate),
          ),
        ],
      ),
    );
  }
}

enum _GuideActionStatus { pending, done, skipped }

class _GuideAction {
  final String id;
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String helpKey;
  final bool canSkip;
  final VoidCallback onTap;

  const _GuideAction({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.helpKey,
    this.canSkip = false,
    required this.onTap,
  });
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

// =============== Summary row ===============

class _SummaryRow extends StatelessWidget {
  final double debit;
  final double credit;
  final double invest;
  final double free;
  final double salary;

  const _SummaryRow({
    required this.debit,
    required this.credit,
    required this.invest,
    required this.free,
    required this.salary,
  });

  String _percent(double value) {
    if (salary <= 0) return '0%';
    return '${((value / salary) * 100).toStringAsFixed(0)}%';
  }

  void _expandCard(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: Container(
          margin: EdgeInsets.all(Responsive.isCompactPhone(context) ? 16 : 24),
          padding: EdgeInsets.all(Responsive.isCompactPhone(context) ? 16 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.28), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppTheme.textSecondary(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                SensitiveDisplay.money(context, value),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _percent(value),
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 24),
              // Adicionando um pequeno detalhe ou dica baseado no tipo
              Text(
                _getTipForCategory(context, label),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted(context),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTipForCategory(BuildContext context, String label) {
    final lower = label.toLowerCase();
    if (lower.contains('fix')) {
      return AppStrings.t(context, 'ratio_tip_fixed');
    }
    if (lower.contains('vari')) {
      return AppStrings.t(context, 'ratio_tip_variable');
    }
    if (lower.contains('invest') || lower.contains('inv.')) {
      return AppStrings.t(context, 'ratio_tip_invest');
    }
    if (lower.contains('sobra') || lower.contains('buffer')) {
      return AppStrings.t(context, 'ratio_tip_buffer');
    }
    return '';
  }

  Widget _legendRow(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _expandCard(context, label, value, color),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          SensitiveDisplay.money(context, value),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _percent(value),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _legendRow(
          context,
          AppStrings.t(context, 'ratio_fixed'),
          debit,
          AppTheme.danger,
          Icons.event_repeat_rounded,
        ),
        const SizedBox(height: 8),
        _legendRow(
          context,
          AppStrings.t(context, 'ratio_variable'),
          credit,
          AppTheme.warning,
          Icons.tune_rounded,
        ),
        const SizedBox(height: 8),
        _legendRow(
          context,
          AppStrings.t(context, 'ratio_invest'),
          invest,
          AppTheme.info,
          Icons.savings,
        ),
        const SizedBox(height: 8),
        _legendRow(
          context,
          AppStrings.t(context, 'ratio_buffer'),
          free,
          AppTheme.success,
          Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }
}

// =============== Expense tile ===============

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTogglePaid;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ExpenseTile({
    required this.expense,
    this.onTogglePaid,
    this.onEdit,
    this.onDelete,
  });

  Color get _color {
    switch (expense.type) {
      case ExpenseType.fixed:
        return AppTheme.danger;
      case ExpenseType.variable:
        return AppTheme.warning;
      case ExpenseType.investment:
        return AppTheme.info;
    }
  }

  String get _typeLabel {
    switch (expense.type) {
      case ExpenseType.fixed:
        return 'Fixo';
      case ExpenseType.variable:
        return 'Variável';
      case ExpenseType.investment:
        return 'Investimento';
    }
  }

  String _categoryLabel(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.moradia:
        return 'Moradia';
      case ExpenseCategory.alimentacao:
        return 'Alimentação';
      case ExpenseCategory.transporte:
        return 'Transporte';
      case ExpenseCategory.educacao:
        return 'Educação';
      case ExpenseCategory.saude:
        return 'Saúde';
      case ExpenseCategory.lazer:
        return 'Lazer';
      case ExpenseCategory.assinaturas:
        return 'Assinaturas';
      case ExpenseCategory.investment:
        return 'Investimento';
      case ExpenseCategory.dividas:
        return 'Dívidas';
      case ExpenseCategory.outros:
        return 'Outros';
    }
  }

  @override
  Widget build(BuildContext context) {
    final due =
        (expense.isFixed || expense.isCreditCard) && expense.dueDay != null
            ? expense.isCreditCard
                ? ' • Fatura dia ${expense.dueDay}'
                : ' • Vence dia ${expense.dueDay}'
            : '';
    final paymentInfo = ' • ${paymentMethodLabel(expense)}';
    final flowInfo = ' • ${paymentImpactLabel(expense)}';
    final subtitleText = expense.isInvestment
        ? _typeLabel
        : '$_typeLabel - ${_categoryLabel(expense.category)}$paymentInfo$flowInfo$due';
    final canTogglePaid = onTogglePaid != null;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: true,
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        title: Text(
          expense.name,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitleText,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [
                if (canTogglePaid)
                  IconButton(
                    onPressed: onTogglePaid,
                    icon: Icon(
                      expense.isPaid
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: expense.isPaid
                          ? AppTheme.success
                          : AppTheme.textMuted(context),
                      size: 18,
                    ),
                    tooltip: expense.isPaid ? 'Pago' : 'Pagar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                  ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textMuted(context),
                    size: 18,
                  ),
                  tooltip: AppStrings.t(context, 'edit_entry'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.textMuted(context),
                    size: 18,
                  ),
                  tooltip: AppStrings.t(context, 'delete_entry'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          SensitiveDisplay.money(context, expense.amount),
          style: TextStyle(
            color: _color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DashboardExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTogglePaid;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DashboardExpenseTile({
    required this.expense,
    this.onTogglePaid,
    this.onEdit,
    this.onDelete,
  });

  Color get _color {
    switch (expense.type) {
      case ExpenseType.fixed:
        return AppTheme.danger;
      case ExpenseType.variable:
        return AppTheme.warning;
      case ExpenseType.investment:
        return AppTheme.info;
    }
  }

  IconData get _categoryIcon {
    switch (expense.category) {
      case ExpenseCategory.moradia:
        return Icons.home_rounded;
      case ExpenseCategory.alimentacao:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transporte:
        return Icons.directions_car_filled_rounded;
      case ExpenseCategory.educacao:
        return Icons.school_rounded;
      case ExpenseCategory.saude:
        return Icons.favorite_rounded;
      case ExpenseCategory.lazer:
        return Icons.celebration_rounded;
      case ExpenseCategory.assinaturas:
        return Icons.subscriptions_rounded;
      case ExpenseCategory.investment:
        return Icons.trending_up_rounded;
      case ExpenseCategory.dividas:
        return Icons.savings_outlined;
      case ExpenseCategory.outros:
        return Icons.widgets_rounded;
    }
  }

  IconData get _paymentIcon {
    if (expense.isInvestment) return Icons.trending_up_rounded;
    return expense.isCreditCard
        ? Icons.credit_card_rounded
        : Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = localizedExpenseTypeLabel(context, expense.type);
    final categoryLabel = localizedExpenseCategoryLabel(
      context,
      expense.category,
    );
    final paymentLabel = localizedPaymentMethodLabel(context, expense);
    final impactLabel = localizedPaymentImpactLabel(context, expense);
    final dueLabel = localizedExpenseDueLabel(context, expense);
    final summaryLabel = expense.isInvestment
        ? typeLabel
        : '$typeLabel • $categoryLabel • $paymentLabel';
    final canTogglePaid = onTogglePaid != null;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Color.alphaBlend(
      _color.withValues(alpha: isDark ? 0.06 : 0.035),
      scheme.surfaceContainerLow,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: _color.withValues(alpha: isDark ? 0.16 : 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _color.withValues(alpha: isDark ? 0.24 : 0.16),
                ),
              ),
              child: Icon(_categoryIcon, color: _color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          expense.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        SensitiveDisplay.money(context, expense.amount),
                        style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (impactLabel.isNotEmpty || dueLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (impactLabel.isNotEmpty)
                          _DashboardEntryMeta(
                            icon: _paymentIcon,
                            label: impactLabel,
                            color: _color,
                          ),
                        if (dueLabel.isNotEmpty)
                          _DashboardEntryMeta(
                            icon: Icons.event_outlined,
                            label: dueLabel,
                            color: AppTheme.textMuted(context),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (canTogglePaid)
                        _DashboardActionButton(
                          icon: expense.isPaid
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: expense.isPaid
                              ? AppTheme.success
                              : AppTheme.textMuted(context),
                          tooltip: expense.isPaid
                              ? AppStrings.t(context, 'paid')
                              : AppStrings.t(context, 'bills_pay_cta'),
                          onPressed: onTogglePaid,
                        ),
                      _DashboardActionButton(
                        icon: Icons.edit_outlined,
                        color: AppTheme.textMuted(context),
                        tooltip: AppStrings.t(context, 'edit_entry'),
                        onPressed: onEdit,
                      ),
                      _DashboardActionButton(
                        icon: Icons.delete_outline,
                        color: AppTheme.textMuted(context),
                        tooltip: AppStrings.t(context, 'delete_entry'),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEntryMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DashboardEntryMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 11,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _DashboardActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _DashboardActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest
              .withValues(alpha: isDark ? 0.78 : 1),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.08)),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }
}
