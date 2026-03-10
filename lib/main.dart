import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/date_utils.dart';
import 'routes/app_routes.dart';
import 'services/local_database_service.dart';
import 'services/local_storage_service.dart';
import 'services/security_lock_service.dart';
import 'state/locale_state.dart';
import 'state/privacy_state.dart';
import 'state/theme_state.dart';
import 'widgets/offline_banner.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const screenshotMode =
      bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);
  const screenshotInitialRoute = String.fromEnvironment(
    'SCREENSHOT_INITIAL_ROUTE',
    defaultValue: '',
  );

  if (screenshotMode) {
    final initialRoute = screenshotInitialRoute.isEmpty
        ? AppRoutes.login
        : screenshotInitialRoute;
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeState()),
          ChangeNotifierProvider(create: (_) => LocaleState()),
          ChangeNotifierProvider(create: (_) => PrivacyState()),
        ],
        child: JetxApp(initialRoute: initialRoute),
      ),
    );
    return;
  }

  var firebaseReady = false;
  var initialRoute = AppRoutes.login;

  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  try {
    await DateUtilsJetx.init().timeout(const Duration(seconds: 2));
  } catch (_) {}

  try {
    await LocalDatabaseService.init().timeout(const Duration(seconds: 3));
  } catch (_) {}

  // Firebase-dependent initialization must never block app startup.
  if (firebaseReady) {
    try {
      await LocalStorageService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (LocalStorageService.currentUserId != null) {
        await LocalStorageService.waitForSync(timeoutSeconds: 2);
      }

      final user = LocalStorageService.getUserProfile();
      final needsSetup = user != null &&
          (!user.setupCompleted ||
              user.profession.trim().isEmpty ||
              user.monthlyIncome <= 0 ||
              user.objectives.isEmpty);

      initialRoute = user == null
          ? AppRoutes.login
          : (await SecurityLockService.requiresUnlockForCurrentUser()
              ? AppRoutes.securityLock
              : (needsSetup ? AppRoutes.onboarding : AppRoutes.dashboard));
    } catch (_) {
      initialRoute = AppRoutes.login;
    }

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
      child: firebaseReady
          ? JetxApp(initialRoute: initialRoute)
          : const _StartupErrorApp(),
    ),
  );
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

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voolo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.error_outline_rounded, size: 42),
                    SizedBox(height: 12),
                    Text(
                      'Nao foi possivel iniciar o app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A configuracao do Firebase para iOS nao foi carregada (GoogleService-Info.plist). Verifique o build de release e tente novamente.',
                      textAlign: TextAlign.center,
                    ),
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
