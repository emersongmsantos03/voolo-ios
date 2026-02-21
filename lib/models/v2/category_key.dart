String? toCategoryKey(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final upperSnake = RegExp(r'^[A-Z0-9_]+$');
  if (upperSnake.hasMatch(raw)) return raw;

  final lower = raw.toLowerCase();
  const legacy = {
    'moradia': 'MORADIA',
    'alimentacao': 'ALIMENTACAO',
    'transporte': 'TRANSPORTE',
    'educacao': 'EDUCACAO',
    'saude': 'SAUDE',
    'lazer': 'LAZER',
    'assinaturas': 'ASSINATURAS',
    'investment': 'INVESTIMENTO',
    'dividas': 'DIVIDAS',
    'outros': 'OUTROS',
  };
  if (legacy.containsKey(lower)) return legacy[lower];

  return lower.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
}
