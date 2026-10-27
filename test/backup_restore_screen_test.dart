import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/screens/backup_restore_screen.dart';

void main() {
  String makeBackupJson({bool includeGoals = false}) {
    return jsonEncode({
      'format': 'fittrack-backup',
      'version': 1,
      'exportedAt': '2026-10-27T12:00:00.000Z',
      'dailyEntries': <dynamic>[],
      'fitnessGoals':
          includeGoals
              ? {
                'daily_calories': 2200,
                'daily_protein': 150.0,
                'daily_carbs': 230.0,
                'daily_fat': 70.0,
                'daily_steps': 8000,
                'target_weight': 75.0,
              }
              : null,
    });
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Future<void> Function()? exportBackup,
    Future<String?> Function()? pickBackupJson,
    Future<void> Function(String)? restoreBackupJson,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BackupRestoreScreen(
          exportBackup: exportBackup,
          pickBackupJson: pickBackupJson,
          restoreBackupJson: restoreBackupJson,
        ),
      ),
    );
  }

  testWidgets('renders export and restore actions', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Select Backup File'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Export Backup'), findsOneWidget);
  });

  testWidgets('export calls the injected callback', (tester) async {
    var exportCount = 0;

    await pumpScreen(
      tester,
      exportBackup: () async {
        exportCount++;
      },
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Export Backup'));
    await tester.pump();

    expect(exportCount, 1);
    expect(find.text('Backup prepared for sharing.'), findsOneWidget);
  });

  testWidgets('cancelled file selection does not restore', (tester) async {
    var restoreCount = 0;

    await pumpScreen(
      tester,
      pickBackupJson: () async => null,
      restoreBackupJson: (_) async {
        restoreCount++;
      },
    );

    final importButton = find.text('Select Backup File');

    await tester.ensureVisible(importButton);
    await tester.pump();

    await tester.tap(importButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(restoreCount, 0);
    expect(find.text('Restore Backup?'), findsNothing);
  });

  testWidgets('invalid JSON is rejected without restoring', (tester) async {
    var restoreCount = 0;

    await pumpScreen(
      tester,
      pickBackupJson: () async => 'invalid json',
      restoreBackupJson: (_) async {
        restoreCount++;
      },
    );

    final importButton = find.text('Select Backup File');

    await tester.ensureVisible(importButton);
    await tester.pump();

    await tester.tap(importButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(restoreCount, 0);
    expect(find.text('Restore Backup?'), findsNothing);

    final errorMessage = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          (widget.data!.contains('Invalid backup:') ||
              widget.data!.contains('Import failed:')),
    );

    expect(errorMessage, findsOneWidget);
  });

  testWidgets('cancel in confirmation prevents restoration', (tester) async {
    var restoreCount = 0;

    await pumpScreen(
      tester,
      pickBackupJson: () async => makeBackupJson(),
      restoreBackupJson: (_) async {
        restoreCount++;
      },
    );

    final importButton = find.text('Select Backup File');

    await tester.ensureVisible(importButton);
    await tester.pump();

    await tester.tap(importButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Restore Backup?'), findsOneWidget);
    expect(find.textContaining('0 daily entries'), findsOneWidget);
    expect(find.textContaining('No fitness goals included.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(restoreCount, 0);
    expect(find.text('Restore Backup?'), findsNothing);
  });

  testWidgets('confirmation invokes restoration exactly once', (tester) async {
    var restoreCount = 0;
    String? restoredJson;
    final backupJson = makeBackupJson();

    await pumpScreen(
      tester,
      pickBackupJson: () async => backupJson,
      restoreBackupJson: (json) async {
        restoreCount++;
        restoredJson = json;
      },
    );

    final importButton = find.text('Select Backup File');

    await tester.ensureVisible(importButton);
    await tester.pump();

    await tester.tap(importButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Restore Backup?'), findsOneWidget);
    expect(restoreCount, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(restoreCount, 1);
    expect(restoredJson, backupJson);
    expect(find.text('Backup restored successfully!'), findsOneWidget);
  });
}
