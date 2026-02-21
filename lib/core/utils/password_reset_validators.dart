import 'package:jetx/core/utils/password_policy.dart';

class PasswordResetValidators {
  PasswordResetValidators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String value) {
    return _emailRegex.hasMatch(value.trim());
  }

  static PasswordPolicyResult passwordStrength(String password) {
    return PasswordPolicy.evaluate(password);
  }
}
