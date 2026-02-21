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
    final birthText = birthDate == null
        ? 'Selecionar'
        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'register'))),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: ListView(
          children: [
            Text(
              _step == 0
                  ? 'Passo 1 de 2: Seus dados basicos'
                  : 'Passo 2 de 2: Seguranca da conta',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _step == 0 ? 0.5 : 1),
            const SizedBox(height: 18),
            if (_step == 0) ...[
              _LabeledField(
                label: AppStrings.t(context, 'first_name'),
                child: TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(hintText: 'Ex: Joao'),
                ),
              ),
              const SizedBox(height: 14),
              _LabeledField(
                label: AppStrings.t(context, 'last_name'),
                child: TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(hintText: 'Ex: Silva'),
                ),
              ),
              const SizedBox(height: 14),
              _LabeledField(
                label: AppStrings.t(context, 'email'),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(hintText: 'nome@dominio.com'),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.t(context, 'birth_date')),
                subtitle: Text(
                  birthText,
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                trailing: const Icon(Icons.calendar_month, color: Colors.amber),
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _genderOptions.contains(gender)
                    ? gender
                    : _genderOptions.first,
                decoration:
                    InputDecoration(labelText: AppStrings.t(context, 'gender')),
                items: _genderOptions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(AppStrings.t(context, 'gender_$value')),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => gender = v ?? _genderOptions.first),
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
                        setState(() => _obscurePassword = !_obscurePassword);
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
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
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
              CheckboxListTile(
                value: acceptedTerms,
                onChanged: (v) => setState(() => acceptedTerms = v ?? false),
                title: Text(AppStrings.t(context, 'register_terms_text')),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppStrings.t(context, 'register_action')),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
