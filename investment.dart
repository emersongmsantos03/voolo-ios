class Investment {
  final String id;
  final double monthlyContribution;
  final double annualInterestRate;
  final int years;
  final DateTime startDate;

  Investment({
    required this.id,
    required this.monthlyContribution,
    required this.annualInterestRate,
    required this.years,
    required this.startDate,
  });

  /// Juros compostos com aporte mensal
  double get totalAmount {
    final monthlyRate = annualInterestRate / 12 / 100;
    final months = years * 12;

    double total = 0;
    for (int i = 0; i < months; i++) {
      total = (total + monthlyContribution) * (1 + monthlyRate);
    }
    return total;
  }

  double get investedAmount => monthlyContribution * years * 12;
  double get profit => totalAmount - investedAmount;
}
