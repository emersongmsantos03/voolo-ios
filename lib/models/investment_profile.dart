import 'package:cloud_firestore/cloud_firestore.dart';

class InvestmentProfile {
  final String risk; // conservative | moderate | aggressive
  final int score;
  final List<int> answers;
  final Map<String, double> allocation;
  final DateTime? updatedAt;
  final String? source; // server | local | etc (optional)

  InvestmentProfile({
    required this.risk,
    required this.score,
    required this.answers,
    required this.allocation,
    required this.updatedAt,
    required this.source,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory InvestmentProfile.fromJson(Map<String, dynamic> json) {
    final answersList = (json['answers'] as List?) ??
        (json['lastAnswers'] as List?) ??
        const [];
    final answersRaw = answersList
        .map((e) => (e as num?)?.toInt() ?? int.tryParse('$e') ?? 0)
        .toList();

    final allocRaw = (json['allocation'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0),
        ) ??
        const <String, double>{};

    final computedScore = answersRaw.fold<int>(0, (acc, v) => acc + v);

    return InvestmentProfile(
      risk: json['risk']?.toString() ?? 'conservative',
      score: (json['score'] as num?)?.toInt() ?? computedScore,
      answers: answersRaw,
      allocation: Map<String, double>.from(allocRaw),
      updatedAt: _parseDate(json['updatedAt']),
      source: json['source']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'risk': risk,
        'score': score,
        'answers': answers,
        'allocation': allocation,
        if (source != null) 'source': source,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
