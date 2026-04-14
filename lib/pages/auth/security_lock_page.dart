import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/responsive.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';
import '../../services/security_lock_service.dart';

class SecurityLockPage extends StatefulWidget {
  const SecurityLockPage({super.key});

  @override
  State<SecurityLockPage> createState() => _SecurityLockPageState();
}

class _SecurityLockPageState extends State<SecurityLockPage> {
  bool _loading = false;
  String? _error;

  bool _needsSetup() {
    final user = LocalStorageService.getUserProfile();
    if (user == null) return false;
    if (!user.setupCompleted) return true;
    if (user.profession.trim().isEmpty) return true;
    if (user.objectives.isEmpty) return true;
    return false;
  }

  Future<void> _unlock() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await SecurityLockService.authenticate(
      reason: 'Desbloqueie para acessar suas financas no Voolo.',
    );
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _loading = false;
        _error =
            'Nao foi possivel desbloquear. Use sua digital ou a senha do aparelho.';
      });
      return;
    }

    final target = _needsSetup() ? AppRoutes.onboarding : AppRoutes.dashboard;
    Navigator.pushNamedAndRemoveUntil(context, target, (route) => false);
  }

  Future<void> _logout() async {
    await LocalStorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
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
                          color: scheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          size: 34,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Area protegida',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use digital, Face ID ou a senha do aparelho para acessar suas financas com seguranca.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_clock_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Seu app continua exatamente de onde voce parou apos a validacao.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _unlock,
                          icon: _loading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.fingerprint_rounded),
                          label: Text(
                            _loading ? 'Validando...' : 'Desbloquear',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading ? null : _logout,
                        child: const Text('Sair desta conta'),
                      ),
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
