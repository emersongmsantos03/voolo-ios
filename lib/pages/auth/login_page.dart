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
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/widgets/guided_assistance.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      _snack(AppStrings.t(context, 'error_connect_server'));
      setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    if (user == null) {
      final loginError = LocalStorageService.lastLoginError;
      if (loginError != null) {
        _snack(AppStrings.t(context, loginError));
      } else {
        _snack(AppStrings.t(context, 'login_invalid_credentials'));
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

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    UserProfile? user;
    try {
      user = await LocalStorageService.loginWithGoogle();
    } catch (_) {
      if (!mounted) return;
      _snack(AppStrings.t(context, 'login_failed_try_again'));
      setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    if (user == null) {
      final loginError = LocalStorageService.lastLoginError;
      if (loginError != null) {
        _snack(AppStrings.t(context, loginError));
      } else {
        _snack(AppStrings.t(context, 'login_failed_try_again'));
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      isDark
                          ? 'assets/branding/Logo_dark_slogan.png'
                          : 'assets/branding/Logo_light_slogan.png',
                      width: Responsive.clampLogoWidth(
                        context,
                        max: 320,
                        fraction: 0.75,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        Responsive.isCompactPhone(context) ? 16 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Acesse com seu e-mail',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: AppStrings.t(context, 'email'),
                              prefixIcon: Icon(
                                Icons.email_outlined,
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
                                Icons.lock_outline,
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
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
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
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: scheme.outline.withValues(alpha: 0.35),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  AppStrings.t(context, 'or'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: scheme.outline.withValues(alpha: 0.35),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _loginWithGoogle,
                              icon: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                height: 18,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.g_mobiledata,
                                  size: 26,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              label:
                                  Text(AppStrings.t(context, 'login_google')),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.forgotPassword,
                              );
                            },
                            child:
                                Text(AppStrings.t(context, 'forgot_password')),
                          ),
                          TextButton(
                            onPressed: () => showSupportSheet(context),
                            child: const Text('Preciso de ajuda'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      AppStrings.t(context, 'register'),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
