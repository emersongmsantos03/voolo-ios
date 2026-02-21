import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    await showDialog(
      context: context,
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
      text:
          widget.income != null ? widget.income!.amount.toStringAsFixed(2) : '',
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

    final String? activeFrom =
        isVariable ? (widget.income?.activeFrom ?? monthKey) : null;
    final String? activeUntil = isVariable
        ? (widget.income?.activeUntil ?? monthKey)
        : widget.income?.activeUntil;

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
        Navigator.pop(context);
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
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surface,
      title: Text(widget.income == null ? 'Nova Renda' : 'Editar Renda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _saving ? null : () => setState(() => _type = 'fixed'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _type == 'fixed' ? scheme.primary : scheme.outline,
                    ),
                  ),
                  child: Text(
                    'Fixo',
                    style: TextStyle(
                      color: _type == 'fixed'
                          ? scheme.primary
                          : AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _saving ? null : () => setState(() => _type = 'variable'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          _type == 'variable' ? scheme.primary : scheme.outline,
                    ),
                  ),
                  child: Text(
                    'Variável',
                    style: TextStyle(
                      color: _type == 'variable'
                          ? scheme.primary
                          : AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppStrings.t(context, 'income_label_placeholder'),
              hintText: 'Ex: Salário, Freelance',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [MoneyTextInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
            ),
          ),
          if (widget.income != null) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Renda Principal'),
              value: _isPrimary,
              onChanged: widget.income!.isPrimary
                  ? null
                  : (v) => setState(() => _isPrimary = v),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.t(context, 'cancel'),
              style: TextStyle(color: AppTheme.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(AppStrings.t(context, 'save')),
        ),
      ],
    );
  }
}
