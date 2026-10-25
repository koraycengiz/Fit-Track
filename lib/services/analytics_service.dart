
import '../models/daily_entry.dart';

class AnalyticsService {
  // Return entries from the last N calendar days,
  // including today.
  static List<DailyEntry> entriesForLastDays(
      List<DailyEntry> entries,
      int days, {
        DateTime? now,
      }) {
    if (days <= 0) return [];

    final current = now ?? DateTime.now();

    final today = DateTime(
      current.year,
      current.month,
      current.day,
    );

    final startDate = today.subtract(
      Duration(days: days - 1),
    );

    final result = entries.where((entry) {
      final date = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );

      return !date.isBefore(startDate) &&
          !date.isAfter(today);
    }).toList();

    result.sort(
          (a, b) => a.date.compareTo(b.date),
    );

    return result;
  }

  static double? averageWeight(
      List<DailyEntry> entries,
      ) {
    final values = entries
        .where((entry) => entry.weight != null)
        .map((entry) => entry.weight!)
        .toList();

    return _average(values);
  }

  static double? averageCalories(
      List<DailyEntry> entries,
      ) {
    final values = entries
        .where((entry) => entry.calories != null)
        .map((entry) => entry.calories!.toDouble())
        .toList();

    return _average(values);
  }

  static double? averageProtein(
      List<DailyEntry> entries,
      ) {
    final values = entries
        .where((entry) => entry.protein != null)
        .map((entry) => entry.protein!)
        .toList();

    return _average(values);
  }

  // Difference between the first and last recorded
  // weights, in chronological order.
  static double? weightChange(
      List<DailyEntry> entries,
      ) {
    final recorded = entries
        .where((entry) => entry.weight != null)
        .toList();

    if (recorded.length < 2) return null;

    recorded.sort(
          (a, b) => a.date.compareTo(b.date),
    );

    return recorded.last.weight! -
        recorded.first.weight!;
  }

  static double? _average(List<double> values) {
    if (values.isEmpty) return null;

    final sum = values.fold<double>(
      0,
          (total, value) => total + value,
    );

    return sum / values.length;
  }
}
