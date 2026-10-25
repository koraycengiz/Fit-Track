
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/fitness_goal.dart';

void main() {
  group('FitnessGoal', () {
    test('all goals are optional by default', () {
      const goal = FitnessGoal();

      expect(goal.hasAnyGoal, false);
      expect(goal.dailyCalories, isNull);
      expect(goal.targetWeight, isNull);
    });

    test('detects configured goals', () {
      const goal = FitnessGoal(
        dailyCalories: 2400,
        dailyProtein: 150,
      );

      expect(goal.hasAnyGoal, true);
      expect(goal.dailyCalories, 2400);
      expect(goal.dailyProtein, 150);
      expect(goal.dailySteps, isNull);
    });

    test('converts goal to map and back', () {
      const original = FitnessGoal(
        dailyCalories: 2400,
        dailyProtein: 150,
        dailyCarbs: 250,
        dailyFat: 70,
        dailySteps: 10000,
        targetWeight: 72.5,
      );

      final restored = FitnessGoal.fromMap(original.toMap());

      expect(restored.dailyCalories, 2400);
      expect(restored.dailyProtein, 150);
      expect(restored.dailyCarbs, 250);
      expect(restored.dailyFat, 70);
      expect(restored.dailySteps, 10000);
      expect(restored.targetWeight, 72.5);
    });

    test('copyWith updates selected goals', () {
      const original = FitnessGoal(
        dailyCalories: 2400,
        dailyProtein: 150,
      );

      final updated = original.copyWith(
        dailyCalories: 2200,
      );

      expect(updated.dailyCalories, 2200);
      expect(updated.dailyProtein, 150);
    });

    test('supports partially configured goals', () {
      const goal = FitnessGoal(
        dailySteps: 8000,
      );

      expect(goal.hasAnyGoal, true);
      expect(goal.dailyCalories, isNull);
      expect(goal.dailySteps, 8000);
    });
  });
}
