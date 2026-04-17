import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jetx/models/user_profile.dart';

void main() {
  test('UserProfile.fromJson accepts Firestore Timestamp dates', () {
    final createdAt = Timestamp.fromDate(DateTime(2026, 4, 17, 12, 0));
    final birthDate = Timestamp.fromDate(DateTime(1990, 8, 23));
    final reportViewed = Timestamp.fromDate(DateTime(2026, 4, 1));

    final profile = UserProfile.fromJson({
      'firstName': 'Teste',
      'lastName': 'Firebase',
      'email': 'teste@voolo.com.br',
      'birthDate': birthDate,
      'profession': 'Analista',
      'monthlyIncome': 1234.5,
      'gender': 'masculino',
      'lastReportViewedAt': reportViewed,
      'lastCalculatorOpenedAt': '2026-04-15T10:30:00.000',
      'createdAt': createdAt,
      'objectives': const [],
      'setupCompleted': true,
      'isPremium': false,
      'isActive': true,
    });

    expect(profile.birthDate, DateTime(1990, 8, 23));
    expect(profile.lastReportViewedAt, DateTime(2026, 4, 1));
    expect(profile.lastCalculatorOpenedAt, DateTime(2026, 4, 15, 10, 30));
    expect(profile.createdAt, DateTime(2026, 4, 17, 12, 0));
    expect(profile.email, 'teste@voolo.com.br');
  });
}
