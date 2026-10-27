import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/daily_entry.dart';
import '../models/fitness_goal.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  @visibleForTesting
  static DatabaseFactory? testDatabaseFactory;
  @visibleForTesting
  static String? testDatabasePath;

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
  static const String _goalsTableName = 'fitness_goals';

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

    final dbPath =
        testDatabasePath ??
        (testDatabaseFactory != null
            ? inMemoryDatabasePath
            : join(await getDatabasesPath(), 'fittrack.db'));

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,

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

          await _createGoalsTable(db);
        },

        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createGoalsTable(db);
          }
        },
      ),
    );
  }

  Future<void> _createGoalsTable(DatabaseExecutor db) async {
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

  // CREATE or UPDATE the user's fitness goals.
  Future<void> saveGoals(FitnessGoal goals) async {
    final db = await database;

    await db.insert(_goalsTableName, {
      'id': 1,
      ...goals.toMap(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // READ the user's fitness goals.
  Future<FitnessGoal> getGoals() async {
    final db = await database;

    final results = await db.query(
      _goalsTableName,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) {
      return const FitnessGoal();
    }

    return FitnessGoal.fromMap(results.first);
  }

  // DELETE all configured goals.
  Future<void> clearGoals() async {
    final db = await database;

    await db.delete(_goalsTableName, where: 'id = ?', whereArgs: [1]);
  }

  // CREATE or UPDATE
  // One entry per date. Saving the same date replaces its row.

  Future<void> saveEntry(DailyEntry entry) async {
    final db = await database;

    await db.insert(
      _tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

    final results = await db.query(_tableName, orderBy: 'date DESC');

    return results.map((row) => DailyEntry.fromMap(row)).toList();
  }

  // READ the most recent entry.
  Future<DailyEntry?> getLatestEntry() async {
    final db = await database;

    final results = await db.query(_tableName, orderBy: 'date DESC', limit: 1);

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
