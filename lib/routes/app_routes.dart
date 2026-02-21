import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/responsive.dart';

// Auth
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/security_lock_page.dart';
import '../pages/auth/reset_password_confirm_page.dart';
import '../pages/auth/reset_password_page.dart';

// Onboarding
import '../pages/onboarding/onboarding_page.dart';

// Dashboard
import '../pages/dashboard/dashboard_page.dart';

// Expenses
import '../pages/expenses/add_expense_page.dart';

// Investments
import '../pages/investments/investment_calculator_page.dart';
import '../pages/investments/investment_plan_page.dart';

// Goals
import '../pages/goals/goals_page.dart';

// Missions
import '../pages/missions/missions_page.dart';

// Reports
import '../pages/reporting/monthly_report_page.dart';

// Insights
import '../pages/insights/insights_page.dart';

// Profile
import '../pages/profile/profile_page.dart';

// Transactions
import '../pages/transactions/transactions_page.dart';

// Budgets
import '../pages/budgets/budgets_page.dart';

// Debts
import '../pages/debts/debts_page.dart';
import '../pages/premium/premium_page.dart';

class AppRoutes {
  AppRoutes._();

  // Route names
  static const String login = '/login';
  static const String securityLock = '/security-lock';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String onboarding = '/onboarding';

  static const String dashboard = '/dashboard';

  static const String addExpense = '/add-expense';
  static const String investmentCalculator = '/investment-calculator';
  static const String calculator = '/calculator';
  static const String goals = '/metas';
  static const String monthlyReport = '/monthly-report';
  static const String missions = '/missions';
  static const String transactions = '/transactions';
  static const String insights = '/insights';
  static const String profile = '/profile';
  static const String budgets = '/budgets';
  static const String investmentPlan = '/investment-plan';
  static const String debts = '/debts';
  static const String premium = '/premium';

  /// Plug no MaterialApp:
  /// onGenerateRoute: AppRoutes.onGenerateRoute,
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final path = settings.name ?? '';

    if (path.startsWith('$resetPassword/')) {
      final token = path.substring('$resetPassword/'.length).trim();
      if (token.isNotEmpty) {
        return MaterialPageRoute(
          builder: (_) => ResetPasswordConfirmPage(token: token),
          settings: settings,
        );
      }
    }

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case securityLock:
        return MaterialPageRoute(builder: (_) => const SecurityLockPage());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());

      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      case addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpensePage());

      case investmentCalculator:
        return MaterialPageRoute(
            builder: (_) => const InvestmentCalculatorPage());

      case investmentPlan:
        return MaterialPageRoute(builder: (_) => const InvestmentPlanPage());

      case calculator:
        return MaterialPageRoute(
            builder: (_) => const InvestmentCalculatorPage());

      case goals:
        return MaterialPageRoute(builder: (_) => const GoalsPage());

      case monthlyReport:
        return MaterialPageRoute(builder: (_) => const MonthlyReportPage());

      case missions:
        return MaterialPageRoute(builder: (_) => const MissionsPage());

      case transactions:
        return MaterialPageRoute(builder: (_) => const TransactionsPage());

      case insights:
        return MaterialPageRoute(builder: (_) => const InsightsPage());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case budgets:
        return MaterialPageRoute(builder: (_) => const BudgetsPage());

      case debts:
        return MaterialPageRoute(builder: (_) => const DebtsPage());

      case premium:
        final args = settings.arguments;
        final initialPlan = args is Map<String, dynamic>
            ? args['plan']?.toString()
            : (args is Map ? args['plan']?.toString() : null);
        return MaterialPageRoute(
          builder: (_) => PremiumPage(initialPlan: initialPlan),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => _UnknownRoutePage(routeName: settings.name),
        );
    }
  }
}

class _UnknownRoutePage extends StatelessWidget {
  final String? routeName;

  const _UnknownRoutePage({this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'unknown_route_title'))),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Center(
          child: Text(
            AppStrings.tr(
              context,
              'unknown_route_body',
              {'route': routeName ?? 'null'},
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      ),
    );
  }
}
