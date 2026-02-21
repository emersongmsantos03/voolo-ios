import 'package:cloud_firestore/cloud_firestore.dart';

class DebtV2 {
  final String id;
  final String creditorName;
  final double totalAmount;
  final double? interestRate; // percent, optional
  final double? minPayment;
  final bool isLate;
  final DateTime? lateSince;
  final String status; // ACTIVE | NEGOTIATING | PAID
  final String kind; // card, loan, financing, etc (free text)

  // Installment debts (schema v2).
  final double? installmentAmount; // valor da parcela
  final int? installmentTotal; // total de parcelas
  final int? installmentDueDay; // dia de vencimento (1-31)
  final String? installmentStartMonthYear; // YYYY-MM
  final Map<String, bool> paidInstallmentMonths; // {YYYY-MM: true/false}
  final String? fixedSeriesId; // ex: debt_{debtId}

  final DateTime? createdAt;
  final DateTime? updatedAt;

  DebtV2({
    required this.id,
    required this.creditorName,
    required this.totalAmount,
    required this.interestRate,
    required this.minPayment,
    required this.isLate,
    required this.lateSince,
    required this.status,
    required this.kind,
    required this.installmentAmount,
    required this.installmentTotal,
    required this.installmentDueDay,
    required this.installmentStartMonthYear,
    Map<String, bool>? paidInstallmentMonths,
    required this.fixedSeriesId,
    required this.createdAt,
    required this.updatedAt,
  }) : paidInstallmentMonths =
            Map<String, bool>.from(paidInstallmentMonths ?? const {});

  bool get isInstallmentDebt =>
      (installmentTotal ?? 0) > 0 && (installmentAmount ?? 0) > 0;

  int get paidInstallmentsCount =>
      paidInstallmentMonths.values.where((v) => v == true).length;

  int? get remainingInstallments {
    final total = installmentTotal;
    if (total == null || total <= 0) return null;
    final remaining = total - paidInstallmentsCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool isWithinInstallmentWindow(String monthYear) {
    if (!isInstallmentDebt) return false;
    final start = (installmentStartMonthYear != null &&
            installmentStartMonthYear!.trim().isNotEmpty)
        ? installmentStartMonthYear!.trim()
        : (createdAt != null
            ? '${createdAt!.year}-${createdAt!.month.toString().padLeft(2, '0')}'
            : null);
    final total = installmentTotal;
    if (start == null || start.isEmpty || total == null || total <= 0) {
      return false;
    }
    if (monthYear.compareTo(start) < 0) return false;

    final parts = start.split('-');
    if (parts.length != 2) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return false;

    final startIndex = year * 12 + (month - 1);
    final curParts = monthYear.split('-');
    if (curParts.length != 2) return false;
    final cy = int.tryParse(curParts[0]);
    final cm = int.tryParse(curParts[1]);
    if (cy == null || cm == null) return false;
    final curIndex = cy * 12 + (cm - 1);

    return curIndex < startIndex + total;
  }

  factory DebtV2.fromJson(Map<String, dynamic> json, {required String id}) {
    Map<String, bool> parsePaidMonths(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v == true));
      }
      return const {};
    }

    return DebtV2(
      id: id,
      creditorName: json['creditorName']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      minPayment: (json['minPayment'] as num?)?.toDouble(),
      isLate: json['isLate'] == true,
      lateSince: (json['lateSince'] is Timestamp)
          ? (json['lateSince'] as Timestamp).toDate()
          : null,
      status: json['status']?.toString() ?? 'ACTIVE',
      kind: json['kind']?.toString() ?? 'card',
      installmentAmount: (json['installmentAmount'] as num?)?.toDouble(),
      installmentTotal: (json['installmentTotal'] as num?)?.toInt(),
      installmentDueDay: (json['installmentDueDay'] as num?)?.toInt(),
      installmentStartMonthYear:
          json['installmentStartMonthYear']?.toString(),
      paidInstallmentMonths: parsePaidMonths(json['paidInstallmentMonths']),
      fixedSeriesId: json['fixedSeriesId']?.toString(),
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (json['updatedAt'] is Timestamp)
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': 2,
      'creditorName': creditorName,
      'totalAmount': totalAmount,
      'interestRate': interestRate,
      'minPayment': minPayment,
      'isLate': isLate,
      'lateSince': lateSince != null ? Timestamp.fromDate(lateSince!) : null,
      'status': status,
      'kind': kind,
      'installmentAmount': installmentAmount,
      'installmentTotal': installmentTotal,
      'installmentDueDay': installmentDueDay,
      'installmentStartMonthYear': installmentStartMonthYear,
      'paidInstallmentMonths': paidInstallmentMonths,
      'fixedSeriesId': fixedSeriesId,
    };
  }
}
