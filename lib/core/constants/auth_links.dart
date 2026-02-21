class AuthLinks {
  static const String passwordResetUrl = String.fromEnvironment(
    'VOOLO_PASSWORD_RESET_URL',
    defaultValue: 'https://voolo-ad416.web.app/auth/reset',
  );
}

