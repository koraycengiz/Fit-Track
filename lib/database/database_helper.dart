
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/daily_entry.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance =
  DatabaseHelper._internal();

  @visibleForTesting
  static DatabaseFactory? testDatabaseFactory;

  static Database? _database;
  @visibleForTesting
  static Future<void> resetForTesting() async {
    final db = _database;
    _database = null;

    if (db != null) {
      await db.close();
    }
  }

  static const String _tableName = 'daily_entries';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final db = await _initializeDatabase();
    _database = db;
    return db;
  }


  Future<Database> _initializeDatabase() async {
    final factory = testDatabaseFactory ?? databaseFactory;

    final dbPath = testDatabaseFactory != null
        ? inMemoryDatabasePath
        : join(await getDatabasesPath(), 'fittrack.db');

    return factory.openDatabase(
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
  }


  // CREATE or UPDATE
  // One entry per date. Saving the same date replaces its row.

  Future<void> saveEntry(DailyEntry entry) async {
    final db = await database;

    debugPrint('DATABASE: Saving entry for ${entry.date}');

    await db.insert(
      _tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('DATABASE: Entry saved successfully');

    final entries = await getAllEntries();

    debugPrint('DATABASE: Total saved entries: ${entries.length}');

    for (final savedEntry in entries) {
      debugPrint(
        'DATABASE: ${savedEntry.date} '
            '- Weight: ${savedEntry.weight} '
            '- Calories: ${savedEntry.calories}',
      );
    }
  }


  // READ one entry by date.
  Future<DailyEntry?> getEntryByDate(DateTime date) async {
    final db = await database;

    final results = await db.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [DailyEntry.dateKey(date)],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return DailyEntry.fromMap(results.first);
  }

  // READ all entries, newest date first.
  Future<List<DailyEntry>> getAllEntries() async {
    final db = await database;

    final results = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );

    return results
        .map((row) => DailyEntry.fromMap(row))
        .toList();
  }

  // READ the most recent entry.
  Future<DailyEntry?> getLatestEntry() async {
    final db = await database;

    final results = await db.query(
      _tableName,
      orderBy: 'date DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return DailyEntry.fromMap(results.first);
  }

  // DELETE one entry by date.
  Future<int> deleteEntry(DateTime date) async {
    final db = await database;

    return db.delete(
      _tableName,
      where: 'date = ?',
      whereArgs: [DailyEntry.dateKey(date)],
    );
  }
}
