import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/screens/analytics_screen.dart';

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

  Future<void> seedEntries() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final entries = [
      DailyEntry(date: todayDate, weight: 75.0, calories: 2500, protein: 150),
      DailyEntry(
        date: todayDate.subtract(const Duration(days: 2)),
        weight: 75.5,
        calories: 2300,
        protein: 140,
      ),
      DailyEntry(
        date: todayDate.subtract(const Duration(days: 15)),
        weight: 77.0,
        calories: 2800,
        protein: 120,
      ),
    ];

    for (final entry in entries) {
      await DatabaseHelper.instance.saveEntry(entry);
    }
  }

  testWidgets('Analytics screen displays summary cards', (
    WidgetTester tester,
  ) async {
    await seedEntries();

    await tester.pumpWidget(const MaterialApp(home: AnalyticsScreen()));

    await tester.pumpAndSettle();

    // Verify both analytics sections are present.
    expect(find.text('Progress Analytics'), findsOneWidget);
    expect(find.text('Weekly Insights'), findsOneWidget);

    // Verify existing summary metrics remain available.
    expect(find.text('Avg. Weight'), findsOneWidget);
    expect(find.text('Weight Change'), findsWidgets);
    expect(find.text('Avg. Calories'), findsWidgets);
    expect(find.text('Avg. Protein'), findsWidgets);

    // Verify calculated values without assuming
    // that they appear only once on the screen.
    expect(find.text('75.3 kg'), findsWidgets);
    expect(find.text('2,400 kcal'), findsWidgets);
    expect(find.text('145.0 g'), findsWidgets);
  });

  testWidgets('30-day filter includes older entries', (
    WidgetTester tester,
  ) async {
    await seedEntries();

    await tester.pumpWidget(const MaterialApp(home: AnalyticsScreen()));

    await tester.pumpAndSettle();

    expect(find.text('75.3 kg'), findsOneWidget);

    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();

    expect(find.text('75.8 kg'), findsOneWidget);
    expect(find.text('2,533 kcal'), findsOneWidget);
  });

  testWidgets('Metric selector changes chart', (WidgetTester tester) async {
    await seedEntries();

    await tester.pumpWidget(const MaterialApp(home: AnalyticsScreen()));

    await tester.pumpAndSettle();

    // Scroll down to the original analytics chart.
    await tester.scrollUntilVisible(
      find.text('Weight (kg)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();

    expect(find.text('Weight (kg)'), findsOneWidget);

    // Switch to Calories.
    await tester.tap(find.text('Calories').last);
    await tester.pumpAndSettle();

    expect(find.text('Calories (kcal)'), findsOneWidget);

    // Switch to Protein.
    await tester.tap(find.text('Protein').last);
    await tester.pumpAndSettle();

    expect(find.text('Protein (g)'), findsOneWidget);
  });
}
