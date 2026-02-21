import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../models/credit_card.dart';
import '../../models/expense.dart';
import '../../services/local_storage_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/money_input.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final DateTime _month;
  StreamSubscription<List<Expense>>? _sub;
  List<Expense> _items = const [];
  int _page = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _listen();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listen() {
    _sub?.cancel();
    _sub = LocalStorageService.watchTransactions(_month.month, _month.year)
        .listen((txs) {
      final deduped = _dedupeExpenses(txs);
      deduped.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _items = deduped;
        _page = _page.clamp(1, _totalPages(deduped));
      });
    });
  }

  int _totalPages(List<Expense> items) {
    final total = (items.length / _pageSize).ceil();
    return total <= 0 ? 1 : total;
  }

  List<Expense> _pageItems() {
    final start = (_page - 1) * _pageSize;
    if (start >= _items.length) return const [];
    final end = (start + _pageSize).clamp(0, _items.length);
    return _items.sublist(start, end);
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

  IconData _categoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.moradia:
        return Icons.home_rounded;
      case ExpenseCategory.alimentacao:
        return Icons.local_cafe_rounded;
      case ExpenseCategory.transporte:
        return Icons.local_shipping_rounded;
      case ExpenseCategory.educacao:
        return Icons.school_rounded;
      case ExpenseCategory.saude:
        return Icons.favorite_rounded;
      case ExpenseCategory.lazer:
        return Icons.music_note_rounded;
      case ExpenseCategory.assinaturas:
        return Icons.sell_rounded;
      case ExpenseCategory.investment:
        return Icons.savings_rounded;
      case ExpenseCategory.dividas:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.outros:
        return Icons.more_horiz_rounded;
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

  Color _typeColor(Expense tx) {
    if (tx.type == ExpenseType.fixed) return AppTheme.danger;
    if (tx.type == ExpenseType.variable) return AppTheme.warning;
    return AppTheme.info;
  }

  Future<void> _togglePaid(Expense tx) async {
    final updated = tx.copyWith(isPaid: !tx.isPaid);
    await LocalStorageService.saveExpense(updated);
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

  Future<void> _deleteExpense(Expense tx) async {
    final isInstallment = (tx.installments ?? 0) > 1;
    if (tx.isFixed && !isInstallment) {
      final scope = await _askFixedDeleteScope();
      if (scope == null) return;
      if (scope == 'month') {
        await LocalStorageService.deleteFixedExpenseOnlyThisMonth(
          expense: tx,
          month: _month,
        );
        return;
      }
      if (scope == 'all') {
        await LocalStorageService.deleteFixedExpenseFromThisMonthForward(
          expense: tx,
          fromMonth: _month,
        );
        return;
      }
    }
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('Deseja excluir "${tx.name}"?'),
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
    await LocalStorageService.deleteExpense(tx.id);
  }

  Future<void> _editExpense(Expense expense) async {
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
    if (!mounted) return;

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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Cadastre um cartão primeiro.')),
                          );
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
                                _categoryLabel(c),
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
                      initialValue: cards.isEmpty ? null : creditCardId,
                      decoration: const InputDecoration(
                        labelText: 'Cartão de crédito',
                      ),
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
                        labelText: 'Dia de Vencimento (Opcional)',
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
      if (cards.isEmpty) return;
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
      isPaid: (type != ExpenseType.fixed || isCard) ? true : expense.isPaid,
    );
    await LocalStorageService.saveExpense(updated);
  }

  @override
  Widget build(BuildContext context) {
    final items = _pageItems();
    final totalPages = _totalPages(_items);
    final hasPrev = _page > 1;
    final hasNext = _page < totalPages;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'timeline_title')),
      ),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? _emptyState()
                  : ListView(
                      children: items.map(_transactionTile).toList(),
                    ),
            ),
            const SizedBox(height: 10),
            _paginationFooter(
              page: _page,
              hasPrev: hasPrev,
              hasNext: hasNext,
              onPrev: () =>
                  setState(() => _page = (_page - 1).clamp(1, totalPages)),
              onNext: () =>
                  setState(() => _page = (_page + 1).clamp(1, totalPages)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: Responsive.pagePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.calendar_month_rounded, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.t(context, 'no_entries_found_title'),
              style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.t(context, 'no_entries_found'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(Expense tx) {
    final color = _typeColor(tx);
    final showPaid = tx.type == ExpenseType.fixed && !tx.isCreditCard;

    return InkWell(
      onTap: () => _editExpense(tx),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            if (showPaid) ...[
              Checkbox(
                value: tx.isPaid,
                onChanged: (_) => _togglePaid(tx),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_categoryIcon(tx.category), color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.name,
                    style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(
                          icon: Icons.tag_rounded,
                          text: _categoryLabel(tx.category)),
                      if (tx.dueDay != null)
                        _badge(
                          icon: Icons.calendar_month_rounded,
                          text: '${AppStrings.t(context, 'day')} ${tx.dueDay}',
                        ),
                      if (tx.isCreditCard)
                        _badge(
                            icon: Icons.credit_card_rounded,
                            text: AppStrings.t(context, 'card')),
                      if ((tx.installments ?? 0) > 1)
                        _badge(
                          icon: Icons.layers_rounded,
                          text:
                              '${tx.installmentIndex ?? 1}/${tx.installments}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.format(tx.amount),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (showPaid && tx.isPaid)
                  Text(
                    AppStrings.t(context, 'paid'),
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 6),
                IconButton(
                  onPressed: () => _editExpense(tx),
                  icon: Icon(Icons.edit_outlined,
                      color: AppTheme.textMuted(context)),
                  tooltip: AppStrings.t(context, 'edit_entry'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                ),
                IconButton(
                  onPressed: () => _deleteExpense(tx),
                  icon: Icon(Icons.delete_outline,
                      color: AppTheme.textMuted(context)),
                  tooltip: AppStrings.t(context, 'delete_entry'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationFooter({
    required int page,
    required bool hasPrev,
    required bool hasNext,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: hasPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.25)),
          ),
          child: Text(
            '$page',
            style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: hasNext ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
