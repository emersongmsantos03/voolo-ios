import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_strings.dart';
import '../../core/debts/debt_plan_calculator.dart';
import '../../core/plans/user_plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/debt_plan_v2.dart';
import '../../models/debt_v2.dart';
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
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _planning = false;
  final Set<String> _ensuredDebtMonthTx = <String>{};
  final Set<String> _payingDebtMonth = <String>{};
  List<DebtV2> _latestDebts = const <DebtV2>[];

  DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _clampToMonthRange(
      DateTime d, DateTime minMonth, DateTime maxMonth) {
    final md = _monthOnly(d);
    if (md.isBefore(minMonth)) return minMonth;
    if (md.isAfter(maxMonth)) return maxMonth;
    return md;
  }

  Future<void> _addDebt(String uid) async {
    final creditorController = TextEditingController();
    final totalController = TextEditingController();
    final rateController = TextEditingController();
    final minController = TextEditingController();
    final installmentAmountController = TextEditingController();
    final installmentTotalController = TextEditingController();
    final installmentDueDayController = TextEditingController(text: '1');
    final installmentStartMonthYearController =
        TextEditingController(text: _monthKey(_currentMonth));
    const kind = 'card';
    var isInstallment = false;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nova dívida'),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            content: Builder(
              builder: (context) {
                Widget fieldLabel(String text) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );

                Widget fieldGroup({
                  required String label,
                  required Widget child,
                }) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fieldLabel(label),
                      child,
                    ],
                  );
                }

                Widget twoCol({
                  required Widget left,
                  required Widget right,
                }) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final canTwoCol = constraints.maxWidth >= 380;
                      if (canTwoCol) {
                        return Row(
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 12),
                            Expanded(child: right),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          left,
                          const SizedBox(height: 10),
                          right,
                        ],
                      );
                    },
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SizedBox(
                    width: 480,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fieldGroup(
                            label: 'Credor',
                            child: TextField(
                              controller: creditorController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Ex.: Cartão, Banco, Empréstimo…',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          fieldGroup(
                            label: 'Valor total (R\$)',
                            child: TextField(
                              controller: totalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: const [
                                MoneyTextInputFormatter()
                              ],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: '0,00',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          twoCol(
                            left: fieldGroup(
                              label: 'Juros (% a.m.)',
                              child: TextField(
                                controller: rateController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Opcional',
                                ),
                              ),
                            ),
                            right: fieldGroup(
                              label: 'Pagamento mínimo (R\$)',
                              child: TextField(
                                controller: minController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: const [
                                  MoneyTextInputFormatter()
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Opcional',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setDialogState(() {
                              isInstallment = !isInstallment;
                              if (!isInstallment) {
                                installmentAmountController.clear();
                                installmentTotalController.clear();
                                installmentDueDayController.text = '1';
                              }
                            }),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: isInstallment,
                                  onChanged: (v) => setDialogState(() {
                                    isInstallment = v == true;
                                    if (!isInstallment) {
                                      installmentAmountController.clear();
                                      installmentTotalController.clear();
                                      installmentDueDayController.text = '1';
                                    }
                                  }),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'É uma dívida parcelada?',
                                          style: TextStyle(
                                            color:
                                                AppTheme.textPrimary(context),
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Se você sabe a parcela mensal e o total de parcelas, o app cria um gasto fixo e só quita quando todas as parcelas estiverem marcadas como pagas.',
                                          style: TextStyle(
                                            color:
                                                AppTheme.textSecondary(context),
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isInstallment) ...[
                            const SizedBox(height: 12),
                            twoCol(
                              left: fieldGroup(
                                label: 'Parcela mensal (R\$)',
                                child: TextField(
                                  controller: installmentAmountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: const [
                                    MoneyTextInputFormatter()
                                  ],
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: '0,00',
                                  ),
                                ),
                              ),
                              right: fieldGroup(
                                label: 'Total de parcelas',
                                child: TextField(
                                  controller: installmentTotalController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex.: 24',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            fieldGroup(
                              label: 'Vencimento (dia do mês)',
                              child: TextField(
                                controller: installmentDueDayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '1',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: const Color(0xFF0B0C0F),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    final creditorName = creditorController.text.trim();
    if (creditorName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o credor.')),
        );
      }
      return;
    }

    final rate = double.tryParse(rateController.text.replaceAll(',', '.'));

    double total = parseMoneyInput(totalController.text);
    final minRaw = parseMoneyInput(minController.text);
    double? minPayment = minRaw > 0 ? minRaw : null;

    if (!(total.isFinite) || total <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um valor total válido.')),
        );
      }
      return;
    }

    double? installmentAmount;
    int? installmentTotal;
    int? installmentDueDay;
    String? installmentStartMonthYear;

    if (isInstallment) {
      installmentAmount = parseMoneyInput(installmentAmountController.text);
      installmentTotal = int.tryParse(installmentTotalController.text.trim());
      installmentDueDay = int.tryParse(installmentDueDayController.text.trim());
      installmentStartMonthYear =
          installmentStartMonthYearController.text.trim();

      final okStart =
          RegExp(r'^\\d{4}-\\d{2}$').hasMatch(installmentStartMonthYear);
      if (!okStart) {
        installmentStartMonthYear = _monthKey(_currentMonth);
      }

      if ((installmentTotal ?? 0) <= 0 || (installmentTotal ?? 0) > 600) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Total de parcelas inválido (1 a 600).'),
            ),
          );
        }
        return;
      }

      installmentDueDay = ((installmentDueDay ?? 1).clamp(1, 31)).toInt();
      if ((installmentDueDay ?? 1) < 1 || (installmentDueDay ?? 1) > 31) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Defina um vencimento entre 1 e 31.')),
          );
        }
        return;
      }

      if (installmentAmount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informe a parcela mensal.')),
          );
        }
        return;
      }
    }

    final debt = DebtV2(
      id: '',
      creditorName: creditorName,
      totalAmount: total,
      interestRate: rate,
      minPayment: minPayment,
      isLate: false,
      lateSince: null,
      status: 'ACTIVE',
      kind: kind,
      installmentAmount: installmentAmount,
      installmentTotal: installmentTotal,
      installmentDueDay: installmentDueDay,
      installmentStartMonthYear: installmentStartMonthYear,
      paidInstallmentMonths: const {},
      fixedSeriesId: null,
      createdAt: null,
      updatedAt: null,
    );
    final debtId = await FirestoreService.saveDebt(uid, debt);

    if (isInstallment) {
      final withId = DebtV2(
        id: debtId,
        creditorName: debt.creditorName,
        totalAmount: debt.totalAmount,
        interestRate: debt.interestRate,
        minPayment: debt.minPayment,
        isLate: debt.isLate,
        lateSince: debt.lateSince,
        status: debt.status,
        kind: debt.kind,
        installmentAmount: debt.installmentAmount,
        installmentTotal: debt.installmentTotal,
        installmentDueDay: debt.installmentDueDay,
        installmentStartMonthYear: debt.installmentStartMonthYear,
        paidInstallmentMonths: debt.paidInstallmentMonths,
        fixedSeriesId: FirestoreService.debtSeriesIdFor(debtId),
        createdAt: debt.createdAt,
        updatedAt: debt.updatedAt,
      );

      await FirestoreService.ensureDebtFixedSeries(uid, withId);
      await FirestoreService.ensureDebtTransactionForMonth(
        uid,
        debt: withId,
        monthYear: _monthKey(_currentMonth),
      );
    }
  }

  Future<void> _generatePlan(String monthYear, String method) async {
    if (_planning) return;
    setState(() => _planning = true);
    try {
      final uid = LocalStorageService.currentUserId;
      if (uid == null || uid.isEmpty) return;

      final budgetController = TextEditingController();
      final minGuess = _latestDebts.fold<double>(0.0, (sum, d) {
        if (d.status == 'PAID') return sum;
        if (d.isInstallmentDebt) {
          if (!d.isWithinInstallmentWindow(monthYear)) return sum;
          if (d.paidInstallmentMonths[monthYear] == true) return sum;
          return sum + (d.installmentAmount ?? 0.0);
        }
        return sum + (d.minPayment ?? 0.0);
      });
      if (minGuess > 0) {
        budgetController.text = formatMoneyInput(minGuess);
      }

      final selectedMonthlyBudget = await showDialog<double?>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Orçamento mensal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quanto você consegue pagar em dívidas neste mês?'),
              const SizedBox(height: 10),
              TextField(
                controller: budgetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [MoneyTextInputFormatter()],
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(AppStrings.t(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final value = parseMoneyInput(budgetController.text);
                Navigator.pop(context, value > 0 ? value : null);
              },
              child: const Text('Gerar'),
            ),
          ],
        ),
      );
      if (selectedMonthlyBudget == null || selectedMonthlyBudget <= 0) return;

      final calc = computeDebtPlanLocal(
        referenceMonth: monthYear,
        method: method,
        monthlyBudget: selectedMonthlyBudget,
        debts: _latestDebts,
      );

      final result = <String, dynamic>{
        'recommendedMaxInstallment': selectedMonthlyBudget,
        'minimumPaymentsTotal': calc.minimumPaymentsTotal,
        'monthlyBudgetUsed': calc.monthlyBudgetUsed,
        'extraBudget': calc.extraBudget,
        'estimatedDebtFreeMonthYear': calc.estimatedDebtFreeMonthYear,
        'explanation': '',
        'instructions': '',
        'warnings': calc.warnings,
        'debts': calc.debts,
      };
      if (!mounted) return;
      final recommended =
          (result['recommendedMaxInstallment'] as num?)?.toDouble() ?? 0.0;
      final minimums =
          (result['minimumPaymentsTotal'] as num?)?.toDouble() ?? 0.0;
      final monthlyBudget =
          (result['monthlyBudgetUsed'] as num?)?.toDouble() ?? 0.0;
      final extra = (result['extraBudget'] as num?)?.toDouble() ?? 0.0;
      final estimated = result['estimatedDebtFreeMonthYear']?.toString();
      final explanation = result['explanation']?.toString() ?? '';
      final instructions = result['instructions']?.toString() ?? '';
      final warningsRaw = result['warnings'];
      final warnings = warningsRaw is List
          ? warningsRaw
              .map((x) => x?.toString() ?? '')
              .where((x) => x.trim().isNotEmpty)
              .toList()
          : const <String>[];
      final debtsRaw = result['debts'];
      final debts = debtsRaw is List ? debtsRaw : const [];

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

      final buffer = StringBuffer();
      if (explanation.trim().isNotEmpty) {
        buffer.writeln(explanation.trim());
        buffer.writeln();
      }
      if (instructions.trim().isNotEmpty) {
        buffer.writeln(instructions.trim());
        buffer.writeln();
      }
      buffer.writeln(
          'Parcela (cap) recomendada: ${CurrencyUtils.format(recommended)}');
      if (minimums > 0)
        buffer.writeln('Total de mínimos: ${CurrencyUtils.format(minimums)}');
      if (monthlyBudget > 0)
        buffer.writeln(
            'Orçamento usado na simulação: ${CurrencyUtils.format(monthlyBudget)}');
      if (extra > 0)
        buffer.writeln('Extra (foco): ${CurrencyUtils.format(extra)}');
      if (estimated != null && estimated.trim().isNotEmpty) {
        buffer.writeln('Previsão “livre de dívidas”: $estimated');
      }

      if (debts.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Ordem de ataque:');
        for (final raw in debts) {
          if (raw is! Map) continue;
          final order = raw['order']?.toString() ?? '';
          final name = raw['creditorName']?.toString() ?? 'Dívida';
          final total = (raw['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final minUsed = (raw['minPaymentUsed'] as num?)?.toDouble();
          final rate = (raw['interestRate'] as num?)?.toDouble();
          final assumed = raw['minPaymentAssumed'] == true;

          final parts = <String>[
            'Total: ${CurrencyUtils.format(total)}',
            if (minUsed != null && minUsed > 0)
              'Mínimo: ${CurrencyUtils.format(minUsed)}',
            if (rate != null) 'Juros: ${rate.toStringAsFixed(1)}% a.m.',
            if (assumed) 'mínimo estimado',
          ];

          buffer.writeln(
              '${order.isEmpty ? '•' : '$order.'} $name — ${parts.join(' • ')}');
        }
      }

      if (warnings.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Atenção:');
        for (final w in warnings) {
          buffer.writeln('• $w');
        }
      }
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Plano de quitação'),
          content: SingleChildScrollView(
            child: Text(
              buffer.toString().trim(),
              style: TextStyle(
                  color: AppTheme.textSecondary(context), height: 1.35),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await FirestoreService.saveDebtPlanV2(
                  uid: uid,
                  monthYear: monthYear,
                  method: method,
                  monthlyBudget: selectedMonthlyBudget,
                  plan: compact,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Plano salvo (sincronizado).')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.t(context, 'close')),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar o plano agora.')),
      );
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  Future<void> _openSavedPlan(DebtPlanDocV2 doc) async {
    if (!mounted) return;
    if (doc.methods.isEmpty) return;

    final method = (doc.lastMethod != null &&
            doc.lastMethod!.isNotEmpty &&
            doc.methods.containsKey(doc.lastMethod))
        ? doc.lastMethod!
        : doc.methods.keys.first;

    final methodData = doc.methods[method] ?? doc.methods.values.first;
    final plan = methodData.plan;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Plano salvo (sincronizado)'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mês: ${doc.referenceMonth} • Método: $method',
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Orçamento: ${CurrencyUtils.format(methodData.monthlyBudget)}',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mínimos: ${CurrencyUtils.format(plan.minimumPaymentsTotal)} • Extra: ${CurrencyUtils.format(plan.extraBudget)}',
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                if (plan.estimatedDebtFreeMonthYear != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Estimativa: ${plan.estimatedDebtFreeMonthYear}',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'O que pagar este mês',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...plan.firstMonthPayments.map((p) {
                  final id = p['debtId']?.toString() ?? '';
                  final kind = p['kind']?.toString() ?? '';
                  final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                  final row = plan.debts
                      .where((d) => d['debtId']?.toString() == id)
                      .toList();
                  final name = row.isNotEmpty
                      ? (row.first['creditorName']?.toString() ?? 'Dívida')
                      : 'Dívida';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $name: ${CurrencyUtils.format(amount)}${kind == 'extra' ? ' (extra)' : ''}',
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Ver detalhes',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Ordem de ataque',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...plan.debts.map((d) {
                      final order = d['order']?.toString() ?? '';
                      final name = d['creditorName']?.toString() ?? 'Dívida';
                      final total =
                          (d['totalAmount'] as num?)?.toDouble() ?? 0.0;
                      final minUsed = (d['minPaymentUsed'] as num?)?.toDouble();
                      final rate = (d['interestRate'] as num?)?.toDouble();
                      final assumed = d['minPaymentAssumed'] == true;
                      final parts = <String>[
                        'Total: ${CurrencyUtils.format(total)}',
                        if (minUsed != null && minUsed > 0)
                          'Mínimo: ${CurrencyUtils.format(minUsed)}',
                        if (rate != null && rate > 0)
                          'Juros: ${rate.toStringAsFixed(1)}% a.m.',
                        if (assumed) 'mínimo estimado',
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${order.isEmpty ? '•' : '$order.'} $name — ${parts.join(' • ')}',
                          style:
                              TextStyle(color: AppTheme.textSecondary(context)),
                        ),
                      );
                    }),
                    if (plan.warnings.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Atenção',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...plan.warnings.map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• $w',
                              style: TextStyle(
                                  color: AppTheme.textSecondary(context)),
                            ),
                          )),
                    ],
                  ],
                ),
              ],
            ),
          ),
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

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  double _estimatedMinPaymentFor(DebtV2 d) {
    final installment = d.installmentAmount ?? 0.0;
    if (installment.isFinite && installment > 0) return installment;
    final min = d.minPayment ?? 0.0;
    if (min.isFinite && min > 0) return min;
    final bal = d.totalAmount;
    if (!bal.isFinite || bal <= 0) return 0.0;
    return max(50.0, bal * 0.03);
  }

  ({double totalDebt, double minTotal, int lateCount, double weightedRate})
      _debtReport(List<DebtV2> debts) {
    final items = debts.where((d) => d.status != 'PAID').toList();
    final totalDebt = items.fold<double>(
        0.0, (acc, d) => acc + (d.totalAmount.isFinite ? d.totalAmount : 0.0));
    final minTotal =
        items.fold<double>(0.0, (acc, d) => acc + _estimatedMinPaymentFor(d));
    final lateCount = items.where((d) => d.isLate).length;
    final weightedRate = totalDebt > 0
        ? items.fold<double>(
              0.0,
              (acc, d) =>
                  acc +
                  (d.totalAmount.isFinite ? d.totalAmount : 0.0) *
                      max(0.0, d.interestRate ?? 0.0),
            ) /
            totalDebt
        : 0.0;
    return (
      totalDebt: totalDebt,
      minTotal: minTotal,
      lateCount: lateCount,
      weightedRate: weightedRate,
    );
  }

  String _debtDetailLine(DebtV2 d, String monthYear) {
    final parts = <String>[
      'Total: ${CurrencyUtils.format(d.totalAmount)}',
    ];

    final hasInstallment = (d.installmentAmount ?? 0) > 0;
    if (hasInstallment) {
      parts.add('Parcela: ${CurrencyUtils.format(d.installmentAmount ?? 0)}');
      final total = d.installmentTotal;
      final remaining = d.remainingInstallments;
      if (total != null && total > 0) {
        parts.add('faltam: ${remaining ?? total}/$total');
      }
    } else {
      final minProvided = (d.minPayment ?? 0) > 0;
      final minEst = _estimatedMinPaymentFor(d);
      if (minProvided) {
        parts.add('Mínimo: ${CurrencyUtils.format(d.minPayment ?? 0)}');
      } else if (minEst > 0) {
        parts.add('Mínimo estimado: ${CurrencyUtils.format(minEst)}');
      }
    }

    if (d.interestRate != null) {
      parts.add('Juros: ${d.interestRate!.toStringAsFixed(1)}% a.m.');
    }
    if (d.isLate) {
      parts.add('Em atraso');
    }
    if (hasInstallment) {
      final paidThisMonth = d.paidInstallmentMonths[monthYear] == true;
      parts.add(paidThisMonth ? 'Pago (este mês)' : 'A pagar (este mês)');
    }

    return parts.join(' • ');
  }

  Widget _reportRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _reportCard(List<DebtV2> debts) {
    final scheme = Theme.of(context).colorScheme;
    final r = _debtReport(debts);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relatório das dívidas',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _reportRow('Total em dívidas', CurrencyUtils.format(r.totalDebt)),
          const SizedBox(height: 8),
          _reportRow(
            'Total de mínimos (estimado)',
            CurrencyUtils.format(r.minTotal),
          ),
          const SizedBox(height: 8),
          _reportRow(
            'Juros médio ponderado',
            '${r.weightedRate.toStringAsFixed(1)}% a.m.',
          ),
          const SizedBox(height: 8),
          _reportRow('Em atraso', '${r.lateCount}'),
          const SizedBox(height: 10),
          Text(
            'Dica: se houver atraso, regularize primeiro para evitar multas/encargos e só então siga a ordem Avalanche/Snowball.',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = LocalStorageService.currentUserId;
    final user = LocalStorageService.getUserProfile();
    final isPremium = !UserPlan.isFeatureLocked(user, 'debt_plan');
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
      appBar: AppBar(title: Text(AppStrings.t(context, 'debts_exit'))),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                try {
                  await _addDebt(uid);
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Não foi possível adicionar a dívida agora.'),
                    ),
                  );
                }
              },
              child: const Icon(Icons.add),
            ),
      body: PremiumGate(
        isPremium: isPremium,
        title: AppStrings.t(context, 'debts_plan_title'),
        subtitle: AppStrings.t(context, 'debts_plan_subtitle'),
        perks: [
          AppStrings.t(context, 'debts_plan_perk_1'),
          AppStrings.t(context, 'debts_plan_perk_2'),
          AppStrings.t(context, 'debts_plan_perk_3')
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
                        const Spacer(),
                        if (_planning)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
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
                        OutlinedButton(
                          onPressed: _planning
                              ? null
                              : () => _generatePlan(monthYear, 'avalanche'),
                          child: const Text('Avalanche'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _planning
                              ? null
                              : () => _generatePlan(monthYear, 'snowball'),
                          child: const Text('Snowball'),
                        ),
                      ],
                    ),
                    StreamBuilder<DebtPlanDocV2?>(
                      stream: FirestoreService.watchDebtPlanV2(uid, monthYear),
                      builder: (context, planSnap) {
                        final doc = planSnap.data;
                        if (doc == null || doc.methods.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cloud_done_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Plano salvo (sincronizado)',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => _openSavedPlan(doc),
                                  child: const Text('Abrir'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<DebtV2>>(
                        stream: FirestoreService.watchDebts(uid),
                        builder: (context, snap) {
                          final all = snap.data ?? const <DebtV2>[];
                          final items =
                              all.where((d) => d.status != 'PAID').toList();
                          _latestDebts = all;
                          if (items.isEmpty) {
                            return Center(
                              child: Text(
                                'Cadastre suas dívidas para gerar um plano.',
                                style: TextStyle(
                                    color: AppTheme.textSecondary(context)),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: items.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              if (i == 0) return _reportCard(items);

                              final d = items[i - 1];
                              final debtMonthKey = '${d.id}|$monthYear';
                              final isInstallment = d.isInstallmentDebt;
                              final inWindow = isInstallment &&
                                  d.isWithinInstallmentWindow(monthYear);

                              if (inWindow &&
                                  !_ensuredDebtMonthTx.contains(debtMonthKey)) {
                                _ensuredDebtMonthTx.add(debtMonthKey);
                                FirestoreService.ensureDebtFixedSeries(uid, d)
                                    .catchError((_) {});
                                FirestoreService.ensureDebtTransactionForMonth(
                                  uid,
                                  debt: d,
                                  monthYear: monthYear,
                                ).catchError((_) {});
                              }

                              final paidThisMonth =
                                  d.paidInstallmentMonths[monthYear] == true;
                              final paying =
                                  _payingDebtMonth.contains(debtMonthKey);
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (d.creditorName).trim().isEmpty
                                                ? 'Dívida'
                                                : d.creditorName.trim(),
                                            style: TextStyle(
                                              color:
                                                  AppTheme.textPrimary(context),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _debtDetailLine(d, monthYear),
                                            style: TextStyle(
                                              color: AppTheme.textSecondary(
                                                  context),
                                              fontSize: 12,
                                              height: 1.35,
                                            ),
                                          ),
                                          if (inWindow) ...[
                                            const SizedBox(height: 10),
                                            OutlinedButton(
                                              onPressed: paying
                                                  ? null
                                                  : () async {
                                                      final next =
                                                          !paidThisMonth;
                                                      setState(() =>
                                                          _payingDebtMonth.add(
                                                              debtMonthKey));
                                                      try {
                                                        await FirestoreService
                                                            .setDebtInstallmentPaidForMonth(
                                                          uid,
                                                          debt: d,
                                                          monthYear: monthYear,
                                                          isPaid: next,
                                                        );
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() =>
                                                              _payingDebtMonth
                                                                  .remove(
                                                                      debtMonthKey));
                                                        }
                                                      }
                                                    },
                                              child: Text(
                                                paying
                                                    ? 'Salvando...'
                                                    : (paidThisMonth
                                                        ? 'Pago'
                                                        : 'Marcar pago'),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title:
                                                const Text('Remover dívida?'),
                                            content: const Text(
                                              'Isso remove esta dívida da sua lista.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: Text(AppStrings.t(
                                                    context, 'cancel')),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Remover'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          await FirestoreService.deleteDebt(
                                              uid, d.id);
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                    ),
                                  ],
                                ),
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
