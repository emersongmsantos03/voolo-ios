import '../routes/app_routes.dart';

class WeeklyActionService {
  WeeklyActionService._();

  static String resolveRoute(String actionKey) {
    switch (actionKey) {
      case 'profile_income':
        return AppRoutes.profile;
      case 'budgets':
        return AppRoutes.budgets;
      case 'transactions':
        return AppRoutes.transactions;
      case 'investment_plan':
        return AppRoutes.investmentPlan;
      case 'goals':
        return AppRoutes.goals;
      case 'insights':
      default:
        return AppRoutes.insights;
    }
  }

  static bool isPremiumOnlyRoute(String route) {
    return route == AppRoutes.budgets ||
        route == AppRoutes.investmentPlan ||
        route == AppRoutes.goals;
  }
}
