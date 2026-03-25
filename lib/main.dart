import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/date_utils.dart';
import 'models/expense.dart';
import 'models/monthly_dashboard.dart';
import 'models/user_profile.dart';
import 'routes/app_routes.dart';
import 'services/local_database_service.dart';
import 'services/local_storage_service.dart';
import 'state/locale_state.dart';
import 'state/privacy_state.dart';
import 'state/theme_state.dart';
import 'widgets/offline_banner.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
const bool _previewForceLogin = bool.fromEnvironment('PREVIEW_FORCE_LOGIN');
const bool _screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const bool _previewLocalMode = _previewForceLogin || _screenshotMode;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      debugPrintStack(stackTrace: details.stack);
    };
    ErrorWidget.builder = (details) => _FatalErrorScaffold(
          title: 'Algo saiu do esperado',
          message: 'O Voolo encontrou um erro nesta tela.',
          details: details.exceptionAsString(),
        );
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught async error: $error');
      debugPrintStack(stackTrace: stack);
      return true;
    };

    final bootstrap = await _bootstrapApp();

    if (bootstrap.cloudEnabled) {
      FirebaseAuth.instance.authStateChanges().listen((authUser) {
        if (authUser != null) return;
        final navigator = _navKey.currentState;
        if (navigator == null) return;
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      });
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeState()),
          ChangeNotifierProvider(create: (_) => LocaleState()),
          ChangeNotifierProvider(create: (_) => PrivacyState()),
        ],
        child: JetxApp(initialRoute: bootstrap.initialRoute),
      ),
    );
  }, (error, stack) {
    debugPrint('Bootstrap error: $error');
    debugPrintStack(stackTrace: stack);
    runApp(
      const _FatalApp(
        title: 'Nao foi possivel abrir o app',
        message: 'O Voolo encontrou um erro ao iniciar.',
      ),
    );
  });
}

Future<_BootstrapResult> _bootstrapApp() async {
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase bootstrap unavailable, starting in local mode: $e');
  }

  LocalStorageService.configureCloud(
    enabled: firebaseReady && !_previewLocalMode,
  );
  await DateUtilsJetx.init();
  await LocalDatabaseService.init();
  await LocalStorageService.forceLogoutOnStartup();
  await LocalStorageService.init().timeout(
    const Duration(seconds: 3),
    onTimeout: () => null,
  );

  if (_previewLocalMode) {
    await _seedPreviewSession();
  }

  if (LocalStorageService.currentUserId != null) {
    await LocalStorageService.waitForSync(timeoutSeconds: 2);
  }

  final initialRoute =
      _previewLocalMode && LocalStorageService.getUserProfile() != null
          ? AppRoutes.dashboard
          : AppRoutes.login;

  return _BootstrapResult(
    firebaseReady: firebaseReady,
    cloudEnabled: firebaseReady && !_previewLocalMode,
    initialRoute: initialRoute,
  );
}

Future<void> _seedPreviewSession() async {
  const previewEmail = 'preview@voolo.com.br';
  const previewPassword = 'Voolo123!';

  UserProfile? demoProfile;
  final accounts = LocalStorageService.getAccounts();
  for (final account in accounts) {
    if (account.email.trim().toLowerCase() == previewEmail) {
      demoProfile = account;
      break;
    }
  }

  if (demoProfile == null) {
    demoProfile = UserProfile(
      firstName: 'Emerson',
      lastName: 'Moraes',
      email: previewEmail,
      password: previewPassword,
      profession: 'Analista financeiro',
      monthlyIncome: 7200,
      gender: 'Nao informado',
      objectives: const [
        'objective_save',
        'objective_invest',
        'objective_security',
      ],
      setupCompleted: true,
      isPremium: true,
      isActive: true,
      propertyValue: 320000,
      investBalance: 28000,
    );
    final created = await LocalStorageService.createAccount(demoProfile);
    if (!created) {
      final login = await LocalStorageService.login(
        email: previewEmail,
        password: previewPassword,
      );
      if (login == null) return;
      demoProfile = login;
    }
  }

  demoProfile = demoProfile.copyWith(
    firstName: 'Emerson',
    lastName: 'Moraes',
    profession: 'Analista financeiro',
    monthlyIncome: 7200,
    setupCompleted: true,
    isPremium: true,
    objectives: const [
      'objective_save',
      'objective_invest',
      'objective_security',
    ],
    propertyValue: 320000,
    investBalance: 28000,
  );
  await LocalStorageService.saveUserProfile(demoProfile);

  final now = DateTime.now();
  final previewMonth = DateTime(now.year, now.month, 1);
  final previewDashboard = MonthlyDashboard(
    month: previewMonth.month,
    year: previewMonth.year,
    salary: demoProfile.monthlyIncome,
    expenses: [
      Expense(
        id: 'preview-rent',
        name: 'Aluguel',
        type: ExpenseType.fixed,
        category: ExpenseCategory.moradia,
        amount: 2100,
        date: DateTime(now.year, now.month, 5),
        dueDay: 5,
      ),
      Expense(
        id: 'preview-groceries',
        name: 'Mercado',
        type: ExpenseType.variable,
        category: ExpenseCategory.alimentacao,
        amount: 860,
        date: DateTime(now.year, now.month, 12),
      ),
      Expense(
        id: 'preview-transport',
        name: 'Transporte',
        type: ExpenseType.variable,
        category: ExpenseCategory.transporte,
        amount: 320,
        date: DateTime(now.year, now.month, 18),
      ),
      Expense(
        id: 'preview-invest',
        name: 'Investimento',
        type: ExpenseType.investment,
        category: ExpenseCategory.investment,
        amount: 950,
        date: DateTime(now.year, now.month, 22),
      ),
    ],
  );
  await LocalStorageService.saveDashboard(previewDashboard);
}

class JetxApp extends StatelessWidget {
  final String initialRoute;

  const JetxApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeState, LocaleState>(
      builder: (context, themeState, localeState, _) => MaterialApp(
        title: 'Voolo',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeState.mode,
        locale: localeState.locale,
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => OfflineBanner(
          child: child ?? const SizedBox.shrink(),
        ),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: initialRoute,
      ),
    );
  }
}

class _BootstrapResult {
  final bool firebaseReady;
  final bool cloudEnabled;
  final String initialRoute;

  const _BootstrapResult({
    required this.firebaseReady,
    required this.cloudEnabled,
    required this.initialRoute,
  });
}

class _FatalApp extends StatelessWidget {
  final String title;
  final String message;

  const _FatalApp({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voolo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _FatalErrorScaffold(title: title, message: message),
    );
  }
}

class _FatalErrorScaffold extends StatelessWidget {
  final String title;
  final String message;
  final String? details;

  const _FatalErrorScaffold({
    required this.title,
    required this.message,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.premiumCardDecoration(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: scheme.error,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                    if (details != null && details!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          details!,
                          style: TextStyle(
                            color: AppTheme.textMuted(context),
                            fontSize: 12,
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
