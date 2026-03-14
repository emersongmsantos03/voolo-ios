import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/date_utils.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/local_database_service.dart';
import 'services/local_storage_service.dart';
import 'services/security_lock_service.dart';
import 'state/locale_state.dart';
import 'state/privacy_state.dart';
import 'state/theme_state.dart';
import 'widgets/offline_banner.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
final ValueNotifier<_RuntimeErrorState?> _runtimeErrorNotifier =
    ValueNotifier<_RuntimeErrorState?>(null);

class _RuntimeErrorState {
  final Object error;
  final StackTrace stackTrace;

  const _RuntimeErrorState({required this.error, required this.stackTrace});
}

class _FirebaseBootstrapException implements Exception {
  final Object explicitError;
  final Object fallbackError;

  const _FirebaseBootstrapException({
    required this.explicitError,
    required this.fallbackError,
  });

  @override
  String toString() {
    return 'Firebase init failed with explicit options: '
        '$explicitError | fallback bundled config failed: $fallbackError';
  }
}

void _reportFatalError(Object error, StackTrace stackTrace) {
  debugPrint('Fatal runtime error: $error');
  debugPrint('$stackTrace');
  _runtimeErrorNotifier.value =
      _RuntimeErrorState(error: error, stackTrace: stackTrace);
}

void _runGuardedApp(Widget app) {
  runApp(
    ValueListenableBuilder<_RuntimeErrorState?>(
      valueListenable: _runtimeErrorNotifier,
      builder: (context, runtimeError, _) {
        if (runtimeError != null) {
          return _RuntimeErrorApp(runtimeError: runtimeError);
        }
        return app;
      },
    ),
  );
}

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _reportFatalError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        _reportFatalError(error, stackTrace);
        return true;
      };
      await _bootstrapApp();
    },
    _reportFatalError,
  );
}

Future<void> _bootstrapApp() async {
  final previewStableMode = await _resolvePreviewStableMode();
  const screenshotMode =
      bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);
  const previewForceLogin =
      bool.fromEnvironment('PREVIEW_FORCE_LOGIN', defaultValue: false);
  const screenshotInitialRoute = String.fromEnvironment(
    'SCREENSHOT_INITIAL_ROUTE',
    defaultValue: '',
  );

  if (previewStableMode) {
    _runGuardedApp(const _PreviewStableApp());
    return;
  }

  if (screenshotMode) {
    final initialRoute = screenshotInitialRoute.isEmpty
        ? AppRoutes.login
        : screenshotInitialRoute;
    _runGuardedApp(
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
  Object? firebaseInitError;
  var initialRoute = AppRoutes.login;

  try {
    await _initializeFirebase().timeout(const Duration(seconds: 8));
    firebaseReady = true;
  } catch (error, stackTrace) {
    firebaseReady = false;
    firebaseInitError = error;
    debugPrint('Firebase bootstrap failed: $error');
    debugPrint('$stackTrace');
  }

  if (firebaseReady && previewForceLogin) {
    try {
      await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 3));
    } catch (_) {}
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

      initialRoute = previewForceLogin
          ? AppRoutes.login
          : user == null
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

  _runGuardedApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeState()),
        ChangeNotifierProvider(create: (_) => LocaleState()),
        ChangeNotifierProvider(create: (_) => PrivacyState()),
      ],
      child: firebaseReady
          ? JetxApp(initialRoute: initialRoute)
          : _StartupErrorApp(details: firebaseInitError?.toString()),
    ),
  );
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  late final Object explicitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized with explicit mobile options.');
    return;
  } catch (error, stackTrace) {
    explicitError = error;
    debugPrint('Firebase explicit init failed: $error');
    debugPrint('$stackTrace');
  }

  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized with bundled platform config.');
  } catch (error, stackTrace) {
    debugPrint('Firebase bundled-config init failed: $error');
    debugPrint('$stackTrace');
    throw _FirebaseBootstrapException(
      explicitError: explicitError,
      fallbackError: error,
    );
  }
}

Future<bool> _resolvePreviewStableMode() async {
  const compileTimeFlag =
      bool.fromEnvironment('PREVIEW_STABLE_MODE', defaultValue: false);
  if (compileTimeFlag) return true;

  try {
    const channel = MethodChannel('voolo/bootstrap');
    final nativeFlag = await channel
        .invokeMethod<bool>('isPreviewStableMode')
        .timeout(const Duration(seconds: 2));
    return nativeFlag ?? false;
  } catch (_) {
    return false;
  }
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
  final String? details;

  const _StartupErrorApp({this.details});

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
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'Nao foi possivel iniciar o app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A configuracao do Firebase para iOS nao foi carregada (GoogleService-Info.plist). Verifique o build de release e tente novamente.',
                      textAlign: TextAlign.center,
                    ),
                    if (details != null && details!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SelectableText(
                        details!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
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

class _RuntimeErrorApp extends StatelessWidget {
  final _RuntimeErrorState runtimeError;

  const _RuntimeErrorApp({required this.runtimeError});

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
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 44),
                    const SizedBox(height: 12),
                    const Text(
                      'O app encontrou um erro inesperado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tente reabrir. Se continuar, envie o log desta execucao para suporte.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      runtimeError.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
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

class _PreviewStableApp extends StatelessWidget {
  const _PreviewStableApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voolo Preview',
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
                  children: [
                    const Icon(Icons.phone_iphone_rounded, size: 46),
                    const SizedBox(height: 12),
                    const Text(
                      'Voolo App Preview',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Modo de visualizacao estavel ativo.\nUse ios-appstore para validacao completa com Firebase.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Preview ativo'),
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
