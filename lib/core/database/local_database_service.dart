import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabaseService {
  LocalDatabaseService({
    this.databaseName = 'stokeasy.sqlite',
    this.inMemory = false,
    DatabaseFactory? factory,
  }) {
    sqfliteFfiInit();
    _databaseFactory = factory ?? databaseFactoryFfi;
  }

  final String databaseName;
  final bool inMemory;
  late final DatabaseFactory _databaseFactory;
  static const int schemaVersion = 7;
  static const String itemSkuCounterName = 'item_sku_sequence';
  static const String itemSkuPrefix = 'ITEM-';
  static const Set<String> _minimumRequiredTables = {'items', 'movements'};

  Database? _database;
  String? _databasePath;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _databasePath ??= await _resolveDatabasePath();
    _database = await _databaseFactory.openDatabase(
      _databasePath!,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );

    return _database!;
  }

  Future<String> get databasePath async {
    _databasePath ??= await _resolveDatabasePath();
    return _databasePath!;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> restoreFrom(String sourcePath) async {
    if (inMemory) {
      throw StateError('Restauracao nao suportada em banco temporario.');
    }

    final targetPath = await databasePath;
    final normalizedSource = _normalizeFilePath(sourcePath);
    final normalizedTarget = _normalizeFilePath(targetPath);

    await _validateBackupFile(sourcePath);

    if (normalizedSource == normalizedTarget) {
      await close();
      await database;
      return;
    }

    await close();
    try {
      await _replaceDatabaseFileSafely(sourcePath, targetPath);
    } catch (_) {
      await database;
      rethrow;
    }
    await database;
  }

  Future<String> _resolveDatabasePath() async {
    if (inMemory) {
      return inMemoryDatabasePath;
    }

    final baseDirectory = await _databaseFactory.getDatabasesPath();
    await Directory(baseDirectory).create(recursive: true);

    return path.join(baseDirectory, databaseName);
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await _createMovementsTable(db);
    await _createMovementIndexes(db);
    await _createStockCountTables(db);
    await _createStockCountIndexes(db);
    await _createServiceOrderTables(db);
    await _createServiceOrderIndexes(db);
    await _createSystemCountersTable(db);
    await _seedItemSkuCounter(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE items ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1;',
      );
      await db.execute('ALTER TABLE items ADD COLUMN deactivated_at TEXT;');

      await db.execute('PRAGMA foreign_keys = OFF;');
      await db.execute('ALTER TABLE movements RENAME TO movements_legacy;');
      await _createMovementsTable(db);
      await db.execute('''
        INSERT INTO movements (id, item_id, type, quantity, note, created_at)
        SELECT id, item_id, type, quantity, note, created_at
        FROM movements_legacy;
      ''');
      await db.execute('DROP TABLE movements_legacy;');
      await _createMovementIndexes(db);
      await db.execute('PRAGMA foreign_keys = ON;');
    }

    if (oldVersion < 3) {
      await _createStockCountTables(db);
      await _createStockCountIndexes(db);
    }

    if (oldVersion < 4) {
      await _createServiceOrderTables(db);
      await _createServiceOrderIndexes(db);
    }

    if (oldVersion >= 4 && oldVersion < 5) {
      await db.execute(
        'ALTER TABLE service_orders ADD COLUMN is_draft INTEGER NOT NULL DEFAULT 0;',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_service_orders_draft ON service_orders(is_draft);',
      );
    }

    if (oldVersion < schemaVersion) {
      await _createSystemCountersTable(db);
      await _seedItemSkuCounter(db);
    }

    if (oldVersion < 7) {
      await _addCustomerColumnsIfMissing(db);
    }
  }

  Future<void> _createSystemCountersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_counters (
        name TEXT PRIMARY KEY,
        value INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  Future<void> _seedItemSkuCounter(Database db) async {
    const sequenceStartIndex = itemSkuPrefix.length + 1;
    final result = await db.rawQuery(
      '''
        SELECT COALESCE(MAX(CAST(SUBSTR(sku, ?) AS INTEGER)), 0) AS max_sequence
        FROM items
        WHERE sku LIKE ?
          AND LENGTH(SUBSTR(sku, ?)) > 0
          AND SUBSTR(sku, ?) NOT GLOB '*[^0-9]*'
      ''',
      [
        sequenceStartIndex,
        '$itemSkuPrefix%',
        sequenceStartIndex,
        sequenceStartIndex,
      ],
    );
    final maxSequence = (result.first['max_sequence'] as num?)?.toInt() ?? 0;

    await db.insert('app_counters', {
      'name': itemSkuCounterName,
      'value': maxSequence,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  String _normalizeFilePath(String value) {
    final normalized = path.normalize(path.absolute(value));
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  Future<void> _replaceDatabaseFileSafely(
    String sourcePath,
    String targetPath,
  ) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Arquivo de backup nao encontrado.');
    }

    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);

    final tempRestoreFile = File('$targetPath.restore_tmp');
    final previousFile = File('$targetPath.pre_restore');

    if (await tempRestoreFile.exists()) {
      await tempRestoreFile.delete();
    }
    if (await previousFile.exists()) {
      await previousFile.delete();
    }

    await sourceFile.copy(tempRestoreFile.path);
    await _validateBackupFile(tempRestoreFile.path);

    var movedPrevious = false;
    try {
      if (await targetFile.exists()) {
        await targetFile.rename(previousFile.path);
        movedPrevious = true;
      }

      await tempRestoreFile.rename(targetPath);

      if (movedPrevious && await previousFile.exists()) {
        await previousFile.delete();
      }
    } catch (_) {
      if (await tempRestoreFile.exists()) {
        await tempRestoreFile.delete();
      }
      if (movedPrevious &&
          !await targetFile.exists() &&
          await previousFile.exists()) {
        await previousFile.rename(targetPath);
      }
      rethrow;
    } finally {
      if (await tempRestoreFile.exists()) {
        await tempRestoreFile.delete();
      }
      if (await previousFile.exists() && await targetFile.exists()) {
        await previousFile.delete();
      }
    }
  }

  Future<void> _validateBackupFile(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw StateError('Arquivo de backup nao encontrado.');
    }

    Database? backupDatabase;
    try {
      backupDatabase = await _databaseFactory.openDatabase(
        backupPath,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
    } catch (_) {
      throw StateError('Arquivo de backup invalido ou corrompido.');
    }

    try {
      final integrityRows = await backupDatabase.rawQuery(
        'PRAGMA integrity_check;',
      );
      final integrityValue = integrityRows.isEmpty
          ? ''
          : (integrityRows.first.values.first ?? '').toString().trim();
      if (integrityValue.toLowerCase() != 'ok') {
        throw StateError(
          'Arquivo de backup invalido: integridade do SQLite comprometida.',
        );
      }

      final versionRows = await backupDatabase.rawQuery('PRAGMA user_version;');
      final backupVersion = versionRows.isEmpty
          ? 0
          : ((versionRows.first.values.first as num?)?.toInt() ?? 0);
      if (backupVersion <= 0) {
        throw StateError(
          'Arquivo de backup invalido: versao do banco desconhecida.',
        );
      }
      if (backupVersion > schemaVersion) {
        throw StateError(
          'Backup em versao mais recente ($backupVersion). Atualize o app antes de restaurar.',
        );
      }

      final placeholders = List.filled(
        _minimumRequiredTables.length,
        '?',
      ).join(',');
      final tableRows = await backupDatabase.rawQuery('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table' AND name IN ($placeholders)
        ''', _minimumRequiredTables.toList());
      final foundTables = tableRows
          .map((row) => (row['name'] as String? ?? '').trim())
          .where((name) => name.isNotEmpty)
          .toSet();
      final missingTables = _minimumRequiredTables.difference(foundTables);
      if (missingTables.isNotEmpty) {
        throw StateError(
          'Arquivo de backup invalido: estrutura obrigatoria ausente (${missingTables.join(', ')}).',
        );
      }
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError('Arquivo de backup invalido ou corrompido.');
    } finally {
      await backupDatabase.close();
    }
  }

  Future<void> _createMovementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT
      );
    ''');
  }

  Future<void> _createMovementIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movements_item_id ON movements(item_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movements_created_at ON movements(created_at DESC);',
    );
  }

  Future<void> _createStockCountTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_counts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        opened_by TEXT NOT NULL,
        closed_by TEXT,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        notes TEXT NOT NULL DEFAULT '',
        closing_notes TEXT NOT NULL DEFAULT '',
        blind_mode INTEGER NOT NULL DEFAULT 0,
        total_items INTEGER NOT NULL DEFAULT 0,
        counted_items INTEGER NOT NULL DEFAULT 0,
        divergent_items INTEGER NOT NULL DEFAULT 0,
        selected_items INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_count_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        count_id INTEGER NOT NULL,
        item_id INTEGER,
        item_name TEXT NOT NULL,
        item_sku TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        unit TEXT NOT NULL DEFAULT '',
        system_quantity REAL NOT NULL DEFAULT 0,
        counted_quantity REAL,
        difference REAL,
        unit_cost REAL NOT NULL DEFAULT 0,
        selected_for_export INTEGER NOT NULL DEFAULT 1,
        line_note TEXT NOT NULL DEFAULT '',
        counted_by TEXT,
        counted_at TEXT,
        line_status TEXT NOT NULL DEFAULT 'pending',
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (count_id) REFERENCES stock_counts(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL
      );
    ''');
  }

  Future<void> _createStockCountIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_counts_opened_at ON stock_counts(opened_at DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_count_lines_count_id ON stock_count_lines(count_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_count_lines_status ON stock_count_lines(line_status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_count_lines_selected ON stock_count_lines(selected_for_export);',
    );
  }

  Future<void> _createServiceOrderTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        trade_name TEXT NOT NULL DEFAULT '',
        contact_name TEXT NOT NULL DEFAULT '',
        birthday TEXT NOT NULL DEFAULT '',
        document TEXT NOT NULL DEFAULT '',
        state_registration TEXT NOT NULL DEFAULT '',
        person_type TEXT NOT NULL DEFAULT '',
        zip_code TEXT NOT NULL DEFAULT '',
        street TEXT NOT NULL DEFAULT '',
        street_number TEXT NOT NULL DEFAULT '',
        complement TEXT NOT NULL DEFAULT '',
        neighborhood TEXT NOT NULL DEFAULT '',
        city TEXT NOT NULL DEFAULT '',
        state_code TEXT NOT NULL DEFAULT '',
        country TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        business_phone TEXT NOT NULL DEFAULT '',
        mobile_phone TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT '',
        fiscal_email TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        customer_group TEXT NOT NULL DEFAULT '',
        gender TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS equipments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        model TEXT NOT NULL,
        brand TEXT NOT NULL DEFAULT '',
        micro_cpu TEXT NOT NULL DEFAULT '',
        ram_hd TEXT NOT NULL DEFAULT '',
        serial_number TEXT NOT NULL DEFAULT '',
        asset_tag TEXT NOT NULL DEFAULT '',
        accessories TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS technicians (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number INTEGER NOT NULL UNIQUE,
        is_draft INTEGER NOT NULL DEFAULT 0,
        customer_id INTEGER,
        equipment_id INTEGER,
        status TEXT NOT NULL DEFAULT 'open',
        priority TEXT NOT NULL DEFAULT 'normal',
        entry_at TEXT NOT NULL,
        ready_at TEXT,
        exit_at TEXT,
        warranty_until TEXT,
        responsible_technician_id INTEGER,
        responsible_technician_name TEXT NOT NULL DEFAULT '',
        situation_note TEXT NOT NULL DEFAULT '',
        customer_name TEXT NOT NULL DEFAULT '',
        customer_document TEXT NOT NULL DEFAULT '',
        customer_phone TEXT NOT NULL DEFAULT '',
        customer_email TEXT NOT NULL DEFAULT '',
        customer_address TEXT NOT NULL DEFAULT '',
        equipment_model TEXT NOT NULL DEFAULT '',
        equipment_brand TEXT NOT NULL DEFAULT '',
        equipment_micro_cpu TEXT NOT NULL DEFAULT '',
        equipment_ram_hd TEXT NOT NULL DEFAULT '',
        equipment_serial_number TEXT NOT NULL DEFAULT '',
        equipment_asset_tag TEXT NOT NULL DEFAULT '',
        equipment_accessories TEXT NOT NULL DEFAULT '',
        defect_complaint TEXT NOT NULL DEFAULT '',
        equipment_observations TEXT NOT NULL DEFAULT '',
        technical_report TEXT NOT NULL DEFAULT '',
        internal_notes TEXT NOT NULL DEFAULT '',
        advance_amount REAL NOT NULL DEFAULT 0,
        labor_amount REAL NOT NULL DEFAULT 0,
        parts_amount REAL NOT NULL DEFAULT 0,
        travel_amount REAL NOT NULL DEFAULT 0,
        third_party_amount REAL NOT NULL DEFAULT 0,
        other_amount REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT NOT NULL DEFAULT '',
        updated_by TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
        FOREIGN KEY (equipment_id) REFERENCES equipments(id) ON DELETE RESTRICT,
        FOREIGN KEY (responsible_technician_id) REFERENCES technicians(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_order_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        service_type TEXT NOT NULL DEFAULT 'Avulso',
        start_time TEXT,
        end_time TEXT,
        quantity REAL NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0,
        total_price REAL NOT NULL DEFAULT 0,
        technician_id INTEGER,
        technician_name TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES service_orders(id) ON DELETE CASCADE,
        FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_order_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        item_id INTEGER,
        part_name TEXT NOT NULL,
        origin TEXT NOT NULL DEFAULT 'loose',
        quantity REAL NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0,
        total_price REAL NOT NULL DEFAULT 0,
        technician_id INTEGER,
        technician_name TEXT NOT NULL DEFAULT '',
        stock_movement_applied INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES service_orders(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT,
        FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_order_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        created_by TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (order_id) REFERENCES service_orders(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_order_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        from_status TEXT,
        to_status TEXT,
        message TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        created_by TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (order_id) REFERENCES service_orders(id) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _createServiceOrderIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name COLLATE NOCASE);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_equipments_customer ON equipments(customer_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_equipments_model ON equipments(model COLLATE NOCASE);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_orders_number ON service_orders(order_number DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_orders_status ON service_orders(status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_orders_draft ON service_orders(is_draft);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_orders_entry ON service_orders(entry_at DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_orders_customer ON service_orders(customer_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_orders_equipment ON service_orders(equipment_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_order_services_order ON service_order_services(order_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_order_parts_order ON service_order_parts(order_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_order_attachments_order ON service_order_attachments(order_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_order_history_order ON service_order_history(order_id, created_at DESC);',
    );
  }

  Future<void> _addCustomerColumnsIfMissing(Database db) async {
    final customerTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'customers' LIMIT 1;",
    );
    if (customerTable.isEmpty) {
      return;
    }

    final tableInfo = await db.rawQuery('PRAGMA table_info(customers);');
    final existingColumns = tableInfo
        .map((row) => (row['name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    final requiredColumns = <String, String>{
      'trade_name': "TEXT NOT NULL DEFAULT ''",
      'contact_name': "TEXT NOT NULL DEFAULT ''",
      'birthday': "TEXT NOT NULL DEFAULT ''",
      'state_registration': "TEXT NOT NULL DEFAULT ''",
      'person_type': "TEXT NOT NULL DEFAULT ''",
      'zip_code': "TEXT NOT NULL DEFAULT ''",
      'street': "TEXT NOT NULL DEFAULT ''",
      'street_number': "TEXT NOT NULL DEFAULT ''",
      'complement': "TEXT NOT NULL DEFAULT ''",
      'neighborhood': "TEXT NOT NULL DEFAULT ''",
      'city': "TEXT NOT NULL DEFAULT ''",
      'state_code': "TEXT NOT NULL DEFAULT ''",
      'country': "TEXT NOT NULL DEFAULT ''",
      'business_phone': "TEXT NOT NULL DEFAULT ''",
      'mobile_phone': "TEXT NOT NULL DEFAULT ''",
      'fiscal_email': "TEXT NOT NULL DEFAULT ''",
      'notes': "TEXT NOT NULL DEFAULT ''",
      'customer_group': "TEXT NOT NULL DEFAULT ''",
      'gender': "TEXT NOT NULL DEFAULT ''",
    };

    for (final entry in requiredColumns.entries) {
      if (existingColumns.contains(entry.key)) {
        continue;
      }
      await db.execute(
        'ALTER TABLE customers ADD COLUMN ${entry.key} ${entry.value};',
      );
    }
  }
}
