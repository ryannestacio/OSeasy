import '../../movements/domain/movements.dart';

class DashboardLowStockItem {
  const DashboardLowStockItem({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.minimumStock,
  });

  final String name;
  final String sku;
  final double quantity;
  final double minimumStock;

  double get shortage => minimumStock - quantity;
}

class DashboardRecentMovement {
  const DashboardRecentMovement({
    required this.itemName,
    required this.itemSku,
    required this.type,
    required this.quantity,
    required this.createdAt,
  });

  final String itemName;
  final String itemSku;
  final MovementType type;
  final double quantity;
  final DateTime createdAt;

  double get signedQuantity => switch (type) {
    MovementType.entry => quantity,
    MovementType.exit => -quantity,
    MovementType.adjustment => quantity,
  };
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalItems,
    required this.lowStockItems,
    required this.inventoryValue,
    required this.stockUnits,
    required this.entryVolumeThisMonth,
    required this.exitVolumeThisMonth,
    required this.lowStockList,
    required this.recentMovements,
  });

  final int totalItems;
  final int lowStockItems;
  final double inventoryValue;
  final double stockUnits;
  final double entryVolumeThisMonth;
  final double exitVolumeThisMonth;
  final List<DashboardLowStockItem> lowStockList;
  final List<DashboardRecentMovement> recentMovements;
}

abstract class DashboardRepository {
  Future<DashboardMetrics> getMetrics();
}

class GetDashboardMetricsUseCase {
  const GetDashboardMetricsUseCase(this._repository);

  final DashboardRepository _repository;

  Future<DashboardMetrics> call() {
    return _repository.getMetrics();
  }
}
