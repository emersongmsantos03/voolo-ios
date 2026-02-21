import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetV2 {
  final String id;
  final String referenceMonth; // YYYY-MM
  final String categoryKey; // e.g. MORADIA
  final double limitAmount;
  final double spentAmount;
  final double? suggestedAmount;
  final bool notified80;
  final bool notified100;
  final bool essential;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BudgetV2({
    required this.id,
    required this.referenceMonth,
    required this.categoryKey,
    required this.limitAmount,
    required this.spentAmount,
    required this.suggestedAmount,
    required this.notified80,
    required this.notified100,
    required this.essential,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetV2.fromJson(Map<String, dynamic> json, {required String id}) {
    return BudgetV2(
      id: id,
      referenceMonth: json['referenceMonth']?.toString() ?? '',
      categoryKey: json['categoryKey']?.toString() ?? '',
      limitAmount: (json['limitAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      suggestedAmount: (json['suggestedAmount'] as num?)?.toDouble(),
      notified80: json['notified80'] == true,
      notified100: json['notified100'] == true,
      essential: json['essential'] == true,
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (json['updatedAt'] is Timestamp)
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
