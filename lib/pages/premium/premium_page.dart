import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/legal_links.dart';
import '../../core/localization/app_strings.dart';
import '../../services/billing_service.dart';
import '../../services/local_storage_service.dart';

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
  bool _openingPortal = false;
  String? _error;
  late String _selectedPlan; // monthly | yearly
  bool _iapAvailable = false;
  bool _loadingProducts = false;
  List<ProductDetails> _productDetails = const [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool get _usesAppleIap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static const _SubscriptionPlanInfo _monthlyPlan = _SubscriptionPlanInfo(
    key: 'monthly',
    title: 'Voolo Monthly',
    durationLabel: '1 month',
    priceSuffix: '/month',
    fallbackPrice: 'R\$ 29,90/month',
    subtitle:
        'Includes premium reports, missions, insights, and the investment calculator while active. Auto-renews until canceled.',
  );

  static const _SubscriptionPlanInfo _yearlyPlan = _SubscriptionPlanInfo(
    key: 'yearly',
    title: 'Voolo Yearly',
    durationLabel: '1 year',
    priceSuffix: '/year',
    fallbackPrice: 'R\$ 299,90/year',
    subtitle:
        'Includes premium reports, missions, insights, and the investment calculator for the full subscription period. Auto-renews until canceled.',
  );

  String _t(String key, String fallback) {
    final value = AppStrings.t(context, key);
    return value == key ? fallback : value;
  }

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan == 'yearly' ? 'yearly' : 'monthly';
    _setupBillingFlow();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _setupBillingFlow() async {
    if (!_usesAppleIap) return;

    _purchaseSub ??= InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = _t(
            'premium_checkout_open_error',
            'Nao foi possivel abrir a assinatura agora.',
          );
          _openingCheckout = false;
        });
      },
    );

    final available = await InAppPurchase.instance.isAvailable();
    if (!mounted) return;
    setState(() {
      _iapAvailable = available;
    });

    if (available) {
      await _loadAppleProducts();
    }
  }

  Future<void> _loadAppleProducts() async {
    if (!_usesAppleIap) return;
    setState(() {
      _loadingProducts = true;
      _error = null;
    });

    final response = await InAppPurchase.instance.queryProductDetails({
      BillingService.appleMonthlySubscriptionId,
      BillingService.appleYearlySubscriptionId,
    });

    if (!mounted) return;
    setState(() {
      _productDetails = response.productDetails;
      _loadingProducts = false;
    });

    if (response.notFoundIDs.isNotEmpty && _productDetails.isEmpty) {
      setState(() {
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel carregar os planos da App Store agora.',
        );
      });
    }
  }

  ProductDetails? _appleProductForPlan(String plan) {
    final productId = plan == 'yearly'
        ? BillingService.appleYearlySubscriptionId
        : BillingService.appleMonthlySubscriptionId;
    try {
      return _productDetails.firstWhere((product) => product.id == productId);
    } catch (_) {
      return null;
    }
  }

  String _planPriceLabel(_SubscriptionPlanInfo plan) {
    final product = _appleProductForPlan(plan.key);
    if (product != null) return '${product.price}${plan.priceSuffix}';
    return plan.fallbackPrice;
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          if (!mounted) break;
          setState(() {
            _openingCheckout = true;
            _error = null;
          });
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _syncApplePurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          if (!mounted) break;
          setState(() {
            _error = purchaseDetails.error?.message ??
                _t(
                  'premium_checkout_open_error',
                  'Nao foi possivel abrir a assinatura agora.',
                );
            _openingCheckout = false;
          });
          break;
        case PurchaseStatus.canceled:
          if (!mounted) break;
          setState(() {
            _openingCheckout = false;
          });
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _syncApplePurchase(PurchaseDetails purchaseDetails) async {
    final receiptData = purchaseDetails.verificationData.serverVerificationData;
    if (receiptData.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel validar a compra agora.',
        );
        _openingCheckout = false;
      });
      return;
    }

    try {
      final response = await BillingService.syncAppStoreSubscription(
        subscriptionId: purchaseDetails.productID,
        receiptData: receiptData,
      );
      final premiumGranted = response['premiumGranted'] == true;
      if (premiumGranted) {
        await LocalStorageService.waitForSync(timeoutSeconds: 8);
      }
      if (!mounted) return;
      setState(() {
        _openingCheckout = false;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'premium_checkout_opened_snack',
              'Compra concluida. O status premium sera atualizado em breve.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _openingCheckout = false;
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel sincronizar a compra agora.',
        );
      });
    }
  }

  Future<void> _purchaseApplePlan() async {
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

    if (!_iapAvailable) {
      if (!mounted) return;
      setState(() {
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel abrir a assinatura agora.',
        );
      });
      return;
    }

    if (_productDetails.isEmpty) {
      await _loadAppleProducts();
    }

    final product = _appleProductForPlan(_selectedPlan);
    if (product == null) {
      if (!mounted) return;
      setState(() {
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel carregar os planos da App Store agora.',
        );
      });
      return;
    }

    setState(() {
      _openingCheckout = true;
      _error = null;
    });

    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        throw Exception('purchase-not-started');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _openingCheckout = false;
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel abrir a assinatura agora.',
        );
      });
    }
  }

  Future<void> _openCheckout() async {
    if (_openingCheckout) return;

    if (_usesAppleIap) {
      await _purchaseApplePlan();
      return;
    }

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

  Future<void> _openCancellationPortal() async {
    if (_openingPortal) return;

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

    setState(() {
      _openingPortal = true;
      _error = null;
    });

    try {
      if (_usesAppleIap) {
        final launched = await launchUrl(
          Uri.parse('https://apps.apple.com/account/subscriptions'),
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
                'profile_subscription_cancelled',
                'Abra a pagina de assinaturas da App Store para gerenciar o plano.',
              ),
            ),
          ),
        );
        return;
      }

      final response = await BillingService.createPaddlePortalSession(
        returnUrl: BillingService.paddlePremiumSuccessUrl,
      );
      final portalUrl = (response['url'] ?? '').toString().trim();
      if (portalUrl.isEmpty) {
        throw Exception('portal-url-missing');
      }

      final launched = await launchUrl(
        Uri.parse(portalUrl),
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
              'premium_portal_opened_snack',
              'Portal de assinatura aberto. Cancele por la se desejar.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _t(
          'premium_portal_open_error',
          'Nao foi possivel abrir o portal de assinaturas agora.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _openingPortal = false;
        });
      }
    }
  }

  Future<void> _openExternalLink(String url) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      setState(() {
        _error = _t(
          'premium_checkout_open_error',
          'Nao foi possivel abrir a assinatura agora.',
        );
      });
    }
  }

  Widget _planTile(_SubscriptionPlanInfo plan) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedPlan == plan.key;
    final price = _planPriceLabel(plan);

    return InkWell(
      onTap: () => setState(() => _selectedPlan = plan.key),
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
                    plan.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${plan.durationLabel}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: $price',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subtitle,
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

  Widget _legalLinksCard() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By subscribing, you agree to our Terms of Use (EULA) and Privacy Policy.',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openExternalLink(LegalLinks.termsOfUseUrl),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Terms of Use (EULA)'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openExternalLink(LegalLinks.privacyPolicyUrl),
                icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                label: const Text('Privacy Policy'),
              ),
            ],
          ),
        ],
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
    final secureBody = _usesAppleIap
        ? 'A assinatura usa a compra da App Store e fica vinculada à sua conta.'
        : 'A assinatura abre no navegador e fica vinculada à sua conta. Nao ha compra dentro do app.';

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
                  if (_usesAppleIap)
                    Text(
                      secureBody,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  if (!_usesAppleIap)
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
            _planTile(_monthlyPlan),
            const SizedBox(height: 10),
            _planTile(_yearlyPlan),
            const SizedBox(height: 18),
            _legalLinksCard(),
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
                onPressed:
                    (_openingCheckout || (_usesAppleIap && _loadingProducts))
                        ? null
                        : _openCheckout,
                child: (_openingCheckout || (_usesAppleIap && _loadingProducts))
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
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _openingPortal ? null : _openCancellationPortal,
                icon: _openingPortal
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(
                  _usesAppleIap
                      ? 'Gerenciar assinatura'
                      : _t(
                          'premium_cancel_subscription_cta',
                          'Cancelar assinatura',
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

class _SubscriptionPlanInfo {
  const _SubscriptionPlanInfo({
    required this.key,
    required this.title,
    required this.durationLabel,
    required this.priceSuffix,
    required this.fallbackPrice,
    required this.subtitle,
  });

  final String key;
  final String title;
  final String durationLabel;
  final String priceSuffix;
  final String fallbackPrice;
  final String subtitle;
}
