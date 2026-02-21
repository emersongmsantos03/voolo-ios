import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/expense.dart';
import '../../models/monthly_dashboard.dart';
import '../../models/v2/category_key.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../core/utils/sensitive_display.dart';
import '../../services/local_storage_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_input.dart';
import '../../utils/date_utils.dart';
import '../../utils/expense_filter_utils.dart';
import '../../routes/app_routes.dart';
import '../../core/plans/user_plan.dart';
import '../../widgets/money_visibility_button.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/premium_tour_widgets.dart';

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  late DateTime _currentMonth;
  MonthlyDashboard? _dashboard;
  List<Expense> _currentExpenses = const [];
  List<Expense> _prevExpenses = const [];
  StreamSubscription<List<Expense>>? _transactionsSub;
  bool _shouldOpenInsights = false;
  bool _didOpenInsights = false;
  bool _tourMode = false;
  late final VoidCallback _userListener;
  late final VoidCallback _dashboardListener;
  final Set<String> _dueDateBackfillDone = {};

  // Draft filters (UI edits)
  DateTime? _draftDueFrom;
  DateTime? _draftDueTo;
  Set<ExpenseCategory> _draftCategoryFilters = {};
  _PaidFilter _draftPaidFilter = _PaidFilter.all;

  // Applied filters (used in the list)
  DateTime? _dueFrom;
  DateTime? _dueTo;
  Set<ExpenseCategory> _categoryFilters = {};
  _PaidFilter _paidFilter = _PaidFilter.all;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _userListener = () {
      if (mounted) _load();
    };
    LocalStorageService.userNotifier.addListener(_userListener);
    _dashboardListener = () {
      if (mounted) _load();
    };
    LocalStorageService.dashboardNotifier.addListener(_dashboardListener);
    _load();
    _resetFiltersToDefault(apply: true);
    _listenTransactions();
    _loadPrevExpenses();
    final user = LocalStorageService.getUserProfile();
    if (user != null && user.isPremium) {
      LocalStorageService.markReportViewed();
    }
  }

  @override
  void dispose() {
    LocalStorageService.userNotifier.removeListener(_userListener);
    LocalStorageService.dashboardNotifier.removeListener(_dashboardListener);
    _transactionsSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final enableTour = args is Map &&
        args['premiumTour'] == true &&
        args['tourStep'] == 'reports';
    if (enableTour && !_tourMode) {
      setState(() => _tourMode = true);
    }
    if (_didOpenInsights) return;
    if (args is Map && args['openSuggestions'] == true) {
      _shouldOpenInsights = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_shouldOpenInsights) return;
        _openInsights();
        _didOpenInsights = true;
        _shouldOpenInsights = false;
      });
    }
  }

  void _load() {
    _dashboard = LocalStorageService.getDashboard(
        _currentMonth.month, _currentMonth.year);
    _listenTransactions();
    _loadPrevExpenses();
    setState(() {});
  }

  DateTime get _monthStart =>
      DateTime(_currentMonth.year, _currentMonth.month, 1);

  DateTime get _monthEnd =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

  void _applyDraftFilters() {
    _dueFrom = _draftDueFrom;
    _dueTo = _draftDueTo;
    _categoryFilters = {..._draftCategoryFilters};
    _paidFilter = _draftPaidFilter;
    _listenTransactions();
  }

  void _resetFiltersToDefault({required bool apply}) {
    _draftDueFrom = _monthStart;
    _draftDueTo = _monthEnd;
    _draftCategoryFilters = {};
    _draftPaidFilter = _PaidFilter.all;
    if (apply) _applyDraftFilters();
  }

  void _listenTransactions() {
    _transactionsSub?.cancel();
    final uid = LocalStorageService.currentUserId;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _currentExpenses = const []);
      return;
    }

    final monthYear =
        '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    if (!_dueDateBackfillDone.contains(monthYear)) {
      _dueDateBackfillDone.add(monthYear);
      FirestoreService.backfillDueDatesForMonth(uid, monthYear)
          .catchError((_) {});
    }
    final keys = _categoryFilters
        .map((c) => toCategoryKey(c.name))
        .whereType<String>()
        .toList();

    DateTime? endOfDay(DateTime? value) {
      if (value == null) return null;
      return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
    }

    _transactionsSub = FirestoreService.watchTransactions(
      uid,
      monthYear,
      dueDateFrom: _dueFrom,
      dueDateTo: endOfDay(_dueTo),
      categoryKeys: keys,
    ).listen((items) {
      final deduped = _dedupeExpenses(items);
      if (!mounted) return;
      setState(() => _currentExpenses = deduped);
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

  MonthlyDashboard? _currentView() {
    final base = _dashboard;
    final salaryFallback =
        LocalStorageService.incomeTotalForMonth(_currentMonth);
    final profileIncome =
        LocalStorageService.getUserProfile()?.monthlyIncome ?? 0;
    final resolvedFallback =
        salaryFallback > 0 ? salaryFallback : profileIncome;
    if (base == null && resolvedFallback <= 0 && _currentExpenses.isEmpty)
      return null;

    final baseSalary = base?.salary ?? 0;
    final salary = baseSalary > 0 ? baseSalary : resolvedFallback;
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

  void _changeMonth(int delta) {
    final user = LocalStorageService.getUserProfile();
    final plan = UserPlan.fromProfile(user);

    if (delta != 0 && plan.isFree) {
      showPremiumDialog(context);
      return;
    }

    final next = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    if (!_isWithinWindow(next)) return;
    _currentMonth = next;
    _resetFiltersToDefault(apply: true);
    _load();
  }

  bool _isWithinWindow(DateTime month) {
    final now = DateTime.now();
    final user = LocalStorageService.getUserProfile();
    final createdAt = user?.createdAt ?? now;

    final start = DateTime(createdAt.year, createdAt.month, 1);
    final end = DateTime(now.year, now.month, 1);
    return !(month.isBefore(start) || month.isAfter(end));
  }

  Future<void> _openInsights() async {
    if (!mounted) return;
    await Navigator.pushNamed(context, AppRoutes.insights);
  }

  Future<void> _logout() async {
    await LocalStorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
  }

  Widget _logoutButton() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: IconButton(
          onPressed: _logout,
          tooltip: 'Sair da conta',
          icon: Icon(Icons.logout, color: AppTheme.textPrimary(context)),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _resetFilters() {
    setState(() {
      _resetFiltersToDefault(apply: true);
    });
  }

  DateTime _dueDateFor(Expense e) {
    final isDueBased =
        (e.type == ExpenseType.fixed || e.isCreditCard) && e.dueDay != null;
    if (isDueBased) {
      return DateTime(_currentMonth.year, _currentMonth.month, e.dueDay!);
    }
    return DateTime(e.date.year, e.date.month, e.date.day);
  }

  String _fmtShortDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _draftDueFrom : _draftDueTo) ?? _monthStart;
    final first = _monthStart;
    final last = _monthEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? 'Vencimento (de)' : 'Vencimento (até)',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _draftDueFrom = DateTime(picked.year, picked.month, picked.day);
        if (_draftDueTo != null && _draftDueFrom!.isAfter(_draftDueTo!)) {
          _draftDueTo = _draftDueFrom;
        }
      } else {
        _draftDueTo = DateTime(picked.year, picked.month, picked.day);
        if (_draftDueFrom != null && _draftDueTo!.isBefore(_draftDueFrom!)) {
          _draftDueFrom = _draftDueTo;
        }
      }
    });
  }

  Future<void> _saveDashboard() async {
    if (_dashboard == null) return;
    final ok = await LocalStorageService.saveDashboard(_dashboard!);
    if (!ok && mounted) {
      _snack(
        'Tivemos um problema ao sincronizar, mas seus dados estão salvos localmente.',
      );
    }
    setState(() {});
  }

  Future<void> _adjustMonthlyIncome() async {
    if (_dashboard == null) return;

    final controller = TextEditingController();
    var isAdd = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Ajustar saldo do mês'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [MoneyTextInputFormatter()],
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setInner) => Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Adicionar'),
                      selected: isAdd,
                      onSelected: (_) => setInner(() => isAdd = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Remover'),
                      selected: !isAdd,
                      onSelected: (_) => setInner(() => isAdd = false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final delta = parseMoneyInput(controller.text);
    if (delta <= 0) return;

    final newSalary = _dashboard!.salary + (isAdd ? delta : -delta);
    _dashboard = MonthlyDashboard(
      month: _dashboard!.month,
      year: _dashboard!.year,
      salary: newSalary < 0 ? 0 : newSalary,
      expenses: List.of(_dashboard!.expenses),
      creditCardPayments: _dashboard!.creditCardPayments,
    );
    _saveDashboard();
  }

  Future<void> _editExpense(Expense expense) async {
    if (_dashboard == null) return;

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

    final cards = LocalStorageService.getUserProfile()?.creditCards ?? const [];
    String? creditCardId = expense.creditCardId;
    if (isCard && cards.isNotEmpty) {
      if (creditCardId == null || creditCardId!.isEmpty) {
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
        title: const Text('Editar lançamento'),
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
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
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
                        child: Text('Gasto variavel'),
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
                      activeColor: Theme.of(context).colorScheme.primary,
                      activeTrackColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.35),
                      inactiveThumbColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55),
                      inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.20),
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
                          } else if (!isCard) {
                            creditCardId = null;
                            cardDueDay = null;
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Categoria: Investimento',
                          style:
                              TextStyle(color: AppTheme.textSecondary(context)),
                        ),
                      ),
                    ),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                  ),
                  if (!isInvestment) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: cards.isEmpty ? null : creditCardId,
                      decoration:
                          const InputDecoration(labelText: 'Cartão de crédito'),
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
                  ],
                  if (!isInvestment && type == ExpenseType.fixed) ...[
                    const SizedBox(height: 12),
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
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
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

    final resolvedCategory =
        type == ExpenseType.investment ? ExpenseCategory.investment : category;
    final mustBePaid = type != ExpenseType.fixed || isCard;
    final effectiveDueDay =
        isCard ? cardDueDay : (type == ExpenseType.fixed ? billDueDay : null);

    final updated = expense.copyWith(
      name: name,
      amount: amount,
      type: type,
      category: resolvedCategory,
      dueDay: effectiveDueDay,
      isCreditCard: isCard,
      creditCardId: isCard ? creditCardId : null,
      isPaid: mustBePaid ? true : expense.isPaid,
    );

    final okSave = await LocalStorageService.saveExpense(updated);
    if (!okSave) {
      _snack('Não foi possível atualizar o lançamento agora.');
    }
  }

  Future<void> _removeExpense(Expense expense) async {
    if (_dashboard == null) return;

    final isInstallment = (expense.installments ?? 0) > 1;
    if (expense.isFixed && !isInstallment) {
      final scope = await showDialog<String>(
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

      if (scope == null) return;
      final okFixed = scope == 'month'
          ? await LocalStorageService.deleteFixedExpenseOnlyThisMonth(
              expense: expense,
              month: _currentMonth,
            )
          : await LocalStorageService.deleteFixedExpenseFromThisMonthForward(
              expense: expense,
              fromMonth: _currentMonth,
            );

      if (!okFixed) {
        _snack('Não foi possível remover a conta fixa agora.');
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Remover lançamento?'),
        content: Text('Remover "${expense.name}" deste mês?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final okDelete = await LocalStorageService.deleteExpense(expense.id);
    if (!okDelete) {
      _snack('Não foi possível remover o lançamento agora.');
    }
  }

  List<Expense> get _fixedExpenses =>
      _currentExpenses.where((e) => e.type == ExpenseType.fixed).toList();

  List<Expense> get _variableExpenses =>
      _currentExpenses.where((e) => e.type == ExpenseType.variable).toList();

  List<Expense> get _investmentExpenses =>
      _currentExpenses.where((e) => e.type == ExpenseType.investment).toList();

  List<Expense> get _filteredExpenses {
    final paid = _paidFilter == _PaidFilter.all
        ? null
        : (_paidFilter == _PaidFilter.paid ? true : false);

    final list = filterExpenses(
      _currentExpenses,
      dueFrom: _dueFrom,
      dueTo: _dueTo,
      categories: _categoryFilters,
      isPaid: paid,
      dueDateFor: _dueDateFor,
    );

    list.sort((a, b) => _dueDateFor(a).compareTo(_dueDateFor(b)));
    return list;
  }

  List<Expense> get _filteredFixedExpenses =>
      _filteredExpenses.where((e) => e.type == ExpenseType.fixed).toList();

  List<Expense> get _filteredVariableExpenses =>
      _filteredExpenses.where((e) => e.type == ExpenseType.variable).toList();

  List<Expense> get _filteredInvestmentExpenses =>
      _filteredExpenses.where((e) => e.type == ExpenseType.investment).toList();

  double get _fixedTotal => _fixedExpenses.fold(0, (a, b) => a + b.amount);
  double get _variableTotal =>
      _variableExpenses.fold(0, (a, b) => a + b.amount);
  double get _investmentTotal =>
      _investmentExpenses.fold(0, (a, b) => a + b.amount);
  double get _total => _fixedTotal + _variableTotal + _investmentTotal;
  double get _remaining => (_currentView()?.salary ?? 0) - _total;

  Widget _filtersCard() {
    String statusLabel(_PaidFilter f) {
      switch (f) {
        case _PaidFilter.all:
          return 'Todos';
        case _PaidFilter.pending:
          return 'A pagar';
        case _PaidFilter.paid:
          return 'Pago';
      }
    }

    String categoriesLabel(Set<ExpenseCategory> cats) {
      if (cats.isEmpty) return 'Categorias: todas';
      if (cats.length == 1) return 'Categorias: 1';
      return 'Categorias: ${cats.length}';
    }

    Widget pill(String text, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceVariant
              .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.textMuted(context)),
              const SizedBox(width: 6),
            ],
            Text(
              text,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtros',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openFiltersSheet,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Editar'),
              ),
              IconButton(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_rounded),
                tooltip: 'Limpar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              pill(
                'Período: ${_fmtShortDate(_dueFrom)} – ${_fmtShortDate(_dueTo)}',
                icon: Icons.calendar_month_outlined,
              ),
              pill(
                'Status: ${statusLabel(_paidFilter)}',
                icon: Icons.task_alt_rounded,
              ),
              pill(
                categoriesLabel(_categoryFilters),
                icon: Icons.sell_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Itens',
                        style: TextStyle(color: AppTheme.textMuted(context)),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_filteredExpenses.length}',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(color: AppTheme.textMuted(context)),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            SensitiveDisplay.money(
                              context,
                              _filteredExpenses.fold(
                                0.0,
                                (sum, e) => sum + e.amount,
                              ),
                            ),
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openFiltersSheet() async {
    String labelFor(ExpenseCategory c) {
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        DateTime? localFrom = _draftDueFrom;
        DateTime? localTo = _draftDueTo;
        Set<ExpenseCategory> localCats = {..._draftCategoryFilters};
        _PaidFilter localPaid = _draftPaidFilter;

        Future<void> pickRange(StateSetter setSheetState) async {
          final start = localFrom ?? _monthStart;
          final end = localTo ?? _monthEnd;
          final initial = DateTimeRange(start: start, end: end);

          final range = await showDateRangePicker(
            context: context,
            firstDate: _monthStart,
            lastDate: _monthEnd,
            initialDateRange: initial,
            helpText: 'Vencimento',
          );
          if (range == null) return;
          setSheetState(() {
            localFrom =
                DateTime(range.start.year, range.start.month, range.start.day);
            localTo = DateTime(range.end.year, range.end.month, range.end.day);
          });
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final periodText =
                '${_fmtShortDate(localFrom)} – ${_fmtShortDate(localTo)}';

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtros de lançamentos',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Período (vencimento)'),
                      subtitle: Text(periodText),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => pickRange(setSheetState),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<_PaidFilter>(
                      segments: const [
                        ButtonSegment(
                          value: _PaidFilter.all,
                          label: Text('Todos'),
                        ),
                        ButtonSegment(
                          value: _PaidFilter.pending,
                          label: Text('A pagar'),
                        ),
                        ButtonSegment(
                          value: _PaidFilter.paid,
                          label: Text('Pago'),
                        ),
                      ],
                      selected: {localPaid},
                      onSelectionChanged: (s) =>
                          setSheetState(() => localPaid = s.first),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Categorias',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Todas'),
                          selected: localCats.isEmpty,
                          onSelected: (_) =>
                              setSheetState(() => localCats = {}),
                        ),
                        ...ExpenseCategory.values.map((c) {
                          final selected = localCats.contains(c);
                          return FilterChip(
                            label: Text(labelFor(c)),
                            selected: selected,
                            onSelected: (v) {
                              setSheetState(() {
                                final next = {...localCats};
                                if (v) {
                                  next.add(c);
                                } else {
                                  next.remove(c);
                                }
                                localCats = next;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => setSheetState(() {
                            localFrom = _monthStart;
                            localTo = _monthEnd;
                            localCats = {};
                            localPaid = _PaidFilter.all;
                          }),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Limpar'),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _draftDueFrom = localFrom ?? _monthStart;
                              _draftDueTo = localTo ?? _monthEnd;
                              _draftCategoryFilters = {...localCats};
                              _draftPaidFilter = localPaid;
                              _applyDraftFilters();
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Aplicar'),
                        ),
                      ],
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

  double _housingTotalFrom(MonthlyDashboard dashboard) {
    return dashboard.expenses
        .where((e) => e.category == ExpenseCategory.moradia && !e.isInvestment)
        .fold(0, (a, b) => a + b.amount);
  }

  double _percentOf(MonthlyDashboard? dashboard, double value) {
    if (dashboard == null || dashboard.salary <= 0) return 0;
    return (value / dashboard.salary) * 100;
  }

  double _idealAmount(MonthlyDashboard dashboard, double percent) {
    if (dashboard.salary <= 0) return 0;
    return dashboard.salary * (percent / 100);
  }

  MonthlyDashboard? _previousMonthDashboard() {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final base = LocalStorageService.getDashboard(prev.month, prev.year);
    final salaryFallback = LocalStorageService.incomeTotalForMonth(prev);
    final profileIncome =
        LocalStorageService.getUserProfile()?.monthlyIncome ?? 0;
    final resolvedFallback =
        salaryFallback > 0 ? salaryFallback : profileIncome;
    if (base == null && resolvedFallback <= 0 && _prevExpenses.isEmpty)
      return null;

    final baseSalary = base?.salary ?? 0;
    final salary = baseSalary > 0 ? baseSalary : resolvedFallback;
    return MonthlyDashboard(
      month: prev.month,
      year: prev.year,
      salary: salary,
      expenses: _prevExpenses,
      creditCardPayments: base?.creditCardPayments ?? const {},
    );
  }

  int _investmentGrowthStreak() {
    return 0;
  }

  List<_TimelineEvent> _timelineItems() {
    if (_currentView() == null) return [];
    final items = <_TimelineEvent>[];

    final prev = _previousMonthDashboard();
    if (prev != null) {
      if (prev.variableExpensesTotal > 0) {
        final change = ((_variableTotal - prev.variableExpensesTotal) /
                prev.variableExpensesTotal) *
            100;
        if (change.abs() >= 10) {
          final direction = change > 0 ? 'a mais' : 'a menos';
          items.add(
            _TimelineEvent(
              title: 'Gastos variáveis',
              detail:
                  '${change.abs().toStringAsFixed(0)}% $direction vs mês passado.',
              icon: change > 0 ? Icons.trending_up : Icons.trending_down,
              color: AppColors.variableExpense,
            ),
          );
        }
      }

      if (prev.fixedExpensesTotal > 0) {
        final change = ((_fixedTotal - prev.fixedExpensesTotal) /
                prev.fixedExpensesTotal) *
            100;
        if (change.abs() >= 10) {
          final direction = change > 0 ? 'a mais' : 'a menos';
          items.add(
            _TimelineEvent(
              title: 'Gastos fixos',
              detail:
                  '${change.abs().toStringAsFixed(0)}% $direction vs mês passado.',
              icon: change > 0 ? Icons.trending_up : Icons.trending_down,
              color: AppColors.fixedExpense,
            ),
          );
        }
      }

      if (prev.investmentsTotal > 0) {
        final change = ((_investmentTotal - prev.investmentsTotal) /
                prev.investmentsTotal) *
            100;
        if (change.abs() >= 10) {
          final direction = change > 0 ? 'a mais' : 'a menos';
          items.add(
            _TimelineEvent(
              title: 'Investimentos',
              detail:
                  '${change.abs().toStringAsFixed(0)}% $direction vs mês passado.',
              icon: change > 0 ? Icons.trending_up : Icons.trending_down,
              color: AppColors.investment,
            ),
          );
        }
      }
    }

    final streak = _investmentGrowthStreak();
    if (streak >= 2) {
      items.add(
        _TimelineEvent(
          title: 'Sequencia positiva',
          detail: 'Investimentos cresceram por $streak meses seguidos.',
          icon: Icons.local_fire_department,
          color: AppColors.investment,
        ),
      );
    }

    if (_variableTotal > _fixedTotal) {
      items.add(
        _TimelineEvent(
          title: 'Alerta de equilibrio',
          detail: 'Variaveis superaram fixos. Revise gastos flexiveis.',
          icon: Icons.report_problem_outlined,
          color: AppColors.warning,
        ),
      );
    } else {
      items.add(
        _TimelineEvent(
          title: 'Controle em dia',
          detail: 'Fixos estão controlados em relação aos gastos variáveis.',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        _TimelineEvent(
          title: 'Mes equilibrado',
          detail: 'Nenhuma variacao relevante detectada.',
          icon: Icons.auto_awesome,
          color: AppColors.success,
        ),
      );
    }

    return items;
  }

  Widget _idealComparisonCard() {
    final current = _currentView();
    if (current == null) return const SizedBox.shrink();
    final prev = _previousMonthDashboard();
    final housingTotal = _housingTotalFrom(current);
    final prevHousing = prev != null ? _housingTotalFrom(prev).toDouble() : 0.0;

    Widget row({
      required String label,
      required double actual,
      required double ideal,
      required double previous,
      required Color color,
      required double actualPct,
      required double idealPct,
      required double prevPct,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _comparisonValue('Agora', actual, actualPct),
                _comparisonValue('Ideal', ideal, idealPct),
                _comparisonValue('Mês anterior', previous, prevPct),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparativo ideal x real',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          row(
            label: 'Fixos',
            actual: _fixedTotal,
            ideal: _idealAmount(current, 50),
            previous: (prev?.fixedExpensesTotal ?? 0).toDouble(),
            color: AppColors.fixedExpense,
            actualPct: _percentOf(current, _fixedTotal),
            idealPct: 50,
            prevPct: _percentOf(prev, prev?.fixedExpensesTotal ?? 0),
          ),
          row(
            label: 'Variáveis',
            actual: _variableTotal,
            ideal: _idealAmount(current, 30),
            previous: (prev?.variableExpensesTotal ?? 0).toDouble(),
            color: AppColors.variableExpense,
            actualPct: _percentOf(current, _variableTotal),
            idealPct: 30,
            prevPct: _percentOf(prev, prev?.variableExpensesTotal ?? 0),
          ),
          row(
            label: 'Investimentos',
            actual: _investmentTotal,
            ideal: _idealAmount(current, 20),
            previous: (prev?.investmentsTotal ?? 0).toDouble(),
            color: AppColors.investment,
            actualPct: _percentOf(current, _investmentTotal),
            idealPct: 20,
            prevPct: _percentOf(prev, prev?.investmentsTotal ?? 0),
          ),
          row(
            label: 'Moradia',
            actual: housingTotal,
            ideal: _idealAmount(current, 35),
            previous: prevHousing,
            color: AppColors.fixedExpense,
            actualPct: _percentOf(current, housingTotal),
            idealPct: 35,
            prevPct: _percentOf(prev, prevHousing),
          ),
        ],
      ),
    );
  }

  Widget _comparisonValue(String label, double value, double pct) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            SensitiveDisplay.money(context, value),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _timelineCard(_TimelineEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(event.icon, color: event.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.detail,
                  style: TextStyle(
                      color: AppTheme.textSecondary(context), height: 1.3),
                ),
              ],
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
        body: Center(
          child: Text(
            'Faça login para acessar relatórios.',
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      );
    }

    if (!user.isPremium) {
      return Scaffold(
        appBar: AppBar(title: Text('Relatório mensal')),
        body: const PremiumGate(
          title: 'Relatórios inteligentes são Premium',
          subtitle:
              'Veja linha do tempo, evolução mensal e insights detalhados.',
          perks: [
            'Linha do tempo do seu dinheiro',
            'Score da saúde financeira',
            'Insights personalizados do mês',
          ],
        ),
      );
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = DateUtilsJetx.monthYear(_currentMonth, locale: locale);

    final view = _currentView();

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório mensal'),
        actions: [
          const MoneyVisibilityButton(),
          IconButton(
            onPressed: _openInsights,
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Insights',
          ),
          IconButton(
            onPressed: _isWithinWindow(
              DateTime(_currentMonth.year, _currentMonth.month - 1, 1),
            )
                ? () => _changeMonth(-1)
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mês anterior',
          ),
          Center(
            child: Text(
              title,
              style: TextStyle(
                  color: AppTheme.textSecondary(context), fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: _isWithinWindow(
              DateTime(_currentMonth.year, _currentMonth.month + 1, 1),
            )
                ? () => _changeMonth(1)
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo mês',
          ),
        ],
      ),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: view == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nenhum dado encontrado para este mês.',
                      style: TextStyle(color: AppTheme.textMuted(context)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _logoutButton(),
                  ],
                ),
              )
            : PremiumTourOverlay(
                active: _tourMode,
                spotlight: PremiumTourSpotlight(
                  icon: Icons.bar_chart_rounded,
                  title: AppStrings.t(context, 'premium_tour_reports_title'),
                  body: AppStrings.t(context, 'premium_tour_reports_body'),
                  location:
                      AppStrings.t(context, 'premium_tour_reports_location'),
                  tip: AppStrings.t(context, 'premium_tour_reports_tip'),
                ),
                child: ListView(
                  children: [
                    Text(
                      'Gastos do mês',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PremiumTourHighlight(
                      active: _tourMode,
                      child: Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              title: 'Fixos',
                              value:
                                  SensitiveDisplay.money(context, _fixedTotal),
                              color: AppColors.fixedExpense,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryCard(
                              title: 'Variáveis',
                              value: SensitiveDisplay.money(
                                  context, _variableTotal),
                              color: AppColors.variableExpense,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _summaryCard(
                      title: 'Total de gastos',
                      value: SensitiveDisplay.money(context, _total),
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    _summaryCard(
                      title: 'Investimentos',
                      value: SensitiveDisplay.money(context, _investmentTotal),
                      color: AppColors.investment,
                    ),
                    const SizedBox(height: 10),
                    _summaryCard(
                      title: 'Saldo do mês',
                      value: SensitiveDisplay.money(context, _remaining),
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    _filtersCard(),
                    const SizedBox(height: 10),
                    Text(
                      'Lançamentos (filtros)',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _section(
                      title: 'Gastos fixos',
                      color: AppColors.fixedExpense,
                      items: _filteredFixedExpenses,
                    ),
                    const SizedBox(height: 14),
                    _section(
                      title: 'Gastos variáveis',
                      color: AppColors.variableExpense,
                      items: _filteredVariableExpenses,
                    ),
                    const SizedBox(height: 14),
                    _section(
                      title: 'Investimentos',
                      color: AppColors.investment,
                      items: _filteredInvestmentExpenses,
                    ),
                    const SizedBox(height: 12),
                    _creditCardBillsCard(view),
                    const SizedBox(height: 16),
                    _idealComparisonCard(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _adjustMonthlyIncome,
                        icon: const Icon(Icons.tune),
                        label: Text('Ajustar saldo do mês'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _barChart(),
                    const SizedBox(height: 18),
                    Text(
                      'Linha do tempo',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._timelineItems().map(_timelineCard),
                    const SizedBox(height: 20),
                    _logoutButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppTheme.textSecondary(context), fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _creditCardBillsCard(MonthlyDashboard d) {
    final cardExpenses = d.expenses.where((e) => e.isCreditCard).toList();
    if (cardExpenses.isEmpty) return const SizedBox.shrink();

    final cards = LocalStorageService.getUserProfile()?.creditCards ?? [];
    final nameById = {for (final c in cards) c.id: c.name};
    final dueById = {for (final c in cards) c.id: c.dueDay};

    final totals = <String, double>{};
    for (final e in cardExpenses) {
      final id = e.creditCardId ?? 'unknown';
      totals[id] = (totals[id] ?? 0) + e.amount;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'credit_card_bills_title'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...totals.entries.map(
            (entry) {
              final id = entry.key;
              final name =
                  nameById[id] ?? AppStrings.t(context, 'card_unknown');
              final dueDay = dueById[id];
              final paid = d.creditCardPayments[id] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style:
                                TextStyle(color: AppTheme.textPrimary(context)),
                          ),
                          if (dueDay != null)
                            Text(
                              AppStrings.tr(
                                context,
                                'card_due_day_label',
                                {'day': '$dueDay'},
                              ),
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (paid)
                      Text(
                        AppStrings.t(context, 'card_paid_badge'),
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      SensitiveDisplay.money(context, entry.value),
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _barChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: SizedBox(
        height: 170,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final label = value == 0
                        ? 'Fixos'
                        : value == 1
                            ? 'Variaveis'
                            : 'Invest.';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(label,
                          style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 12)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: _fixedTotal <= 0 ? 0.5 : _fixedTotal,
                    color: AppColors.fixedExpense,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: _variableTotal <= 0 ? 0.5 : _variableTotal,
                    color: AppColors.variableExpense,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(
                    toY: _investmentTotal <= 0 ? 0.5 : _investmentTotal,
                    color: AppColors.investment,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Color color,
    required List<Expense> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text('Nenhum lançamento.',
                style: TextStyle(color: AppTheme.textMuted(context)))
          else
            ...items.map((e) => _itemTile(e)),
        ],
      ),
    );
  }

  Widget _itemTile(Expense e) {
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

    final dueDate = _dueDateFor(e);
    final dueText = _fmtShortDate(dueDate);
    final dueSuffix =
        (e.type == ExpenseType.fixed || e.isCreditCard) && e.dueDay != null
            ? e.isCreditCard
                ? ' ? fatura dia ${e.dueDay}'
                : ' ? vence dia ${e.dueDay}'
            : '';
    final canTogglePaid = e.type == ExpenseType.fixed && !e.isCreditCard;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.name}$dueSuffix',
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${categoryLabel(e.category)} ? venc: $dueText',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            SensitiveDisplay.money(context, e.amount),
            style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          if (canTogglePaid)
            IconButton(
              onPressed: () => _togglePaid(e),
              icon: Icon(
                e.isPaid ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color:
                    e.isPaid ? AppTheme.success : AppTheme.textMuted(context),
              ),
              tooltip: e.isPaid ? 'Pago' : 'Marcar como pago',
            ),
          IconButton(
            onPressed: () => _editExpense(e),
            icon: Icon(Icons.edit,
                size: 18, color: AppTheme.textSecondary(context)),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: () => _removeExpense(e),
            icon: Icon(Icons.delete_outline,
                size: 18, color: AppTheme.textMuted(context)),
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }

  Future<void> _togglePaid(Expense e) async {
    final updated = e.copyWith(isPaid: !e.isPaid);
    final okSave = await LocalStorageService.saveExpense(updated);
    if (!okSave) {
      _snack('Não foi possível atualizar o pagamento agora.');
    }
  }
}

class _TimelineEvent {
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _TimelineEvent({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

enum _PaidFilter { all, pending, paid }
