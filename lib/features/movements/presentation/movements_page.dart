import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/extensions/movement_type_view.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/movements.dart';
import 'movement_form_dialog.dart';
import 'movements_controller.dart';

class MovementsPage extends StatelessWidget {
  const MovementsPage({
    super.key,
    required this.controller,
    required this.onInventoryChanged,
  });

  final MovementsController controller;
  final Future<void> Function() onInventoryChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final movements = controller.movements;
        final entryVolume = movements
            .where((movement) => movement.type == MovementType.entry)
            .fold<double>(0, (sum, movement) => sum + movement.quantity);
        final exitVolume = movements
            .where((movement) => movement.type == MovementType.exit)
            .fold<double>(0, (sum, movement) => sum + movement.quantity);
        final adjustmentsCount = movements
            .where((movement) => movement.type == MovementType.adjustment)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Movimentacoes',
                subtitle:
                    'Registre entradas, saidas e ajustes para manter o saldo local sempre confiavel.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => _openMovementDialog(context),
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Nova movimentacao'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                          title: 'Historico carregado',
                          value: '${movements.length}',
                          subtitle: 'Ultimas movimentacoes registradas',
                          icon: Icons.history_rounded,
                          accentColor: AppPalette.gold,
                          highlight: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Entradas',
                          value: AppFormatters.quantity(entryVolume),
                          subtitle: 'Volume de reposicao',
                          icon: Icons.south_west_rounded,
                          accentColor: AppPalette.success,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Saidas',
                          value: AppFormatters.quantity(exitVolume),
                          subtitle: 'Volume consumido ou vendido',
                          icon: Icons.north_east_rounded,
                          accentColor: AppPalette.danger,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Ajustes',
                          value: '$adjustmentsCount',
                          subtitle: 'Correcoes de inventario',
                          icon: Icons.tune_rounded,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Historico recente',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (controller.isLoading)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (controller.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          controller.errorMessage!,
                          style: const TextStyle(color: AppPalette.black),
                        ),
                      ),
                    if (movements.isEmpty)
                      EmptyStateCard(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Nenhuma movimentacao registrada',
                        message: controller.availableItems.isEmpty
                            ? 'Cadastre pelo menos um item antes de registrar entradas, saidas ou ajustes.'
                            : 'O historico aparecera aqui assim que a primeira movimentacao for registrada.',
                        action: controller.availableItems.isEmpty
                            ? null
                            : FilledButton.icon(
                                onPressed: () => _openMovementDialog(context),
                                icon: const Icon(Icons.add_task_rounded),
                                label: const Text('Registrar movimentacao'),
                              ),
                      )
                    else
                      Column(
                        children: [
                          for (
                            var index = 0;
                            index < movements.length;
                            index++
                          ) ...[
                            _MovementTile(movement: movements[index]),
                            if (index < movements.length - 1)
                              const Divider(height: 28),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMovementDialog(BuildContext context) async {
    if (controller.availableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre ou reative um item antes de registrar movimentacoes.',
          ),
        ),
      );
      return;
    }

    final draft = await showDialog<InventoryMovementDraft>(
      context: context,
      builder: (context) =>
          MovementFormDialog(items: controller.availableItems),
    );

    if (draft == null) {
      return;
    }

    try {
      await controller.createMovement(draft);
      await onInventoryChanged();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimentacao registrada com sucesso.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = error is StateError
          ? error.message
          : 'Nao foi possivel registrar a movimentacao.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppPalette.black),
      );
    }
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    final signedQuantity = movement.signedQuantity;
    final indicatorColor = AppPalette.indicatorForValue(signedQuantity);
    final quantityLabel = signedQuantity > 0
        ? '+${AppFormatters.quantity(signedQuantity)}'
        : AppFormatters.quantity(signedQuantity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;

        final leading = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: movement.type.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(movement.type.icon, color: movement.type.color),
            ),
            const SizedBox(width: 14),
            Flexible(
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
                  if (movement.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      movement.note,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        final trailing = Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            StatusChip(
              label: movement.type.label,
              color: movement.type.color,
              icon: movement.type.icon,
            ),
            Text(
              quantityLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: indicatorColor),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [leading, const SizedBox(height: 14), trailing],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leading),
            const SizedBox(width: 18),
            trailing,
          ],
        );
      },
    );
  }
}
