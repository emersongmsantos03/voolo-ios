import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final NumberFormat _realFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Exibe: R$ 1.500,00
  static String format(double value) {
    return _realFormatter.format(value);
  }

  /// Converte texto para double (aceita 1.500,50 ou 1500.50)
  static double parse(String text) {
    final normalized =
        text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  /// Formata apenas número sem símbolo
  static String formatWithoutSymbol(double value) {
    return NumberFormat('#,##0.00', 'pt_BR').format(value);
  }
}
