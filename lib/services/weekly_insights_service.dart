import '../models/daily_entry.dart';
import '../models/fitness_goal.dart';
import '../models/weekly_insights.dart';

class WeeklyInsightsService {
  static WeeklyInsights calculate({
    required List<DailyEntry> entries,
    required FitnessGoal goals,
    DateTime? selectedDate,
    DateTime? today,
  }) {
    final reference = _dateOnly(today ?? DateTime.now());
    final selected = _dateOnly(selectedDate ?? reference);

    final weekStart = selected.subtract(
      Duration(days: selected.weekday - DateTime.monday),
    );

    final weekEnd = weekStart.add(const Duration(days: 6));

    final weeklyEntries =
        entries.where((entry) {
            final date = _dateOnly(entry.date);

            return !date.isBefore(weekStart) &&
                !date.isAfter(weekEnd) &&
                !date.isAfter(reference);
          }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final loggedDays =
        weeklyEntries
            .map((entry) => DailyEntry.dateKey(entry.date))
            .toSet()
            .length;

    final calories =
        weeklyEntries
            .where((entry) => entry.calories != null)
            .map((entry) => entry.calories!)
            .toList();

    final protein =
        weeklyEntries
            .where((entry) => entry.protein != null)
            .map((entry) => entry.protein!)
            .toList();

    final steps =
        weeklyEntries
            .where((entry) => entry.steps != null)
            .map((entry) => entry.steps!)
            .toList();

    final weights =
        weeklyEntries
            .where((entry) => entry.weight != null)
            .map((entry) => entry.weight!)
            .toList();

    return WeeklyInsights(
      weekStart: weekStart,
      weekEnd: weekEnd,
      loggedDays: loggedDays,
      averageCalories: _average(calories),
      averageProtein: _average(protein),
      averageSteps: _average(steps),
      weightChange: weights.length < 2 ? null : weights.last - weights.first,
      caloriesGoal:
          goals.dailyCalories == null
              ? null
              : WeeklyGoalProgress(
                achievedDays:
                    calories
                        .where((value) => value <= goals.dailyCalories!)
                        .length,
                measuredDays: calories.length,
              ),
      proteinGoal:
          goals.dailyProtein == null
              ? null
              : WeeklyGoalProgress(
                achievedDays:
                    protein
                        .where((value) => value >= goals.dailyProtein!)
                        .length,
                measuredDays: protein.length,
              ),
      stepsGoal:
          goals.dailySteps == null
              ? null
              : WeeklyGoalProgress(
                achievedDays:
                    steps.where((value) => value >= goals.dailySteps!).length,
                measuredDays: steps.length,
              ),
    );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static double? _average(List<num> values) {
    if (values.isEmpty) return null;

    final sum = values.fold<double>(
      0,
      (total, value) => total + value.toDouble(),
    );

    return sum / values.length;
  }
}
