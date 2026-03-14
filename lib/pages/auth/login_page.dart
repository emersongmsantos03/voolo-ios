import 'package:flutter/material.dart';

import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/models/user_profile.dart';
import 'package:jetx/pages/auth/register_page.dart';
import 'package:jetx/pages/onboarding/onboarding_page.dart';
import 'package:jetx/routes/app_routes.dart';
import 'package:jetx/services/firestore_service.dart';
import 'package:jetx/services/local_storage_service.dart';
import 'package:jetx/services/notification_service.dart';
import 'package:jetx/services/security_lock_service.dart';
import 'package:jetx/core/theme/app_theme.dart';
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/widgets/guided_assistance.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const bool _appPreviewMode =
      bool.fromEnvironment('APP_PREVIEW_MODE', defaultValue: false);
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);

    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _snack(AppStrings.t(context, 'login_fill_email_password'));
      setState(() => _loading = false);
      return;
    }
    if (!_isValidEmail(email)) {
      _snack('Digite um e-mail no formato nome@dominio.com');
      setState(() => _loading = false);
      return;
    }

    UserProfile? user;
    try {
      user = await LocalStorageService.login(email: email, password: password);
    } catch (_) {
      if (!mounted) return;
      _snack(_loginFeedbackMessage('error_connect_server'));
      setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    if (user == null) {
      final loginError = LocalStorageService.lastLoginError;
      if (loginError != null) {
        _snack(_loginFeedbackMessage(loginError));
      } else {
        _snack(_loginFeedbackMessage('login_invalid_credentials'));
      }
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginSuccessSplash()),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  String _loginFeedbackMessage(String fallbackKey) {
    final base = AppStrings.t(context, fallbackKey);
    final diagnostic = LocalStorageService.lastAuthDiagnostic;
    if (diagnostic == null || diagnostic.trim().isEmpty) {
      return base;
    }
    final lower = diagnostic.toLowerCase();
    if (lower.contains('keychain')) {
      if (_appPreviewMode) {
        return 'O login do Firebase no App Preview iOS ainda esta bloqueado pelo Keychain do simulator. '
            'Teste o login no build assinado do iPhone/TestFlight. '
            '[$diagnostic]';
      }
      return 'O iPhone nao conseguiu acessar o Keychain para salvar a sessao. '
          'Isso costuma indicar problema de signing/entitlements no build iOS. '
          '[$diagnostic]';
    }
    return '$base [$diagnostic]';
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    UserProfile? user;
    try {
      user = await LocalStorageService.loginWithGoogle();
    } catch (_) {
      if (!mounted) return;
      _snack(_loginFeedbackMessage('login_failed_try_again'));
      setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    if (user == null) {
      final loginError = LocalStorageService.lastLoginError;
      if (loginError != null) {
        _snack(_loginFeedbackMessage(loginError));
      } else {
        _snack(_loginFeedbackMessage('login_failed_try_again'));
      }
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginSuccessSplash()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          _AuthBackdrop(isDark: isDark),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: Responsive.pagePadding(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 468),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthHero(
                        logoAsset: isDark
                            ? 'assets/branding/Logo_dark_slogan.png'
                            : 'assets/branding/Logo_light_slogan.png',
                        badge: 'Voolo',
                        title: 'Sua vida financeira, finalmente organizada.',
                        subtitle:
                            'Entre para acompanhar gastos, metas, cartões e evolução do mês com clareza.',
                        chips: const [
                          'Fluxo simples',
                          'Visual premium',
                          'Feito para rotina real',
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration:
                            AppTheme.panelDecoration(context, highlighted: true),
                        child: Padding(
                          padding: EdgeInsets.all(
                            Responsive.isCompactPhone(context) ? 18 : 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Acesso seguro',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Entrar',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Use seu e-mail para continuar de onde parou.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: AppStrings.t(context, 'email'),
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                    color: scheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _loading ? null : _login(),
                                decoration: InputDecoration(
                                  labelText: AppStrings.t(context, 'password'),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: scheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: _loading ? null : _login,
                                child: _loading
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : Text(AppStrings.t(context, 'login')),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color:
                                          scheme.outline.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      AppStrings.t(context, 'or'),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color:
                                          scheme.outline.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _loading ? null : _loginWithGoogle,
                                icon: Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 28,
                                  color: scheme.primary,
                                ),
                                label: Text(
                                  AppStrings.t(context, 'login_google'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgotPassword,
                                  );
                                },
                                child: Text(
                                  AppStrings.t(context, 'forgot_password'),
                                ),
                              ),
                              TextButton(
                                onPressed: () => showSupportSheet(context),
                                child: const Text('Preciso de ajuda'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: AppTheme.panelDecoration(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Primeira vez aqui?',
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: Text(
                                AppStrings.t(context, 'register'),
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  final bool isDark;

  const _AuthBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.authBackground(context)),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -30,
            child: _GlowOrb(
              size: 220,
              color: AppTheme.gold.withValues(alpha: isDark ? 0.14 : 0.18),
            ),
          ),
          Positioned(
            left: -50,
            top: 180,
            child: _GlowOrb(
              size: 170,
              color: AppTheme.yellow.withValues(alpha: isDark ? 0.09 : 0.14),
            ),
          ),
          Positioned(
            bottom: -70,
            right: 30,
            child: _GlowOrb(
              size: 210,
              color: const Color(0xFFB98D1A)
                  .withValues(alpha: isDark ? 0.12 : 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final String logoAsset;
  final String badge;
  final String title;
  final String subtitle;
  final List<String> chips;

  const _AuthHero({
    required this.logoAsset,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: AppTheme.panelDecoration(context),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Image.asset(
            logoAsset,
            width: Responsive.clampLogoWidth(context, max: 280, fraction: 0.58),
          ),
          const SizedBox(height: 18),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (chip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      chip,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class LoginSuccessSplash extends StatefulWidget {
  const LoginSuccessSplash({super.key});

  @override
  State<LoginSuccessSplash> createState() => _LoginSuccessSplashState();
}

class _LoginSuccessSplashState extends State<LoginSuccessSplash> {
  void _snack(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _shouldOpenSetup(UserProfile? user) {
    if (user == null) return false;
    if (!user.setupCompleted) return true;
    if (user.profession.trim().isEmpty) return true;
    if (user.monthlyIncome <= 0) return true;
    if (user.objectives.isEmpty) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    // Wait for remote sync to finish (important for new devices/first login)
    await LocalStorageService.waitForSync(timeoutSeconds: 3);

    if (!mounted) return;

    final user = LocalStorageService.getUserProfile();
    _initNotifications();
    await _maybeOfferDeviceProtection();
    if (!mounted) return;

    if (_shouldOpenSetup(user)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService.init();
      final uid = LocalStorageService.currentUserId;
      if (uid == null || uid.isEmpty) return;

      // Fixed bills (recurring) reminders
      final series = await FirestoreService.getFixedSeries(uid);
      for (final s in series) {
        await NotificationService.scheduleFixedSeriesReminder(s);
      }

      // Credit card bill reminders
      final user = LocalStorageService.getUserProfile();
      final cards = user?.creditCards ?? const [];
      for (final card in cards) {
        await NotificationService.scheduleCreditCardBillReminder(card);
      }
    } catch (_) {
      // Nao bloqueia o login se notificacoes falharem.
    }
  }

  Future<void> _maybeOfferDeviceProtection() async {
    final shouldAsk =
        await SecurityLockService.shouldOfferPromptForCurrentUser();
    if (!shouldAsk || !mounted) return;

    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Proteger acesso ao app?'),
        content: const Text(
          'Deseja proteger suas financas com digital/Face ID ou senha do aparelho sempre que abrir o Voolo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora nao'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ativar protecao'),
          ),
        ],
      ),
    );

    if (choice != true) {
      await SecurityLockService.markPromptedForCurrentUser();
      return;
    }

    final authOk = await SecurityLockService.authenticate(
      reason: 'Confirme para ativar a protecao do app.',
    );
    if (!mounted) return;

    if (authOk) {
      await SecurityLockService.setEnabledForCurrentUser(true);
      await SecurityLockService.markPromptedForCurrentUser();
      _snack('Protecao ativada. O app pedira desbloqueio ao abrir.');
      return;
    }

    _snack('Nao foi possivel ativar agora. Tente novamente no proximo login.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'assets/branding/Logo_dark_slogan.png'
              : 'assets/branding/Logo_light_slogan.png',
          width: Responsive.clampLogoWidth(context, max: 390, fraction: 0.85),
        ),
      ),
    );
  }
}
