import 'package:flutter_test/flutter_test.dart';
import 'package:jetx/routes/app_routes.dart';
import 'package:jetx/services/weekly_action_service.dart';

void main() {
  test('WeeklyActionService resolves route for known action keys', () {
    expect(
      WeeklyActionService.resolveRoute('transactions'),
      AppRoutes.transactions,
    );
    expect(WeeklyActionService.resolveRoute('goals'), AppRoutes.goals);
    expect(
      WeeklyActionService.resolveRoute('investment_plan'),
      AppRoutes.investmentPlan,
    );
    expect(WeeklyActionService.resolveRoute('unknown'), AppRoutes.insights);
  });

  test('WeeklyActionService marks premium-only routes', () {
    expect(WeeklyActionService.isPremiumOnlyRoute(AppRoutes.goals), isTrue);
    expect(WeeklyActionService.isPremiumOnlyRoute(AppRoutes.budgets), isTrue);
    expect(
      WeeklyActionService.isPremiumOnlyRoute(AppRoutes.investmentPlan),
      isTrue,
    );
    expect(
      WeeklyActionService.isPremiumOnlyRoute(AppRoutes.transactions),
      isFalse,
    );
  });
}
