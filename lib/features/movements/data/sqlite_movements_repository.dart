import '../../../core/database/local_database_service.dart';
import '../domain/movements.dart';

class SqliteMovementsRepository implements MovementsRepository {
  SqliteMovementsRepository(this._databaseService);

  final LocalDatabaseService _databaseService;

  @override
  Future<InventoryMovement> createMovement(InventoryMovementDraft draft) async {
    draft.validate();

    final database = await _databaseService.database;

    return database.transaction((transaction) async {
      final itemRows = await transaction.query(
        'items',
        columns: ['id', 'name', 'sku', 'quantity', 'is_active'],
        where: 'id = ?',
        whereArgs: [draft.itemId],
        limit: 1,
      );

      if (itemRows.isEmpty) {
        throw StateError('O item selecionado nao foi encontrado.');
      }

      final item = itemRows.first;
      if ((item['is_active'] as num?)?.toInt() == 0) {
        throw StateError(
          'O item selecionado esta inativo. Reative-o antes de registrar movimentacoes.',
        );
      }

      final currentQuantity = _toDouble(item['quantity']);
      final nextQuantity = switch (draft.type) {
        MovementType.entry => currentQuantity + draft.quantity,
        MovementType.exit => currentQuantity - draft.quantity,
        MovementType.adjustment => currentQuantity + draft.quantity,
      };

      if (nextQuantity < 0) {
        throw StateError('Estoque insuficiente para concluir a saida.');
      }

      final now = DateTime.now().toUtc().toIso8601String();

      await transaction.update(
        'items',
        {'quantity': nextQuantity, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [draft.itemId],
      );

      final movementId = await transaction.insert('movements', {
        'item_id': draft.itemId,
        'type': draft.type.storageValue,
        'quantity': draft.quantity,
        'note': draft.note.trim(),
        'created_at': now,
      });

      return InventoryMovement(
        id: movementId,
        itemId: draft.itemId,
        itemName: item['name'] as String? ?? '',
        itemSku: item['sku'] as String? ?? '',
        type: draft.type,
        quantity: draft.quantity,
        note: draft.note.trim(),
        createdAt: _parseDateTime(now) ?? DateTime.now(),
      );
    });
  }

  @override
  Future<List<InventoryMovement>> getMovements({int limit = 100}) async {
    final database = await _databaseService.database;
    final rows = await database.rawQuery(
      '''
      SELECT
        movements.id,
        movements.item_id,
        movements.type,
        movements.quantity,
        movements.note,
        movements.created_at,
        COALESCE(items.name, 'Item indisponivel') AS item_name,
        COALESCE(items.sku, 'SEM-CODIGO') AS item_sku
      FROM movements
      LEFT JOIN items ON items.id = movements.item_id
      ORDER BY movements.created_at DESC
      LIMIT ?
      ''',
      [limit],
    );

    return rows.map(_mapMovement).toList();
  }

  InventoryMovement _mapMovement(Map<String, Object?> row) {
    return InventoryMovement(
      id: row['id'] as int,
      itemId: row['item_id'] as int,
      itemName: row['item_name'] as String? ?? '',
      itemSku: row['item_sku'] as String? ?? '',
      type: MovementTypeValue.fromStorageValue(row['type'] as String? ?? ''),
      quantity: _toDouble(row['quantity']),
      note: row['note'] as String? ?? '',
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
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
}
