import 'package:flutter/foundation.dart';

import '../domain/stock_counts.dart';

class CountsController extends ChangeNotifier {
  CountsController({
    required GetStockCountsUseCase getStockCountsUseCase,
    required GetStockCountDetailsUseCase getStockCountDetailsUseCase,
    required CreateStockCountUseCase createStockCountUseCase,
    required UpdateStockCountLineUseCase updateStockCountLineUseCase,
    required SetStockCountLineSelectionUseCase
    setStockCountLineSelectionUseCase,
    required CloseStockCountUseCase closeStockCountUseCase,
    required ExportStockCountWorksheetPdfUseCase
    exportStockCountWorksheetPdfUseCase,
    required ExportStockCountResultPdfUseCase exportStockCountResultPdfUseCase,
  }) : _getStockCountsUseCase = getStockCountsUseCase,
       _getStockCountDetailsUseCase = getStockCountDetailsUseCase,
       _createStockCountUseCase = createStockCountUseCase,
       _updateStockCountLineUseCase = updateStockCountLineUseCase,
       _setStockCountLineSelectionUseCase = setStockCountLineSelectionUseCase,
       _closeStockCountUseCase = closeStockCountUseCase,
       _exportStockCountWorksheetPdfUseCase =
           exportStockCountWorksheetPdfUseCase,
       _exportStockCountResultPdfUseCase = exportStockCountResultPdfUseCase;

  final GetStockCountsUseCase _getStockCountsUseCase;
  final GetStockCountDetailsUseCase _getStockCountDetailsUseCase;
  final CreateStockCountUseCase _createStockCountUseCase;
  final UpdateStockCountLineUseCase _updateStockCountLineUseCase;
  final SetStockCountLineSelectionUseCase _setStockCountLineSelectionUseCase;
  final CloseStockCountUseCase _closeStockCountUseCase;
  final ExportStockCountWorksheetPdfUseCase
  _exportStockCountWorksheetPdfUseCase;
  final ExportStockCountResultPdfUseCase _exportStockCountResultPdfUseCase;

  List<StockCountSession> _counts = const [];
  StockCountDetails? _selectedDetails;
  int? _selectedCountId;
  String _lineSearchQuery = '';
  StockCountLineFilter _lineFilter = StockCountLineFilter.all;
  bool _isLoading = false;
  bool _isBusy = false;
  String? _errorMessage;

  List<StockCountSession> get counts => _counts;
  StockCountDetails? get selectedDetails => _selectedDetails;
  StockCountSession? get selectedSession => _selectedDetails?.session;
  int? get selectedCountId => _selectedCountId;
  String get lineSearchQuery => _lineSearchQuery;
  StockCountLineFilter get lineFilter => _lineFilter;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  List<StockCountLine> get filteredLines {
    final details = _selectedDetails;
    if (details == null) {
      return const [];
    }

    final query = _lineSearchQuery.trim().toLowerCase();

    return details.lines.where((line) {
      final matchesFilter = switch (_lineFilter) {
        StockCountLineFilter.all => true,
        StockCountLineFilter.pending =>
          line.status == StockCountLineStatus.pending,
        StockCountLineFilter.counted =>
          line.status == StockCountLineStatus.counted,
        StockCountLineFilter.divergent =>
          line.status == StockCountLineStatus.divergent,
        StockCountLineFilter.selected => line.selectedForExport,
      };

      if (!matchesFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        line.itemName,
        line.itemSku,
        line.category,
        line.unit,
        line.lineNote,
        line.countedBy ?? '',
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  Future<void> loadData({int? selectCountId}) async {
    _isLoading = true;
    _errorMessage = null;
    if (selectCountId != null) {
      _selectedCountId = selectCountId;
    }
    notifyListeners();

    try {
      final counts = await _getStockCountsUseCase();
      final resolvedId = _resolveSelectedCountId(counts, _selectedCountId);
      final details = resolvedId == null
          ? null
          : await _getStockCountDetailsUseCase(resolvedId);

      _counts = counts;
      _selectedCountId = resolvedId;
      _selectedDetails = details;
    } catch (error) {
      _errorMessage = _humanizeError(
        error,
        fallback: 'Nao foi possivel carregar as contagens.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCount(int countId) async {
    if (_selectedCountId == countId && _selectedDetails != null) {
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final details = await _getStockCountDetailsUseCase(countId);
      if (details == null) {
        throw StateError('A contagem selecionada nao foi encontrada.');
      }

      _selectedCountId = countId;
      _selectedDetails = details;
    } catch (error) {
      _errorMessage = _humanizeError(
        error,
        fallback: 'Nao foi possivel abrir a contagem.',
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> createCount(CreateStockCountDraft draft) async {
    await _runMutation(() async {
      final details = await _createStockCountUseCase(draft);
      await _syncFromDetails(details);
    });
  }

  Future<void> updateLine(int lineId, UpdateStockCountLineDraft draft) async {
    await _runMutation(() async {
      final details = await _updateStockCountLineUseCase(lineId, draft);
      await _syncFromDetails(details);
    });
  }

  Future<void> setLineSelection(int lineId, bool selected) async {
    await _runMutation(() async {
      final details = await _setStockCountLineSelectionUseCase(
        lineId,
        selected,
      );
      await _syncFromDetails(details);
    });
  }

  Future<void> closeCount(CloseStockCountDraft draft) async {
    final countId = _selectedCountId;
    if (countId == null) {
      throw StateError('Selecione uma contagem antes de fechar.');
    }

    await _runMutation(() async {
      final details = await _closeStockCountUseCase(countId, draft);
      await _syncFromDetails(details);
    });
  }

  Future<String?> exportWorksheetPdf() async {
    final countId = _selectedCountId;
    if (countId == null) {
      throw StateError('Selecione uma contagem para exportar.');
    }

    return _runBusyAction(
      () => _exportStockCountWorksheetPdfUseCase(countId),
      fallback: 'Nao foi possivel exportar a folha da contagem.',
    );
  }

  Future<String?> exportResultPdf() async {
    final countId = _selectedCountId;
    if (countId == null) {
      throw StateError('Selecione uma contagem para exportar.');
    }

    return _runBusyAction(
      () => _exportStockCountResultPdfUseCase(countId),
      fallback: 'Nao foi possivel exportar o resultado da contagem.',
    );
  }

  void setLineSearchQuery(String value) {
    _lineSearchQuery = value;
    notifyListeners();
  }

  void setLineFilter(StockCountLineFilter value) {
    _lineFilter = value;
    notifyListeners();
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      throw StateError(
        _humanizeError(
          error,
          fallback: 'Nao foi possivel concluir a operacao na contagem.',
        ),
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<T> _runBusyAction<T>(
    Future<T> Function() action, {
    required String fallback,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      return await action();
    } catch (error) {
      throw StateError(_humanizeError(error, fallback: fallback));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromDetails(StockCountDetails details) async {
    _counts = await _getStockCountsUseCase();
    _selectedCountId = details.session.id;
    _selectedDetails = details;
  }

  int? _resolveSelectedCountId(
    List<StockCountSession> counts,
    int? preferredId,
  ) {
    if (counts.isEmpty) {
      return null;
    }

    if (preferredId != null && counts.any((count) => count.id == preferredId)) {
      return preferredId;
    }

    for (final count in counts) {
      if (count.isOpen) {
        return count.id;
      }
    }

    return counts.first.id;
  }

  String _humanizeError(Object error, {required String fallback}) {
    if (error is StateError) {
      return error.message;
    }
    return fallback;
  }
}
