import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/features/service_orders/domain/service_orders.dart';
import 'package:stokeasy/features/service_orders/presentation/service_orders_page.dart';

import 'service_orders_test_fixtures.dart';

void main() {
  group('ServiceOrdersPage critical flows', () {
    testWidgets('full flow: Nova OS -> Gravar -> Encerrar -> Reabrir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repository = FakeServiceOrdersRepository(initialOrders: []);
      final controller = buildServiceOrdersController(repository);
      await controller.loadData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ServiceOrdersPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nova OS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente Base').first);
      await tester.pumpAndSettle();

      final modelField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText?.trim() == 'Modelo',
      );
      expect(modelField, findsOneWidget);
      await tester.enterText(modelField, 'Notebook Fluxo');

      await tester.tap(find.text('Mao de obra/Servicos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar servico'));
      await tester.pumpAndSettle();

      final serviceDialog = find.byType(AlertDialog).last;
      final serviceFields = find.descendant(
        of: serviceDialog,
        matching: find.byType(TextFormField),
      );
      await tester.enterText(serviceFields.first, 'Servico de teste');
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aberta').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pronta').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gravar OS'));
      await tester.pumpAndSettle();

      expect(controller.selectedDetails, isNotNull);
      expect(controller.selectedDetails!.isDraft, isFalse);
      expect(controller.selectedDetails!.status, ServiceOrderStatus.ready);

      await tester.tap(find.text('Encerrar OS'));
      await tester.pumpAndSettle();
      expect(controller.selectedDetails!.status, ServiceOrderStatus.delivered);
      expect(find.text('Reabrir OS'), findsOneWidget);

      await tester.tap(find.text('Reabrir OS'));
      await tester.pumpAndSettle();
      expect(controller.selectedDetails!.status, ServiceOrderStatus.inProgress);
      expect(find.text('Encerrar OS'), findsOneWidget);
      expect(find.text('Gravar OS'), findsOneWidget);
    });

    testWidgets('does not call close when save fails', (tester) async {
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repository = FakeServiceOrdersRepository(
        initialOrders: [
          buildServiceOrderDetails(
            id: 1,
            orderNumber: 1,
            status: ServiceOrderStatus.ready,
          ),
        ],
      )..throwStateOnSave = true;
      final controller = buildServiceOrdersController(repository);
      await controller.loadData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ServiceOrdersPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cliente Base').first);
      await tester.pumpAndSettle();

      expect(find.text('Encerrar OS'), findsOneWidget);
      await tester.tap(find.text('Encerrar OS'));
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 1);
      expect(repository.closeCalls, 0);
      expect(find.textContaining('Falha ao salvar'), findsOneWidget);
    });

    testWidgets('calls close when save succeeds', (tester) async {
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repository = FakeServiceOrdersRepository(
        initialOrders: [
          buildServiceOrderDetails(
            id: 1,
            orderNumber: 1,
            status: ServiceOrderStatus.ready,
          ),
        ],
      );
      final controller = buildServiceOrdersController(repository);
      await controller.loadData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ServiceOrdersPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cliente Base').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Encerrar OS'));
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 1);
      expect(repository.closeCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closed order hides editing actions and shows reopen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repository = FakeServiceOrdersRepository(
        initialOrders: [
          buildServiceOrderDetails(
            id: 1,
            orderNumber: 1,
            status: ServiceOrderStatus.delivered,
          ),
        ],
      );
      final controller = buildServiceOrdersController(repository);
      await controller.loadData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ServiceOrdersPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cliente Base').first);
      await tester.pumpAndSettle();

      expect(find.text('Reabrir OS'), findsOneWidget);
      expect(find.text('Encerrar OS'), findsNothing);
      expect(find.text('Gravar OS'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('missing attachment path shows message without crash', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repository = FakeServiceOrdersRepository(
        initialOrders: [
          buildServiceOrderDetails(
            id: 1,
            orderNumber: 1,
            status: ServiceOrderStatus.open,
            attachments: [
              ServiceOrderAttachment(
                id: 10,
                orderId: 1,
                filePath: r'C:\nao-existe\arquivo.pdf',
                fileName: 'arquivo.pdf',
                createdAt: DateTime(2026, 3, 25, 11),
                createdBy: 'Operador',
              ),
            ],
          ),
        ],
      );
      final controller = buildServiceOrdersController(repository);
      await controller.loadData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ServiceOrdersPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cliente Base').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fotos/Docs'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('arquivo.pdf'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
