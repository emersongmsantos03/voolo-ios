import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:jetx/main.dart' as app;
import 'package:jetx/models/expense.dart';
import 'package:jetx/models/monthly_dashboard.dart';
import 'package:jetx/models/user_profile.dart';
import 'package:jetx/routes/app_routes.dart';
import 'package:jetx/services/local_database_service.dart';
import 'package:jetx/services/local_storage_service.dart';
import 'package:jetx/state/locale_state.dart';
import 'package:jetx/state/privacy_state.dart';
import 'package:jetx/state/theme_state.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures App Store screenshots', (tester) async {
    await _prepareDemoData();

    await _captureRoute(tester, AppRoutes.login);
    await binding.takeScreenshot('01_login');

    await _captureRoute(tester, AppRoutes.dashboard);
    await binding.takeScreenshot('02_dashboard');

    await _captureRoute(tester, AppRoutes.addExpense);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_add_expense');

    await _captureRoute(tester, AppRoutes.profile);
    await binding.takeScreenshot('04_profile');

    await _captureRoute(tester, AppRoutes.investmentCalculator);
    await binding.takeScreenshot('05_calculator');

    await _captureRoute(tester, AppRoutes.premium);
    await binding.takeScreenshot('06_premium');
  });
}

Future<void> _prepareDemoData() async {
  LocalStorageService.configureCloud(enabled: false);
  await LocalDatabaseService.init();

  final users = await LocalDatabaseService.getUsers();
  UserProfile? demoUser;
  for (final user in users) {
    if (user.email.toLowerCase() == 'emerson@jetx.com') {
      demoUser = user;
      break;
    }
  }
  if (demoUser == null) {
    throw StateError('Demo user emerson@jetx.com was not found.');
  }

  final now = DateTime.now();
  final currentMonthDashboard = MonthlyDashboard(
    month: now.month,
    year: now.year,
    salary: demoUser.monthlyIncome > 0 ? demoUser.monthlyIncome : 5000,
    expenses: [
      Expense(
        id: 'shot-rent',
        name: 'Aluguel',
        type: ExpenseType.fixed,
        category: ExpenseCategory.moradia,
        amount: 1800,
        date: DateTime(now.year, now.month, 5),
        dueDay: 5,
      ),
      Expense(
        id: 'shot-food',
        name: 'Mercado',
        type: ExpenseType.variable,
        category: ExpenseCategory.alimentacao,
        amount: 650,
        date: DateTime(now.year, now.month, 12),
      ),
      Expense(
        id: 'shot-invest',
        name: 'Investimento',
        type: ExpenseType.investment,
        category: ExpenseCategory.investment,
        amount: 500,
        date: DateTime(now.year, now.month, 25),
      ),
    ],
  );

  await LocalDatabaseService.upsertUser(
    demoUser.copyWith(
      setupCompleted: true,
      isPremium: true,
    ),
  );
  final dashboards = await LocalDatabaseService.getDashboards(demoUser.email);
  await LocalDatabaseService.replaceDashboards(
    demoUser.email,
    [
      ...dashboards,
      currentMonthDashboard,
    ],
  );

  await LocalStorageService.init();
  await LocalStorageService.setCurrentUser(demoUser.email);
  await LocalStorageService.markDashboardEssentialGuideSeen();
}

Future<void> _captureRoute(WidgetTester tester, String routeName) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeState()),
        ChangeNotifierProvider(create: (_) => LocaleState()),
        ChangeNotifierProvider(create: (_) => PrivacyState()),
      ],
      child: app.JetxApp(initialRoute: routeName),
    ),
  );
  await tester.pumpAndSettle();
}
