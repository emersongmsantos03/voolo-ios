import 'package:cloud_firestore/cloud_firestore.dart';

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
  assinaturas,
  investment,
  dividas,
  outros,
}

class Expense {
  final String id;
  final String name;
  final ExpenseType type;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  // Firestore v2 canonical type (EXPENSE | INCOME | INVESTMENT | DEBT_PAYMENT).
  // Null when the source is legacy (fixed/variable/investment).
  final String? txType;
  final String? seriesId; // recurring fixed series id
  final String? debtId; // debt link for DEBT_PAYMENT
  final int? dueDay; // para contas fixas (ex: aluguel dia 5)
  final bool isCreditCard;
  final String? creditCardId;
  final bool isCardRecurring;
  final int? installments;
  final int? installmentIndex;
  final bool isPaid;

  Expense({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.txType,
    this.seriesId,
    this.debtId,
    this.dueDay,
    this.isCreditCard = false,
    this.creditCardId,
    this.isCardRecurring = false,
    this.installments,
    this.installmentIndex,
    this.isPaid = false,
  });

  bool get isFixed => type == ExpenseType.fixed;
  bool get isVariable => type == ExpenseType.variable;
  bool get isInvestment => type == ExpenseType.investment;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'category': category.name,
        'amount': amount,
        'date': date.toIso8601String(),
        if (txType != null) 'txType': txType,
        'seriesId': seriesId,
        'debtId': debtId,
        'dueDay': dueDay,
        'isCreditCard': isCreditCard,
        'creditCardId': creditCardId,
        'isCardRecurring': isCardRecurring,
        'installments': installments,
        'installmentIndex': installmentIndex,
        'isPaid': isPaid,
      };

  factory Expense.fromJson(Map<dynamic, dynamic> json) {
    String? readString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    ExpenseType resolveType() {
      final raw = (readString(json['type']) ?? '').trim();
      if (raw.isEmpty) return ExpenseType.variable;

      // V2 types (Firestore rules): EXPENSE / INVESTMENT / INCOME / DEBT_PAYMENT
      final upper = raw.toUpperCase();
      if (upper == 'INVESTMENT') return ExpenseType.investment;
      if (upper == 'DEBT_PAYMENT') return ExpenseType.fixed;
      if (upper == 'EXPENSE') {
        final isVar =
            json['isVariable'] is bool ? json['isVariable'] as bool : null;
        return isVar == true ? ExpenseType.variable : ExpenseType.fixed;
      }

      // Legacy types (UI): fixed / variable / investment
      final lower = raw.toLowerCase();
      if (lower == 'fixed') return ExpenseType.fixed;
      if (lower == 'investment') return ExpenseType.investment;
      return ExpenseType.variable;
    }

    ExpenseCategory resolveCategory(ExpenseType type) {
      if (type == ExpenseType.investment) return ExpenseCategory.investment;

      final rawCategory = readString(json['category']);
      if (rawCategory != null) {
        try {
          return ExpenseCategory.values.byName(rawCategory);
        } catch (_) {
          // ignore, try categoryKey below
        }
      }

      final rawKey = (readString(json['categoryKey']) ?? '').toUpperCase();
      switch (rawKey) {
        case 'MORADIA':
          return ExpenseCategory.moradia;
        case 'ALIMENTACAO':
          return ExpenseCategory.alimentacao;
        case 'TRANSPORTE':
          return ExpenseCategory.transporte;
        case 'EDUCACAO':
          return ExpenseCategory.educacao;
        case 'SAUDE':
          return ExpenseCategory.saude;
        case 'LAZER':
          return ExpenseCategory.lazer;
        case 'ASSINATURAS':
          return ExpenseCategory.assinaturas;
        case 'INVESTIMENTO':
          return ExpenseCategory.investment;
        case 'DIVIDAS':
          return ExpenseCategory.dividas;
        case 'OUTROS':
          return ExpenseCategory.outros;
        default:
          return ExpenseCategory.outros;
      }
    }

    final resolvedType = resolveType();
    final resolvedCategory = resolveCategory(resolvedType);

    final rawType = (readString(json['type']) ?? '').trim();
    final rawTypeUpper = rawType.isEmpty ? null : rawType.toUpperCase();
    const v2Types = {'EXPENSE', 'INCOME', 'INVESTMENT', 'DEBT_PAYMENT'};
    final resolvedTxType =
        (rawTypeUpper != null && v2Types.contains(rawTypeUpper))
            ? rawTypeUpper
            : null;

    final statusRaw = readString(json['status'])?.toUpperCase();
    final paidFromStatus = statusRaw == 'PAID';
    final resolvedPaid = paidFromStatus || (json['isPaid'] as bool?) == true;

    return Expense(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      type: resolvedType,
      category: resolvedCategory,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: parseDate(json['dueDate'] ?? json['date']),
      txType: resolvedTxType,
      seriesId: json['seriesId'] as String?,
      debtId: readString(json['debtId']),
      dueDay: (json['dueDay'] as num?)?.toInt(),
      isCreditCard: (json['isCreditCard'] as bool?) ?? false,
      creditCardId: json['creditCardId'] as String?,
      isCardRecurring: (json['isCardRecurring'] as bool?) ?? false,
      installments: (json['installments'] as num?)?.toInt(),
      installmentIndex: (json['installmentIndex'] as num?)?.toInt(),
      isPaid: resolvedPaid,
    );
  }

  Expense copyWith({
    String? id,
    String? name,
    ExpenseType? type,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? txType,
    String? seriesId,
    String? debtId,
    int? dueDay,
    bool? isCreditCard,
    String? creditCardId,
    bool? isCardRecurring,
    int? installments,
    int? installmentIndex,
    bool? isPaid,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      txType: txType ?? this.txType,
      seriesId: seriesId ?? this.seriesId,
      debtId: debtId ?? this.debtId,
      dueDay: dueDay ?? this.dueDay,
      isCreditCard: isCreditCard ?? this.isCreditCard,
      creditCardId: creditCardId ?? this.creditCardId,
      isCardRecurring: isCardRecurring ?? this.isCardRecurring,
      installments: installments ?? this.installments,
      installmentIndex: installmentIndex ?? this.installmentIndex,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
