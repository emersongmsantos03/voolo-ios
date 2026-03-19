import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/models/credit_card.dart';
import 'package:jetx/models/expense.dart';
import 'package:jetx/utils/finance_overview_utils.dart';

void main() {
  group('buildFinanceOverview', () {
    test('counts credit spending inside the month commitment', () {
      final overview = buildFinanceOverview(
        salary: 5000,
        expenses: [
          Expense(
            id: 'd1',
            name: 'Mercado',
            type: ExpenseType.variable,
            category: ExpenseCategory.alimentacao,
            amount: 300,
            date: DateTime(2026, 3, 16),
          ),
          Expense(
            id: 'c1',
            name: 'Notebook',
            type: ExpenseType.variable,
            category: ExpenseCategory.outros,
            amount: 1200,
            date: DateTime(2026, 3, 16),
            isCreditCard: true,
            creditCardId: 'nubank',
          ),
        ],
        cards: [CreditCard(id: 'nubank', name: 'Nubank', dueDay: 10)],
      );

      expect(overview.debitSpent, 300);
      expect(overview.creditSpent, 1200);
      expect(overview.availableNow, 3500);
      expect(overview.projectedAfterInvoices, 3500);
      expect(overview.currentInvoice, 1200);
      expect(overview.openInvoice, 1200);
      expect(overview.cards.single.invoiceTotal, 1200);
    });

    test('counts investments as immediate outflow', () {
      final overview = buildFinanceOverview(
        salary: 4000,
        expenses: [
          Expense(
            id: 'i1',
            name: 'Tesouro',
            type: ExpenseType.investment,
            category: ExpenseCategory.investment,
            amount: 500,
            date: DateTime(2026, 3, 16),
          ),
        ],
      );

      expect(overview.invested, 500);
      expect(overview.immediateOutflow, 500);
      expect(overview.availableNow, 3500);
      expect(overview.creditSpent, 0);
    });

    test('keeps the month invoice visible even after payment', () {
      final overview = buildFinanceOverview(
        salary: 6000,
        expenses: [
          Expense(
            id: 'c1',
            name: 'Celular',
            type: ExpenseType.fixed,
            category: ExpenseCategory.outros,
            amount: 250,
            date: DateTime(2026, 3, 16),
            isCreditCard: true,
            creditCardId: 'gold',
            installments: 10,
            installmentIndex: 1,
          ),
          Expense(
            id: 'c2',
            name: 'Mercado',
            type: ExpenseType.variable,
            category: ExpenseCategory.alimentacao,
            amount: 120,
            date: DateTime(2026, 3, 16),
            isCreditCard: true,
            creditCardId: 'gold',
          ),
        ],
        cards: [CreditCard(id: 'gold', name: 'Gold', dueDay: 18)],
        creditCardPayments: const {'gold': true},
      );

      expect(overview.currentInvoice, 370);
      expect(overview.openInvoice, 0);
      expect(overview.installmentBurden, 250);
      expect(overview.cards.single.installmentsInInvoice, 250);
      expect(overview.cards.single.isPaid, isTrue);
    });
  });

  group('payment labels', () {
    test('returns debit and credit labels', () {
      final debit = Expense(
        id: '1',
        name: 'Mercado',
        type: ExpenseType.variable,
        category: ExpenseCategory.alimentacao,
        amount: 50,
        date: DateTime(2026, 3, 16),
      );
      final credit = Expense(
        id: '2',
        name: 'Curso',
        type: ExpenseType.variable,
        category: ExpenseCategory.educacao,
        amount: 50,
        date: DateTime(2026, 3, 16),
        isCreditCard: true,
        installments: 6,
        installmentIndex: 2,
      );

      expect(paymentMethodLabel(debit), 'Debito');
      expect(paymentImpactLabel(debit), 'Sai do saldo agora');
      expect(paymentMethodLabel(credit), 'Credito');
      expect(paymentImpactLabel(credit), 'Entra na fatura (2/6)');
    });
  });
}
