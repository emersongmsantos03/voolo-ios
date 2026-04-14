import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/utils/sensitive_display.dart';
import '../../models/income_source.dart';
import '../../services/local_storage_service.dart';
import '../../utils/income_category_utils.dart';
import '../../utils/money_input.dart';

class IncomeModal extends StatefulWidget {
  final IncomeSource? income;

  const IncomeModal({super.key, this.income});

  static Future<void> show(BuildContext context, {IncomeSource? income}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomeModal(income: income),
    );
  }

  @override
  State<IncomeModal> createState() => _IncomeModalState();
}

class _IncomeModalState extends State<IncomeModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  String _category = IncomeCategoryUtils.salary;
  String? _editingId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _editingId = widget.income?.id;
    _titleController = TextEditingController(text: widget.income?.title ?? '');
    _amountController = TextEditingController(
      text:
          widget.income != null ? formatMoneyInput(widget.income!.amount) : '',
    );
    _category = IncomeCategoryUtils.normalize(widget.income?.type ?? _category);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  List<IncomeSource> _monthIncomes() {
    final month = DateTime.now();
    final incomes = LocalStorageService.getIncomes()
        .where((income) => income.appliesToMonth(month))
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return incomes;
  }

  void _loadIncome(IncomeSource income) {
    setState(() {
      _editingId = income.id;
      _titleController.text = income.title;
      _amountController.text = formatMoneyInput(income.amount);
      _category = IncomeCategoryUtils.normalize(income.type);
    });
  }

  Future<void> _removeIncome(IncomeSource income) async {
    final ok = await LocalStorageService.deleteIncome(income.id);
    if (!mounted) return;
    if (ok) {
      if (_editingId == income.id) {
        setState(() {
          _editingId = null;
          _titleController.clear();
          _amountController.clear();
          _category = IncomeCategoryUtils.salary;
        });
      }
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.t(context, 'income_modal_error_save'))),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final amount = parseMoneyInput(_amountController.text);
    final resolvedTitle =
        title.isEmpty ? IncomeCategoryUtils.label(context, _category) : title;

    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(context, 'income_modal_error_fill')),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final monthKey = _monthKey(now);
    final income = IncomeSource(
      id: _editingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: resolvedTitle,
      amount: amount,
      type: IncomeCategoryUtils.normalize(_category),
      isPrimary: false,
      isActive: widget.income?.isActive ?? true,
      activeFrom: monthKey,
      activeUntil: monthKey,
      excludedMonths: widget.income?.excludedMonths ?? const [],
      createdAt: widget.income?.createdAt ?? DateTime.now(),
    );

    final ok = await LocalStorageService.saveIncome(income);

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(context, 'income_modal_error_save')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final total = LocalStorageService.incomeTotalForMonth(DateTime.now());
    final incomes = _monthIncomes();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF151515),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.yellow.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.yellow.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppTheme.yellow,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minhas entradas',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cada entrada só vale para este mês.',
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: AppStrings.t(context, 'close'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL MENSAL',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          SensitiveDisplay.money(context, total),
                          style: TextStyle(
                            color: AppTheme.yellow,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (incomes.isNotEmpty)
                    ...incomes.map(
                      (income) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _loadIncome(income),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: income.id == _editingId
                                    ? AppTheme.yellow.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayTitle(context, income),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        SensitiveDisplay.money(
                                          context,
                                          income.amount,
                                        ),
                                        style: TextStyle(
                                          color:
                                              AppTheme.textSecondary(context),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.yellow.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppTheme.yellow.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        IncomeCategoryUtils.icon(income.type),
                                        size: 16,
                                        color: AppTheme.yellow,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        IncomeCategoryUtils.label(
                                          context,
                                          income.type,
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.yellow,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _loadIncome(income),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: AppStrings.t(context, 'edit_short'),
                                ),
                                IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _removeIncome(income),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Excluir entrada',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Categoria da entrada',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecione uma categoria.',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: const Color(0xFF171717),
                    iconEnabledColor: AppTheme.textSecondary(context),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.yellow.withValues(alpha: 0.8),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    items: IncomeCategoryUtils.all
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppTheme.yellow.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    IncomeCategoryUtils.icon(category),
                                    color: AppTheme.yellow,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  IncomeCategoryUtils.label(context, category),
                                  style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _category = value);
                          },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Nome da entrada',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Ex: Salário, Freelance...',
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.yellow.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Valor (R\$)',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '0,00',
                      prefixText: 'R\$ ',
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.yellow.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: AppTheme.textPrimary(context),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(AppStrings.t(context, 'cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.yellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  AppStrings.t(context, 'save'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayTitle(BuildContext context, IncomeSource income) {
    final title = income.title.trim();
    if (title.isEmpty) {
      return IncomeCategoryUtils.label(context, income.type);
    }
    if (title.toLowerCase() == 'renda principal' ||
        income.id == 'main_income') {
      return IncomeCategoryUtils.label(context, income.type);
    }
    return title;
  }
}
