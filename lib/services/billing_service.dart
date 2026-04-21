import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'backend_config_service.dart';

class BillingException implements Exception {
  BillingException(this.code, {this.details});

  final String code;
  final Object? details;

  @override
  String toString() => 'BillingException($code)';
}

class BillingService {
  BillingService._();

  static const String paddleMonthlyPriceId = 'pri_01knqmg977ezes0x1nn555g280';
  static const String paddleYearlyPriceId = 'pri_01knqmn1q7gbpjcvm0aws4p1ej';
  static const String appleMonthlySubscriptionId = 'voolo_month';
  static const String appleYearlySubscriptionId = 'voolo_year';
  static const String paddleCheckoutHostUrl = 'https://www.voolo.com.br';
  static const String paddlePremiumSuccessUrl =
      'https://www.voolo.com.br/profile?premium=success';

  static Uri buildPaddleCheckoutUri({
    required String uid,
    required String plan,
    String? email,
    String? successUrl,
  }) {
    final normalizedPlan = plan.trim().toLowerCase();
    final resolvedPlan = normalizedPlan == 'yearly' ? 'yearly' : 'monthly';
    final base = Uri.parse(paddleCheckoutHostUrl);
    final params = <String, String>{
      'plan': resolvedPlan,
      'uid': uid.trim(),
      'successUrl': (successUrl?.trim().isNotEmpty ?? false)
          ? successUrl!.trim()
          : paddlePremiumSuccessUrl,
    };

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      params['email'] = normalizedEmail;
    }

    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/premium-checkout',
      queryParameters: params,
    );
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final apiBaseUrl = BackendConfigService.billingApiBaseUrl;

    if (apiBaseUrl.isEmpty) {
      throw BillingException('api-not-configured');
    }

    final uri = Uri.parse('$apiBaseUrl$path');
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'data': data}),
    );

    final body = response.body;
    final decoded = body.isEmpty ? null : jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return const <String, dynamic>{};
    }

    final code = _parseErrorCode(decoded) ?? 'unknown';
    throw BillingException(code, details: decoded);
  }

  static String? _parseErrorCode(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) return message;
      }
      final msg = decoded['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return null;
  }

  static Future<Map<String, dynamic>> createPaddlePortalSession({
    String? returnUrl,
  }) {
    return _post('/billing/paddle/create-portal-session', {
      if (returnUrl != null && returnUrl.trim().isNotEmpty)
        'returnUrl': returnUrl.trim(),
    });
  }

  static Future<Map<String, dynamic>> syncPaddleTransaction({
    required String transactionId,
  }) {
    return _post('/billing/paddle/sync-transaction', {
      'transactionId': transactionId,
    });
  }

  static Future<Map<String, dynamic>> cancelPaddleSubscription() {
    return _post('/billing/paddle/cancel-subscription', const {});
  }

  static Future<Map<String, dynamic>> syncAppStoreSubscription({
    required String subscriptionId,
    required String receiptData,
    String? transactionId,
    String? originalTransactionId,
  }) {
    return _post('/billing/appstore/sync-subscription', {
      'subscriptionId': subscriptionId,
      'receiptData': receiptData,
      if (transactionId != null && transactionId.trim().isNotEmpty)
        'transactionId': transactionId.trim(),
      if (originalTransactionId != null &&
          originalTransactionId.trim().isNotEmpty)
        'originalTransactionId': originalTransactionId.trim(),
    });
  }
}
