class PasswordResetVerifyResult {
  const PasswordResetVerifyResult({
    required this.valid,
    this.message,
  });

  final bool valid;
  final String? message;

  factory PasswordResetVerifyResult.fromJson(Map<String, dynamic> json) {
    final rawValid = json['valid'];
    final valid = rawValid is bool ? rawValid : true;
    final message = json['message'] is String ? json['message'] as String : null;

    return PasswordResetVerifyResult(
      valid: valid,
      message: message,
    );
  }
}
