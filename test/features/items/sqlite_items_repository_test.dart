import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/core/database/local_database_service.dart';
import 'package:stokeasy/features/items/data/sqlite_items_repository.dart';
import 'package:stokeasy/features/items/domain/items.dart';

void main() {
  late LocalDatabaseService databaseService;
  late SqliteItemsRepository repository;

  setUp(() {
    databaseService = LocalDatabaseService(inMemory: true);
    repository = SqliteItemsRepository(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
  });

  test('creates an item with generated code when code is blank', () async {
    final created = await repository.createItem(
      const InventoryItemDraft(
        name: 'Detergente',
        sku: '',
        category: 'Limpeza',
        unit: 'un',
        initialQuantity: 8,
        minimumStock: 2,
        price: 14.9,
      ),
    );

    expect(created.sku, 'ITEM-0001');
  });

  test('keeps generated counter aligned with manual ITEM- codes', () async {
    await repository.createItem(
      const InventoryItemDraft(
        name: 'Parafuso',
        sku: 'ITEM-0450',
        category: 'Ferragens',
        unit: 'un',
        initialQuantity: 10,
        minimumStock: 2,
        price: 0.5,
      ),
    );

    final generated = await repository.createItem(
      const InventoryItemDraft(
        name: 'Porca',
        sku: '',
        category: 'Ferragens',
        unit: 'un',
        initialQuantity: 12,
        minimumStock: 3,
        price: 0.4,
      ),
    );

    expect(generated.sku, 'ITEM-0451');
  });

  test('retries generated code when counter is stale and collides', () async {
    final first = await repository.createItem(
      const InventoryItemDraft(
        name: 'Luva nitrilica',
        sku: '',
        category: 'EPI',
        unit: 'caixa',
        initialQuantity: 6,
        minimumStock: 2,
        price: 19.9,
      ),
    );
    expect(first.sku, 'ITEM-0001');

    final database = await databaseService.database;
    await database.update(
      'app_counters',
      {'value': 0},
      where: 'name = ?',
      whereArgs: [LocalDatabaseService.itemSkuCounterName],
    );

    final retried = await repository.createItem(
      const InventoryItemDraft(
        name: 'Mascara PFF2',
        sku: '',
        category: 'EPI',
        unit: 'un',
        initialQuantity: 20,
        minimumStock: 5,
        price: 3.2,
      ),
    );

    expect(retried.sku, 'ITEM-0002');
  });

  test('keeps current code when editing with blank code', () async {
    final created = await repository.createItem(
      const InventoryItemDraft(
        name: 'Agua sanitaria',
        sku: 'LIMP-001',
        category: 'Limpeza',
        unit: 'un',
        initialQuantity: 10,
        minimumStock: 3,
        price: 9.5,
      ),
    );

    await repository.updateItem(
      created.id!,
      const InventoryItemDraft(
        name: 'Agua sanitaria premium',
        sku: '',
        category: 'Limpeza',
        unit: 'un',
        initialQuantity: 99,
        minimumStock: 4,
        price: 12,
      ),
    );

    final items = await repository.getItems();
    final updated = items.singleWhere((item) => item.id == created.id);

    expect(updated.sku, 'LIMP-001');
    expect(updated.name, 'Agua sanitaria premium');
    expect(updated.quantity, 10);
  });

  test(
    'deactivates item safely and keeps it available only when requested',
    () async {
      final created = await repository.createItem(
        const InventoryItemDraft(
          name: 'Papel toalha',
          sku: 'PAP-001',
          category: 'Limpeza',
          unit: 'un',
          initialQuantity: 0,
          minimumStock: 5,
          price: 6,
        ),
      );

      await repository.deactivateItem(created.id!);

      final activeItems = await repository.getItems(
        status: ItemStatusFilter.active,
      );
      final allItems = await repository.getItems(status: ItemStatusFilter.all);

      expect(activeItems, isEmpty);
      expect(allItems.single.isActive, isFalse);
    },
  );

  test('prevents deactivation when item still has stock', () async {
    final created = await repository.createItem(
      const InventoryItemDraft(
        name: 'Copo descartavel',
        sku: 'COP-001',
        category: 'Descartaveis',
        unit: 'un',
        initialQuantity: 12,
        minimumStock: 3,
        price: 8,
      ),
    );

    expect(
      () => repository.deactivateItem(created.id!),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Somente itens com estoque zerado podem ser inativados.',
        ),
      ),
    );
  });

  test('reactivates an inactive item', () async {
    final created = await repository.createItem(
      const InventoryItemDraft(
        name: 'Luva',
        sku: 'LUV-001',
        category: 'EPI',
        unit: 'par',
        initialQuantity: 0,
        minimumStock: 1,
        price: 3.5,
      ),
    );

    await repository.deactivateItem(created.id!);
    await repository.reactivateItem(created.id!);

    final items = await repository.getItems();
    expect(items.single.isActive, isTrue);
  });

  test('filters items by status category and unit', () async {
    final activeCleaning = await repository.createItem(
      const InventoryItemDraft(
        name: 'Detergente neutro',
        sku: 'LIMP-010',
        category: 'Limpeza',
        unit: 'litro',
        initialQuantity: 4,
        minimumStock: 1,
        price: 8,
      ),
    );
    await repository.createItem(
      const InventoryItemDraft(
        name: 'Papel sulfite',
        sku: 'PAP-010',
        category: 'Escritorio',
        unit: 'un',
        initialQuantity: 10,
        minimumStock: 2,
        price: 24,
      ),
    );
    final inactiveCleaning = await repository.createItem(
      const InventoryItemDraft(
        name: 'Sabao liquido',
        sku: 'LIMP-011',
        category: 'Limpeza',
        unit: 'ml',
        initialQuantity: 0,
        minimumStock: 0,
        price: 5,
      ),
    );
    await repository.deactivateItem(inactiveCleaning.id!);

    final activeByCategory = await repository.getItems(
      status: ItemStatusFilter.active,
      category: 'Limpeza',
    );
    final inactiveByUnit = await repository.getItems(
      status: ItemStatusFilter.inactive,
      unit: 'ml',
    );
    final allByUnit = await repository.getItems(
      status: ItemStatusFilter.all,
      unit: 'litro',
    );

    expect(activeByCategory.map((item) => item.id), [activeCleaning.id]);
    expect(inactiveByUnit.map((item) => item.id), [inactiveCleaning.id]);
    expect(allByUnit.map((item) => item.id), [activeCleaning.id]);
  });

  test('sorts items by requested ordering', () async {
    await repository.createItem(
      const InventoryItemDraft(
        name: 'Zinco',
        sku: 'IT-001',
        category: 'Metal',
        unit: 'un',
        initialQuantity: 5,
        minimumStock: 1,
        price: 2,
      ),
    );
    await repository.createItem(
      const InventoryItemDraft(
        name: 'Aluminio',
        sku: 'IT-002',
        category: 'Metal',
        unit: 'un',
        initialQuantity: 20,
        minimumStock: 1,
        price: 1,
      ),
    );
    await repository.createItem(
      const InventoryItemDraft(
        name: 'Bronze',
        sku: 'IT-003',
        category: 'Metal',
        unit: 'un',
        initialQuantity: 8,
        minimumStock: 1,
        price: 10,
      ),
    );

    final byName = await repository.getItems(sort: ItemSortOption.nameAsc);
    final byHighestStock = await repository.getItems(
      sort: ItemSortOption.highestStock,
    );
    final byLowestStock = await repository.getItems(
      sort: ItemSortOption.lowestStock,
    );
    final byHighestValue = await repository.getItems(
      sort: ItemSortOption.highestValue,
    );

    expect(byName.take(3).map((item) => item.name), [
      'Aluminio',
      'Bronze',
      'Zinco',
    ]);
    expect(byHighestStock.first.name, 'Aluminio');
    expect(byLowestStock.first.name, 'Zinco');
    expect(byHighestValue.first.name, 'Bronze');
  });
}
