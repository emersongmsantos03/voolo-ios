import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/utils/finance_score_utils.dart';

void main() {
  group('FinanceScoreUtils business thresholds', () {
    test('uses 30% for housing and 25% for variable spending', () {
      final housingHigh = FinanceScoreUtils.computeFinancialHealthScore(
        income: 10000,
        fixed: 3000,
        variable: 1000,
        investContribution: 1500,
        housing: 3100,
      );
      final variableHigh = FinanceScoreUtils.computeFinancialHealthScore(
        income: 10000,
        fixed: 3000,
        variable: 2600,
        investContribution: 1500,
        housing: 2000,
      );

      expect(housingHigh.tipKey, 'score_tip_housing_high');
      expect(housingHigh.tipArgs['pct'], '30%');
      expect(variableHigh.tipKey, 'score_tip_variable_high');
      expect(variableHigh.tipArgs['pct'], '25%');
    });

    test('uses 15% as ideal floor for investments', () {
      final investLow = FinanceScoreUtils.computeFinancialHealthScore(
        income: 10000,
        fixed: 3000,
        variable: 1500,
        investContribution: 1400,
        housing: 2000,
      );

      expect(investLow.tipKey, 'score_tip_invest_low');
      expect(investLow.tipArgs['pct'], '15%');
    });
  });
}
