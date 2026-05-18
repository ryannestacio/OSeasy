import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/database/local_database_service.dart';
import '../core/services/backup_service.dart';
import '../features/counts/data/sqlite_stock_counts_repository.dart';
import '../features/counts/data/stock_count_pdf_service.dart';
import '../features/counts/domain/stock_counts.dart';
import '../features/dashboard/data/sqlite_dashboard_repository.dart';
import '../features/dashboard/domain/dashboard.dart';
import '../features/items/data/sqlite_items_repository.dart';
import '../features/items/domain/items.dart';
import '../features/movements/data/sqlite_movements_repository.dart';
import '../features/movements/domain/movements.dart';
import '../features/service_orders/data/service_order_pdf_service.dart';
import '../features/service_orders/data/sqlite_service_orders_repository.dart';
import '../features/service_orders/domain/service_orders.dart';
import 'app.dart';

Future<void> bootstrapApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final dependencies = await initializeAppDependencies();
  runApp(StokEasyApp(dependencies: dependencies));
}

Future<AppDependencies> initializeAppDependencies({
  bool useInMemoryDatabase = false,
}) async {
  final databaseService = LocalDatabaseService(inMemory: useInMemoryDatabase);
  await databaseService.database;

  final itemsRepository = SqliteItemsRepository(databaseService);
  final movementsRepository = SqliteMovementsRepository(databaseService);
  final dashboardRepository = SqliteDashboardRepository(databaseService);
  final stockCountPdfService = StockCountPdfService();
  final stockCountsRepository = SqliteStockCountsRepository(
    databaseService,
    stockCountPdfService,
  );
  final serviceOrderPdfService = ServiceOrderPdfService();
  final serviceOrdersRepository = SqliteServiceOrdersRepository(
    databaseService,
    serviceOrderPdfService,
  );
  final backupService = BackupService(databaseService);

  return AppDependencies(
    databaseService: databaseService,
    backupService: backupService,
    getItemsUseCase: GetItemsUseCase(itemsRepository),
    createItemUseCase: CreateItemUseCase(itemsRepository),
    updateItemUseCase: UpdateItemUseCase(itemsRepository),
    deactivateItemUseCase: DeactivateItemUseCase(itemsRepository),
    reactivateItemUseCase: ReactivateItemUseCase(itemsRepository),
    getMovementsUseCase: GetMovementsUseCase(movementsRepository),
    createMovementUseCase: CreateMovementUseCase(movementsRepository),
    getDashboardMetricsUseCase: GetDashboardMetricsUseCase(dashboardRepository),
    getStockCountsUseCase: GetStockCountsUseCase(stockCountsRepository),
    getStockCountDetailsUseCase: GetStockCountDetailsUseCase(
      stockCountsRepository,
    ),
    createStockCountUseCase: CreateStockCountUseCase(stockCountsRepository),
    updateStockCountLineUseCase: UpdateStockCountLineUseCase(
      stockCountsRepository,
    ),
    setStockCountLineSelectionUseCase: SetStockCountLineSelectionUseCase(
      stockCountsRepository,
    ),
    closeStockCountUseCase: CloseStockCountUseCase(stockCountsRepository),
    exportStockCountWorksheetPdfUseCase: ExportStockCountWorksheetPdfUseCase(
      stockCountsRepository,
    ),
    exportStockCountResultPdfUseCase: ExportStockCountResultPdfUseCase(
      stockCountsRepository,
    ),
    getServiceOrderLookupUseCase: GetServiceOrderLookupUseCase(
      serviceOrdersRepository,
    ),
    getServiceOrdersUseCase: GetServiceOrdersUseCase(serviceOrdersRepository),
    createServiceOrderUseCase: CreateServiceOrderUseCase(
      serviceOrdersRepository,
    ),
    getServiceOrderDetailsUseCase: GetServiceOrderDetailsUseCase(
      serviceOrdersRepository,
    ),
    createServiceOrderCustomerUseCase: CreateServiceOrderCustomerUseCase(
      serviceOrdersRepository,
    ),
    createServiceOrderEquipmentUseCase: CreateServiceOrderEquipmentUseCase(
      serviceOrdersRepository,
    ),
    createServiceOrderTechnicianUseCase: CreateServiceOrderTechnicianUseCase(
      serviceOrdersRepository,
    ),
    saveServiceOrderUseCase: SaveServiceOrderUseCase(serviceOrdersRepository),
    changeServiceOrderStatusUseCase: ChangeServiceOrderStatusUseCase(
      serviceOrdersRepository,
    ),
    closeServiceOrderUseCase: CloseServiceOrderUseCase(serviceOrdersRepository),
    deleteDraftServiceOrderUseCase: DeleteDraftServiceOrderUseCase(
      serviceOrdersRepository,
    ),
    exportServiceOrderPdfUseCase: ExportServiceOrderPdfUseCase(
      serviceOrdersRepository,
    ),
    exportServiceOrderBudgetPdfUseCase: ExportServiceOrderBudgetPdfUseCase(
      serviceOrdersRepository,
    ),
  );
}

class AppDependencies {
  const AppDependencies({
    required this.databaseService,
    required this.backupService,
    required this.getItemsUseCase,
    required this.createItemUseCase,
    required this.updateItemUseCase,
    required this.deactivateItemUseCase,
    required this.reactivateItemUseCase,
    required this.getMovementsUseCase,
    required this.createMovementUseCase,
    required this.getDashboardMetricsUseCase,
    required this.getStockCountsUseCase,
    required this.getStockCountDetailsUseCase,
    required this.createStockCountUseCase,
    required this.updateStockCountLineUseCase,
    required this.setStockCountLineSelectionUseCase,
    required this.closeStockCountUseCase,
    required this.exportStockCountWorksheetPdfUseCase,
    required this.exportStockCountResultPdfUseCase,
    required this.getServiceOrderLookupUseCase,
    required this.getServiceOrdersUseCase,
    required this.createServiceOrderUseCase,
    required this.getServiceOrderDetailsUseCase,
    required this.createServiceOrderCustomerUseCase,
    required this.createServiceOrderEquipmentUseCase,
    required this.createServiceOrderTechnicianUseCase,
    required this.saveServiceOrderUseCase,
    required this.changeServiceOrderStatusUseCase,
    required this.closeServiceOrderUseCase,
    required this.deleteDraftServiceOrderUseCase,
    required this.exportServiceOrderPdfUseCase,
    required this.exportServiceOrderBudgetPdfUseCase,
  });

  final LocalDatabaseService databaseService;
  final BackupService backupService;
  final GetItemsUseCase getItemsUseCase;
  final CreateItemUseCase createItemUseCase;
  final UpdateItemUseCase updateItemUseCase;
  final DeactivateItemUseCase deactivateItemUseCase;
  final ReactivateItemUseCase reactivateItemUseCase;
  final GetMovementsUseCase getMovementsUseCase;
  final CreateMovementUseCase createMovementUseCase;
  final GetDashboardMetricsUseCase getDashboardMetricsUseCase;
  final GetStockCountsUseCase getStockCountsUseCase;
  final GetStockCountDetailsUseCase getStockCountDetailsUseCase;
  final CreateStockCountUseCase createStockCountUseCase;
  final UpdateStockCountLineUseCase updateStockCountLineUseCase;
  final SetStockCountLineSelectionUseCase setStockCountLineSelectionUseCase;
  final CloseStockCountUseCase closeStockCountUseCase;
  final ExportStockCountWorksheetPdfUseCase exportStockCountWorksheetPdfUseCase;
  final ExportStockCountResultPdfUseCase exportStockCountResultPdfUseCase;
  final GetServiceOrderLookupUseCase getServiceOrderLookupUseCase;
  final GetServiceOrdersUseCase getServiceOrdersUseCase;
  final CreateServiceOrderUseCase createServiceOrderUseCase;
  final GetServiceOrderDetailsUseCase getServiceOrderDetailsUseCase;
  final CreateServiceOrderCustomerUseCase createServiceOrderCustomerUseCase;
  final CreateServiceOrderEquipmentUseCase createServiceOrderEquipmentUseCase;
  final CreateServiceOrderTechnicianUseCase createServiceOrderTechnicianUseCase;
  final SaveServiceOrderUseCase saveServiceOrderUseCase;
  final ChangeServiceOrderStatusUseCase changeServiceOrderStatusUseCase;
  final CloseServiceOrderUseCase closeServiceOrderUseCase;
  final DeleteDraftServiceOrderUseCase deleteDraftServiceOrderUseCase;
  final ExportServiceOrderPdfUseCase exportServiceOrderPdfUseCase;
  final ExportServiceOrderBudgetPdfUseCase exportServiceOrderBudgetPdfUseCase;

  Future<void> dispose() async {
    await databaseService.close();
  }
}
