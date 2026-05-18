import 'package:flutter/material.dart';

import '../../app/navigation/app_sections.dart';
import '../../app/theme/app_palette.dart';
import '../widgets/stokeasy_logo.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    this.compact = false,
  });

  final AppSection selectedSection;
  final ValueChanged<AppSection> onSectionSelected;
  final bool compact;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.compact ? double.infinity : 288,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.black, AppPalette.navy, AppPalette.navy],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: constraints.maxHeight < 900,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppPalette.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppPalette.dividerOnDark,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppPalette.gold,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: StokEasyLogo(),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'StokEasy',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(color: AppPalette.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Controle local com SQLite',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppPalette.overlayOnDark,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Navegacao',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppPalette.overlayOnDark,
                                  letterSpacing: 0.3,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ...AppSection.values.map(
                            (section) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SidebarItem(
                                section: section,
                                selected: section == widget.selectedSection,
                                onTap: () => widget.onSectionSelected(section),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppPalette.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppPalette.gold.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pronto para crescer',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: AppPalette.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Estrutura separada por camadas para itens, movimentacoes, relatorios e backup.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppPalette.overlayOnDark,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? AppPalette.black : AppPalette.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? AppPalette.gold
            : AppPalette.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppPalette.gold : AppPalette.dividerOnDark,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(section.icon, color: foregroundColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: foregroundColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
