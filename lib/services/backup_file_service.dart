import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_service.dart';

class BackupFileService {
  BackupFileService({BackupService? backupService})
    : _backupService = backupService ?? BackupService();

  final BackupService _backupService;

  static const int maxBackupBytes = 10 * 1024 * 1024;

  Future<void> shareBackup() async {
    final json = await _backupService.exportBackupJson();

    final directory = await getTemporaryDirectory();

    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final file = File(
      p.join(directory.path, 'fittrack_backup_$timestamp.json'),
    );

    await file.writeAsString(json, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'FitTrack fitness data backup',
      ),
    );
  }

  Future<String?> pickBackupJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );

    if (result == null) {
      return null;
    }

    final selected = result.files.single;
    final path = selected.path;

    if (path == null) {
      throw const FormatException('Could not access the selected backup file.');
    }

    final file = File(path);

    final actualSize = await file.length();

    if (actualSize > maxBackupBytes) {
      throw const FormatException(
        'Backup file is too large. Maximum size is 10 MB.',
      );
    }

    return file.readAsString();
  }
}
