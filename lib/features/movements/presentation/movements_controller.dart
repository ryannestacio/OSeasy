import 'package:flutter/foundation.dart';

import '../../items/domain/items.dart';
import '../domain/movements.dart';

class MovementsController extends ChangeNotifier {
  MovementsController({
    required GetMovementsUseCase getMovementsUseCase,
    required CreateMovementUseCase createMovementUseCase,
    required GetItemsUseCase getItemsUseCase,
  }) : _getMovementsUseCase = getMovementsUseCase,
       _createMovementUseCase = createMovementUseCase,
       _getItemsUseCase = getItemsUseCase;

  final GetMovementsUseCase _getMovementsUseCase;
  final CreateMovementUseCase _createMovementUseCase;
  final GetItemsUseCase _getItemsUseCase;

  List<InventoryMovement> _movements = const [];
  List<InventoryItem> _availableItems = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InventoryMovement> get movements => _movements;
  List<InventoryItem> get availableItems => _availableItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final movementsFuture = _getMovementsUseCase(limit: 150);
      final activeItemsFuture = _getItemsUseCase(
        status: ItemStatusFilter.active,
      );

      _movements = await movementsFuture;
      _availableItems = await activeItemsFuture;
    } catch (error) {
      _errorMessage = _humanizeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMovement(InventoryMovementDraft draft) async {
    await _createMovementUseCase(draft);
    await loadData();
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel carregar as movimentacoes.';
  }
}
