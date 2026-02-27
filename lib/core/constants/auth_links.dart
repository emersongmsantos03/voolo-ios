class AuthLinks {
  static const String passwordResetUrl = String.fromEnvironment(
    'VOOLO_PASSWORD_RESET_URL',
    defaultValue: 'https://voolo-ad416.web.app/auth/reset',
  );

  static const String termsUrl = String.fromEnvironment(
    'VOOLO_TERMS_URL',
    defaultValue: 'https://voolo-ad416.web.app/terms',
  );

  static const String privacyUrl = String.fromEnvironment(
    'VOOLO_PRIVACY_URL',
    defaultValue: 'https://voolo-ad416.web.app/privacy',
  );
}
