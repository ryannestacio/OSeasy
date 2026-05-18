import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/page_header.dart';
import 'backup_controller.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({
    super.key,
    required this.controller,
    required this.onInventoryRestored,
  });

  final BackupController controller;
  final Future<void> Function() onInventoryRestored;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    title: 'Backup',
                    subtitle:
                        'Proteja o banco local com copia manual em arquivo e restaure rapidamente quando precisar.',
                  ),
                  const SizedBox(height: 20),
                  _BackupHeroCard(),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1080;

                      final actionsPanel = _BackupActionsPanel(
                        busy: controller.isBusy,
                        onCreate: () => _createBackup(context),
                        onRestore: () => _restoreBackup(context),
                      );

                      final infoPanel = _CurrentInfoPanel(
                        databasePath: controller.databasePath,
                        lastBackupPath: controller.lastBackupPath,
                        lastRestorePath: controller.lastRestorePath,
                        statusMessage: controller.statusMessage,
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: actionsPanel),
                            const SizedBox(width: 18),
                            Expanded(flex: 5, child: infoPanel),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          actionsPanel,
                          const SizedBox(height: 16),
                          infoPanel,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      final backupPath = await controller.createBackup();
      if (!context.mounted) {
        return;
      }

      final message = backupPath == null
          ? controller.statusMessage ?? 'Backup cancelado.'
          : 'Backup salvo em $backupPath';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = error is StateError
          ? error.message
          : 'Nao foi possivel criar o backup.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppPalette.black),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restaurar backup'),
          content: const Text(
            'A base local atual sera substituida. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final restorePath = await controller.restoreBackup();
      if (restorePath != null) {
        await onInventoryRestored();
      }

      if (!context.mounted) {
        return;
      }

      final message = restorePath == null
          ? controller.statusMessage ?? 'Restauracao cancelada.'
          : 'Backup restaurado de $restorePath';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = error is StateError
          ? error.message
          : 'Nao foi possivel restaurar o backup.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppPalette.black),
      );
    }
  }
}

class _BackupHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppPalette.gold, AppPalette.navy],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final textTheme = Theme.of(context).textTheme;

          final textColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seguranca do banco local',
                style: textTheme.bodyLarge?.copyWith(color: AppPalette.black),
              ),
              const SizedBox(height: 8),
              Text(
                'Gere copias do SQLite em arquivo e restaure a base quando precisar.',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppPalette.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'As operacoes usam o banco local. Antes de restaurar, confirme o arquivo selecionado.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppPalette.navy,
                  height: 1.45,
                ),
              ),
            ],
          );

          final chips = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroTag(label: 'Backup manual', icon: Icons.download_rounded),
              _HeroTag(
                label: 'Restore seguro',
                icon: Icons.upload_file_rounded,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [textColumn, const SizedBox(height: 14), chips],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: textColumn),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                child: Align(alignment: Alignment.centerRight, child: chips),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppPalette.black),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupActionsPanel extends StatelessWidget {
  const _BackupActionsPanel({
    required this.busy,
    required this.onCreate,
    required this.onRestore,
  });

  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acoes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Escolha a operacao de backup para a base local.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.textMuted),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;

              if (compact) {
                return Column(
                  children: [
                    _ActionCard(
                      title: 'Criar backup',
                      description:
                          'Selecione um local no computador para salvar uma copia do banco SQLite atual.',
                      buttonLabel: 'Salvar copia',
                      icon: Icons.download_rounded,
                      color: AppPalette.gold,
                      busy: busy,
                      onPressed: onCreate,
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      title: 'Restaurar backup',
                      description:
                          'Substitua a base atual por um arquivo de backup previamente salvo.',
                      buttonLabel: 'Restaurar arquivo',
                      icon: Icons.upload_file_rounded,
                      color: AppPalette.navy,
                      busy: busy,
                      onPressed: onRestore,
                    ),
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'Criar backup',
                        description:
                            'Selecione um local no computador para salvar uma copia do banco SQLite atual.',
                        buttonLabel: 'Salvar copia',
                        icon: Icons.download_rounded,
                        color: AppPalette.gold,
                        busy: busy,
                        onPressed: onCreate,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionCard(
                        title: 'Restaurar backup',
                        description:
                            'Substitua a base atual por um arquivo de backup previamente salvo.',
                        buttonLabel: 'Restaurar arquivo',
                        icon: Icons.upload_file_rounded,
                        color: AppPalette.navy,
                        busy: busy,
                        onPressed: onRestore,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CurrentInfoPanel extends StatelessWidget {
  const _CurrentInfoPanel({
    required this.databasePath,
    required this.lastBackupPath,
    required this.lastRestorePath,
    required this.statusMessage,
  });

  final String? databasePath;
  final String? lastBackupPath;
  final String? lastRestorePath;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppPalette.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppPalette.navy,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Informacoes atuais',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoTile(
            label: 'Banco local',
            value: databasePath ?? 'Carregando...',
          ),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Ultimo backup salvo',
            value: lastBackupPath ?? 'Nenhum backup criado nesta sessao.',
          ),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Ultima restauracao',
            value:
                lastRestorePath ??
                'Nenhuma restauracao realizada nesta sessao.',
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppPalette.navy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: busy ? null : onPressed,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppPalette.textMuted),
          ),
          const SizedBox(height: 4),
          SelectableText(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
