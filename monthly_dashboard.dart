import 'expense.dart';

class MonthlyDashboard {
  final int month;
  final int year;
  final double salary;
  final List<Expense> expenses;

  MonthlyDashboard({
    required this.month,
    required this.year,
    required this.salary,
    required this.expenses,
  });

  double get fixedExpensesTotal =>
      expenses.where((e) => e.isFixed).fold(0, (a, b) => a + b.amount);

  double get variableExpensesTotal =>
      expenses.where((e) => e.isVariable).fold(0, (a, b) => a + b.amount);

  double get investmentsTotal =>
      expenses.where((e) => e.isInvestment).fold(0, (a, b) => a + b.amount);

  double get totalExpenses =>
      fixedExpensesTotal + variableExpensesTotal + investmentsTotal;

  double get remainingSalary => salary - totalExpenses;
}
