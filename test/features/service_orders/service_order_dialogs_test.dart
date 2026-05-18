import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/features/items/domain/items.dart';
import 'package:stokeasy/features/service_orders/domain/service_orders.dart';
import 'package:stokeasy/features/service_orders/presentation/service_order_dialogs.dart';

void main() {
  group('Service order dialogs', () {
    testWidgets('customer dialog validates required name', (tester) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<ServiceOrderCustomerDraft>(
        tester,
        const ServiceOrderCustomerDialog(),
      );

      await tester.ensureVisible(find.text('Gravar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gravar'));
      await tester.pump();

      expect(find.text('Campo obrigatorio'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await resultFuture, isNull);
    });

    testWidgets('customer dialog returns draft with composed address', (
      tester,
    ) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<ServiceOrderCustomerDraft>(
        tester,
        const ServiceOrderCustomerDialog(),
      );

      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeastNWidgets(21));

      await tester.enterText(fields.at(0), 'Cliente QA');
      await tester.enterText(fields.at(2), 'Maria');
      await tester.enterText(fields.at(4), '52998224725');
      await tester.enterText(fields.at(6), '29000-000');
      await tester.enterText(fields.at(7), 'Rua Central');
      await tester.enterText(fields.at(8), '123');
      await tester.enterText(fields.at(10), 'Centro');
      await tester.enterText(fields.at(11), 'Vitoria');
      await tester.enterText(fields.at(12), 'ES');
      await tester.enterText(fields.at(14), '(27) 99999-0000');
      await tester.enterText(fields.at(17), 'cliente@qa.com');

      final customerDropdowns = find.byType(DropdownButtonFormField<String>);
      expect(customerDropdowns, findsNWidgets(2));

      await tester.tap(customerDropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pessoa Juridica').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Gravar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gravar'));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      expect(result, isNotNull);
      expect(result!.name, 'Cliente QA');
      expect(result.personType, 'Pessoa Juridica');
      expect(result.document, '529.982.247-25');
      expect(result.gender, isEmpty);
      expect(result.city, 'Vitoria');
      expect(
        result.address,
        'Rua Central, 123\nCentro\nCEP 29000-000 - Brasil\nVitoria, ES',
      );
    });

    testWidgets('customer dialog validates cpf cep date and email', (
      tester,
    ) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<ServiceOrderCustomerDraft>(
        tester,
        const ServiceOrderCustomerDialog(),
      );

      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeastNWidgets(21));

      await tester.enterText(fields.at(0), 'Cliente Validacao');
      await tester.enterText(fields.at(3), '32132026');
      await tester.enterText(fields.at(4), '11111111111');
      await tester.enterText(fields.at(6), '12345');
      await tester.enterText(fields.at(17), 'email-invalido');
      await tester.enterText(fields.at(18), 'fiscal-invalido');

      await tester.ensureVisible(find.text('Gravar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gravar'));
      await tester.pump();

      expect(find.text('Data invalida'), findsOneWidget);
      expect(find.text('CPF/CNPJ invalido'), findsOneWidget);
      expect(find.text('CEP invalido'), findsOneWidget);
      expect(find.text('Email invalido'), findsNWidgets(2));

      await tester.enterText(fields.at(3), '01011990');
      await tester.enterText(fields.at(4), '52998224725');
      await tester.enterText(fields.at(6), '29000000');
      await tester.enterText(fields.at(17), 'cliente@qa.com');
      await tester.enterText(fields.at(18), 'fiscal@qa.com');

      await tester.tap(find.text('Gravar'));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      expect(result, isNotNull);
      expect(result!.birthday, '01/01/1990');
      expect(result.document, '529.982.247-25');
      expect(result.zipCode, '29000-000');
      expect(result.email, 'cliente@qa.com');
      expect(result.fiscalEmail, 'fiscal@qa.com');
    });

    testWidgets('equipment dialog validates and returns draft', (tester) async {
      _configureDesktopViewport(tester);
      final customers = <ServiceOrderCustomer>[
        const ServiceOrderCustomer(
          id: 1,
          name: 'Cliente 1',
          document: '',
          phone: '',
          email: '',
          address: '',
        ),
      ];

      final invalidResultFuture = await _openDialog<ServiceOrderEquipmentDraft>(
        tester,
        ServiceOrderEquipmentDialog(customers: customers),
      );

      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(find.text('Campo obrigatorio'), findsWidgets);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await invalidResultFuture, isNull);

      final validResultFuture = await _openDialog<ServiceOrderEquipmentDraft>(
        tester,
        ServiceOrderEquipmentDialog(customers: customers, initialCustomerId: 1),
      );

      await tester.enterText(_textFormFieldByLabel('Modelo'), 'Notebook Teste');
      await tester.enterText(
        _textFormFieldByLabel('Marca/Fabricante'),
        'Marca X',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final result = await validResultFuture;
      expect(result, isNotNull);
      expect(result!.customerId, 1);
      expect(result.model, 'Notebook Teste');
      expect(result.brand, 'Marca X');
    });

    testWidgets('part dialog shows stock item warning when missing selection', (
      tester,
    ) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<ServiceOrderPartLineDraft>(
        tester,
        ServicePartDialog(
          stockItems: _sampleStockItems,
          technicianName: 'Tecnico 1',
        ),
      );

      await _selectPartOrigin(tester, 'Estoque');

      await tester.enterText(_textFormFieldByLabel('Peca'), 'SSD');
      await tester.enterText(_textFormFieldByLabel('Qtd'), '1');
      await tester.enterText(_textFormFieldByLabel('Valor unitario'), '100');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione o item de estoque.'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await resultFuture, isNull);
    });

    testWidgets('part dialog selects stock item and returns draft', (
      tester,
    ) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<ServiceOrderPartLineDraft>(
        tester,
        ServicePartDialog(
          stockItems: _sampleStockItems,
          technicianName: 'Tecnico 2',
        ),
      );

      await _selectPartOrigin(tester, 'Estoque');

      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SSD 240').first);
      await tester.pumpAndSettle();

      await tester.enterText(_textFormFieldByLabel('Qtd'), '2');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      expect(result, isNotNull);
      expect(result!.origin, ServiceOrderPartOrigin.stock);
      expect(result.itemId, 10);
      expect(result.partName, 'SSD 240');
      expect(result.technicianName, 'Tecnico 2');
    });

    testWidgets('stock item lookup filters by balance and query', (
      tester,
    ) async {
      _configureDesktopViewport(tester);
      final resultFuture = await _openDialog<InventoryItem>(
        tester,
        StockItemLookupDialog(stockItems: _sampleStockItems),
      );

      expect(find.text('Mouse sem fio'), findsNothing);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(find.text('Mouse sem fio'), findsOneWidget);

      await tester.enterText(
        _textFieldByLabel('Nome, SKU, categoria ou unidade'),
        'ssd',
      );
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.text('SSD 240'), findsOneWidget);
      expect(find.text('Teclado mecanico'), findsNothing);

      await tester.tap(find.text('SSD 240').first);
      await tester.pumpAndSettle();

      final selected = await resultFuture;
      expect(selected, isNotNull);
      expect(selected!.id, 10);
      expect(selected.name, 'SSD 240');
    });
  });
}

final _sampleStockItems = <InventoryItem>[
  InventoryItem(
    id: 10,
    name: 'SSD 240',
    sku: 'SSD-240',
    category: 'Armazenamento',
    unit: 'un',
    quantity: 4,
    minimumStock: 1,
    price: 150,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  InventoryItem(
    id: 20,
    name: 'Mouse sem fio',
    sku: 'MOU-001',
    category: 'Perifericos',
    unit: 'un',
    quantity: 0,
    minimumStock: 2,
    price: 80,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  InventoryItem(
    id: 30,
    name: 'Teclado mecanico',
    sku: 'TEC-001',
    category: 'Perifericos',
    unit: 'un',
    quantity: 3,
    minimumStock: 1,
    price: 250,
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

Finder _textFieldByLabel(String label) {
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

Future<void> _selectPartOrigin(WidgetTester tester, String label) async {
  await tester.tap(
    find.byType(DropdownButtonFormField<ServiceOrderPartOrigin>),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void _configureDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
