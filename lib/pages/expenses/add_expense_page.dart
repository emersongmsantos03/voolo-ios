import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/expense.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
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

  int? dueDay; // opcional (somente para fixo)
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

  Color _typeColor(ExpenseType t) {
    switch (t) {
      case ExpenseType.fixed:
        return AppColors.fixedExpense;
      case ExpenseType.variable:
        return AppColors.variableExpense;
      case ExpenseType.investment:
        return AppColors.investment;
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

  Widget _contextTip(IconData icon, String text) {
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

  Widget? _highExpenseTip() {
    final user = LocalStorageService.getUserProfile();
    if (user == null || user.monthlyIncome <= 0) return null;

    final amount = parseMoneyInput(amountController.text);
    if (amount <= 0) return null;

    final pct = (amount / user.monthlyIncome) * 100;

    final idealPct = type == ExpenseType.investment
        ? 25
        : category == ExpenseCategory.moradia
            ? 35
            : 10;
    if (pct < idealPct) return null;

    return _contextTip(
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

  void _save() {
    final name = nameController.text.trim();
    final amount = parseMoneyInput(amountController.text);

    if (name.isEmpty) {
      _snack('Digite o nome do gasto. Exemplo: Aluguel, Mercado, Uber.');
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
      final selected = cards.firstWhere((c) => c.id == creditCardId,
          orElse: () => cards.first);
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    final isFixed = type == ExpenseType.fixed;
    final isInvestment = type == ExpenseType.investment;
    final showBillDueDay = isFixed;
    final showCardControls = !isInvestment;
    final cards = LocalStorageService.getUserProfile()?.creditCards ?? [];
    final hasCards = cards.isNotEmpty;
    final selectedCard = (hasCards && creditCardId != null)
        ? cards.firstWhere(
            (c) => c.id == creditCardId,
            orElse: () => cards.first,
          )
        : null;
    final selectedCardDueDay = selectedCard?.dueDay ?? cardDueDay;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'new_entry')),
      ),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preencha 3 itens para salvar: tipo, nome e valor. O resto e opcional.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tipo
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, 'type'),
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ExpenseType>(
                    initialValue: type,
                    decoration: const InputDecoration(),
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
                        }
                        if (type == ExpenseType.investment) {
                          isCreditCard = false;
                          dueDay = null;
                          cardDueDay = null;
                          installments = null;
                          isInstallment = false;
                          creditCardId = null;
                        } else if (category == ExpenseCategory.investment) {
                          category = ExpenseCategory.outros;
                        } else if (type != ExpenseType.fixed) {
                          dueDay = null;
                          installments = null;
                          isInstallment = false;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nome
            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: AppStrings.t(context, 'name')),
            ),
            const SizedBox(height: 16),

            // Categoria (nao se aplica a investimentos)
            if (!isInvestment) ...[
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: category,
                decoration: InputDecoration(
                    labelText: AppStrings.t(context, 'category')),
                items: ExpenseCategory.values
                    .where((c) =>
                        c != ExpenseCategory.investment &&
                        (type == ExpenseType.fixed ||
                            c != ExpenseCategory.assinaturas))
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(_categoryLabel(c)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? category),
              ),
              const SizedBox(height: 16),
            ],

            // Valor
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [MoneyTextInputFormatter()],
              decoration: InputDecoration(
                  labelText: AppStrings.t(context, 'value_currency')),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _QuickAmountChip(
                  label: 'R\$ 50',
                  onTap: () => amountController.text = formatMoneyInput(50),
                ),
                _QuickAmountChip(
                  label: 'R\$ 100',
                  onTap: () => amountController.text = formatMoneyInput(100),
                ),
                _QuickAmountChip(
                  label: 'R\$ 300',
                  onTap: () => amountController.text = formatMoneyInput(300),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_highExpenseTip() != null) _highExpenseTip()!,

            const SizedBox(height: 16),

            // Vencimento opcional (somente fixo)
            if (showBillDueDay)
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
                        AppStrings.tr(context, 'day_label', {'n': '${i + 1}'}),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged:
                    isCreditCard ? null : (v) => setState(() => dueDay = v),
              ),
            if (showCardControls) ...[
              const SizedBox(height: 10),
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
              const SizedBox(height: 6),
              Text(
                AppStrings.tr(
                  context,
                  'card_due_day_value',
                  {
                    'day': selectedCardDueDay == null
                        ? '-'
                        : selectedCardDueDay.toString(),
                  },
                ),
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ],

            if (isFixed || (!isInvestment && !isFixed)) ...[
              const SizedBox(height: 14),
              SwitchListTile(
                value: isCreditCard,
                onChanged: (v) {
                  if (v && cards.isEmpty) {
                    _snack(AppStrings.t(context, 'card_required'));
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
                      cardDueDay = selected.dueDay;
                    } else {
                      creditCardId = null;
                      cardDueDay = null;
                      isInstallment = false;
                      installments = null;
                    }
                    if (!isCreditCard) {
                      isInstallment = false;
                      installments = null;
                    }
                  });
                },
                title: Text(AppStrings.t(context, 'credit_card_charge')),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
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
            ],

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
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
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
                  decoration: InputDecoration(
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

            const SizedBox(height: 28),

            // Botao salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                ),
                child: Text(AppStrings.t(context, 'save')),
              ),
            ),

            const SizedBox(height: 24),

            // Preview de cor do tipo (visual simples e bonito)
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
                  _typeLabel(type),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
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
      label: Text(label),
      avatar: const Icon(Icons.flash_on, size: 16),
      onPressed: onTap,
    );
  }
}
