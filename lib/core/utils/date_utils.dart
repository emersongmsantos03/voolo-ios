import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class DateUtilsJetx {
  DateUtilsJetx._();

  static bool _initialized = false;

  /// Inicializa os locales suportados apenas uma vez
  static Future<void> init() async {
    if (_initialized) return;
    await initializeDateFormatting('pt_BR', null);
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('es_ES', null);
    _initialized = true;
  }

  /// Formata data: 10/01/2026
  static String formatDate(DateTime date, {String? locale}) {
    final resolved = _normalizeLocale(locale);
    return DateFormat('dd/MM/yyyy', resolved).format(date);
  }

  /// Mês e ano: Janeiro 2026
  static String monthYear(DateTime date, {String? locale}) {
    final resolved = _normalizeLocale(locale);
    return DateFormat('MMMM yyyy', resolved).format(date);
  }

  /// Retorna apenas mês: Janeiro
  static String month(DateTime date, {String? locale}) {
    final resolved = _normalizeLocale(locale);
    return DateFormat('MMMM', resolved).format(date);
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

  static String _normalizeLocale(String? locale) {
    final raw = (locale ?? Intl.getCurrentLocale()).replaceAll('-', '_');
    switch (raw) {
      case 'pt':
        return 'pt_BR';
      case 'en':
        return 'en_US';
      case 'es':
        return 'es_ES';
      default:
        return raw.isEmpty ? 'pt_BR' : raw;
    }
  }
}
