part of 'sqlite_service_orders_repository.dart';

extension _ServiceOrdersRepositoryCommands on SqliteServiceOrdersRepository {
  Future<ServiceOrderDetails> _createOrder({required String actor}) async {
    final normalizedActor = actor.trim().isEmpty ? 'Sistema' : actor.trim();
    final database = await _databaseService.database;

    return database.transaction((transaction) async {
      final orderNumber = await _nextOrderNumber(transaction);
      final now = DateTime.now().toUtc().toIso8601String();

      final orderId = await transaction.insert('service_orders', {
        'order_number': orderNumber,
        'is_draft': 1,
        'status': ServiceOrderStatus.open.storageValue,
        'priority': ServiceOrderPriority.normal.storageValue,
        'entry_at': now,
        'responsible_technician_name': normalizedActor,
        'created_at': now,
        'updated_at': now,
        'created_by': normalizedActor,
        'updated_by': normalizedActor,
      });

      await _insertHistory(
        transaction,
        orderId: orderId,
        eventType: 'created',
        fromStatus: null,
        toStatus: ServiceOrderStatus.open,
        message: 'OS criada.',
        actor: normalizedActor,
      );

      return _loadDetails(transaction, orderId);
    });
  }

  Future<ServiceOrderDetails?> _getOrderDetails(int orderId) async {
    final database = await _databaseService.database;
    final row = await database.query(
      'service_orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (row.isEmpty) {
      return null;
    }

    return _loadDetails(database, orderId);
  }

  Future<ServiceOrderCustomer> _createCustomer(
    ServiceOrderCustomerDraft draft,
  ) async {
    draft.validate();

    final database = await _databaseService.database;
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await database.insert('customers', {
      'name': draft.name.trim(),
      'trade_name': draft.tradeName.trim(),
      'contact_name': draft.contactName.trim(),
      'birthday': draft.birthday.trim(),
      'document': draft.document.trim(),
      'state_registration': draft.stateRegistration.trim(),
      'person_type': draft.personType.trim(),
      'zip_code': draft.zipCode.trim(),
      'street': draft.street.trim(),
      'street_number': draft.streetNumber.trim(),
      'complement': draft.complement.trim(),
      'neighborhood': draft.neighborhood.trim(),
      'city': draft.city.trim(),
      'state_code': draft.stateCode.trim(),
      'country': draft.country.trim(),
      'phone': draft.phone.trim(),
      'business_phone': draft.businessPhone.trim(),
      'mobile_phone': draft.mobilePhone.trim(),
      'email': draft.email.trim(),
      'fiscal_email': draft.fiscalEmail.trim(),
      'notes': draft.notes.trim(),
      'customer_group': draft.customerGroup.trim(),
      'gender': draft.gender.trim(),
      'address': _buildCustomerAddress(draft),
      'created_at': now,
      'updated_at': now,
    });

    final rows = await database.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return _mapCustomer(rows.first);
  }

  Future<ServiceOrderEquipment> _createEquipment(
    ServiceOrderEquipmentDraft draft,
  ) async {
    draft.validate();

    final database = await _databaseService.database;
    final customerRows = await database.query(
      'customers',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [draft.customerId],
      limit: 1,
    );
    if (customerRows.isEmpty) {
      throw StateError('Cliente do equipamento nao encontrado.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final id = await database.insert('equipments', {
      'customer_id': draft.customerId,
      'model': draft.model.trim(),
      'brand': draft.brand.trim(),
      'micro_cpu': draft.microCpu.trim(),
      'ram_hd': draft.ramHd.trim(),
      'serial_number': draft.serialNumber.trim(),
      'asset_tag': draft.assetTag.trim(),
      'accessories': draft.accessories.trim(),
      'notes': draft.notes.trim(),
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    final rows = await database.query(
      'equipments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return _mapEquipment(rows.first);
  }

  Future<ServiceOrderTechnician> _createTechnician(
    ServiceOrderTechnicianDraft draft,
  ) async {
    draft.validate();

    final database = await _databaseService.database;
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await database.insert('technicians', {
      'name': draft.name.trim(),
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    final rows = await database.query(
      'technicians',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return _mapTechnician(rows.first);
  }

  Future<ServiceOrderDetails> _saveOrder(ServiceOrderDraft draft) async {
    draft.validate();

    final database = await _databaseService.database;

    return database.transaction((transaction) async {
      final orderRows = await transaction.query(
        'service_orders',
        columns: [
          'id',
          'status',
          'total_amount',
          'responsible_technician_name',
          'equipment_model',
          'equipment_brand',
          'equipment_micro_cpu',
          'equipment_ram_hd',
          'equipment_serial_number',
          'equipment_asset_tag',
          'equipment_accessories',
        ],
        where: 'id = ?',
        whereArgs: [draft.id],
        limit: 1,
      );

      if (orderRows.isEmpty) {
        throw StateError('A OS selecionada nao foi encontrada.');
      }

      final orderRow = orderRows.first;
      final currentStatus = ServiceOrderStatusView.fromStorageValue(
        orderRow['status'] as String? ?? '',
      );

      if (currentStatus == ServiceOrderStatus.delivered ||
          currentStatus == ServiceOrderStatus.canceled) {
        throw StateError('Nao e possivel editar uma OS entregue ou cancelada.');
      }

      if (!currentStatus.canTransitionTo(draft.status)) {
        throw StateError(
          'Transicao de status invalida: ${currentStatus.label} -> ${draft.status.label}.',
        );
      }

      final customerRow = await _loadCustomerRow(
        transaction,
        draft.customerId!,
      );
      final responsibleName = draft.updatedBy.trim().isEmpty
          ? (orderRow['responsible_technician_name'] as String? ?? '').trim()
          : draft.updatedBy.trim();

      final laborAmount = draft.serviceLines.fold<double>(
        0,
        (sum, line) => sum + line.totalPrice,
      );
      final partsAmount = draft.partLines.fold<double>(
        0,
        (sum, line) => sum + line.totalPrice,
      );
      final gross =
          laborAmount +
          partsAmount +
          draft.travelAmount +
          draft.thirdPartyAmount +
          draft.otherAmount;
      final totalAmount = max<double>(0, gross - draft.advanceAmount);
      final now = DateTime.now().toUtc().toIso8601String();

      final existingPartRows = await transaction.query(
        'service_order_parts',
        columns: ['id', 'stock_movement_applied'],
        where: 'order_id = ?',
        whereArgs: [draft.id],
      );
      final movementFlagById = <int, bool>{
        for (final row in existingPartRows)
          (row['id'] as int):
              (row['stock_movement_applied'] as num?)?.toInt() == 1,
      };

      await transaction.update(
        'service_orders',
        {
          'customer_id': draft.customerId,
          'is_draft': 0,
          'equipment_id': draft.equipmentId,
          'status': draft.status.storageValue,
          'priority': draft.priority.storageValue,
          'entry_at': draft.entryAt.toUtc().toIso8601String(),
          'ready_at': draft.readyAt?.toUtc().toIso8601String(),
          'exit_at': draft.exitAt?.toUtc().toIso8601String(),
          'warranty_until': draft.warrantyUntil?.toUtc().toIso8601String(),
          'responsible_technician_id': draft.responsibleTechnicianId,
          'responsible_technician_name': responsibleName,
          'situation_note': draft.situation.trim(),
          'customer_name': customerRow['name'] as String? ?? '',
          'customer_document': customerRow['document'] as String? ?? '',
          'customer_phone': customerRow['phone'] as String? ?? '',
          'customer_email': customerRow['email'] as String? ?? '',
          'customer_address': customerRow['address'] as String? ?? '',
          'equipment_model': _pickSnapshotValue(
            draft.equipmentModel,
            orderRow['equipment_model'] as String?,
          ),
          'equipment_brand': _pickSnapshotValue(
            draft.equipmentBrand,
            orderRow['equipment_brand'] as String?,
          ),
          'equipment_micro_cpu': _pickSnapshotValue(
            draft.equipmentMicroCpu,
            orderRow['equipment_micro_cpu'] as String?,
          ),
          'equipment_ram_hd': _pickSnapshotValue(
            draft.equipmentRamHd,
            orderRow['equipment_ram_hd'] as String?,
          ),
          'equipment_serial_number': _pickSnapshotValue(
            draft.equipmentSerialNumber,
            orderRow['equipment_serial_number'] as String?,
          ),
          'equipment_asset_tag': _pickSnapshotValue(
            draft.equipmentAssetTag,
            orderRow['equipment_asset_tag'] as String?,
          ),
          'equipment_accessories': _pickSnapshotValue(
            draft.equipmentAccessories,
            orderRow['equipment_accessories'] as String?,
          ),
          'defect_complaint': draft.defectComplaint.trim(),
          'equipment_observations': draft.equipmentObservations.trim(),
          'technical_report': draft.technicalReport.trim(),
          'internal_notes': draft.internalNotes.trim(),
          'advance_amount': draft.advanceAmount,
          'labor_amount': laborAmount,
          'parts_amount': partsAmount,
          'travel_amount': draft.travelAmount,
          'third_party_amount': draft.thirdPartyAmount,
          'other_amount': draft.otherAmount,
          'total_amount': totalAmount,
          'updated_at': now,
          'updated_by': draft.updatedBy.trim(),
        },
        where: 'id = ?',
        whereArgs: [draft.id],
      );

      await _replaceServiceLines(transaction, draft.id, draft.serviceLines);
      await _replacePartLines(
        transaction,
        draft.id,
        draft.partLines,
        movementFlagById,
      );
      await _replaceAttachments(transaction, draft.id, draft.attachments);

      final oldTotal = _toDouble(orderRow['total_amount']);
      if ((oldTotal - totalAmount).abs() > 0.000001) {
        await _insertHistory(
          transaction,
          orderId: draft.id,
          eventType: 'total_changed',
          fromStatus: null,
          toStatus: null,
          message:
              'Total atualizado de R\$ ${oldTotal.toStringAsFixed(2)} para R\$ ${totalAmount.toStringAsFixed(2)}.',
          actor: draft.updatedBy,
        );
      }

      if (currentStatus != draft.status) {
        await _insertHistory(
          transaction,
          orderId: draft.id,
          eventType: 'status_changed',
          fromStatus: currentStatus,
          toStatus: draft.status,
          message:
              'Status alterado de ${currentStatus.label} para ${draft.status.label}.',
          actor: draft.updatedBy,
        );
      }

      return _loadDetails(transaction, draft.id);
    });
  }

  Future<ServiceOrderDetails> _changeStatus(
    int orderId,
    ServiceOrderStatus status, {
    required String actor,
    String note = '',
  }) async {
    final normalizedActor = actor.trim().isEmpty ? 'Sistema' : actor.trim();
    final database = await _databaseService.database;

    return database.transaction((transaction) async {
      final rows = await transaction.query(
        'service_orders',
        columns: ['id', 'status', 'ready_at'],
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw StateError('A OS selecionada nao foi encontrada.');
      }

      final currentStatus = ServiceOrderStatusView.fromStorageValue(
        rows.first['status'] as String? ?? '',
      );

      if (status == ServiceOrderStatus.delivered) {
        throw StateError(
          'Use o botao Encerrar OS para concluir entrega e baixa de estoque.',
        );
      }
      if (!currentStatus.canTransitionTo(status)) {
        throw StateError(
          'Transicao de status invalida: ${currentStatus.label} -> ${status.label}.',
        );
      }

      final now = DateTime.now().toUtc().toIso8601String();
      await transaction.update(
        'service_orders',
        {
          'status': status.storageValue,
          'ready_at': status == ServiceOrderStatus.ready
              ? (rows.first['ready_at'] as String?) ?? now
              : rows.first['ready_at'],
          'updated_at': now,
          'updated_by': normalizedActor,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );

      await _insertHistory(
        transaction,
        orderId: orderId,
        eventType: 'status_changed',
        fromStatus: currentStatus,
        toStatus: status,
        message: note.trim().isEmpty
            ? 'Status alterado manualmente.'
            : 'Status alterado: ${note.trim()}',
        actor: normalizedActor,
      );

      return _loadDetails(transaction, orderId);
    });
  }

  Future<ServiceOrderDetails> _closeOrder(
    int orderId, {
    required String actor,
  }) async {
    final normalizedActor = actor.trim().isEmpty ? 'Sistema' : actor.trim();
    final database = await _databaseService.database;

    return database.transaction((transaction) async {
      final details = await _loadDetails(transaction, orderId);

      if (details.status == ServiceOrderStatus.delivered) {
        throw StateError('Esta OS ja foi encerrada.');
      }
      if (details.status == ServiceOrderStatus.canceled) {
        throw StateError('Nao e possivel encerrar uma OS cancelada.');
      }
      if (!details.status.canTransitionTo(ServiceOrderStatus.delivered)) {
        throw StateError('A OS precisa estar pronta para ser encerrada.');
      }
      if (!details.canBeClosed) {
        throw StateError(
          'Nao e possivel encerrar sem cliente, dados do equipamento e pelo menos um servico ou peca.',
        );
      }

      final now = DateTime.now().toUtc().toIso8601String();

      for (final part in details.partLines.where(
        (line) =>
            line.origin == ServiceOrderPartOrigin.stock &&
            !line.stockMovementApplied,
      )) {
        final itemId = part.itemId;
        if (itemId == null) {
          throw StateError(
            'A peca "${part.partName}" esta marcada como estoque sem item vinculado.',
          );
        }

        final itemRows = await transaction.query(
          'items',
          columns: ['id', 'name', 'quantity', 'is_active'],
          where: 'id = ?',
          whereArgs: [itemId],
          limit: 1,
        );

        if (itemRows.isEmpty) {
          throw StateError(
            'Item de estoque da peca "${part.partName}" nao encontrado.',
          );
        }

        final itemRow = itemRows.first;
        if ((itemRow['is_active'] as num?)?.toInt() == 0) {
          throw StateError(
            'O item de estoque "${itemRow['name']}" esta inativo. Reative-o para encerrar a OS.',
          );
        }

        final currentQuantity = _toDouble(itemRow['quantity']);
        if (currentQuantity < part.quantity) {
          throw StateError(
            'Estoque insuficiente para a peca "${part.partName}". Saldo atual: ${currentQuantity.toStringAsFixed(2)}.',
          );
        }

        final nextQuantity = currentQuantity - part.quantity;

        await transaction.update(
          'items',
          {'quantity': nextQuantity, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [itemId],
        );

        await transaction.insert('movements', {
          'item_id': itemId,
          'type': 'exit',
          'quantity': part.quantity,
          'note':
              'Baixa automatica da OS N${details.orderNumber}: ${part.partName}',
          'created_at': now,
        });

        if (part.id != null) {
          await transaction.update(
            'service_order_parts',
            {'stock_movement_applied': 1},
            where: 'id = ?',
            whereArgs: [part.id],
          );
        }
      }

      await transaction.update(
        'service_orders',
        {
          'status': ServiceOrderStatus.delivered.storageValue,
          'exit_at': details.exitAt == null
              ? now
              : details.exitAt!.toUtc().toIso8601String(),
          'updated_at': now,
          'updated_by': normalizedActor,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );

      await _insertHistory(
        transaction,
        orderId: orderId,
        eventType: 'closed',
        fromStatus: details.status,
        toStatus: ServiceOrderStatus.delivered,
        message: 'OS encerrada com baixa de estoque aplicada.',
        actor: normalizedActor,
      );

      return _loadDetails(transaction, orderId);
    });
  }

  Future<Uint8List> _exportOrderPdf(int orderId) async {
    final details = await _getOrderDetails(orderId);
    if (details == null) {
      throw StateError('A OS selecionada nao foi encontrada.');
    }

    return _pdfService.exportOrder(details);
  }

  Future<Uint8List> _exportBudgetPdf(int orderId) async {
    final details = await _getOrderDetails(orderId);
    if (details == null) {
      throw StateError('A OS selecionada nao foi encontrada.');
    }

    return _pdfService.exportBudget(details);
  }

  Future<void> _deleteDraftOrder(int orderId) async {
    final database = await _databaseService.database;
    await database.transaction((transaction) async {
      final rows = await transaction.query(
        'service_orders',
        columns: ['id', 'is_draft'],
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return;
      }
      if ((rows.first['is_draft'] as num?)?.toInt() != 1) {
        return;
      }
      await transaction.delete(
        'service_orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  String _buildCustomerAddress(ServiceOrderCustomerDraft draft) {
    final legacyAddress = draft.address.trim();
    if (legacyAddress.isNotEmpty) {
      return legacyAddress;
    }

    final firstLineParts = <String>[
      draft.street.trim(),
      draft.streetNumber.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (draft.complement.trim().isNotEmpty) {
      firstLineParts.add(draft.complement.trim());
    }

    final lines = <String>[
      if (firstLineParts.isNotEmpty) firstLineParts.join(', '),
      if (draft.neighborhood.trim().isNotEmpty) draft.neighborhood.trim(),
      if (draft.zipCode.trim().isNotEmpty ||
          draft.country.trim().isNotEmpty) ...[
        [
          if (draft.zipCode.trim().isNotEmpty) 'CEP ${draft.zipCode.trim()}',
          if (draft.country.trim().isNotEmpty) draft.country.trim(),
        ].join(' - '),
      ],
      if (draft.city.trim().isNotEmpty || draft.stateCode.trim().isNotEmpty)
        [
          draft.city.trim(),
          draft.stateCode.trim(),
        ].where((part) => part.isNotEmpty).join(', '),
    ];

    return lines.join('\n').trim();
  }
}
