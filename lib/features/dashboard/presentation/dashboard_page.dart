import 'package:flutter/material.dart';

import '../../../app/navigation/app_sections.dart';
import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/extensions/movement_type_view.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../movements/domain/movements.dart';
import '../domain/dashboard.dart';
import 'dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  final DashboardController controller;
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final metrics = controller.metrics;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Dashboard',
                subtitle:
                    'Uma visao moderna do estoque local com alertas, valor imobilizado e atividade recente.',
              ),
              const SizedBox(height: 24),
              _OverviewBanner(onNavigate: onNavigate, metrics: metrics),
              const SizedBox(height: 24),
              if (controller.errorMessage != null && metrics == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: AppPalette.black),
                  ),
                ),
              if (controller.isLoading && metrics == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (metrics == null)
                EmptyStateCard(
                  icon: Icons.space_dashboard_outlined,
                  title: 'Preparando visao inicial',
                  message:
                      'Cadastre itens e registre movimentacoes para preencher os indicadores do dashboard.',
                  action: FilledButton.icon(
                    onPressed: () => onNavigate(AppSection.items),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ir para itens'),
                  ),
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final columns = availableWidth > 1280
                        ? 6
                        : availableWidth > 980
                        ? 3
                        : availableWidth > 640
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
                            title: 'Itens cadastrados',
                            value: '${metrics.totalItems}',
                            subtitle: 'Base total do catalogo',
                            icon: Icons.inventory_2_rounded,
                            accentColor: AppPalette.gold,
                            highlight: true,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Unidades em estoque',
                            value: AppFormatters.compactNumber(
                              metrics.stockUnits,
                            ),
                            subtitle: 'Saldo consolidado',
                            icon: Icons.stacked_bar_chart_rounded,
                            accentColor: AppPalette.navy,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Itens em alerta',
                            value: '${metrics.lowStockItems}',
                            subtitle: 'Abaixo do estoque minimo',
                            icon: Icons.warning_amber_rounded,
                            accentColor: AppPalette.black,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Valor em estoque',
                            value: AppFormatters.currency(
                              metrics.inventoryValue,
                            ),
                            subtitle: 'Custo total estimado',
                            icon: Icons.payments_rounded,
                            accentColor: AppPalette.gold,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Entradas no mes',
                            value: AppFormatters.quantity(
                              metrics.entryVolumeThisMonth,
                            ),
                            subtitle: 'Volume de reposicao',
                            icon: Icons.south_west_rounded,
                            accentColor: AppPalette.success,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: MetricCard(
                            title: 'Saidas no mes',
                            value: AppFormatters.quantity(
                              metrics.exitVolumeThisMonth,
                            ),
                            subtitle: 'Volume consumido',
                            icon: Icons.north_east_rounded,
                            accentColor: AppPalette.danger,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _DashboardInsights(metrics: metrics, onNavigate: onNavigate),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OverviewBanner extends StatelessWidget {
  const _OverviewBanner({required this.onNavigate, required this.metrics});

  final ValueChanged<AppSection> onNavigate;
  final DashboardMetrics? metrics;

  String _summaryText() {
    final currentMetrics = metrics;
    if (currentMetrics == null) {
      return 'Assim que os primeiros dados entrarem, o dashboard mostrara alertas e atividade recente.';
    }
    return 'Hoje voce acompanha ${currentMetrics.totalItems} itens e ${currentMetrics.lowStockItems} alertas criticos em uma unica visao.';
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0, 0.48, 1],
        colors: [Color(0xFFFDB63A), Color(0xFFD08A16), AppPalette.navy],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: -50,
              bottom: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.black.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;
                  final theme = Theme.of(context);

                  final content = ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? constraints.maxWidth : 620,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppPalette.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_graph_rounded,
                                size: 16,
                                color: AppPalette.navy,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Operacao centralizada e local',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppPalette.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Controle seu estoque com cadastro de itens, movimentacoes e backup em arquivo.',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppPalette.black,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _summaryText(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppPalette.navy,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );

                  final actionPanel = Container(
                    width: compact ? double.infinity : 296,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppPalette.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppPalette.white.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.black.withValues(alpha: 0.12),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Acoes rapidas',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppPalette.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppPalette.white,
                            foregroundColor: AppPalette.black,
                            minimumSize: const Size.fromHeight(54),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () => onNavigate(AppSection.items),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Cadastrar item'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppPalette.navy,
                            foregroundColor: AppPalette.white,
                            minimumSize: const Size.fromHeight(54),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () => onNavigate(AppSection.movements),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Registrar movimentacao'),
                        ),
                      ],
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        content,
                        const SizedBox(height: 24),
                        actionPanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 24),
                      actionPanel,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardInsights extends StatelessWidget {
  const _DashboardInsights({required this.metrics, required this.onNavigate});

  final DashboardMetrics metrics;
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;

        final recentMovements = AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Movimentacoes recentes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigate(AppSection.movements),
                    child: const Text('Ver tudo'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (metrics.recentMovements.isEmpty)
                const EmptyStateCard(
                  icon: Icons.history_rounded,
                  title: 'Sem movimentacoes ainda',
                  message:
                      'As ultimas entradas, saidas e ajustes aparecerao aqui.',
                )
              else
                Column(
                  children: [
                    for (
                      var index = 0;
                      index < metrics.recentMovements.length;
                      index++
                    ) ...[
                      _RecentMovementTile(
                        movement: metrics.recentMovements[index],
                      ),
                      if (index < metrics.recentMovements.length - 1)
                        const Divider(height: 28),
                    ],
                  ],
                ),
            ],
          ),
        );

        final sideColumn = Column(
          children: [
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saude do estoque',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInsight(
                          label: 'Itens saudaveis',
                          value:
                              '${(metrics.totalItems - metrics.lowStockItems).clamp(0, metrics.totalItems)}',
                          color: AppPalette.navy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniInsight(
                          label: 'Itens criticos',
                          value: '${metrics.lowStockItems}',
                          color: AppPalette.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: metrics.totalItems == 0
                        ? 0
                        : (metrics.totalItems - metrics.lowStockItems) /
                              metrics.totalItems,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: AppPalette.silver,
                    color: AppPalette.gold,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    metrics.totalItems == 0
                        ? 'Cadastre itens para gerar a primeira leitura operacional.'
                        : 'Quanto maior a barra, maior a cobertura acima do estoque minimo.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Itens em alerta',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigate(AppSection.items),
                        child: const Text('Ir para itens'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (metrics.lowStockList.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Nenhum alerta de estoque',
                      message:
                          'Os itens abaixo do minimo aparecerao aqui automaticamente.',
                    )
                  else
                    Column(
                      children: [
                        for (
                          var index = 0;
                          index < metrics.lowStockList.length;
                          index++
                        ) ...[
                          _LowStockTile(item: metrics.lowStockList[index]),
                          if (index < metrics.lowStockList.length - 1)
                            const Divider(height: 28),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            children: [recentMovements, const SizedBox(height: 16), sideColumn],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: recentMovements),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: sideColumn),
          ],
        );
      },
    );
  }
}

class _MiniInsight extends StatelessWidget {
  const _MiniInsight({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RecentMovementTile extends StatelessWidget {
  const _RecentMovementTile({required this.movement});

  final DashboardRecentMovement movement;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = AppPalette.indicatorForValue(
      movement.signedQuantity,
    );
    final quantityLabel = movement.signedQuantity > 0
        ? '+${AppFormatters.quantity(movement.signedQuantity)}'
        : AppFormatters.quantity(movement.signedQuantity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: indicatorColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(movement.type.icon, color: indicatorColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movement.itemName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${movement.itemSku} | ${AppFormatters.dateTime(movement.createdAt)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusChip(
          label: '${movement.type.label} | $quantityLabel',
          color: indicatorColor,
          icon: movement.type.icon,
        ),
      ],
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.item});

  final DashboardLowStockItem item;

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
              Text(item.sku, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusChip(
              label:
                  '${AppFormatters.quantity(item.quantity)} / ${AppFormatters.quantity(item.minimumStock)}',
              color: AppPalette.gold,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 8),
            Text(
              'Faltam ${AppFormatters.quantity(item.shortage)} unidades',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
