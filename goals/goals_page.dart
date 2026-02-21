import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../theme/app_colors.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late int selectedYear;

  // ⚠️ Sem banco por enquanto: metas em memória (sessão)
  final List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;

    // Meta "obrigatória" sugerida
    _ensureMandatoryIncomeGoal(selectedYear);
  }

  void _ensureMandatoryIncomeGoal(int year) {
    final exists = _goals.any((g) =>
        g.targetYear == year &&
        g.type == GoalType.income &&
        g.title.toLowerCase().contains('aumentar'));

    if (!exists) {
      _goals.add(
        Goal(
          id: 'income_$year',
          title: 'Aumentar renda',
          type: GoalType.income,
          targetYear: year,
          description: 'Crie um plano para aumentar seu rendimento no ano.',
          completed: false,
        ),
      );
    }
  }

  List<Goal> get _filteredGoals {
    final list = _goals.where((g) => g.targetYear == selectedYear).toList();

    // mantém a obrigatória no ano selecionado
    final hasIncomeGoal = list.any((g) =>
        g.type == GoalType.income &&
        g.title.toLowerCase().contains('aumentar'));

    if (!hasIncomeGoal) {
      _ensureMandatoryIncomeGoal(selectedYear);
      return _goals.where((g) => g.targetYear == selectedYear).toList();
    }

    return list;
  }

  Future<void> _openAddGoal() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    GoalType type = GoalType.personal;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Nova meta',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título da meta'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: GoalType.income,
                    child: Text('Renda / Carreira'),
                  ),
                  DropdownMenuItem(
                    value: GoalType.education,
                    child: Text('Educação'),
                  ),
                  DropdownMenuItem(
                    value: GoalType.personal,
                    child: Text('Pessoal'),
                  ),
                ],
                onChanged: (v) => type = v ?? GoalType.personal,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final desc = descController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Digite um título para a meta.')),
                );
                return;
              }

              // Evita duplicar a meta "Aumentar renda" manualmente
              if (type == GoalType.income &&
                  title.toLowerCase().contains('aumentar renda')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Essa meta já existe como obrigatória do ano.')),
                );
                return;
              }

              setState(() {
                _goals.add(
                  Goal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    type: type,
                    targetYear: selectedYear,
                    description: desc.isEmpty ? '—' : desc,
                    completed: false,
                  ),
                );
              });

              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Color _typeColor(GoalType type) {
    switch (type) {
      case GoalType.income:
        return AppColors.freeBalance;
      case GoalType.education:
        return AppColors.investment;
      case GoalType.personal:
        return AppColors.variableExpense;
    }
  }

  String _typeLabel(GoalType type) {
    switch (type) {
      case GoalType.income:
        return 'Renda';
      case GoalType.education:
        return 'Educação';
      case GoalType.personal:
        return 'Pessoal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = _filteredGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddGoal,
            tooltip: 'Nova meta',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _YearSelector(
              selectedYear: selectedYear,
              onPrev: () => setState(() {
                selectedYear--;
                _ensureMandatoryIncomeGoal(selectedYear);
              }),
              onNext: () => setState(() {
                selectedYear++;
                _ensureMandatoryIncomeGoal(selectedYear);
              }),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: goals.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma meta cadastrada para este ano.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      itemCount: goals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final g = goals[index];
                        final isMandatory = g.id == 'income_${g.targetYear}';

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _typeColor(g.type),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    g.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isMandatory ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isMandatory)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Obrigatória',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${_typeLabel(g.type)} • ${g.description}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            trailing: Checkbox(
                              value: g.completed,
                              onChanged: (v) {
                                setState(() => g.completed = v ?? false);
                              },
                            ),
                            onLongPress: isMandatory
                                ? null
                                : () {
                                    setState(() => _goals.removeWhere((x) => x.id == g.id));
                                  },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),
            Text(
              'Dica: segure uma meta (não obrigatória) para remover.',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int selectedYear;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _YearSelector({
    required this.selectedYear,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            selectedYear.toString(),
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
