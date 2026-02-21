import 'package:flutter/material.dart';

import '../models/goal.dart';

class GoalsState extends ChangeNotifier {
  final List<Goal> _goals = [];

  List<Goal> get goals => _goals;

  int get totalGoals => _goals.length;

  int get completedGoals => _goals.where((g) => g.completed).length;

  double get completionRate =>
      totalGoals == 0 ? 0 : completedGoals / totalGoals;

  void addGoal(Goal goal) {
    _goals.add(goal);
    notifyListeners();
  }

  void setGoalCompleted(String goalId, bool completed) {
    for (final goal in _goals) {
      if (goal.id == goalId) {
        goal.completed = completed;
        notifyListeners();
        return;
      }
    }
  }

  void removeGoal(String goalId) {
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
  }
}
