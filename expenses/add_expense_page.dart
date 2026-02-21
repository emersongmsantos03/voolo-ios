import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_utils.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  ExpenseType type = ExpenseType.fixed;
  ExpenseCategory category = ExpenseCategory.moradia;

  int? dueDay; // opcional (somente para fixo)

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
        return 'Gasto fixo';
      case ExpenseType.variable:
        return 'Gasto variável';
      case ExpenseType.investment:
        return 'Investimento';
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
      case ExpenseCategory.investment:
        return 'Investimento';
      case ExpenseCategory.outros:
        return 'Outros';
    }
  }

  void _save() {
    final name = nameController.text.trim();
    final amount = CurrencyUtils.parse(amountController.text);

    if (name.isEmpty) {
      _snack('Digite o nome.');
      return;
    }

    if (amount <= 0) {
      _snack('Digite um valor válido.');
      return;
    }

    if (type != ExpenseType.fixed) {
      dueDay = null; // garante consistência
    }
    if (type == ExpenseType.investment) {
      category = ExpenseCategory.investment;
    }

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      category: type == ExpenseType.investment ? ExpenseCategory.investment : category,
      amount: amount,
      date: DateTime.now(),
      dueDay: dueDay,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo lançamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            // Tipo
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo',
                    style: TextStyle(color: Colors.white70),
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
                          dueDay = null;
                        } else if (category == ExpenseCategory.investment) {
                          category = ExpenseCategory.outros;
                        } else if (type != ExpenseType.fixed) {
                          dueDay = null;
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
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),

            // Categoria
            if (type != ExpenseType.investment) ...[
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: ExpenseCategory.values
                    .where((c) => c != ExpenseCategory.investment)
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
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Categoria: Investimento',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

            // Valor
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
            ),

            const SizedBox(height: 16),

            // Vencimento opcional (somente fixo)
            if (isFixed)
              DropdownButtonFormField<int?>(
                initialValue: dueDay,
                decoration: const InputDecoration(
                  labelText: 'Dia de vencimento (opcional)',
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
                      child: Text('Dia ${i + 1}'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => dueDay = v),
              ),

            const SizedBox(height: 28),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Salvar'),
              ),
            ),

            const SizedBox(height: 10),

            // Dica minimalista (opcional)
            Text(
              isFixed
                  ? 'Dica: Se preencher o vencimento, o Jetx avisará 3 dias antes e no dia (quando ativarmos notificações).'
                  : 'Dica: Gastos variáveis contam apenas no mês atual.',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
            ),

            const SizedBox(height: 24),

            // Preview de cor do tipo (visual simples e bonito)
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
