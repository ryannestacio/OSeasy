import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/core/database/local_database_service.dart';
import 'package:stokeasy/features/dashboard/data/sqlite_dashboard_repository.dart';
import 'package:stokeasy/features/movements/domain/movements.dart';

Future<int> _insertItem(
  LocalDatabaseService service, {
  required String name,
  required String sku,
  required double quantity,
  required double minimumStock,
  required double price,
  bool isActive = true,
}) async {
  final db = await service.database;
  final now = DateTime.now().toUtc().toIso8601String();
  return db.insert('items', {
    'name': name,
    'sku': sku,
    'category': 'Teste',
    'unit': 'un',
    'quantity': quantity,
    'minimum_stock': minimumStock,
    'price': price,
    'is_active': isActive ? 1 : 0,
    'deactivated_at': null,
    'created_at': now,
    'updated_at': now,
  });
}

Future<void> _insertMovement(
  LocalDatabaseService service, {
  required int itemId,
  required String type,
  required double quantity,
  required DateTime createdAt,
}) async {
  final db = await service.database;
  await db.insert('movements', {
    'item_id': itemId,
    'type': type,
    'quantity': quantity,
    'note': '',
    'created_at': createdAt.toUtc().toIso8601String(),
  });
}

void main() {
  late LocalDatabaseService databaseService;
  late SqliteDashboardRepository repository;

  setUp(() {
    databaseService = LocalDatabaseService(inMemory: true);
    repository = SqliteDashboardRepository(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
  });

  test('returns metrics with current month movement filters', () async {
    final lowItemId = await _insertItem(
      databaseService,
      name: 'Detergente',
      sku: 'LIMP-001',
      quantity: 2,
      minimumStock: 5,
      price: 10,
    );
    final regularItemId = await _insertItem(
      databaseService,
      name: 'Papel A4',
      sku: 'ESC-001',
      quantity: 12,
      minimumStock: 3,
      price: 2,
    );
    await _insertItem(
      databaseService,
      name: 'Item inativo',
      sku: 'OLD-001',
      quantity: 99,
      minimumStock: 1,
      price: 4,
      isActive: false,
    );

    final now = DateTime.now();
    final previousMonthDate = DateTime(now.year, now.month - 1, 15, 10, 0);

    await _insertMovement(
      databaseService,
      itemId: lowItemId,
      type: 'entry',
      quantity: 7,
      createdAt: now.subtract(const Duration(hours: 1)),
    );
    await _insertMovement(
      databaseService,
      itemId: regularItemId,
      type: 'exit',
      quantity: 3,
      createdAt: now,
    );
    await _insertMovement(
      databaseService,
      itemId: regularItemId,
      type: 'entry',
      quantity: 100,
      createdAt: previousMonthDate,
    );

    final metrics = await repository.getMetrics();

    expect(metrics.totalItems, 2);
    expect(metrics.lowStockItems, 1);
    expect(metrics.inventoryValue, 44);
    expect(metrics.stockUnits, 14);
    expect(metrics.entryVolumeThisMonth, 7);
    expect(metrics.exitVolumeThisMonth, 3);

    expect(metrics.lowStockList.length, 1);
    expect(metrics.lowStockList.first.name, 'Detergente');
    expect(metrics.lowStockList.first.sku, 'LIMP-001');

    expect(metrics.recentMovements.length, 3);
    expect(metrics.recentMovements.first.type, MovementType.exit);
    expect(metrics.recentMovements.first.itemName, 'Papel A4');
  });
}
