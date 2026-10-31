import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/models/fitness_goal.dart';
import 'package:fittrack/services/weekly_insights_service.dart';

void main() {
  group('WeeklyInsightsService', () {
    final entries = [
      DailyEntry(
        date: DateTime(2026, 10, 26),
        weight: 75.5,
        calories: 2400,
        protein: 140,
        steps: 8000,
      ),
      DailyEntry(
        date: DateTime(2026, 10, 27),
        weight: 75.2,
        calories: 2200,
        protein: 160,
        steps: 11000,
      ),
      DailyEntry(
        date: DateTime(2026, 10, 28),
        weight: 75.0,
        calories: 2300,
        protein: null,
        steps: 10000,
      ),
    ];

    const goals = FitnessGoal(
      dailyCalories: 2300,
      dailyProtein: 150,
      dailySteps: 10000,
    );

    test('calculates Monday to Sunday boundaries', () {
      final result = WeeklyInsightsService.calculate(
        entries: entries,
        goals: goals,
        today: DateTime(2026, 10, 30),
      );

      expect(result.weekStart, DateTime.utc(2026, 10, 26));
      expect(result.weekEnd, DateTime.utc(2026, 11, 1));
    });

    test('calculates weekly averages', () {
      final result = WeeklyInsightsService.calculate(
        entries: entries,
        goals: goals,
        today: DateTime(2026, 10, 30),
      );

      expect(result.loggedDays, 3);
      expect(result.averageCalories, closeTo(2300, 0.001));
      expect(result.averageProtein, closeTo(150, 0.001));
      expect(result.averageSteps, closeTo(9666.67, 0.01));
    });

    test('calculates weight change', () {
      final result = WeeklyInsightsService.calculate(
        entries: entries,
        goals: goals,
        today: DateTime(2026, 10, 30),
      );

      expect(result.weightChange, closeTo(-0.5, 0.001));
    });

    test('calculates goal achievement', () {
      final result = WeeklyInsightsService.calculate(
        entries: entries,
        goals: goals,
        today: DateTime(2026, 10, 30),
      );

      expect(result.caloriesGoal!.achievedDays, 2);
      expect(result.caloriesGoal!.measuredDays, 3);

      expect(result.proteinGoal!.achievedDays, 1);
      expect(result.proteinGoal!.measuredDays, 2);

      expect(result.stepsGoal!.achievedDays, 2);
      expect(result.stepsGoal!.measuredDays, 3);
    });

    test('handles empty weeks', () {
      final result = WeeklyInsightsService.calculate(
        entries: [],
        goals: goals,
        today: DateTime(2026, 10, 30),
      );

      expect(result.loggedDays, 0);
      expect(result.averageCalories, isNull);
      expect(result.averageProtein, isNull);
      expect(result.averageSteps, isNull);
      expect(result.weightChange, isNull);
      expect(result.caloriesGoal!.achievementRate, isNull);
    });

    test('ignores future entries', () {
      final result = WeeklyInsightsService.calculate(
        entries: [DailyEntry(date: DateTime(2026, 11, 1), calories: 2000)],
        goals: goals,
        today: DateTime(2026, 10, 30),
      );

      expect(result.loggedDays, 0);
      expect(result.averageCalories, isNull);
    });

    test('handles unconfigured goals', () {
      final result = WeeklyInsightsService.calculate(
        entries: entries,
        goals: const FitnessGoal(),
        today: DateTime(2026, 10, 30),
      );

      expect(result.caloriesGoal, isNull);
      expect(result.proteinGoal, isNull);
      expect(result.stepsGoal, isNull);
    });

    test('supports previous weeks', () {
      final result = WeeklyInsightsService.calculate(
        entries: [DailyEntry(date: DateTime(2026, 10, 20), calories: 2100)],
        goals: goals,
        selectedDate: DateTime(2026, 10, 21),
        today: DateTime(2026, 10, 30),
      );

      expect(result.weekStart, DateTime.utc(2026, 10, 19));
      expect(result.loggedDays, 1);
      expect(result.averageCalories, 2100);
    });
  });
}
