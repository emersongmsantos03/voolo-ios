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
}
