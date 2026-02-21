import 'package:flutter/material.dart';
import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/core/utils/password_reset_validators.dart';
import 'package:jetx/routes/app_routes.dart';
import 'package:jetx/services/password_reset_service.dart';

class ResetPasswordConfirmPage extends StatefulWidget {
  const ResetPasswordConfirmPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<ResetPasswordConfirmPage> createState() =>
      _ResetPasswordConfirmPageState();
}

class _ResetPasswordConfirmPageState extends State<ResetPasswordConfirmPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _verifyingToken = true;
  bool _tokenValid = false;
  bool _saving = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _tokenError;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    setState(() {
      _verifyingToken = true;
      _tokenValid = false;
      _tokenError = null;
    });

    try {
      final result = await PasswordResetService.verifyResetToken(token: widget.token);
      if (!mounted) return;
      if (!result.valid) {
        setState(() {
          _verifyingToken = false;
          _tokenValid = false;
          _tokenError = result.message ??
              'Este link de redefinição é inválido ou expirou. Solicite um novo link.';
        });
        return;
      }
      setState(() {
        _verifyingToken = false;
        _tokenValid = true;
      });
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyingToken = false;
        _tokenValid = false;
        if (e.isRateLimited) {
          _tokenError = AppStrings.t(context, 'reset_rate_limited');
        } else if (e.isServerError) {
          _tokenError = AppStrings.t(context, 'error_connect_server');
        } else {
          _tokenError =
              'Este link de redefinição é inválido ou expirou. Solicite um novo link.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifyingToken = false;
        _tokenValid = false;
        _tokenError = AppStrings.t(context, 'error_connect_server');
      });
    }
  }

  Future<void> _confirmReset() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    final password = _newPasswordController.text;

    setState(() => _saving = true);

    try {
      await PasswordResetService.confirmReset(
        token: widget.token,
        newPassword: password,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha redefinida com sucesso. Faça login novamente.'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      if (e.isRateLimited) {
        _showSnack(AppStrings.t(context, 'reset_rate_limited'));
      } else if (e.isServerError) {
        _showSnack(AppStrings.t(context, 'error_connect_server'));
      } else if (e.isBadRequest) {
        _showSnack('Token inválido ou senha fora do padrão exigido.');
      } else {
        _showSnack(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.t(context, 'error_connect_server'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Informe uma nova senha.';
    }

    final policy = PasswordResetValidators.passwordStrength(password);
    if (!policy.isValid) {
      return AppStrings.t(context, 'register_weak_password');
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirm = value ?? '';
    if (confirm.isEmpty) {
      return 'Confirme a nova senha.';
    }
    if (confirm != _newPasswordController.text) {
      return AppStrings.t(context, 'reset_password_mismatch');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'reset_new_password_title')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.isCompactPhone(context) ? 16 : 22),
                child: _verifyingToken
                    ? const _VerifyingTokenState()
                    : _tokenValid
                        ? Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppStrings.t(
                                    context,
                                    'reset_new_password_subtitle',
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: !_showNewPassword,
                                  validator: _validateNewPassword,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppStrings.t(context, 'reset_new_password'),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _showNewPassword = !_showNewPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _showNewPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  validator: _validateConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!_saving) _confirmReset();
                                  },
                                  decoration: InputDecoration(
                                    labelText: AppStrings.t(
                                      context,
                                      'reset_confirm_password',
                                    ),
                                    prefixIcon: const Icon(Icons.verified_user_outlined),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _showConfirmPassword =
                                              !_showConfirmPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _showConfirmPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _confirmReset,
                                    child: _saving
                                        ? SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: scheme.onPrimary,
                                            ),
                                          )
                                        : Text(
                                            AppStrings.t(context, 'reset_confirm_button'),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _InvalidTokenState(
                            message: _tokenError ??
                                'Não foi possível validar este link de redefinição.',
                            onRetry: _verifyToken,
                            onRequestNewLink: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.forgotPassword,
                                (route) => route.settings.name == AppRoutes.login,
                              );
                            },
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifyingTokenState extends StatelessWidget {
  const _VerifyingTokenState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Validando link de redefinição...',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InvalidTokenState extends StatelessWidget {
  const _InvalidTokenState({
    required this.message,
    required this.onRetry,
    required this.onRequestNewLink,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onRequestNewLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: scheme.error,
          size: 34,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onRequestNewLink,
            child: const Text('Solicitar novo link'),
          ),
        ),
      ],
    );
  }
}
