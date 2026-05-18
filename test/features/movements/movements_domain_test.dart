import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/features/movements/domain/movements.dart';

void main() {
  group('MovementTypeValue', () {
    test('maps labels, storage values and fallback correctly', () {
      expect(MovementType.entry.storageValue, 'entry');
      expect(MovementType.exit.storageValue, 'exit');
      expect(MovementType.adjustment.storageValue, 'adjustment');

      expect(MovementType.entry.label, 'Entrada');
      expect(MovementType.exit.label, 'Saida');
      expect(MovementType.adjustment.label, 'Ajuste');

      expect(MovementTypeValue.fromStorageValue('entry'), MovementType.entry);
      expect(MovementTypeValue.fromStorageValue('exit'), MovementType.exit);
      expect(
        MovementTypeValue.fromStorageValue('adjustment'),
        MovementType.adjustment,
      );
      expect(
        MovementTypeValue.fromStorageValue('desconhecido'),
        MovementType.adjustment,
      );
    });
  });

  group('InventoryMovement', () {
    test('signedQuantity respects movement type', () {
      final entry = InventoryMovement(
        id: 1,
        itemId: 10,
        itemName: 'Mouse',
        itemSku: 'MOU-001',
        type: MovementType.entry,
        quantity: 2,
        note: '',
        createdAt: DateTime(2026, 1, 1),
      );
      final exit = InventoryMovement(
        id: 2,
        itemId: 10,
        itemName: 'Mouse',
        itemSku: 'MOU-001',
        type: MovementType.exit,
        quantity: 2,
        note: '',
        createdAt: DateTime(2026, 1, 1),
      );
      final adjustment = InventoryMovement(
        id: 3,
        itemId: 10,
        itemName: 'Mouse',
        itemSku: 'MOU-001',
        type: MovementType.adjustment,
        quantity: -2,
        note: '',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(entry.signedQuantity, 2);
      expect(exit.signedQuantity, -2);
      expect(adjustment.signedQuantity, -2);
    });
  });

  group('InventoryMovementDraft', () {
    test('validate rejects invalid item', () {
      final draft = InventoryMovementDraft(
        itemId: 0,
        type: MovementType.entry,
        quantity: 1,
        note: '',
      );

      expect(
        draft.validate,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Selecione um item para movimentar.',
          ),
        ),
      );
    });

    test('validate rejects zero/negative values for entry and exit', () {
      final entry = InventoryMovementDraft(
        itemId: 1,
        type: MovementType.entry,
        quantity: 0,
        note: '',
      );
      final exit = InventoryMovementDraft(
        itemId: 1,
        type: MovementType.exit,
        quantity: -1,
        note: '',
      );

      expect(
        entry.validate,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'A quantidade precisa ser maior que zero.',
          ),
        ),
      );
      expect(
        exit.validate,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'A quantidade precisa ser maior que zero.',
          ),
        ),
      );
    });

    test('validate requires non-zero quantity for adjustment', () {
      final adjustmentZero = InventoryMovementDraft(
        itemId: 1,
        type: MovementType.adjustment,
        quantity: 0,
        note: '',
      );
      final adjustmentValid = InventoryMovementDraft(
        itemId: 1,
        type: MovementType.adjustment,
        quantity: -2,
        note: '',
      );

      expect(
        adjustmentZero.validate,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Informe um ajuste diferente de zero.',
          ),
        ),
      );
      expect(adjustmentValid.validate, returnsNormally);
    });
  });
}
