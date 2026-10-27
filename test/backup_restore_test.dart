import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/models/fitness_goal.dart';
import 'package:fittrack/services/backup_service.dart';
import 'package:fittrack/services/backup_validator.dart';

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

  test('restores daily entries and fitness goals', () async {
    final helper = DatabaseHelper.instance;
    final service = BackupService();

    final date = DateTime(2026, 10, 27);

    await helper.saveEntry(
      DailyEntry(date: date, weight: 70.5, calories: 2400),
    );

    await helper.saveGoals(
      const FitnessGoal(dailyCalories: 2500, dailyProtein: 150),
    );

    final json = await service.exportBackupJson();

    // Change the stored data before restoring.
    await helper.saveEntry(DailyEntry(date: date, weight: 90));

    await helper.clearGoals();

    await service.restoreBackupJson(json);

    final restored = await helper.getEntryByDate(date);
    final goals = await helper.getGoals();

    expect(restored?.weight, 70.5);
    expect(restored?.calories, 2400);
    expect(goals.dailyCalories, 2500);
    expect(goals.dailyProtein, 150);
  });

  test('replaces existing entries rather than merging', () async {
    final helper = DatabaseHelper.instance;
    final service = BackupService();

    final originalDate = DateTime(2026, 10, 20);
    final backupDate = DateTime(2026, 10, 27);

    await helper.saveEntry(DailyEntry(date: backupDate, weight: 70));

    final backup = await service.exportBackupJson();

    await helper.saveEntry(DailyEntry(date: originalDate, weight: 80));

    await service.restoreBackupJson(backup);

    final entries = await helper.getAllEntries();

    expect(entries.length, 1);
    expect(entries.first.date, backupDate);
    expect(entries.first.weight, 70);
  });

  test('rejects invalid JSON without changing data', () async {
    final helper = DatabaseHelper.instance;

    final date = DateTime(2026, 10, 27);

    await helper.saveEntry(DailyEntry(date: date, weight: 71));

    await expectLater(
      BackupService().restoreBackupJson('{invalid'),
      throwsA(isA<BackupValidationException>()),
    );

    final saved = await helper.getEntryByDate(date);

    expect(saved?.weight, 71);
  });

  test('restores an empty backup by clearing records', () async {
    final helper = DatabaseHelper.instance;
    final service = BackupService();

    final emptyBackup = await service.exportBackupJson();

    await helper.saveEntry(
      DailyEntry(date: DateTime(2026, 10, 27), weight: 70),
    );

    await helper.saveGoals(const FitnessGoal(dailySteps: 10000));

    await service.restoreBackupJson(emptyBackup);

    expect(await helper.getAllEntries(), isEmpty);
    expect((await helper.getGoals()).hasAnyGoal, isFalse);
  });

  test('rolls back all changes if a database insert fails', () async {
    final helper = DatabaseHelper.instance;
    final service = BackupService();

    final originalDate = DateTime(2026, 10, 20);

    await helper.saveEntry(DailyEntry(date: originalDate, weight: 75));

    await helper.saveGoals(const FitnessGoal(dailySteps: 8000));

    final db = await helper.database;

    // Simulate a database failure during restoration.
    await db.execute('''
      CREATE TRIGGER reject_restore_entry
      BEFORE INSERT ON daily_entries
      BEGIN
        SELECT RAISE(ABORT, 'Simulated restore failure');
      END;
    ''');

    final backup = {
      'format': 'fittrack-backup',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'dailyEntries': [
        DailyEntry(date: DateTime(2026, 10, 27), weight: 70).toMap(),
      ],
      'fitnessGoals': null,
    };

    try {
      await expectLater(
        service.restoreBackupJson(jsonEncode(backup)),
        throwsA(isA<DatabaseException>()),
      );

      // Original data must survive the failed transaction.
      final entries = await helper.getAllEntries();
      final goals = await helper.getGoals();

      expect(entries.length, 1);
      expect(entries.first.date, originalDate);
      expect(entries.first.weight, 75);
      expect(goals.dailySteps, 8000);
    } finally {
      await db.execute('DROP TRIGGER IF EXISTS reject_restore_entry');
    }
  });
}
