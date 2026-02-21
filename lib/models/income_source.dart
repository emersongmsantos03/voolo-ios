import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeSource {
  final String id;
  final String title;
  final double amount;
  final String type; // 'fixed' | 'variable'
  final String recurrence; // 'monthly'
  final String? activeFrom; // YYYY-MM
  final String? activeUntil; // YYYY-MM
  final List<String> excludedMonths; // YYYY-MM
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isPrimary;

  IncomeSource({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.recurrence = 'monthly',
    this.activeFrom,
    this.activeUntil,
    List<String> excludedMonths = const [],
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isPrimary = false,
  }) : excludedMonths = List<String>.from(excludedMonths);

  factory IncomeSource.fromJson(Map<String, dynamic> json, {String? id}) {
    return IncomeSource(
      id: id ?? json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'fixed',
      recurrence: json['recurrence'] ?? 'monthly',
      activeFrom: json['activeFrom'] as String?,
      activeUntil: json['activeUntil'] as String?,
      excludedMonths: (json['excludedMonths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
      isActive: json['isActive'] ?? true,
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'recurrence': recurrence,
      'activeFrom': activeFrom,
      'activeUntil': activeUntil,
      'excludedMonths': excludedMonths,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'isPrimary': isPrimary,
    };
  }

  IncomeSource copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? recurrence,
    String? activeFrom,
    String? activeUntil,
    List<String>? excludedMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPrimary,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      recurrence: recurrence ?? this.recurrence,
      activeFrom: activeFrom ?? this.activeFrom,
      activeUntil: activeUntil ?? this.activeUntil,
      excludedMonths: excludedMonths ?? this.excludedMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
