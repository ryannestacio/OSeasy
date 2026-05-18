enum MovementType { entry, exit, adjustment }

extension MovementTypeValue on MovementType {
  String get storageValue => switch (this) {
    MovementType.entry => 'entry',
    MovementType.exit => 'exit',
    MovementType.adjustment => 'adjustment',
  };

  String get label => switch (this) {
    MovementType.entry => 'Entrada',
    MovementType.exit => 'Saida',
    MovementType.adjustment => 'Ajuste',
  };

  static MovementType fromStorageValue(String value) => switch (value) {
    'entry' => MovementType.entry,
    'exit' => MovementType.exit,
    'adjustment' => MovementType.adjustment,
    _ => MovementType.adjustment,
  };
}

class InventoryMovement {
  const InventoryMovement({
    this.id,
    required this.itemId,
    required this.itemName,
    required this.itemSku,
    required this.type,
    required this.quantity,
    required this.note,
    required this.createdAt,
  });

  final int? id;
  final int itemId;
  final String itemName;
  final String itemSku;
  final MovementType type;
  final double quantity;
  final String note;
  final DateTime createdAt;

  double get signedQuantity => switch (type) {
    MovementType.entry => quantity,
    MovementType.exit => -quantity,
    MovementType.adjustment => quantity,
  };
}

class InventoryMovementDraft {
  const InventoryMovementDraft({
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.note,
  });

  final int itemId;
  final MovementType type;
  final double quantity;
  final String note;

  void validate() {
    if (itemId <= 0) {
      throw StateError('Selecione um item para movimentar.');
    }

    if (type == MovementType.adjustment) {
      if (quantity == 0) {
        throw StateError('Informe um ajuste diferente de zero.');
      }
    } else if (quantity <= 0) {
      throw StateError('A quantidade precisa ser maior que zero.');
    }
  }
}

abstract class MovementsRepository {
  Future<List<InventoryMovement>> getMovements({int limit = 100});

  Future<InventoryMovement> createMovement(InventoryMovementDraft draft);
}

class GetMovementsUseCase {
  const GetMovementsUseCase(this._repository);

  final MovementsRepository _repository;

  Future<List<InventoryMovement>> call({int limit = 100}) {
    return _repository.getMovements(limit: limit);
  }
}

class CreateMovementUseCase {
  const CreateMovementUseCase(this._repository);

  final MovementsRepository _repository;

  Future<InventoryMovement> call(InventoryMovementDraft draft) {
    return _repository.createMovement(draft);
  }
}
