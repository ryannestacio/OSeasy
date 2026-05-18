import 'dart:typed_data';

import 'package:stokeasy/features/items/domain/items.dart';
import 'package:stokeasy/features/service_orders/domain/service_orders.dart';
import 'package:stokeasy/features/service_orders/presentation/service_orders_controller.dart';

ServiceOrdersController buildServiceOrdersController(
  FakeServiceOrdersRepository repository,
) {
  return ServiceOrdersController(
    getLookupUseCase: GetServiceOrderLookupUseCase(repository),
    getOrdersUseCase: GetServiceOrdersUseCase(repository),
    createOrderUseCase: CreateServiceOrderUseCase(repository),
    getOrderDetailsUseCase: GetServiceOrderDetailsUseCase(repository),
    createCustomerUseCase: CreateServiceOrderCustomerUseCase(repository),
    createEquipmentUseCase: CreateServiceOrderEquipmentUseCase(repository),
    createTechnicianUseCase: CreateServiceOrderTechnicianUseCase(repository),
    saveOrderUseCase: SaveServiceOrderUseCase(repository),
    changeStatusUseCase: ChangeServiceOrderStatusUseCase(repository),
    closeOrderUseCase: CloseServiceOrderUseCase(repository),
    deleteDraftUseCase: DeleteDraftServiceOrderUseCase(repository),
    exportOrderPdfUseCase: ExportServiceOrderPdfUseCase(repository),
    exportBudgetPdfUseCase: ExportServiceOrderBudgetPdfUseCase(repository),
  );
}

class FakeServiceOrdersRepository implements ServiceOrdersRepository {
  FakeServiceOrdersRepository({
    List<ServiceOrderDetails>? initialOrders,
    ServiceOrderLookupData? lookupData,
  }) {
    this.lookupData = lookupData ?? _buildDefaultLookupData();
    final seed =
        initialOrders ??
        [
          buildServiceOrderDetails(
            id: 1,
            orderNumber: 1,
            status: ServiceOrderStatus.open,
          ),
        ];
    for (final order in seed) {
      _detailsById[order.id] = order;
    }
  }

  static final DateTime _baseNow = DateTime(2026, 3, 25, 10, 0);

  late final ServiceOrderLookupData lookupData;
  final Map<int, ServiceOrderDetails> _detailsById = {};

  ServiceOrderFilter? lastFilter;
  int saveCalls = 0;
  int closeCalls = 0;
  int createCalls = 0;
  final List<int> deletedDraftOrderIds = [];

  bool throwStateOnSave = false;
  bool throwGenericOnSave = false;
  bool throwStateOnClose = false;

  static ServiceOrderLookupData _buildDefaultLookupData() {
    return ServiceOrderLookupData(
      customers: const [
        ServiceOrderCustomer(
          id: 1,
          name: 'Cliente Base',
          document: '000.000.000-00',
          phone: '(27) 99999-0000',
          email: 'cliente@teste.com',
          address: 'Rua Teste, 100',
        ),
      ],
      equipments: const [],
      technicians: const [],
      stockItems: [
        InventoryItem(
          id: 1,
          name: 'Peca X',
          sku: 'P-001',
          category: 'Pecas',
          unit: 'un',
          quantity: 15,
          minimumStock: 2,
          price: 10,
          isActive: true,
          createdAt: _baseNow,
          updatedAt: _baseNow,
        ),
      ],
    );
  }

  @override
  Future<ServiceOrderLookupData> getLookupData({int? customerId}) async {
    return lookupData;
  }

  @override
  Future<List<ServiceOrderSummary>> getOrders({
    ServiceOrderFilter filter = const ServiceOrderFilter(),
  }) async {
    lastFilter = filter;
    final all =
        _detailsById.values.where((details) => !details.isDraft).toList()
          ..sort((a, b) => b.orderNumber.compareTo(a.orderNumber));
    return all
        .map(
          (details) => ServiceOrderSummary(
            id: details.id,
            orderNumber: details.orderNumber,
            customerName: details.customerName,
            equipmentModel: details.equipmentModel,
            status: details.status,
            priority: details.priority,
            entryAt: details.entryAt,
            readyAt: details.readyAt,
            exitAt: details.exitAt,
            responsibleTechnician: details.updatedBy,
            totalAmount: details.totalAmount,
          ),
        )
        .toList();
  }

  @override
  Future<ServiceOrderDetails> createOrder({required String actor}) async {
    createCalls++;
    final nextId =
        (_detailsById.keys.isEmpty
            ? 0
            : _detailsById.keys.reduce((a, b) => a > b ? a : b)) +
        1;
    final nextNumber = _detailsById.values.isEmpty
        ? 1
        : _detailsById.values
                  .map((details) => details.orderNumber)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final details = buildServiceOrderDetails(
      id: nextId,
      orderNumber: nextNumber,
      status: ServiceOrderStatus.open,
      isDraft: true,
      customerId: null,
      customerName: '',
      equipmentModel: '',
    );
    _detailsById[nextId] = details;
    return details;
  }

  @override
  Future<ServiceOrderDetails?> getOrderDetails(int orderId) async {
    return _detailsById[orderId];
  }

  @override
  Future<ServiceOrderCustomer> createCustomer(
    ServiceOrderCustomerDraft draft,
  ) async {
    return ServiceOrderCustomer(
      id: 99,
      name: draft.name,
      document: draft.document,
      phone: draft.phone,
      email: draft.email,
      address: draft.address,
    );
  }

  @override
  Future<ServiceOrderEquipment> createEquipment(
    ServiceOrderEquipmentDraft draft,
  ) async {
    return ServiceOrderEquipment(
      id: 99,
      customerId: draft.customerId,
      model: draft.model,
      brand: draft.brand,
      microCpu: draft.microCpu,
      ramHd: draft.ramHd,
      serialNumber: draft.serialNumber,
      assetTag: draft.assetTag,
      accessories: draft.accessories,
      notes: draft.notes,
      isActive: true,
    );
  }

  @override
  Future<ServiceOrderTechnician> createTechnician(
    ServiceOrderTechnicianDraft draft,
  ) async {
    return ServiceOrderTechnician(id: 99, name: draft.name, isActive: true);
  }

  @override
  Future<ServiceOrderDetails> saveOrder(ServiceOrderDraft draft) async {
    saveCalls++;
    if (throwStateOnSave) {
      throw StateError('Falha ao salvar (teste).');
    }
    if (throwGenericOnSave) {
      throw Exception('Falha generica');
    }
    final current = _detailsById[draft.id];
    if (current == null) {
      throw StateError('A OS selecionada nao foi encontrada.');
    }
    final saved = buildServiceOrderDetails(
      id: current.id,
      orderNumber: current.orderNumber,
      status: draft.status,
      isDraft: false,
      customerId: draft.customerId,
      customerName:
          lookupData.customers
              .firstWhere(
                (customer) => customer.id == draft.customerId,
                orElse: () => const ServiceOrderCustomer(
                  id: null,
                  name: '',
                  document: '',
                  phone: '',
                  email: '',
                  address: '',
                ),
              )
              .name
              .trim()
              .isEmpty
          ? current.customerName
          : lookupData.customers
                .firstWhere(
                  (customer) => customer.id == draft.customerId,
                  orElse: () => const ServiceOrderCustomer(
                    id: null,
                    name: '',
                    document: '',
                    phone: '',
                    email: '',
                    address: '',
                  ),
                )
                .name,
      equipmentModel: draft.equipmentModel.trim(),
      serviceLines: [
        for (var index = 0; index < draft.serviceLines.length; index++)
          ServiceOrderServiceLine(
            id: draft.serviceLines[index].id ?? (index + 1),
            orderId: current.id,
            description: draft.serviceLines[index].description,
            serviceType: draft.serviceLines[index].serviceType,
            startTime: draft.serviceLines[index].startTime,
            endTime: draft.serviceLines[index].endTime,
            quantity: draft.serviceLines[index].quantity,
            unitPrice: draft.serviceLines[index].unitPrice,
            totalPrice: draft.serviceLines[index].totalPrice,
            technicianId: draft.serviceLines[index].technicianId,
            technicianName: draft.serviceLines[index].technicianName,
            sortOrder: index,
          ),
      ],
      partLines: [
        for (var index = 0; index < draft.partLines.length; index++)
          ServiceOrderPartLine(
            id: draft.partLines[index].id ?? (index + 1),
            orderId: current.id,
            itemId: draft.partLines[index].itemId,
            partName: draft.partLines[index].partName,
            origin: draft.partLines[index].origin,
            quantity: draft.partLines[index].quantity,
            unitPrice: draft.partLines[index].unitPrice,
            totalPrice: draft.partLines[index].totalPrice,
            technicianId: draft.partLines[index].technicianId,
            technicianName: draft.partLines[index].technicianName,
            stockMovementApplied: false,
            sortOrder: index,
          ),
      ],
      attachments: [
        for (final attachment in draft.attachments)
          ServiceOrderAttachment(
            id: attachment.id,
            orderId: current.id,
            filePath: attachment.filePath,
            fileName: attachment.fileName,
            createdAt: attachment.createdAt,
            createdBy: attachment.createdBy,
          ),
      ],
      history: current.history,
    );
    _detailsById[draft.id] = saved;
    return saved;
  }

  @override
  Future<ServiceOrderDetails> changeStatus(
    int orderId,
    ServiceOrderStatus status, {
    required String actor,
    String note = '',
  }) async {
    final current = _detailsById[orderId];
    if (current == null) {
      throw StateError('A OS selecionada nao foi encontrada.');
    }
    final updated = buildServiceOrderDetails(
      id: current.id,
      orderNumber: current.orderNumber,
      status: status,
      isDraft: current.isDraft,
      customerId: current.customerId,
      customerName: current.customerName,
      equipmentModel: current.equipmentModel,
      attachments: current.attachments,
      serviceLines: current.serviceLines,
      partLines: current.partLines,
      history: current.history,
    );
    _detailsById[orderId] = updated;
    return updated;
  }

  @override
  Future<ServiceOrderDetails> closeOrder(
    int orderId, {
    required String actor,
  }) async {
    closeCalls++;
    if (throwStateOnClose) {
      throw StateError('Falha ao encerrar (teste).');
    }
    final current = _detailsById[orderId];
    if (current == null) {
      throw StateError('A OS selecionada nao foi encontrada.');
    }
    final updated = buildServiceOrderDetails(
      id: current.id,
      orderNumber: current.orderNumber,
      status: ServiceOrderStatus.delivered,
      isDraft: current.isDraft,
      customerId: current.customerId,
      customerName: current.customerName,
      equipmentModel: current.equipmentModel,
      attachments: current.attachments,
      serviceLines: current.serviceLines,
      partLines: current.partLines,
      history: current.history,
    );
    _detailsById[orderId] = updated;
    return updated;
  }

  @override
  Future<void> deleteDraftOrder(int orderId) async {
    deletedDraftOrderIds.add(orderId);
    final details = _detailsById[orderId];
    if (details?.isDraft == true) {
      _detailsById.remove(orderId);
    }
  }

  @override
  Future<Uint8List> exportOrderPdf(int orderId) async {
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<Uint8List> exportBudgetPdf(int orderId) async {
    return Uint8List.fromList([4, 5, 6]);
  }
}

ServiceOrderDetails buildServiceOrderDetails({
  required int id,
  required int orderNumber,
  required ServiceOrderStatus status,
  bool isDraft = false,
  int? customerId = 1,
  String customerName = 'Cliente Base',
  String equipmentModel = 'Notebook Teste',
  List<ServiceOrderServiceLine>? serviceLines,
  List<ServiceOrderPartLine>? partLines,
  List<ServiceOrderAttachment>? attachments,
  List<ServiceOrderHistoryEntry>? history,
}) {
  final now = DateTime(2026, 3, 25, 10, 0);
  return ServiceOrderDetails(
    id: id,
    orderNumber: orderNumber,
    isDraft: isDraft,
    customerId: customerId,
    equipmentId: null,
    status: status,
    priority: ServiceOrderPriority.normal,
    entryAt: now,
    readyAt:
        status == ServiceOrderStatus.ready ||
            status == ServiceOrderStatus.delivered
        ? now.add(const Duration(hours: 1))
        : null,
    exitAt: status == ServiceOrderStatus.delivered
        ? now.add(const Duration(hours: 2))
        : null,
    warrantyUntil: now.add(const Duration(days: 90)),
    responsibleTechnicianId: null,
    situation: 'Aguardando',
    customerName: customerName,
    customerDocument: '000.000.000-00',
    customerPhone: '(27) 99999-0000',
    customerEmail: 'cliente@teste.com',
    customerAddress: 'Rua Teste, 100',
    equipmentModel: equipmentModel,
    equipmentBrand: 'Marca X',
    equipmentMicroCpu: 'CPU X',
    equipmentRamHd: '16GB/512GB',
    equipmentSerialNumber: 'SN-001',
    equipmentAssetTag: 'PAT-001',
    equipmentAccessories: 'Carregador',
    defectComplaint: 'Nao liga',
    equipmentObservations: 'Obs',
    technicalReport: 'Laudo',
    internalNotes: 'Interno',
    advanceAmount: 0,
    laborAmount: 100,
    partsAmount: 20,
    travelAmount: 0,
    thirdPartyAmount: 0,
    otherAmount: 0,
    totalAmount: 120,
    createdAt: now,
    updatedAt: now,
    createdBy: 'Operador',
    updatedBy: 'Operador',
    serviceLines:
        serviceLines ??
        const [
          ServiceOrderServiceLine(
            id: 1,
            orderId: 1,
            description: 'Servico teste',
            serviceType: 'Avulso',
            startTime: null,
            endTime: null,
            quantity: 1,
            unitPrice: 100,
            totalPrice: 100,
            technicianId: null,
            technicianName: 'Operador',
            sortOrder: 0,
          ),
        ],
    partLines:
        partLines ??
        const [
          ServiceOrderPartLine(
            id: 1,
            orderId: 1,
            itemId: 1,
            partName: 'Peca teste',
            origin: ServiceOrderPartOrigin.stock,
            quantity: 1,
            unitPrice: 20,
            totalPrice: 20,
            technicianId: null,
            technicianName: 'Operador',
            stockMovementApplied: false,
            sortOrder: 0,
          ),
        ],
    attachments: attachments ?? const [],
    history: history ?? const [],
  );
}
