import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardState>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            dashboard.changeMonth(
              dashboard.month - 1,
              dashboard.year,
            );
          },
        ),
        Text(
          '${dashboard.month}/${dashboard.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            dashboard.changeMonth(
              dashboard.month + 1,
              dashboard.year,
            );
          },
        ),
      ],
    );
  }
}
