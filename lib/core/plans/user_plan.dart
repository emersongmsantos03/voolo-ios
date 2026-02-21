import '../../models/user_profile.dart';

enum UserPlanType {
  free,
  premium,
}

class UserPlan {
  final UserPlanType type;

  UserPlan(this.type);

  bool get isPremium => type == UserPlanType.premium;
  bool get isFree => type == UserPlanType.free;

  // Web is canonical for feature gating (see src/utils/UserPlan.js)
  static const Set<String> premiumFeatures = {
    'missions',
    'reports',
    'goals',
    'calculator',
    'financial_score',
    'xp_progression',
    'monthly_comparison',
    'budgets',
    'investment_plan',
    'debt_plan',
  };

  static bool isFeatureLocked(UserProfile? user, String feature) {
    if (user != null && user.isPremium) return false;
    return premiumFeatures.contains(feature);
  }

  // Feature Flags
  bool get canAddMultipleGoals => isPremium;
  bool get hasAdvancedReports => isPremium;
  bool get hasMonthlyComparison => isPremium;
  bool get hasFullHistory => isPremium;
  bool get hasAdvancedCalculator => isPremium;
  bool get hasCloudBackup => isPremium;
  bool get canExportData => isPremium;
  bool get hasPersonalizedInsights => isPremium;
  bool get hasSmartAlerts => isPremium;
  bool get hasAdvancedGamification => isPremium;

  int get maxActiveGoals => isPremium ? 999 : 1;

  static UserPlan fromProfile(UserProfile? profile) {
    if (profile == null) return UserPlan(UserPlanType.free);
    return UserPlan(profile.isPremium ? UserPlanType.premium : UserPlanType.free);
  }
}
