import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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
  static const bool _screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _storeAvailable = false;
  bool _loading = true;
  bool _working = false;
  bool _iosStoreProductsLoaded = false;
  String? _error;
  String? _storeDiagnostic;
  List<String> _missingStoreProductIds = const [];

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
    if (_screenshotMode) {
      _loading = false;
      _storeAvailable = true;
      _iosStoreProductsLoaded = true;
      _planOptions['monthly'] = _PlanPurchaseOption(
        planKey: 'monthly',
        productId: BillingService.iosMonthlySubscriptionId,
        productDetails: ProductDetails(
          id: BillingService.iosMonthlySubscriptionId,
          title: 'Plano mensal',
          description: 'Acesso premium mensal no Voolo',
          price: 'R\$ 29,90',
          rawPrice: 29.90,
          currencyCode: 'BRL',
        ),
        priceText: 'R\$ 29,90 / mes',
      );
      _planOptions['yearly'] = _PlanPurchaseOption(
        planKey: 'yearly',
        productId: BillingService.iosYearlySubscriptionId,
        productDetails: ProductDetails(
          id: BillingService.iosYearlySubscriptionId,
          title: 'Plano anual',
          description: 'Acesso premium anual no Voolo',
          price: 'R\$ 299,90',
          rawPrice: 299.90,
          currencyCode: 'BRL',
        ),
        priceText: 'R\$ 299,90 / ano',
      );
      return;
    }
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );
    if (Platform.isIOS) {
      _storeAvailable = true;
      _loading = false;
      _iosStoreProductsLoaded = false;
      _planOptions.addAll(_buildFallbackApplePlanOptions());
    }
    _initStore();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _initStore() async {
    if (_screenshotMode) return;

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        if (Platform.isIOS) {
          _applyAppleFallbackPaywall(
            storeDiagnostic: _buildStoreDiagnostic(
              errorCode: 'store-unavailable',
              errorMessage:
                  'O StoreKit nao respondeu neste dispositivo ou simulador.',
            ),
          );
          return;
        }
        setState(() {
          _storeAvailable = false;
          _loading = false;
          _error = 'store-unavailable';
        });
        return;
      }

      final response =
          await _iap.queryProductDetails(_subscriptionProductIds());
      final notFoundIds = List<String>.unmodifiable(response.notFoundIDs);

      if (response.error != null) {
        if (Platform.isIOS) {
          _applyAppleFallbackPaywall(
            missingStoreProductIds: notFoundIds,
            storeDiagnostic: _buildStoreDiagnostic(
              missingStoreProductIds: notFoundIds,
              errorCode: response.error?.code,
              errorMessage: response.error?.message,
            ),
          );
          return;
        }
        setState(() {
          _storeAvailable = true;
          _loading = false;
          _error = 'product-query-failed';
        });
        return;
      }

      final options = _buildPlanOptions(response.productDetails);

      if (options.isEmpty && Platform.isIOS) {
        _applyAppleFallbackPaywall(
          missingStoreProductIds: notFoundIds,
          storeDiagnostic: _buildStoreDiagnostic(
            missingStoreProductIds: notFoundIds,
          ),
        );
        return;
      }

      setState(() {
        _storeAvailable = true;
        _iosStoreProductsLoaded = Platform.isIOS && options.isNotEmpty;
        _planOptions
          ..clear()
          ..addAll(options);
        _loading = false;
        _error = options.isEmpty ? 'product-not-found' : null;
        _missingStoreProductIds = notFoundIds;
        _storeDiagnostic = _buildStoreDiagnostic(
          missingStoreProductIds: notFoundIds,
        );
      });

      await _loadPastPurchasesAndSync();
    } catch (_) {
      if (!mounted) return;
      if (Platform.isIOS) {
        _applyAppleFallbackPaywall(
          storeDiagnostic: _buildStoreDiagnostic(
            errorCode: 'unknown',
            errorMessage:
                'Falha ao consultar os produtos da App Store neste build.',
          ),
        );
        return;
      }
      setState(() {
        _storeAvailable = false;
        _loading = false;
        _error = 'unknown';
      });
    }
  }

  void _applyAppleFallbackPaywall({
    List<String> missingStoreProductIds = const [],
    String? storeDiagnostic,
  }) {
    if (!mounted) return;
    setState(() {
      _storeAvailable = true;
      _iosStoreProductsLoaded = false;
      _loading = false;
      _error = null;
      _missingStoreProductIds =
          List<String>.unmodifiable(missingStoreProductIds);
      _storeDiagnostic = storeDiagnostic ??
          _buildStoreDiagnostic(
            missingStoreProductIds: missingStoreProductIds,
          );
      _planOptions
        ..clear()
        ..addAll(_buildFallbackApplePlanOptions());
    });
  }

  String _buildStoreDiagnostic({
    List<String> missingStoreProductIds = const [],
    String? errorCode,
    String? errorMessage,
  }) {
    final expectedIds = <String>[
      BillingService.iosMonthlySubscriptionId,
      BillingService.iosYearlySubscriptionId,
    ];
    final missing = missingStoreProductIds.isEmpty
        ? 'nenhum ID ausente foi reportado'
        : missingStoreProductIds.join(', ');
    final errorDetails = [
      if (errorCode != null && errorCode.trim().isNotEmpty)
        'codigo: $errorCode',
      if (errorMessage != null && errorMessage.trim().isNotEmpty)
        'mensagem: ${errorMessage.trim()}',
    ].join(' | ');

    return [
      'O StoreKit nao retornou os produtos esperados.',
      'IDs esperados: ${expectedIds.join(', ')}.',
      'IDs ausentes: $missing.',
      if (errorDetails.isNotEmpty) 'Resposta da loja: $errorDetails.',
      'No dispositivo fisico, confirme que estes produtos existem no App Store Connect, estao em uma Subscription Group ativa e que a conta usada e sandbox/review.',
    ].join(' ');
  }

  _PlanPurchaseOption? _effectiveOptionFor(String planKey) {
    final option = _planOptions[planKey];
    if (option != null) return option;
    if (Platform.isIOS) {
      return _buildFallbackApplePlanOptions()[planKey];
    }
    return null;
  }

  Set<String> _subscriptionProductIds() {
    if (Platform.isAndroid) {
      return {
        BillingService.googlePlayUnifiedSubscriptionId,
        BillingService.googlePlayMonthlySubscriptionId,
        BillingService.googlePlayYearlySubscriptionId,
      };
    }

    return {
      BillingService.iosMonthlySubscriptionId,
      BillingService.iosYearlySubscriptionId,
    };
  }

  Map<String, _PlanPurchaseOption> _buildPlanOptions(
      List<ProductDetails> productDetails) {
    final options = <String, _PlanPurchaseOption>{};

    if (!Platform.isAndroid) {
      ProductDetails? firstById(String id) {
        for (final p in productDetails) {
          if (p.id == id) return p;
        }
        return null;
      }

      final monthly = firstById(BillingService.iosMonthlySubscriptionId);
      if (monthly != null) {
        options['monthly'] = _PlanPurchaseOption(
          planKey: 'monthly',
          productId: monthly.id,
          productDetails: monthly,
          priceText: monthly.price,
        );
      }

      final yearly = firstById(BillingService.iosYearlySubscriptionId);
      if (yearly != null) {
        options['yearly'] = _PlanPurchaseOption(
          planKey: 'yearly',
          productId: yearly.id,
          productDetails: yearly,
          priceText: yearly.price,
        );
      }

      return options;
    }

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

    final legacyYearly =
        firstById(BillingService.googlePlayYearlySubscriptionId);
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

  Map<String, _PlanPurchaseOption> _buildFallbackApplePlanOptions() {
    return {
      'monthly': _PlanPurchaseOption(
        planKey: 'monthly',
        productId: BillingService.iosMonthlySubscriptionId,
        productDetails: ProductDetails(
          id: BillingService.iosMonthlySubscriptionId,
          title: 'Plano mensal',
          description: 'Acesso premium mensal no Voolo',
          price: 'R\$ 29,90',
          rawPrice: 29.90,
          currencyCode: 'BRL',
        ),
        priceText: 'R\$ 29,90 / mes',
      ),
      'yearly': _PlanPurchaseOption(
        planKey: 'yearly',
        productId: BillingService.iosYearlySubscriptionId,
        productDetails: ProductDetails(
          id: BillingService.iosYearlySubscriptionId,
          title: 'Plano anual',
          description: 'Acesso premium anual no Voolo',
          price: 'R\$ 299,90',
          rawPrice: 299.90,
          currencyCode: 'BRL',
        ),
        priceText: 'R\$ 299,90 / ano',
      ),
    };
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
      final addition =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
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
      try {
        await _iap.restorePurchases();
        await _loadPastPurchasesAndSync();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compras restauradas e sincronizadas.')),
        );
      } catch (error) {
        debugPrint('Restore purchases failed: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao foi possivel restaurar as compras agora.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _buySelectedPlan() async {
    if (_working) return;
    if (Platform.isIOS && !_iosStoreProductsLoaded) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Os produtos da App Store ainda nao foram carregados. '
            'Verifique o App Store Connect.',
          ),
        ),
      );
      return;
    }
    final option = _effectiveOptionFor(_selectedPlan);
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
          changeSubscriptionParam:
              (oldSub != null && oldSub.productID != option.productId)
                  ? ChangeSubscriptionParam(oldPurchaseDetails: oldSub)
                  : null,
        );
      } else {
        param = PurchaseParam(productDetails: option.productDetails);
      }

      try {
        await _iap.buyNonConsumable(purchaseParam: param);
      } catch (error) {
        debugPrint('Buy purchase failed: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao foi possivel abrir a compra da App Store.',
            ),
          ),
        );
      }
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
    final subscriptionId = purchase.productID.toString().trim();

    try {
      final res = Platform.isAndroid
          ? await _syncGooglePlayPremium(subscriptionId, purchase)
          : await _syncAppStorePremium(subscriptionId, purchase);
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

  Future<Map<String, dynamic>> _syncGooglePlayPremium(
    String subscriptionId,
    PurchaseDetails purchase,
  ) async {
    final purchaseToken =
        purchase.verificationData.serverVerificationData.toString().trim();
    if (purchaseToken.isEmpty || subscriptionId.isEmpty) {
      throw BillingException('invalid-argument');
    }

    if (!BillingService.supportedGooglePlaySubscriptionIds
        .contains(subscriptionId)) {
      throw BillingException('unsupported-subscription-id');
    }

    return BillingService.syncGooglePlaySubscription(
      purchaseToken: purchaseToken,
      subscriptionId: subscriptionId,
    );
  }

  Future<Map<String, dynamic>> _syncAppStorePremium(
    String subscriptionId,
    PurchaseDetails purchase,
  ) async {
    final receiptData =
        purchase.verificationData.serverVerificationData.toString().trim();
    if (receiptData.isEmpty || subscriptionId.isEmpty) {
      throw BillingException('invalid-argument');
    }

    if (!BillingService.supportedAppleSubscriptionIds
        .contains(subscriptionId)) {
      throw BillingException('unsupported-subscription-id');
    }

    return BillingService.syncAppStoreSubscription(
      receiptData: receiptData,
      subscriptionId: subscriptionId,
      transactionId: purchase.purchaseID,
    );
  }

  Widget _planTile({
    required String planKey,
    required String title,
    required String fallbackPrice,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedPlan == planKey;
    final option = _effectiveOptionFor(planKey);
    final priceText = option?.priceText ?? fallbackPrice;

    return InkWell(
      onTap:
          option == null ? null : () => setState(() => _selectedPlan = planKey),
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
                  if (option == null && !Platform.isIOS) ...[
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

  Widget _buildScreenshotPaywall(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('premium_badge', 'Premium')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.12),
                        scheme.secondary.withValues(alpha: 0.08),
                        scheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: scheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Desbloqueie o Voolo Pro',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assinatura pelo App Store com acesso a missoes, metas, relatorios e simuladores premium.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _planTile(
                        planKey: 'monthly',
                        title: 'Plano mensal',
                        fallbackPrice: 'R\$ 29,90 / mes',
                        subtitle:
                            'Renovacao automatica. Cancele quando quiser.',
                      ),
                      const SizedBox(height: 10),
                      _planTile(
                        planKey: 'yearly',
                        title: 'Plano anual',
                        fallbackPrice: 'R\$ 299,90 / ano',
                        subtitle:
                            'Cobrado 1 vez por ano. Melhora o custo mensal.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _perkLine(context, 'Relatorios e insights premium'),
                            _perkLine(
                                context, 'Calculadora e simuladores avancados'),
                            _perkLine(
                                context, 'Restaurar compras no mesmo Apple ID'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: null,
                          child: const Text('Assinar com a App Store'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 46,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: null,
                          child: const Text('Restaurar compras'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A captura de tela abaixo pode ser enviada para revisao da App Store.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: null,
                      child: const Text('Termos de Uso'),
                    ),
                    TextButton(
                      onPressed: null,
                      child: const Text('Politica de Privacidade'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _perkLine(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_screenshotMode) {
      return _buildScreenshotPaywall(context);
    }
    final scheme = Theme.of(context).colorScheme;
    final showPaywallContent = Platform.isIOS || _storeAvailable;

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
                  if (!Platform.isIOS && _error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error == 'product-not-found'
                          ? 'Produtos ainda nao localizados no App Store Connect.'
                          : _error == 'product-query-failed'
                              ? 'Nao foi possivel carregar os produtos da loja.'
                              : 'Loja indisponivel no momento.',
                      style: TextStyle(
                        color: scheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (Platform.isIOS && !_iosStoreProductsLoaded) ...[
                    _storeDiagnosticCard(context),
                    const SizedBox(height: 12),
                  ],
                  if (!showPaywallContent) ...[
                    Text(
                      Platform.isAndroid
                          ? 'Funcionalidade indisponivel nesta plataforma.'
                          : 'Os produtos da App Store ainda nao foram encontrados. Quando estiverem configurados, os precos aparecem aqui.',
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
                        onPressed: _working ||
                                _effectiveOptionFor(_selectedPlan) == null ||
                                (Platform.isIOS && !_iosStoreProductsLoaded)
                            ? null
                            : _buySelectedPlan,
                        child: _working
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                      Platform.isAndroid
                          ? 'No plano anual voce paga uma vez por ano e continua com acesso premium por todos os meses do periodo.'
                          : 'O pagamento sera processado pela App Store e pode ser restaurado no mesmo Apple ID.',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
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

  Widget _storeDiagnosticCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expectedIds = <String>[
      BillingService.iosMonthlySubscriptionId,
      BillingService.iosYearlySubscriptionId,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostico do StoreKit',
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _storeDiagnostic ??
                'O app nao conseguiu carregar os produtos da App Store.',
            style: TextStyle(
              color: scheme.onErrorContainer,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IDs do build: ${expectedIds.join(', ')}',
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontSize: 12,
            ),
          ),
          if (_missingStoreProductIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'IDs nao encontrados: ${_missingStoreProductIds.join(', ')}',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
