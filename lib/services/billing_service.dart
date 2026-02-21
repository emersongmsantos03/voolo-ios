import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'backend_config_service.dart';

enum BillingPlatform {
  googlePlay,
  appStore,
}

class BillingException implements Exception {
  BillingException(this.code, {this.details});

  final String code;
  final Object? details;

  @override
  String toString() => 'BillingException($code)';
}

class BillingService {
  BillingService._();

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

  static Future<Map<String, dynamic>> syncGooglePlaySubscription({
    required String purchaseToken,
    required String subscriptionId,
  }) {
    return _post('/billing/googleplay/sync-subscription', {
      'purchaseToken': purchaseToken,
      'subscriptionId': subscriptionId,
    });
  }

  static Future<Map<String, dynamic>> syncAppStoreSubscription({
    required String receiptData,
    required String subscriptionId,
    String? transactionId,
  }) {
    return _post('/billing/appstore/sync-subscription', {
      'receiptData': receiptData,
      'subscriptionId': subscriptionId,
      if (transactionId != null && transactionId.isNotEmpty)
        'transactionId': transactionId,
    });
  }

  static Future<Map<String, dynamic>> syncSubscription({
    required BillingPlatform platform,
    required String verificationPayload,
    required String subscriptionId,
    String? transactionId,
  }) {
    switch (platform) {
      case BillingPlatform.googlePlay:
        return syncGooglePlaySubscription(
          purchaseToken: verificationPayload,
          subscriptionId: subscriptionId,
        );
      case BillingPlatform.appStore:
        return syncAppStoreSubscription(
          receiptData: verificationPayload,
          subscriptionId: subscriptionId,
          transactionId: transactionId,
        );
    }
  }
}
