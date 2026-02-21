import 'package:cloud_firestore/cloud_firestore.dart';

class DebtPlanCompactV2 {
  final double minimumPaymentsTotal;
  final double monthlyBudgetUsed;
  final double extraBudget;
  final String? estimatedDebtFreeMonthYear; // YYYY-MM
  final List<String> warnings;

  /// Ordered debts used in the simulation.
  /// Each row is a small map to keep Firestore payload compact.
  final List<Map<String, dynamic>> debts;

  /// Payments for the first month only (compact storage).
  final List<Map<String, dynamic>> firstMonthPayments;

  /// Compact summary timeline (no per-debt balances).
  final List<Map<String, dynamic>> scheduleSummary;

  const DebtPlanCompactV2({
    required this.minimumPaymentsTotal,
    required this.monthlyBudgetUsed,
    required this.extraBudget,
    required this.estimatedDebtFreeMonthYear,
    required this.warnings,
    required this.debts,
    required this.firstMonthPayments,
    required this.scheduleSummary,
  });

  Map<String, dynamic> toJson() => {
        'minimumPaymentsTotal': minimumPaymentsTotal,
        'monthlyBudgetUsed': monthlyBudgetUsed,
        'extraBudget': extraBudget,
        'estimatedDebtFreeMonthYear': estimatedDebtFreeMonthYear,
        'warnings': warnings,
        'debts': debts,
        'firstMonthPayments': firstMonthPayments,
        'scheduleSummary': scheduleSummary,
      };

  factory DebtPlanCompactV2.fromJson(Map<String, dynamic> json) {
    List<String> parseWarnings(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return const <String>[];
    }

    List<Map<String, dynamic>> parseMapList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
      return const <Map<String, dynamic>>[];
    }

    return DebtPlanCompactV2(
      minimumPaymentsTotal:
          (json['minimumPaymentsTotal'] as num?)?.toDouble() ?? 0.0,
      monthlyBudgetUsed: (json['monthlyBudgetUsed'] as num?)?.toDouble() ?? 0.0,
      extraBudget: (json['extraBudget'] as num?)?.toDouble() ?? 0.0,
      estimatedDebtFreeMonthYear: json['estimatedDebtFreeMonthYear']?.toString(),
      warnings: parseWarnings(json['warnings']),
      debts: parseMapList(json['debts']),
      firstMonthPayments: parseMapList(json['firstMonthPayments']),
      scheduleSummary: parseMapList(json['scheduleSummary']),
    );
  }
}

class DebtPlanMethodV2 {
  final double monthlyBudget;
  final DebtPlanCompactV2 plan;
  final DateTime? updatedAt;

  const DebtPlanMethodV2({
    required this.monthlyBudget,
    required this.plan,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'monthlyBudget': monthlyBudget,
        'plan': plan.toJson(),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory DebtPlanMethodV2.fromJson(Map<String, dynamic> json) {
    final rawUpdated = json['updatedAt'];
    final updatedAt = rawUpdated is Timestamp ? rawUpdated.toDate() : null;
    final planRaw = json['plan'];
    return DebtPlanMethodV2(
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
      plan: planRaw is Map<String, dynamic>
          ? DebtPlanCompactV2.fromJson(planRaw)
          : DebtPlanCompactV2.fromJson(const {}),
      updatedAt: updatedAt,
    );
  }
}

class DebtPlanDocV2 {
  final String referenceMonth; // YYYY-MM (doc id)
  final String? lastMethod; // avalanche | snowball
  final Map<String, DebtPlanMethodV2> methods;
  final DateTime? updatedAt;

  const DebtPlanDocV2({
    required this.referenceMonth,
    required this.lastMethod,
    required this.methods,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': 2,
        'referenceMonth': referenceMonth,
        'lastMethod': lastMethod,
        'methods': methods.map((k, v) => MapEntry(k, v.toJson())),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory DebtPlanDocV2.fromJson(
    Map<String, dynamic> json, {
    required String referenceMonth,
  }) {
    final rawMethods = json['methods'];
    final methods = <String, DebtPlanMethodV2>{};
    if (rawMethods is Map) {
      for (final e in rawMethods.entries) {
        final key = e.key.toString();
        final val = e.value;
        if (val is Map<String, dynamic>) {
          methods[key] = DebtPlanMethodV2.fromJson(val);
        } else if (val is Map) {
          methods[key] = DebtPlanMethodV2.fromJson(
            val.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    }

    final rawUpdated = json['updatedAt'];
    final updatedAt = rawUpdated is Timestamp ? rawUpdated.toDate() : null;

    return DebtPlanDocV2(
      referenceMonth: referenceMonth,
      lastMethod: json['lastMethod']?.toString(),
      methods: methods,
      updatedAt: updatedAt,
    );
  }
}

