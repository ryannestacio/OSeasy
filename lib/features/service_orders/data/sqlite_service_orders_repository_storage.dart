part of 'sqlite_service_orders_repository.dart';

extension _ServiceOrdersRepositoryStorage on SqliteServiceOrdersRepository {
  Future<int> _nextOrderNumber(DatabaseExecutor executor) async {
    final row = (await executor.rawQuery(
      'SELECT COALESCE(MAX(order_number), 0) AS max_order FROM service_orders',
    )).first;
    return _toInt(row['max_order']) + 1;
  }

  Future<void> _replaceServiceLines(
    DatabaseExecutor executor,
    int orderId,
    List<ServiceOrderServiceLineDraft> lines,
  ) async {
    await executor.delete(
      'service_order_services',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      await executor.insert('service_order_services', {
        'order_id': orderId,
        'description': line.description.trim(),
        'service_type': line.serviceType.trim().isEmpty
            ? 'Avulso'
            : line.serviceType.trim(),
        'start_time': line.startTime?.toUtc().toIso8601String(),
        'end_time': line.endTime?.toUtc().toIso8601String(),
        'quantity': line.quantity,
        'unit_price': line.unitPrice,
        'total_price': line.totalPrice,
        'technician_id': line.technicianId,
        'technician_name': line.technicianName.trim(),
        'sort_order': index,
      });
    }
  }

  Future<void> _replacePartLines(
    DatabaseExecutor executor,
    int orderId,
    List<ServiceOrderPartLineDraft> lines,
    Map<int, bool> movementFlagById,
  ) async {
    await executor.delete(
      'service_order_parts',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final stockMovementApplied = line.id == null
          ? false
          : (movementFlagById[line.id!] ?? false);

      await executor.insert('service_order_parts', {
        'order_id': orderId,
        'item_id': line.origin == ServiceOrderPartOrigin.stock
            ? line.itemId
            : null,
        'part_name': line.partName.trim(),
        'origin': line.origin.storageValue,
        'quantity': line.quantity,
        'unit_price': line.unitPrice,
        'total_price': line.totalPrice,
        'technician_id': line.technicianId,
        'technician_name': line.technicianName.trim(),
        'stock_movement_applied': stockMovementApplied ? 1 : 0,
        'sort_order': index,
      });
    }
  }

  Future<void> _replaceAttachments(
    DatabaseExecutor executor,
    int orderId,
    List<ServiceOrderAttachmentDraft> attachments,
  ) async {
    await executor.delete(
      'service_order_attachments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    for (final attachment in attachments) {
      await executor.insert('service_order_attachments', {
        'order_id': orderId,
        'file_path': attachment.filePath,
        'file_name': attachment.fileName,
        'created_at': attachment.createdAt.toUtc().toIso8601String(),
        'created_by': attachment.createdBy,
      });
    }
  }

  Future<Map<String, Object?>> _loadCustomerRow(
    DatabaseExecutor executor,
    int customerId,
  ) async {
    final rows = await executor.query(
      'customers',
      columns: ['id', 'name', 'document', 'phone', 'email', 'address'],
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('Cliente selecionado nao encontrado.');
    }

    return rows.first;
  }

  Future<void> _insertHistory(
    DatabaseExecutor executor, {
    required int orderId,
    required String eventType,
    required ServiceOrderStatus? fromStatus,
    required ServiceOrderStatus? toStatus,
    required String message,
    required String actor,
  }) async {
    await executor.insert('service_order_history', {
      'order_id': orderId,
      'event_type': eventType,
      'from_status': fromStatus?.storageValue,
      'to_status': toStatus?.storageValue,
      'message': message.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'created_by': actor.trim().isEmpty ? 'Sistema' : actor.trim(),
    });
  }

  Future<ServiceOrderDetails> _loadDetails(
    DatabaseExecutor executor,
    int orderId,
  ) async {
    final orderRows = await executor.query(
      'service_orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (orderRows.isEmpty) {
      throw StateError('A OS selecionada nao foi encontrada.');
    }

    final serviceRows = await executor.query(
      'service_order_services',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'sort_order ASC, id ASC',
    );

    final partRows = await executor.query(
      'service_order_parts',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'sort_order ASC, id ASC',
    );

    final attachmentRows = await executor.query(
      'service_order_attachments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC, id DESC',
    );

    final historyRows = await executor.query(
      'service_order_history',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC, id DESC',
    );

    return _mapDetails(
      orderRows.first,
      serviceRows,
      partRows,
      attachmentRows,
      historyRows,
    );
  }
}
