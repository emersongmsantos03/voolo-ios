import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/catalogs/gender_catalog.dart';
import '../core/catalogs/objectives_catalog.dart';
import 'credit_card.dart';

class UserProfile {
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String planFree = 'free';
  static const String planPremium = 'premium';

  String firstName;
  String lastName;
  String email;
  String password;
  DateTime birthDate;
  String profession;
  double monthlyIncome;
  String gender;
  String? photoPath;
  List<String> objectives;
  bool setupCompleted;
  bool isPremium;
  DateTime? premiumUntil;
  bool isActive;
  int totalXp;
  List<String> completedMissions;
  Map<String, String> missionNotes;
  Map<String, String> missionCompletionType;
  DateTime? lastReportViewedAt;
  DateTime? lastCalculatorOpenedAt;
  List<CreditCard> creditCards;
  List<Map<String, dynamic>> incomeSources;
  double propertyValue;
  double investBalance;
  DateTime createdAt;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.password = '',
    required this.birthDate,
    required this.profession,
    required this.monthlyIncome,
    required this.gender,
    this.photoPath,
    this.objectives = const [],
    this.setupCompleted = false,
    this.isPremium = false,
    this.premiumUntil,
    this.isActive = true,
    this.totalXp = 0,
    List<String> completedMissions = const [],
    Map<String, String> missionNotes = const {},
    Map<String, String> missionCompletionType = const {},
    this.lastReportViewedAt,
    this.lastCalculatorOpenedAt,
    List<CreditCard> creditCards = const [],
    List<Map<String, dynamic>> incomeSources = const [],
    this.propertyValue = 0.0,
    this.investBalance = 0.0,
    DateTime? createdAt,
  })  : completedMissions = List<String>.from(completedMissions),
        missionNotes = Map<String, String>.from(missionNotes),
        missionCompletionType = Map<String, String>.from(missionCompletionType),
        creditCards = List<CreditCard>.from(creditCards),
        incomeSources = List<Map<String, dynamic>>.from(incomeSources),
        createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';
  String get status => isActive ? statusActive : statusInactive;
  String get plan => isPremium ? planPremium : planFree;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'birthDate': birthDate.toIso8601String(),
        'profession': profession,
        'monthlyIncome': monthlyIncome,
        'gender': gender,
        'photoPath': photoPath,
        'objectives': objectives,
        'setupCompleted': setupCompleted,
        'isPremium': isPremium,
        'isActive': isActive,
        'plan': plan,
        'status': status,
        'totalXp': totalXp,
        'completedMissions': completedMissions,
        'missionNotes': missionNotes,
        'missionCompletionType': missionCompletionType,
        'lastReportViewedAt': lastReportViewedAt?.toIso8601String(),
        'lastCalculatorOpenedAt': lastCalculatorOpenedAt?.toIso8601String(),
        'creditCards': creditCards.map((c) => c.toJson()).toList(),
        'incomeSources': incomeSources,
        'propertyValue': propertyValue,
        'investBalance': investBalance,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String?)?.trim().toLowerCase();
    final planRaw = (json['plan'] as String?)?.trim().toLowerCase();

    var isActive = (json['isActive'] as bool?) ??
        (json['active'] as bool?) ??
        true;
    final blockedFlag = (json['blocked'] as bool?) ?? false;
    final suspensoFlag =
        (json['suspenso'] as bool?) ?? (json['suspended'] as bool?) ?? false;

    if (blockedFlag || suspensoFlag) {
      isActive = false;
    }

    if (statusRaw == 'inactive' ||
        statusRaw == 'inativo' ||
        statusRaw == 'blocked' ||
        statusRaw == 'bloqueado' ||
        statusRaw == 'suspenso' ||
        statusRaw == 'suspended') {
      isActive = false;
    } else if (statusRaw == 'active' || statusRaw == 'ativo') {
      isActive = true;
    }

    var isPremium = (json['isPremium'] as bool?) ??
        (json['premium'] as bool?) ??
        (json['premiumAtivo'] as bool?) ??
        false;
    if (planRaw == 'premium') {
      isPremium = true;
    } else if (planRaw == 'free' || planRaw == 'gratuito') {
      isPremium = false;
    }

    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parsePremiumUntil(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final now = DateTime.now();
    final premiumUntil = parsePremiumUntil(json['premiumUntil']);
    if (premiumUntil != null) {
      isPremium = premiumUntil.isAfter(now);
    }

    return UserProfile(
      firstName: (json['firstName'] as String?) ?? 'Usuario',
      lastName: (json['lastName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      password: (json['password'] as String?) ?? '',
      birthDate: json['birthDate'] != null 
          ? DateTime.tryParse(json['birthDate'] as String) ?? DateTime(2000, 1, 1)
          : DateTime(2000, 1, 1),
      profession: (json['profession'] as String?) ?? '',
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      gender: GenderCatalog.normalize((json['gender'] as String?) ?? '') ??
          ((json['gender'] as String?) ?? 'not_informed'),
      photoPath: json['photoPath'] as String?,
      objectives: ObjectivesCatalog.normalizeList(
        (json['objectives'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      ),
      setupCompleted: (json['setupCompleted'] as bool?) ?? false,
      isPremium: isPremium,
      premiumUntil: premiumUntil,
      isActive: isActive,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      completedMissions: (json['completedMissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      missionNotes: (json['missionNotes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
          const {},
      missionCompletionType:
          (json['missionCompletionType'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
              const {},
      lastReportViewedAt: (json['lastReportViewedAt'] as String?) == null
          ? null
          : DateTime.tryParse(json['lastReportViewedAt'] as String),
      lastCalculatorOpenedAt: (json['lastCalculatorOpenedAt'] as String?) == null
          ? null
          : DateTime.tryParse(json['lastCalculatorOpenedAt'] as String),
      creditCards: (json['creditCards'] as List<dynamic>?)
              ?.map((e) => CreditCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      incomeSources: (json['incomeSources'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      propertyValue: (json['propertyValue'] as num?)?.toDouble() ?? 0.0,
      investBalance: (json['investBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseCreatedAt(json['createdAt']),
    );
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    DateTime? birthDate,
    String? profession,
    double? monthlyIncome,
    String? gender,
    String? photoPath,
    List<String>? objectives,
    bool? setupCompleted,
    bool? isPremium,
    DateTime? premiumUntil,
    bool? isActive,
    int? totalXp,
    List<String>? completedMissions,
    Map<String, String>? missionNotes,
    Map<String, String>? missionCompletionType,
    DateTime? lastReportViewedAt,
    DateTime? lastCalculatorOpenedAt,
    List<CreditCard>? creditCards,
    List<Map<String, dynamic>>? incomeSources,
    double? propertyValue,
    double? investBalance,
    DateTime? createdAt,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      profession: profession ?? this.profession,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      gender: gender ?? this.gender,
      photoPath: photoPath ?? this.photoPath,
      objectives: objectives ?? this.objectives,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      isActive: isActive ?? this.isActive,
      totalXp: totalXp ?? this.totalXp,
      completedMissions: completedMissions ?? this.completedMissions,
      missionNotes: missionNotes ?? this.missionNotes,
      missionCompletionType: missionCompletionType ?? this.missionCompletionType,
      lastReportViewedAt: lastReportViewedAt ?? this.lastReportViewedAt,
      lastCalculatorOpenedAt: lastCalculatorOpenedAt ?? this.lastCalculatorOpenedAt,
      creditCards: creditCards ?? this.creditCards,
      incomeSources: incomeSources ?? this.incomeSources,
      propertyValue: propertyValue ?? this.propertyValue,
      investBalance: investBalance ?? this.investBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
