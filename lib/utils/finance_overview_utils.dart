import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/credit_card.dart';
import '../models/expense.dart';

double _roundMoney(double value) {
  return double.parse(value.toStringAsFixed(2));
}

class FinanceCardOverview {
  final String cardId;
  final String name;
  final int? dueDay;
  final double invoiceTotal;
  final double installmentsInInvoice;
  final bool isPaid;

  const FinanceCardOverview({
    required this.cardId,
    required this.name,
    required this.dueDay,
    required this.invoiceTotal,
    required this.installmentsInInvoice,
    required this.isPaid,
  });
}

class FinanceOverview {
  final double salary;
  final double debitSpent;
  final double creditSpent;
  final double invested;
  final double immediateOutflow;
  final double availableNow;
  final double projectedAfterInvoices;
  final double currentInvoice;
  final double openInvoice;
  final double totalCommitted;
  final double installmentBurden;
  final int debitCount;
  final int creditCount;
  final int investmentCount;
  final List<FinanceCardOverview> cards;

  const FinanceOverview({
    required this.salary,
    required this.debitSpent,
    required this.creditSpent,
    required this.invested,
    required this.immediateOutflow,
    required this.availableNow,
    required this.projectedAfterInvoices,
    required this.currentInvoice,
    required this.openInvoice,
    required this.totalCommitted,
    required this.installmentBurden,
    required this.debitCount,
    required this.creditCount,
    required this.investmentCount,
    required this.cards,
  });

  bool get hasCreditSpending => creditSpent > 0;
  bool get hasOpenInvoice => openInvoice > 0;

  double get creditShareOfCommitments {
    if (totalCommitted <= 0) return 0;
    return creditSpent / totalCommitted;
  }
}

FinanceOverview buildFinanceOverview({
  required double salary,
  required List<Expense> expenses,
  List<CreditCard> cards = const [],
  Map<String, bool> creditCardPayments = const {},
}) {
  var debitSpent = 0.0;
  var creditSpent = 0.0;
  var invested = 0.0;
  var immediateOutflow = 0.0;
  var installmentBurden = 0.0;
  var debitCount = 0;
  var creditCount = 0;
  var investmentCount = 0;

  final cardById = {for (final card in cards) card.id: card};
  final cardTotals = <String, double>{};
  final installmentsByCard = <String, double>{};

  for (final expense in expenses) {
    if (expense.isInvestment) {
      invested += expense.amount;
      immediateOutflow += expense.amount;
      investmentCount += 1;
      continue;
    }

    if (expense.isCreditCard) {
      creditSpent += expense.amount;
      creditCount += 1;

      final cardId =
          (expense.creditCardId == null || expense.creditCardId!.trim().isEmpty)
              ? 'unknown'
              : expense.creditCardId!.trim();
      cardTotals[cardId] = (cardTotals[cardId] ?? 0) + expense.amount;

      if ((expense.installments ?? 0) > 1) {
        installmentBurden += expense.amount;
        installmentsByCard[cardId] =
            (installmentsByCard[cardId] ?? 0) + expense.amount;
      }
      continue;
    }

    debitSpent += expense.amount;
    immediateOutflow += expense.amount;
    debitCount += 1;
  }

  var openInvoice = 0.0;
  for (final entry in cardTotals.entries) {
    final isPaid = creditCardPayments[entry.key] ?? false;
    if (!isPaid) openInvoice += entry.value;
  }

  final currentInvoice = creditSpent;
  final totalCommitted = immediateOutflow + creditSpent;
  final availableNow = salary - totalCommitted;
  final projectedAfterInvoices = availableNow;

  final usedCardIds = {...cardById.keys, ...cardTotals.keys}.toList()..sort();
  final cardOverviews = usedCardIds.map((cardId) {
    final card = cardById[cardId];
    return FinanceCardOverview(
      cardId: cardId,
      name: card?.name ?? 'Cartao',
      dueDay: card?.dueDay,
      invoiceTotal: _roundMoney(cardTotals[cardId] ?? 0),
      installmentsInInvoice: _roundMoney(installmentsByCard[cardId] ?? 0),
      isPaid: creditCardPayments[cardId] ?? false,
    );
  }).toList();

  return FinanceOverview(
    salary: _roundMoney(salary),
    debitSpent: _roundMoney(debitSpent),
    creditSpent: _roundMoney(creditSpent),
    invested: _roundMoney(invested),
    immediateOutflow: _roundMoney(immediateOutflow),
    availableNow: _roundMoney(availableNow),
    projectedAfterInvoices: _roundMoney(projectedAfterInvoices),
    currentInvoice: _roundMoney(currentInvoice),
    openInvoice: _roundMoney(openInvoice),
    totalCommitted: _roundMoney(totalCommitted),
    installmentBurden: _roundMoney(installmentBurden),
    debitCount: debitCount,
    creditCount: creditCount,
    investmentCount: investmentCount,
    cards: cardOverviews,
  );
}

String paymentMethodLabel(Expense expense) {
  if (expense.isInvestment) return 'Investimento';
  return expense.isCreditCard ? 'Credito' : 'Debito';
}

String paymentImpactLabel(Expense expense) {
  if (expense.isCreditCard) {
    final installments = expense.installments ?? 0;
    if (installments > 1) {
      final current = expense.installmentIndex ?? 1;
      return 'Entra na fatura ($current/$installments)';
    }
    return 'Entra na fatura';
  }

  return 'Sai do saldo agora';
}

String localizedExpenseTypeLabel(BuildContext context, ExpenseType type) {
  switch (type) {
    case ExpenseType.fixed:
      return AppStrings.t(context, 'expense_type_fixed_short');
    case ExpenseType.variable:
      return AppStrings.t(context, 'expense_type_variable_short');
    case ExpenseType.investment:
      return AppStrings.t(context, 'expense_type_investment_short');
  }
}

String localizedExpenseCategoryLabel(
  BuildContext context,
  ExpenseCategory category,
) {
  switch (category) {
    case ExpenseCategory.moradia:
      return AppStrings.t(context, 'expense_category_housing');
    case ExpenseCategory.alimentacao:
      return AppStrings.t(context, 'expense_category_food');
    case ExpenseCategory.transporte:
      return AppStrings.t(context, 'expense_category_transport');
    case ExpenseCategory.educacao:
      return AppStrings.t(context, 'expense_category_education');
    case ExpenseCategory.saude:
      return AppStrings.t(context, 'expense_category_health');
    case ExpenseCategory.lazer:
      return AppStrings.t(context, 'expense_category_leisure');
    case ExpenseCategory.assinaturas:
      return AppStrings.t(context, 'expense_category_subscriptions');
    case ExpenseCategory.investment:
      return AppStrings.t(context, 'expense_category_investment');
    case ExpenseCategory.dividas:
      return AppStrings.t(context, 'expense_category_debts');
    case ExpenseCategory.outros:
      return AppStrings.t(context, 'expense_category_other');
  }
}

String localizedPaymentMethodLabel(BuildContext context, Expense expense) {
  if (expense.isInvestment) {
    return AppStrings.t(context, 'payment_method_investment');
  }
  return expense.isCreditCard
      ? AppStrings.t(context, 'payment_method_credit')
      : AppStrings.t(context, 'payment_method_debit');
}

String localizedPaymentImpactLabel(BuildContext context, Expense expense) {
  if (expense.isCreditCard) {
    final installments = expense.installments ?? 0;
    if (installments > 1) {
      final current = expense.installmentIndex ?? 1;
      return AppStrings.tr(context, 'payment_impact_invoice_installment', {
        'current': '$current',
        'total': '$installments',
      });
    }
    return AppStrings.t(context, 'payment_impact_invoice');
  }

  return AppStrings.t(context, 'payment_impact_balance_now');
}

String localizedExpenseDueLabel(BuildContext context, Expense expense) {
  final dueDay = expense.dueDay;
  if (dueDay == null) return '';
  if (!(expense.isFixed || expense.isCreditCard)) return '';

  if (expense.isCreditCard) {
    return AppStrings.tr(context, 'expense_due_statement_day', {
      'day': '$dueDay',
    });
  }

  return AppStrings.tr(context, 'bills_selected_due', {
    'day': '$dueDay',
  });
}
