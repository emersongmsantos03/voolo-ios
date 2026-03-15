import 'package:flutter/material.dart';

// Auth
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';

// Onboarding
import '../pages/onboarding/onboarding_page.dart';

// Dashboard
import '../pages/dashboard/dashboard_page.dart';

// Expenses
import '../pages/expenses/add_expense_page.dart';

// Investments
import '../pages/investments/investment_calculator_page.dart';

// Goals
import '../pages/goals/goals_page.dart';

// Reports
import '../pages/reports/monthly_report_page.dart';

// Profile
import '../pages/profile/profile_page.dart';

class AppRoutes {
  AppRoutes._();

  // Route names
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';

  static const String dashboard = '/dashboard';

  static const String addExpense = '/add-expense';
  static const String investmentCalculator = '/investment-calculator';
  static const String goals = '/goals';
  static const String monthlyReport = '/monthly-report';
  static const String profile = '/profile';

  /// Plug no MaterialApp:
  /// onGenerateRoute: AppRoutes.onGenerateRoute,
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      case addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpensePage());

      case investmentCalculator:
        return MaterialPageRoute(builder: (_) => const InvestmentCalculatorPage());

      case goals:
        return MaterialPageRoute(builder: (_) => const GoalsPage());

      case monthlyReport:
        return MaterialPageRoute(builder: (_) => const MonthlyReportPage());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

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
      appBar: AppBar(title: const Text('Rota não encontrada')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'A rota "${routeName ?? 'null'}" não existe.\n'
            'Verifique AppRoutes e seus Navigator.pushNamed().',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
