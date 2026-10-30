import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/services/tracking_streak_service.dart';

void main() {
  final today = DateTime(2026, 10, 30);

  DailyEntry entry(int year, int month, int day) {
    return DailyEntry(date: DateTime(year, month, day));
  }

  test('empty history returns zero streaks', () {
    final result = TrackingStreakService.calculate([], today: today);

    expect(result.currentStreak, 0);
    expect(result.longestStreak, 0);
  });

  test('consecutive days ending today', () {
    final result = TrackingStreakService.calculate([
      entry(2026, 10, 28),
      entry(2026, 10, 29),
      entry(2026, 10, 30),
    ], today: today);

    expect(result.currentStreak, 3);
    expect(result.longestStreak, 3);
  });

  test('yesterday keeps current streak active', () {
    final result = TrackingStreakService.calculate([
      entry(2026, 10, 27),
      entry(2026, 10, 28),
      entry(2026, 10, 29),
    ], today: today);

    expect(result.currentStreak, 3);
    expect(result.longestStreak, 3);
  });

  test('missing two days ends current streak', () {
    final result = TrackingStreakService.calculate([
      entry(2026, 10, 25),
      entry(2026, 10, 26),
      entry(2026, 10, 27),
    ], today: today);

    expect(result.currentStreak, 0);
    expect(result.longestStreak, 3);
  });

  test('longest streak can be greater than current streak', () {
    final result = TrackingStreakService.calculate([
      entry(2026, 10, 20),
      entry(2026, 10, 21),
      entry(2026, 10, 22),
      entry(2026, 10, 23),
      entry(2026, 10, 29),
      entry(2026, 10, 30),
    ], today: today);

    expect(result.currentStreak, 2);
    expect(result.longestStreak, 4);
  });

  test('duplicate dates count only once', () {
    final result = TrackingStreakService.calculate([
      entry(2026, 10, 29),
      entry(2026, 10, 29),
      entry(2026, 10, 30),
    ], today: today);

    expect(result.currentStreak, 2);
    expect(result.longestStreak, 2);
  });

  test('consecutive dates across months count correctly', () {
    final result = TrackingStreakService.calculate([
      entry(2026, 9, 30),
      entry(2026, 10, 1),
      entry(2026, 10, 2),
    ], today: DateTime(2026, 10, 2));

    expect(result.currentStreak, 3);
    expect(result.longestStreak, 3);
  });

  test('future entries do not affect streaks', () {
    final result = TrackingStreakService.calculate([
      entry(2026, 10, 29),
      entry(2026, 10, 30),
      entry(2026, 10, 31),
    ], today: today);

    expect(result.currentStreak, 2);
    expect(result.longestStreak, 2);
  });
}
