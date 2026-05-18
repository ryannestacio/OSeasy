import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/local_database_service.dart';
import '../domain/stock_counts.dart';
import 'stock_count_pdf_service.dart';

class SqliteStockCountsRepository implements StockCountsRepository {
  SqliteStockCountsRepository(this._databaseService, this._pdfService);

  final LocalDatabaseService _databaseService;
  final StockCountPdfService _pdfService;

  @override
  Future<StockCountDetails> createCount(CreateStockCountDraft draft) async {
    draft.validate();

    final database = await _databaseService.database;

    return database.transaction((transaction) async {
      final itemRows = await transaction.query(
        'items',
        columns: ['id', 'name', 'sku', 'category', 'unit', 'quantity', 'price'],
        where: 'is_active = 1',
        orderBy: 'name COLLATE NOCASE ASC',
      );

      if (itemRows.isEmpty) {
        throw StateError('Nao ha itens ativos para abrir uma contagem.');
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final name = draft.name.trim().isEmpty
          ? 'Contagem ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
          : draft.name.trim();

      final countId = await transaction.insert('stock_counts', {
        'name': name,
        'status': StockCountSessionStatus.open.storageValue,
        'opened_by': draft.openedBy.trim(),
        'opened_at': now,
        'notes': draft.notes.trim(),
        'blind_mode': draft.blindMode ? 1 : 0,
        'total_items': itemRows.length,
        'counted_items': 0,
        'divergent_items': 0,
        'selected_items': itemRows.length,
      });

      for (var index = 0; index < itemRows.length; index++) {
        final row = itemRows[index];
        await transaction.insert('stock_count_lines', {
          'count_id': countId,
          'item_id': row['id'],
          'item_name': row['name'] as String? ?? '',
          'item_sku': row['sku'] as String? ?? '',
          'category': row['category'] as String? ?? '',
          'unit': row['unit'] as String? ?? '',
          'system_quantity': _toDouble(row['quantity']),
          'unit_cost': _toDouble(row['price']),
          'selected_for_export': 1,
          'line_status': StockCountLineStatus.pending.storageValue,
          'sort_order': index,
        });
      }

      return _loadDetails(transaction, countId);
    });
  }

  @override
  Future<StockCountDetails?> getCountDetails(int countId) async {
    final database = await _databaseService.database;
    final rows = await database.query(
      'stock_counts',
      where: 'id = ?',
      whereArgs: [countId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return _loadDetails(database, countId);
  }

  @override
  Future<List<StockCountSession>> getCounts() async {
    final database = await _databaseService.database;
    final rows = await database.query(
      'stock_counts',
      orderBy: "CASE status WHEN 'open' THEN 0 ELSE 1 END, opened_at DESC",
    );
    return rows.map(_mapSession).toList();
  }

  @override
  Future<StockCountDetails> updateLine(
    int lineId,
    UpdateStockCountLineDraft draft,
  ) async {
    draft.validate();

    final database = await _databaseService.database;
    return database.transaction((transaction) async {
      final lineRows = await transaction.query(
        'stock_count_lines',
        columns: ['id', 'count_id', 'system_quantity'],
        where: 'id = ?',
        whereArgs: [lineId],
        limit: 1,
      );
      if (lineRows.isEmpty) {
        throw StateError('A linha da contagem nao foi encontrada.');
      }

      final line = lineRows.first;
      final countId = line['count_id'] as int;
      await _ensureCountIsOpen(transaction, countId);

      final systemQuantity = _toDouble(line['system_quantity']);
      final difference = draft.countedQuantity - systemQuantity;
      final status = difference.abs() < 0.000001
          ? StockCountLineStatus.counted
          : StockCountLineStatus.divergent;
      final now = DateTime.now().toUtc().toIso8601String();

      await transaction.update(
        'stock_count_lines',
        {
          'counted_quantity': draft.countedQuantity,
          'difference': difference,
          'line_note': draft.note.trim(),
          'counted_by': draft.countedBy.trim(),
          'counted_at': now,
          'selected_for_export': draft.selectedForExport ? 1 : 0,
          'line_status': status.storageValue,
        },
        where: 'id = ?',
        whereArgs: [lineId],
      );

      await _refreshCountTotals(transaction, countId);
      return _loadDetails(transaction, countId);
    });
  }

  @override
  Future<StockCountDetails> setLineSelection(int lineId, bool selected) async {
    final database = await _databaseService.database;
    return database.transaction((transaction) async {
      final lineRows = await transaction.query(
        'stock_count_lines',
        columns: ['id', 'count_id'],
        where: 'id = ?',
        whereArgs: [lineId],
        limit: 1,
      );
      if (lineRows.isEmpty) {
        throw StateError('A linha da contagem nao foi encontrada.');
      }

      final countId = lineRows.first['count_id'] as int;
      await transaction.update(
        'stock_count_lines',
        {'selected_for_export': selected ? 1 : 0},
        where: 'id = ?',
        whereArgs: [lineId],
      );
      await _refreshCountTotals(transaction, countId);
      return _loadDetails(transaction, countId);
    });
  }

  @override
  Future<StockCountDetails> closeCount(
    int countId,
    CloseStockCountDraft draft,
  ) async {
    draft.validate();

    final database = await _databaseService.database;
    return database.transaction((transaction) async {
      final details = await _loadDetails(transaction, countId);
      if (!details.session.isOpen) {
        throw StateError('Esta contagem ja foi encerrada.');
      }
      if (details.session.pendingItems > 0) {
        throw StateError('Conte todos os itens antes de fechar a contagem.');
      }

      final now = DateTime.now().toUtc().toIso8601String();
      await transaction.update(
        'stock_counts',
        {
          'status': StockCountSessionStatus.closed.storageValue,
          'closed_by': draft.closedBy.trim(),
          'closed_at': now,
          'closing_notes': draft.notes.trim(),
        },
        where: 'id = ?',
        whereArgs: [countId],
      );

      return _loadDetails(transaction, countId);
    });
  }

  @override
  Future<String?> exportResultPdf(int countId) async {
    final details = await getCountDetails(countId);
    if (details == null) {
      throw StateError('A contagem selecionada nao foi encontrada.');
    }
    return _pdfService.exportResult(details);
  }

  @override
  Future<String?> exportWorksheetPdf(int countId) async {
    final details = await getCountDetails(countId);
    if (details == null) {
      throw StateError('A contagem selecionada nao foi encontrada.');
    }
    return _pdfService.exportWorksheet(details);
  }

  Future<void> _ensureCountIsOpen(
    DatabaseExecutor executor,
    int countId,
  ) async {
    final rows = await executor.query(
      'stock_counts',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [countId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('A contagem selecionada nao foi encontrada.');
    }
    final status = StockCountSessionStatusView.fromStorageValue(
      rows.first['status'] as String? ?? '',
    );
    if (status != StockCountSessionStatus.open) {
      throw StateError('Somente contagens abertas podem ser alteradas.');
    }
  }

  Future<void> _refreshCountTotals(
    DatabaseExecutor executor,
    int countId,
  ) async {
    final totalsRow = (await executor.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_items,
        SUM(CASE WHEN line_status != 'pending' THEN 1 ELSE 0 END) AS counted_items,
        SUM(CASE WHEN line_status = 'divergent' THEN 1 ELSE 0 END) AS divergent_items,
        SUM(CASE WHEN selected_for_export = 1 THEN 1 ELSE 0 END) AS selected_items
      FROM stock_count_lines
      WHERE count_id = ?
      ''',
      [countId],
    )).first;

    await executor.update(
      'stock_counts',
      {
        'total_items': _toInt(totalsRow['total_items']),
        'counted_items': _toInt(totalsRow['counted_items']),
        'divergent_items': _toInt(totalsRow['divergent_items']),
        'selected_items': _toInt(totalsRow['selected_items']),
      },
      where: 'id = ?',
      whereArgs: [countId],
    );
  }

  Future<StockCountDetails> _loadDetails(
    DatabaseExecutor executor,
    int countId,
  ) async {
    final countRows = await executor.query(
      'stock_counts',
      where: 'id = ?',
      whereArgs: [countId],
      limit: 1,
    );
    if (countRows.isEmpty) {
      throw StateError('A contagem selecionada nao foi encontrada.');
    }

    final lineRows = await executor.query(
      'stock_count_lines',
      where: 'count_id = ?',
      whereArgs: [countId],
      orderBy: 'sort_order ASC, item_name COLLATE NOCASE ASC',
    );

    return StockCountDetails(
      session: _mapSession(countRows.first),
      lines: lineRows.map(_mapLine).toList(),
    );
  }

  StockCountSession _mapSession(Map<String, Object?> row) {
    return StockCountSession(
      id: row['id'] as int,
      name: row['name'] as String? ?? '',
      status: StockCountSessionStatusView.fromStorageValue(
        row['status'] as String? ?? '',
      ),
      openedBy: row['opened_by'] as String? ?? '',
      closedBy: row['closed_by'] as String?,
      openedAt: _parseDateTime(row['opened_at']) ?? DateTime.now(),
      closedAt: (row['closed_at'] as String?) == null
          ? null
          : _parseDateTime(row['closed_at']),
      notes: row['notes'] as String? ?? '',
      closingNotes: row['closing_notes'] as String? ?? '',
      blindMode: (row['blind_mode'] as num?)?.toInt() == 1,
      totalItems: _toInt(row['total_items']),
      countedItems: _toInt(row['counted_items']),
      divergentItems: _toInt(row['divergent_items']),
      selectedItems: _toInt(row['selected_items']),
    );
  }

  StockCountLine _mapLine(Map<String, Object?> row) {
    return StockCountLine(
      id: row['id'] as int,
      countId: row['count_id'] as int,
      itemId: row['item_id'] as int?,
      itemName: row['item_name'] as String? ?? '',
      itemSku: row['item_sku'] as String? ?? '',
      category: row['category'] as String? ?? '',
      unit: row['unit'] as String? ?? '',
      systemQuantity: _toDouble(row['system_quantity']),
      countedQuantity: row['counted_quantity'] == null
          ? null
          : _toDouble(row['counted_quantity']),
      difference: row['difference'] == null
          ? null
          : _toDouble(row['difference']),
      unitCost: _toDouble(row['unit_cost']),
      selectedForExport: (row['selected_for_export'] as num?)?.toInt() == 1,
      lineNote: row['line_note'] as String? ?? '',
      countedBy: row['counted_by'] as String?,
      countedAt: (row['counted_at'] as String?) == null
          ? null
          : _parseDateTime(row['counted_at']),
      status: StockCountLineStatusView.fromStorageValue(
        row['line_status'] as String? ?? '',
      ),
      sortOrder: _toInt(row['sort_order']),
    );
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
}
