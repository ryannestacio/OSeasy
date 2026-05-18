import 'package:flutter/foundation.dart';

import '../domain/items.dart';

class ItemsController extends ChangeNotifier {
  ItemsController({
    required GetItemsUseCase getItemsUseCase,
    required CreateItemUseCase createItemUseCase,
    required UpdateItemUseCase updateItemUseCase,
    required DeactivateItemUseCase deactivateItemUseCase,
    required ReactivateItemUseCase reactivateItemUseCase,
  }) : _getItemsUseCase = getItemsUseCase,
       _createItemUseCase = createItemUseCase,
       _updateItemUseCase = updateItemUseCase,
       _deactivateItemUseCase = deactivateItemUseCase,
       _reactivateItemUseCase = reactivateItemUseCase;

  final GetItemsUseCase _getItemsUseCase;
  final CreateItemUseCase _createItemUseCase;
  final UpdateItemUseCase _updateItemUseCase;
  final DeactivateItemUseCase _deactivateItemUseCase;
  final ReactivateItemUseCase _reactivateItemUseCase;

  List<InventoryItem> _items = const [];
  bool _isLoading = false;
  String _searchQuery = '';
  ItemStatusFilter _statusFilter = ItemStatusFilter.active;
  String _categoryFilter = '';
  String _unitFilter = '';
  ItemSortOption _sortOption = ItemSortOption.newest;
  String? _errorMessage;

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ItemStatusFilter get statusFilter => _statusFilter;
  String get categoryFilter => _categoryFilter;
  String get unitFilter => _unitFilter;
  ItemSortOption get sortOption => _sortOption;
  List<String> get availableCategories =>
      _collectDistinctValues(_items.map((item) => item.category));
  List<String> get availableUnits =>
      _collectDistinctValues(_items.map((item) => item.unit));
  String? get errorMessage => _errorMessage;

  Future<void> loadItems({
    String? query,
    ItemStatusFilter? status,
    String? category,
    String? unit,
    ItemSortOption? sort,
  }) async {
    if (query != null) {
      _searchQuery = query;
    }
    if (status != null) {
      _statusFilter = status;
    }
    if (category != null) {
      _categoryFilter = category;
    }
    if (unit != null) {
      _unitFilter = unit;
    }
    if (sort != null) {
      _sortOption = sort;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _getItemsUseCase(
        query: _searchQuery,
        status: _statusFilter,
        category: _categoryFilter,
        unit: _unitFilter,
        sort: _sortOption,
      );
    } catch (error) {
      _errorMessage = _humanizeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createItem(InventoryItemDraft draft) async {
    await _createItemUseCase(draft);
    await loadItems();
  }

  Future<void> updateItem(int id, InventoryItemDraft draft) async {
    await _updateItemUseCase(id, draft);
    await loadItems();
  }

  Future<void> deactivateItem(int id) async {
    await _deactivateItemUseCase(id);
    await loadItems();
  }

  Future<void> reactivateItem(int id) async {
    await _reactivateItemUseCase(id);
    await loadItems();
  }

  Future<void> clearFilters() {
    return loadItems(
      query: '',
      status: ItemStatusFilter.active,
      category: '',
      unit: '',
      sort: ItemSortOption.newest,
    );
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel carregar os itens.';
  }

  List<String> _collectDistinctValues(Iterable<String> values) {
    final normalized =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return normalized;
  }
}
