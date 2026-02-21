import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_key.dart';
import 'enums.dart';
import 'reference_month.dart';

class TransactionV2 {
  TransactionV2({
    required this.id,
    required this.type,
    required this.categoryKey,
    required this.amount,
    required this.referenceMonth,
    required this.status,
    required this.isVariable,
    required this.createdBy,
    required this.sourceApp,
    this.dueDate,
    this.paidAt,
    this.title,
    this.merchant,
  });

  final String id;
  final String type;
  final String categoryKey;
  final double amount;
  final String referenceMonth;
  final String status;
  final bool isVariable;
  final String createdBy;
  final String sourceApp;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? title;
  final String? merchant;

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed;
    }
    return null;
  }

  static TransactionV2 fromFirestore(Map<String, dynamic> data, {required String id}) {
    final due = _toDate(data['dueDate']) ?? _toDate(data['date']);
    final referenceMonth = (data['referenceMonth'] as String?) ?? toReferenceMonth(due) ?? '1970-01';
    final cat = (data['categoryKey'] as String?) ?? toCategoryKey(data['category']) ?? 'OUTROS';

    final rawType = data['type'];
    final type = rawType == TxType.expense ||
            rawType == TxType.income ||
            rawType == TxType.investment ||
            rawType == TxType.debtPayment
        ? rawType as String
        : (rawType?.toString().toLowerCase() == 'investment'
            ? TxType.investment
            : TxType.expense);

    final statusRaw = data['status'];
    final status = statusRaw == TxStatus.paid || statusRaw == TxStatus.pending
        ? statusRaw as String
        : (data['isPaid'] == true ? TxStatus.paid : TxStatus.pending);

    final legacyType = rawType?.toString().toLowerCase() ?? '';
    final isVariable = data['isVariable'] is bool ? data['isVariable'] as bool : legacyType == 'variable';

    return TransactionV2(
      id: id,
      type: type,
      categoryKey: cat,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      referenceMonth: referenceMonth,
      status: status,
      isVariable: isVariable,
      createdBy: (data['createdBy'] as String?) ?? '',
      sourceApp: (data['sourceApp'] as String?) ?? (data['origin'] as String?) ?? SourceApp.flutter,
      dueDate: due,
      paidAt: _toDate(data['paidAt']),
      title: (data['title'] as String?) ?? (data['name'] as String?),
      merchant: data['merchant'] as String?,
    );
  }

  Map<String, dynamic> toWriteMap({
    required String uid,
    required String sourceApp,
  }) {
    final due = dueDate;
    if (type == TxType.expense && due == null) {
      throw StateError('missing_due_date');
    }
    final refMonth = referenceMonth.isNotEmpty ? referenceMonth : (toReferenceMonth(due) ?? '');
    if (refMonth.isEmpty) {
      throw StateError('missing_reference_month');
    }

    return {
      'schemaVersion': SchemaVersion.v2,
      'type': type,
      'categoryKey': categoryKey,
      'amount': amount,
      'referenceMonth': refMonth,
      'status': status,
      'isVariable': isVariable,
      'dueDate': due != null ? Timestamp.fromDate(due) : null,
      'paidAt': status == TxStatus.paid ? Timestamp.fromDate((paidAt ?? DateTime.now())) : null,
      'title': title ?? '',
      'merchant': merchant,
      'createdBy': uid,
      'sourceApp': sourceApp,
    };
  }
}

