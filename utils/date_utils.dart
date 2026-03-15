import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateUtilsJetx {
  DateUtilsJetx._();

  static bool _initialized = false;

  /// Inicializa locale pt_BR apenas uma vez
  static Future<void> init() async {
    if (!_initialized) {
      await initializeDateFormatting('pt_BR', null);
      _initialized = true;
    }
  }

  /// Formata data: 10/01/2026
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  /// Mês e ano: Janeiro 2026
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'pt_BR').format(date);
  }

  /// Retorna apenas mês: Janeiro
  static String month(DateTime date) {
    return DateFormat('MMMM', 'pt_BR').format(date);
  }

  /// Calcula idade automaticamente
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Data atual
  static DateTime now() => DateTime.now();

  /// Primeiro dia do mês atual
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Último dia do mês atual
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}
