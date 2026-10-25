
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    final entries = [
      DailyEntry(
        date: DateTime(2026, 10, 20),
        weight: 75.5,
        calories: 2500,
        protein: 140,
      ),
      DailyEntry(
        date: DateTime(2026, 10, 21),
        weight: 75.2,
        calories: 2300,
        protein: 150,
      ),
      DailyEntry(
        date: DateTime(2026, 10, 22),
        weight: 74.9,
        calories: 2400,
        protein: null,
      ),
    ];

    test('calculates average weight', () {
      expect(
        AnalyticsService.averageWeight(entries),
        closeTo(75.2, 0.001),
      );
    });

    test('calculates average calories', () {
      expect(
        AnalyticsService.averageCalories(entries),
        closeTo(2400, 0.001),
      );
    });

    test('ignores missing protein values', () {
      expect(
        AnalyticsService.averageProtein(entries),
        closeTo(145, 0.001),
      );
    });

    test('calculates weight change', () {
      expect(
        AnalyticsService.weightChange(entries),
        closeTo(-0.6, 0.001),
      );
    });

    test('filters entries by date', () {
      final filtered = AnalyticsService.entriesForLastDays(
        entries,
        2,
        now: DateTime(2026, 10, 22),
      );

      expect(filtered.length, 2);
      expect(
        filtered.first.date,
        DateTime(2026, 10, 21),
      );
    });

    test('returns null for missing measurements', () {
      final empty = [
        DailyEntry(date: DateTime(2026, 10, 22)),
      ];

      expect(
        AnalyticsService.averageWeight(empty),
        isNull,
      );

      expect(
        AnalyticsService.averageProtein(empty),
        isNull,
      );

      expect(
        AnalyticsService.weightChange(empty),
        isNull,
      );
    });
  });
}
