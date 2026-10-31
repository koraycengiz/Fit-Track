class WeeklyGoalProgress {
  final int achievedDays;
  final int measuredDays;

  const WeeklyGoalProgress({
    required this.achievedDays,
    required this.measuredDays,
  });

  double? get achievementRate {
    if (measuredDays == 0) return null;
    return achievedDays / measuredDays;
  }
}

class WeeklyInsights {
  final DateTime weekStart;
  final DateTime weekEnd;

  final int loggedDays;

  final double? averageCalories;
  final double? averageProtein;
  final double? averageSteps;
  final double? weightChange;

  final WeeklyGoalProgress? caloriesGoal;
  final WeeklyGoalProgress? proteinGoal;
  final WeeklyGoalProgress? stepsGoal;

  const WeeklyInsights({
    required this.weekStart,
    required this.weekEnd,
    required this.loggedDays,
    required this.averageCalories,
    required this.averageProtein,
    required this.averageSteps,
    required this.weightChange,
    required this.caloriesGoal,
    required this.proteinGoal,
    required this.stepsGoal,
  });
}
