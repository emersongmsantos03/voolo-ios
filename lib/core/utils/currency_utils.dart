import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();
  static const String masked = 'R\$ •••••';
  static bool hideValues = false;

  static final NumberFormat _realFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Exibe: R$ 1.500,00
  static String format(double value, {bool maskWhenHidden = true}) {
    if (hideValues && maskWhenHidden) return masked;
    return _realFormatter.format(value);
  }

  /// Converte texto para double (aceita 1.500,50 ou 1500.50)
  static double parse(String text) {
    final raw = text
        .replaceAll('R\$', '')
        .replaceAll('\u00A0', ' ')
        .trim();

    final cleaned = raw.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (cleaned.isEmpty) return 0.0;

    final lastDot = cleaned.lastIndexOf('.');
    final lastComma = cleaned.lastIndexOf(',');

    String normalized;
    if (lastDot >= 0 && lastComma >= 0) {
      // If both exist, the last separator is likely the decimal separator.
      final dotIsDecimal = lastDot > lastComma;
      if (dotIsDecimal) {
        // "1,500.50" -> remove commas
        normalized = cleaned.replaceAll(',', '');
      } else {
        // "1.500,50" -> remove dots and use comma as decimal
        normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (lastComma >= 0) {
      // "1500,50"
      normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // "1500.50" or "1500"
      normalized = cleaned.replaceAll(',', '');
    }

    return double.tryParse(normalized) ?? 0.0;
  }

  /// Formata apenas número sem símbolo
  static String formatWithoutSymbol(double value) {
    return NumberFormat('#,##0.00', 'pt_BR').format(value);
  }
}
