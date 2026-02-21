class GenderCatalog {
  GenderCatalog._();

  static const String notInformed = 'not_informed';
  static const String male = 'male';
  static const String female = 'female';
  static const String other = 'other';

  static const List<String> codes = [
    notInformed,
    male,
    female,
    other,
  ];

  static final Map<String, String> _labelToCode = {
    _k('Nao informado'): notInformed,
    _k('Masculino'): male,
    _k('Feminino'): female,
    _k('Outro'): other,
    _k('Not informed'): notInformed,
    _k('Male'): male,
    _k('Female'): female,
    _k('Other'): other,
    _k('No informado'): notInformed,
    _k('Masculino'): male,
    _k('Femenino'): female,
    _k('Otro'): other,
  };

  static String? normalize(String value) {
    final key = _k(value);
    return _labelToCode[key];
  }

  static String _k(String value) {
    final lower = value.trim().toLowerCase();
    return lower
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('�', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }
}

