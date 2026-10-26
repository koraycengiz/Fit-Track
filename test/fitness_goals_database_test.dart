import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/models/fitness_goal.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

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

  group('Fitness Goals Database', () {
    test('returns empty goals when nothing is saved', () async {
      final goals = await DatabaseHelper.instance.getGoals();

      expect(goals.hasAnyGoal, false);
      expect(goals.dailyCalories, isNull);
      expect(goals.dailyProtein, isNull);
    });

    test('saves and retrieves fitness goals', () async {
      const goals = FitnessGoal(
        dailyCalories: 2400,
        dailyProtein: 150,
        dailyCarbs: 250,
        dailyFat: 70,
        dailySteps: 10000,
        targetWeight: 72.5,
      );

      await DatabaseHelper.instance.saveGoals(goals);

      final saved = await DatabaseHelper.instance.getGoals();

      expect(saved.dailyCalories, 2400);
      expect(saved.dailyProtein, 150);
      expect(saved.dailyCarbs, 250);
      expect(saved.dailyFat, 70);
      expect(saved.dailySteps, 10000);
      expect(saved.targetWeight, 72.5);
    });

    test('updates existing goals without creating duplicates', () async {
      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2400, dailyProtein: 150),
      );

      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2200, dailyProtein: 160),
      );

      final saved = await DatabaseHelper.instance.getGoals();

      expect(saved.dailyCalories, 2200);
      expect(saved.dailyProtein, 160);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('fitness_goals');

      expect(rows.length, 1);
    });

    test('supports partially configured goals', () async {
      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailySteps: 8000),
      );

      final saved = await DatabaseHelper.instance.getGoals();

      expect(saved.hasAnyGoal, true);
      expect(saved.dailySteps, 8000);
      expect(saved.dailyCalories, isNull);
    });

    test('clears individual goals when saving null values', () async {
      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2400, dailyProtein: 150),
      );

      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyProtein: 150),
      );

      final saved = await DatabaseHelper.instance.getGoals();

      expect(saved.dailyCalories, isNull);
      expect(saved.dailyProtein, 150);
    });

    test('clears all fitness goals', () async {
      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2400, dailySteps: 10000),
      );

      await DatabaseHelper.instance.clearGoals();

      final saved = await DatabaseHelper.instance.getGoals();

      expect(saved.hasAnyGoal, false);
    });

    test('saving goals does not modify daily entries', () async {
      final entry = DailyEntry(
        date: DateTime(2026, 10, 25),
        weight: 75.5,
        calories: 2500,
        protein: 140,
      );

      await DatabaseHelper.instance.saveEntry(entry);

      await DatabaseHelper.instance.saveGoals(
        const FitnessGoal(dailyCalories: 2300, dailyProtein: 150),
      );

      final savedEntry = await DatabaseHelper.instance.getEntryByDate(
        entry.date,
      );

      expect(savedEntry, isNotNull);
      expect(savedEntry!.weight, 75.5);
      expect(savedEntry.calories, 2500);
      expect(savedEntry.protein, 140);
    });

    test('upgrades a v1 database without losing daily entries', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'fittrack_migration_',
      );

      final dbPath = '${tempDir.path}/fittrack_migration.db';

      try {
        // Create a database using the original version 1 schema.
        final oldDb = await databaseFactoryFfiNoIsolate.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
            CREATE TABLE daily_entries (
              date TEXT PRIMARY KEY,
              weight REAL,
              calories INTEGER,
              protein REAL,
              carbs REAL,
              fat REAL,
              steps INTEGER,
              waist REAL,
              workout TEXT,
              notes TEXT
            )
          ''');
            },
          ),
        );

        await oldDb.insert('daily_entries', {
          'date': '2026-10-20',
          'weight': 75.5,
          'calories': 2500,
          'protein': 145.0,
        });

        await oldDb.close();

        // Reopen the existing database as version 2.
        final upgradedDb = await databaseFactoryFfiNoIsolate.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 2,
            onUpgrade: (db, oldVersion, newVersion) async {
              if (oldVersion < 2) {
                await db.execute('''
              CREATE TABLE fitness_goals (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                daily_calories INTEGER,
                daily_protein REAL,
                daily_carbs REAL,
                daily_fat REAL,
                daily_steps INTEGER,
                target_weight REAL
              )
            ''');
              }
            },
          ),
        );

        try {
          final entries = await upgradedDb.query('daily_entries');

          expect(entries.length, 1);
          expect(entries.first['date'], '2026-10-20');
          expect(entries.first['weight'], 75.5);
          expect(entries.first['calories'], 2500);

          // Verify the new goals table works.
          await upgradedDb.insert('fitness_goals', {
            'id': 1,
            'daily_calories': 2300,
            'daily_protein': 150.0,
          });

          final goals = await upgradedDb.query('fitness_goals');

          expect(goals.length, 1);
          expect(goals.first['daily_calories'], 2300);

          // Confirm the database version was upgraded.
          final versionResult = await upgradedDb.rawQuery(
            'PRAGMA user_version',
          );

          expect(versionResult.first['user_version'], 2);
        } finally {
          await upgradedDb.close();
        }
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
