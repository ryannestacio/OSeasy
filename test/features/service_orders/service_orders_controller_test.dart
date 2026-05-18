import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/features/service_orders/domain/service_orders.dart';

import 'service_orders_test_fixtures.dart';

void main() {
  group('ServiceOrdersController', () {
    test('closeSelectedOrder throws when there is no selected order', () async {
      final repository = FakeServiceOrdersRepository();
      final controller = buildServiceOrdersController(repository);

      await controller.loadData();

      expect(
        () => controller.closeSelectedOrder(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Selecione uma OS antes de encerrar.',
          ),
        ),
      );
    });

    test(
      'discardSelectedDraftIfAny removes only selected draft and clears selection',
      () async {
        final repository = FakeServiceOrdersRepository(
          initialOrders: [
            buildServiceOrderDetails(
              id: 1,
              orderNumber: 1,
              status: ServiceOrderStatus.open,
            ),
            buildServiceOrderDetails(
              id: 2,
              orderNumber: 2,
              status: ServiceOrderStatus.open,
              isDraft: true,
              customerId: null,
              customerName: '',
              equipmentModel: '',
            ),
          ],
        );
        final controller = buildServiceOrdersController(repository);

        await controller.loadData();
        await controller.selectOrder(2);
        await controller.discardSelectedDraftIfAny();

        expect(repository.deletedDraftOrderIds, [2]);
        expect(controller.selectedOrderId, isNull);
        expect(controller.selectedDetails, isNull);
      },
    );

    test('applyFilters builds date range using start/end of day', () async {
      final repository = FakeServiceOrdersRepository();
      final controller = buildServiceOrdersController(repository);

      final entry = DateTime(2026, 3, 25, 14, 30);
      final ready = DateTime(2026, 3, 26, 9, 15);
      final exit = DateTime(2026, 3, 27, 19, 45);

      await controller.applyFilters(
        query: 'abc',
        customerId: 1,
        equipmentId: null,
        status: ServiceOrderStatus.open,
        priority: ServiceOrderPriority.normal,
        technicianId: null,
        entryDate: entry,
        readyDate: ready,
        exitDate: exit,
      );

      final filter = repository.lastFilter;
      expect(filter, isNotNull);
      expect(filter!.query, 'abc');
      expect(filter.customerId, 1);
      expect(filter.status, ServiceOrderStatus.open);
      expect(filter.priority, ServiceOrderPriority.normal);
      expect(filter.entryFrom, DateTime(2026, 3, 25));
      expect(filter.entryTo, DateTime(2026, 3, 25, 23, 59, 59, 999));
      expect(filter.readyFrom, DateTime(2026, 3, 26));
      expect(filter.readyTo, DateTime(2026, 3, 26, 23, 59, 59, 999));
      expect(filter.exitFrom, DateTime(2026, 3, 27));
      expect(filter.exitTo, DateTime(2026, 3, 27, 23, 59, 59, 999));
    });

    test('saveOrder wraps unexpected errors with fallback message', () async {
      final repository = FakeServiceOrdersRepository(
        initialOrders: [
          buildServiceOrderDetails(
            id: 10,
            orderNumber: 10,
            status: ServiceOrderStatus.open,
          ),
        ],
      )..throwGenericOnSave = true;
      final controller = buildServiceOrdersController(repository);
      await controller.loadData();
      await controller.selectOrder(10);

      final draft = ServiceOrderDraft(
        id: 10,
        orderNumber: 10,
        customerId: 1,
        equipmentId: null,
        status: ServiceOrderStatus.open,
        priority: ServiceOrderPriority.normal,
        entryAt: DateTime(2026, 3, 25, 10),
        readyAt: null,
        exitAt: null,
        warrantyUntil: null,
        responsibleTechnicianId: null,
        situation: 'Teste',
        equipmentModel: 'Notebook Teste',
        equipmentBrand: 'Marca X',
        equipmentMicroCpu: 'CPU X',
        equipmentRamHd: '16GB/512GB',
        equipmentSerialNumber: 'SN-001',
        equipmentAssetTag: 'PAT-001',
        equipmentAccessories: 'Carregador',
        defectComplaint: 'Defeito',
        equipmentObservations: 'Obs',
        technicalReport: 'Laudo',
        internalNotes: 'Interno',
        advanceAmount: 0,
        travelAmount: 0,
        thirdPartyAmount: 0,
        otherAmount: 0,
        updatedBy: 'Operador',
        serviceLines: const [],
        partLines: const [],
        attachments: const [],
      );

      expect(
        () => controller.saveOrder(draft),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Nao foi possivel concluir a operacao na OS.',
          ),
        ),
      );
    });
  });
}
