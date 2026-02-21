class BackendConfigService {
  BackendConfigService._();

  // Optional: full API base for billing (example: https://...cloudfunctions.net/api)
  static const String _billingApiBaseFromEnv = String.fromEnvironment(
    'VOOLO_BILLING_API_BASE_URL',
    defaultValue: '',
  );

  // Optional: shared API base (legacy compatibility)
  static const String _apiBaseFromEnv = String.fromEnvironment(
    'VOOLO_API_BASE_URL',
    defaultValue: '',
  );

  // Optional: Cloud Functions base URL (example: https://...cloudfunctions.net)
  static const String _functionsBaseFromEnv = String.fromEnvironment(
    'VOOLO_FUNCTIONS_BASE_URL',
    defaultValue: '',
  );

  static String get functionsBaseUrl {
    if (_functionsBaseFromEnv.trim().isNotEmpty) {
      return _functionsBaseFromEnv.trim();
    }
    return 'https://southamerica-east1-voolo-ad416.cloudfunctions.net';
  }

  static String get billingApiBaseUrl {
    if (_billingApiBaseFromEnv.trim().isNotEmpty) {
      return _billingApiBaseFromEnv.trim();
    }
    if (_apiBaseFromEnv.trim().isNotEmpty) {
      return _apiBaseFromEnv.trim();
    }
    // Legacy default kept for backward compatibility.
    return 'https://us-central1-voolo-ad416.cloudfunctions.net/api';
  }
}
