import 'package:flutter/material.dart';

enum AppSection {
  dashboard,
  items,
  movements,
  serviceOrders,
  counts,
  reports,
  backup,
}

extension AppSectionView on AppSection {
  String get label => switch (this) {
    AppSection.dashboard => 'Dashboard',
    AppSection.items => 'Itens',
    AppSection.movements => 'Movimentacoes',
    AppSection.serviceOrders => 'Ordem de Servico',
    AppSection.counts => 'Contagem',
    AppSection.reports => 'Relatorios',
    AppSection.backup => 'Backup',
  };

  String get headline => switch (this) {
    AppSection.dashboard => 'Visao geral do estoque',
    AppSection.items => 'Cadastro e consulta de itens',
    AppSection.movements => 'Entradas, saidas e ajustes',
    AppSection.serviceOrders => 'Atendimento tecnico de equipamentos',
    AppSection.counts => 'Inventario fisico e conferencias',
    AppSection.reports => 'Indicadores operacionais',
    AppSection.backup => 'Seguranca do banco local',
  };

  IconData get icon => switch (this) {
    AppSection.dashboard => Icons.space_dashboard_rounded,
    AppSection.items => Icons.inventory_2_rounded,
    AppSection.movements => Icons.swap_horiz_rounded,
    AppSection.serviceOrders => Icons.build_rounded,
    AppSection.counts => Icons.fact_check_rounded,
    AppSection.reports => Icons.bar_chart_rounded,
    AppSection.backup => Icons.backup_rounded,
  };
}
