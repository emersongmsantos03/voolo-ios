import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetx/core/gamification/gamification.dart';
import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/models/credit_card.dart';
import 'package:jetx/models/debt_v2.dart';
import 'package:jetx/models/expense.dart';
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
import 'package:jetx/state/locale_state.dart';
import 'package:jetx/state/theme_state.dart';
import 'package:jetx/core/theme/app_theme.dart';
import 'package:jetx/core/ui/formatters/money_text_input_formatter.dart';
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/core/utils/sensitive_display.dart';
import 'package:jetx/utils/money_input.dart';
import 'package:jetx/utils/date_utils.dart';
import 'package:jetx/utils/finance_score_utils.dart';
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
              .where((e) =>
                  e.category == ExpenseCategory.moradia && !e.isInvestment)
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
        ? _replicateFixedExpenses(
            _currentMonth.month,
            _currentMonth.year,
          )
        : const <Expense>[];

    final base = existing ??
        MonthlyDashboard(
          month: _currentMonth.month,
          year: _currentMonth.year,
          salary: _user!.monthlyIncome,
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
        _insights = _insightService.generateInsights(_dashboard!, goals, plan);

        final housing = _dashboard!.expenses
            .where(
                (e) => e.category == ExpenseCategory.moradia && !e.isInvestment)
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
    _insights = _insightService.generateInsights(_dashboard!, goals, plan);

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
    final next = await HabitsService.toggleHabit(
      habitId: habitId,
      totalHabits: totalHabits,
    );
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

  void _changeMonth(int delta) {
    final next = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    if (!_isWithinWindow(next)) return;
    _currentMonth = next;
    _load();
  }

  bool _isWithinWindow(DateTime month) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 11, 1);
    return !(month.isBefore(start) || month.isAfter(end));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
                      fontWeight: FontWeight.w600),
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
          'Tivemos um problema ao sincronizar, mas seus dados estão salvos localmente.');
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                      title: const Text('Cartão de crédito'),
                      value: isCard,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      activeTrackColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.35),
                      inactiveThumbColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.20),
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
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  categoryLabel(c),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
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
                        style:
                            TextStyle(color: AppTheme.textSecondary(context)),
                      ),
                    ),
                  if (!isInvestment) ...[
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: cards.isEmpty ? null : creditCardId,
                      decoration: const InputDecoration(labelText: 'Cartão'),
                      items: cards.isEmpty
                          ? const [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Sem cartão cadastrado',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]
                          : cards
                              .map((c) => DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                      onChanged: (!isCard || cards.isEmpty)
                          ? null
                          : (v) {
                              if (v == null) return;
                              setDialogState(() {
                                creditCardId = v;
                                final selected =
                                    cards.firstWhere((c) => c.id == v);
                                cardDueDay = selected.dueDay;
                              });
                            },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vencimento do cartão: dia ${cardDueDay ?? '-'}',
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
                      decoration: const InputDecoration(
                        labelText: 'Dia de vencimento (opcional)',
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
            child: const Text('Somente este mês'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('Meses seguintes'),
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
    _dashboard = MonthlyDashboard(
      month: _dashboard!.month,
      year: _dashboard!.year,
      salary: _dashboard!.salary,
      expenses: List.of(_dashboard!.expenses),
      creditCardPayments: updated,
    );
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
                  labelText: AppStrings.t(context, 'card_name')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: dueDay,
              decoration: InputDecoration(
                  labelText: AppStrings.t(context, 'card_due_day')),
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
          previous: _user!, updated: newUser);
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
                final incomes = LocalStorageService.getIncomes().toList()
                  ..sort((a, b) {
                    if (a.isPrimary == b.isPrimary) return 0;
                    return a.isPrimary ? -1 : 1;
                  });

                return SizedBox(
                  height: maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar rendas',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toque em uma renda para editar.',
                        style:
                            TextStyle(color: AppTheme.textSecondary(context)),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            await IncomeModal.show(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar renda'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: incomes.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhuma renda cadastrada.',
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
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: Text(
                                        income.title,
                                        style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        income.isPrimary
                                            ? 'Renda principal'
                                            : (income.type == 'variable'
                                                ? 'Renda variável'
                                                : 'Renda fixa'),
                                        style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            SensitiveDisplay.money(
                                                context, income.amount),
                                            style: TextStyle(
                                              color:
                                                  AppTheme.textPrimary(context),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color:
                                                AppTheme.textSecondary(context),
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
    final balance = d.remainingSalary;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t(context, 'essential_balance_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tr(
                context,
                'essential_balance_entries',
                {'value': SensitiveDisplay.money(context, entries)},
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.tr(
                context,
                'essential_balance_exits',
                {'value': SensitiveDisplay.money(context, exits)},
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.tr(
                context,
                'essential_balance_free',
                {'value': SensitiveDisplay.money(context, balance)},
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
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
                .where((s) =>
                    s == _GuideActionStatus.done ||
                    s == _GuideActionStatus.skipped)
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
                              context, 'essential_guide_subtitle_free'),
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tr(
                        context,
                        'essential_guide_progress',
                        {
                          'done': '$doneCount',
                          'total': '${actions.length}',
                        },
                      ),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.35),
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
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
                                                      context, 'close'),
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
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          AppStrings.t(context, 'essential_guide_later'),
                        ),
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
                    Icon(Icons.chevron_right,
                        size: 14, color: Theme.of(context).colorScheme.primary),
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

  Widget _alertsCard(MonthlyDashboard d) {
    final salaryFallback =
        LocalStorageService.incomeTotalForMonth(_currentMonth);
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
          Text(
            AppStrings.t(context, 'alert_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
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
          Text(
            AppStrings.t(context, 'plan_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
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

  Widget _creditCardBillsSection(MonthlyDashboard d) {
    final cards = _user?.creditCards ?? [];
    if (cards.isEmpty) return const SizedBox.shrink();

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
          Text(
            AppStrings.t(context, 'credit_card_bills_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...cards.map(
            (card) {
              final paid = d.creditCardPayments[card.id] ?? false;
              final invoiceTotal = d.expenses
                  .where((e) => e.isCreditCard && e.creditCardId == card.id)
                  .fold(0.0, (sum, e) => sum + e.amount);
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style:
                              TextStyle(color: AppTheme.textPrimary(context)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.tr(
                            context,
                            'card_due_day_label',
                            {'day': '${card.dueDay}'},
                          ),
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          SensitiveDisplay.money(context, invoiceTotal),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: paid,
                    onChanged: (v) => _setCardPayment(card.id, v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    AppStrings.t(context, 'card_invoice_paid'),
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  MonthlyDashboard? _previousMonthDashboard() {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    return LocalStorageService.getDashboard(prev.month, prev.year);
  }

  Widget _buildProgressCard(
      FinancialLevel level, double progress, FinancialLevel? nextLevel) {
    final primary = Theme.of(context).colorScheme.primary;
    final currentXp = _user?.totalXp ?? 0;
    final isMaxLevel = nextLevel == null;
    final nextTargetXp = nextLevel?.minXp;
    final percent = (progress * 100).clamp(0.0, 100.0).round();
    final levelName = AppStrings.t(context, 'financial_level_${level.level}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  AppStrings.tr(
                    context,
                    'level_label',
                    {'level': '${level.level}'},
                  ),
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
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
              backgroundColor:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(
                primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tr(
              context,
              'level_progress_next',
              {'pct': '$percent'},
            ),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
      title:
          Text(title, style: TextStyle(color: AppTheme.textPrimary(context))),
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
      final date =
          DateTime(year, month, clampDueDay(template.dueDay, daysInMonth));

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

  Future<void> _openAddExpenseDialog(
      {required ExpenseType type, ExpenseCategory? category}) async {
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
      final income = _user?.monthlyIncome ?? 0;
      if (income <= 0) return null;
      final amount = parseMoneyInput(amountController.text);
      if (amount <= 0) return null;
      final pct = (amount / income) * 100;

      final idealPct = isInvestment
          ? 25
          : selectedCategory == ExpenseCategory.moradia
              ? 35
              : 10;
      if (pct < idealPct) return null;

      return contextTip(
        Icons.report_problem_outlined,
        AppStrings.tr(
          context,
          'expense_high_tip',
          {
            'pct': pct.toStringAsFixed(0),
            'ideal': idealPct.toString(),
          },
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
            final showBillDueDay = isFixed;
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
                    decoration:
                        const InputDecoration(labelText: 'Nome do gasto'),
                  ),
                  const SizedBox(height: 12),
                  if (!isInvestment) ...[
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: ExpenseCategory.values
                          .where((c) =>
                              c != ExpenseCategory.investment &&
                              (isFixed || c != ExpenseCategory.assinaturas))
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_categoryLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                          () => selectedCategory = v ?? ExpenseCategory.outros),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  if (highExpenseTip() != null) highExpenseTip()!,
                  if (showBillDueDay) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      initialValue: dueDay,
                      decoration: const InputDecoration(
                        labelText: 'Dia de vencimento (opcional)',
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
                  if (!isInvestment) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: hasCards ? creditCardId : null,
                      decoration: const InputDecoration(
                        labelText: 'Cartão de crédito',
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
                          : const [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Sem cartão cadastrado',
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
                      'Vencimento do cartão: dia ${selectedCardDueDay ?? '-'}',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (!isInvestment) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: isCreditCard,
                      onChanged: (v) {
                        if (v && cards.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Cadastre um cartão primeiro.')),
                          );
                          return;
                        }
                        setState(() {
                          isCreditCard = v;
                          if (isCreditCard && hasCards) {
                            creditCardId = creditCardId ?? cards.first.id;
                            final selected = cards.firstWhere(
                              (c) => c.id == creditCardId,
                              orElse: () => cards.first,
                            );
                            creditCardId = selected.id;
                            cardDueDay = selected.dueDay;
                          } else {
                            creditCardId = null;
                            cardDueDay = null;
                            isInstallment = false;
                            installments = null;
                            if (!isFixed) {
                              dueDay = null;
                            }
                          }
                          if (!isCreditCard) {
                            isInstallment = false;
                            installments = null;
                          }
                        });
                      },
                      title: Text('Conta no cartão de crédito'),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      activeTrackColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.35),
                      inactiveThumbColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.20),
                      contentPadding: EdgeInsets.zero,
                    ),
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
                        activeTrackColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.35),
                        inactiveThumbColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                        inactiveTrackColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.20),
                        contentPadding: EdgeInsets.zero,
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
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final amount = parseMoneyInput(amountController.text);

              if (name.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Preencha nome e valor corretamente.')),
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
                      content: Text('Informe a quantidade de parcelas.')),
                );
                return;
              }
              if (isFixed && isCreditCard && isInstallment) {
                final cents = (amount * 100).round();
                if (installments != null && cents < installments!) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'O valor ? muito baixo para parcelar em tantas vezes.')),
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
                        content: Text('Cadastre um cartão primeiro.')),
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
              } else {
                await LocalStorageService.saveExpense(expense);

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

  // ====== PIE ======

  List<PieChartSectionData> _sections(MonthlyDashboard d) {
    final fixed = d.fixedExpensesTotal;
    final variable = d.variableExpensesTotal;
    final invest = d.investmentsTotal;
    final free = d.remainingSalary;
    final total = fixed + variable + invest + free;

    String pct(double value) {
      if (total <= 0) return '0%';
      final percent = ((value / total) * 100).toStringAsFixed(0);
      return '$percent%';
    }

    final allZero = fixed <= 0 && variable <= 0 && invest <= 0 && free <= 0;
    if (allZero) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.white12,
          showTitle: true,
          title: '0%',
          titleStyle:
              TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
          radius: 54,
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: fixed <= 0 ? 0.01 : fixed,
        color: AppTheme.danger,
        showTitle: fixed > 0,
        title: pct(fixed),
        titleStyle:
            TextStyle(color: AppTheme.textPrimary(context), fontSize: 12),
        radius: 54,
      ),
      PieChartSectionData(
        value: variable <= 0 ? 0.01 : variable,
        color: AppTheme.warning,
        showTitle: variable > 0,
        title: pct(variable),
        titleStyle:
            TextStyle(color: AppTheme.textPrimary(context), fontSize: 12),
        radius: 54,
      ),
      PieChartSectionData(
        value: invest <= 0 ? 0.01 : invest,
        color: AppTheme.info,
        showTitle: invest > 0,
        title: pct(invest),
        titleStyle:
            TextStyle(color: AppTheme.textPrimary(context), fontSize: 12),
        radius: 54,
      ),
      PieChartSectionData(
        value: free <= 0 ? 0.01 : free,
        color: AppTheme.success,
        showTitle: free > 0,
        title: pct(free),
        titleStyle:
            TextStyle(color: AppTheme.textPrimary(context), fontSize: 12),
        radius: 54,
      ),
    ];
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
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        drawer: _JetxDrawer(user: _user!, timeline: _timeline),
        appBar: AppBar(
          title: Text(title),
          actions: [
            const MoneyVisibilityButton(),
            IconButton(
              onPressed: (_user?.isPremium ?? false) &&
                      _isWithinWindow(
                        DateTime(
                            _currentMonth.year, _currentMonth.month - 1, 1),
                      )
                  ? () => _changeMonth(-1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: (_user?.isPremium ?? false) &&
                      _isWithinWindow(
                        DateTime(
                            _currentMonth.year, _currentMonth.month + 1, 1),
                      )
                  ? () => _changeMonth(1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _BottomActionRow(
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
        body: Padding(
          padding: Responsive.pagePadding(context),
          child: ListView(
            children: [
              Text(
                AppStrings.t(context, 'month_salary'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      SensitiveDisplay.money(context, d.salary),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openIncomeEditorPopup,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!_user!.isPremium) ...[
                PremiumUpsellCard(
                  perks: [
                    AppStrings.t(context, 'score_title_month_tips'),
                    AppStrings.t(context, 'premium_step_invest_title'),
                    AppStrings.t(context, 'missions_premium_perk3'),
                  ],
                  onCta: _openPremium,
                ),
                const SizedBox(height: 18),
              ],

              // Progresso e niveis (Simplified for logic cleanup)
              if (_user!.isPremium)
                _buildProgressCard(level, progress, nextLevel)
              else
                _lockedFeatureCard(
                  title: AppStrings.t(context, 'progress_levels_title'),
                  subtitle: AppStrings.t(
                    context,
                    'progress_levels_locked_subtitle',
                  ),
                  icon: Icons.lock_outline,
                ),
              const SizedBox(height: 18),

              if (_user!.isPremium)
                InkWell(
                  onTap: _openInsights,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: EdgeInsets.all(
                        Responsive.isCompactPhone(context) ? 16 : 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .shadowColor
                              .withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: _score / 100,
                                strokeWidth: 8,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _scoreColor(_scoreStatus)),
                              ),
                            ),
                            Text(
                              '$_score',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.t(context, 'score_health_label'),
                                style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 6),
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
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppTheme.textSecondary(context)),
                      ],
                    ),
                  ),
                )
              else
                _lockedFeatureCard(
                  title: AppStrings.t(context, 'score_title'),
                  subtitle: AppStrings.t(context, 'score_locked_subtitle'),
                  icon: Icons.shield_outlined,
                ),
              const SizedBox(height: 18),
              const SizedBox(height: 18),

              Card(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 48,
                        sections: _sections(d),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _SummaryRow(
                fixed: d.fixedExpensesTotal,
                variable: d.variableExpensesTotal,
                invest: d.investmentsTotal,
                free: d.remainingSalary,
                salary: d.salary,
              ),

              const SizedBox(height: 18),
              if (_user!.isPremium)
                _comparisonCard(d)
              else
                _lockedFeatureCard(
                  title: AppStrings.t(context, 'compare_title'),
                  subtitle: AppStrings.t(
                    context,
                    'compare_locked_subtitle',
                  ),
                  icon: Icons.compare_arrows,
                ),

              const SizedBox(height: 18),
              _creditCardBillsSection(d),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add_card),
                  label: Text(AppStrings.t(context, 'card_add')),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.t(context, 'month_entries'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 10),

              if (d.expenses.isEmpty)
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
                ...d.expenses.map(
                  (e) => _ExpenseTile(
                    expense: e,
                    onTogglePaid: (e.isFixed && !e.isCreditCard)
                        ? () => _toggleExpensePaid(e, !e.isPaid)
                        : null,
                    onEdit: () => _editExpense(e),
                    onDelete: () => _deleteExpense(e),
                  ),
                ),
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
  const _JetxDrawer({required this.user, required this.timeline});

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

    Widget proBadge() {
      final primary = Theme.of(context).colorScheme.primary;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: primary.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 14, color: primary),
            const SizedBox(width: 6),
            Text(
              'PRO',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundImage: img,
                            child: img == null
                                ? const Icon(Icons.person,
                                    color: Colors.black, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              current.fullName,
                              style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.profile);
                        },
                        icon:
                            const Icon(Icons.person_outline_rounded, size: 16),
                        label:
                            Text(AppStrings.t(context, 'profile_edit_short')),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary(context),
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.dashboard_outlined,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'dashboard'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.track_changes_rounded,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'missions'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: !isPremium ? proBadge() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isPremium) {
                      showPremiumDialog(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.missions);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.rocket_launch_outlined,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'goals'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: !isPremium ? proBadge() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isPremium) {
                      showPremiumDialog(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.goals);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.pie_chart_outline_rounded,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'reports'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: !isPremium ? proBadge() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isPremium) {
                      showPremiumDialog(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.monthlyReport);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calculate_outlined,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'simulator'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: !isPremium ? proBadge() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isPremium) {
                      showPremiumDialog(context);
                      return;
                    }
                    Navigator.pushNamed(
                        context, AppRoutes.investmentCalculator);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lightbulb_outline_rounded,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'insights'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.insights);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.list_alt_rounded,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'transactions'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.transactions);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    AppStrings.t(context, 'planning'),
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'budgets'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: !isPremium ? proBadge() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isPremium) {
                      showPremiumDialog(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.budgets);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.trending_up_rounded,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'investments_plan'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: !isPremium ? proBadge() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isPremium) {
                      showPremiumDialog(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.investmentPlan);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.payments_outlined,
                      color: AppTheme.textPrimary(context)),
                  title: Text(
                    AppStrings.t(context, 'debts_exit'),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: !isPremium ? proBadge() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isPremium) {
                      showPremiumDialog(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.debts);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                if (!isPremium)
                  ListTile(
                    leading:
                        const Icon(Icons.star_rounded, color: Colors.amber),
                    title: Text(
                      AppStrings.t(context, 'premium_cta'),
                      style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      AppStrings.t(context, 'premium_subtitle_short'),
                      style: TextStyle(
                          color: AppTheme.textMuted(context), fontSize: 12),
                    ),
                    onTap: () => showPremiumDialog(context),
                  ),
                if (isPremium && timeline.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 4, bottom: 6),
                    child: Text(
                      AppStrings.t(context, 'timeline_title'),
                      style: TextStyle(
                          color: AppTheme.textSecondary(context), fontSize: 12),
                    ),
                  ),
                  ...timeline.map(
                    (t) => ListTile(
                      dense: true,
                      leading: Icon(Icons.auto_awesome,
                          color: AppTheme.textMuted(context), size: 18),
                      title: Text(
                        t,
                        style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12),
                      ),
                    ),
                  ),
                ],
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
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    secondary: const Icon(Icons.contrast),
                  ),
                ),
                const _LanguageSwitcher(),
              ],
            ),
          ),
          // Footer pinned to bottom
          SafeArea(
            top: false,
            child: ListTile(
              leading:
                  Icon(Icons.logout, color: AppTheme.textSecondary(context)),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();

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
                  color: AppTheme.textSecondary(context), fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _LangOption(
                  label: AppStrings.t(context, 'language_pt'),
                  code: 'pt',
                  selected: current == 'pt',
                  onTap: () => localeState.setLocale(const Locale('pt', 'BR')),
                ),
                const SizedBox(width: 8),
                _LangOption(
                  label: AppStrings.t(context, 'language_en'),
                  code: 'en',
                  selected: current == 'en',
                  onTap: () => localeState.setLocale(const Locale('en')),
                ),
                const SizedBox(width: 8),
                _LangOption(
                  label: AppStrings.t(context, 'language_es'),
                  code: 'es',
                  selected: current == 'es',
                  onTap: () => localeState.setLocale(const Locale('es')),
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
                color: selected ? Colors.transparent : Colors.white12),
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
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 10,
                ),
              ),
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
      child: Row(
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
  final double fixed;
  final double variable;
  final double invest;
  final double free;
  final double salary;

  const _SummaryRow({
    required this.fixed,
    required this.variable,
    required this.invest,
    required this.free,
    required this.salary,
  });

  String _percent(double value) {
    if (salary <= 0) return '0%';
    return '${((value / salary) * 100).toStringAsFixed(0)}%';
  }

  void _expandCard(
      BuildContext context, String label, double value, Color color) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: Container(
          margin: EdgeInsets.all(Responsive.isCompactPhone(context) ? 16 : 24),
          padding: EdgeInsets.all(Responsive.isCompactPhone(context) ? 16 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: 0.28),
              width: 2,
            ),
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
                _getTipForCategory(label),
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

  String _getTipForCategory(String label) {
    if (label.contains('Fixo')) {
      return 'Mantenha seus custos fixos abaixo de 50% de sua renda.';
    }
    if (label.contains('Variave')) {
      return 'Gastos variaveis devem ser monitorados de perto para evitar surpresas.';
    }
    if (label.contains('Investimento')) {
      return 'Tente investir pelo menos 15-20% de sua renda mensal.';
    }
    if (label.contains('Livre')) {
      return 'Este e o valor que voce tem disponivel apos todas as obrigacoes.';
    }
    return '';
  }

  Widget _pill(BuildContext context, String label, double value, Color color,
      IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => _expandCard(context, label, value, color),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(label,
                          style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis)),
                  Icon(icon, size: 14, color: AppTheme.textMuted(context)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                SensitiveDisplay.money(context, value),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _percent(value),
                style:
                    TextStyle(color: AppTheme.textMuted(context), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill(context, AppStrings.t(context, 'summary_fixed'), fixed,
            AppTheme.danger, Icons.lock_outline),
        const SizedBox(width: 8),
        _pill(context, AppStrings.t(context, 'summary_variable'), variable,
            AppTheme.warning, Icons.shopping_bag_outlined),
        const SizedBox(width: 8),
        _pill(context, AppStrings.t(context, 'summary_invest'), invest,
            AppTheme.info, Icons.savings),
        const SizedBox(width: 8),
        _pill(context, AppStrings.t(context, 'summary_free'), free,
            AppTheme.success, Icons.account_balance_wallet_outlined),
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
                ? ' ? Fatura dia ${expense.dueDay}'
                : ' ? Vence dia ${expense.dueDay}'
            : '';
    final cardInfo = expense.isCreditCard
        ? expense.installmentIndex != null && expense.installments != null
            ? ' ? Cartão ${expense.installmentIndex}/${expense.installments}'
            : expense.isCardRecurring
                ? ' ? ${AppStrings.t(context, 'card_recurring_short')}'
                : ' ? Cartão'
        : '';
    final subtitleText = expense.isInvestment
        ? _typeLabel
        : '$_typeLabel - ${_categoryLabel(expense.category)}$due$cardInfo';
    final canTogglePaid = onTogglePaid != null;
    return Card(
      elevation: 0,
      child: ListTile(
        isThreeLine: true,
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        title: Text(expense.name,
            style: TextStyle(color: AppTheme.textPrimary(context))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitleText,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 6),
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
                      size: 20,
                    ),
                    tooltip: expense.isPaid ? 'Pago' : 'Pagar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 34, height: 34),
                  ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textMuted(context),
                    size: 20,
                  ),
                  tooltip: AppStrings.t(context, 'edit_entry'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 34, height: 34),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.textMuted(context),
                    size: 20,
                  ),
                  tooltip: AppStrings.t(context, 'delete_entry'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 34, height: 34),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          SensitiveDisplay.money(context, expense.amount),
          style: TextStyle(color: _color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
