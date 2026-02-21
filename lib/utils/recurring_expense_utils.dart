import '../models/expense.dart';

final _recurrenceSuffix = RegExp(r'^(.+)-\d{6}$');

String recurringBaseExpenseId(String id) {
  final match = _recurrenceSuffix.firstMatch(id);
  return match != null ? match.group(1)! : id;
}

String recurringExpenseId(String baseId, int year, int month) {
  final monthStr = month.toString().padLeft(2, '0');
  return '$baseId-${year.toString()}$monthStr';
}

bool matchesRecurringExpenseId(String candidateId, String baseId) {
  if (candidateId == baseId) return true;
  if (!candidateId.startsWith('$baseId-')) return false;
  final suffix = candidateId.substring(baseId.length + 1);
  if (suffix.length != 6) return false;
  return int.tryParse(suffix) != null;
}

int clampDueDay(int? dueDay, int daysInMonth) {
  if (dueDay == null || dueDay <= 0) return 1;
  if (dueDay > daysInMonth) return daysInMonth;
  return dueDay;
}

Expense copyExpenseForMonth(Expense template, int year, int month) {
  final baseId = recurringBaseExpenseId(template.id);
  final monthlyId = recurringExpenseId(baseId, year, month);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return template.copyWith(
    id: monthlyId,
    date: DateTime(year, month, clampDueDay(template.dueDay, daysInMonth)),
    isPaid: false,
  );
}

DateTime resolveExpenseDate({
  required ExpenseType type,
  required DateTime baseDate,
  int? dueDay,
}) {
  if (type != ExpenseType.fixed || dueDay == null) {
    return baseDate;
  }
  final daysInMonth = DateTime(baseDate.year, baseDate.month + 1, 0).day;
  return DateTime(
    baseDate.year,
    baseDate.month,
    clampDueDay(dueDay, daysInMonth),
  );
}
