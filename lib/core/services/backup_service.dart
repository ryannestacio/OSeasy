import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

import '../database/local_database_service.dart';

class BackupService {
  BackupService(this._databaseService);

  final LocalDatabaseService _databaseService;

  static const List<XTypeGroup> _supportedTypeGroups = [
    XTypeGroup(label: 'Banco SQLite', extensions: ['sqlite', 'db', 'backup']),
  ];

  Future<String> getCurrentDatabasePath() {
    return _databaseService.databasePath;
  }

  Future<String?> createBackup() async {
    await _databaseService.database;

    final sourcePath = await _databaseService.databasePath;
    final saveLocation = await getSaveLocation(
      suggestedName:
          'stokeasy-backup-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.sqlite',
      acceptedTypeGroups: _supportedTypeGroups,
    );

    if (saveLocation == null) {
      return null;
    }

    await _copyReplacing(sourcePath, saveLocation.path);
    return saveLocation.path;
  }

  Future<String?> restoreBackup() async {
    final pickedFile = await openFile(acceptedTypeGroups: _supportedTypeGroups);

    if (pickedFile == null) {
      return null;
    }

    await _databaseService.restoreFrom(pickedFile.path);
    return pickedFile.path;
  }

  Future<void> _copyReplacing(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Arquivo de origem nao encontrado.');
    }

    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);

    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await sourceFile.copy(targetPath);
  }
}
