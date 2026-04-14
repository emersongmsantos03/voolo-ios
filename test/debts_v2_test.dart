import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/core/utils/money_input.dart';
import 'package:jetx/models/debt_plan_v2.dart';
import 'package:jetx/models/debt_v2.dart';
import 'package:jetx/utils/finance_score_utils.dart';

void main() {
  group('Money input (pt-BR)', () {
    test('parseMoneyInput accepts comma and dot decimals', () {
      expect(parseMoneyInput('1.540,80'), closeTo(1540.80, 1e-9));
      expect(parseMoneyInput('1540.80'), closeTo(1540.80, 1e-9));
      expect(parseMoneyInput('R\$ 1.540,80'), closeTo(1540.80, 1e-9));
    });

    test('formatMoneyInput keeps cents', () {
      expect(formatMoneyInput(1540.8), '1.540,80');
      expect(formatMoneyInput('1540.8'), '1.540,80');
      expect(formatMoneyInput('1540.80'), '1.540,80');
    });
  });

  group('Debt installments', () {
    test('remaining installments uses paidInstallmentMonths count', () {
      final d = DebtV2(
        id: 'd1',
        creditorName: 'Banco',
        totalAmount: 1000,
        interestRate: null,
        minPayment: null,
        isLate: false,
        lateSince: null,
        status: 'ACTIVE',
        kind: 'loan',
        installmentAmount: 100,
        installmentTotal: 10,
        installmentDueDay: 5,
        installmentStartMonthYear: '2026-01',
        paidInstallmentMonths: const {
          '2026-01': true,
          '2026-02': true,
          '2026-03': false,
          '2026-04': true,
        },
        fixedSeriesId: 'debt_d1',
        createdAt: null,
        updatedAt: null,
      );

      expect(d.isInstallmentDebt, true);
      expect(d.paidInstallmentsCount, 3);
      expect(d.remainingInstallments, 7);
    });
  });

  group('Financial score debt penalty', () {
    test('applies 20% penalty when hasOpenDebts', () {
      final base = FinanceScoreUtils.computeFinancialHealthScore(
        income: 5000,
        fixed: 1000,
        variable: 500,
        investContribution: 600,
        housing: 1200,
        hasOpenDebts: false,
      );
      final penalized = FinanceScoreUtils.computeFinancialHealthScore(
        income: 5000,
        fixed: 1000,
        variable: 500,
        investContribution: 600,
        housing: 1200,
        hasOpenDebts: true,
      );

      expect(penalized.score, (base.score * 0.8).round());
      expect(
        penalized.tip,
        contains('Dívidas em aberto reduzem seu score em 20%'),
      );
    });
  });

  group('Debt plan serialization', () {
    test('DebtPlanCompactV2 round-trips', () {
      const plan = DebtPlanCompactV2(
        minimumPaymentsTotal: 300,
        monthlyBudgetUsed: 500,
        extraBudget: 200,
        estimatedDebtFreeMonthYear: '2026-12',
        warnings: ['warn'],
        debts: [
          {
            'order': 1,
            'debtId': 'd1',
            'creditorName': 'Banco',
            'totalAmount': 1000.0,
            'minPaymentUsed': 300.0,
          }
        ],
        firstMonthPayments: [
          {'debtId': 'd1', 'amount': 300.0, 'kind': 'minimum'}
        ],
        scheduleSummary: [
          {'monthYear': '2026-02', 'paidTotal': 500.0, 'remainingDebts': 1}
        ],
      );

      final decoded = DebtPlanCompactV2.fromJson(plan.toJson());
      expect(decoded.minimumPaymentsTotal, plan.minimumPaymentsTotal);
      expect(decoded.extraBudget, plan.extraBudget);
      expect(
          decoded.estimatedDebtFreeMonthYear, plan.estimatedDebtFreeMonthYear);
      expect(decoded.debts.length, 1);
      expect(decoded.firstMonthPayments.length, 1);
      expect(decoded.scheduleSummary.length, 1);
    });
  });
}
