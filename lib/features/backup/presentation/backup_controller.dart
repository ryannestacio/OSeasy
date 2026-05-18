import 'package:flutter/foundation.dart';

import '../../../core/services/backup_service.dart';

class BackupController extends ChangeNotifier {
  BackupController({required BackupService backupService})
    : _backupService = backupService;

  final BackupService _backupService;

  bool _isBusy = false;
  String? _databasePath;
  String? _lastBackupPath;
  String? _lastRestorePath;
  String? _statusMessage;

  bool get isBusy => _isBusy;
  String? get databasePath => _databasePath;
  String? get lastBackupPath => _lastBackupPath;
  String? get lastRestorePath => _lastRestorePath;
  String? get statusMessage => _statusMessage;

  Future<void> load() async {
    _databasePath = await _backupService.getCurrentDatabasePath();
    notifyListeners();
  }

  Future<String?> createBackup() async {
    _isBusy = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final backupPath = await _backupService.createBackup();
      if (backupPath == null) {
        _statusMessage = 'Backup cancelado pelo usuario.';
        return null;
      }

      _lastBackupPath = backupPath;
      _statusMessage = 'Backup gerado com sucesso.';
      return backupPath;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<String?> restoreBackup() async {
    _isBusy = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final restorePath = await _backupService.restoreBackup();
      if (restorePath == null) {
        _statusMessage = 'Restauracao cancelada pelo usuario.';
        return null;
      }

      _lastRestorePath = restorePath;
      _statusMessage = 'Backup restaurado com sucesso.';
      return restorePath;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
