import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../items/domain/items.dart';
import '../../items/presentation/items_controller.dart';
import '../../movements/domain/movements.dart';
import '../../movements/presentation/movements_controller.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    required this.dashboardController,
    required this.itemsController,
    required this.movementsController,
  });

  final DashboardController dashboardController;
  final ItemsController itemsController;
  final MovementsController movementsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        dashboardController,
        itemsController,
        movementsController,
      ]),
      builder: (context, child) {
        final items = List<InventoryItem>.from(itemsController.items)
          ..removeWhere((item) => !item.isActive)
          ..sort(
            (first, second) => second.stockValue.compareTo(first.stockValue),
          );
        final movements = movementsController.movements;
        final metrics = dashboardController.metrics;

        final latestMovement = movements.isEmpty ? null : movements.first;
        final criticalItems = items.where((item) => item.isLowStock).toList();
        final healthyItems = items.length - criticalItems.length;
        final coverage = items.isEmpty ? 0 : healthyItems / items.length;
        final adjustments = movements
            .where((movement) => movement.type == MovementType.adjustment)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Relatorios',
                subtitle:
                    'Leitura operacional inicial para acompanhar valor imobilizado, cobertura de estoque e itens mais sensiveis.',
              ),
              const SizedBox(height: 24),
              if (items.isEmpty && movements.isEmpty)
                const EmptyStateCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Ainda sem base para relatorios',
                  message:
                      'Assim que itens e movimentacoes forem registrados, os indicadores aparecerao aqui automaticamente.',
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final columns = availableWidth > 1200
                        ? 4
                        : availableWidth > 760
                        ? 2
                        : 1;
                    final cardWidth =
                        (availableWidth - ((columns - 1) * 16)) / columns;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Cobertura do estoque',
                            value: '${(coverage * 100).round()}%',
                            subtitle: 'Itens acima do minimo',
                            icon: Icons.shield_moon_rounded,
                            accentColor: AppPalette.gold,
                            highlight: true,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Itens saudaveis',
                            value: '$healthyItems',
                            subtitle: 'Sem alerta critico',
                            icon: Icons.check_circle_outline_rounded,
                            accentColor: AppPalette.navy,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Ajustes realizados',
                            value: '$adjustments',
                            subtitle: 'Correcoes no historico atual',
                            icon: Icons.tune_rounded,
                            accentColor: AppPalette.black,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Ultima atividade',
                            value: latestMovement == null
                                ? 'Sem dados'
                                : AppFormatters.date(latestMovement.createdAt),
                            subtitle: latestMovement == null
                                ? 'Aguardando movimentacoes'
                                : latestMovement.type.label,
                            icon: Icons.schedule_rounded,
                            accentColor: AppPalette.gold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1050;

                    final valueRanking = AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Itens com maior valor em estoque',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 18),
                          if (items.isEmpty)
                            const EmptyStateCard(
                              icon: Icons.payments_outlined,
                              title: 'Sem itens para analisar',
                              message:
                                  'Cadastre itens para acompanhar o valor imobilizado.',
                            )
                          else
                            Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < items.take(5).length;
                                  index++
                                ) ...[
                                  _ItemValueTile(item: items[index]),
                                  if (index < items.take(5).length - 1)
                                    const Divider(height: 28),
                                ],
                              ],
                            ),
                        ],
                      ),
                    );

                    final operationalPanel = Column(
                      children: [
                        AppSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Itens criticos',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 18),
                              if (criticalItems.isEmpty)
                                const EmptyStateCard(
                                  icon: Icons.verified_outlined,
                                  title: 'Sem itens criticos',
                                  message:
                                      'Nenhum item esta abaixo do estoque minimo no momento.',
                                )
                              else
                                Column(
                                  children: [
                                    for (
                                      var index = 0;
                                      index < criticalItems.take(5).length;
                                      index++
                                    ) ...[
                                      _CriticalItemTile(
                                        item: criticalItems[index],
                                      ),
                                      if (index <
                                          criticalItems.take(5).length - 1)
                                        const Divider(height: 28),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumo operacional',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 18),
                              _SummaryLine(
                                label: 'Valor total estimado',
                                value: metrics == null
                                    ? AppFormatters.currency(
                                        items.fold<double>(
                                          0,
                                          (sum, item) => sum + item.stockValue,
                                        ),
                                      )
                                    : AppFormatters.currency(
                                        metrics.inventoryValue,
                                      ),
                              ),
                              const SizedBox(height: 12),
                              _SummaryLine(
                                label: 'Entradas no mes',
                                value: metrics == null
                                    ? AppFormatters.quantity(
                                        movements
                                            .where(
                                              (movement) =>
                                                  movement.type ==
                                                  MovementType.entry,
                                            )
                                            .fold<double>(
                                              0,
                                              (sum, movement) =>
                                                  sum + movement.quantity,
                                            ),
                                      )
                                    : AppFormatters.quantity(
                                        metrics.entryVolumeThisMonth,
                                      ),
                              ),
                              const SizedBox(height: 12),
                              _SummaryLine(
                                label: 'Saidas no mes',
                                value: metrics == null
                                    ? AppFormatters.quantity(
                                        movements
                                            .where(
                                              (movement) =>
                                                  movement.type ==
                                                  MovementType.exit,
                                            )
                                            .fold<double>(
                                              0,
                                              (sum, movement) =>
                                                  sum + movement.quantity,
                                            ),
                                      )
                                    : AppFormatters.quantity(
                                        metrics.exitVolumeThisMonth,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        children: [
                          valueRanking,
                          const SizedBox(height: 16),
                          operationalPanel,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: valueRanking),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: operationalPanel),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ItemValueTile extends StatelessWidget {
  const _ItemValueTile({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '${item.sku} | ${item.category}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.currency(item.stockValue),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${AppFormatters.quantity(item.quantity)} ${item.unit}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _CriticalItemTile extends StatelessWidget {
  const _CriticalItemTile({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '${item.sku} | minimo ${AppFormatters.quantity(item.minimumStock)} ${item.unit}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusChip(
          label: '${AppFormatters.quantity(item.quantity)} ${item.unit}',
          color: AppPalette.gold,
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 16),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
