import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/core/database/local_database_service.dart';
import 'package:stokeasy/features/items/data/sqlite_items_repository.dart';
import 'package:stokeasy/features/items/domain/items.dart';
import 'package:stokeasy/features/movements/data/sqlite_movements_repository.dart';
import 'package:stokeasy/features/movements/domain/movements.dart';

void main() {
  late LocalDatabaseService databaseService;
  late SqliteItemsRepository itemsRepository;
  late SqliteMovementsRepository movementsRepository;

  setUp(() {
    databaseService = LocalDatabaseService(inMemory: true);
    itemsRepository = SqliteItemsRepository(databaseService);
    movementsRepository = SqliteMovementsRepository(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
  });

  test('blocks movement for inactive item', () async {
    final created = await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Etiqueta',
        sku: 'ETQ-001',
        category: 'Expedicao',
        unit: 'un',
        initialQuantity: 0,
        minimumStock: 0,
        price: 1.2,
      ),
    );

    await itemsRepository.deactivateItem(created.id!);

    expect(
      () => movementsRepository.createMovement(
        InventoryMovementDraft(
          itemId: created.id!,
          type: MovementType.entry,
          quantity: 5,
          note: 'Tentativa',
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'O item selecionado esta inativo. Reative-o antes de registrar movimentacoes.',
        ),
      ),
    );
  });

  test('creates entry movement and updates stock quantity', () async {
    final created = await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Mouse',
        sku: 'MOU-010',
        category: 'Perifericos',
        unit: 'un',
        initialQuantity: 2,
        minimumStock: 1,
        price: 50,
      ),
    );

    final movement = await movementsRepository.createMovement(
      InventoryMovementDraft(
        itemId: created.id!,
        type: MovementType.entry,
        quantity: 3,
        note: 'Reposicao',
      ),
    );

    expect(movement.itemId, created.id);
    expect(movement.type, MovementType.entry);
    expect(movement.quantity, 3);
    expect(movement.note, 'Reposicao');

    final rows = await (await databaseService.database).query(
      'items',
      columns: ['quantity'],
      where: 'id = ?',
      whereArgs: [created.id],
      limit: 1,
    );
    expect(rows, isNotEmpty);
    expect((rows.first['quantity'] as num).toDouble(), 5);
  });

  test('blocks exit when stock is insufficient', () async {
    final created = await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Teclado',
        sku: 'TEC-010',
        category: 'Perifericos',
        unit: 'un',
        initialQuantity: 1,
        minimumStock: 0,
        price: 80,
      ),
    );

    expect(
      () => movementsRepository.createMovement(
        InventoryMovementDraft(
          itemId: created.id!,
          type: MovementType.exit,
          quantity: 2,
          note: 'Venda',
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Estoque insuficiente para concluir a saida.',
        ),
      ),
    );
  });

  test('creates adjustment movement with negative quantity', () async {
    final created = await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Cabo HDMI',
        sku: 'CAB-010',
        category: 'Cabos',
        unit: 'un',
        initialQuantity: 10,
        minimumStock: 1,
        price: 12,
      ),
    );

    final movement = await movementsRepository.createMovement(
      InventoryMovementDraft(
        itemId: created.id!,
        type: MovementType.adjustment,
        quantity: -3,
        note: 'Quebra no inventario',
      ),
    );

    expect(movement.type, MovementType.adjustment);
    expect(movement.quantity, -3);

    final rows = await (await databaseService.database).query(
      'items',
      columns: ['quantity'],
      where: 'id = ?',
      whereArgs: [created.id],
      limit: 1,
    );
    expect(rows, isNotEmpty);
    expect((rows.first['quantity'] as num).toDouble(), 7);
  });

  test('maps unknown movement type as adjustment and applies limit', () async {
    final db = await databaseService.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final older = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 10))
        .toIso8601String();

    final itemId = await db.insert('items', {
      'name': 'Adaptador',
      'sku': 'ADP-001',
      'category': 'Acessorios',
      'unit': 'un',
      'quantity': 5,
      'minimum_stock': 1,
      'price': 20,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('movements', {
      'item_id': itemId,
      'type': 'unknown_type',
      'quantity': 1,
      'note': 'Tipo legado',
      'created_at': older,
    });
    await db.insert('movements', {
      'item_id': itemId,
      'type': 'entry',
      'quantity': 2,
      'note': 'Entrada nova',
      'created_at': now,
    });

    final limited = await movementsRepository.getMovements(limit: 1);
    expect(limited, hasLength(1));
    expect(limited.first.note, 'Entrada nova');

    final all = await movementsRepository.getMovements(limit: 10);
    final legacy = all.firstWhere((movement) => movement.note == 'Tipo legado');
    expect(legacy.type, MovementType.adjustment);
  });
}
