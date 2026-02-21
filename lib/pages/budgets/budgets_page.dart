import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_strings.dart';
import '../../core/plans/user_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/budget_v2.dart';
import '../../models/expense.dart';
import '../../services/advanced_modules_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/money_input.dart';
import '../../widgets/premium_gate.dart';
import '_suggest_budgets_dialog.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  static const List<String> _categoryKeys = [
    'MORADIA',
    'ALIMENTACAO',
    'TRANSPORTE',
    'EDUCACAO',
    'SAUDE',
    'LAZER',
    'ASSINATURAS',
    'OUTROS',
  ];

  static const Set<String> _essentialCategoryKeys = {
    'MORADIA',
    'ALIMENTACAO',
    'TRANSPORTE',
    'EDUCACAO',
    'SAUDE',
    'ASSINATURAS',
  };

  double _savingsPct = 0.10;
  bool _suggesting = false;
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _clampToMonthRange(
      DateTime d, DateTime minMonth, DateTime maxMonth) {
    final md = _monthOnly(d);
    if (md.isBefore(minMonth)) return minMonth;
    if (md.isAfter(maxMonth)) return maxMonth;
    return md;
  }

  DateTime _monthStart(String monthYear) {
    final parts = monthYear.split('-');
    if (parts.length != 2) return DateTime.now();
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateTime(y, m, 1);
  }

  List<String> _monthKeysFrom(String startMonthYear, {int maxMonths = 12}) {
    final start = _monthStart(startMonthYear);
    final out = <String>[];
    for (var i = 0; i < maxMonths; i++) {
      final d = DateTime(start.year, start.month + i, 1);
      out.add(_monthKey(d));
    }
    return out;
  }

  Map<String, double> _extractSuggestions(Object? payload) {
    final out = <String, double>{};
    if (payload is Map<String, dynamic>) {
      final raw = payload['suggestions'] ??
          payload['data'] ??
          payload['result'] ??
          payload;

      if (raw is List) {
        for (final row in raw) {
          if (row is! Map) continue;
          final key =
              (row['categoryKey'] ?? row['category'])?.toString().trim();
          final val =
              (row['suggestedAmount'] ?? row['amount'] ?? row['limitAmount']);
          final numVal =
              (val is num) ? val.toDouble() : double.tryParse('$val');
          if (key == null || key.isEmpty) continue;
          if (numVal == null || !numVal.isFinite || numVal <= 0) continue;
          out[key] = numVal;
        }
        return out;
      }

      if (raw is Map) {
        for (final entry in raw.entries) {
          final key = entry.key?.toString().trim();
          final val = entry.value;
          final numVal =
              (val is num) ? val.toDouble() : double.tryParse('$val');
          if (key == null || key.isEmpty) continue;
          if (numVal == null || !numVal.isFinite || numVal <= 0) continue;
          out[key] = numVal;
        }
        return out;
      }
    }
    return out;
  }

  Map<String, double> _buildLocalSuggestions({
    required double monthlyIncome,
    double savingsPct = 0.10,
  }) {
    final usable = monthlyIncome > 0
        ? monthlyIncome * (1 - savingsPct.clamp(0.0, 0.5))
        : 0.0;

    const weights = <String, double>{
      'MORADIA': 0.32,
      'ALIMENTACAO': 0.16,
      'TRANSPORTE': 0.10,
      'EDUCACAO': 0.06,
      'SAUDE': 0.06,
      'LAZER': 0.06,
      'ASSINATURAS': 0.04,
      'OUTROS': 0.20,
    };

    final out = <String, double>{};
    if (usable <= 0) return out;
    for (final k in _categoryKeys) {
      final w = weights[k] ?? 0.0;
      if (w <= 0) continue;
      out[k] = double.parse((usable * w).toStringAsFixed(2));
    }
    return out;
  }

  String _categoryKeyFromExpense(Expense e) {
    switch (e.category) {
      case ExpenseCategory.moradia:
        return 'MORADIA';
      case ExpenseCategory.alimentacao:
        return 'ALIMENTACAO';
      case ExpenseCategory.transporte:
        return 'TRANSPORTE';
      case ExpenseCategory.educacao:
        return 'EDUCACAO';
      case ExpenseCategory.saude:
        return 'SAUDE';
      case ExpenseCategory.lazer:
        return 'LAZER';
      case ExpenseCategory.assinaturas:
        return 'ASSINATURAS';
      case ExpenseCategory.dividas:
        return 'DIVIDAS';
      case ExpenseCategory.outros:
        return 'OUTROS';
      case ExpenseCategory.investment:
        return 'INVESTIMENTO';
    }
  }

  Future<void> _editLimit(BudgetV2 b) async {
    final controller = TextEditingController(
      text: formatMoneyInput(b.limitAmount),
    );
    var essential = b.essential;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.tr(context, 'budget_edit_title',
            {'category': _categoryLabel(context, b.categoryKey)})),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [MoneyTextInputFormatter()],
                decoration: InputDecoration(
                    labelText: AppStrings.t(context, 'budget_limit_label')),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.t(context, 'budget_essential_title')),
                subtitle:
                    Text(AppStrings.t(context, 'budget_essential_subtitle')),
                value: essential,
                onChanged: (v) => setDialogState(() => essential = v),
              ),
            ],
          ),
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
    final uid = LocalStorageService.currentUserId;
    if (uid == null) return;
    final limit = parseMoneyInput(controller.text);
    await FirestoreService.saveBudgetLimit(
      uid: uid,
      monthYear: b.referenceMonth,
      categoryKey: b.categoryKey,
      limitAmount: limit,
      essential: essential,
    );
  }

  Future<void> _suggest(String monthYear) async {
    try {
      await AdvancedModulesService.suggestBudgets(
        monthYear: monthYear,
        savingsPct: _savingsPct,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppStrings.t(context, 'budget_suggestions_updated'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppStrings.t(context, 'budget_suggestions_failed'))),
        );
      }
    }
  }

  Future<void> _suggestFlow(String monthYear) async {
    final uid = LocalStorageService.currentUserId;
    if (uid == null || _suggesting) return;

    setState(() => _suggesting = true);
    String? error;
    Map<String, double> suggestions = {};
    String source = 'server';
    try {
      final res = await AdvancedModulesService.suggestBudgets(
        monthYear: monthYear,
        savingsPct: _savingsPct,
      );
      suggestions = _extractSuggestions(res);
      if (suggestions.isEmpty) source = 'local';
    } catch (e) {
      error = e.toString();
      source = 'local';
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }

    if (!mounted) return;

    if (suggestions.isEmpty) {
      final user = LocalStorageService.getUserProfile();
      final incomes = LocalStorageService.getIncomes();
      final incomeTotal = incomes.fold<double>(0.0, (acc, inc) {
        if (inc.isActive == false) return acc;
        if (inc.excludedMonths.contains(monthYear)) return acc;
        if (inc.activeFrom != null &&
            RegExp(r'^\d{4}-\d{2}$').hasMatch(inc.activeFrom!) &&
            monthYear.compareTo(inc.activeFrom!) < 0) {
          return acc;
        }
        if (inc.activeUntil != null &&
            RegExp(r'^\d{4}-\d{2}$').hasMatch(inc.activeUntil!) &&
            monthYear.compareTo(inc.activeUntil!) > 0) {
          return acc;
        }
        return acc + (inc.amount.isFinite ? inc.amount : 0.0);
      });
      suggestions = _buildLocalSuggestions(
        monthlyIncome:
            incomeTotal > 0 ? incomeTotal : (user?.monthlyIncome ?? 0),
        savingsPct: _savingsPct,
      );
    }

    await showDialog<void>(
      context: context,
      builder: (_) => SuggestBudgetsDialog(
        uid: uid,
        monthYear: monthYear,
        suggestions: suggestions,
        source: source,
        error: error,
        applyBudget: (categoryKey, value, replicateFuture) async {
          final months =
              replicateFuture ? _monthKeysFrom(monthYear) : <String>[monthYear];
          for (final m in months) {
            await FirestoreService.saveBudgetLimit(
              uid: uid,
              monthYear: m,
              categoryKey: categoryKey,
              limitAmount: value,
            );
          }

          await FirestoreService.logBudgetSuggestionRun(
            uid: uid,
            monthYear: monthYear,
            categoryKey: categoryKey,
            suggestedAmount: value,
            replicateFuture: replicateFuture,
          );
        },
      ),
    );
  }

  String _categoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'MORADIA':
        return AppStrings.t(context, 'expense_category_housing');
      case 'ALIMENTACAO':
        return AppStrings.t(context, 'expense_category_food');
      case 'TRANSPORTE':
        return AppStrings.t(context, 'expense_category_transport');
      case 'EDUCACAO':
        return AppStrings.t(context, 'expense_category_education');
      case 'SAUDE':
        return AppStrings.t(context, 'expense_category_health');
      case 'LAZER':
        return AppStrings.t(context, 'expense_category_leisure');
      case 'ASSINATURAS':
        return AppStrings.t(context, 'expense_category_subscriptions');
      default:
        return AppStrings.t(context, 'expense_category_other');
    }
  }

  BudgetV2 _placeholderBudget({
    required String monthYear,
    required String categoryKey,
  }) {
    return BudgetV2(
      id: '${monthYear}_$categoryKey',
      referenceMonth: monthYear,
      categoryKey: categoryKey,
      limitAmount: 0,
      spentAmount: 0,
      suggestedAmount: null,
      notified80: false,
      notified100: false,
      essential: _essentialCategoryKeys.contains(categoryKey),
      createdAt: null,
      updatedAt: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = LocalStorageService.currentUserId;
    final user = LocalStorageService.getUserProfile();
    final isPremium = !UserPlan.isFeatureLocked(user, 'budgets');
    final creationDate = user?.createdAt ?? DateTime.now();
    final now = DateTime.now();
    final minMonth = DateTime(creationDate.year, creationDate.month, 1);
    final maxMonth = DateTime(now.year, now.month + 12, 1);

    final clampedMonth = _clampToMonthRange(_currentMonth, minMonth, maxMonth);
    if (clampedMonth != _currentMonth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _currentMonth = clampedMonth);
      });
    }

    final monthYear = _monthKey(clampedMonth);
    final isAtMinMonth = _monthOnly(clampedMonth) == _monthOnly(minMonth);
    final isAtMaxMonth = _monthOnly(clampedMonth) == _monthOnly(maxMonth);
    final monthLabel = DateFormat(
      'MMMM yyyy',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(clampedMonth);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'budgets'))),
      body: PremiumGate(
        isPremium: isPremium,
        title: AppStrings.t(context, 'budgets_smart_title'),
        subtitle: AppStrings.t(context, 'budgets_smart_subtitle'),
        perks: [
          AppStrings.t(context, 'budgets_smart_perk_1'),
          AppStrings.t(context, 'budgets_smart_perk_2'),
          AppStrings.t(context, 'budgets_smart_perk_3')
        ],
        child: uid == null
            ? Center(
                child: Text(
                  AppStrings.t(context, 'login_required_missions'),
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              )
            : Padding(
                padding: Responsive.pagePadding(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                onPressed: isAtMinMonth
                                    ? null
                                    : () => setState(() {
                                          _currentMonth = _clampToMonthRange(
                                            DateTime(clampedMonth.year,
                                                clampedMonth.month - 1, 1),
                                            minMonth,
                                            maxMonth,
                                          );
                                        }),
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                monthLabel,
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                onPressed: isAtMaxMonth
                                    ? null
                                    : () => setState(() {
                                          _currentMonth = _clampToMonthRange(
                                            DateTime(clampedMonth.year,
                                                clampedMonth.month + 1, 1),
                                            minMonth,
                                            maxMonth,
                                          );
                                        }),
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mês: $monthYear',
                            style: TextStyle(
                                color: AppTheme.textSecondary(context)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _suggesting
                              ? null
                              : () => _suggestFlow(monthYear),
                          icon:
                              const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: Text(_suggesting ? 'Gerando…' : 'Sugerir'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meta de poupança: ${(_savingsPct * 100).round()}%',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Usada só para calcular as sugestões (backend).',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                          Slider(
                            value: _savingsPct,
                            min: 0.0,
                            max: 0.4,
                            divisions: 40,
                            label: '${(_savingsPct * 100).round()}%',
                            onChanged: (v) => setState(() => _savingsPct = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<Expense>>(
                        stream: LocalStorageService.watchTransactions(
                            clampedMonth.month, clampedMonth.year),
                        builder: (context, txSnap) {
                          final txs = txSnap.data ?? const <Expense>[];
                          final spentByCategory = <String, double>{
                            for (final k in _categoryKeys) k: 0.0,
                          };

                          for (final tx in txs) {
                            if (tx.txType == 'INCOME' ||
                                tx.txType == 'DEBT_PAYMENT') {
                              continue;
                            }
                            if (tx.isInvestment || tx.txType == 'INVESTMENT') {
                              continue;
                            }
                            final key = _categoryKeyFromExpense(tx);
                            if (!spentByCategory.containsKey(key)) continue;
                            spentByCategory[key] =
                                (spentByCategory[key] ?? 0.0) + tx.amount;
                          }

                          return StreamBuilder<List<BudgetV2>>(
                            stream:
                                FirestoreService.watchBudgets(uid, monthYear),
                            builder: (context, snap) {
                              final byKey = <String, BudgetV2>{};
                              for (final b
                                  in (snap.data ?? const <BudgetV2>[])) {
                                byKey[b.categoryKey] = b;
                              }
                              final items = _categoryKeys
                                  .map((k) =>
                                      byKey[k] ??
                                      _placeholderBudget(
                                          monthYear: monthYear, categoryKey: k))
                                  .toList();
                              return ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final b = items[i];
                                  final limit = b.limitAmount;
                                  final spent =
                                      spentByCategory[b.categoryKey] ?? 0.0;
                                  final pct = limit <= 0
                                      ? 0.0
                                      : (spent / limit).clamp(0.0, 1.0);
                                  final color = pct >= 1
                                      ? Colors.redAccent
                                      : pct >= 0.8
                                          ? Colors.amber
                                          : Colors.green;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _editLimit(b),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border:
                                            Border.all(color: Colors.white10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _categoryLabel(
                                                      context, b.categoryKey),
                                                  style: TextStyle(
                                                    color: AppTheme.textPrimary(
                                                        context),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                CurrencyUtils.format(spent),
                                                style: TextStyle(
                                                  color: color,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: pct,
                                            minHeight: 8,
                                            backgroundColor:
                                                Colors.white.withOpacity(0.08),
                                            valueColor:
                                                AlwaysStoppedAnimation(color),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Limite: ${CurrencyUtils.format(limit)}'
                                            '${b.suggestedAmount != null ? ' • Sugestão: ${CurrencyUtils.format(b.suggestedAmount!)}' : ''}',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary(
                                                  context),
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (b.essential)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Text(
                                                'Essencial',
                                                style: TextStyle(
                                                  color: AppTheme.textMuted(
                                                      context),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
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
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
