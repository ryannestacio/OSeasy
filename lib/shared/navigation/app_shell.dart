import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/bootstrap.dart';
import '../../app/navigation/app_sections.dart';
import '../../app/theme/app_palette.dart';
import '../../features/backup/presentation/backup_controller.dart';
import '../../features/backup/presentation/backup_page.dart';
import '../../features/counts/presentation/counts_controller.dart';
import '../../features/counts/presentation/counts_page.dart';
import '../../features/dashboard/presentation/dashboard_controller.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/items/presentation/items_controller.dart';
import '../../features/items/presentation/items_page.dart';
import '../../features/movements/presentation/movements_controller.dart';
import '../../features/movements/presentation/movements_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/service_orders/presentation/service_orders_controller.dart';
import '../../features/service_orders/presentation/service_orders_page.dart';
import 'app_sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final DashboardController _dashboardController;
  late final ItemsController _itemsController;
  late final MovementsController _movementsController;
  late final CountsController _countsController;
  late final BackupController _backupController;
  late final ServiceOrdersController _serviceOrdersController;

  AppSection _selectedSection = AppSection.dashboard;

  @override
  void initState() {
    super.initState();

    _dashboardController = DashboardController(
      getDashboardMetricsUseCase:
          widget.dependencies.getDashboardMetricsUseCase,
    );
    _itemsController = ItemsController(
      getItemsUseCase: widget.dependencies.getItemsUseCase,
      createItemUseCase: widget.dependencies.createItemUseCase,
      updateItemUseCase: widget.dependencies.updateItemUseCase,
      deactivateItemUseCase: widget.dependencies.deactivateItemUseCase,
      reactivateItemUseCase: widget.dependencies.reactivateItemUseCase,
    );
    _movementsController = MovementsController(
      getMovementsUseCase: widget.dependencies.getMovementsUseCase,
      createMovementUseCase: widget.dependencies.createMovementUseCase,
      getItemsUseCase: widget.dependencies.getItemsUseCase,
    );
    _countsController = CountsController(
      getStockCountsUseCase: widget.dependencies.getStockCountsUseCase,
      getStockCountDetailsUseCase:
          widget.dependencies.getStockCountDetailsUseCase,
      createStockCountUseCase: widget.dependencies.createStockCountUseCase,
      updateStockCountLineUseCase:
          widget.dependencies.updateStockCountLineUseCase,
      setStockCountLineSelectionUseCase:
          widget.dependencies.setStockCountLineSelectionUseCase,
      closeStockCountUseCase: widget.dependencies.closeStockCountUseCase,
      exportStockCountWorksheetPdfUseCase:
          widget.dependencies.exportStockCountWorksheetPdfUseCase,
      exportStockCountResultPdfUseCase:
          widget.dependencies.exportStockCountResultPdfUseCase,
    );
    _backupController = BackupController(
      backupService: widget.dependencies.backupService,
    );
    _serviceOrdersController = ServiceOrdersController(
      getLookupUseCase: widget.dependencies.getServiceOrderLookupUseCase,
      getOrdersUseCase: widget.dependencies.getServiceOrdersUseCase,
      createOrderUseCase: widget.dependencies.createServiceOrderUseCase,
      getOrderDetailsUseCase: widget.dependencies.getServiceOrderDetailsUseCase,
      createCustomerUseCase:
          widget.dependencies.createServiceOrderCustomerUseCase,
      createEquipmentUseCase:
          widget.dependencies.createServiceOrderEquipmentUseCase,
      createTechnicianUseCase:
          widget.dependencies.createServiceOrderTechnicianUseCase,
      saveOrderUseCase: widget.dependencies.saveServiceOrderUseCase,
      changeStatusUseCase: widget.dependencies.changeServiceOrderStatusUseCase,
      closeOrderUseCase: widget.dependencies.closeServiceOrderUseCase,
      deleteDraftUseCase: widget.dependencies.deleteDraftServiceOrderUseCase,
      exportOrderPdfUseCase: widget.dependencies.exportServiceOrderPdfUseCase,
      exportBudgetPdfUseCase:
          widget.dependencies.exportServiceOrderBudgetPdfUseCase,
    );

    unawaited(_loadInitialData());
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _itemsController.dispose();
    _movementsController.dispose();
    _countsController.dispose();
    _backupController.dispose();
    _serviceOrdersController.dispose();
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _dashboardController.loadMetrics(),
      _itemsController.loadItems(),
      _movementsController.loadData(),
      _serviceOrdersController.loadData(),
      _countsController.loadData(),
      _backupController.load(),
    ]);
  }

  Future<void> _refreshInventoryData() async {
    await Future.wait([
      _dashboardController.loadMetrics(),
      _itemsController.loadItems(query: _itemsController.searchQuery),
      _movementsController.loadData(),
      _serviceOrdersController.loadData(
        selectOrderId: _serviceOrdersController.selectedOrderId,
      ),
      _countsController.loadData(
        selectCountId: _countsController.selectedCountId,
      ),
    ]);
  }

  void _selectSection(AppSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;

        return Scaffold(
          drawer: compact
              ? Drawer(
                  width: 320,
                  child: AppSidebar(
                    compact: true,
                    selectedSection: _selectedSection,
                    onSectionSelected: (section) {
                      Navigator.of(context).pop();
                      _selectSection(section);
                    },
                  ),
                )
              : null,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppPalette.white, AppPalette.canvasStrong],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (!compact)
                    AppSidebar(
                      selectedSection: _selectedSection,
                      onSectionSelected: _selectSection,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        if (compact)
                          _ShellTopBar(selectedSection: _selectedSection),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: KeyedSubtree(
                              key: ValueKey(_selectedSection),
                              child: _buildCurrentPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentPage() {
    return switch (_selectedSection) {
      AppSection.dashboard => DashboardPage(
        controller: _dashboardController,
        onNavigate: _selectSection,
      ),
      AppSection.items => ItemsPage(
        controller: _itemsController,
        onInventoryChanged: _refreshInventoryData,
      ),
      AppSection.movements => MovementsPage(
        controller: _movementsController,
        onInventoryChanged: _refreshInventoryData,
      ),
      AppSection.serviceOrders => ServiceOrdersPage(
        controller: _serviceOrdersController,
      ),
      AppSection.counts => CountsPage(controller: _countsController),
      AppSection.reports => ReportsPage(
        dashboardController: _dashboardController,
        itemsController: _itemsController,
        movementsController: _movementsController,
      ),
      AppSection.backup => BackupPage(
        controller: _backupController,
        onInventoryRestored: _refreshInventoryData,
      ),
    };
  }
}

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({required this.selectedSection});

  final AppSection selectedSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton.filledTonal(
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu_rounded),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedSection.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  selectedSection.headline,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
