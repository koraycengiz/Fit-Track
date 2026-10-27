import 'package:flutter/material.dart';

import '../services/backup_file_service.dart';
import '../services/backup_service.dart';
import '../services/backup_validator.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({
    super.key,
    this.exportBackup,
    this.pickBackupJson,
    this.restoreBackupJson,
  });

  // Optional overrides allow widget tests to avoid native plugins.
  final Future<void> Function()? exportBackup;
  final Future<String?> Function()? pickBackupJson;
  final Future<void> Function(String json)? restoreBackupJson;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late final BackupFileService _fileService;
  late final BackupService _backupService;

  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _fileService = BackupFileService();
    _backupService = BackupService();
  }

  Future<void> _exportBackup() async {
    setState(() => _isBusy = true);

    try {
      if (widget.exportBackup != null) {
        await widget.exportBackup!();
      } else {
        await _fileService.shareBackup();
      }

      if (!mounted) return;

      _showMessage('Backup prepared for sharing.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Export failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isBusy = true);

    try {
      final json =
          widget.pickBackupJson != null
              ? await widget.pickBackupJson!()
              : await _fileService.pickBackupJson();

      if (!mounted || json == null) return;

      // Validation happens before any database operation.
      final validated = BackupValidator.validateJson(json);

      final goalsDescription =
          validated.goals == null
              ? 'No fitness goals included.'
              : 'Fitness goals included.';

      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Restore Backup?'),
              content: Text(
                'This backup contains ${validated.entries.length} '
                'daily entries.\n'
                '$goalsDescription\n\n'
                'Restoring it will REPLACE all existing fitness '
                'entries and goals on this device.\n\n'
                'Make sure you have exported your current data '
                'before continuing.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Restore'),
                ),
              ],
            ),
      );

      if (!mounted || confirmed != true) return;

      if (widget.restoreBackupJson != null) {
        await widget.restoreBackupJson!(json);
      } else {
        await _backupService.restoreBackupJson(json);
      }

      if (!mounted) return;

      _showMessage('Backup restored successfully!');
    } on BackupValidationException catch (error) {
      if (!mounted) return;
      _showMessage('Invalid backup: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Import failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.cloud_sync_outlined,
            size: 64,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 16),
          Text(
            'Keep your fitness data safe',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Export your fitness history and goals, '
            'or restore them from a previously saved backup.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.file_upload_outlined, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Export Backup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a JSON backup of your daily '
                    'entries and fitness goals.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : _exportBackup,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Export Backup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.file_download_outlined, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Restore Backup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a FitTrack JSON backup. '
                    'You will be asked to confirm before '
                    'any existing data is replaced.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _importBackup,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Select Backup File'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isBusy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
