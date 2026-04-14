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

    if (bootstrap.firebaseReady) {
      FirebaseAuth.instance.authStateChanges().listen((authUser) {
        if (authUser != null) return;
        final navigator = _navKey.currentState;
        if (navigator == null) return;
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      });
    }

    _launchApp(bootstrap.initialRoute);
  }, (error, stack) {
    debugPrint('Bootstrap error: $error');
    debugPrintStack(stackTrace: stack);
    _launchApp(AppRoutes.login);
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

  try {
    LocalStorageService.configureCloud(enabled: firebaseReady);
    await DateUtilsJetx.init();
    await LocalDatabaseService.init();
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
            user.objectives.isEmpty);
    final initialRoute = user == null
        ? AppRoutes.login
        : (await SecurityLockService.requiresUnlockForCurrentUser()
            ? AppRoutes.securityLock
            : (needsSetup ? AppRoutes.onboarding : AppRoutes.dashboard));

    return _BootstrapResult(
      firebaseReady: firebaseReady,
      initialRoute: initialRoute,
    );
  } catch (e, stack) {
    debugPrint('Bootstrap fallback to login after error: $e');
    debugPrintStack(stackTrace: stack);
    LocalStorageService.configureCloud(enabled: false);
    return const _BootstrapResult(
      firebaseReady: false,
      initialRoute: AppRoutes.login,
    );
  }
}

void _launchApp(String initialRoute) {
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
  final String initialRoute;

  const _BootstrapResult({
    required this.firebaseReady,
    required this.initialRoute,
  });
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
