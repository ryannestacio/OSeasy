import 'dart:typed_data';

import '../../items/domain/items.dart';

enum ServiceOrderStatus {
  open,
  waitingBudget,
  approved,
  inProgress,
  ready,
  delivered,
  canceled,
}

enum ServiceOrderPriority { low, normal, high, urgent }

enum ServiceOrderPartOrigin { stock, loose }

extension ServiceOrderStatusView on ServiceOrderStatus {
  String get storageValue => switch (this) {
    ServiceOrderStatus.open => 'open',
    ServiceOrderStatus.waitingBudget => 'waiting_budget',
    ServiceOrderStatus.approved => 'approved',
    ServiceOrderStatus.inProgress => 'in_progress',
    ServiceOrderStatus.ready => 'ready',
    ServiceOrderStatus.delivered => 'delivered',
    ServiceOrderStatus.canceled => 'canceled',
  };

  String get label => switch (this) {
    ServiceOrderStatus.open => 'Aberta',
    ServiceOrderStatus.waitingBudget => 'Aguardando orcamento',
    ServiceOrderStatus.approved => 'Aprovada',
    ServiceOrderStatus.inProgress => 'Em andamento',
    ServiceOrderStatus.ready => 'Pronta',
    ServiceOrderStatus.delivered => 'Entregue',
    ServiceOrderStatus.canceled => 'Cancelada',
  };

  bool canTransitionTo(ServiceOrderStatus target) {
    if (target == this) {
      return true;
    }

    return switch (this) {
      ServiceOrderStatus.open => {
        ServiceOrderStatus.waitingBudget,
        ServiceOrderStatus.approved,
        ServiceOrderStatus.inProgress,
        ServiceOrderStatus.canceled,
      }.contains(target),
      ServiceOrderStatus.waitingBudget => {
        ServiceOrderStatus.approved,
        ServiceOrderStatus.canceled,
      }.contains(target),
      ServiceOrderStatus.approved => {
        ServiceOrderStatus.inProgress,
        ServiceOrderStatus.canceled,
      }.contains(target),
      ServiceOrderStatus.inProgress => {
        ServiceOrderStatus.ready,
        ServiceOrderStatus.canceled,
      }.contains(target),
      ServiceOrderStatus.ready => {
        ServiceOrderStatus.inProgress,
        ServiceOrderStatus.delivered,
        ServiceOrderStatus.canceled,
      }.contains(target),
      ServiceOrderStatus.delivered => {
        ServiceOrderStatus.inProgress,
      }.contains(target),
      ServiceOrderStatus.canceled => {ServiceOrderStatus.open}.contains(target),
    };
  }

  static ServiceOrderStatus fromStorageValue(String value) => switch (value) {
    'waiting_budget' => ServiceOrderStatus.waitingBudget,
    'approved' => ServiceOrderStatus.approved,
    'in_progress' => ServiceOrderStatus.inProgress,
    'ready' => ServiceOrderStatus.ready,
    'delivered' => ServiceOrderStatus.delivered,
    'canceled' => ServiceOrderStatus.canceled,
    _ => ServiceOrderStatus.open,
  };
}

extension ServiceOrderPriorityView on ServiceOrderPriority {
  String get storageValue => switch (this) {
    ServiceOrderPriority.low => 'low',
    ServiceOrderPriority.normal => 'normal',
    ServiceOrderPriority.high => 'high',
    ServiceOrderPriority.urgent => 'urgent',
  };

  String get label => switch (this) {
    ServiceOrderPriority.low => 'Baixa',
    ServiceOrderPriority.normal => 'Normal',
    ServiceOrderPriority.high => 'Alta',
    ServiceOrderPriority.urgent => 'Urgente',
  };

  static ServiceOrderPriority fromStorageValue(String value) => switch (value) {
    'low' => ServiceOrderPriority.low,
    'high' => ServiceOrderPriority.high,
    'urgent' => ServiceOrderPriority.urgent,
    _ => ServiceOrderPriority.normal,
  };
}

extension ServiceOrderPartOriginView on ServiceOrderPartOrigin {
  String get storageValue => switch (this) {
    ServiceOrderPartOrigin.stock => 'stock',
    ServiceOrderPartOrigin.loose => 'loose',
  };

  String get label => switch (this) {
    ServiceOrderPartOrigin.stock => 'Estoque',
    ServiceOrderPartOrigin.loose => 'Avulsa',
  };

  static ServiceOrderPartOrigin fromStorageValue(String value) =>
      switch (value) {
        'stock' => ServiceOrderPartOrigin.stock,
        _ => ServiceOrderPartOrigin.loose,
      };
}

class ServiceOrderCustomer {
  const ServiceOrderCustomer({
    this.id,
    required this.name,
    required this.document,
    required this.phone,
    required this.email,
    required this.address,
    this.tradeName = '',
    this.contactName = '',
    this.birthday = '',
    this.stateRegistration = '',
    this.personType = '',
    this.zipCode = '',
    this.street = '',
    this.streetNumber = '',
    this.complement = '',
    this.neighborhood = '',
    this.city = '',
    this.stateCode = '',
    this.country = '',
    this.businessPhone = '',
    this.mobilePhone = '',
    this.fiscalEmail = '',
    this.notes = '',
    this.customerGroup = '',
    this.gender = '',
  });

  final int? id;
  final String name;
  final String document;
  final String phone;
  final String email;
  final String address;
  final String tradeName;
  final String contactName;
  final String birthday;
  final String stateRegistration;
  final String personType;
  final String zipCode;
  final String street;
  final String streetNumber;
  final String complement;
  final String neighborhood;
  final String city;
  final String stateCode;
  final String country;
  final String businessPhone;
  final String mobilePhone;
  final String fiscalEmail;
  final String notes;
  final String customerGroup;
  final String gender;
}

class ServiceOrderEquipment {
  const ServiceOrderEquipment({
    this.id,
    required this.customerId,
    required this.model,
    required this.brand,
    required this.microCpu,
    required this.ramHd,
    required this.serialNumber,
    required this.assetTag,
    required this.accessories,
    required this.notes,
    required this.isActive,
  });

  final int? id;
  final int customerId;
  final String model;
  final String brand;
  final String microCpu;
  final String ramHd;
  final String serialNumber;
  final String assetTag;
  final String accessories;
  final String notes;
  final bool isActive;
}

class ServiceOrderTechnician {
  const ServiceOrderTechnician({
    this.id,
    required this.name,
    required this.isActive,
  });

  final int? id;
  final String name;
  final bool isActive;
}

class ServiceOrderLookupData {
  const ServiceOrderLookupData({
    required this.customers,
    required this.equipments,
    required this.technicians,
    required this.stockItems,
  });

  final List<ServiceOrderCustomer> customers;
  final List<ServiceOrderEquipment> equipments;
  final List<ServiceOrderTechnician> technicians;
  final List<InventoryItem> stockItems;
}

class ServiceOrderSummary {
  const ServiceOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.equipmentModel,
    required this.status,
    required this.priority,
    required this.entryAt,
    required this.readyAt,
    required this.exitAt,
    required this.responsibleTechnician,
    required this.totalAmount,
  });

  final int id;
  final int orderNumber;
  final String customerName;
  final String equipmentModel;
  final ServiceOrderStatus status;
  final ServiceOrderPriority priority;
  final DateTime entryAt;
  final DateTime? readyAt;
  final DateTime? exitAt;
  final String responsibleTechnician;
  final double totalAmount;
}

class ServiceOrderFilter {
  const ServiceOrderFilter({
    this.query = '',
    this.customerId,
    this.equipmentId,
    this.status,
    this.priority,
    this.technicianId,
    this.entryFrom,
    this.entryTo,
    this.readyFrom,
    this.readyTo,
    this.exitFrom,
    this.exitTo,
  });

  final String query;
  final int? customerId;
  final int? equipmentId;
  final ServiceOrderStatus? status;
  final ServiceOrderPriority? priority;
  final int? technicianId;
  final DateTime? entryFrom;
  final DateTime? entryTo;
  final DateTime? readyFrom;
  final DateTime? readyTo;
  final DateTime? exitFrom;
  final DateTime? exitTo;
}

class ServiceOrderServiceLine {
  const ServiceOrderServiceLine({
    this.id,
    required this.orderId,
    required this.description,
    required this.serviceType,
    required this.startTime,
    required this.endTime,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.technicianId,
    required this.technicianName,
    required this.sortOrder,
  });

  final int? id;
  final int orderId;
  final String description;
  final String serviceType;
  final DateTime? startTime;
  final DateTime? endTime;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final int? technicianId;
  final String technicianName;
  final int sortOrder;

  Duration get duration {
    if (startTime == null || endTime == null) {
      return Duration.zero;
    }

    final diff = endTime!.difference(startTime!);
    if (diff.isNegative) {
      return Duration.zero;
    }
    return diff;
  }
}

class ServiceOrderPartLine {
  const ServiceOrderPartLine({
    this.id,
    required this.orderId,
    required this.itemId,
    required this.partName,
    required this.origin,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.technicianId,
    required this.technicianName,
    required this.stockMovementApplied,
    required this.sortOrder,
  });

  final int? id;
  final int orderId;
  final int? itemId;
  final String partName;
  final ServiceOrderPartOrigin origin;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final int? technicianId;
  final String technicianName;
  final bool stockMovementApplied;
  final int sortOrder;
}

class ServiceOrderAttachment {
  const ServiceOrderAttachment({
    this.id,
    required this.orderId,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.createdBy,
  });

  final int? id;
  final int orderId;
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final String createdBy;
}

class ServiceOrderHistoryEntry {
  const ServiceOrderHistoryEntry({
    this.id,
    required this.orderId,
    required this.eventType,
    required this.fromStatus,
    required this.toStatus,
    required this.message,
    required this.createdAt,
    required this.createdBy,
  });

  final int? id;
  final int orderId;
  final String eventType;
  final ServiceOrderStatus? fromStatus;
  final ServiceOrderStatus? toStatus;
  final String message;
  final DateTime createdAt;
  final String createdBy;
}

class ServiceOrderDetails {
  const ServiceOrderDetails({
    required this.id,
    required this.orderNumber,
    required this.isDraft,
    required this.customerId,
    required this.equipmentId,
    required this.status,
    required this.priority,
    required this.entryAt,
    required this.readyAt,
    required this.exitAt,
    required this.warrantyUntil,
    required this.responsibleTechnicianId,
    required this.situation,
    required this.customerName,
    required this.customerDocument,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.equipmentModel,
    required this.equipmentBrand,
    required this.equipmentMicroCpu,
    required this.equipmentRamHd,
    required this.equipmentSerialNumber,
    required this.equipmentAssetTag,
    required this.equipmentAccessories,
    required this.defectComplaint,
    required this.equipmentObservations,
    required this.technicalReport,
    required this.internalNotes,
    required this.advanceAmount,
    required this.laborAmount,
    required this.partsAmount,
    required this.travelAmount,
    required this.thirdPartyAmount,
    required this.otherAmount,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.serviceLines,
    required this.partLines,
    required this.attachments,
    required this.history,
  });

  final int id;
  final int orderNumber;
  final bool isDraft;
  final int? customerId;
  final int? equipmentId;
  final ServiceOrderStatus status;
  final ServiceOrderPriority priority;
  final DateTime entryAt;
  final DateTime? readyAt;
  final DateTime? exitAt;
  final DateTime? warrantyUntil;
  final int? responsibleTechnicianId;
  final String situation;
  final String customerName;
  final String customerDocument;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final String equipmentModel;
  final String equipmentBrand;
  final String equipmentMicroCpu;
  final String equipmentRamHd;
  final String equipmentSerialNumber;
  final String equipmentAssetTag;
  final String equipmentAccessories;
  final String defectComplaint;
  final String equipmentObservations;
  final String technicalReport;
  final String internalNotes;
  final double advanceAmount;
  final double laborAmount;
  final double partsAmount;
  final double travelAmount;
  final double thirdPartyAmount;
  final double otherAmount;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final List<ServiceOrderServiceLine> serviceLines;
  final List<ServiceOrderPartLine> partLines;
  final List<ServiceOrderAttachment> attachments;
  final List<ServiceOrderHistoryEntry> history;

  double get calculatedLaborAmount =>
      serviceLines.fold<double>(0, (sum, line) => sum + line.totalPrice);

  double get calculatedPartsAmount =>
      partLines.fold<double>(0, (sum, line) => sum + line.totalPrice);

  bool get canBeClosed =>
      customerId != null &&
      equipmentModel.trim().isNotEmpty &&
      (serviceLines.isNotEmpty || partLines.isNotEmpty);
}

class ServiceOrderCustomerDraft {
  const ServiceOrderCustomerDraft({
    required this.name,
    required this.document,
    required this.phone,
    required this.email,
    required this.address,
    this.tradeName = '',
    this.contactName = '',
    this.birthday = '',
    this.stateRegistration = '',
    this.personType = '',
    this.zipCode = '',
    this.street = '',
    this.streetNumber = '',
    this.complement = '',
    this.neighborhood = '',
    this.city = '',
    this.stateCode = '',
    this.country = '',
    this.businessPhone = '',
    this.mobilePhone = '',
    this.fiscalEmail = '',
    this.notes = '',
    this.customerGroup = '',
    this.gender = '',
  });

  final String name;
  final String document;
  final String phone;
  final String email;
  final String address;
  final String tradeName;
  final String contactName;
  final String birthday;
  final String stateRegistration;
  final String personType;
  final String zipCode;
  final String street;
  final String streetNumber;
  final String complement;
  final String neighborhood;
  final String city;
  final String stateCode;
  final String country;
  final String businessPhone;
  final String mobilePhone;
  final String fiscalEmail;
  final String notes;
  final String customerGroup;
  final String gender;

  void validate() {
    if (name.trim().isEmpty) {
      throw StateError('Informe o nome do cliente.');
    }
  }
}

class ServiceOrderEquipmentDraft {
  const ServiceOrderEquipmentDraft({
    required this.customerId,
    required this.model,
    required this.brand,
    required this.microCpu,
    required this.ramHd,
    required this.serialNumber,
    required this.assetTag,
    required this.accessories,
    required this.notes,
  });

  final int customerId;
  final String model;
  final String brand;
  final String microCpu;
  final String ramHd;
  final String serialNumber;
  final String assetTag;
  final String accessories;
  final String notes;

  void validate() {
    if (customerId <= 0) {
      throw StateError('Selecione o cliente do equipamento.');
    }
    if (model.trim().isEmpty) {
      throw StateError('Informe o modelo do equipamento.');
    }
  }
}

class ServiceOrderTechnicianDraft {
  const ServiceOrderTechnicianDraft({required this.name});

  final String name;

  void validate() {
    if (name.trim().isEmpty) {
      throw StateError('Informe o nome do tecnico.');
    }
  }
}

class ServiceOrderServiceLineDraft {
  const ServiceOrderServiceLineDraft({
    this.id,
    required this.description,
    required this.serviceType,
    required this.startTime,
    required this.endTime,
    required this.quantity,
    required this.unitPrice,
    required this.technicianId,
    required this.technicianName,
  });

  final int? id;
  final String description;
  final String serviceType;
  final DateTime? startTime;
  final DateTime? endTime;
  final double quantity;
  final double unitPrice;
  final int? technicianId;
  final String technicianName;

  double get totalPrice => quantity * unitPrice;

  void validate() {
    if (description.trim().isEmpty) {
      throw StateError('Informe a descricao do servico.');
    }
    if (quantity <= 0) {
      throw StateError('A quantidade do servico deve ser maior que zero.');
    }
    if (unitPrice < 0) {
      throw StateError('O valor do servico nao pode ser negativo.');
    }
    if (startTime != null && endTime != null && endTime!.isBefore(startTime!)) {
      throw StateError('O horario final nao pode ser menor que o inicial.');
    }
  }
}

class ServiceOrderPartLineDraft {
  const ServiceOrderPartLineDraft({
    this.id,
    required this.itemId,
    required this.partName,
    required this.origin,
    required this.quantity,
    required this.unitPrice,
    required this.technicianId,
    required this.technicianName,
  });

  final int? id;
  final int? itemId;
  final String partName;
  final ServiceOrderPartOrigin origin;
  final double quantity;
  final double unitPrice;
  final int? technicianId;
  final String technicianName;

  double get totalPrice => quantity * unitPrice;

  void validate() {
    if (partName.trim().isEmpty) {
      throw StateError('Informe a descricao da peca.');
    }
    if (quantity <= 0) {
      throw StateError('A quantidade da peca deve ser maior que zero.');
    }
    if (unitPrice < 0) {
      throw StateError('O valor da peca nao pode ser negativo.');
    }
    if (origin == ServiceOrderPartOrigin.stock && (itemId ?? 0) <= 0) {
      throw StateError('Selecione o item de estoque para peca de estoque.');
    }
  }
}

class ServiceOrderAttachmentDraft {
  const ServiceOrderAttachmentDraft({
    this.id,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.createdBy,
  });

  final int? id;
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final String createdBy;
}

class ServiceOrderDraft {
  const ServiceOrderDraft({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.equipmentId,
    required this.status,
    required this.priority,
    required this.entryAt,
    required this.readyAt,
    required this.exitAt,
    required this.warrantyUntil,
    required this.responsibleTechnicianId,
    required this.situation,
    required this.equipmentModel,
    required this.equipmentBrand,
    required this.equipmentMicroCpu,
    required this.equipmentRamHd,
    required this.equipmentSerialNumber,
    required this.equipmentAssetTag,
    required this.equipmentAccessories,
    required this.defectComplaint,
    required this.equipmentObservations,
    required this.technicalReport,
    required this.internalNotes,
    required this.advanceAmount,
    required this.travelAmount,
    required this.thirdPartyAmount,
    required this.otherAmount,
    required this.updatedBy,
    required this.serviceLines,
    required this.partLines,
    required this.attachments,
  });

  final int id;
  final int orderNumber;
  final int? customerId;
  final int? equipmentId;
  final ServiceOrderStatus status;
  final ServiceOrderPriority priority;
  final DateTime entryAt;
  final DateTime? readyAt;
  final DateTime? exitAt;
  final DateTime? warrantyUntil;
  final int? responsibleTechnicianId;
  final String situation;
  final String equipmentModel;
  final String equipmentBrand;
  final String equipmentMicroCpu;
  final String equipmentRamHd;
  final String equipmentSerialNumber;
  final String equipmentAssetTag;
  final String equipmentAccessories;
  final String defectComplaint;
  final String equipmentObservations;
  final String technicalReport;
  final String internalNotes;
  final double advanceAmount;
  final double travelAmount;
  final double thirdPartyAmount;
  final double otherAmount;
  final String updatedBy;
  final List<ServiceOrderServiceLineDraft> serviceLines;
  final List<ServiceOrderPartLineDraft> partLines;
  final List<ServiceOrderAttachmentDraft> attachments;

  void validate() {
    if (id <= 0) {
      throw StateError('Ordem de servico invalida.');
    }
    if ((customerId ?? 0) <= 0) {
      throw StateError('Selecione o cliente da OS.');
    }
    if (equipmentModel.trim().isEmpty) {
      throw StateError('Informe o modelo do equipamento.');
    }
    if (updatedBy.trim().isEmpty) {
      throw StateError('Informe o usuario responsavel pela alteracao.');
    }
    if (advanceAmount < 0 ||
        travelAmount < 0 ||
        thirdPartyAmount < 0 ||
        otherAmount < 0) {
      throw StateError('Valores adicionais nao podem ser negativos.');
    }

    for (final line in serviceLines) {
      line.validate();
    }
    for (final line in partLines) {
      line.validate();
    }
  }
}

abstract class ServiceOrdersRepository {
  Future<ServiceOrderLookupData> getLookupData({int? customerId});

  Future<List<ServiceOrderSummary>> getOrders({
    ServiceOrderFilter filter = const ServiceOrderFilter(),
  });

  Future<ServiceOrderDetails> createOrder({required String actor});

  Future<ServiceOrderDetails?> getOrderDetails(int orderId);

  Future<ServiceOrderCustomer> createCustomer(ServiceOrderCustomerDraft draft);

  Future<ServiceOrderEquipment> createEquipment(
    ServiceOrderEquipmentDraft draft,
  );

  Future<ServiceOrderTechnician> createTechnician(
    ServiceOrderTechnicianDraft draft,
  );

  Future<ServiceOrderDetails> saveOrder(ServiceOrderDraft draft);

  Future<ServiceOrderDetails> changeStatus(
    int orderId,
    ServiceOrderStatus status, {
    required String actor,
    String note = '',
  });

  Future<ServiceOrderDetails> closeOrder(int orderId, {required String actor});

  Future<void> deleteDraftOrder(int orderId);

  Future<Uint8List> exportOrderPdf(int orderId);

  Future<Uint8List> exportBudgetPdf(int orderId);
}

class GetServiceOrderLookupUseCase {
  const GetServiceOrderLookupUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderLookupData> call({int? customerId}) {
    return _repository.getLookupData(customerId: customerId);
  }
}

class GetServiceOrdersUseCase {
  const GetServiceOrdersUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<List<ServiceOrderSummary>> call({
    ServiceOrderFilter filter = const ServiceOrderFilter(),
  }) {
    return _repository.getOrders(filter: filter);
  }
}

class CreateServiceOrderUseCase {
  const CreateServiceOrderUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderDetails> call({required String actor}) {
    return _repository.createOrder(actor: actor);
  }
}

class GetServiceOrderDetailsUseCase {
  const GetServiceOrderDetailsUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderDetails?> call(int orderId) {
    return _repository.getOrderDetails(orderId);
  }
}

class CreateServiceOrderCustomerUseCase {
  const CreateServiceOrderCustomerUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderCustomer> call(ServiceOrderCustomerDraft draft) {
    return _repository.createCustomer(draft);
  }
}

class CreateServiceOrderEquipmentUseCase {
  const CreateServiceOrderEquipmentUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderEquipment> call(ServiceOrderEquipmentDraft draft) {
    return _repository.createEquipment(draft);
  }
}

class CreateServiceOrderTechnicianUseCase {
  const CreateServiceOrderTechnicianUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderTechnician> call(ServiceOrderTechnicianDraft draft) {
    return _repository.createTechnician(draft);
  }
}

class SaveServiceOrderUseCase {
  const SaveServiceOrderUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderDetails> call(ServiceOrderDraft draft) {
    return _repository.saveOrder(draft);
  }
}

class ChangeServiceOrderStatusUseCase {
  const ChangeServiceOrderStatusUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderDetails> call(
    int orderId,
    ServiceOrderStatus status, {
    required String actor,
    String note = '',
  }) {
    return _repository.changeStatus(orderId, status, actor: actor, note: note);
  }
}

class CloseServiceOrderUseCase {
  const CloseServiceOrderUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<ServiceOrderDetails> call(int orderId, {required String actor}) {
    return _repository.closeOrder(orderId, actor: actor);
  }
}

class ExportServiceOrderPdfUseCase {
  const ExportServiceOrderPdfUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<Uint8List> call(int orderId) => _repository.exportOrderPdf(orderId);
}

class ExportServiceOrderBudgetPdfUseCase {
  const ExportServiceOrderBudgetPdfUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<Uint8List> call(int orderId) => _repository.exportBudgetPdf(orderId);
}

class DeleteDraftServiceOrderUseCase {
  const DeleteDraftServiceOrderUseCase(this._repository);

  final ServiceOrdersRepository _repository;

  Future<void> call(int orderId) => _repository.deleteDraftOrder(orderId);
}
