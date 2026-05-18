part of 'sqlite_service_orders_repository.dart';

extension _ServiceOrdersRepositoryQueries on SqliteServiceOrdersRepository {
  Future<ServiceOrderLookupData> _getLookupData({int? customerId}) async {
    final database = await _databaseService.database;

    final customerRows = await database.query(
      'customers',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final equipmentRows = await database.query(
      'equipments',
      where: customerId == null
          ? 'is_active = 1'
          : 'is_active = 1 AND customer_id = ?',
      whereArgs: customerId == null ? null : [customerId],
      orderBy: 'model COLLATE NOCASE ASC',
    );

    final technicianRows = await database.query(
      'technicians',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final itemRows = await database.query(
      'items',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return ServiceOrderLookupData(
      customers: customerRows.map(_mapCustomer).toList(),
      equipments: equipmentRows.map(_mapEquipment).toList(),
      technicians: technicianRows.map(_mapTechnician).toList(),
      stockItems: itemRows.map(_mapInventoryItem).toList(),
    );
  }

  Future<List<ServiceOrderSummary>> _getOrders({
    ServiceOrderFilter filter = const ServiceOrderFilter(),
  }) async {
    final database = await _databaseService.database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    final query = filter.query.trim();
    if (query.isNotEmpty) {
      final parsedNumber = int.tryParse(query);
      if (parsedNumber != null) {
        whereClauses.add(
          '(order_number = ? OR customer_name LIKE ? OR equipment_model LIKE ? OR responsible_technician_name LIKE ?)',
        );
        whereArgs.add(parsedNumber);
        whereArgs.addAll(['%$query%', '%$query%', '%$query%']);
      } else {
        whereClauses.add(
          '(customer_name LIKE ? OR equipment_model LIKE ? OR situation_note LIKE ? OR responsible_technician_name LIKE ?)',
        );
        whereArgs.addAll(['%$query%', '%$query%', '%$query%', '%$query%']);
      }
    }

    whereClauses.add('is_draft = 0');

    if (filter.customerId != null) {
      whereClauses.add('customer_id = ?');
      whereArgs.add(filter.customerId);
    }
    if (filter.equipmentId != null) {
      whereClauses.add('equipment_id = ?');
      whereArgs.add(filter.equipmentId);
    }
    if (filter.technicianId != null) {
      whereClauses.add('responsible_technician_id = ?');
      whereArgs.add(filter.technicianId);
    }
    if (filter.status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(filter.status!.storageValue);
    }
    if (filter.priority != null) {
      whereClauses.add('priority = ?');
      whereArgs.add(filter.priority!.storageValue);
    }

    _appendDateRange(
      whereClauses: whereClauses,
      whereArgs: whereArgs,
      column: 'entry_at',
      from: filter.entryFrom,
      to: filter.entryTo,
    );
    _appendDateRange(
      whereClauses: whereClauses,
      whereArgs: whereArgs,
      column: 'ready_at',
      from: filter.readyFrom,
      to: filter.readyTo,
    );
    _appendDateRange(
      whereClauses: whereClauses,
      whereArgs: whereArgs,
      column: 'exit_at',
      from: filter.exitFrom,
      to: filter.exitTo,
    );

    final rows = await database.query(
      'service_orders',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy:
          "CASE status WHEN 'open' THEN 0 WHEN 'in_progress' THEN 1 WHEN 'ready' THEN 2 ELSE 3 END, entry_at DESC, order_number DESC",
    );

    return rows.map(_mapSummary).toList();
  }
}
