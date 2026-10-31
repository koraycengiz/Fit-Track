import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/models/weekly_insights.dart';
import 'package:fittrack/widgets/weekly_insights_section.dart';

void main() {
  WeeklyInsights createInsights({
    int loggedDays = 3,
    double? averageCalories = 2300,
    double? averageProtein = 150,
    double? averageSteps = 9500,
    double? weightChange = -0.5,
    WeeklyGoalProgress? proteinGoal,
  }) {
    return WeeklyInsights(
      weekStart: DateTime.utc(2026, 10, 26),
      weekEnd: DateTime.utc(2026, 11, 1),
      loggedDays: loggedDays,
      averageCalories: averageCalories,
      averageProtein: averageProtein,
      averageSteps: averageSteps,
      weightChange: weightChange,
      caloriesGoal: null,
      proteinGoal: proteinGoal,
      stepsGoal: null,
    );
  }

  Future<void> pumpSection(
    WidgetTester tester,
    WeeklyInsights insights, {
    required VoidCallback onPreviousWeek,
    VoidCallback? onNextWeek,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeeklyInsightsSection(
              insights: insights,
              onPreviousWeek: onPreviousWeek,
              onNextWeek: onNextWeek,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('displays weekly summary', (tester) async {
    await pumpSection(tester, createInsights(), onPreviousWeek: () {});

    expect(find.text('Weekly Insights'), findsOneWidget);
    expect(find.text('3 days logged'), findsOneWidget);
    expect(find.text('2300.0 kcal'), findsOneWidget);
    expect(find.text('150.0 g'), findsOneWidget);
    expect(find.text('-0.5 kg'), findsOneWidget);
  });

  testWidgets('displays missing data correctly', (tester) async {
    await pumpSection(
      tester,
      createInsights(
        loggedDays: 0,
        averageCalories: null,
        averageProtein: null,
        averageSteps: null,
        weightChange: null,
      ),
      onPreviousWeek: () {},
    );

    expect(find.text('0 days logged'), findsOneWidget);
    expect(find.text('No data'), findsNWidgets(4));
  });

  testWidgets('previous week button invokes callback', (tester) async {
    var pressed = false;

    await pumpSection(
      tester,
      createInsights(),
      onPreviousWeek: () => pressed = true,
    );

    await tester.tap(find.byTooltip('Previous week'));

    expect(pressed, isTrue);
  });

  testWidgets('next week button is disabled when null', (tester) async {
    await pumpSection(tester, createInsights(), onPreviousWeek: () {});

    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('displays goal achievement', (tester) async {
    await pumpSection(
      tester,
      createInsights(
        proteinGoal: const WeeklyGoalProgress(achievedDays: 2, measuredDays: 3),
      ),
      onPreviousWeek: () {},
    );

    expect(find.text('Goal Achievement'), findsOneWidget);
    expect(find.text('2/3 days'), findsOneWidget);
  });
}
