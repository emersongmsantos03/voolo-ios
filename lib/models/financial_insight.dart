enum NextBestAction {
  createGoal,
  adjustSpend,
  simulateInvestment,
  addExpense,
  none,
}

class FinancialInsight {
  final String message;
  final NextBestAction action;
  final String actionLabel;

  FinancialInsight({
    required this.message,
    required this.action,
    required this.actionLabel,
  });
}
