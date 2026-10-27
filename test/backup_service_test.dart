import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/models/fitness_goal.dart';
import 'package:fittrack/services/backup_service.dart';

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

  test('exports an empty database', () async {
    final backup = await BackupService().exportBackup();

    expect(backup['format'], 'fittrack-backup');
    expect(backup['version'], 1);
    expect(backup['dailyEntries'], isEmpty);
    expect(backup['fitnessGoals'], isNull);
    expect(DateTime.tryParse(backup['exportedAt'] as String), isNotNull);
  });

  test('exports saved daily entries', () async {
    await DatabaseHelper.instance.saveEntry(
      DailyEntry(
        date: DateTime(2026, 10, 27),
        weight: 70.5,
        calories: 2400,
        protein: 142.0,
        steps: 12356,
        notes: 'Great workout',
      ),
    );

    final backup = await BackupService().exportBackup();

    final entries = backup['dailyEntries'] as List<dynamic>;

    expect(entries.length, 1);

    final entry = entries.first as Map<String, Object?>;

    expect(entry['date'], '2026-10-27');
    expect(entry['weight'], 70.5);
    expect(entry['calories'], 2400);
    expect(entry['protein'], 142.0);
    expect(entry['steps'], 12356);
    expect(entry['notes'], 'Great workout');
    expect(entry['carbs'], isNull);
  });

  test('exports configured fitness goals', () async {
    await DatabaseHelper.instance.saveGoals(
      const FitnessGoal(
        dailyCalories: 2500,
        dailyProtein: 150.0,
        dailySteps: 10000,
        targetWeight: 72.0,
      ),
    );

    final backup = await BackupService().exportBackup();

    final goals = backup['fitnessGoals'] as Map<String, Object?>;

    expect(goals['daily_calories'], 2500);
    expect(goals['daily_protein'], 150.0);
    expect(goals['daily_steps'], 10000);
    expect(goals['target_weight'], 72.0);
    expect(goals['daily_carbs'], isNull);
  });

  test('exports valid JSON', () async {
    final jsonString = await BackupService().exportBackupJson();

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    expect(decoded['format'], 'fittrack-backup');
    expect(decoded['version'], 1);
    expect(decoded['dailyEntries'], isA<List>());
  });

  test('export does not modify existing data', () async {
    final date = DateTime(2026, 10, 27);

    await DatabaseHelper.instance.saveEntry(
      DailyEntry(date: date, weight: 71.0),
    );

    await BackupService().exportBackup();

    final savedEntry = await DatabaseHelper.instance.getEntryByDate(date);

    expect(savedEntry, isNotNull);
    expect(savedEntry!.weight, 71.0);
  });
}
