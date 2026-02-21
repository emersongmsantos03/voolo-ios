import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jetx/models/password_reset_models.dart';

class PasswordResetException implements Exception {
  PasswordResetException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  bool get isRateLimited => statusCode == 429;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isBadRequest => statusCode == 400;

  @override
  String toString() =>
      'PasswordResetException(code: $code, statusCode: $statusCode, message: $message)';
}

class PasswordResetService {
  PasswordResetService._();

  static const String _baseUrl =
      'https://voolo.com.br/api/auth/password-reset-link';
  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse('$_baseUrl/$path');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      final decoded = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return const {};
      }

      throw _buildException(response.statusCode, decoded);
    } on TimeoutException {
      throw PasswordResetException(
        code: 'timeout',
        message: 'Tempo de resposta excedido.',
      );
    } on PasswordResetException {
      rethrow;
    } catch (_) {
      throw PasswordResetException(
        code: 'network_error',
        message: 'Falha de conexao com o servidor.',
      );
    }
  }

  static Object? _decodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static PasswordResetException _buildException(
    int statusCode,
    Object? decoded,
  ) {
    final payload = decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
    final code = _readString(payload['code']) ??
        _readString(payload['error']) ??
        _readNestedErrorCode(payload) ??
        'http_$statusCode';

    final message = _readString(payload['message']) ??
        _readString(payload['error_description']) ??
        _readNestedErrorMessage(payload) ??
        _defaultMessageForStatus(statusCode);

    return PasswordResetException(
      code: code,
      message: message,
      statusCode: statusCode,
    );
  }

  static String? _readNestedErrorCode(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      return _readString(error['code']) ?? _readString(error['status']);
    }
    return null;
  }

  static String? _readNestedErrorMessage(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      return _readString(error['message']) ?? _readString(error['detail']);
    }
    return null;
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static String _defaultMessageForStatus(int statusCode) {
    if (statusCode == 400) return 'Solicitacao invalida.';
    if (statusCode == 429) return 'Muitas tentativas. Tente novamente em alguns minutos.';
    if (statusCode >= 500) return 'Erro interno no servidor.';
    return 'Erro inesperado ao processar a solicitacao.';
  }

  static Future<void> requestResetLink({required String email}) async {
    await _post('request', {'email': email});
  }

  static Future<PasswordResetVerifyResult> verifyResetToken({
    required String token,
  }) async {
    final json = await _post('verify', {'token': token});
    return PasswordResetVerifyResult.fromJson(json);
  }

  static Future<void> confirmReset({
    required String token,
    required String newPassword,
  }) async {
    await _post('confirm', {
      'token': token,
      'newPassword': newPassword,
    });
  }
}
