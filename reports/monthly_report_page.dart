import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/monthly_dashboard.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  late DateTime _currentMonth;
  MonthlyDashboard? _dashboard;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _load();
  }

  void _load() {
    _dashboard = LocalStorageService.getDashboard(_currentMonth.month, _currentMonth.year);
    setState(() {});
  }

  void _changeMonth(int delta) {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    _load();
  }

  List<Expense> get _fixedExpenses =>
      (_dashboard?.expenses ?? []).where((e) => e.type == ExpenseType.fixed).toList();

  List<Expense> get _variableExpenses =>
      (_dashboard?.expenses ?? []).where((e) => e.type == ExpenseType.variable).toList();

  double get _fixedTotal => _fixedExpenses.fold(0, (a, b) => a + b.amount);
  double get _variableTotal => _variableExpenses.fold(0, (a, b) => a + b.amount);
  double get _total => _fixedTotal + _variableTotal;

  @override
  Widget build(BuildContext context) {
    final title = DateUtilsJetx.monthYear(_currentMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório mensal'),
        actions: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mês anterior',
          ),
          Center(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo mês',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _dashboard == null
            ? const Center(
                child: Text(
                  'Nenhum dado encontrado para este mês.',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: [
                  Text(
                    'Gastos do mês',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          title: 'Fixos',
                          value: CurrencyUtils.format(_fixedTotal),
                          color: AppColors.fixedExpense,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          title: 'Variáveis',
                          value: CurrencyUtils.format(_variableTotal),
                          color: AppColors.variableExpense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _summaryCard(
                    title: 'Total de gastos',
                    value: CurrencyUtils.format(_total),
                    color: Colors.white,
                  ),

                  const SizedBox(height: 18),
                  _barChart(),

                  const SizedBox(height: 18),
                  const Text(
                    'Detalhamento',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),

                  _section(
                    title: 'Gastos fixos',
                    color: AppColors.fixedExpense,
                    items: _fixedExpenses,
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title: 'Gastos variáveis',
                    color: AppColors.variableExpense,
                    items: _variableExpenses,
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Dica: para remover um lançamento, faça isso na tela do Dashboard (por enquanto).',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _barChart() {
    // Gráfico simples: Fixos vs Variáveis
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: SizedBox(
        height: 170,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final label = value == 0 ? 'Fixos' : 'Variáveis';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: _fixedTotal <= 0 ? 0.5 : _fixedTotal,
                    color: AppColors.fixedExpense,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: _variableTotal <= 0 ? 0.5 : _variableTotal,
                    color: AppColors.variableExpense,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Color color,
    required List<Expense> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Nenhum lançamento.', style: TextStyle(color: Colors.white54))
          else
            ...items.map((e) => _itemTile(e)),
        ],
      ),
    );
  }

  Widget _itemTile(Expense e) {
    final due = (e.type == ExpenseType.fixed && e.dueDay != null) ? ' • vence dia ${e.dueDay}' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${e.name}$due',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyUtils.format(e.amount),
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
