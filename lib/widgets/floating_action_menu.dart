import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class FloatingActionMenu extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onGoals;
  final VoidCallback onInvestments;

  const FloatingActionMenu({
    super.key,
    required this.onAddExpense,
    required this.onGoals,
    required this.onInvestments,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _button(Icons.flag, onGoals),
          FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: onAddExpense,
            child: const Icon(Icons.add),
          ),
          _button(Icons.calculate, onInvestments),
        ],
      ),
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) {
    return FloatingActionButton(
      mini: true,
      onPressed: onTap,
      child: Icon(icon),
    );
  }
}
