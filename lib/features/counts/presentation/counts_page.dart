import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../domain/stock_counts.dart';
import 'close_stock_count_dialog.dart';
import 'count_line_dialog.dart';
import 'counts_components.dart';
import 'counts_controller.dart';
import 'create_stock_count_dialog.dart';

class CountsPage extends StatefulWidget {
  const CountsPage({super.key, required this.controller});

  final CountsController controller;

  @override
  State<CountsPage> createState() => _CountsPageState();
}

class _CountsPageState extends State<CountsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.lineSearchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final counts = widget.controller.counts;
        final details = widget.controller.selectedDetails;
        final session = details?.session;
        final lines = widget.controller.filteredLines;
        final openCounts = counts.where((count) => count.isOpen).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Contagem',
                subtitle:
                    'Abra conferencias, conte todos os itens com rastreabilidade e exporte o resultado em PDF.',
                actions: [
                  FilledButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : _openCreateDialog,
                    icon: const Icon(Icons.fact_check_rounded),
                    label: const Text('Nova contagem'),
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
                          title: 'Contagens abertas',
                          value: '$openCounts',
                          subtitle: 'Sessoes em andamento',
                          icon: Icons.playlist_add_check_circle_rounded,
                          accentColor: AppPalette.gold,
                          highlight: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Itens da sessao',
                          value: '${session?.totalItems ?? 0}',
                          subtitle: 'Snapshot da contagem selecionada',
                          icon: Icons.format_list_bulleted_rounded,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Pendentes',
                          value: '${session?.pendingItems ?? 0}',
                          subtitle: 'Itens ainda nao conferidos',
                          icon: Icons.pending_actions_rounded,
                          accentColor: AppPalette.gold,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Divergencias',
                          value: '${session?.divergentItems ?? 0}',
                          subtitle: 'Itens com diferenca na contagem',
                          icon: Icons.rule_folder_rounded,
                          accentColor: AppPalette.black,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              if (widget.controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    widget.controller.errorMessage!,
                    style: const TextStyle(color: AppPalette.black),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1100;

                  final sessionsPanel = AppSurfaceCard(
                    child: CountsSessionPanel(
                      counts: counts,
                      selectedCountId: widget.controller.selectedCountId,
                      isLoading: widget.controller.isLoading,
                      isBusy: widget.controller.isBusy,
                      onCreate: _openCreateDialog,
                      onSelectCount: widget.controller.selectCount,
                    ),
                  );

                  final detailsPanel = AppSurfaceCard(
                    child: CountDetailsPanel(
                      session: session,
                      lines: lines,
                      lineFilter: widget.controller.lineFilter,
                      isBusy: widget.controller.isBusy,
                      searchController: _searchController,
                      onLineFilterChanged: widget.controller.setLineFilter,
                      onLineSearchChanged: widget.controller.setLineSearchQuery,
                      onExportWorksheet: _exportWorksheet,
                      onExportResult: _exportResult,
                      onCloseCount: _openCloseDialog,
                      onOpenLine: _openLineDialog,
                      onToggleLineSelection: _toggleLineSelection,
                    ),
                  );

                  if (compact) {
                    return Column(
                      children: [
                        sessionsPanel,
                        const SizedBox(height: 16),
                        detailsPanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: sessionsPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: detailsPanel),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreateDialog() async {
    final draft = await showDialog<CreateStockCountDraft>(
      context: context,
      builder: (context) => const CreateStockCountDialog(),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      await widget.controller.createCount(draft);
      if (!mounted) {
        return;
      }
      _showMessage('Contagem aberta com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _openLineDialog(StockCountLine line) async {
    final session = widget.controller.selectedSession;
    if (session == null || line.id == null || !session.isOpen) {
      return;
    }

    final draft = await showDialog<UpdateStockCountLineDraft>(
      context: context,
      builder: (context) => CountLineDialog(session: session, line: line),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      await widget.controller.updateLine(line.id!, draft);
      if (!mounted) {
        return;
      }
      _showMessage('Contagem do item salva com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _toggleLineSelection(StockCountLine line, bool selected) async {
    if (line.id == null) {
      return;
    }

    try {
      await widget.controller.setLineSelection(line.id!, selected);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _openCloseDialog() async {
    final session = widget.controller.selectedSession;
    if (session == null || !session.isOpen) {
      return;
    }

    final draft = await showDialog<CloseStockCountDraft>(
      context: context,
      builder: (context) => CloseStockCountDialog(session: session),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      await widget.controller.closeCount(draft);
      if (!mounted) {
        return;
      }
      _showMessage('Contagem fechada com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _exportWorksheet() async {
    try {
      final path = await widget.controller.exportWorksheetPdf();
      if (!mounted) {
        return;
      }
      if (path == null) {
        _showMessage('Exportacao cancelada.');
        return;
      }
      _showMessage('Folha de contagem exportada em:\n$path');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _exportResult() async {
    try {
      final path = await widget.controller.exportResultPdf();
      if (!mounted) {
        return;
      }
      if (path == null) {
        _showMessage('Exportacao cancelada.');
        return;
      }
      _showMessage('Resultado da contagem exportado em:\n$path');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppPalette.black : AppPalette.navy,
      ),
    );
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel concluir a operacao na contagem.';
  }
}
