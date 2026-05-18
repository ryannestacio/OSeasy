import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stokeasy/core/database/local_database_service.dart';

int _databaseSequence = 0;

String _uniqueDatabaseName(String prefix) {
  _databaseSequence += 1;
  return '${prefix}_$_databaseSequence.sqlite';
}

Future<void> _insertItem(
  Database db, {
  required String name,
  required String sku,
}) async {
  final now = DateTime.now().toUtc().toIso8601String();
  await db.insert('items', {
    'name': name,
    'sku': sku,
    'category': 'Teste',
    'unit': 'un',
    'quantity': 0,
    'minimum_stock': 0,
    'price': 0,
    'is_active': 1,
    'deactivated_at': null,
    'created_at': now,
    'updated_at': now,
  });
}

Future<void> _deleteServiceDatabase(LocalDatabaseService service) async {
  final databasePath = await service.databasePath;
  await service.close();
  await databaseFactoryFfi.deleteDatabase(databasePath);
}

Future<void> _createLegacyVersionFiveDatabase(String databasePath) async {
  final database = await databaseFactoryFfi.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            sku TEXT NOT NULL UNIQUE,
            category TEXT NOT NULL,
            unit TEXT NOT NULL,
            quantity REAL NOT NULL DEFAULT 0,
            minimum_stock REAL NOT NULL DEFAULT 0,
            price REAL NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            deactivated_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            quantity REAL NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          );
        ''');
      },
    ),
  );

  await _insertItem(database, name: 'Legado', sku: 'ITEM-0099');
  await database.close();
}

Future<void> _createBackupDatabase({
  required String databasePath,
  required int version,
  required Future<void> Function(Database db) onCreate,
}) async {
  final database = await databaseFactoryFfi.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(
      version: version,
      onCreate: (db, _) async => onCreate(db),
    ),
  );
  await database.close();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('constructor does not override global databaseFactory', () async {
    final globalFactoryBefore = databaseFactory;

    final service = LocalDatabaseService(
      databaseName: _uniqueDatabaseName('factory_guard'),
    );
    addTearDown(() async => _deleteServiceDatabase(service));

    expect(identical(databaseFactory, globalFactoryBefore), isTrue);
  });

  test('restoreFrom rejects corrupted backup files', () async {
    final service = LocalDatabaseService(
      databaseName: _uniqueDatabaseName('restore_corrupted'),
    );
    addTearDown(() async => _deleteServiceDatabase(service));

    await service.database;

    final backupFile = File(
      '${Directory.systemTemp.path}/corrupted_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    addTearDown(() async {
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });
    await backupFile.writeAsString('not a sqlite file');

    expect(
      () => service.restoreFrom(backupFile.path),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('invalido'),
        ),
      ),
    );
  });

  test('restoreFrom rejects backups with unsupported future version', () async {
    final service = LocalDatabaseService(
      databaseName: _uniqueDatabaseName('restore_version_guard'),
    );
    addTearDown(() async => _deleteServiceDatabase(service));

    await service.database;

    final backupPath =
        '${Directory.systemTemp.path}/future_version_${DateTime.now().microsecondsSinceEpoch}.sqlite';
    final backupFile = File(backupPath);
    addTearDown(() async {
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });

    await _createBackupDatabase(
      databasePath: backupPath,
      version: LocalDatabaseService.schemaVersion + 1,
      onCreate: (db) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY,
            sku TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            unit TEXT NOT NULL,
            quantity REAL NOT NULL,
            minimum_stock REAL NOT NULL,
            price REAL NOT NULL,
            is_active INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE movements (
            id INTEGER PRIMARY KEY,
            item_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            quantity REAL NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          );
        ''');
      },
    );

    expect(
      () => service.restoreFrom(backupPath),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('versao mais recente'),
        ),
      ),
    );
  });

  test('restoreFrom rejects backup with missing required tables', () async {
    final service = LocalDatabaseService(
      databaseName: _uniqueDatabaseName('restore_structure_guard'),
    );
    addTearDown(() async => _deleteServiceDatabase(service));

    await service.database;

    final backupPath =
        '${Directory.systemTemp.path}/invalid_structure_${DateTime.now().microsecondsSinceEpoch}.sqlite';
    final backupFile = File(backupPath);
    addTearDown(() async {
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });

    await _createBackupDatabase(
      databasePath: backupPath,
      version: LocalDatabaseService.schemaVersion,
      onCreate: (db) async {
        await db.execute(
          'CREATE TABLE random_table (id INTEGER PRIMARY KEY, value TEXT NOT NULL);',
        );
      },
    );

    expect(
      () => service.restoreFrom(backupPath),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('estrutura obrigatoria'),
        ),
      ),
    );
  });

  test('restoreFrom replaces current database with a valid backup', () async {
    final targetService = LocalDatabaseService(
      databaseName: _uniqueDatabaseName('restore_target'),
    );
    addTearDown(() async => _deleteServiceDatabase(targetService));

    final backupService = LocalDatabaseService(
      databaseName: _uniqueDatabaseName('restore_source'),
    );
    addTearDown(() async => _deleteServiceDatabase(backupService));

    final targetDb = await targetService.database;
    await _insertItem(targetDb, name: 'Item original', sku: 'ORI-001');

    final backupDb = await backupService.database;
    await _insertItem(backupDb, name: 'Item backup', sku: 'BKP-001');

    final backupPath = await backupService.databasePath;
    await targetService.restoreFrom(backupPath);

    final restoredRows = await (await targetService.database).query(
      'items',
      columns: ['name', 'sku'],
      orderBy: 'id ASC',
    );

    expect(restoredRows.length, 1);
    expect(restoredRows.first['name'], 'Item backup');
    expect(restoredRows.first['sku'], 'BKP-001');
  });

  test('upgrades legacy version 5 database and seeds sku counter', () async {
    final service = LocalDatabaseService(
      databaseName: _uniqueDatabaseName('migration_v5'),
    );
    addTearDown(() async => _deleteServiceDatabase(service));

    final databasePath = await service.databasePath;
    await service.close();
    await databaseFactoryFfi.deleteDatabase(databasePath);

    await _createLegacyVersionFiveDatabase(databasePath);

    final upgradedDatabase = await service.database;
    final counterRows = await upgradedDatabase.query(
      'app_counters',
      columns: ['value'],
      where: 'name = ?',
      whereArgs: [LocalDatabaseService.itemSkuCounterName],
      limit: 1,
    );

    expect(counterRows, isNotEmpty);
    expect(counterRows.first['value'], 99);
  });
}
