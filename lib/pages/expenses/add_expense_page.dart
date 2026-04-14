import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/expense.dart';
import '../../services/local_storage_service.dart';
import '../../utils/budget_rule_utils.dart';
import '../../utils/money_input.dart';
import '../../utils/recurring_expense_utils.dart';

class AddExpensePage extends StatefulWidget {
  final ExpenseCategory? initialCategory;

  const AddExpensePage({super.key, this.initialCategory});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  ExpenseType type = ExpenseType.fixed;
  late ExpenseCategory category;

  int? dueDay;
  int? cardDueDay;
  bool isCreditCard = false;
  int? installments;
  bool isInstallment = false;
  String? creditCardId;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory ?? ExpenseCategory.moradia;
    if (category == ExpenseCategory.assinaturas) {
      type = ExpenseType.fixed;
    }
    if (category == ExpenseCategory.investment) {
      type = ExpenseType.investment;
    }
    amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _typeColor(ExpenseType t) {
    switch (t) {
      case ExpenseType.fixed:
        return AppTheme.warning;
      case ExpenseType.variable:
        return AppTheme.danger;
      case ExpenseType.investment:
        return AppTheme.info;
    }
  }

  String _typeLabel(ExpenseType t) {
    switch (t) {
      case ExpenseType.fixed:
        return AppStrings.t(context, 'expense_type_fixed');
      case ExpenseType.variable:
        return AppStrings.t(context, 'expense_type_variable');
      case ExpenseType.investment:
        return AppStrings.t(context, 'expense_type_investment');
    }
  }

  String _categoryLabel(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.moradia:
        return AppStrings.t(context, 'expense_category_housing');
      case ExpenseCategory.alimentacao:
        return AppStrings.t(context, 'expense_category_food');
      case ExpenseCategory.transporte:
        return AppStrings.t(context, 'expense_category_transport');
      case ExpenseCategory.educacao:
        return AppStrings.t(context, 'expense_category_education');
      case ExpenseCategory.saude:
        return AppStrings.t(context, 'expense_category_health');
      case ExpenseCategory.lazer:
        return AppStrings.t(context, 'expense_category_leisure');
      case ExpenseCategory.assinaturas:
        return AppStrings.t(context, 'expense_category_subscriptions');
      case ExpenseCategory.investment:
        return AppStrings.t(context, 'expense_category_investment');
      case ExpenseCategory.dividas:
        return 'Dívidas';
      case ExpenseCategory.outros:
        return AppStrings.t(context, 'expense_category_other');
    }
  }

  Widget _sectionShell({
    required Widget child,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.premiumCardDecoration(
        context,
        highlighted: highlighted,
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String eyebrow, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            color: AppTheme.textMuted(context),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _contextTip(IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary(context), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _highExpenseTip() {
    final now = DateTime.now();
    final dashboard = LocalStorageService.getDashboard(now.month, now.year);
    final income =
        dashboard?.salary ?? LocalStorageService.incomeTotalForMonth(now);
    if (income <= 0) return null;

    final amount = parseMoneyInput(amountController.text);
    if (amount <= 0) return null;

    final existingExpenses = dashboard?.expenses ?? const <Expense>[];
    final rule = budgetRuleForEntry(type: type, category: category);
    final projectedTotal = trackedTotalForBudgetRule(
          existingExpenses,
          type: type,
          category: category,
        ) +
        amount;
    final share = projectedTotal / income;
    final pct = share * 100;
    final idealPct = (rule.idealShare * 100).round();
    if (!shouldShowBudgetTip(rule, share)) return null;

    return _contextTip(
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

  Widget _paymentMethodCard({
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
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.07)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.20)
                  : scheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? scheme.primary : scheme.onSurface),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w800,
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

  String _flowTitle() {
    if (type == ExpenseType.investment) return 'Aporte registrado';
    if (isCreditCard) return 'Vai para a fatura';
    return 'Sai do saldo agora';
  }

  String _flowSubtitle() {
    if (type == ExpenseType.investment) {
      return 'Esse valor entra separado do consumo para sua evolução financeira ficar clara.';
    }
    if (isCreditCard) {
      return 'Crédito entra na fatura atual e compromete seu mês imediatamente.';
    }
    return 'Débito reduz seu disponível agora e não aparece na fatura.';
  }

  Color _heroColor() {
    if (type == ExpenseType.investment) return AppTheme.info;
    if (isCreditCard) return Theme.of(context).colorScheme.primary;
    return AppTheme.success;
  }

  void _save() {
    final name = nameController.text.trim();
    final amount = parseMoneyInput(amountController.text);

    if (name.isEmpty) {
      _snack('Digite o nome do gasto. Exemplo: aluguel, mercado ou Uber.');
      return;
    }
    if (amount <= 0) {
      _snack('Digite um valor maior que zero. Exemplo: 250,00.');
      return;
    }
    if (type == ExpenseType.fixed &&
        isCreditCard &&
        isInstallment &&
        (installments == null || installments! < 2 || installments! > 24)) {
      _snack(AppStrings.t(context, 'installments_required'));
      return;
    }
    if (type == ExpenseType.fixed && isCreditCard && isInstallment) {
      final cents = (amount * 100).round();
      if (installments != null && cents < installments!) {
        _snack('O valor é muito baixo para parcelar em tantas vezes.');
        return;
      }
    }

    if (type == ExpenseType.investment) {
      isCreditCard = false;
      dueDay = null;
      cardDueDay = null;
      installments = null;
      isInstallment = false;
      creditCardId = null;
    } else if (type != ExpenseType.fixed) {
      dueDay = null;
      installments = null;
      isInstallment = false;
    }

    if (!isCreditCard || type != ExpenseType.fixed || !isInstallment) {
      installments = null;
    }

    final resolvedCategory =
        type == ExpenseType.investment ? ExpenseCategory.investment : category;

    if (isCreditCard) {
      final user = LocalStorageService.getUserProfile();
      final cards = user?.creditCards ?? [];
      if (cards.isEmpty) {
        _snack(AppStrings.t(context, 'card_required'));
        return;
      }
      final selected = cards.firstWhere(
        (c) => c.id == creditCardId,
        orElse: () => cards.first,
      );
      creditCardId = selected.id;
      cardDueDay = selected.dueDay;
    }

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
      isCardRecurring:
          type == ExpenseType.fixed && isCreditCard && !isInstallment,
      installments: type == ExpenseType.fixed && isCreditCard && isInstallment
          ? installments
          : null,
    );

    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    final isFixed = type == ExpenseType.fixed;
    final isInvestment = type == ExpenseType.investment;
    final showBillDueDay = isFixed && !isCreditCard;
    final showCardControls = !isInvestment && isCreditCard;
    final cards = LocalStorageService.getUserProfile()?.creditCards ?? [];
    final hasCards = cards.isNotEmpty;
    final selectedCard = (hasCards && creditCardId != null)
        ? cards.firstWhere(
            (c) => c.id == creditCardId,
            orElse: () => cards.first,
          )
        : null;
    final selectedCardDueDay = selectedCard?.dueDay ?? cardDueDay;
    final previewValue = parseMoneyInput(amountController.text);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'new_entry'))),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isInvestment)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    isCreditCard
                        ? 'Credito vai para a fatura e compromete o mes. Debito sai do disponivel.'
                        : 'Debito reduz o disponivel agora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(AppStrings.t(context, 'save')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: Responsive.pagePadding(context),
        children: [
          _sectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(context, 'new_entry'),
                  style: TextStyle(
                    color: AppTheme.textMuted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  previewValue > 0
                      ? formatMoneyInput(previewValue)
                      : 'R\$ 0,00',
                  style: TextStyle(
                    color: _heroColor(),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _flowTitle(),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _flowSubtitle(),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAmountChip(
                      label: 'R\$ 50',
                      onTap: () => amountController.text = formatMoneyInput(50),
                    ),
                    _QuickAmountChip(
                      label: 'R\$ 100',
                      onTap: () =>
                          amountController.text = formatMoneyInput(100),
                    ),
                    _QuickAmountChip(
                      label: 'R\$ 300',
                      onTap: () =>
                          amountController.text = formatMoneyInput(300),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  'Essencial',
                  'O que aconteceu?',
                  'Preencha so o essencial. O resto ajuda o app a organizar melhor seu mes.',
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<ExpenseType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo do lançamento',
                  ),
                  items: ExpenseType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      type = v;
                      if (type == ExpenseType.investment) {
                        category = ExpenseCategory.investment;
                        isCreditCard = false;
                        dueDay = null;
                        cardDueDay = null;
                        installments = null;
                        isInstallment = false;
                        creditCardId = null;
                      } else if (category == ExpenseCategory.investment) {
                        category = ExpenseCategory.outros;
                      }
                      if (type != ExpenseType.fixed) {
                        dueDay = null;
                        installments = null;
                        isInstallment = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: type == ExpenseType.investment
                        ? 'Nome do investimento'
                        : AppStrings.t(context, 'name'),
                    hintText: type == ExpenseType.investment
                        ? 'Ex.: Tesouro Selic, CDB, ETF'
                        : 'Ex.: mercado, aluguel, Uber',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [MoneyTextInputFormatter()],
                  decoration: InputDecoration(
                    labelText: AppStrings.t(context, 'value_currency'),
                  ),
                ),
                if (_highExpenseTip() != null) ...[
                  const SizedBox(height: 14),
                  _highExpenseTip()!,
                ],
              ],
            ),
          ),
          if (!isInvestment) ...[
            const SizedBox(height: 18),
            _sectionShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    'Pagamento',
                    'Como isso deve aparecer?',
                    'Aqui o app decide se isso sai do saldo agora ou vai para a fatura.',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _paymentMethodCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Debito',
                        subtitle: 'Sai do saldo na hora.',
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
                      const SizedBox(width: 12),
                      _paymentMethodCard(
                        icon: Icons.credit_card_rounded,
                        title: 'Credito',
                        subtitle: 'Vai para a fatura e conta no mês.',
                        selected: isCreditCard,
                        onTap: () {
                          if (cards.isEmpty) {
                            _snack(AppStrings.t(context, 'card_required'));
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
                  const SizedBox(height: 12),
                  _contextTip(
                    isCreditCard
                        ? Icons.credit_score_outlined
                        : Icons.check_circle_outline_rounded,
                    isCreditCard
                        ? 'Credito entra na fatura atual e ja conta no comprometido do mes.'
                        : 'Debito reduz o saldo disponivel agora e nao aparece na fatura.',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _sectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  'Detalhes',
                  isInvestment
                      ? 'Classificacao do aporte'
                      : 'Contexto do lancamento',
                  isInvestment
                      ? 'O investimento fica separado do consumo para a leitura do mes ficar limpa.'
                      : 'Categoria, vencimento e parcelamento deixam tudo mais claro depois.',
                ),
                const SizedBox(height: 18),
                if (!isInvestment) ...[
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'category'),
                    ),
                    items: ExpenseCategory.values
                        .where(
                          (c) =>
                              c != ExpenseCategory.investment &&
                              (type == ExpenseType.fixed ||
                                  c != ExpenseCategory.assinaturas),
                        )
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(_categoryLabel(c)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 14),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: AppTheme.info),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Categoria: Investimento',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showBillDueDay) ...[
                  DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: dueDay,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'due_day_optional'),
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
                            AppStrings.tr(
                                context, 'day_label', {'n': '${i + 1}'}),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged:
                        isCreditCard ? null : (v) => setState(() => dueDay = v),
                  ),
                  const SizedBox(height: 14),
                ],
                if (showCardControls) ...[
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: hasCards ? creditCardId : null,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'card_select'),
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
                                AppStrings.t(context, 'credit_cards_empty'),
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
                  const SizedBox(height: 10),
                  _contextTip(
                    Icons.calendar_month_outlined,
                    AppStrings.tr(context, 'card_due_day_value', {
                      'day': selectedCardDueDay == null
                          ? '-'
                          : selectedCardDueDay.toString(),
                    }),
                  ),
                ],
                if (isFixed && isCreditCard) ...[
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
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
                    title: const Text('Parcelar'),
                    subtitle: const Text(
                      'Cada parcela entra em uma fatura diferente.',
                    ),
                  ),
                  if (isInstallment) ...[
                    const SizedBox(height: 10),
                    _contextTip(
                      Icons.layers_outlined,
                      'Cada parcela entra em uma fatura. Assim o valor não parece descontado duas vezes no app.',
                    ),
                    const SizedBox(height: 10),
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
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _typeColor(type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _typeLabel(type),
                style: TextStyle(
                  color: _typeColor(type),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
      ),
      avatar: Icon(
        Icons.add_rounded,
        size: 14,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: AppTheme.textPrimary(context),
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: onTap,
    );
  }
}
