import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../domain/service_orders.dart';
import 'service_order_dialogs.dart';
import 'service_orders_controller.dart';

part 'service_orders_page_sections.dart';
part 'service_orders_page_actions.dart';
part 'service_orders_page_helpers.dart';

class ServiceOrdersPage extends StatefulWidget {
  const ServiceOrdersPage({super.key, required this.controller});

  final ServiceOrdersController controller;

  @override
  State<ServiceOrdersPage> createState() => _ServiceOrdersPageState();
}

class _ServiceOrdersPageState extends State<ServiceOrdersPage>
    with SingleTickerProviderStateMixin {
  static const List<XTypeGroup> _pdfTypeGroups = [
    XTypeGroup(label: 'Documento PDF', extensions: ['pdf']),
  ];

  late final TabController _tabController;
  late final TextEditingController _searchFilterController;
  late final TextEditingController _operatorController;

  bool _isEditing = false;
  int? _pendingInitialCustomerId;
  int? _editingOrderId;
  int? _selectedCustomerId;
  ServiceOrderStatus _selectedStatus = ServiceOrderStatus.open;
  ServiceOrderPriority _selectedPriority = ServiceOrderPriority.normal;
  DateTime _entryAt = DateTime.now();
  DateTime? _readyAt;
  DateTime? _exitAt;
  DateTime? _warrantyUntil;

  final _situationController = TextEditingController();
  final _equipmentModelController = TextEditingController();
  final _equipmentBrandController = TextEditingController();
  final _equipmentMicroCpuController = TextEditingController();
  final _equipmentRamHdController = TextEditingController();
  final _equipmentSerialController = TextEditingController();
  final _equipmentAssetController = TextEditingController();
  final _equipmentAccessoriesController = TextEditingController();
  final _defectController = TextEditingController();
  final _equipmentObsController = TextEditingController();
  final _technicalReportController = TextEditingController();
  final _internalNotesController = TextEditingController();

  final _advanceController = TextEditingController(text: '0');
  final _travelController = TextEditingController(text: '0');
  final _thirdController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');

  List<ServiceOrderServiceLineDraft> _serviceLines = const [];
  List<ServiceOrderPartLineDraft> _partLines = const [];
  List<ServiceOrderAttachmentDraft> _attachments = const [];

  int? _filterCustomerId;
  ServiceOrderStatus? _filterStatus;
  ServiceOrderPriority? _filterPriority;
  DateTime? _filterEntryDate;
  DateTime? _filterReadyDate;
  DateTime? _filterExitDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchFilterController = TextEditingController(
      text: widget.controller.queryFilter,
    );
    _operatorController = TextEditingController(
      text: widget.controller.operatorName,
    );
    _filterCustomerId = widget.controller.customerFilter;
    _filterStatus = widget.controller.statusFilter;
    _filterPriority = widget.controller.priorityFilter;
    _filterEntryDate = widget.controller.entryDateFilter;
    _filterReadyDate = widget.controller.readyDateFilter;
    _filterExitDate = widget.controller.exitDateFilter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFilterController.dispose();
    _operatorController.dispose();
    _situationController.dispose();
    _equipmentModelController.dispose();
    _equipmentBrandController.dispose();
    _equipmentMicroCpuController.dispose();
    _equipmentRamHdController.dispose();
    _equipmentSerialController.dispose();
    _equipmentAssetController.dispose();
    _equipmentAccessoriesController.dispose();
    _defectController.dispose();
    _equipmentObsController.dispose();
    _technicalReportController.dispose();
    _internalNotesController.dispose();
    _advanceController.dispose();
    _travelController.dispose();
    _thirdController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final selected = widget.controller.selectedDetails;
        if (_isEditing) {
          _syncEditorWithSelected(selected);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Ordem de servico',
                subtitle:
                    'Gerencie OS de equipamentos com cliente, servicos, pecas, anexos e fechamento com baixa de estoque.',
                actions: [
                  if (_isEditing)
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : _discardChanges,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Voltar para lista'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: widget.controller.isBusy ? null : _createOrder,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nova OS'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_isEditing) ...[
                _buildFiltersCard(context),
                const SizedBox(height: 16),
                if (widget.controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.controller.errorMessage!,
                      style: const TextStyle(color: AppPalette.black),
                    ),
                  ),
                _buildOrderListCard(context),
              ] else ...[
                if (selected == null)
                  const EmptyStateCard(
                    icon: Icons.description_outlined,
                    title: 'Carregando OS',
                    message: 'Aguarde enquanto os dados da OS sao carregados.',
                  )
                else
                  _buildEditorCard(context, selected),
              ],
            ],
          ),
        );
      },
    );
  }

  void _syncEditorWithSelected(ServiceOrderDetails? details) {
    if (details == null) {
      _editingOrderId = null;
      return;
    }
    if (_editingOrderId == details.id) {
      return;
    }

    _editingOrderId = details.id;
    _selectedCustomerId = details.customerId;
    if (_pendingInitialCustomerId != null) {
      _selectedCustomerId = _pendingInitialCustomerId;
      _pendingInitialCustomerId = null;
    }
    _selectedStatus = details.status;
    _selectedPriority = details.priority;
    _entryAt = details.entryAt;
    _readyAt = details.readyAt;
    _exitAt = details.exitAt;
    _warrantyUntil = details.warrantyUntil;
    _situationController.text = details.situation;
    _equipmentModelController.text = details.equipmentModel;
    _equipmentBrandController.text = details.equipmentBrand;
    _equipmentMicroCpuController.text = details.equipmentMicroCpu;
    _equipmentRamHdController.text = details.equipmentRamHd;
    _equipmentSerialController.text = details.equipmentSerialNumber;
    _equipmentAssetController.text = details.equipmentAssetTag;
    _equipmentAccessoriesController.text = details.equipmentAccessories;
    _defectController.text = details.defectComplaint;
    _equipmentObsController.text = details.equipmentObservations;
    _technicalReportController.text = details.technicalReport;
    _internalNotesController.text = details.internalNotes;
    _advanceController.text = details.advanceAmount.toStringAsFixed(2);
    _travelController.text = details.travelAmount.toStringAsFixed(2);
    _thirdController.text = details.thirdPartyAmount.toStringAsFixed(2);
    _otherController.text = details.otherAmount.toStringAsFixed(2);
    _serviceLines = [
      for (final line in details.serviceLines)
        ServiceOrderServiceLineDraft(
          id: line.id,
          description: line.description,
          serviceType: line.serviceType,
          startTime: line.startTime,
          endTime: line.endTime,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          technicianId: line.technicianId,
          technicianName: line.technicianName,
        ),
    ];
    _partLines = [
      for (final line in details.partLines)
        ServiceOrderPartLineDraft(
          id: line.id,
          itemId: line.itemId,
          partName: line.partName,
          origin: line.origin,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          technicianId: line.technicianId,
          technicianName: line.technicianName,
        ),
    ];
    _attachments = [
      for (final attachment in details.attachments)
        ServiceOrderAttachmentDraft(
          id: attachment.id,
          filePath: attachment.filePath,
          fileName: attachment.fileName,
          createdAt: attachment.createdAt,
          createdBy: attachment.createdBy,
        ),
    ];
  }

  void _setState(VoidCallback callback) {
    setState(callback);
  }
}
