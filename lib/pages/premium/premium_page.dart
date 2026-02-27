import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/auth_links.dart';
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
  static const String _monthlySubscriptionId = 'voolo-mensal';
  static const String _yearlySubscriptionId = 'voolo-anual';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _storeAvailable = false;
  bool _loading = true;
  bool _working = false;
  String? _error;

  final Map<String, ProductDetails> _productsById = {};
  late String _selectedProductId;

  String _t(String key, String fallback) {
    final value = AppStrings.t(context, key);
    return value == key ? fallback : value;
  }

  bool get _isStorePlatformSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _storeName {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'App Store'
        : 'Google Play';
  }

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialPlan == 'yearly'
        ? _yearlySubscriptionId
        : _monthlySubscriptionId;
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );
    _initStore();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _initStore() async {
    if (!_isStorePlatformSupported) {
      setState(() {
        _storeAvailable = false;
        _loading = false;
        _error = 'unsupported-platform';
      });
      return;
    }

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        setState(() {
          _storeAvailable = false;
          _loading = false;
          _error = 'store-unavailable';
        });
        return;
      }

      final response = await _iap
          .queryProductDetails({_monthlySubscriptionId, _yearlySubscriptionId});

      if (response.error != null) {
        setState(() {
          _storeAvailable = true;
          _loading = false;
          _error = 'product-query-failed';
        });
        return;
      }

      final products = <String, ProductDetails>{
        for (final p in response.productDetails) p.id: p,
      };

      setState(() {
        _storeAvailable = true;
        _productsById
          ..clear()
          ..addAll(products);
        _loading = false;
        _error = products.isEmpty ? 'product-not-found' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storeAvailable = false;
        _loading = false;
        _error = 'unknown';
      });
    }
  }

  Future<void> _restore() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await _iap.restorePurchases();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _buySelectedPlan() async {
    if (_working) return;
    final product = _productsById[_selectedProductId];
    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Plano ainda nao disponivel na $_storeName para este app.'),
        ),
      );
      return;
    }

    setState(() => _working = true);
    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento cancelado ou falhou.')),
        );
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _syncPremium(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _syncPremium(PurchaseDetails purchase) async {
    final verificationPayload =
        purchase.verificationData.serverVerificationData.toString().trim();
    final subscriptionId = purchase.productID.toString().trim();
    if (verificationPayload.isEmpty || subscriptionId.isEmpty) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? BillingPlatform.appStore
        : BillingPlatform.googlePlay;

    try {
      final res = await BillingService.syncSubscription(
        platform: platform,
        verificationPayload: verificationPayload,
        subscriptionId: subscriptionId,
        transactionId: purchase.purchaseID,
      );
      final granted = res['premiumGranted'] == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? _t('billing_premium_activated', 'Premium ativado!')
                : 'Assinatura vinculada, mas sem Premium ativo.',
          ),
        ),
      );
    } on BillingException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel validar a compra agora.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao sincronizar Premium.')),
      );
    }
  }

  Widget _planTile({
    required String id,
    required String title,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedProductId == id;
    final product = _productsById[id];
    final priceText = product?.price ?? 'Preço indisponível no momento';

    return InkWell(
      onTap: () => setState(() => _selectedProductId = id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
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
                    priceText,
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

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('premium_badge', 'Premium')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t('unlock_premium_title', 'Desbloqueie Voolo Pro'),
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
                  const SizedBox(height: 16),
                  if (!_storeAvailable) ...[
                    Text(
                      _error == 'unsupported-platform'
                          ? 'Compras disponiveis apenas no Android e iOS.'
                          : 'Loja indisponivel.',
                      style: TextStyle(color: scheme.error),
                    ),
                  ] else ...[
                    _planTile(
                      id: _monthlySubscriptionId,
                      title: 'Plano mensal',
                      subtitle: 'Renovacao automatica. Cancele quando quiser.',
                    ),
                    const SizedBox(height: 10),
                    _planTile(
                      id: _yearlySubscriptionId,
                      title: 'Plano anual',
                      subtitle: 'Cobranca anual. Equivale a R\$ 24,99/mes.',
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _working ||
                                !_productsById.containsKey(_selectedProductId)
                            ? null
                            : _buySelectedPlan,
                        child: _working
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_t('premium_cta', 'Seja Premium')),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: _working ? null : _restore,
                        child: const Text('Restaurar compras'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pagamento sera cobrado na sua conta Apple ID na confirmacao da compra. A assinatura renova automaticamente ate cancelamento nas configuracoes da App Store.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No plano anual voce paga uma vez por ano e continua com acesso premium por todos os meses do periodo.',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => _openExternalUrl(AuthLinks.termsUrl),
                          child: const Text('Termos de Uso'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _openExternalUrl(AuthLinks.privacyUrl),
                          child: const Text('Politica de Privacidade'),
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
