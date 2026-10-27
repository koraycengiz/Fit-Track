import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/fitness_goal.dart';
import 'package:fittrack/screens/goals_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUp(() async {
    await DatabaseHelper.resetForTesting();
    DatabaseHelper.testDatabaseFactory = databaseFactoryFfiNoIsolate;
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    DatabaseHelper.testDatabaseFactory = null;
  });

  Future<void> openGoalsScreen(WidgetTester tester) async {
    // Use a taller test viewport so the complete Goals form
    // can fit without requiring scrolling.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: GoalsScreen()));

    await tester.pumpAndSettle();
  }

  group('Goals Screen', () {
    testWidgets('shows all six optional goal fields', (tester) async {
      await openGoalsScreen(tester);

      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Daily Steps'), findsOneWidget);
      expect(find.text('Target Weight'), findsOneWidget);
    });

    testWidgets('loads previously saved goals', (tester) async {
      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2400, dailyProtein: 150),
      );

      await openGoalsScreen(tester);

      expect(find.text('2400'), findsOneWidget);
      expect(find.text('150.0'), findsOneWidget);
    });

    testWidgets('saves entered goals to the database', (tester) async {
      await openGoalsScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Calories'),
        '2400',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Protein'),
        '150',
      );

      final saveButton = find.text('Save Goals', skipOffstage: false);

      await tester.ensureVisible(saveButton);
      await tester.tap(find.text('Save Goals'));
      await tester.pumpAndSettle();

      final saved = await DatabaseHelper.instance.getGoals();

      expect(saved.dailyCalories, 2400);
      expect(saved.dailyProtein, 150);
    });

    testWidgets('rejects negative calorie values', (tester) async {
      await openGoalsScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Calories'),
        '-500',
      );

      final saveButton = find.text('Save Goals', skipOffstage: false);

      await tester.ensureVisible(saveButton);
      await tester.tap(find.text('Save Goals'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a positive whole number'), findsOneWidget);

      final saved = await DatabaseHelper.instance.getGoals();
      expect(saved.hasAnyGoal, false);
    });

    testWidgets('canceling clear preserves saved goals', (tester) async {
      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2400),
      );

      await openGoalsScreen(tester);

      final saveButton = find.text('Clear All Goals', skipOffstage: false);

      await tester.ensureVisible(saveButton);
      await tester.tap(find.text('Clear All Goals'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all goals?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final saved = await DatabaseHelper.instance.getGoals();
      expect(saved.dailyCalories, 2400);
    });

    testWidgets('confirming clear removes saved goals', (tester) async {
      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2400, dailyProtein: 150),
      );

      await openGoalsScreen(tester);

      final saveButton = find.text('Clear All Goals', skipOffstage: false);

      await tester.ensureVisible(saveButton);
      await tester.tap(find.text('Clear All Goals'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear Goals'));
      await tester.pumpAndSettle();

      final saved = await DatabaseHelper.instance.getGoals();

      expect(saved.hasAnyGoal, false);

      final calorieField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Calories'),
      );

      expect(calorieField.controller!.text, isEmpty);
    });
  });
}
