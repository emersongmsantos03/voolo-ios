import 'package:intl/intl.dart';

import 'currency_utils.dart';

final NumberFormat _moneyInputFormatter = NumberFormat('#,##0.00', 'pt_BR');

/// Parses money text input into a double.
///
/// Accepts both PT-BR ("1.540,80") and EN/US-like ("1540.80") separators.
double parseMoneyInput(String? text) {
  return CurrencyUtils.parse(text ?? '');
}

/// Formats a money value for input fields (PT-BR, without symbol).
///
/// Accepts `num` or `String` (which will be parsed via [parseMoneyInput]).
/// Always keeps two decimal places to avoid losing cents (e.g. 1540.8 -> 1.540,80).
String formatMoneyInput(Object? value) {
  double resolved = 0.0;
  if (value is num) {
    resolved = value.toDouble();
  } else if (value is String) {
    resolved = parseMoneyInput(value);
  }
  if (!resolved.isFinite) resolved = 0.0;
  return _moneyInputFormatter.format(resolved);
}

