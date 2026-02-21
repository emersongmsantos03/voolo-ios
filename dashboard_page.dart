import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:jetx/models/expense.dart';
import 'package:jetx/models/monthly_dashboard.dart';
import 'package:jetx/models/user_profile.dart';
import 'package:jetx/routes/app_routes.dart';
import 'package:jetx/services/local_storage_service.dart';
import 'package:jetx/services/notification_service.dart';
import 'package:jetx/theme/app_theme.dart';
import 'package:jetx/utils/currency_utils.dart';
import 'package:jetx/utils/date_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _currentMonth;
  UserProfile? _user;
  MonthlyDashboard? _dashboard;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _load();
  }

  void _load() {
    _user = LocalStorageService.getUserProfile();

    if (_user == null) {
      setState(() {
        _dashboard = null;
      });
      return;
    }

    final existing = LocalStorageService.getDashboard(
      _currentMonth.month,
      _currentMonth.year,
    );

    final base = existing ??
        MonthlyDashboard(
          month: _currentMonth.month,
          year: _currentMonth.year,
          salary: _user!.monthlyIncome,
          expenses: [],
        );

    // garante que salário do mês acompanha renda atual do usuário
    _dashboard = MonthlyDashboard(
      month: base.month,
      year: base.year,
      salary: _user!.monthlyIncome,
      expenses: List.of(base.expenses),
    );

    LocalStorageService.saveDashboard(_dashboard!);
    setState(() {});
  }

  void _changeMonth(int delta) {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    _load();
  }

  void _saveDashboard() {
    if (_dashboard == null) return;
    LocalStorageService.saveDashboard(_dashboard!);
    setState(() {});
  }

  // ====== ADD MENU ======

  Future<void> _openAddMenu() async {
    if (_user == null || _dashboard == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetItem(
                icon: Icons.lock_outline,
                title: 'Adicionar gasto fixo',
                onTap: () {
                  Navigator.pop(context);
                  _openAddExpenseDialog(type: ExpenseType.fixed);
                },
              ),
              _sheetItem(
                icon: Icons.shopping_cart_outlined,
                title: 'Adicionar gasto variável',
                onTap: () {
                  Navigator.pop(context);
                  _openAddExpenseDialog(type: ExpenseType.variable);
                },
              ),
              _sheetItem(
                icon: Icons.savings,
                title: 'Adicionar investimento',
                onTap: () {
                  Navigator.pop(context);
                  _openAddExpenseDialog(type: ExpenseType.investment);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Future<void> _openAddExpenseDialog({required ExpenseType type}) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    int? dueDay;

    final isFixed = type == ExpenseType.fixed;
    final isInvestment = type == ExpenseType.investment;
    ExpenseCategory category = isInvestment ? ExpenseCategory.investment : ExpenseCategory.outros;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          type == ExpenseType.fixed
              ? 'Novo gasto fixo'
              : type == ExpenseType.variable
                  ? 'Novo gasto variável'
                  : 'Novo investimento',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              if (!isInvestment) ...[
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
                  onChanged: (v) => category = v ?? ExpenseCategory.outros,
                ),
                const SizedBox(height: 12),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Categoria: Investimento',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              ),
              if (isFixed) ...[
                const SizedBox(height: 12),
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
                  onChanged: (v) => dueDay = v,
                ),
              ],
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
              final name = nameController.text.trim();
              final amount = CurrencyUtils.parse(amountController.text);

              if (name.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha nome e valor corretamente.')),
                );
                return;
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

              _dashboard!.expenses.add(expense);

              if (expense.isFixed && expense.dueDay != null) {
                NotificationService.scheduleExpenseReminder(expense);
              }

              _saveDashboard();
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
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

  // ====== PIE ======

  List<PieChartSectionData> _sections(MonthlyDashboard d) {
    final fixed = d.fixedExpensesTotal;
    final variable = d.variableExpensesTotal;
    final invest = d.investmentsTotal;
    final free = d.remainingSalary;

    final allZero = fixed <= 0 && variable <= 0 && invest <= 0 && free <= 0;
    if (allZero) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.white12,
          showTitle: false,
          radius: 54,
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: fixed <= 0 ? 0.01 : fixed,
        color: AppTheme.danger,
        showTitle: false,
        radius: 54,
      ),
      PieChartSectionData(
        value: variable <= 0 ? 0.01 : variable,
        color: AppTheme.warning,
        showTitle: false,
        radius: 54,
      ),
      PieChartSectionData(
        value: invest <= 0 ? 0.01 : invest,
        color: AppTheme.info,
        showTitle: false,
        radius: 54,
      ),
      PieChartSectionData(
        value: free <= 0 ? 0.01 : free,
        color: AppTheme.success,
        showTitle: false,
        radius: 54,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Sem usuário
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhum usuário cadastrado.\nCrie uma conta para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    // Enquanto carrega dashboard (evita _dashboard! null)
    if (_dashboard == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final d = _dashboard!;
    final title = DateUtilsJetx.monthYear(_currentMonth);

    return Scaffold(
      drawer: _JetxDrawer(user: _user!),
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _BottomActionRow(
        onGoals: () => Navigator.pushNamed(context, AppRoutes.goals),
        onAdd: _openAddMenu,
        onCalculator: () => Navigator.pushNamed(context, AppRoutes.investmentCalculator),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text('Salário do mês', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              CurrencyUtils.format(d.salary),
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                      sections: _sections(d),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _SummaryRow(
              fixed: d.fixedExpensesTotal,
              variable: d.variableExpensesTotal,
              invest: d.investmentsTotal,
              free: d.remainingSalary,
            ),

            const SizedBox(height: 18),
            const Text('Lançamentos do mês', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),

            if (d.expenses.isEmpty)
              const Text('Nenhum lançamento ainda.', style: TextStyle(color: Colors.white54))
            else
              ...d.expenses.map((e) => _ExpenseTile(expense: e)),
          ],
        ),
      ),
    );
  }
}

// ================= Drawer =================

class _JetxDrawer extends StatelessWidget {
  final UserProfile user;
  const _JetxDrawer({required this.user});

  ImageProvider? _photoProvider() {
    final path = user.photoPath;
    if (path == null || path.isEmpty) return null;
    final f = File(path);
    if (!f.existsSync()) return null;
    return FileImage(f);
  }

  @override
  Widget build(BuildContext context) {
    final img = _photoProvider();

    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.surface),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: img,
                  child: img == null
                      ? const Icon(Icons.person, color: Colors.black, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.profession,
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Perfil', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.white),
            title: const Text('Relatórios', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.monthlyReport);
            },
          ),
        ],
      ),
    );
  }
}

// =============== Bottom action row ===============

class _BottomActionRow extends StatelessWidget {
  final VoidCallback onGoals;
  final VoidCallback onAdd;
  final VoidCallback onCalculator;

  const _BottomActionRow({
    required this.onGoals,
    required this.onAdd,
    required this.onCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: 'goals',
            mini: true,
            backgroundColor: AppTheme.surface,
            foregroundColor: Colors.white,
            onPressed: onGoals,
            child: const Icon(Icons.flag),
          ),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: 'calc',
            mini: true,
            backgroundColor: AppTheme.surface,
            foregroundColor: Colors.white,
            onPressed: onCalculator,
            child: const Icon(Icons.calculate),
          ),
        ],
      ),
    );
  }
}

// =============== Summary row ===============

class _SummaryRow extends StatelessWidget {
  final double fixed;
  final double variable;
  final double invest;
  final double free;

  const _SummaryRow({
    required this.fixed,
    required this.variable,
    required this.invest,
    required this.free,
  });

  Widget _pill(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              CurrencyUtils.format(value),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill('Fixos', fixed, AppTheme.danger),
        const SizedBox(width: 10),
        _pill('Variáveis', variable, AppTheme.warning),
        const SizedBox(width: 10),
        _pill('Invest.', invest, AppTheme.info),
        const SizedBox(width: 10),
        _pill('Livre', free, AppTheme.success),
      ],
    );
  }
}

// =============== Expense tile ===============

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  Color get _color {
    switch (expense.type) {
      case ExpenseType.fixed:
        return AppTheme.danger;
      case ExpenseType.variable:
        return AppTheme.warning;
      case ExpenseType.investment:
        return AppTheme.info;
    }
  }

  String get _typeLabel {
    switch (expense.type) {
      case ExpenseType.fixed:
        return 'Fixo';
      case ExpenseType.variable:
        return 'Variável';
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

  @override
  Widget build(BuildContext context) {
    final due = (expense.isFixed && expense.dueDay != null)
        ? ' • Vence dia ${expense.dueDay}'
        : '';

    return Card(
      elevation: 0,
      child: ListTile(
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        title: Text(expense.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '$_typeLabel • ${_categoryLabel(expense.category)}$due',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          CurrencyUtils.format(expense.amount),
          style: TextStyle(color: _color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

