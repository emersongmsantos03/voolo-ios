import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../models/income_source.dart';
import '../../services/local_storage_service.dart';
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
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  bool _isPrimary = false;
  bool _saving = false;
  String _type = 'fixed';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.income?.title ?? '');
    _amountController = TextEditingController(
      text: widget.income != null ? formatMoneyInput(widget.income!.amount) : '',
    );
    _isPrimary = widget.income?.isPrimary ?? false;
    _type = (widget.income?.type ?? 'fixed').isEmpty
        ? 'fixed'
        : (widget.income?.type ?? 'fixed');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final amount = parseMoneyInput(_amountController.text);

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha o nome e o valor corretamente.')),
      );
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final monthKey = _monthKey(now);
    final isVariable = _type == 'variable';

    final String? activeFrom = isVariable ? monthKey : null;
    final String? activeUntil = isVariable ? monthKey : null;

    final income = IncomeSource(
      id: widget.income?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      type: _type,
      isPrimary: _isPrimary,
      isActive: widget.income?.isActive ?? true,
      activeFrom: activeFrom,
      activeUntil: activeUntil,
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
          const SnackBar(content: Text('Erro ao salvar renda.')),
        );
      }
    }
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final isFixed = _type == 'fixed';
    final infoBg = isFixed
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12);
    final infoBorder = isFixed
        ? Colors.green.withValues(alpha: 0.35)
        : Colors.orange.withValues(alpha: 0.35);
    final infoIcon = isFixed ? Icons.event_repeat : Icons.calendar_month;
    final infoTitle = isFixed ? 'Renda Fixa' : 'Renda Variavel';
    final infoText = isFixed
        ? 'Esta renda sera replicada automaticamente para os proximos meses.'
        : 'Esta renda sera considerada somente no mes atual.';

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.income == null ? 'Nova renda' : 'Editar renda',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'fixed',
                        icon: Icon(Icons.lock_outline),
                        label: Text('Fixa'),
                      ),
                      ButtonSegment<String>(
                        value: 'variable',
                        icon: Icon(Icons.show_chart),
                        label: Text('Variavel'),
                      ),
                    ],
                    selected: <String>{_type},
                    onSelectionChanged: _saving
                        ? null
                        : (selection) {
                            setState(() {
                              _type = selection.first;
                            });
                          },
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      key: ValueKey<String>(_type),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: infoBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: infoBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(infoIcon, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  infoTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  infoText,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary(context),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'income_label_placeholder'),
                      hintText: 'Ex: Salario, Freelance',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [MoneyTextInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Valor mensal',
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                    ),
                  ),
                  if (widget.income != null) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Renda Principal'),
                      value: _isPrimary,
                      onChanged: (widget.income!.isPrimary || _saving)
                          ? null
                          : (v) => setState(() => _isPrimary = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(AppStrings.t(context, 'cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text(AppStrings.t(context, 'save')),
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
}
