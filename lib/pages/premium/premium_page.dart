import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import '../../services/billing_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({
    super.key,
    this.initialPlan,
  });

  final String? initialPlan;

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _openingCheckout = false;
  String? _error;
  late String _selectedPlan; // monthly | yearly

  String _t(String key, String fallback) {
    final value = AppStrings.t(context, key);
    return value == key ? fallback : value;
  }

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan == 'yearly' ? 'yearly' : 'monthly';
  }

  Future<void> _openCheckout() async {
    if (_openingCheckout) return;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim() ?? '';
    if (uid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = _t(
          'premium_checkout_login_required',
          'Entre na conta para continuar.',
        );
      });
      return;
    }

    final email = user?.email?.trim();
    final checkoutUri = BillingService.buildPaddleCheckoutUri(
      uid: uid,
      plan: _selectedPlan,
      email: email,
      successUrl: BillingService.paddlePremiumSuccessUrl,
    );

    setState(() {
      _openingCheckout = true;
      _error = null;
    });

    try {
      final launched = await launchUrl(
        checkoutUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('launch-failed');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'premium_checkout_opened_snack',
              'Checkout aberto. Conclua a assinatura no navegador.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel abrir a assinatura agora.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _openingCheckout = false;
        });
      }
    }
  }

  Widget _planTile({
    required String planKey,
    required String title,
    required String price,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedPlan == planKey;

    return InkWell(
      onTap: () => setState(() => _selectedPlan = planKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.45)
              : scheme.surface,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('premium_badge', 'Premium')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t('unlock_premium_title', 'Desbloqueie Voolo Premium'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'premium_feature_desc',
                'Missoes, metas, relatorios e simuladores para acelerar seus resultados.',
              ),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      'premium_checkout_secure_title',
                      'Pagamento seguro',
                    ),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'premium_checkout_secure_body',
                      'A assinatura abre no navegador e fica vinculada à sua conta. Não há compra dentro do app.',
                    ),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _planTile(
              planKey: 'monthly',
              title: _t(
                'premium_checkout_monthly_title',
                'Plano mensal',
              ),
              price: 'R\$ 29,99 / mes',
              subtitle: _t(
                'premium_checkout_monthly_subtitle',
                '7 dias de teste. Cancele quando quiser.',
              ),
            ),
            const SizedBox(height: 10),
            _planTile(
              planKey: 'yearly',
              title: _t(
                'premium_checkout_yearly_title',
                'Plano anual',
              ),
              price: 'R\$ 299,99 / ano',
              subtitle: _t(
                'premium_checkout_yearly_subtitle',
                '7 dias de teste. Melhor custo-beneficio para manter o Premium.',
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: scheme.surface,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      'premium_checkout_includes_title',
                      'O que você libera',
                    ),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _featureItem(
                    _t(
                      'premium_checkout_feature_1',
                      'Relatórios inteligentes e detalhes premium.',
                    ),
                  ),
                  _featureItem(
                    _t(
                      'premium_checkout_feature_2',
                      'Metas, missões e insights avançados.',
                    ),
                  ),
                  _featureItem(
                    _t(
                      'premium_checkout_feature_3',
                      'Acesso contínuo enquanto a assinatura estiver ativa.',
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: scheme.error),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _openingCheckout ? null : _openCheckout,
                child: _openingCheckout
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _t(
                          'premium_checkout_cta',
                          'Continuar',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                'premium_checkout_footer',
                'Depois de concluir a assinatura, volte ao app. O status premium sera atualizado pelo servidor.',
              ),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
