import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../app_theme/app_colors.dart';

class PieChartWidget extends StatelessWidget {
  const PieChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardState>().dashboard;

    if (dashboard == null) {
      return const SizedBox.shrink();
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          _section(dashboard.fixedExpensesTotal, AppColors.red),
          _section(dashboard.variableExpensesTotal, AppColors.yellow),
          _section(dashboard.totalInvested, AppColors.blue),
          _section(dashboard.balance, AppColors.green),
        ],
      ),
    );
  }

  PieChartSectionData _section(double value, Color color) {
    return PieChartSectionData(
      value: value <= 0 ? 0.01 : value,
      color: color,
      radius: 50,
      showTitle: false,
    );
  }
}
