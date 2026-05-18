import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/features/items/domain/items.dart';
import 'package:stokeasy/features/movements/domain/movements.dart';
import 'package:stokeasy/features/movements/presentation/movement_form_dialog.dart';

void main() {
  group('MovementFormDialog', () {
    testWidgets('shows empty-state dialog when there are no items', (
      tester,
    ) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<InventoryMovementDraft>(
        tester,
        const MovementFormDialog(items: []),
      );

      expect(
        find.text('Nao ha itens ativos disponiveis para movimentacao.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(await resultFuture, isNull);
    });

    testWidgets('validates adjustment and returns movement draft', (
      tester,
    ) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<InventoryMovementDraft>(
        tester,
        MovementFormDialog(items: _items),
      );

      await _selectDropdownOption(
        tester,
        currentText: 'Entrada',
        newText: 'Ajuste',
      );

      await tester.enterText(_textFormFieldByLabel('Ajuste de estoque'), '0');
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      expect(find.text('Use um ajuste diferente de zero'), findsOneWidget);

      await tester.enterText(_textFormFieldByLabel('Ajuste de estoque'), '-2');
      await tester.enterText(_textFormFieldByLabel('Observacao'), 'Inventario');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      final draft = await resultFuture;
      expect(draft, isNotNull);
      expect(draft!.itemId, 1);
      expect(draft.type, MovementType.adjustment);
      expect(draft.quantity, -2);
      expect(draft.note, 'Inventario');
    });
  });
}

final _items = <InventoryItem>[
  InventoryItem(
    id: 1,
    name: 'Mouse',
    sku: 'MOU-001',
    category: 'Perifericos',
    unit: 'un',
    quantity: 10,
    minimumStock: 2,
    price: 50,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  InventoryItem(
    id: 2,
    name: 'Teclado',
    sku: 'TEC-001',
    category: 'Perifericos',
    unit: 'un',
    quantity: 6,
    minimumStock: 2,
    price: 80,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
];

Finder _textFormFieldByLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.labelText?.trim() == label,
  );
}

Future<Future<T?>> _openDialog<T>(WidgetTester tester, Widget dialog) async {
  late Future<T?> result;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  result = showDialog<T>(
                    context: context,
                    builder: (_) => dialog,
                  );
                },
                child: const Text('Abrir'),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return result;
}

Future<void> _selectDropdownOption(
  WidgetTester tester, {
  required String currentText,
  required String newText,
}) async {
  await tester.tap(find.text(currentText).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(newText).last);
  await tester.pumpAndSettle();
}

void _configureDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
