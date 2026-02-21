class ObjectivesCatalog {
  ObjectivesCatalog._();

  static const List<String> codes = [
    'dream',
    'property',
    'trip',
    'debts',
    'save',
    'security',
    'emergency_fund',
    'invest',
  ];

  static final Map<String, String> _labelToCode = {
    _k('Conquistar um sonho'): 'dream',
    _k('Adquirir um imovel'): 'property',
    _k('Fazer uma viagem'): 'trip',
    _k('Sair de dividas'): 'debts',
    _k('Guardar dinheiro'): 'save',
    _k('Ter mais seguranca'): 'security',
    _k('Construir reserva de emergencia'): 'emergency_fund',
    _k('Investir melhor'): 'invest',
    _k('Achieve a dream'): 'dream',
    _k('Buy a home'): 'property',
    _k('Take a trip'): 'trip',
    _k('Get out of debt'): 'debts',
    _k('Save money'): 'save',
    _k('Feel more secure'): 'security',
    _k('Build an emergency fund'): 'emergency_fund',
    _k('Invest better'): 'invest',
    _k('Conquistar un sueno'): 'dream',
    _k('Comprar una vivienda'): 'property',
    _k('Hacer un viaje'): 'trip',
    _k('Salir de deudas'): 'debts',
    _k('Ahorrar dinero'): 'save',
    _k('Tener mas seguridad'): 'security',
    _k('Construir un fondo de emergencia'): 'emergency_fund',
    _k('Invertir mejor'): 'invest',
  };

  static String? normalize(String label) {
    final key = _k(label);
    return _labelToCode[key];
  }

  static List<String> normalizeList(List<String> labels) {
    return labels.map((label) => normalize(label) ?? label).toList();
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

