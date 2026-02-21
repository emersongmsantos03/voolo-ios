import 'dart:math';

import '../../models/debt_v2.dart';

class DebtPlanCalculation {
  final double minimumPaymentsTotal;
  final double monthlyBudgetUsed;
  final double extraBudget;
  final String? estimatedDebtFreeMonthYear;
  final List<String> warnings;
  final List<Map<String, dynamic>> debts;
  final List<Map<String, dynamic>> firstMonthPayments;
  final List<Map<String, dynamic>> scheduleSummary;

  const DebtPlanCalculation({
    required this.minimumPaymentsTotal,
    required this.monthlyBudgetUsed,
    required this.extraBudget,
    required this.estimatedDebtFreeMonthYear,
    required this.warnings,
    required this.debts,
    required this.firstMonthPayments,
    required this.scheduleSummary,
  });

  Map<String, dynamic> toCompactJson() => {
        'minimumPaymentsTotal': minimumPaymentsTotal,
        'monthlyBudgetUsed': monthlyBudgetUsed,
        'extraBudget': extraBudget,
        'estimatedDebtFreeMonthYear': estimatedDebtFreeMonthYear,
        'warnings': warnings,
        'debts': debts,
        'firstMonthPayments': firstMonthPayments,
        'scheduleSummary': scheduleSummary,
      };
}

String _monthKeyFromIndex(int monthIndex) {
  final year = monthIndex ~/ 12;
  final month = (monthIndex % 12) + 1;
  return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
}

int? _monthIndex(String monthYear) {
  final parts = monthYear.split('-');
  if (parts.length != 2) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (y == null || m == null || m < 1 || m > 12) return null;
  return y * 12 + (m - 1);
}

double _round2(double v) => double.parse(v.toStringAsFixed(2));

double _assumedMinPayment(double balance) {
  if (!balance.isFinite || balance <= 0) return 0.0;
  return _round2(max(50.0, balance * 0.03));
}

DebtPlanCalculation computeDebtPlanLocal({
  required String referenceMonth,
  required String method, // avalanche | snowball
  required double monthlyBudget,
  required List<DebtV2> debts,
  int maxMonths = 240,
}) {
  final warnings = <String>[];
  final startIndex = _monthIndex(referenceMonth);
  if (startIndex == null) {
    return DebtPlanCalculation(
      minimumPaymentsTotal: 0,
      monthlyBudgetUsed: monthlyBudget,
      extraBudget: 0,
      estimatedDebtFreeMonthYear: null,
      warnings: const ['Mês inválido. Use YYYY-MM.'],
      debts: const [],
      firstMonthPayments: const [],
      scheduleSummary: const [],
    );
  }

  final normalizedMethod = method.toLowerCase().trim();
  final resolvedMethod =
      (normalizedMethod == 'snowball') ? 'snowball' : 'avalanche';

  // Build internal state.
  final state = debts.where((d) => d.status != 'PAID').map((d) {
    final isInstallment = d.isInstallmentDebt;
    final balance = isInstallment
        ? _round2((d.installmentAmount ?? 0) * (d.remainingInstallments ?? 0))
        : _round2(d.totalAmount);
    final min = isInstallment
        ? ((d.isWithinInstallmentWindow(referenceMonth) &&
                d.paidInstallmentMonths[referenceMonth] != true)
            ? (d.installmentAmount ?? 0.0)
            : 0.0)
        : (d.minPayment ?? _assumedMinPayment(balance));

    final assumed = !isInstallment && d.minPayment == null;

    return {
      'id': d.id,
      'name': d.creditorName,
      'interestRate': d.interestRate ?? 0.0,
      'isInstallment': isInstallment,
      'installmentAmount': d.installmentAmount,
      'installmentTotal': d.installmentTotal,
      'installmentStartMonthYear': d.installmentStartMonthYear,
      'paidInstallments': d.paidInstallmentsCount,
      'remainingInstallments': d.remainingInstallments ?? 0,
      'balance': balance,
      'minPayment': _round2(min),
      'minAssumed': assumed,
    };
  }).toList();

  if (state.isEmpty) {
    return DebtPlanCalculation(
      minimumPaymentsTotal: 0,
      monthlyBudgetUsed: monthlyBudget,
      extraBudget: monthlyBudget,
      estimatedDebtFreeMonthYear: referenceMonth,
      warnings: const [],
      debts: const [],
      firstMonthPayments: const [],
      scheduleSummary: const [],
    );
  }

  int debtSortKey(Map<String, dynamic> d) {
    final isInstallment = d['isInstallment'] == true;
    if (isInstallment) return 1;
    return 0;
  }

  state.sort((a, b) {
    final aType = debtSortKey(a);
    final bType = debtSortKey(b);
    if (aType != bType) return aType.compareTo(bType);

    if (resolvedMethod == 'snowball') {
      final ab = (a['balance'] as num?)?.toDouble() ?? 0.0;
      final bb = (b['balance'] as num?)?.toDouble() ?? 0.0;
      final cmp = ab.compareTo(bb);
      if (cmp != 0) return cmp;
    } else {
      final ar = (a['interestRate'] as num?)?.toDouble() ?? 0.0;
      final br = (b['interestRate'] as num?)?.toDouble() ?? 0.0;
      final cmp = br.compareTo(ar);
      if (cmp != 0) return cmp;
    }

    final ab = (a['balance'] as num?)?.toDouble() ?? 0.0;
    final bb = (b['balance'] as num?)?.toDouble() ?? 0.0;
    return bb.compareTo(ab);
  });

  final firstMonthPayments = <Map<String, dynamic>>[];
  final scheduleSummary = <Map<String, dynamic>>[];

  String? focusDebtId;

  double monthMinTotal() => state.fold(0.0, (sum, d) {
        final min = (d['minPayment'] as num?)?.toDouble() ?? 0.0;
        return sum + max(0.0, min);
      });

  final minTotal = _round2(monthMinTotal());
  final budgetUsed = max(0.0, monthlyBudget);
  final extraBudget = _round2(max(0.0, budgetUsed - minTotal));

  // Month 1 distribution.
  double remainingExtra = extraBudget;
  for (final d in state) {
    final minPay = (d['minPayment'] as num?)?.toDouble() ?? 0.0;
    if (minPay > 0) {
      firstMonthPayments.add({
        'debtId': d['id'],
        'amount': _round2(minPay),
        'kind': 'minimum',
      });
    }
  }

  // Focus debt = first non-installment debt in ordering.
  final focusCandidate = state.firstWhere(
    (d) => d['isInstallment'] != true,
    orElse: () => state.first,
  );
  focusDebtId = focusCandidate['id']?.toString();

  if (remainingExtra > 0) {
    for (final d in state) {
      if (remainingExtra <= 0) break;
      if (d['isInstallment'] == true) continue; // keep installments fixed
      final bal = (d['balance'] as num?)?.toDouble() ?? 0.0;
      if (bal <= 0) continue;
      final pay = _round2(min(remainingExtra, bal));
      remainingExtra = _round2(remainingExtra - pay);
      firstMonthPayments.add({
        'debtId': d['id'],
        'amount': pay,
        'kind': 'extra',
      });
      break;
    }
  }

  // Full simulation (summary only).
  double prevTotalBalance = state.fold(
    0.0,
    (sum, d) => sum + ((d['balance'] as num?)?.toDouble() ?? 0.0),
  );

  int growingStreak = 0;
  int months = 0;

  while (months < maxMonths) {
    final monthIndex = startIndex + months;
    final monthKey = _monthKeyFromIndex(monthIndex);

    double available = budgetUsed;
    double paidThisMonth = 0.0;

    // Minimums first.
    for (final d in state) {
      final isInstallment = d['isInstallment'] == true;
      double minPay = (d['minPayment'] as num?)?.toDouble() ?? 0.0;
      if (months > 0) {
        if (isInstallment) {
          // For future months assume 1 installment per month until depleted.
          final rem = (d['remainingInstallments'] as num?)?.toInt() ?? 0;
          minPay = rem > 0
              ? ((d['installmentAmount'] as num?)?.toDouble() ?? 0.0)
              : 0.0;
          d['minPayment'] = _round2(minPay);
        } else {
          minPay = (d['minPayment'] as num?)?.toDouble() ?? 0.0;
        }
      }

      minPay = max(0.0, minPay);
      if (minPay <= 0) continue;
      if (available <= 0) break;

      final pay = _round2(min(available, minPay));
      available = _round2(available - pay);
      paidThisMonth = _round2(paidThisMonth + pay);
      paidThisMonth = max(0.0, paidThisMonth);

      if (isInstallment) {
        final rem = (d['remainingInstallments'] as num?)?.toInt() ?? 0;
        if (rem > 0 && pay > 0) {
          d['remainingInstallments'] = rem - 1;
          final bal = (d['balance'] as num?)?.toDouble() ?? 0.0;
          d['balance'] = _round2(max(0.0, bal - pay));
        }
      } else {
        final rate = (d['interestRate'] as num?)?.toDouble() ?? 0.0;
        final bal = (d['balance'] as num?)?.toDouble() ?? 0.0;
        final withInterest = _round2(bal * (1 + max(0.0, rate) / 100.0));
        d['balance'] = _round2(max(0.0, withInterest - pay));
      }
    }

    // Extra goes to focus debt (first in ordering with balance).
    if (available > 0) {
      for (final d in state) {
        if (available <= 0) break;
        if (d['isInstallment'] == true) continue;
        final bal = (d['balance'] as num?)?.toDouble() ?? 0.0;
        if (bal <= 0) continue;
        final pay = _round2(min(available, bal));
        available = _round2(available - pay);
        paidThisMonth = _round2(paidThisMonth + pay);

        final rate = (d['interestRate'] as num?)?.toDouble() ?? 0.0;
        final withInterest = _round2(bal * (1 + max(0.0, rate) / 100.0));
        d['balance'] = _round2(max(0.0, withInterest - pay));
        focusDebtId = d['id']?.toString();
        break;
      }
    }

    // Cleanup: debts with zero balance and no remaining installments.
    state.removeWhere((d) {
      final isInstallment = d['isInstallment'] == true;
      final bal = (d['balance'] as num?)?.toDouble() ?? 0.0;
      if (isInstallment) {
        final rem = (d['remainingInstallments'] as num?)?.toInt() ?? 0;
        return rem <= 0 || bal <= 0;
      }
      return bal <= 0;
    });

    scheduleSummary.add({
      'monthYear': monthKey,
      'paidTotal': paidThisMonth,
      'focusDebtId': focusDebtId,
      'remainingDebts': state.length,
    });

    if (state.isEmpty) {
      final estimated = monthKey;
      return DebtPlanCalculation(
        minimumPaymentsTotal: minTotal,
        monthlyBudgetUsed: budgetUsed,
        extraBudget: extraBudget,
        estimatedDebtFreeMonthYear: estimated,
        warnings: warnings,
        debts: debtsToCompactRows(debts, resolvedMethod),
        firstMonthPayments: firstMonthPayments,
        scheduleSummary: scheduleSummary.take(24).toList(),
      );
    }

    final totalBalance = state.fold(
      0.0,
      (sum, d) => sum + ((d['balance'] as num?)?.toDouble() ?? 0.0),
    );
    if (totalBalance > prevTotalBalance + 0.01) {
      growingStreak += 1;
    } else {
      growingStreak = 0;
    }
    prevTotalBalance = totalBalance;

    if (growingStreak >= 6) {
      warnings.add(
        'A simulação está instável (saldo crescendo por vários meses). Considere aumentar o orçamento mensal ou renegociar juros.',
      );
      break;
    }

    months += 1;
  }

  warnings.add('Simulação interrompida por limite de meses ($maxMonths).');
  return DebtPlanCalculation(
    minimumPaymentsTotal: minTotal,
    monthlyBudgetUsed: budgetUsed,
    extraBudget: extraBudget,
    estimatedDebtFreeMonthYear: null,
    warnings: warnings,
    debts: debtsToCompactRows(debts, resolvedMethod),
    firstMonthPayments: firstMonthPayments,
    scheduleSummary: scheduleSummary.take(24).toList(),
  );
}

List<Map<String, dynamic>> debtsToCompactRows(
  List<DebtV2> debts,
  String method,
) {
  final rows = <Map<String, dynamic>>[];
  final open = debts.where((d) => d.status != 'PAID').toList();

  open.sort((a, b) {
    final aIsInst = a.isInstallmentDebt;
    final bIsInst = b.isInstallmentDebt;
    if (aIsInst != bIsInst) return aIsInst ? 1 : -1;

    if (method == 'snowball') {
      final cmp = a.totalAmount.compareTo(b.totalAmount);
      if (cmp != 0) return cmp;
    } else {
      final ar = a.interestRate ?? 0.0;
      final br = b.interestRate ?? 0.0;
      final cmp = br.compareTo(ar);
      if (cmp != 0) return cmp;
    }
    return b.totalAmount.compareTo(a.totalAmount);
  });

  for (var i = 0; i < open.length; i++) {
    final d = open[i];
    final isInstallment = d.isInstallmentDebt;
    final assumed = !isInstallment && d.minPayment == null;
    final minUsed = isInstallment
        ? (d.installmentAmount ?? 0.0)
        : (d.minPayment ?? _assumedMinPayment(d.totalAmount));
    rows.add({
      'order': i + 1,
      'debtId': d.id,
      'creditorName': d.creditorName,
      'totalAmount': d.totalAmount,
      'interestRate': d.interestRate,
      'minPaymentUsed': _round2(minUsed),
      'minPaymentAssumed': assumed,
      'isInstallment': isInstallment,
      'installmentAmount': d.installmentAmount,
      'installmentTotal': d.installmentTotal,
      'installmentDueDay': d.installmentDueDay,
      'paidInstallments': d.paidInstallmentsCount,
    });
  }

  return rows;
}
