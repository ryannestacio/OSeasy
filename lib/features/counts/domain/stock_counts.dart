enum StockCountSessionStatus { open, closed }

enum StockCountLineStatus { pending, counted, divergent }

enum StockCountLineFilter { all, pending, counted, divergent, selected }

extension StockCountSessionStatusView on StockCountSessionStatus {
  String get storageValue => switch (this) {
    StockCountSessionStatus.open => 'open',
    StockCountSessionStatus.closed => 'closed',
  };

  String get label => switch (this) {
    StockCountSessionStatus.open => 'Aberta',
    StockCountSessionStatus.closed => 'Fechada',
  };

  static StockCountSessionStatus fromStorageValue(String value) =>
      switch (value) {
        'closed' => StockCountSessionStatus.closed,
        _ => StockCountSessionStatus.open,
      };
}

extension StockCountLineStatusView on StockCountLineStatus {
  String get storageValue => switch (this) {
    StockCountLineStatus.pending => 'pending',
    StockCountLineStatus.counted => 'counted',
    StockCountLineStatus.divergent => 'divergent',
  };

  String get label => switch (this) {
    StockCountLineStatus.pending => 'Pendente',
    StockCountLineStatus.counted => 'Conferido',
    StockCountLineStatus.divergent => 'Divergente',
  };

  static StockCountLineStatus fromStorageValue(String value) => switch (value) {
    'counted' => StockCountLineStatus.counted,
    'divergent' => StockCountLineStatus.divergent,
    _ => StockCountLineStatus.pending,
  };
}

extension StockCountLineFilterView on StockCountLineFilter {
  String get label => switch (this) {
    StockCountLineFilter.all => 'Todos',
    StockCountLineFilter.pending => 'Pendentes',
    StockCountLineFilter.counted => 'Conferidos',
    StockCountLineFilter.divergent => 'Divergentes',
    StockCountLineFilter.selected => 'Selecionados para PDF',
  };
}

class StockCountSession {
  const StockCountSession({
    this.id,
    required this.name,
    required this.status,
    required this.openedBy,
    required this.closedBy,
    required this.openedAt,
    required this.closedAt,
    required this.notes,
    required this.closingNotes,
    required this.blindMode,
    required this.totalItems,
    required this.countedItems,
    required this.divergentItems,
    required this.selectedItems,
  });

  final int? id;
  final String name;
  final StockCountSessionStatus status;
  final String openedBy;
  final String? closedBy;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String notes;
  final String closingNotes;
  final bool blindMode;
  final int totalItems;
  final int countedItems;
  final int divergentItems;
  final int selectedItems;

  bool get isOpen => status == StockCountSessionStatus.open;
  int get pendingItems => totalItems - countedItems;
  double get completionRate => totalItems == 0 ? 0 : countedItems / totalItems;
}

class StockCountLine {
  const StockCountLine({
    this.id,
    required this.countId,
    required this.itemId,
    required this.itemName,
    required this.itemSku,
    required this.category,
    required this.unit,
    required this.systemQuantity,
    required this.countedQuantity,
    required this.difference,
    required this.unitCost,
    required this.selectedForExport,
    required this.lineNote,
    required this.countedBy,
    required this.countedAt,
    required this.status,
    required this.sortOrder,
  });

  final int? id;
  final int countId;
  final int? itemId;
  final String itemName;
  final String itemSku;
  final String category;
  final String unit;
  final double systemQuantity;
  final double? countedQuantity;
  final double? difference;
  final double unitCost;
  final bool selectedForExport;
  final String lineNote;
  final String? countedBy;
  final DateTime? countedAt;
  final StockCountLineStatus status;
  final int sortOrder;

  bool get isPending => status == StockCountLineStatus.pending;
  bool get isDivergent => status == StockCountLineStatus.divergent;
  bool get isCounted => !isPending;
  double get divergenceValue => (difference ?? 0) * unitCost;
}

class StockCountDetails {
  const StockCountDetails({required this.session, required this.lines});

  final StockCountSession session;
  final List<StockCountLine> lines;
}

class CreateStockCountDraft {
  const CreateStockCountDraft({
    required this.name,
    required this.openedBy,
    required this.notes,
    required this.blindMode,
  });

  final String name;
  final String openedBy;
  final String notes;
  final bool blindMode;

  void validate() {
    if (openedBy.trim().isEmpty) {
      throw StateError('Informe quem iniciou a contagem.');
    }
  }
}

class UpdateStockCountLineDraft {
  const UpdateStockCountLineDraft({
    required this.countedQuantity,
    required this.countedBy,
    required this.note,
    required this.selectedForExport,
  });

  final double countedQuantity;
  final String countedBy;
  final String note;
  final bool selectedForExport;

  void validate() {
    if (countedQuantity < 0) {
      throw StateError('A quantidade contada nao pode ser negativa.');
    }
    if (countedBy.trim().isEmpty) {
      throw StateError('Informe quem realizou a contagem do item.');
    }
  }
}

class CloseStockCountDraft {
  const CloseStockCountDraft({required this.closedBy, required this.notes});

  final String closedBy;
  final String notes;

  void validate() {
    if (closedBy.trim().isEmpty) {
      throw StateError('Informe quem encerrou a contagem.');
    }
  }
}

abstract class StockCountsRepository {
  Future<List<StockCountSession>> getCounts();

  Future<StockCountDetails?> getCountDetails(int countId);

  Future<StockCountDetails> createCount(CreateStockCountDraft draft);

  Future<StockCountDetails> updateLine(
    int lineId,
    UpdateStockCountLineDraft draft,
  );

  Future<StockCountDetails> setLineSelection(int lineId, bool selected);

  Future<StockCountDetails> closeCount(int countId, CloseStockCountDraft draft);

  Future<String?> exportWorksheetPdf(int countId);

  Future<String?> exportResultPdf(int countId);
}

class GetStockCountsUseCase {
  const GetStockCountsUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<List<StockCountSession>> call() => _repository.getCounts();
}

class GetStockCountDetailsUseCase {
  const GetStockCountDetailsUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<StockCountDetails?> call(int countId) =>
      _repository.getCountDetails(countId);
}

class CreateStockCountUseCase {
  const CreateStockCountUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<StockCountDetails> call(CreateStockCountDraft draft) =>
      _repository.createCount(draft);
}

class UpdateStockCountLineUseCase {
  const UpdateStockCountLineUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<StockCountDetails> call(int lineId, UpdateStockCountLineDraft draft) {
    return _repository.updateLine(lineId, draft);
  }
}

class SetStockCountLineSelectionUseCase {
  const SetStockCountLineSelectionUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<StockCountDetails> call(int lineId, bool selected) {
    return _repository.setLineSelection(lineId, selected);
  }
}

class CloseStockCountUseCase {
  const CloseStockCountUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<StockCountDetails> call(int countId, CloseStockCountDraft draft) {
    return _repository.closeCount(countId, draft);
  }
}

class ExportStockCountWorksheetPdfUseCase {
  const ExportStockCountWorksheetPdfUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<String?> call(int countId) => _repository.exportWorksheetPdf(countId);
}

class ExportStockCountResultPdfUseCase {
  const ExportStockCountResultPdfUseCase(this._repository);

  final StockCountsRepository _repository;

  Future<String?> call(int countId) => _repository.exportResultPdf(countId);
}
