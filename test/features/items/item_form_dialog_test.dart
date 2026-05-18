import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/features/items/presentation/item_form_dialog.dart';

void main() {
  testWidgets('shows optional item code field instead of required SKU', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ItemFormDialog())),
    );

    expect(find.text('Codigo do item'), findsOneWidget);
    expect(find.text('Opcional'), findsOneWidget);
    expect(
      find.text('Deixe em branco para gerar automaticamente.'),
      findsOneWidget,
    );
    expect(find.text('SKU'), findsNothing);
    expect(find.text('Valor de custo'), findsOneWidget);
    expect(find.text('Custo unitario'), findsNothing);
  });
}
