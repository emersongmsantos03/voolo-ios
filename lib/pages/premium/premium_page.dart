import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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

class _PlanPurchaseOption {
  const _PlanPurchaseOption({
    required this.planKey,
    required this.productId,
    required this.productDetails,
    required this.priceText,
    this.offerToken,
  });

  final String planKey; // monthly | yearly
  final String productId;
  final ProductDetails productDetails;
  final String priceText;
  final String? offerToken;
}

class _PremiumPageState extends State<PremiumPage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _storeAvailable = false;
  bool _loading = true;
  bool _working = false;
  String? _error;

  final Map<String, _PlanPurchaseOption> _planOptions = {};
  final Map<String, GooglePlayPurchaseDetails> _activeSubscriptionsByProductId =
      {};
  late String _selectedPlan; // monthly | yearly

  String _t(String key, String fallback) {
    final value = AppStrings.t(context, key);
    return value == key ? fallback : value;
  }

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan == 'yearly' ? 'yearly' : 'monthly';
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
    if (!Platform.isAndroid) {
      setState(() {
        _storeAvailable = false;
        _loading = false;
        _error = 'store-unavailable';
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

      final response = await _iap.queryProductDetails(
        {
          BillingService.googlePlayUnifiedSubscriptionId,
          BillingService.googlePlayMonthlySubscriptionId,
          BillingService.googlePlayYearlySubscriptionId,
        },
      );

      if (response.error != null) {
        setState(() {
          _storeAvailable = true;
          _loading = false;
          _error = 'product-query-failed';
        });
        return;
      }

      final options = _buildPlanOptions(response.productDetails);

      setState(() {
        _storeAvailable = true;
        _planOptions
          ..clear()
          ..addAll(options);
        _loading = false;
        _error = options.isEmpty ? 'product-not-found' : null;
      });

      await _loadPastPurchasesAndSync();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storeAvailable = false;
        _loading = false;
        _error = 'unknown';
      });
    }
  }

  Map<String, _PlanPurchaseOption> _buildPlanOptions(
      List<ProductDetails> productDetails) {
    final options = <String, _PlanPurchaseOption>{};

    // Prefer unified subscription with base plans/offers.
    for (final pd in productDetails) {
      if (pd.id != BillingService.googlePlayUnifiedSubscriptionId) continue;
      if (pd is! GooglePlayProductDetails) continue;

      final index = pd.subscriptionIndex;
      final offers = pd.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null || index >= offers.length) continue;

      final offer = offers[index];
      final planKey = _inferPlanFromOffer(
        basePlanId: offer.basePlanId,
        offerId: offer.offerId,
        offerTags: offer.offerTags,
        billingPeriods:
            offer.pricingPhases.map((phase) => phase.billingPeriod).toList(),
      );
      if (planKey == null || options.containsKey(planKey)) continue;

      options[planKey] = _PlanPurchaseOption(
        planKey: planKey,
        productId: pd.id,
        productDetails: pd,
        priceText: _extractOfferDisplayPrice(offer.pricingPhases, pd.price),
        offerToken: pd.offerToken,
      );
    }

    // Fallback to legacy product IDs when unified offers are unavailable.
    ProductDetails? firstById(String id) {
      for (final p in productDetails) {
        if (p.id == id) return p;
      }
      return null;
    }

    final legacyMonthly =
        firstById(BillingService.googlePlayMonthlySubscriptionId);
    if (!options.containsKey('monthly') && legacyMonthly != null) {
      options['monthly'] = _PlanPurchaseOption(
        planKey: 'monthly',
        productId: legacyMonthly.id,
        productDetails: legacyMonthly,
        priceText: legacyMonthly.price,
      );
    }

    final legacyYearly = firstById(BillingService.googlePlayYearlySubscriptionId);
    if (!options.containsKey('yearly') && legacyYearly != null) {
      options['yearly'] = _PlanPurchaseOption(
        planKey: 'yearly',
        productId: legacyYearly.id,
        productDetails: legacyYearly,
        priceText: legacyYearly.price,
      );
    }

    return options;
  }

  String? _inferPlanFromOffer({
    required String basePlanId,
    required String? offerId,
    required List<String> offerTags,
    required List<String> billingPeriods,
  }) {
    final normalized = <String>[
      basePlanId,
      offerId ?? '',
      ...offerTags,
    ].join(' ').toLowerCase();

    if (normalized.contains('anual') ||
        normalized.contains('yearly') ||
        normalized.contains('year')) {
      return 'yearly';
    }
    if (normalized.contains('mensal') ||
        normalized.contains('monthly') ||
        normalized.contains('month')) {
      return 'monthly';
    }

    final joinedPeriods = billingPeriods.join(' ').toUpperCase();
    if (joinedPeriods.contains('P1Y') || joinedPeriods.contains('P12M')) {
      return 'yearly';
    }
    if (joinedPeriods.contains('P1M')) {
      return 'monthly';
    }
    return null;
  }

  String _extractOfferDisplayPrice(List<dynamic> phases, String fallback) {
    for (final phase in phases) {
      final micros = (phase.priceAmountMicros as int?) ?? 0;
      if (micros > 0) {
        final formatted = (phase.formattedPrice as String?) ?? '';
        if (formatted.trim().isNotEmpty) return formatted.trim();
      }
    }
    return fallback;
  }

  Future<void> _loadPastPurchasesAndSync() async {
    if (!Platform.isAndroid) return;
    try {
      final addition = _iap.getPlatformAddition<
          InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) return;

      for (final purchase in response.pastPurchases) {
        if (!BillingService.supportedGooglePlaySubscriptionIds
            .contains(purchase.productID)) {
          continue;
        }
        _activeSubscriptionsByProductId[purchase.productID] = purchase;
        await _syncPremium(purchase, showFeedback: false);
      }
    } catch (_) {
      // Ignore on startup; user can still restore manually.
    }
  }

  Future<void> _restore() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await _iap.restorePurchases();
      await _loadPastPurchasesAndSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compras restauradas e sincronizadas.')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _buySelectedPlan() async {
    if (_working) return;
    final option = _planOptions[_selectedPlan];
      if (option == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plano ainda nao disponivel para este app.'),
        ),
      );
      return;
    }

    setState(() => _working = true);
    try {
      final PurchaseParam param;
      if (Platform.isAndroid) {
        final oldSub = _findOldSubscriptionForTarget(option.productId);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        param = GooglePlayPurchaseParam(
          productDetails: option.productDetails,
          applicationUserName: uid,
          offerToken: option.offerToken,
          changeSubscriptionParam: (oldSub != null &&
                  oldSub.productID != option.productId)
              ? ChangeSubscriptionParam(oldPurchaseDetails: oldSub)
              : null,
        );
      } else {
        param = PurchaseParam(productDetails: option.productDetails);
      }

      await _iap.buyNonConsumable(purchaseParam: param);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  GooglePlayPurchaseDetails? _findOldSubscriptionForTarget(
      String targetProductId) {
    for (final entry in _activeSubscriptionsByProductId.entries) {
      if (entry.key == targetProductId) continue;
      return entry.value;
    }
    return null;
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
        if (purchase is GooglePlayPurchaseDetails &&
            BillingService.supportedGooglePlaySubscriptionIds
                .contains(purchase.productID)) {
          _activeSubscriptionsByProductId[purchase.productID] = purchase;
        }
        await _syncPremium(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _syncPremium(
    PurchaseDetails purchase, {
    bool showFeedback = true,
  }) async {
    final purchaseToken =
        purchase.verificationData.serverVerificationData.toString().trim();
    final subscriptionId = purchase.productID.toString().trim();
    if (purchaseToken.isEmpty || subscriptionId.isEmpty) return;

    if (!BillingService.supportedGooglePlaySubscriptionIds
        .contains(subscriptionId)) {
      return;
    }

    try {
      final res = await BillingService.syncGooglePlaySubscription(
        purchaseToken: purchaseToken,
        subscriptionId: subscriptionId,
      );
      final granted = res['premiumGranted'] == true;
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? _t('billing_premium_activated', 'Premium ativado!')
                  : 'Assinatura vinculada, mas sem Premium ativo.',
            ),
          ),
        );
      }
    } on BillingException catch (_) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel validar a compra agora.'),
          ),
        );
      }
    } catch (_) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao sincronizar Premium.')),
        );
      }
    }
  }

  Widget _planTile({
    required String planKey,
    required String title,
    required String fallbackPrice,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedPlan == planKey;
    final option = _planOptions[planKey];
    final priceText = option?.priceText ?? fallbackPrice;

    return InkWell(
      onTap: option == null ? null : () => setState(() => _selectedPlan = planKey),
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
                  if (option == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Indisponivel no momento',
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosFallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('premium_badge', 'Premium')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Nesta versao para iOS, a ativacao de recursos Premium ainda nao esta disponivel. O app continua funcionando normalmente enquanto concluimos a liberacao dessa area.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return _buildIosFallback(context);
    }
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
                      'Funcionalidade indisponivel nesta plataforma.',
                      style: TextStyle(color: scheme.error),
                    ),
                  ] else ...[
                    _planTile(
                      planKey: 'monthly',
                      title: 'Plano mensal',
                      fallbackPrice: 'R\$ 29,90 / mes',
                      subtitle: 'Renovacao automatica. Cancele quando quiser.',
                    ),
                    const SizedBox(height: 10),
                    _planTile(
                      planKey: 'yearly',
                      title: 'Plano anual',
                      fallbackPrice: 'R\$ 299,90 / ano',
                      subtitle: 'Cobranca anual. Equivale a R\$ 24,99/mes.',
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _working || _planOptions[_selectedPlan] == null
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
                      'No plano anual voce paga uma vez por ano e continua com acesso premium por todos os meses do periodo.',
                      style:
                          TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
