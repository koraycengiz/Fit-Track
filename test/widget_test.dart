
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fittrack/main.dart';
import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/daily_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();

  // Use an in-memory SQLite database for widget tests.
  DatabaseHelper.testDatabaseFactory = databaseFactoryFfiNoIsolate;

  setUp(() async {
    await DatabaseHelper.resetForTesting();

    // Ensure every test starts with a clean database.
    final db = await DatabaseHelper.instance.database;
    await db.delete('daily_entries');
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
  });

  testWidgets('FitTrack dashboard displays correctly', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(const FitTrackApp());

    await tester.pumpAndSettle();

    expect(find.text('FitTrack'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Dashboard displays saved fitness data', (
      WidgetTester tester,
      ) async {
    final entry = DailyEntry(
      date: DateTime(2026, 10, 24),
      weight: 75.5,
      calories: 2500,
      protein: 150,
      steps: 10000,
    );

    await DatabaseHelper.instance.saveEntry(entry);

    await tester.pumpWidget(const FitTrackApp());

    await tester.pumpAndSettle();

    expect(find.textContaining('75.5'), findsWidgets);
    expect(find.textContaining('2500'), findsWidgets);
    expect(find.textContaining('10000'), findsWidgets);
  });
}
