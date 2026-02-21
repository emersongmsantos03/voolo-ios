class ExpenseCategory {
  final String name;
  final List<String> subcategories;

  const ExpenseCategory({
    required this.name,
    required this.subcategories,
  });
}

class ExpenseCategories {
  ExpenseCategories._();

  static const List<ExpenseCategory> fixed = [
    ExpenseCategory(
      name: 'Moradia',
      subcategories: [
        'Aluguel',
        'Condomínio',
        'Água',
        'Energia',
        'Internet',
        'Gás',
      ],
    ),
    ExpenseCategory(
      name: 'Transporte',
      subcategories: [
        'Combustível',
        'Financiamento',
        'Seguro',
        'Transporte público',
      ],
    ),
    ExpenseCategory(
      name: 'Educação',
      subcategories: [
        'Faculdade',
        'Cursos',
        'Pós-graduação',
        'Outros',
      ],
    ),
  ];

  static const List<ExpenseCategory> variable = [
    ExpenseCategory(
      name: 'Alimentação',
      subcategories: [
        'Supermercado',
        'Restaurantes',
        'Delivery',
      ],
    ),
    ExpenseCategory(
      name: 'Lazer',
      subcategories: [
        'Viagens',
        'Streaming',
        'Eventos',
        'Hobbies',
      ],
    ),
    ExpenseCategory(
      name: 'Saúde',
      subcategories: [
        'Farmácia',
        'Consultas',
        'Plano de saúde',
      ],
    ),
    ExpenseCategory(
      name: 'Outros',
      subcategories: ['Outros'],
    ),
  ];

  static const List<String> investmentTypes = [
    'Poupança',
    'CDB',
    'Tesouro Direto',
    'Fundos Imobiliários',
    'Ações',
    'Criptomoedas',
    'Outros',
  ];
}
