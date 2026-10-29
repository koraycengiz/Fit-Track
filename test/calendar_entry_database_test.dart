import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fittrack/database/database_helper.dart';
import 'package:fittrack/models/daily_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();

  setUp(() async {
    DatabaseHelper.testDatabaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
    await DatabaseHelper.resetForTesting();
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    DatabaseHelper.testDatabaseFactory = null;
    DatabaseHelper.testDatabasePath = null;
  });

  final database = DatabaseHelper.instance;

  group('saveEntrySafely', () {
    test('creates an entry on an empty date', () async {
      final date = DateTime(2026, 10, 28);

      await database.saveEntrySafely(DailyEntry(date: date, weight: 72));

      final saved = await database.getEntryByDate(date);

      expect(saved, isNotNull);
      expect(saved!.weight, 72);
    });

    test('updates an existing entry', () async {
      final date = DateTime(2026, 10, 27);

      await database.saveEntry(DailyEntry(date: date, weight: 70));

      await database.saveEntrySafely(
        DailyEntry(date: date, weight: 71),
        originalDate: date,
      );

      final saved = await database.getEntryByDate(date);

      expect(saved!.weight, 71);
      expect((await database.getAllEntries()).length, 1);
    });

    test('moves an entry to an unoccupied date', () async {
      final oldDate = DateTime(2026, 10, 27);
      final newDate = DateTime(2026, 10, 28);

      await database.saveEntry(DailyEntry(date: oldDate, weight: 70));

      await database.saveEntrySafely(
        DailyEntry(date: newDate, weight: 71),
        originalDate: oldDate,
      );

      expect(await database.getEntryByDate(oldDate), isNull);

      final moved = await database.getEntryByDate(newDate);
      expect(moved, isNotNull);
      expect(moved!.weight, 71);

      expect((await database.getAllEntries()).length, 1);
    });

    test('rejects a move to an occupied date', () async {
      final oldDate = DateTime(2026, 10, 27);
      final occupiedDate = DateTime(2026, 10, 28);

      await database.saveEntry(DailyEntry(date: oldDate, weight: 70));

      await database.saveEntry(DailyEntry(date: occupiedDate, weight: 80));

      await expectLater(
        database.saveEntrySafely(
          DailyEntry(date: occupiedDate, weight: 75),
          originalDate: oldDate,
        ),
        throwsStateError,
      );

      final original = await database.getEntryByDate(oldDate);
      final occupied = await database.getEntryByDate(occupiedDate);

      expect(original!.weight, 70);
      expect(occupied!.weight, 80);
      expect((await database.getAllEntries()).length, 2);
    });

    test('rejects editing an entry that no longer exists', () async {
      final date = DateTime(2026, 10, 27);

      await expectLater(
        database.saveEntrySafely(
          DailyEntry(date: date, weight: 71),
          originalDate: date,
        ),
        throwsStateError,
      );

      expect(await database.getEntryByDate(date), isNull);
    });

    test('rejects creating an entry on an occupied date', () async {
      final date = DateTime(2026, 10, 28);

      await database.saveEntry(DailyEntry(date: date, weight: 70));

      await expectLater(
        database.saveEntrySafely(DailyEntry(date: date, weight: 90)),
        throwsStateError,
      );

      final saved = await database.getEntryByDate(date);

      expect(saved!.weight, 70);
      expect((await database.getAllEntries()).length, 1);
    });
  });
}
