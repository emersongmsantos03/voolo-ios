import 'package:cloud_firestore/cloud_firestore.dart';

class InvestmentPlanAllocationBlock {
  final String label;
  final double percent;

  InvestmentPlanAllocationBlock({
    required this.label,
    required this.percent,
  });

  factory InvestmentPlanAllocationBlock.fromJson(Map<String, dynamic> json) {
    return InvestmentPlanAllocationBlock(
      label: json['label']?.toString() ?? '',
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'percent': percent,
      };
}

class InvestmentPlanSelectedAllocation {
  final String title;
  final String subtitle;
  final List<InvestmentPlanAllocationBlock> blocks;
  final List<String> notes;

  InvestmentPlanSelectedAllocation({
    required this.title,
    required this.subtitle,
    required this.blocks,
    required this.notes,
  });

  factory InvestmentPlanSelectedAllocation.fromJson(Map<String, dynamic> json) {
    final blocksRaw = (json['blocks'] as List?) ?? const [];
    final blocks = blocksRaw
        .whereType<Map>()
        .map((e) => InvestmentPlanAllocationBlock.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
    final notes = (json['notes'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    return InvestmentPlanSelectedAllocation(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      blocks: blocks,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'notes': notes,
      };
}

class InvestmentPlanDoc {
  final int schemaVersion;
  final String monthYear;
  final int? emergencyMonthsTarget;
  final double? monthlyContributionTarget;
  final String? risk;
  final double? selectedMonthlyAmount;
  final InvestmentPlanSelectedAllocation? selectedAllocation;
  final DateTime? selectedAt;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final String? createdBy;
  final String? sourceApp;

  InvestmentPlanDoc({
    required this.schemaVersion,
    required this.monthYear,
    required this.emergencyMonthsTarget,
    required this.monthlyContributionTarget,
    required this.risk,
    required this.selectedMonthlyAmount,
    required this.selectedAllocation,
    required this.selectedAt,
    required this.updatedAt,
    required this.createdAt,
    required this.createdBy,
    required this.sourceApp,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory InvestmentPlanDoc.fromJson(Map<String, dynamic> json) {
    final allocationRaw = json['selectedAllocation'];
    final selectedAllocation = allocationRaw is Map
        ? InvestmentPlanSelectedAllocation.fromJson(
            allocationRaw.map((k, v) => MapEntry(k.toString(), v)))
        : null;

    return InvestmentPlanDoc(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      monthYear: json['monthYear']?.toString() ?? '',
      emergencyMonthsTarget: (json['emergencyMonthsTarget'] as num?)?.toInt(),
      monthlyContributionTarget:
          (json['monthlyContributionTarget'] as num?)?.toDouble(),
      risk: json['risk']?.toString(),
      selectedMonthlyAmount:
          (json['selectedMonthlyAmount'] as num?)?.toDouble(),
      selectedAllocation: selectedAllocation,
      selectedAt: _parseDate(json['selectedAt']),
      updatedAt: _parseDate(json['updatedAt']),
      createdAt: _parseDate(json['createdAt']),
      createdBy: json['createdBy']?.toString(),
      sourceApp: json['sourceApp']?.toString() ?? json['origin']?.toString(),
    );
  }
}
