import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fittrack/main.dart';
import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/daily_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    await DatabaseHelper.resetForTesting();
    DatabaseHelper.testDatabaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.testDatabasePath = null;
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    DatabaseHelper.testDatabaseFactory = null;
    DatabaseHelper.testDatabasePath = null;
  });

  Future<void> openDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    await tester.pumpAndSettle();
  }

  testWidgets('shows welcome screen when database is empty', (tester) async {
    await openDashboard(tester);

    expect(find.text('Welcome to FitTrack!'), findsOneWidget);
    expect(find.text('Add Your First Entry'), findsOneWidget);
    expect(find.text('No fitness entries recorded yet'), findsOneWidget);
  });

  testWidgets('shows metrics when a saved entry exists', (tester) async {
    await DatabaseHelper.instance.saveEntry(
      DailyEntry(
        date: DateTime.now(),
        weight: 70.5,
        calories: 2400,
        protein: 142,
        steps: 12356,
      ),
    );

    await openDashboard(tester);

    expect(find.text('70.5 kg'), findsOneWidget);
    expect(find.text('2400 kcal'), findsOneWidget);
    expect(find.text('142.0 g'), findsOneWidget);
    expect(find.text('12356'), findsOneWidget);

    expect(find.text('Welcome to FitTrack!'), findsNothing);
  });

  testWidgets('shows today label for today entry', (tester) async {
    await DatabaseHelper.instance.saveEntry(
      DailyEntry(date: DateTime.now(), weight: 71.0),
    );

    await openDashboard(tester);

    expect(find.text("Today's fitness data"), findsOneWidget);
  });

  testWidgets('shows historical date for older entry', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    await DatabaseHelper.instance.saveEntry(
      DailyEntry(date: yesterday, weight: 72.0),
    );

    await openDashboard(tester);

    expect(
      find.text('Latest entry: ${DailyEntry.dateKey(yesterday)}'),
      findsOneWidget,
    );

    expect(find.text("Today's fitness data"), findsNothing);
  });
}
