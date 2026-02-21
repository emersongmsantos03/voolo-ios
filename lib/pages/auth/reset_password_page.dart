import 'package:flutter/material.dart';
import 'package:jetx/core/localization/app_strings.dart';
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/core/utils/password_reset_validators.dart';
import 'package:jetx/services/password_reset_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const String _neutralMessage =
      'Se este e-mail existir, enviaremos um link de redefinição.';

  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _feedback;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _feedback = null;
    });

    final email = _emailController.text.trim().toLowerCase();

    try {
      await PasswordResetService.requestResetLink(email: email);
      if (!mounted) return;
      setState(() => _feedback = _neutralMessage);
    } on PasswordResetException catch (e) {
      if (!mounted) return;

      setState(() => _feedback = _neutralMessage);

      if (e.isRateLimited) {
        _showSnack(AppStrings.t(context, 'reset_rate_limited'));
      } else if (e.isServerError) {
        _showSnack(AppStrings.t(context, 'error_connect_server'));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _feedback = _neutralMessage);
      _showSnack(AppStrings.t(context, 'error_connect_server'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return AppStrings.t(context, 'reset_need_email');
    }

    if (!PasswordResetValidators.isValidEmail(email)) {
      return AppStrings.t(context, 'login_invalid_email');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'reset_title')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.isCompactPhone(context) ? 16 : 22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.t(context, 'reset_subtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: _validateEmail,
                        onFieldSubmitted: (_) {
                          if (!_loading) _sendLink();
                        },
                        decoration: InputDecoration(
                          labelText: AppStrings.t(context, 'email'),
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _sendLink,
                          child: _loading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Text(AppStrings.t(context, 'reset_send_button')),
                        ),
                      ),
                      if (_feedback != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _feedback!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface,
                            ),
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
      ),
    );
  }
}
