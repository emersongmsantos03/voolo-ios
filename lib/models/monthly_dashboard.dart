import 'expense.dart';

class MonthlyDashboard {
  final int month;
  final int year;
  final double salary;
  final List<Expense> expenses;
  final Map<String, bool> creditCardPayments;
  final List<String> fixedExclusions; // seriesIds excluded for this month
  final double balanceBeforeMonth;
  final double monthBalance;
  final double totalBalance;

  MonthlyDashboard({
    required this.month,
    required this.year,
    required this.salary,
    required this.expenses,
    Map<String, bool>? creditCardPayments,
    List<String>? fixedExclusions,
    this.balanceBeforeMonth = 0.0,
    double? monthBalance,
    double? totalBalance,
  })  : creditCardPayments = Map<String, bool>.from(creditCardPayments ?? const {}),
        fixedExclusions = List<String>.from(fixedExclusions ?? const []),
        monthBalance = monthBalance ??
            _roundMoney(salary - _expensesTotal(expenses)),
        totalBalance = totalBalance ??
            _roundMoney(
              balanceBeforeMonth +
                  (monthBalance ?? _roundMoney(salary - _expensesTotal(expenses))),
            );

  static double _expensesTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  static double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  double get fixedExpensesTotal =>
      expenses.where((e) => e.isFixed).fold(0, (a, b) => a + b.amount);

  double get variableExpensesTotal =>
      expenses.where((e) => e.isVariable).fold(0, (a, b) => a + b.amount);

  double get investmentsTotal =>
      expenses.where((e) => e.isInvestment).fold(0, (a, b) => a + b.amount);

  double get totalExpenses =>
      fixedExpensesTotal + variableExpensesTotal + investmentsTotal;

  double get remainingSalary => monthBalance;

  Map<String, dynamic> toJson() => {
        'month': month,
        'year': year,
        'salary': salary,
        'balanceBeforeMonth': balanceBeforeMonth,
        'monthBalance': monthBalance,
        'totalBalance': totalBalance,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'creditCardPayments': creditCardPayments,
        'fixedExclusions': fixedExclusions,
      };

  factory MonthlyDashboard.fromJson(Map<dynamic, dynamic> json, {String? id}) {
    int? fallbackMonth;
    int? fallbackYear;
    
    if (id != null && id.contains('-')) {
      final parts = id.split('-');
      fallbackYear = int.tryParse(parts[0]);
      fallbackMonth = int.tryParse(parts[1]);
    }

    return MonthlyDashboard(
      month: (json['month'] as num?)?.toInt() ?? fallbackMonth ?? 1,
      year: (json['year'] as num?)?.toInt() ?? fallbackYear ?? 2024,
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      balanceBeforeMonth: (json['balanceBeforeMonth'] as num?)?.toDouble() ?? 0.0,
      monthBalance: (json['monthBalance'] as num?)?.toDouble(),
      totalBalance: (json['totalBalance'] as num?)?.toDouble(),
      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map((e) => Expense.fromJson(e as Map))
          .toList(),
      creditCardPayments: (json['creditCardPayments'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
          const {},
      fixedExclusions: (json['fixedExclusions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  MonthlyDashboard copyWith({
    int? month,
    int? year,
    double? salary,
    List<Expense>? expenses,
    Map<String, bool>? creditCardPayments,
    List<String>? fixedExclusions,
    double? balanceBeforeMonth,
    double? monthBalance,
    double? totalBalance,
  }) {
    final nextSalary = salary ?? this.salary;
    final nextExpenses = expenses ?? this.expenses;
    final nextBalanceBeforeMonth = balanceBeforeMonth ?? this.balanceBeforeMonth;
    final nextMonthBalance =
        monthBalance ?? _roundMoney(nextSalary - _expensesTotal(nextExpenses));
    final nextTotalBalance =
        totalBalance ?? _roundMoney(nextBalanceBeforeMonth + nextMonthBalance);

    return MonthlyDashboard(
      month: month ?? this.month,
      year: year ?? this.year,
      salary: nextSalary,
      expenses: nextExpenses,
      creditCardPayments: creditCardPayments ?? this.creditCardPayments,
      fixedExclusions: fixedExclusions ?? this.fixedExclusions,
      balanceBeforeMonth: nextBalanceBeforeMonth,
      monthBalance: nextMonthBalance,
      totalBalance: nextTotalBalance,
    );
  }
}
