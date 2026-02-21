import 'package:flutter/material.dart';

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
    if (user.monthlyIncome <= 0) return true;
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
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 42, color: scheme.primary),
                      const SizedBox(height: 12),
                      const Text(
                        'Area protegida',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use digital, Face ID ou a senha do aparelho para acessar suas financas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.fingerprint),
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
