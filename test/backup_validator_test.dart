import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/services/backup_validator.dart';

void main() {
  Map<String, dynamic> validBackup() => {
    'format': 'fittrack-backup',
    'version': 1,
    'exportedAt': '2026-10-27T14:00:00.000Z',
    'dailyEntries': [
      {
        'date': '2026-10-27',
        'weight': 70.5,
        'calories': 2400,
        'protein': 142.0,
        'carbs': null,
        'fat': null,
        'steps': 12356,
        'waist': null,
        'workout': 'Chest workout',
        'notes': null,
      },
    ],
    'fitnessGoals': {
      'daily_calories': 2500,
      'daily_protein': 150.0,
      'daily_carbs': null,
      'daily_fat': null,
      'daily_steps': 10000,
      'target_weight': 72.0,
    },
  };

  test('accepts a valid backup', () {
    final result = BackupValidator.validate(validBackup());

    expect(result.entries.length, 1);
    expect(result.entries.first.weight, 70.5);
    expect(result.goals?.dailyCalories, 2500);
  });

  test('accepts valid JSON text', () {
    final result = BackupValidator.validateJson(jsonEncode(validBackup()));

    expect(result.entries.length, 1);
  });

  test('rejects invalid JSON', () {
    expect(
      () => BackupValidator.validateJson('{invalid'),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects an incorrect backup format', () {
    final backup = validBackup();
    backup['format'] = 'unknown';

    expect(
      () => BackupValidator.validate(backup),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects unsupported backup versions', () {
    final backup = validBackup();
    backup['version'] = 99;

    expect(
      () => BackupValidator.validate(backup),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects invalid calendar dates', () {
    final backup = validBackup();
    final entries = backup['dailyEntries'] as List;
    entries.first['date'] = '2026-02-30';

    expect(
      () => BackupValidator.validate(backup),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects duplicate dates', () {
    final backup = validBackup();
    final entries = backup['dailyEntries'] as List;
    entries.add(Map<String, dynamic>.from(entries.first));

    expect(
      () => BackupValidator.validate(backup),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects negative calories', () {
    final backup = validBackup();
    final entries = backup['dailyEntries'] as List;
    entries.first['calories'] = -100;

    expect(
      () => BackupValidator.validate(backup),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects invalid goal types', () {
    final backup = validBackup();

    final originalGoals = backup['fitnessGoals'] as Map;

    final goals = Map<String, dynamic>.from(originalGoals);

    goals['daily_steps'] = 'ten thousand';

    backup['fitnessGoals'] = goals;

    expect(
      () => BackupValidator.validate(backup),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('accepts an empty backup without goals', () {
    final backup = validBackup();
    backup['dailyEntries'] = [];
    backup['fitnessGoals'] = null;

    final result = BackupValidator.validate(backup);

    expect(result.entries, isEmpty);
    expect(result.goals, isNull);
  });
}
