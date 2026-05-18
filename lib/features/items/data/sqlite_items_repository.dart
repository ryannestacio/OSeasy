import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/local_database_service.dart';
import '../domain/items.dart';

class SqliteItemsRepository implements ItemsRepository {
  SqliteItemsRepository(this._databaseService);

  static const _generatedSkuPrefix = 'ITEM-';
  static const _generatedSkuPadding = 4;
  static const _maxGeneratedSkuRetries = 6;
  static const _generatedSkuSequenceStartIndex = _generatedSkuPrefix.length + 1;
  static final RegExp _digitsOnlyPattern = RegExp(r'^\d+$');

  final LocalDatabaseService _databaseService;

  Future<String> _resolveSku(
    DatabaseExecutor executor,
    String rawSku, {
    String? fallbackSku,
  }) async {
    final normalizedSku = rawSku.trim();
    if (normalizedSku.isNotEmpty) {
      return normalizedSku;
    }
    final normalizedFallback = fallbackSku?.trim() ?? '';
    if (normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    final sequence = await _nextGeneratedSkuSequence(executor);
    return _formatGeneratedSku(sequence);
  }

  @override
  Future<InventoryItem> createItem(InventoryItemDraft draft) async {
    draft.validate();

    final database = await _databaseService.database;
    final normalizedSku = draft.sku.trim();

    if (normalizedSku.isNotEmpty) {
      try {
        return await database.transaction((transaction) async {
          final created = await _insertItem(
            transaction,
            draft,
            sku: normalizedSku,
          );
          final manualSequence = _extractGeneratedSkuSequence(normalizedSku);
          if (manualSequence != null) {
            await _syncGeneratedSkuCounterFloor(transaction, manualSequence);
          }
          return created;
        });
      } catch (error) {
        if (_isSkuUniqueConstraintError(error)) {
          throw StateError('Ja existe um item cadastrado com esse codigo.');
        }
        rethrow;
      }
    }

    Object? lastUniqueError;
    for (var attempt = 0; attempt < _maxGeneratedSkuRetries; attempt++) {
      try {
        final generatedSku = await _resolveSku(database, draft.sku);
        return await _insertItem(database, draft, sku: generatedSku);
      } catch (error) {
        if (!_isSkuUniqueConstraintError(error)) {
          rethrow;
        }
        lastUniqueError = error;
      }
    }

    if (lastUniqueError != null) {
      throw StateError(
        'Nao foi possivel gerar um codigo de item unico automaticamente. Tente novamente.',
      );
    }

    throw StateError('Nao foi possivel cadastrar o item.');
  }

  @override
  Future<void> deactivateItem(int id) async {
    final database = await _databaseService.database;
    final rows = await database.query(
      'items',
      columns: ['id', 'quantity', 'is_active'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('O item selecionado nao foi encontrado.');
    }

    final item = rows.first;
    if ((item['is_active'] as num?)?.toInt() == 0) {
      return;
    }

    if (_toDouble(item['quantity']) != 0) {
      throw StateError(
        'Somente itens com estoque zerado podem ser inativados.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await database.update(
      'items',
      {'is_active': 0, 'deactivated_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<InventoryItem>> getItems({
    String query = '',
    ItemStatusFilter status = ItemStatusFilter.all,
    String category = '',
    String unit = '',
    ItemSortOption sort = ItemSortOption.newest,
  }) async {
    final database = await _databaseService.database;
    final normalizedQuery = query.trim();
    final normalizedCategory = category.trim();
    final normalizedUnit = unit.trim();
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    switch (status) {
      case ItemStatusFilter.active:
        whereClauses.add('is_active = 1');
      case ItemStatusFilter.inactive:
        whereClauses.add('is_active = 0');
      case ItemStatusFilter.all:
        break;
    }
    if (normalizedQuery.isNotEmpty) {
      whereClauses.add('(name LIKE ? OR sku LIKE ? OR category LIKE ?)');
      whereArgs.addAll(List.filled(3, '%$normalizedQuery%'));
    }
    if (normalizedCategory.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(normalizedCategory);
    }
    if (normalizedUnit.isNotEmpty) {
      whereClauses.add('unit = ?');
      whereArgs.add(normalizedUnit);
    }

    final orderBy = switch (sort) {
      ItemSortOption.nameAsc => 'is_active DESC, name COLLATE NOCASE ASC',
      ItemSortOption.newest => 'is_active DESC, updated_at DESC, name ASC',
      ItemSortOption.highestStock =>
        'is_active DESC, quantity DESC, name COLLATE NOCASE ASC',
      ItemSortOption.lowestStock =>
        'is_active DESC, quantity ASC, name COLLATE NOCASE ASC',
      ItemSortOption.highestValue =>
        'is_active DESC, (quantity * price) DESC, name COLLATE NOCASE ASC',
    };

    final rows = await database.query(
      'items',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return rows.map(_mapItem).toList();
  }

  @override
  Future<void> reactivateItem(int id) async {
    final database = await _databaseService.database;
    final rows = await database.query(
      'items',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('O item selecionado nao foi encontrado.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await database.update(
      'items',
      {'is_active': 1, 'deactivated_at': null, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateItem(int id, InventoryItemDraft draft) async {
    draft.validate();

    final database = await _databaseService.database;
    final currentRows = await database.query(
      'items',
      columns: ['quantity', 'created_at', 'sku', 'is_active', 'deactivated_at'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (currentRows.isEmpty) {
      throw StateError('O item selecionado nao foi encontrado.');
    }

    final currentItem = currentRows.first;
    final currentSku = (currentItem['sku'] as String? ?? '').trim();
    final shouldRetryGenerated = draft.sku.trim().isEmpty && currentSku.isEmpty;

    if (shouldRetryGenerated) {
      Object? lastUniqueError;
      for (var attempt = 0; attempt < _maxGeneratedSkuRetries; attempt++) {
        try {
          final sku = await _resolveSku(
            database,
            draft.sku,
            fallbackSku: currentItem['sku'] as String?,
          );
          await _updateItemRow(database, id, draft, currentItem, sku: sku);
          return;
        } catch (error) {
          if (!_isSkuUniqueConstraintError(error)) {
            rethrow;
          }
          lastUniqueError = error;
        }
      }

      if (lastUniqueError != null) {
        throw StateError(
          'Nao foi possivel gerar um codigo de item unico automaticamente. Tente novamente.',
        );
      }
    }

    final sku = await _resolveSku(
      database,
      draft.sku,
      fallbackSku: currentItem['sku'] as String?,
    );

    try {
      await _updateItemRow(database, id, draft, currentItem, sku: sku);
      final manualSequence = _extractGeneratedSkuSequence(sku);
      if (manualSequence != null) {
        await _syncGeneratedSkuCounterFloor(database, manualSequence);
      }
    } catch (error) {
      if (_isSkuUniqueConstraintError(error)) {
        throw StateError('Ja existe um item cadastrado com esse codigo.');
      }
      rethrow;
    }
  }

  InventoryItem _mapItem(Map<String, Object?> row) {
    return InventoryItem(
      id: row['id'] as int,
      name: row['name'] as String? ?? '',
      sku: row['sku'] as String? ?? '',
      category: row['category'] as String? ?? '',
      unit: row['unit'] as String? ?? '',
      quantity: _toDouble(row['quantity']),
      minimumStock: _toDouble(row['minimum_stock']),
      price: _toDouble(row['price']),
      isActive: (row['is_active'] as num?)?.toInt() != 0,
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(row['updated_at']) ?? DateTime.now(),
    );
  }

  DateTime? _parseDateTime(Object? value) {
    final raw = value as String?;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  double _toDouble(Object? value) {
    return (value as num?)?.toDouble() ?? 0;
  }

  int _toInt(Object? value) {
    return (value as num?)?.toInt() ?? 0;
  }

  Future<InventoryItem> _insertItem(
    DatabaseExecutor executor,
    InventoryItemDraft draft, {
    required String sku,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await executor.insert('items', {
      'name': draft.name.trim(),
      'sku': sku,
      'category': draft.category.trim(),
      'unit': draft.unit.trim(),
      'quantity': draft.initialQuantity,
      'minimum_stock': draft.minimumStock,
      'price': draft.price,
      'is_active': 1,
      'deactivated_at': null,
      'created_at': now,
      'updated_at': now,
    });

    final createdRows = await executor.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return _mapItem(createdRows.first);
  }

  Future<void> _updateItemRow(
    DatabaseExecutor executor,
    int id,
    InventoryItemDraft draft,
    Map<String, Object?> currentItem, {
    required String sku,
  }) async {
    await executor.update(
      'items',
      {
        'name': draft.name.trim(),
        'sku': sku,
        'category': draft.category.trim(),
        'unit': draft.unit.trim(),
        'quantity': _toDouble(currentItem['quantity']),
        'minimum_stock': draft.minimumStock,
        'price': draft.price,
        'is_active': (currentItem['is_active'] as num?)?.toInt() ?? 1,
        'deactivated_at': currentItem['deactivated_at'],
        'created_at': currentItem['created_at'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> _nextGeneratedSkuSequence(DatabaseExecutor executor) async {
    var updatedRows = await executor.rawUpdate(
      'UPDATE app_counters SET value = value + 1 WHERE name = ?',
      [LocalDatabaseService.itemSkuCounterName],
    );

    if (updatedRows == 0) {
      final maxSequence = await _readMaxGeneratedSkuSequence(executor);
      await executor.insert('app_counters', {
        'name': LocalDatabaseService.itemSkuCounterName,
        'value': maxSequence,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      updatedRows = await executor.rawUpdate(
        'UPDATE app_counters SET value = value + 1 WHERE name = ?',
        [LocalDatabaseService.itemSkuCounterName],
      );
      if (updatedRows == 0) {
        throw StateError('Nao foi possivel atualizar o contador de codigos.');
      }
    }

    final rows = await executor.query(
      'app_counters',
      columns: ['value'],
      where: 'name = ?',
      whereArgs: [LocalDatabaseService.itemSkuCounterName],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Contador de codigos de item nao encontrado.');
    }
    return _toInt(rows.first['value']);
  }

  Future<int> _readMaxGeneratedSkuSequence(DatabaseExecutor executor) async {
    final result = await executor.rawQuery(
      '''
        SELECT COALESCE(MAX(CAST(SUBSTR(sku, ?) AS INTEGER)), 0) AS max_sequence
        FROM items
        WHERE sku LIKE ?
          AND LENGTH(SUBSTR(sku, ?)) > 0
          AND SUBSTR(sku, ?) NOT GLOB '*[^0-9]*'
      ''',
      [
        _generatedSkuSequenceStartIndex,
        '$_generatedSkuPrefix%',
        _generatedSkuSequenceStartIndex,
        _generatedSkuSequenceStartIndex,
      ],
    );
    return _toInt(result.first['max_sequence']);
  }

  Future<void> _syncGeneratedSkuCounterFloor(
    DatabaseExecutor executor,
    int sequence,
  ) async {
    if (sequence <= 0) {
      return;
    }

    final updatedRows = await executor.rawUpdate(
      '''
        UPDATE app_counters
        SET value = CASE WHEN value < ? THEN ? ELSE value END
        WHERE name = ?
      ''',
      [sequence, sequence, LocalDatabaseService.itemSkuCounterName],
    );
    if (updatedRows == 0) {
      await executor.insert('app_counters', {
        'name': LocalDatabaseService.itemSkuCounterName,
        'value': sequence,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  int? _extractGeneratedSkuSequence(String sku) {
    if (!sku.startsWith(_generatedSkuPrefix)) {
      return null;
    }
    final suffix = sku.substring(_generatedSkuPrefix.length).trim();
    if (suffix.isEmpty || !_digitsOnlyPattern.hasMatch(suffix)) {
      return null;
    }
    return int.tryParse(suffix);
  }

  String _formatGeneratedSku(int sequence) {
    return '$_generatedSkuPrefix${sequence.toString().padLeft(_generatedSkuPadding, '0')}';
  }

  bool _isSkuUniqueConstraintError(Object error) {
    if (error is DatabaseException && error.isUniqueConstraintError()) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('unique constraint failed: items.sku') ||
        message.contains('code 2067');
  }
}
