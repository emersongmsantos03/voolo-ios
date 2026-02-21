class PasswordPolicyResult {
  final bool minLength;
  final bool hasUpper;
  final bool hasLower;
  final bool hasNumber;
  final bool hasSpecial;
  final bool notCommon;
  final bool notSequential;

  const PasswordPolicyResult({
    required this.minLength,
    required this.hasUpper,
    required this.hasLower,
    required this.hasNumber,
    required this.hasSpecial,
    required this.notCommon,
    required this.notSequential,
  });

  bool get isValid =>
      minLength && hasUpper && hasLower && hasNumber && hasSpecial && notCommon && notSequential;
}

class PasswordPolicy {
  static const Set<String> _commonWeak = {
    '123456',
    '1234567',
    '12345678',
    '123123',
    '111111',
    '000000',
    'senha',
    'senha123',
    'password',
    'password123',
    'qwerty',
    'qwerty123',
    'admin',
    'admin123',
  };

  static bool _hasSequentialRun(String value) {
    final lower = value.toLowerCase();
    const sequences = [
      '0123',
      '1234',
      '2345',
      '3456',
      '4567',
      '5678',
      '6789',
      'abcd',
      'bcde',
      'cdef',
      'defg',
      'efgh',
      'fghi',
      'ghij',
      'hijk',
      'ijkl',
      'jklm',
      'klmn',
      'lmno',
      'mnop',
      'nopq',
      'opqr',
      'pqrs',
      'qrst',
      'rstu',
      'stuv',
      'tuvw',
      'uvwx',
      'vwxy',
      'wxyz',
      'qwer',
      'asdf',
      'zxcv',
    ];
    for (final s in sequences) {
      if (lower.contains(s)) return true;
    }
    return false;
  }

  static PasswordPolicyResult evaluate(String password) {
    final value = password;
    final trimmedLower = value.trim().toLowerCase();

    final minLength = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(value);
    final notCommon = !_commonWeak.contains(trimmedLower);
    final notSequential = !_hasSequentialRun(value);

    return PasswordPolicyResult(
      minLength: minLength,
      hasUpper: hasUpper,
      hasLower: hasLower,
      hasNumber: hasNumber,
      hasSpecial: hasSpecial,
      notCommon: notCommon,
      notSequential: notSequential,
    );
  }
}

