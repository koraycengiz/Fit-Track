import 'dart:convert';

import '../models/daily_entry.dart';
import '../models/fitness_goal.dart';

class BackupValidationException implements Exception {
  final String message;

  const BackupValidationException(this.message);

  @override
  String toString() => 'BackupValidationException: $message';
}

class ValidatedBackup {
  final List<DailyEntry> entries;
  final FitnessGoal? goals;

  const ValidatedBackup({required this.entries, required this.goals});
}

class BackupValidator {
  static const String format = 'fittrack-backup';
  static const int version = 1;

  static const Set<String> _entryFields = {
    'date',
    'weight',
    'calories',
    'protein',
    'carbs',
    'fat',
    'steps',
    'waist',
    'workout',
    'notes',
  };

  static const Set<String> _goalFields = {
    'daily_calories',
    'daily_protein',
    'daily_carbs',
    'daily_fat',
    'daily_steps',
    'target_weight',
  };

  static ValidatedBackup validateJson(String jsonString) {
    dynamic decoded;

    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const BackupValidationException(
        'The backup file is not valid JSON.',
      );
    }

    return validate(decoded);
  }

  static ValidatedBackup validate(dynamic data) {
    final backup = _asMap(data, 'Backup');

    if (backup['format'] != format) {
      throw const BackupValidationException('This is not a FitTrack backup.');
    }

    if (backup['version'] != version) {
      throw const BackupValidationException('Unsupported backup version.');
    }

    final exportedAt = backup['exportedAt'];
    if (exportedAt is! String || DateTime.tryParse(exportedAt) == null) {
      throw const BackupValidationException('Invalid backup export timestamp.');
    }

    final rawEntries = backup['dailyEntries'];

    if (rawEntries is! List) {
      throw const BackupValidationException('dailyEntries must be a list.');
    }

    final entries = <DailyEntry>[];
    final dates = <String>{};

    for (var i = 0; i < rawEntries.length; i++) {
      final row = _asMap(rawEntries[i], 'Entry ${i + 1}');

      _requireFields(row, _entryFields, 'Entry ${i + 1}');

      final dateValue = row['date'];

      if (dateValue is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateValue)) {
        throw BackupValidationException('Entry ${i + 1} has an invalid date.');
      }

      final parsedDate = DateTime.tryParse(dateValue);

      if (parsedDate == null || DailyEntry.dateKey(parsedDate) != dateValue) {
        throw BackupValidationException(
          'Entry ${i + 1} has an invalid calendar date.',
        );
      }

      if (!dates.add(dateValue)) {
        throw BackupValidationException('Duplicate entry date: $dateValue');
      }

      _validateNumber(row, 'weight', i, positive: true);
      _validateNumber(row, 'calories', i, integer: true);
      _validateNumber(row, 'protein', i);
      _validateNumber(row, 'carbs', i);
      _validateNumber(row, 'fat', i);
      _validateNumber(row, 'steps', i, integer: true);
      _validateNumber(row, 'waist', i, positive: true);

      for (final field in ['workout', 'notes']) {
        final value = row[field];
        if (value != null && value is! String) {
          throw BackupValidationException(
            'Entry ${i + 1}: $field must be text.',
          );
        }
      }

      entries.add(DailyEntry.fromMap(row));
    }

    final rawGoals = backup['fitnessGoals'];
    FitnessGoal? goals;

    if (rawGoals != null) {
      final goalMap = _asMap(rawGoals, 'Fitness goals');

      _requireFields(goalMap, _goalFields, 'Fitness goals');

      for (final field in _goalFields) {
        final value = goalMap[field];

        if (value == null) continue;

        final integer = field == 'daily_calories' || field == 'daily_steps';

        if (value is! num ||
            !value.isFinite ||
            value < 0 ||
            (integer && value is! int) ||
            ((field == 'target_weight') && value <= 0)) {
          throw BackupValidationException('Invalid fitness goal: $field');
        }
      }

      goals = FitnessGoal.fromMap(goalMap);
    }

    return ValidatedBackup(entries: entries, goals: goals);
  }

  static Map<String, Object?> _asMap(dynamic value, String label) {
    if (value is! Map) {
      throw BackupValidationException('$label must be an object.');
    }

    if (value.keys.any((key) => key is! String)) {
      throw BackupValidationException('$label contains invalid field names.');
    }

    return Map<String, Object?>.from(value);
  }

  static void _requireFields(
    Map<String, Object?> map,
    Set<String> fields,
    String label,
  ) {
    for (final field in fields) {
      if (!map.containsKey(field)) {
        throw BackupValidationException('$label is missing $field.');
      }
    }
  }

  static void _validateNumber(
    Map<String, Object?> row,
    String field,
    int index, {
    bool integer = false,
    bool positive = false,
  }) {
    final value = row[field];

    if (value == null) return;

    if (value is! num ||
        !value.isFinite ||
        (positive ? value <= 0 : value < 0) ||
        (integer && value is! int)) {
      throw BackupValidationException('Entry ${index + 1}: invalid $field.');
    }
  }
}
