import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'backend_config_service.dart';

class AdvancedModulesException implements Exception {
  AdvancedModulesException(this.code);

  final String code;
}

class AdvancedModulesService {
  AdvancedModulesService._();

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final functionsBaseUrl = BackendConfigService.functionsBaseUrl;
    final uri = Uri.parse('$functionsBaseUrl/$path');
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
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        final result = decoded['result'];
        if (result is Map<String, dynamic>) return result;
        return decoded;
      }
      return const {};
    }

    throw AdvancedModulesException(_parseError(decoded));
  }

  static String _parseError(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return 'unknown';
  }

  static Future<Map<String, dynamic>> suggestBudgets({
    required String monthYear,
    double savingsPct = 0.1,
  }) {
    return _post('suggestBudgets', {
      'monthYear': monthYear,
      'savingsPct': savingsPct,
    });
  }

  static Future<Map<String, dynamic>> computeDebtPlan({
    required String monthYear,
    String method = 'avalanche',
  }) {
    return _post('computeDebtPlan', {
      'monthYear': monthYear,
      'method': method,
    });
  }

  static Future<Map<String, dynamic>> computeInvestmentProfile({
    required List<int> answers,
  }) {
    return _post('computeInvestmentProfile', {'answers': answers});
  }
}
