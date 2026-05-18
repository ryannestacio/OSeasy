import '../../../core/database/local_database_service.dart';
import '../../movements/domain/movements.dart';
import '../domain/dashboard.dart';

class SqliteDashboardRepository implements DashboardRepository {
  SqliteDashboardRepository(this._databaseService);

  final LocalDatabaseService _databaseService;

  @override
  Future<DashboardMetrics> getMetrics() async {
    final database = await _databaseService.database;
    final monthStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    ).toUtc().toIso8601String();

    final totalItemsRow = (await database.rawQuery(
      'SELECT COUNT(*) AS total FROM items WHERE is_active = 1',
    )).first;
    final lowStockRow = (await database.rawQuery(
      'SELECT COUNT(*) AS total FROM items WHERE is_active = 1 AND quantity <= minimum_stock',
    )).first;
    final inventoryValueRow = (await database.rawQuery(
      'SELECT COALESCE(SUM(quantity * price), 0) AS total FROM items WHERE is_active = 1',
    )).first;
    final stockUnitsRow = (await database.rawQuery(
      'SELECT COALESCE(SUM(quantity), 0) AS total FROM items WHERE is_active = 1',
    )).first;
    final entryVolumeRow = (await database.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity), 0) AS total
      FROM movements
      WHERE type = 'entry' AND created_at >= ?
      ''',
      [monthStart],
    )).first;
    final exitVolumeRow = (await database.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity), 0) AS total
      FROM movements
      WHERE type = 'exit' AND created_at >= ?
      ''',
      [monthStart],
    )).first;

    final lowStockRows = await database.rawQuery('''
      SELECT name, sku, quantity, minimum_stock
      FROM items
      WHERE is_active = 1 AND quantity <= minimum_stock
      ORDER BY (minimum_stock - quantity) DESC, updated_at DESC
      LIMIT 6
      ''');

    final recentMovementRows = await database.rawQuery('''
      SELECT
        items.name AS item_name,
        items.sku AS item_sku,
        movements.type,
        movements.quantity,
        movements.created_at
      FROM movements
      LEFT JOIN items ON items.id = movements.item_id
      ORDER BY movements.created_at DESC
      LIMIT 8
      ''');

    return DashboardMetrics(
      totalItems: _toInt(totalItemsRow['total']),
      lowStockItems: _toInt(lowStockRow['total']),
      inventoryValue: _toDouble(inventoryValueRow['total']),
      stockUnits: _toDouble(stockUnitsRow['total']),
      entryVolumeThisMonth: _toDouble(entryVolumeRow['total']),
      exitVolumeThisMonth: _toDouble(exitVolumeRow['total']),
      lowStockList: lowStockRows
          .map(
            (row) => DashboardLowStockItem(
              name: row['name'] as String? ?? '',
              sku: row['sku'] as String? ?? '',
              quantity: _toDouble(row['quantity']),
              minimumStock: _toDouble(row['minimum_stock']),
            ),
          )
          .toList(),
      recentMovements: recentMovementRows
          .map(
            (row) => DashboardRecentMovement(
              itemName: row['item_name'] as String? ?? 'Item indisponivel',
              itemSku: row['item_sku'] as String? ?? 'SEM-CODIGO',
              type: MovementTypeValue.fromStorageValue(
                row['type'] as String? ?? '',
              ),
              quantity: _toDouble(row['quantity']),
              createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
            ),
          )
          .toList(),
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

  int _toInt(Object? value) {
    return (value as num?)?.toInt() ?? 0;
  }

  double _toDouble(Object? value) {
    return (value as num?)?.toDouble() ?? 0;
  }
}
