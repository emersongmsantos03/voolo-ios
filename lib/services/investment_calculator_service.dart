import '../models/investment.dart';

class InvestmentCalculatorService {
  InvestmentCalculatorService._();

  static Investment createSimulation({
    required double monthlyContribution,
    required double annualInterestRate,
    required int years,
  }) {
    return Investment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      monthlyContribution: monthlyContribution,
      annualInterestRate: annualInterestRate,
      years: years,
      startDate: DateTime.now(),
    );
  }

  static Map<String, double> calculateSummary(Investment investment) {
    return {
      'invested': investment.investedAmount,
      'profit': investment.profit,
      'total': investment.totalAmount,
    };
  }
}
