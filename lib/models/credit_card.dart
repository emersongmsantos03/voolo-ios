class CreditCard {
  final String id;
  final String name;
  final int dueDay;

  CreditCard({
    required this.id,
    required this.name,
    required this.dueDay,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dueDay': dueDay,
      };

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'] as String,
      name: json['name'] as String,
      dueDay: (json['dueDay'] as num?)?.toInt() ?? 1,
    );
  }
}
