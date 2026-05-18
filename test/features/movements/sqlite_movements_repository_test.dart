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
}
