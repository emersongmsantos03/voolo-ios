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

  Widget _signalPill(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
        _snack(AppStrings.t(context, 'register_email_in_use'));
      } else if (e.code == 'invalid-email') {
        _snack('Digite um e-mail no formato nome@dominio.com');
      } else if (e.code == 'weak-password') {
        _snack(AppStrings.t(context, 'register_weak_password'));
      } else if (e.code == 'operation-not-allowed') {
        _snack(AppStrings.t(context, 'register_email_not_enabled'));
      } else if (e.code == 'network-request-failed') {
        _snack(AppStrings.t(context, 'no_connection'));
      } else {
        _snack(AppStrings.tr(
            context, 'register_error_with_code', {'code': e.code}));
      }
      setState(() => _loading = false);
      return;
    } catch (_) {
      if (!mounted) return;
      _snack(AppStrings.t(context, 'error_connect_server'));
      setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    if (!created) {
      _snack(AppStrings.t(context, 'register_email_in_use'));
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
    final birthText = birthDate == null
        ? 'Selecionar'
        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';
    final stepTitle = _step == 0
        ? 'Crie sua conta para organizar o mes com mais clareza.'
        : 'Proteja sua conta e finalize a entrada no Voolo.';
    final stepSubtitle = _step == 0
        ? 'Comece com seus dados basicos. Depois o app personaliza metas, alertas e a sua rotina financeira.'
        : 'Uma senha forte deixa sua rotina segura e pronta para continuar do ponto em que voce parou.';

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'register'))),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              scheme.surfaceContainerLow,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.premiumCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == 0
                                ? 'Passo 1 de 2: Seus dados basicos'
                                : 'Passo 2 de 2: Seguranca da conta',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: _step == 0 ? 0.5 : 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: AppTheme.premiumCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stepSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _step == 0
                                ? [
                                    _signalPill(
                                      context,
                                      Icons.auto_awesome_rounded,
                                      'Configuracao rapida',
                                    ),
                                    _signalPill(
                                      context,
                                      Icons.account_balance_wallet_outlined,
                                      'Saldo e fatura claros',
                                    ),
                                    _signalPill(
                                      context,
                                      Icons.lightbulb_outline_rounded,
                                      'Insights personalizados',
                                    ),
                                  ]
                                : [
                                    _signalPill(
                                      context,
                                      Icons.lock_outline_rounded,
                                      'Conta protegida',
                                    ),
                                    _signalPill(
                                      context,
                                      Icons.fingerprint_rounded,
                                      'Acesso seguro',
                                    ),
                                    _signalPill(
                                      context,
                                      Icons.check_circle_outline,
                                      'Pronto para entrar',
                                    ),
                                  ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(
                        Responsive.isCompactPhone(context) ? 16 : 22,
                      ),
                      decoration: AppTheme.premiumCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_step == 0) ...[
                            _LabeledField(
                              label: AppStrings.t(context, 'first_name'),
                              child: TextField(
                                controller: firstNameController,
                                textInputAction: TextInputAction.next,
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
                                textInputAction: TextInputAction.next,
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
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'nome@dominio.com',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _LabeledField(
                              label: AppStrings.t(context, 'birth_date'),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: _pickBirthDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: scheme.outline.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          birthText,
                                          style: TextStyle(
                                            color:
                                                AppTheme.textPrimary(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _LabeledField(
                              label: AppStrings.t(context, 'gender'),
                              child: DropdownButtonFormField<String>(
                                initialValue: _genderOptions.contains(gender)
                                    ? gender
                                    : _genderOptions.first,
                                decoration: const InputDecoration(
                                  hintText: 'Selecione',
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
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_validateStepOne()) {
                                    setState(() => _step = 1);
                                  }
                                },
                                child: const Text('Continuar'),
                              ),
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
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
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
                                      setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      );
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
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: scheme.outline.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Para sua conta ficar mais segura:',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Use 8+ caracteres, uma letra maiuscula, uma minuscula, um numero e um simbolo.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: scheme.outline.withValues(alpha: 0.10),
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
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('Ja tenho conta'),
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
