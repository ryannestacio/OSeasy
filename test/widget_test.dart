import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/app/navigation/app_sections.dart';
import 'package:stokeasy/features/dashboard/domain/dashboard.dart';
import 'package:stokeasy/features/dashboard/presentation/dashboard_controller.dart';
import 'package:stokeasy/features/dashboard/presentation/dashboard_page.dart';
import 'package:stokeasy/features/movements/domain/movements.dart';
import 'package:stokeasy/shared/navigation/app_sidebar.dart';

void main() {
  testWidgets('renders sidebar sections and dashboard cards', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = DashboardController(
      getDashboardMetricsUseCase: GetDashboardMetricsUseCase(
        _FakeDashboardRepository(),
      ),
    );
    await controller.loadMetrics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppSidebar(
                selectedSection: AppSection.dashboard,
                onSectionSelected: (_) {},
              ),
              Expanded(
                child: DashboardPage(
                  controller: controller,
                  onNavigate: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Itens'), findsOneWidget);
    expect(find.text('Movimentacoes'), findsOneWidget);
    expect(find.text('Ordem de Servico'), findsOneWidget);
    expect(find.text('Contagem'), findsOneWidget);
    expect(find.text('Relatorios'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Itens cadastrados'), findsOneWidget);
    expect(find.text('Movimentacoes recentes'), findsOneWidget);
    expect(find.text('Itens em alerta'), findsWidgets);
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardMetrics> getMetrics() async {
    return DashboardMetrics(
      totalItems: 24,
      lowStockItems: 3,
      inventoryValue: 18450,
      stockUnits: 320,
      entryVolumeThisMonth: 125,
      exitVolumeThisMonth: 84,
      lowStockList: const [
        DashboardLowStockItem(
          name: 'Papel A4',
          sku: 'PAP-A4',
          quantity: 4,
          minimumStock: 10,
        ),
      ],
      recentMovements: [
        DashboardRecentMovement(
          itemName: 'Mouse sem fio',
          itemSku: 'MOU-001',
          type: MovementType.entry,
          quantity: 12,
          createdAt: DateTime(2026, 3, 20, 10, 30),
        ),
      ],
    );
  }
}
