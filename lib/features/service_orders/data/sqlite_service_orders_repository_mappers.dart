part of 'sqlite_service_orders_repository.dart';

extension _ServiceOrdersRepositoryMappers on SqliteServiceOrdersRepository {
  ServiceOrderSummary _mapSummary(Map<String, Object?> row) {
    return ServiceOrderSummary(
      id: row['id'] as int,
      orderNumber: _toInt(row['order_number']),
      customerName: row['customer_name'] as String? ?? '',
      equipmentModel: row['equipment_model'] as String? ?? '',
      status: ServiceOrderStatusView.fromStorageValue(
        row['status'] as String? ?? '',
      ),
      priority: ServiceOrderPriorityView.fromStorageValue(
        row['priority'] as String? ?? '',
      ),
      entryAt: _parseDateTime(row['entry_at']) ?? DateTime.now(),
      readyAt: _parseDateTime(row['ready_at']),
      exitAt: _parseDateTime(row['exit_at']),
      responsibleTechnician:
          row['responsible_technician_name'] as String? ?? '',
      totalAmount: _toDouble(row['total_amount']),
    );
  }

  ServiceOrderDetails _mapDetails(
    Map<String, Object?> row,
    List<Map<String, Object?>> serviceRows,
    List<Map<String, Object?>> partRows,
    List<Map<String, Object?>> attachmentRows,
    List<Map<String, Object?>> historyRows,
  ) {
    return ServiceOrderDetails(
      id: row['id'] as int,
      orderNumber: _toInt(row['order_number']),
      isDraft: (row['is_draft'] as num?)?.toInt() == 1,
      customerId: row['customer_id'] as int?,
      equipmentId: row['equipment_id'] as int?,
      status: ServiceOrderStatusView.fromStorageValue(
        row['status'] as String? ?? '',
      ),
      priority: ServiceOrderPriorityView.fromStorageValue(
        row['priority'] as String? ?? '',
      ),
      entryAt: _parseDateTime(row['entry_at']) ?? DateTime.now(),
      readyAt: _parseDateTime(row['ready_at']),
      exitAt: _parseDateTime(row['exit_at']),
      warrantyUntil: _parseDateTime(row['warranty_until']),
      responsibleTechnicianId: row['responsible_technician_id'] as int?,
      situation: row['situation_note'] as String? ?? '',
      customerName: row['customer_name'] as String? ?? '',
      customerDocument: row['customer_document'] as String? ?? '',
      customerPhone: row['customer_phone'] as String? ?? '',
      customerEmail: row['customer_email'] as String? ?? '',
      customerAddress: row['customer_address'] as String? ?? '',
      equipmentModel: row['equipment_model'] as String? ?? '',
      equipmentBrand: row['equipment_brand'] as String? ?? '',
      equipmentMicroCpu: row['equipment_micro_cpu'] as String? ?? '',
      equipmentRamHd: row['equipment_ram_hd'] as String? ?? '',
      equipmentSerialNumber: row['equipment_serial_number'] as String? ?? '',
      equipmentAssetTag: row['equipment_asset_tag'] as String? ?? '',
      equipmentAccessories: row['equipment_accessories'] as String? ?? '',
      defectComplaint: row['defect_complaint'] as String? ?? '',
      equipmentObservations: row['equipment_observations'] as String? ?? '',
      technicalReport: row['technical_report'] as String? ?? '',
      internalNotes: row['internal_notes'] as String? ?? '',
      advanceAmount: _toDouble(row['advance_amount']),
      laborAmount: _toDouble(row['labor_amount']),
      partsAmount: _toDouble(row['parts_amount']),
      travelAmount: _toDouble(row['travel_amount']),
      thirdPartyAmount: _toDouble(row['third_party_amount']),
      otherAmount: _toDouble(row['other_amount']),
      totalAmount: _toDouble(row['total_amount']),
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(row['updated_at']) ?? DateTime.now(),
      createdBy: row['created_by'] as String? ?? '',
      updatedBy: row['updated_by'] as String? ?? '',
      serviceLines: serviceRows.map(_mapServiceLine).toList(),
      partLines: partRows.map(_mapPartLine).toList(),
      attachments: attachmentRows.map(_mapAttachment).toList(),
      history: historyRows.map(_mapHistory).toList(),
    );
  }

  ServiceOrderCustomer _mapCustomer(Map<String, Object?> row) {
    return ServiceOrderCustomer(
      id: row['id'] as int,
      name: row['name'] as String? ?? '',
      tradeName: row['trade_name'] as String? ?? '',
      contactName: row['contact_name'] as String? ?? '',
      birthday: row['birthday'] as String? ?? '',
      document: row['document'] as String? ?? '',
      stateRegistration: row['state_registration'] as String? ?? '',
      personType: row['person_type'] as String? ?? '',
      zipCode: row['zip_code'] as String? ?? '',
      street: row['street'] as String? ?? '',
      streetNumber: row['street_number'] as String? ?? '',
      complement: row['complement'] as String? ?? '',
      neighborhood: row['neighborhood'] as String? ?? '',
      city: row['city'] as String? ?? '',
      stateCode: row['state_code'] as String? ?? '',
      country: row['country'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      businessPhone: row['business_phone'] as String? ?? '',
      mobilePhone: row['mobile_phone'] as String? ?? '',
      email: row['email'] as String? ?? '',
      fiscalEmail: row['fiscal_email'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      customerGroup: row['customer_group'] as String? ?? '',
      gender: row['gender'] as String? ?? '',
      address: row['address'] as String? ?? '',
    );
  }

  ServiceOrderEquipment _mapEquipment(Map<String, Object?> row) {
    return ServiceOrderEquipment(
      id: row['id'] as int,
      customerId: _toInt(row['customer_id']),
      model: row['model'] as String? ?? '',
      brand: row['brand'] as String? ?? '',
      microCpu: row['micro_cpu'] as String? ?? '',
      ramHd: row['ram_hd'] as String? ?? '',
      serialNumber: row['serial_number'] as String? ?? '',
      assetTag: row['asset_tag'] as String? ?? '',
      accessories: row['accessories'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      isActive: (row['is_active'] as num?)?.toInt() != 0,
    );
  }

  ServiceOrderTechnician _mapTechnician(Map<String, Object?> row) {
    return ServiceOrderTechnician(
      id: row['id'] as int,
      name: row['name'] as String? ?? '',
      isActive: (row['is_active'] as num?)?.toInt() != 0,
    );
  }

  InventoryItem _mapInventoryItem(Map<String, Object?> row) {
    return InventoryItem(
      id: row['id'] as int,
      name: row['name'] as String? ?? '',
      sku: row['sku'] as String? ?? '',
      category: row['category'] as String? ?? '',
      unit: row['unit'] as String? ?? '',
      quantity: _toDouble(row['quantity']),
      minimumStock: _toDouble(row['minimum_stock']),
      price: _toDouble(row['price']),
      isActive: (row['is_active'] as num?)?.toInt() != 0,
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(row['updated_at']) ?? DateTime.now(),
    );
  }

  ServiceOrderServiceLine _mapServiceLine(Map<String, Object?> row) {
    return ServiceOrderServiceLine(
      id: row['id'] as int,
      orderId: _toInt(row['order_id']),
      description: row['description'] as String? ?? '',
      serviceType: row['service_type'] as String? ?? '',
      startTime: _parseDateTime(row['start_time']),
      endTime: _parseDateTime(row['end_time']),
      quantity: _toDouble(row['quantity']),
      unitPrice: _toDouble(row['unit_price']),
      totalPrice: _toDouble(row['total_price']),
      technicianId: row['technician_id'] as int?,
      technicianName: row['technician_name'] as String? ?? '',
      sortOrder: _toInt(row['sort_order']),
    );
  }

  ServiceOrderPartLine _mapPartLine(Map<String, Object?> row) {
    return ServiceOrderPartLine(
      id: row['id'] as int,
      orderId: _toInt(row['order_id']),
      itemId: row['item_id'] as int?,
      partName: row['part_name'] as String? ?? '',
      origin: ServiceOrderPartOriginView.fromStorageValue(
        row['origin'] as String? ?? '',
      ),
      quantity: _toDouble(row['quantity']),
      unitPrice: _toDouble(row['unit_price']),
      totalPrice: _toDouble(row['total_price']),
      technicianId: row['technician_id'] as int?,
      technicianName: row['technician_name'] as String? ?? '',
      stockMovementApplied:
          (row['stock_movement_applied'] as num?)?.toInt() == 1,
      sortOrder: _toInt(row['sort_order']),
    );
  }

  ServiceOrderAttachment _mapAttachment(Map<String, Object?> row) {
    return ServiceOrderAttachment(
      id: row['id'] as int,
      orderId: _toInt(row['order_id']),
      filePath: row['file_path'] as String? ?? '',
      fileName: row['file_name'] as String? ?? '',
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
      createdBy: row['created_by'] as String? ?? '',
    );
  }

  ServiceOrderHistoryEntry _mapHistory(Map<String, Object?> row) {
    return ServiceOrderHistoryEntry(
      id: row['id'] as int,
      orderId: _toInt(row['order_id']),
      eventType: row['event_type'] as String? ?? '',
      fromStatus: (row['from_status'] as String?) == null
          ? null
          : ServiceOrderStatusView.fromStorageValue(
              row['from_status'] as String? ?? '',
            ),
      toStatus: (row['to_status'] as String?) == null
          ? null
          : ServiceOrderStatusView.fromStorageValue(
              row['to_status'] as String? ?? '',
            ),
      message: row['message'] as String? ?? '',
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.now(),
      createdBy: row['created_by'] as String? ?? '',
    );
  }

  void _appendDateRange({
    required List<String> whereClauses,
    required List<Object?> whereArgs,
    required String column,
    required DateTime? from,
    required DateTime? to,
  }) {
    if (from != null) {
      whereClauses.add('$column >= ?');
      whereArgs.add(from.toUtc().toIso8601String());
    }
    if (to != null) {
      whereClauses.add('$column <= ?');
      whereArgs.add(to.toUtc().toIso8601String());
    }
  }

  DateTime? _parseDateTime(Object? value) {
    final raw = value as String?;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  double _toDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

  int _toInt(Object? value) => (value as num?)?.toInt() ?? 0;

  String _pickSnapshotValue(String draftValue, String? fallback) {
    final trimmed = draftValue.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return (fallback ?? '').trim();
  }
}
