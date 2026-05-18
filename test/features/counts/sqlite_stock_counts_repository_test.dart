import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/core/database/local_database_service.dart';
import 'package:stokeasy/features/counts/data/sqlite_stock_counts_repository.dart';
import 'package:stokeasy/features/counts/data/stock_count_pdf_service.dart';
import 'package:stokeasy/features/counts/domain/stock_counts.dart';
import 'package:stokeasy/features/items/data/sqlite_items_repository.dart';
import 'package:stokeasy/features/items/domain/items.dart';

void main() {
  late LocalDatabaseService databaseService;
  late SqliteItemsRepository itemsRepository;
  late SqliteStockCountsRepository repository;

  setUp(() {
    databaseService = LocalDatabaseService(inMemory: true);
    itemsRepository = SqliteItemsRepository(databaseService);
    repository = SqliteStockCountsRepository(
      databaseService,
      StockCountPdfService(),
    );
  });

  tearDown(() async {
    await databaseService.close();
  });

  test('creates a count with snapshot of active items only', () async {
    await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Cafe',
        sku: 'ALM-001',
        category: 'Alimentos',
        unit: 'un',
        initialQuantity: 10,
        minimumStock: 2,
        price: 12.5,
      ),
    );
    final inactiveItem = await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Acucar',
        sku: 'ALM-002',
        category: 'Alimentos',
        unit: 'un',
        initialQuantity: 0,
        minimumStock: 0,
        price: 6.3,
      ),
    );
    await itemsRepository.deactivateItem(inactiveItem.id!);

    final details = await repository.createCount(
      const CreateStockCountDraft(
        name: '',
        openedBy: 'Ryan',
        notes: 'Contagem geral',
        blindMode: true,
      ),
    );

    expect(details.session.isOpen, isTrue);
    expect(details.session.blindMode, isTrue);
    expect(details.session.totalItems, 1);
    expect(details.lines, hasLength(1));
    expect(details.lines.single.itemSku, 'ALM-001');
  });

  test('updates a counted line and refreshes totals', () async {
    await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Etiqueta',
        sku: 'EXP-010',
        category: 'Expedicao',
        unit: 'un',
        initialQuantity: 5,
        minimumStock: 1,
        price: 2,
      ),
    );

    final details = await repository.createCount(
      const CreateStockCountDraft(
        name: 'Conferencia turno A',
        openedBy: 'Paula',
        notes: '',
        blindMode: false,
      ),
    );

    final updated = await repository.updateLine(
      details.lines.single.id!,
      const UpdateStockCountLineDraft(
        countedQuantity: 7,
        countedBy: 'Paula',
        note: 'Sobrou material',
        selectedForExport: true,
      ),
    );

    expect(updated.session.countedItems, 1);
    expect(updated.session.pendingItems, 0);
    expect(updated.session.divergentItems, 1);
    expect(updated.lines.single.status, StockCountLineStatus.divergent);
    expect(updated.lines.single.difference, 2);
  });

  test('requires all items to be counted before closing', () async {
    await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Papel A4',
        sku: 'ESC-001',
        category: 'Escritorio',
        unit: 'un',
        initialQuantity: 20,
        minimumStock: 5,
        price: 29.9,
      ),
    );
    await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Caneta',
        sku: 'ESC-002',
        category: 'Escritorio',
        unit: 'un',
        initialQuantity: 30,
        minimumStock: 10,
        price: 3.5,
      ),
    );

    final details = await repository.createCount(
      const CreateStockCountDraft(
        name: 'Contagem escritorio',
        openedBy: 'Ana',
        notes: '',
        blindMode: false,
      ),
    );

    await repository.updateLine(
      details.lines.first.id!,
      const UpdateStockCountLineDraft(
        countedQuantity: 20,
        countedBy: 'Ana',
        note: '',
        selectedForExport: true,
      ),
    );

    expect(
      () => repository.closeCount(
        details.session.id!,
        const CloseStockCountDraft(
          closedBy: 'Ana',
          notes: 'Primeira tentativa',
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Conte todos os itens antes de fechar a contagem.',
        ),
      ),
    );

    await repository.updateLine(
      details.lines.last.id!,
      const UpdateStockCountLineDraft(
        countedQuantity: 30,
        countedBy: 'Ana',
        note: 'Ok',
        selectedForExport: true,
      ),
    );

    final closed = await repository.closeCount(
      details.session.id!,
      const CloseStockCountDraft(closedBy: 'Ana', notes: 'Contagem finalizada'),
    );

    expect(closed.session.status, StockCountSessionStatus.closed);
    expect(closed.session.closedBy, 'Ana');
    expect(closed.session.closedAt, isNotNull);
  });
}
