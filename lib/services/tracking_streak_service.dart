import '../models/daily_entry.dart';

class TrackingStreakResult {
  final int currentStreak;
  final int longestStreak;

  const TrackingStreakResult({
    required this.currentStreak,
    required this.longestStreak,
  });
}

class TrackingStreakService {
  static TrackingStreakResult calculate(
    List<DailyEntry> entries, {
    DateTime? today,
  }) {
    final reference = _dateOnly(today ?? DateTime.now());

    // Ignore future dates and count each calendar date only once.
    final dates =
        entries
            .map((entry) => _dateOnly(entry.date))
            .where((date) => !date.isAfter(reference))
            .map(_dayNumber)
            .toSet()
            .toList()
          ..sort();

    if (dates.isEmpty) {
      return const TrackingStreakResult(currentStreak: 0, longestStreak: 0);
    }

    int longest = 1;
    int running = 1;

    for (int i = 1; i < dates.length; i++) {
      if (dates[i] == dates[i - 1] + 1) {
        running++;
      } else {
        running = 1;
      }

      if (running > longest) {
        longest = running;
      }
    }

    final todayNumber = _dayNumber(reference);
    final lastDay = dates.last;

    // The current streak remains active until the end of today,
    // even if today's entry hasn't been recorded yet.
    if (lastDay != todayNumber && lastDay != todayNumber - 1) {
      return TrackingStreakResult(currentStreak: 0, longestStreak: longest);
    }

    int current = 1;

    for (int i = dates.length - 1; i > 0; i--) {
      if (dates[i] == dates[i - 1] + 1) {
        current++;
      } else {
        break;
      }
    }

    return TrackingStreakResult(currentStreak: current, longestStreak: longest);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static int _dayNumber(DateTime date) {
    return date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
