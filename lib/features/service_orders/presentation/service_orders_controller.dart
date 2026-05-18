import 'package:flutter/foundation.dart';

import '../domain/service_orders.dart';

class ServiceOrdersController extends ChangeNotifier {
  ServiceOrdersController({
    required GetServiceOrderLookupUseCase getLookupUseCase,
    required GetServiceOrdersUseCase getOrdersUseCase,
    required CreateServiceOrderUseCase createOrderUseCase,
    required GetServiceOrderDetailsUseCase getOrderDetailsUseCase,
    required CreateServiceOrderCustomerUseCase createCustomerUseCase,
    required CreateServiceOrderEquipmentUseCase createEquipmentUseCase,
    required CreateServiceOrderTechnicianUseCase createTechnicianUseCase,
    required SaveServiceOrderUseCase saveOrderUseCase,
    required ChangeServiceOrderStatusUseCase changeStatusUseCase,
    required CloseServiceOrderUseCase closeOrderUseCase,
    required DeleteDraftServiceOrderUseCase deleteDraftUseCase,
    required ExportServiceOrderPdfUseCase exportOrderPdfUseCase,
    required ExportServiceOrderBudgetPdfUseCase exportBudgetPdfUseCase,
  }) : _getLookupUseCase = getLookupUseCase,
       _getOrdersUseCase = getOrdersUseCase,
       _createOrderUseCase = createOrderUseCase,
       _getOrderDetailsUseCase = getOrderDetailsUseCase,
       _createCustomerUseCase = createCustomerUseCase,
       _createEquipmentUseCase = createEquipmentUseCase,
       _createTechnicianUseCase = createTechnicianUseCase,
       _saveOrderUseCase = saveOrderUseCase,
       _changeStatusUseCase = changeStatusUseCase,
       _closeOrderUseCase = closeOrderUseCase,
       _deleteDraftUseCase = deleteDraftUseCase,
       _exportOrderPdfUseCase = exportOrderPdfUseCase,
       _exportBudgetPdfUseCase = exportBudgetPdfUseCase;

  final GetServiceOrderLookupUseCase _getLookupUseCase;
  final GetServiceOrdersUseCase _getOrdersUseCase;
  final CreateServiceOrderUseCase _createOrderUseCase;
  final GetServiceOrderDetailsUseCase _getOrderDetailsUseCase;
  final CreateServiceOrderCustomerUseCase _createCustomerUseCase;
  final CreateServiceOrderEquipmentUseCase _createEquipmentUseCase;
  final CreateServiceOrderTechnicianUseCase _createTechnicianUseCase;
  final SaveServiceOrderUseCase _saveOrderUseCase;
  final ChangeServiceOrderStatusUseCase _changeStatusUseCase;
  final CloseServiceOrderUseCase _closeOrderUseCase;
  final DeleteDraftServiceOrderUseCase _deleteDraftUseCase;
  final ExportServiceOrderPdfUseCase _exportOrderPdfUseCase;
  final ExportServiceOrderBudgetPdfUseCase _exportBudgetPdfUseCase;

  ServiceOrderLookupData _lookupData = const ServiceOrderLookupData(
    customers: [],
    equipments: [],
    technicians: [],
    stockItems: [],
  );
  List<ServiceOrderSummary> _orders = const [];
  ServiceOrderDetails? _selectedDetails;
  int? _selectedOrderId;

  String _operatorName = 'Operador';
  String _queryFilter = '';
  int? _customerFilter;
  int? _equipmentFilter;
  ServiceOrderStatus? _statusFilter;
  ServiceOrderPriority? _priorityFilter;
  int? _technicianFilter;
  DateTime? _entryDateFilter;
  DateTime? _readyDateFilter;
  DateTime? _exitDateFilter;

  bool _isLoading = false;
  bool _isBusy = false;
  String? _errorMessage;

  ServiceOrderLookupData get lookupData => _lookupData;
  List<ServiceOrderCustomer> get customers => _lookupData.customers;
  List<ServiceOrderEquipment> get equipments => _lookupData.equipments;
  List<ServiceOrderTechnician> get technicians => _lookupData.technicians;
  List<ServiceOrderSummary> get orders => _orders;
  ServiceOrderDetails? get selectedDetails => _selectedDetails;
  int? get selectedOrderId => _selectedOrderId;
  String get operatorName => _operatorName;

  String get queryFilter => _queryFilter;
  int? get customerFilter => _customerFilter;
  int? get equipmentFilter => _equipmentFilter;
  ServiceOrderStatus? get statusFilter => _statusFilter;
  ServiceOrderPriority? get priorityFilter => _priorityFilter;
  int? get technicianFilter => _technicianFilter;
  DateTime? get entryDateFilter => _entryDateFilter;
  DateTime? get readyDateFilter => _readyDateFilter;
  DateTime? get exitDateFilter => _exitDateFilter;

  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Future<void> loadData({int? selectOrderId}) async {
    _isLoading = true;
    _errorMessage = null;
    if (selectOrderId != null) {
      _selectedOrderId = selectOrderId;
    }
    notifyListeners();

    try {
      final lookup = await _getLookupUseCase();
      final orders = await _getOrdersUseCase(filter: _buildFilter());
      final resolvedOrderId = _resolveSelectedOrderId(orders, _selectedOrderId);
      final details = resolvedOrderId == null
          ? null
          : await _getOrderDetailsUseCase(resolvedOrderId);

      _lookupData = lookup;
      _orders = orders;
      _selectedOrderId = resolvedOrderId;
      _selectedDetails = details;
    } catch (error) {
      _errorMessage = _humanizeError(
        error,
        fallback: 'Nao foi possivel carregar a tela de OS.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectOrder(int orderId) async {
    if (_selectedOrderId == orderId && _selectedDetails != null) {
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final details = await _getOrderDetailsUseCase(orderId);
      if (details == null) {
        throw StateError('A OS selecionada nao foi encontrada.');
      }

      _selectedOrderId = orderId;
      _selectedDetails = details;
    } catch (error) {
      _errorMessage = _humanizeError(
        error,
        fallback: 'Nao foi possivel abrir a OS selecionada.',
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> createOrder() async {
    await _runBusyMutation(() async {
      final details = await _createOrderUseCase(actor: _operatorName);
      await _syncAfterMutation(details);
    });
  }

  Future<void> saveOrder(ServiceOrderDraft draft) async {
    await _runBusyMutation(() async {
      final details = await _saveOrderUseCase(draft);
      await _syncAfterMutation(details);
    });
  }

  Future<void> changeStatus(
    ServiceOrderStatus status, {
    String note = '',
  }) async {
    final selectedOrderId = _selectedOrderId;
    if (selectedOrderId == null) {
      throw StateError('Selecione uma OS antes de alterar o status.');
    }

    await _runBusyMutation(() async {
      final details = await _changeStatusUseCase(
        selectedOrderId,
        status,
        actor: _operatorName,
        note: note,
      );
      await _syncAfterMutation(details);
    });
  }

  Future<void> closeSelectedOrder() async {
    final selectedOrderId = _selectedOrderId;
    if (selectedOrderId == null) {
      throw StateError('Selecione uma OS antes de encerrar.');
    }

    await _runBusyMutation(() async {
      final details = await _closeOrderUseCase(
        selectedOrderId,
        actor: _operatorName,
      );
      await _syncAfterMutation(details);
    });
  }

  Future<void> discardSelectedDraftIfAny() async {
    final selected = _selectedDetails;
    if (selected == null || !selected.isDraft) {
      return;
    }

    await _runBusyMutation(() async {
      await _deleteDraftUseCase(selected.id);
      _orders = await _getOrdersUseCase(filter: _buildFilter());
      _selectedOrderId = null;
      _selectedDetails = null;
      _lookupData = await _getLookupUseCase(customerId: _customerFilter);
    });
  }

  Future<void> createCustomer(ServiceOrderCustomerDraft draft) async {
    await _runBusyMutation(() async {
      await _createCustomerUseCase(draft);
      _lookupData = await _getLookupUseCase();
    });
  }

  Future<void> createEquipment(ServiceOrderEquipmentDraft draft) async {
    await _runBusyMutation(() async {
      await _createEquipmentUseCase(draft);
      _lookupData = await _getLookupUseCase();
    });
  }

  Future<void> createTechnician(ServiceOrderTechnicianDraft draft) async {
    await _runBusyMutation(() async {
      await _createTechnicianUseCase(draft);
      _lookupData = await _getLookupUseCase();
    });
  }

  Future<Uint8List> exportCurrentOrderPdf() async {
    final selectedOrderId = _selectedOrderId;
    if (selectedOrderId == null) {
      throw StateError('Selecione uma OS para exportar.');
    }

    return _runBusyAction(
      () => _exportOrderPdfUseCase(selectedOrderId),
      fallback: 'Nao foi possivel exportar o PDF da OS.',
    );
  }

  Future<Uint8List> exportCurrentBudgetPdf() async {
    final selectedOrderId = _selectedOrderId;
    if (selectedOrderId == null) {
      throw StateError('Selecione uma OS para exportar.');
    }

    return _runBusyAction(
      () => _exportBudgetPdfUseCase(selectedOrderId),
      fallback: 'Nao foi possivel exportar o PDF do orcamento.',
    );
  }

  Future<void> applyFilters({
    required String query,
    required int? customerId,
    required int? equipmentId,
    required ServiceOrderStatus? status,
    required ServiceOrderPriority? priority,
    required int? technicianId,
    required DateTime? entryDate,
    required DateTime? readyDate,
    required DateTime? exitDate,
  }) async {
    _queryFilter = query;
    _customerFilter = customerId;
    _equipmentFilter = equipmentId;
    _statusFilter = status;
    _priorityFilter = priority;
    _technicianFilter = technicianId;
    _entryDateFilter = entryDate;
    _readyDateFilter = readyDate;
    _exitDateFilter = exitDate;
    await loadData(selectOrderId: _selectedOrderId);
  }

  Future<void> clearFilters() async {
    _queryFilter = '';
    _customerFilter = null;
    _equipmentFilter = null;
    _statusFilter = null;
    _priorityFilter = null;
    _technicianFilter = null;
    _entryDateFilter = null;
    _readyDateFilter = null;
    _exitDateFilter = null;
    await loadData(selectOrderId: _selectedOrderId);
  }

  void setOperatorName(String value) {
    final normalized = value.trim();
    _operatorName = normalized.isEmpty ? 'Operador' : normalized;
    notifyListeners();
  }

  ServiceOrderFilter _buildFilter() {
    return ServiceOrderFilter(
      query: _queryFilter,
      customerId: _customerFilter,
      equipmentId: _equipmentFilter,
      status: _statusFilter,
      priority: _priorityFilter,
      technicianId: _technicianFilter,
      entryFrom: _entryDateFilter == null
          ? null
          : _startOfDay(_entryDateFilter!),
      entryTo: _entryDateFilter == null ? null : _endOfDay(_entryDateFilter!),
      readyFrom: _readyDateFilter == null
          ? null
          : _startOfDay(_readyDateFilter!),
      readyTo: _readyDateFilter == null ? null : _endOfDay(_readyDateFilter!),
      exitFrom: _exitDateFilter == null ? null : _startOfDay(_exitDateFilter!),
      exitTo: _exitDateFilter == null ? null : _endOfDay(_exitDateFilter!),
    );
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  Future<void> _syncAfterMutation(ServiceOrderDetails details) async {
    _orders = await _getOrdersUseCase(filter: _buildFilter());
    _selectedOrderId = details.id;
    _selectedDetails = details;
    _lookupData = await _getLookupUseCase(customerId: _customerFilter);
  }

  int? _resolveSelectedOrderId(
    List<ServiceOrderSummary> orders,
    int? preferredId,
  ) {
    if (preferredId != null && orders.any((order) => order.id == preferredId)) {
      return preferredId;
    }

    return null;
  }

  Future<void> _runBusyMutation(Future<void> Function() callback) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await callback();
    } catch (error) {
      throw StateError(
        _humanizeError(
          error,
          fallback: 'Nao foi possivel concluir a operacao na OS.',
        ),
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<T> _runBusyAction<T>(
    Future<T> Function() callback, {
    required String fallback,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await callback();
    } catch (error) {
      throw StateError(_humanizeError(error, fallback: fallback));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _humanizeError(Object error, {required String fallback}) {
    if (error is StateError) {
      return error.message;
    }
    return fallback;
  }
}
