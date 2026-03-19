import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/debts/debt_plan_calculator.dart';
import '../../core/plans/user_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/debt_plan_v2.dart';
import '../../models/debt_v2.dart';
import '../../routes/app_routes.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/money_input.dart';
import '../../widgets/premium_gate.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});
  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _planning = false;
  final Set<String> _savingMonths = <String>{};

  void _exit() {
    final navigator = Navigator.of(context);
    var foundDashboard = false;
    navigator.popUntil((route) {
      final isDashboard = route.settings.name == AppRoutes.dashboard;
      if (isDashboard) foundDashboard = true;
      return isDashboard || route.isFirst;
    });
    if (!foundDashboard && context.mounted) {
      navigator.pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
  DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _clamp(DateTime d, DateTime min, DateTime max) =>
      _monthOnly(d).isBefore(min)
          ? min
          : (_monthOnly(d).isAfter(max) ? max : _monthOnly(d));

  double _estimatedMin(DebtV2 debt) {
    if (debt.isInstallmentDebt) return debt.installmentAmount ?? 0.0;
    final explicit = debt.minPayment ?? 0.0;
    if (explicit > 0) return explicit;
    return debt.totalAmount <= 0
        ? 0
        : (debt.totalAmount * 0.03).clamp(50, debt.totalAmount);
  }

  String _detail(DebtV2 debt, String monthYear) {
    final parts = <String>[
      CurrencyUtils.format(debt.totalAmount),
      'Mínimo ${CurrencyUtils.format(_estimatedMin(debt))}',
    ];
    if ((debt.interestRate ?? 0) > 0) {
      parts.add('${debt.interestRate!.toStringAsFixed(1)}% a.m.');
    }
    if (debt.isInstallmentDebt) {
      final paid = debt.paidInstallmentsCount;
      final total = debt.installmentTotal ?? 0;
      final paidThisMonth = debt.paidInstallmentMonths[monthYear] == true;
      parts.add('$paid/$total parcelas');
      parts.add(paidThisMonth ? 'Pago neste mês' : 'A pagar');
    }
    if (debt.isLate) parts.add('Em atraso');
    return parts.join(' • ');
  }

  Widget _card(BuildContext context, Widget child,
          {bool highlighted = false}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration:
            AppTheme.premiumCardDecoration(context, highlighted: highlighted),
        child: child,
      );

  Future<void> _addDebt(String uid) async {
    final creditor = TextEditingController();
    final total = TextEditingController();
    final rate = TextEditingController();
    final minimum = TextEditingController();
    final installmentAmount = TextEditingController();
    final installmentTotal = TextEditingController();
    final installmentDueDay = TextEditingController(text: '1');
    var isInstallment = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova dívida'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: creditor,
                    decoration: const InputDecoration(labelText: 'Credor')),
                const SizedBox(height: 10),
                TextField(
                    controller: total,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration:
                        const InputDecoration(labelText: 'Valor total')),
                const SizedBox(height: 10),
                TextField(
                    controller: rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Juros (% a.m.)')),
                const SizedBox(height: 10),
                TextField(
                    controller: minimum,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration:
                        const InputDecoration(labelText: 'Pagamento mínimo')),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isInstallment,
                  onChanged: (value) =>
                      setDialogState(() => isInstallment = value),
                  title: const Text('Dívida parcelada'),
                ),
                if (isInstallment) ...[
                  TextField(
                      controller: installmentAmount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: const [MoneyTextInputFormatter()],
                      decoration:
                          const InputDecoration(labelText: 'Valor da parcela')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: installmentTotal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Total de parcelas')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: installmentDueDay,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Dia do vencimento')),
                ],
              ],
            ),
          ),
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

    final debt = DebtV2(
      id: '',
      creditorName: creditor.text.trim(),
      totalAmount: parseMoneyInput(total.text),
      interestRate: double.tryParse(rate.text.replaceAll(',', '.')),
      minPayment: parseMoneyInput(minimum.text),
      isLate: false,
      lateSince: null,
      status: 'ACTIVE',
      kind: 'card',
      installmentAmount:
          isInstallment ? parseMoneyInput(installmentAmount.text) : null,
      installmentTotal:
          isInstallment ? int.tryParse(installmentTotal.text) : null,
      installmentDueDay:
          isInstallment ? int.tryParse(installmentDueDay.text) : null,
      installmentStartMonthYear: isInstallment ? _monthKey(_month) : null,
      paidInstallmentMonths: const {},
      fixedSeriesId: null,
      createdAt: null,
      updatedAt: null,
    );
    await FirestoreService.saveDebt(uid, debt);
  }

  Future<void> _generatePlan(
      String uid, String monthYear, String method, List<DebtV2> debts) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Plano ${method == 'snowball' ? 'Snowball' : 'Avalanche'}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MoneyTextInputFormatter()],
          decoration:
              const InputDecoration(labelText: 'Orçamento mensal para dívidas'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Gerar')),
        ],
      ),
    );
    if (ok != true) return;

    final monthlyBudget = parseMoneyInput(controller.text);
    if (monthlyBudget <= 0) return;
    setState(() => _planning = true);
    try {
      final calc = computeDebtPlanLocal(
        referenceMonth: monthYear,
        method: method,
        monthlyBudget: monthlyBudget,
        debts: debts,
      );
      final compact = DebtPlanCompactV2(
        minimumPaymentsTotal: calc.minimumPaymentsTotal,
        monthlyBudgetUsed: calc.monthlyBudgetUsed,
        extraBudget: calc.extraBudget,
        estimatedDebtFreeMonthYear: calc.estimatedDebtFreeMonthYear,
        warnings: calc.warnings,
        debts: calc.debts,
        firstMonthPayments: calc.firstMonthPayments,
        scheduleSummary: calc.scheduleSummary,
      );
      await FirestoreService.saveDebtPlanV2(
        uid: uid,
        monthYear: monthYear,
        method: method,
        monthlyBudget: monthlyBudget,
        plan: compact,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plano salvo com sucesso.')),
      );
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  Future<void> _openSavedPlan(DebtPlanDocV2 doc) async {
    final methodKey = doc.lastMethod ??
        (doc.methods.keys.isEmpty ? null : doc.methods.keys.first);
    if (methodKey == null) return;
    final method = doc.methods[methodKey];
    if (method == null) return;
    final plan = method.plan;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Plano ${methodKey == 'snowball' ? 'Snowball' : 'Avalanche'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Orçamento mensal: ${CurrencyUtils.format(method.monthlyBudget)}'),
            const SizedBox(height: 8),
            Text('Mínimos: ${CurrencyUtils.format(plan.minimumPaymentsTotal)}'),
            const SizedBox(height: 8),
            Text('Extra: ${CurrencyUtils.format(plan.extraBudget)}'),
            const SizedBox(height: 8),
            Text(
                'Previsão de quitação: ${plan.estimatedDebtFreeMonthYear ?? 'Sem previsão'}'),
            if (plan.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...plan.warnings.take(3).map(Text.new),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = LocalStorageService.currentUserId;
    final user = LocalStorageService.getUserProfile();
    final isPremium = !UserPlan.isFeatureLocked(user, 'debt_plan');
    final scheme = Theme.of(context).colorScheme;
    final createdAt = user?.createdAt ?? DateTime.now();
    final minMonth = DateTime(createdAt.year, createdAt.month, 1);
    final maxMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 12, 1);
    final month = _clamp(_month, minMonth, maxMonth);
    final monthYear = _monthKey(month);
    final label =
        DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
            .format(month);
    if (month != _month)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _month = month);
      });

    return WillPopScope(
      onWillPop: () async {
        _exit();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: _exit, icon: const Icon(Icons.arrow_back_rounded)),
          title: const Text('Sair das Dívidas'),
          centerTitle: true,
        ),
        floatingActionButton: uid == null
            ? null
            : FloatingActionButton(
                onPressed: () => _addDebt(uid),
                child: const Icon(Icons.add),
              ),
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
                      child: Text('Faça login para visualizar suas dívidas.',
                          style: TextStyle(
                              color: AppTheme.textSecondary(context)))))
              : StreamBuilder<List<DebtV2>>(
                  stream: FirestoreService.watchDebts(uid),
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? const <DebtV2>[];
                    final debts = all.where((d) => d.status != 'PAID').toList();
                    final totalDebt =
                        debts.fold<double>(0, (sum, d) => sum + d.totalAmount);
                    final minTotal = debts.fold<double>(
                        0, (sum, d) => sum + _estimatedMin(d));
                    final lateCount = debts.where((d) => d.isLate).length;
                    return ListView(
                      padding: Responsive.pagePadding(context),
                      children: [
                        if (!isPremium) ...[
                          PremiumUpsellCard(perks: const [
                            'Monte um plano Avalanche ou Snowball.',
                            'Acompanhe pagamento mínimo e parcelas.',
                            'Veja clareza do total em aberto.'
                          ]),
                          const SizedBox(height: 16),
                        ],
                        _card(
                            context,
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Plano do mês',
                                      style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Organize suas dívidas sem misturar pagamento, juros e parcelas.',
                                      style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
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
                                        child: Text(
                                            '${label[0].toUpperCase()}${label.substring(1)}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: AppTheme.textPrimary(
                                                    context),
                                                fontWeight: FontWeight.w700))),
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
                                  Text('Mês: $monthYear',
                                      style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                          onPressed: _planning
                                              ? null
                                              : () => _generatePlan(
                                                  uid,
                                                  monthYear,
                                                  'avalanche',
                                                  debts),
                                          child: const Text('Avalanche')),
                                      OutlinedButton(
                                          onPressed: _planning
                                              ? null
                                              : () => _generatePlan(uid,
                                                  monthYear, 'snowball', debts),
                                          child: const Text('Snowball')),
                                      if (_planning)
                                        const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                                    ],
                                  ),
                                ]),
                            highlighted: true),
                        const SizedBox(height: 16),
                        StreamBuilder<DebtPlanDocV2?>(
                          stream:
                              FirestoreService.watchDebtPlanV2(uid, monthYear),
                          builder: (context, planSnapshot) {
                            final doc = planSnapshot.data;
                            if (doc == null || doc.methods.isEmpty)
                              return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _card(
                                  context,
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Icon(Icons.cloud_done_rounded,
                                              color: scheme.primary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: Text(
                                                  'Plano salvo e sincronizado',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.textPrimary(
                                                              context),
                                                      fontWeight:
                                                          FontWeight.w700))),
                                        ]),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                                onPressed: () =>
                                                    _openSavedPlan(doc),
                                                child: const Text(
                                                    'Abrir plano salvo'))),
                                      ])),
                            );
                          },
                        ),
                        Row(children: [
                          Expanded(
                              child: _card(
                                  context,
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Total em dívidas',
                                            style: TextStyle(
                                                color: AppTheme.textSecondary(
                                                    context),
                                                fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Text(CurrencyUtils.format(totalDebt),
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
                                        Text('Mínimos',
                                            style: TextStyle(
                                                color: AppTheme.textSecondary(
                                                    context),
                                                fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Text(CurrencyUtils.format(minTotal),
                                            style: TextStyle(
                                                color: AppTheme.textPrimary(
                                                    context),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18))
                                      ]))),
                        ]),
                        const SizedBox(height: 12),
                        _card(
                            context,
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Leitura rápida',
                                      style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text('Dívidas em atraso: $lateCount',
                                      style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context))),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Dica: regularize atrasos antes de acelerar Avalanche ou Snowball.',
                                      style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                          height: 1.35)),
                                ])),
                        const SizedBox(height: 20),
                        Text('Suas dívidas',
                            style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        if (debts.isEmpty)
                          _card(
                              context,
                              Column(children: [
                                Icon(Icons.credit_card_off_rounded,
                                    color: scheme.primary, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                    'Cadastre suas dívidas para gerar um plano',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppTheme.textPrimary(context),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18)),
                              ]))
                        else
                          ...debts.map((debt) {
                            final debtMonthKey = '${debt.id}|$monthYear';
                            final saving = _savingMonths.contains(debtMonthKey);
                            final paidThisMonth =
                                debt.paidInstallmentMonths[monthYear] == true;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: debt.isInstallmentDebt
                                    ? () async {
                                        setState(() =>
                                            _savingMonths.add(debtMonthKey));
                                        try {
                                          await FirestoreService
                                              .setDebtInstallmentPaidForMonth(
                                                  uid,
                                                  debt: debt,
                                                  monthYear: monthYear,
                                                  isPaid: !paidThisMonth);
                                        } finally {
                                          if (mounted)
                                            setState(() => _savingMonths
                                                .remove(debtMonthKey));
                                        }
                                      }
                                    : null,
                                child: _card(
                                    context,
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(
                                                    debt.creditorName
                                                            .trim()
                                                            .isEmpty
                                                        ? 'Dívida'
                                                        : debt.creditorName
                                                            .trim(),
                                                    style: TextStyle(
                                                        color: AppTheme
                                                            .textPrimary(
                                                                context),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16))),
                                            IconButton(
                                              onPressed: () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (dialogContext) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Remover dívida?'),
                                                    content: const Text(
                                                        'Isso remove esta dívida da sua lista.'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  dialogContext,
                                                                  false),
                                                          child: const Text(
                                                              'Cancelar')),
                                                      ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  dialogContext,
                                                                  true),
                                                          child: const Text(
                                                              'Remover')),
                                                    ],
                                                  ),
                                                );
                                                if (ok == true)
                                                  await FirestoreService
                                                      .deleteDebt(uid, debt.id);
                                              },
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.redAccent),
                                            ),
                                          ]),
                                          const SizedBox(height: 8),
                                          Text(_detail(debt, monthYear),
                                              style: TextStyle(
                                                  color: AppTheme.textSecondary(
                                                      context),
                                                  height: 1.35)),
                                          if (debt.isInstallmentDebt) ...[
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton(
                                                onPressed: saving
                                                    ? null
                                                    : () async {
                                                        setState(() =>
                                                            _savingMonths.add(
                                                                debtMonthKey));
                                                        try {
                                                          await FirestoreService
                                                              .setDebtInstallmentPaidForMonth(
                                                                  uid,
                                                                  debt: debt,
                                                                  monthYear:
                                                                      monthYear,
                                                                  isPaid:
                                                                      !paidThisMonth);
                                                        } finally {
                                                          if (mounted)
                                                            setState(() =>
                                                                _savingMonths
                                                                    .remove(
                                                                        debtMonthKey));
                                                        }
                                                      },
                                                child: Text(saving
                                                    ? 'Salvando...'
                                                    : (paidThisMonth
                                                        ? 'Pago neste mês'
                                                        : 'Marcar como pago')),
                                              ),
                                            ),
                                          ],
                                        ])),
                              ),
                            );
                          }),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
