import 'dart:math';

class HealthScoreResult {
  final int score;
  final String status; // excellent, good, attention, critical
  final String tip;
  final bool needsIncome;
  final String? tipKey;
  final Map<String, String> tipArgs;
  final bool hasDebtPenalty;

  HealthScoreResult({
    required this.score,
    required this.status,
    required this.tip,
    this.needsIncome = false,
    this.tipKey,
    this.tipArgs = const <String, String>{},
    this.hasDebtPenalty = false,
  });
}

class FinanceScoreUtils {
  static HealthScoreResult computeFinancialHealthScore({
    required double income,
    required double fixed,
    required double variable,
    required double investContribution,
    bool hasOpenDebts = false,
    double housing = 0.0,
    double? investBalance,
    double propertyValue = 0.0,
  }) {
    int clampInt(int n, int minValue, int maxValue) =>
        min(maxValue, max(minValue, n));

    double clampDouble(double n, double minValue, double maxValue) =>
        min(maxValue, max(minValue, n));

    String pct(double ratio) => '${(ratio * 100).round()}%';

    if (!income.isFinite || income <= 0) {
      return HealthScoreResult(
        score: 0,
        status: 'critical',
        tip: 'Register your income to calculate your financial health.',
        needsIncome: true,
        tipKey: 'score_tip_add_income',
      );
    }

    const targets = (
      housingMax: 0.35,
      fixedMax: 0.50,
      variableMax: 0.30,
      investMin: 0.10,
      bufferMin: 0.10,
    );

    final totalSpent = fixed + variable + investContribution;
    final leftover = income - totalSpent;
    final leftoverRate = leftover / income;

    final housingRatio = housing / income;
    final fixedRatio = fixed / income;
    final variableRatio = variable / income;
    final investRatio = investContribution / income;

    // Hard fail: spending above income.
    if (leftover < 0) {
      final overspendRate = leftoverRate.abs();
      final score = clampInt((30 - overspendRate * 120).round(), 0, 30);
      return HealthScoreResult(
        score: score,
        status: 'critical',
        tip:
            'Your spending exceeded your income (${pct(overspendRate)} over). Cut variable expenses first and renegotiate fixed costs.',
        needsIncome: false,
        tipKey: 'score_tip_overspending',
        tipArgs: {'pct': pct(overspendRate)},
        hasDebtPenalty: hasOpenDebts,
      );
    }

    double score = 100;

    // Buffer / breathing room
    if (leftoverRate < targets.bufferMin) {
      final lack = (targets.bufferMin - leftoverRate) / targets.bufferMin;
      score -= clampDouble(lack * 18, 0, 18);
    }

    // Over-target penalties
    final housingOver = max(0.0, housingRatio - targets.housingMax);
    final fixedOver = max(0.0, fixedRatio - targets.fixedMax);
    final variableOver = max(0.0, variableRatio - targets.variableMax);

    score -= clampDouble(housingOver * 55, 0, 18);
    score -= clampDouble(fixedOver * 50, 0, 16);
    score -= clampDouble(variableOver * 50, 0, 16);

    // Investment shortfall (keep it softer than overspending/buffer)
    if (investRatio < targets.investMin) {
      final short = (targets.investMin - investRatio) / targets.investMin;
      score -= clampDouble(short * 10, 0, 10);
    }

    final baseScore = clampInt(score.round(), 0, 100);
    final debtPenaltyFactor = hasOpenDebts ? 0.8 : 1.0;
    final resultScore =
        clampInt((baseScore * debtPenaltyFactor).round(), 0, 100);

    String status = 'critical';
    if (resultScore >= 80) {
      status = 'excellent';
    } else if (resultScore >= 60) {
      status = 'good';
    } else if (resultScore >= 40) {
      status = 'attention';
    }

    // Tip priority: most actionable first
    var tip = 'Good balance. Keep consistency and review your budget monthly.';
    var tipKey = 'score_tip_balanced';
    var tipArgs = <String, String>{};

    if (leftoverRate < targets.bufferMin) {
      tip =
          'Your budget is tight. Try to keep at least ${pct(targets.bufferMin)} as monthly buffer.';
      tipKey = 'score_tip_budget_tight';
      tipArgs = {'pct': pct(targets.bufferMin)};
    } else if (housingRatio > targets.housingMax) {
      tip =
          'Housing is high. Try to keep it up to ${pct(targets.housingMax)} of your income (rent/mortgage/condo).';
      tipKey = 'score_tip_housing_high';
      tipArgs = {'pct': pct(targets.housingMax)};
    } else if (variableRatio > targets.variableMax) {
      tip =
          'Variable expenses are high. Set a cap up to ${pct(targets.variableMax)} of income this month.';
      tipKey = 'score_tip_variable_high';
      tipArgs = {'pct': pct(targets.variableMax)};
    } else if (fixedRatio > targets.fixedMax) {
      tip =
          'Fixed costs are high. Try reducing to up to ${pct(targets.fixedMax)} of income through cuts and renegotiation.';
      tipKey = 'score_tip_fixed_high';
      tipArgs = {'pct': pct(targets.fixedMax)};
    } else if (investRatio == 0) {
      tip =
          'You are balanced, but investing adds more resilience (target: ${pct(targets.investMin)} of income).';
      tipKey = 'score_tip_invest_zero';
      tipArgs = {'pct': pct(targets.investMin)};
    } else if (investRatio < targets.investMin) {
      tip =
          'Increase your investments to around ${pct(targets.investMin)} of income to strengthen your score.';
      tipKey = 'score_tip_invest_low';
      tipArgs = {'pct': pct(targets.investMin)};
    }

    final finalTip = hasOpenDebts
        ? '$tip\n\nOpen debts reduce your score by 20% until paid off.'
        : tip;

    return HealthScoreResult(
      score: resultScore,
      status: status,
      tip: finalTip,
      needsIncome: false,
      tipKey: tipKey,
      tipArgs: tipArgs,
      hasDebtPenalty: hasOpenDebts,
    );
  }

  static String localizeTip(
    HealthScoreResult result, {
    required String Function(String key, Map<String, String> params) tr,
  }) {
    final base =
        result.tipKey == null ? result.tip : tr(result.tipKey!, result.tipArgs);
    if (!result.hasDebtPenalty) return base;
    return '$base\n\n${tr('score_tip_debt_penalty', const <String, String>{})}';
  }
}
