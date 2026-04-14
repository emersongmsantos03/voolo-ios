import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/plans/user_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/budget_v2.dart';
import '../../models/expense.dart';
import '../../routes/app_routes.dart';
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
  static const _keys = [
    'MORADIA',
    'ALIMENTACAO',
    'TRANSPORTE',
    'EDUCACAO',
    'SAUDE',
    'LAZER',
    'ASSINATURAS',
    'OUTROS',
  ];
  static const _essential = {
    'MORADIA',
    'ALIMENTACAO',
    'TRANSPORTE',
    'EDUCACAO',
    'SAUDE',
    'ASSINATURAS',
  };

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  double _savingsPct = 0.10;
  bool _suggesting = false;

  void _exit() => Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
  DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _clamp(DateTime d, DateTime min, DateTime max) =>
      _monthOnly(d).isBefore(min)
          ? min
          : (_monthOnly(d).isAfter(max) ? max : _monthOnly(d));

  String _label(String key) {
    switch (key) {
      case 'MORADIA':
        return 'Moradia';
      case 'ALIMENTACAO':
        return 'Alimentação';
      case 'TRANSPORTE':
        return 'Transporte';
      case 'EDUCACAO':
        return 'Educação';
      case 'SAUDE':
        return 'Saúde';
      case 'LAZER':
        return 'Lazer';
      case 'ASSINATURAS':
        return 'Assinaturas';
      default:
        return 'Outros';
    }
  }

  String _expenseKey(Expense e) {
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
      default:
        return 'OUTROS';
    }
  }

  BudgetV2 _placeholder(String monthYear, String key) => BudgetV2(
        id: '${monthYear}_$key',
        referenceMonth: monthYear,
        categoryKey: key,
        limitAmount: 0,
        spentAmount: 0,
        suggestedAmount: null,
        notified80: false,
        notified100: false,
        essential: _essential.contains(key),
        createdAt: null,
        updatedAt: null,
      );

  Color _statusColor(double pct) => pct >= 1
      ? AppTheme.danger
      : (pct >= 0.8 ? AppTheme.warning : AppTheme.success);
  String _statusLabel(double pct, double limit) => limit <= 0
      ? 'Sem limite'
      : (pct >= 1 ? 'Estourou' : (pct >= 0.8 ? 'Atenção' : 'Sob controle'));

  Map<String, double> _extractSuggestions(Object? payload) {
    final out = <String, double>{};
    if (payload is! Map<String, dynamic>) return out;
    final raw = payload['suggestions'] ??
        payload['data'] ??
        payload['result'] ??
        payload;
    if (raw is List) {
      for (final row in raw) {
        if (row is! Map) continue;
        final key = (row['categoryKey'] ?? row['category'])?.toString();
        final value =
            row['suggestedAmount'] ?? row['amount'] ?? row['limitAmount'];
        final amount =
            value is num ? value.toDouble() : double.tryParse('$value');
        if (key == null || key.isEmpty || amount == null || amount <= 0) {
          continue;
        }
        out[key] = amount;
      }
    }
    return out;
  }

  Map<String, double> _localSuggestions(double income) {
    final usable =
        income > 0 ? income * (1 - _savingsPct.clamp(0.0, 0.5)) : 0.0;
    const weights = {
      'MORADIA': 0.32,
      'ALIMENTACAO': 0.16,
      'TRANSPORTE': 0.10,
      'EDUCACAO': 0.06,
      'SAUDE': 0.06,
      'LAZER': 0.06,
      'ASSINATURAS': 0.04,
      'OUTROS': 0.20
    };
    return {
      for (final entry in weights.entries)
        entry.key: double.parse((usable * entry.value).toStringAsFixed(2))
    };
  }

  Future<void> _edit(BudgetV2 budget) async {
    final controller =
        TextEditingController(text: formatMoneyInput(budget.limitAmount));
    var essential = budget.essential;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar ${_label(budget.categoryKey)}'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) =>
              Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [MoneyTextInputFormatter()],
                decoration: const InputDecoration(labelText: 'Limite mensal')),
            const SizedBox(height: 8),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: essential,
                onChanged: (v) => setStateDialog(() => essential = v),
                title: const Text('Categoria essencial')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true) return;
    final uid = LocalStorageService.currentUserId;
    if (uid == null) return;
    await FirestoreService.saveBudgetLimit(
        uid: uid,
        monthYear: budget.referenceMonth,
        categoryKey: budget.categoryKey,
        limitAmount: parseMoneyInput(controller.text),
        essential: essential);
  }

  Future<void> _suggest(String monthYear) async {
    final uid = LocalStorageService.currentUserId;
    if (uid == null || _suggesting) return;
    setState(() => _suggesting = true);
    String? error;
    var source = 'server';
    var suggestions = <String, double>{};
    try {
      suggestions = _extractSuggestions(
          await AdvancedModulesService.suggestBudgets(
              monthYear: monthYear, savingsPct: _savingsPct));
      if (suggestions.isEmpty) source = 'local';
    } catch (e) {
      error = e.toString();
      source = 'local';
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
    if (suggestions.isEmpty) {
      final totalIncome = LocalStorageService.incomeTotalForMonth(
        DateTime(_month.year, _month.month, 1),
      );
      suggestions = _localSuggestions(totalIncome > 0 ? totalIncome : 0);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => SuggestBudgetsDialog(
        uid: uid,
        monthYear: monthYear,
        suggestions: suggestions,
        source: source,
        error: error,
        applyBudget: (categoryKey, value, replicateFuture) async {
          final months = replicateFuture
              ? List.generate(12,
                  (i) => _monthKey(DateTime(_month.year, _month.month + i, 1)))
              : <String>[monthYear];
          for (final month in months) {
            await FirestoreService.saveBudgetLimit(
                uid: uid,
                monthYear: month,
                categoryKey: categoryKey,
                limitAmount: value);
          }
          await FirestoreService.logBudgetSuggestionRun(
              uid: uid,
              monthYear: monthYear,
              categoryKey: categoryKey,
              suggestedAmount: value,
              replicateFuture: replicateFuture);
        },
      ),
    );
  }

  Widget _card(BuildContext context, Widget child,
          {bool highlighted = false}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration:
            AppTheme.premiumCardDecoration(context, highlighted: highlighted),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final uid = LocalStorageService.currentUserId;
    final user = LocalStorageService.getUserProfile();
    final isPremium = !UserPlan.isFeatureLocked(user, 'budgets');
    final scheme = Theme.of(context).colorScheme;
    final minMonth = DateTime((user?.createdAt ?? DateTime.now()).year,
        (user?.createdAt ?? DateTime.now()).month, 1);
    final maxMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 12, 1);
    final month = _clamp(_month, minMonth, maxMonth);
    final monthYear = _monthKey(month);
    final monthLabel =
        DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
            .format(month);
    if (month != _month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _month = month);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
            leading: IconButton(
                onPressed: _exit, icon: const Icon(Icons.arrow_back_rounded)),
            title: const Text('Orçamentos'),
            centerTitle: true),
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).scaffoldBackgroundColor,
            scheme.surfaceContainerLow
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: uid == null
              ? Center(
                  child: Padding(
                      padding: Responsive.pagePadding(context),
                      child: Text('Faça login para visualizar seus orçamentos.',
                          style: TextStyle(
                              color: AppTheme.textSecondary(context)))))
              : StreamBuilder<List<Expense>>(
                  stream: LocalStorageService.watchTransactions(
                      month.month, month.year),
                  builder: (context, txSnapshot) {
                    final spentByKey = {for (final key in _keys) key: 0.0};
                    for (final tx in txSnapshot.data ?? const <Expense>[]) {
                      if (tx.txType == 'INCOME' ||
                          tx.txType == 'DEBT_PAYMENT' ||
                          tx.txType == 'INVESTMENT' ||
                          tx.isInvestment) {
                        continue;
                      }
                      final key = _expenseKey(tx);
                      if (spentByKey.containsKey(key)) {
                        spentByKey[key] = spentByKey[key]! + tx.amount;
                      }
                    }
                    return StreamBuilder<List<BudgetV2>>(
                      stream: FirestoreService.watchBudgets(uid, monthYear),
                      builder: (context, budgetSnapshot) {
                        final byKey = <String, BudgetV2>{
                          for (final b
                              in budgetSnapshot.data ?? const <BudgetV2>[])
                            b.categoryKey: b
                        };
                        final items = _keys
                            .map((key) =>
                                byKey[key] ?? _placeholder(monthYear, key))
                            .toList();
                        final visible = items
                            .where((b) =>
                                b.limitAmount > 0 ||
                                (spentByKey[b.categoryKey] ?? 0) > 0)
                            .toList();
                        final totalSpent =
                            spentByKey.values.fold<double>(0, (a, b) => a + b);
                        final totalLimit =
                            items.fold<double>(0, (a, b) => a + b.limitAmount);

                        return ListView(
                          padding: Responsive.pagePadding(context),
                          children: [
                            if (!isPremium) ...[
                              PremiumUpsellCard(perks: const [
                                'Acompanhe limites por categoria.',
                                'Receba sugestões automáticas.',
                                'Entenda onde o mês está mais pressionado.'
                              ]),
                              const SizedBox(height: 16),
                            ],
                            _card(
                                context,
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Planejamento do mês',
                                          style: TextStyle(
                                              color:
                                                  AppTheme.textPrimary(context),
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Defina limites claros e acompanhe o que já saiu do mês.',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary(
                                                  context),
                                              height: 1.4)),
                                      const SizedBox(height: 16),
                                      Row(children: [
                                        IconButton(
                                            onPressed: _monthOnly(month) ==
                                                    _monthOnly(minMonth)
                                                ? null
                                                : () => setState(() => _month =
                                                    DateTime(month.year,
                                                        month.month - 1, 1)),
                                            icon: const Icon(
                                                Icons.chevron_left_rounded)),
                                        Expanded(
                                            child: Column(children: [
                                          Text(
                                              '${monthLabel[0].toUpperCase()}${monthLabel.substring(1)}',
                                              style: TextStyle(
                                                  color: AppTheme.textPrimary(
                                                      context),
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(monthYear,
                                              style: TextStyle(
                                                  color: AppTheme.textSecondary(
                                                      context),
                                                  fontSize: 12)),
                                        ])),
                                        IconButton(
                                            onPressed: _monthOnly(month) ==
                                                    _monthOnly(maxMonth)
                                                ? null
                                                : () => setState(() => _month =
                                                    DateTime(month.year,
                                                        month.month + 1, 1)),
                                            icon: const Icon(
                                                Icons.chevron_right_rounded)),
                                      ]),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                              onPressed: _suggesting
                                                  ? null
                                                  : () => _suggest(monthYear),
                                              icon: _suggesting
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2))
                                                  : const Icon(Icons
                                                      .auto_awesome_rounded),
                                              label: Text(_suggesting
                                                  ? 'Gerando sugestões...'
                                                  : 'Sugerir limites'))),
                                    ]),
                                highlighted: true),
                            const SizedBox(height: 16),
                            _card(
                                context,
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Meta de poupança',
                                          style: TextStyle(
                                              color:
                                                  AppTheme.textPrimary(context),
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      Text(
                                          '${(_savingsPct * 100).round()}% reservado para você.',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary(
                                                  context))),
                                      Slider(
                                          value: _savingsPct,
                                          min: 0,
                                          max: 0.4,
                                          divisions: 40,
                                          label:
                                              '${(_savingsPct * 100).round()}%',
                                          onChanged: (v) =>
                                              setState(() => _savingsPct = v)),
                                    ])),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                  child: _card(
                                      context,
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Total gasto',
                                                style: TextStyle(
                                                    color:
                                                        AppTheme.textSecondary(
                                                            context),
                                                    fontSize: 12)),
                                            const SizedBox(height: 8),
                                            Text(
                                                CurrencyUtils.format(
                                                    totalSpent),
                                                style: TextStyle(
                                                    color: AppTheme.textPrimary(
                                                        context),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 18))
                                          ]))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _card(
                                      context,
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Total de limites',
                                                style: TextStyle(
                                                    color:
                                                        AppTheme.textSecondary(
                                                            context),
                                                    fontSize: 12)),
                                            const SizedBox(height: 8),
                                            Text(
                                                CurrencyUtils.format(
                                                    totalLimit),
                                                style: TextStyle(
                                                    color: AppTheme.textPrimary(
                                                        context),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 18))
                                          ]))),
                            ]),
                            const SizedBox(height: 20),
                            Text('Categorias',
                                style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            if (visible.isEmpty)
                              _card(
                                  context,
                                  Column(children: [
                                    Icon(Icons.pie_chart_outline_rounded,
                                        color: scheme.primary, size: 32),
                                    const SizedBox(height: 12),
                                    Text('Seus orçamentos aparecem aqui',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color:
                                                AppTheme.textPrimary(context),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Toque em Sugerir para criar limites iniciais ou edite uma categoria manualmente.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color:
                                                AppTheme.textSecondary(context),
                                            height: 1.4)),
                                  ]))
                            else
                              ...visible.map((b) {
                                final spent = spentByKey[b.categoryKey] ?? 0.0;
                                final pct = b.limitAmount <= 0
                                    ? 0.0
                                    : (spent / b.limitAmount).clamp(0.0, 1.0);
                                final color = _statusColor(pct);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () => _edit(b),
                                    child: _card(
                                        context,
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Expanded(
                                                    child: Text(
                                                        _label(b.categoryKey),
                                                        style: TextStyle(
                                                            color: AppTheme
                                                                .textPrimary(
                                                                    context),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 16))),
                                                Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                        color: color.withValues(
                                                            alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999)),
                                                    child: Text(
                                                        _statusLabel(
                                                            pct, b.limitAmount),
                                                        style: TextStyle(
                                                            color: color,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 11))),
                                              ]),
                                              const SizedBox(height: 12),
                                              LinearProgressIndicator(
                                                  value: pct,
                                                  minHeight: 8,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  backgroundColor: scheme
                                                      .surfaceContainerHigh,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          color)),
                                              const SizedBox(height: 12),
                                              Row(children: [
                                                Expanded(
                                                    child: Text(
                                                        'Gasto\n${CurrencyUtils.format(spent)}',
                                                        style: TextStyle(
                                                            color: AppTheme
                                                                .textSecondary(
                                                                    context),
                                                            height: 1.4))),
                                                Expanded(
                                                    child: Text(
                                                        'Limite\n${CurrencyUtils.format(b.limitAmount)}',
                                                        style: TextStyle(
                                                            color: AppTheme
                                                                .textSecondary(
                                                                    context),
                                                            height: 1.4))),
                                              ]),
                                              if (b.suggestedAmount != null ||
                                                  b.essential) ...[
                                                const SizedBox(height: 12),
                                                Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      if (b.suggestedAmount !=
                                                          null)
                                                        Container(
                                                            padding: const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 6),
                                                            decoration: BoxDecoration(
                                                                color: scheme
                                                                    .surfaceContainerHigh,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            999)),
                                                            child: Text(
                                                                'Sugestão ${CurrencyUtils.format(b.suggestedAmount!)}',
                                                                style: TextStyle(
                                                                    color: AppTheme.textSecondary(
                                                                        context),
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700))),
                                                      if (b.essential)
                                                        Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        6),
                                                            decoration: BoxDecoration(
                                                                color: scheme
                                                                    .surfaceContainerHigh,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            999)),
                                                            child: Text(
                                                                'Essencial',
                                                                style: TextStyle(
                                                                    color: AppTheme
                                                                        .textSecondary(
                                                                            context),
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700))),
                                                    ]),
                                              ],
                                            ])),
                                  ),
                                );
                              }),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
