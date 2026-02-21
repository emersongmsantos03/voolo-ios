enum ExpenseType {
  fixed,
  variable,
  investment,
}

enum ExpenseCategory {
  moradia,
  alimentacao,
  transporte,
  educacao,
  saude,
  lazer,
  investment,
  outros,
}

class Expense {
  final String id;
  final String name;
  final ExpenseType type;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final int? dueDay; // para contas fixas (ex: aluguel dia 5)

  Expense({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.dueDay,
  });

  bool get isFixed => type == ExpenseType.fixed;
  bool get isVariable => type == ExpenseType.variable;
  bool get isInvestment => type == ExpenseType.investment;
}
