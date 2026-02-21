import 'expense.dart';

class FixedSeries {
  final String seriesId;
  final String name;
  final double amount;
  final ExpenseCategory category;
  final int? dueDay;
  final bool isCreditCard;
  final String? creditCardId;
  final bool isActive;
  final String? endMonthYear; // YYYY-MM

  FixedSeries({
    required this.seriesId,
    required this.name,
    required this.amount,
    required this.category,
    this.dueDay,
    this.isCreditCard = false,
    this.creditCardId,
    this.isActive = true,
    this.endMonthYear,
  });

  factory FixedSeries.fromJson(Map<String, dynamic> json, {required String id}) {
    ExpenseCategory parseCategory(String? val) {
      if (val == null) return ExpenseCategory.outros;
      try {
        return ExpenseCategory.values.byName(val);
      } catch (_) {
        return ExpenseCategory.outros;
      }
    }

    return FixedSeries(
      seriesId: (json['seriesId'] as String?) ?? id,
      name: (json['name'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: parseCategory(json['category'] as String?),
      dueDay: (json['dueDay'] as num?)?.toInt(),
      isCreditCard: (json['isCreditCard'] as bool?) ?? false,
      creditCardId: json['creditCardId'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      endMonthYear: json['endMonthYear'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'seriesId': seriesId,
        'name': name,
        'amount': amount,
        'category': category.name,
        'dueDay': dueDay,
        'isCreditCard': isCreditCard,
        'creditCardId': creditCardId,
        'type': 'fixed',
        'isActive': isActive,
        'endMonthYear': endMonthYear,
      };
}

