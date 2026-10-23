
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/daily_entry.dart';

void main() {
  group('DailyEntry serialization', () {
    test('converts a DailyEntry to a map', () {
      final entry = DailyEntry(
        date: DateTime(2026, 10, 23),
        weight: 70.5,
        calories: 2300,
        protein: 145,
        steps: 9000,
      );

      final map = entry.toMap();

      expect(map['date'], '2026-10-23');
      expect(map['weight'], 70.5);
      expect(map['calories'], 2300);
      expect(map['protein'], 145);
      expect(map['steps'], 9000);
      expect(map['waist'], isNull);
    });

    test('reconstructs a DailyEntry from a map', () {
      final map = <String, Object?>{
        'date': '2026-10-23',
        'weight': 70.5,
        'calories': 2300,
        'protein': 145.0,
        'carbs': null,
        'fat': null,
        'steps': 9000,
        'waist': null,
        'workout': 'Running',
        'notes': 'Good workout',
      };

      final entry = DailyEntry.fromMap(map);

      expect(entry.date, DateTime(2026, 10, 23));
      expect(entry.weight, 70.5);
      expect(entry.calories, 2300);
      expect(entry.steps, 9000);
      expect(entry.workout, 'Running');
      expect(entry.notes, 'Good workout');
    });

    test('normalizes dates without time', () {
      final date = DateTime(2026, 10, 23, 18, 45);

      expect(
        DailyEntry.dateKey(date),
        '2026-10-23',
      );
    });
  });
}
