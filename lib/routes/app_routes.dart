import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/responsive.dart';
import '../widgets/web_layout_wrapper.dart';

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

    Widget page;
    switch (settings.name) {
      case login:
        page = const LoginPage();
        break;

      case securityLock:
        page = const SecurityLockPage();
        break;

      case register:
        page = const RegisterPage();
        break;

      case forgotPassword:
        page = const ResetPasswordPage();
        break;

      case resetPassword:
        page = const ResetPasswordPage();
        break;

      case onboarding:
        page = const OnboardingPage();
        break;

      case dashboard:
        page = const DashboardPage();
        break;

      case addExpense:
        page = const AddExpensePage();
        break;

      case investmentCalculator:
        page = const InvestmentCalculatorPage();
        break;

      case investmentPlan:
        page = const InvestmentPlanPage();
        break;

      case calculator:
        page = const InvestmentCalculatorPage();
        break;

      case goals:
        page = const GoalsPage();
        break;

      case monthlyReport:
        page = const MonthlyReportPage();
        break;

      case missions:
        page = const MissionsPage();
        break;

      case transactions:
        page = const TransactionsPage();
        break;

      case insights:
        page = const InsightsPage();
        break;

      case profile:
        page = const ProfilePage();
        break;

      case budgets:
        page = const BudgetsPage();
        break;

      case debts:
        page = const DebtsPage();
        break;

      case premium:
        final args = settings.arguments;
        final initialPlan = args is Map<String, dynamic>
            ? args['plan']?.toString()
            : (args is Map ? args['plan']?.toString() : null);
        page = PremiumPage(initialPlan: initialPlan);
        break;

      default:
        page = _UnknownRoutePage(routeName: settings.name);
        break;
    }

    // Determine if it's an auth/unauthenticated screen
    final isAuthScreen = [
      login,
      register,
      forgotPassword,
      resetPassword,
      onboarding,
      securityLock
    ].contains(settings.name);

    if (isAuthScreen) {
      return MaterialPageRoute(builder: (_) => page, settings: settings);
    } else {
      return MaterialPageRoute(
        builder: (_) => WebLayoutWrapper(routeName: settings.name, child: page),
        settings: settings,
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
