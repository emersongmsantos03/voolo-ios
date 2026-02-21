enum GoalType {
  income,
  education,
  personal,
}

class Goal {
  final String id;
  final String title;
  final GoalType type;
  final int targetYear;
  final String description;
  bool completed;

  Goal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetYear,
    required this.description,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'targetYear': targetYear,
        'description': description,
        'completed': completed,
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      type: GoalType.values.byName(json['type'] as String),
      targetYear: json['targetYear'] as int,
      description: json['description'] as String,
      completed: (json['completed'] as bool?) ?? false,
    );
  }
}
