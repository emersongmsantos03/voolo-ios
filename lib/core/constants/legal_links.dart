class LegalLinks {
  LegalLinks._();

  static const String privacyPolicyUrl = String.fromEnvironment(
    'VOOLO_PRIVACY_POLICY_URL',
    defaultValue: 'https://voolo.app/privacy',
  );

  static const String termsOfUseUrl = String.fromEnvironment(
    'VOOLO_TERMS_OF_USE_URL',
    defaultValue:
        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );
}
