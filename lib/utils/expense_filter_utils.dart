import '../models/expense.dart';

bool isEffectivelyPaid(Expense e) {
  final canBePending = e.type == ExpenseType.fixed && !e.isCreditCard;
  return canBePending ? e.isPaid : true;
}

List<Expense> filterExpenses(
  List<Expense> expenses, {
  required DateTime Function(Expense) dueDateFor,
  DateTime? dueFrom,
  DateTime? dueTo,
  Set<ExpenseCategory> categories = const {},
  bool? isPaid,
}) {
  if (expenses.isEmpty) return <Expense>[];

  final hasCategoryFilter = categories.isNotEmpty;

  return expenses.where((e) {
    final due = dueDateFor(e);

    if (dueFrom != null && due.isBefore(dueFrom)) return false;
    if (dueTo != null && due.isAfter(dueTo)) return false;

    if (hasCategoryFilter && !categories.contains(e.category)) return false;

    if (isPaid != null && isEffectivelyPaid(e) != isPaid) return false;

    return true;
  }).toList();
}
