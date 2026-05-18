import 'dart:math';
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/local_database_service.dart';
import '../../items/domain/items.dart';
import '../domain/service_orders.dart';
import 'service_order_pdf_service.dart';

part 'sqlite_service_orders_repository_queries.dart';
part 'sqlite_service_orders_repository_commands.dart';
part 'sqlite_service_orders_repository_storage.dart';
part 'sqlite_service_orders_repository_mappers.dart';

class SqliteServiceOrdersRepository implements ServiceOrdersRepository {
  SqliteServiceOrdersRepository(this._databaseService, this._pdfService);

  final LocalDatabaseService _databaseService;
  final ServiceOrderPdfService _pdfService;

  @override
  Future<ServiceOrderLookupData> getLookupData({int? customerId}) {
    return _getLookupData(customerId: customerId);
  }

  @override
  Future<List<ServiceOrderSummary>> getOrders({
    ServiceOrderFilter filter = const ServiceOrderFilter(),
  }) {
    return _getOrders(filter: filter);
  }

  @override
  Future<ServiceOrderDetails> createOrder({required String actor}) {
    return _createOrder(actor: actor);
  }

  @override
  Future<ServiceOrderDetails?> getOrderDetails(int orderId) {
    return _getOrderDetails(orderId);
  }

  @override
  Future<ServiceOrderCustomer> createCustomer(ServiceOrderCustomerDraft draft) {
    return _createCustomer(draft);
  }

  @override
  Future<ServiceOrderEquipment> createEquipment(
    ServiceOrderEquipmentDraft draft,
  ) {
    return _createEquipment(draft);
  }

  @override
  Future<ServiceOrderTechnician> createTechnician(
    ServiceOrderTechnicianDraft draft,
  ) {
    return _createTechnician(draft);
  }

  @override
  Future<ServiceOrderDetails> saveOrder(ServiceOrderDraft draft) {
    return _saveOrder(draft);
  }

  @override
  Future<ServiceOrderDetails> changeStatus(
    int orderId,
    ServiceOrderStatus status, {
    required String actor,
    String note = '',
  }) {
    return _changeStatus(orderId, status, actor: actor, note: note);
  }

  @override
  Future<ServiceOrderDetails> closeOrder(int orderId, {required String actor}) {
    return _closeOrder(orderId, actor: actor);
  }

  @override
  Future<Uint8List> exportOrderPdf(int orderId) {
    return _exportOrderPdf(orderId);
  }

  @override
  Future<Uint8List> exportBudgetPdf(int orderId) {
    return _exportBudgetPdf(orderId);
  }

  @override
  Future<void> deleteDraftOrder(int orderId) {
    return _deleteDraftOrder(orderId);
  }
}
