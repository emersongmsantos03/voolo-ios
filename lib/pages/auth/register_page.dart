import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/catalogs/gender_catalog.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/responsive.dart';
import '../../core/utils/password_policy.dart';
import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const bool _appPreviewMode =
      bool.fromEnvironment('APP_PREVIEW_MODE', defaultValue: false);
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DateTime? birthDate;
  String gender = GenderCatalog.notInformed;
  static const List<String> _genderOptions = GenderCatalog.codes;

  bool acceptedTerms = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _step = 0;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => birthDate = date);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _registerFeedback(String base) {
    final diagnostic = LocalStorageService.lastAuthDiagnostic;
    if (diagnostic == null || diagnostic.trim().isEmpty) {
      return base;
    }
    final lower = diagnostic.toLowerCase();
    if (lower.contains('keychain')) {
      if (_appPreviewMode) {
        return 'O cadastro do Firebase no App Preview iOS ainda esta bloqueado pelo Keychain do simulator. '
            'Teste o cadastro no build assinado do iPhone/TestFlight. '
            '[$diagnostic]';
      }
      return 'O iPhone nao conseguiu acessar o Keychain para salvar a sessao. '
          'Isso costuma indicar problema de signing/entitlements no build iOS. '
          '[$diagnostic]';
    }
    return '$base [$diagnostic]';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  bool _validateStepOne() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();

    if (firstName.isEmpty) {
      _snack('Digite seu nome. Exemplo: Maria.');
      return false;
    }
    if (lastName.isEmpty) {
      _snack('Digite seu sobrenome. Exemplo: Souza.');
      return false;
    }
    if (!_isValidEmail(email)) {
      _snack('Digite um e-mail no formato nome@dominio.com');
      return false;
    }
    if (birthDate == null) {
      _snack('Escolha sua data de nascimento para continuar.');
      return false;
    }
    return true;
  }

  bool _validateStepTwo() {
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (password.isEmpty) {
      _snack('Crie sua senha para proteger sua conta.');
      return false;
    }
    if (confirm.isEmpty || password != confirm) {
      _snack('As senhas precisam ser iguais. Tente novamente.');
      return false;
    }

    final passwordCheck = PasswordPolicy.evaluate(password);
    if (!passwordCheck.isValid) {
      _snack(
          'Sua senha precisa ter 8+ caracteres, letra maiuscula, minuscula, numero e simbolo. Exemplo: Casa@2026');
      return false;
    }

    if (!acceptedTerms) {
      _snack(AppStrings.t(context, 'register_terms_required'));
      return false;
    }
    return true;
  }

  Future<void> _register() async {
    if (!_validateStepTwo()) return;
    setState(() => _loading = true);

    final user = UserProfile(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      birthDate: birthDate!,
      profession: '',
      monthlyIncome: 0,
      gender: gender,
      photoPath: null,
      setupCompleted: false,
      objectives: const [],
      totalXp: 0,
    );

    bool created;
    try {
      created = await LocalStorageService.createAccount(user);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        _snack(
            _registerFeedback(AppStrings.t(context, 'register_email_in_use')));
      } else if (e.code == 'invalid-email') {
        _snack(
            _registerFeedback('Digite um e-mail no formato nome@dominio.com'));
      } else if (e.code == 'weak-password') {
        _snack(
            _registerFeedback(AppStrings.t(context, 'register_weak_password')));
      } else if (e.code == 'operation-not-allowed') {
        _snack(_registerFeedback(
            AppStrings.t(context, 'register_email_not_enabled')));
      } else if (e.code == 'network-request-failed') {
        _snack(_registerFeedback(AppStrings.t(context, 'no_connection')));
      } else {
        _snack(_registerFeedback(
          AppStrings.tr(context, 'register_error_with_code', {'code': e.code}),
        ));
      }
      setState(() => _loading = false);
      return;
    } catch (_) {
      if (!mounted) return;
      _snack(_registerFeedback(AppStrings.t(context, 'error_connect_server')));
      setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    if (!created) {
      _snack(_registerFeedback(AppStrings.t(context, 'register_email_in_use')));
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = false);
    _snack(AppStrings.t(context, 'register_success'));
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final birthText = birthDate == null
        ? 'Selecionar'
        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';

    return Scaffold(
      body: Stack(
        children: [
          _RegisterBackdrop(isDark: isDark),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: Responsive.pagePadding(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 468),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Criar conta',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: AppTheme.panelDecoration(context),
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _step == 0 ? 'Passo 1 de 2' : 'Passo 2 de 2',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _step == 0
                                  ? 'Vamos montar seu perfil inicial'
                                  : 'Proteja sua conta com uma senha forte',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _step == 0
                                  ? 'Coletamos só o essencial para personalizar metas, relatórios e missões.'
                                  : 'Mais segurança agora, menos atrito depois.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _step == 0 ? 0.5 : 1,
                                minHeight: 10,
                                backgroundColor:
                                    scheme.outline.withValues(alpha: 0.18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration:
                            AppTheme.panelDecoration(context, highlighted: true),
                        padding: EdgeInsets.all(
                          Responsive.isCompactPhone(context) ? 18 : 24,
                        ),
                        child: Column(
                          children: [
                            if (_step == 0) ...[
                              _LabeledField(
                                label: AppStrings.t(context, 'first_name'),
                                child: TextField(
                                  controller: firstNameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: Joao',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _LabeledField(
                                label: AppStrings.t(context, 'last_name'),
                                child: TextField(
                                  controller: lastNameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: Silva',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _LabeledField(
                                label: AppStrings.t(context, 'email'),
                                child: TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'nome@dominio.com',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                decoration: BoxDecoration(
                                  color: scheme.surface.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        scheme.outline.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(AppStrings.t(context, 'birth_date')),
                                  subtitle: Text(
                                    birthText,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.calendar_month_rounded,
                                    color: scheme.primary,
                                  ),
                                  onTap: _pickBirthDate,
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue: _genderOptions.contains(gender)
                                    ? gender
                                    : _genderOptions.first,
                                decoration: InputDecoration(
                                  labelText: AppStrings.t(context, 'gender'),
                                ),
                                items: _genderOptions
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(
                                          AppStrings.t(
                                            context,
                                            'gender_$value',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => gender = v ?? _genderOptions.first,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  if (_validateStepOne()) {
                                    setState(() => _step = 1);
                                  }
                                },
                                child: const Text('Continuar'),
                              ),
                            ] else ...[
                              _LabeledField(
                                label: AppStrings.t(context, 'password'),
                                child: TextField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: 'Crie uma senha forte',
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
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _LabeledField(
                                label: AppStrings.t(context, 'confirm_password'),
                                child: TextField(
                                  controller: confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Repita a senha',
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: scheme.surface.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        scheme.outline.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: acceptedTerms,
                                  onChanged: (v) => setState(
                                    () => acceptedTerms = v ?? false,
                                  ),
                                  title: Text(
                                    AppStrings.t(
                                      context,
                                      'register_terms_text',
                                    ),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              setState(() => _step = 0);
                                            },
                                      child: const Text('Voltar'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _register,
                                      child: _loading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              AppStrings.t(
                                                context,
                                                'register_action',
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

class _RegisterBackdrop extends StatelessWidget {
  final bool isDark;

  const _RegisterBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.authBackground(context)),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -40,
            child: _RegisterOrb(
              size: 220,
              color: AppTheme.gold.withValues(alpha: isDark ? 0.12 : 0.16),
            ),
          ),
          Positioned(
            right: -30,
            top: 220,
            child: _RegisterOrb(
              size: 180,
              color: AppTheme.yellow.withValues(alpha: isDark ? 0.09 : 0.13),
            ),
          ),
          Positioned(
            bottom: -60,
            left: 30,
            child: _RegisterOrb(
              size: 190,
              color: const Color(0xFFB98D1A)
                  .withValues(alpha: isDark ? 0.12 : 0.09),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _RegisterOrb({required this.size, required this.color});

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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}
