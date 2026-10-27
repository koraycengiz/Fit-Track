import 'dart:convert';

import '../database/database_helper.dart';
import 'backup_validator.dart';

class BackupService {
  BackupService({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  static const String backupFormat = 'fittrack-backup';
  static const int backupVersion = 1;

  Future<Map<String, Object?>> exportBackup() async {
    final entries = await _databaseHelper.getAllEntries();
    final goals = await _databaseHelper.getGoals();

    return {
      'format': backupFormat,
      'version': backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'dailyEntries': entries.map((entry) => entry.toMap()).toList(),
      'fitnessGoals': goals.hasAnyGoal ? goals.toMap() : null,
    };
  }

  Future<void> restoreBackupJson(String jsonString) async {
    // Validate the entire backup before writing anything.
    final validated = BackupValidator.validateJson(jsonString);

    // Replace all records in one atomic SQLite transaction.
    await _databaseHelper.replaceAllData(
      entries: validated.entries,
      goals: validated.goals,
    );
  }

  Future<String> exportBackupJson() async {
    final backup = await exportBackup();

    return const JsonEncoder.withIndent('  ').convert(backup);
  }
}
