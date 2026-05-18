part of 'service_orders_page.dart';

extension _ServiceOrdersPageActions on _ServiceOrdersPageState {
  Future<void> _createOrder() async {
    if (widget.controller.customers.isEmpty) {
      _showMessage('Cadastre um cliente antes de abrir nova OS.', error: true);
      await _openCreateCustomer();
      if (!mounted || widget.controller.customers.isEmpty) {
        return;
      }
    }

    final selectedCustomer = await _showCustomerLookupDialog(
      title: 'Localizar cliente pelo nome.',
    );
    if (selectedCustomer == null || !mounted) {
      return;
    }

    try {
      await widget.controller.createOrder();
      if (!mounted) {
        return;
      }
      _setState(() {
        _pendingInitialCustomerId = selectedCustomer.id;
        _editingOrderId = null;
        _isEditing = true;
      });
      _showMessage('Nova OS criada com sucesso.');
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _openOrderForEdit(int orderId) async {
    try {
      await widget.controller.selectOrder(orderId);
      if (!mounted) {
        return;
      }
      _setState(() {
        _editingOrderId = null;
        _isEditing = true;
      });
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _applyFilters() async {
    await widget.controller.applyFilters(
      query: _searchFilterController.text.trim(),
      customerId: _filterCustomerId,
      equipmentId: null,
      status: _filterStatus,
      priority: _filterPriority,
      technicianId: null,
      entryDate: _filterEntryDate,
      readyDate: _filterReadyDate,
      exitDate: _filterExitDate,
    );
  }

  Future<void> _clearFilters() async {
    _searchFilterController.clear();
    _setState(() {
      _filterCustomerId = null;
      _filterStatus = null;
      _filterPriority = null;
      _filterEntryDate = null;
      _filterReadyDate = null;
      _filterExitDate = null;
    });
    await widget.controller.clearFilters();
  }

  Future<bool> _saveOrder() async {
    final selected = widget.controller.selectedDetails;
    if (selected == null) {
      return false;
    }
    if (_isClosedStatus(selected.status)) {
      _showMessage(
        'Esta OS esta fechada. Reabra a OS para permitir edicao.',
        error: true,
      );
      return false;
    }

    try {
      final draft = ServiceOrderDraft(
        id: selected.id,
        orderNumber: selected.orderNumber,
        customerId: _selectedCustomerId,
        equipmentId: null,
        status: _selectedStatus,
        priority: _selectedPriority,
        entryAt: _entryAt,
        readyAt: _readyAt,
        exitAt: _exitAt,
        warrantyUntil: _warrantyUntil,
        responsibleTechnicianId: null,
        situation: _situationController.text.trim(),
        equipmentModel: _equipmentModelController.text.trim(),
        equipmentBrand: _equipmentBrandController.text.trim(),
        equipmentMicroCpu: _equipmentMicroCpuController.text.trim(),
        equipmentRamHd: _equipmentRamHdController.text.trim(),
        equipmentSerialNumber: _equipmentSerialController.text.trim(),
        equipmentAssetTag: _equipmentAssetController.text.trim(),
        equipmentAccessories: _equipmentAccessoriesController.text.trim(),
        defectComplaint: _defectController.text.trim(),
        equipmentObservations: _equipmentObsController.text.trim(),
        technicalReport: _technicalReportController.text.trim(),
        internalNotes: _internalNotesController.text.trim(),
        advanceAmount: _parseDecimal(_advanceController.text),
        travelAmount: _parseDecimal(_travelController.text),
        thirdPartyAmount: _parseDecimal(_thirdController.text),
        otherAmount: _parseDecimal(_otherController.text),
        updatedBy: _operatorController.text.trim().isEmpty
            ? widget.controller.operatorName
            : _operatorController.text.trim(),
        serviceLines: _serviceLines,
        partLines: _partLines,
        attachments: _attachments,
      );

      await widget.controller.saveOrder(draft);
      if (!mounted) {
        return false;
      }
      _setState(() => _editingOrderId = null);
      _showMessage('OS gravada com sucesso.');
      return true;
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
      return false;
    }
  }

  Future<void> _discardChanges() async {
    final selected = widget.controller.selectedDetails;
    if (selected?.isDraft ?? false) {
      final shouldDiscard = await _confirmDiscardDraft();
      if (shouldDiscard != true) {
        return;
      }
      await widget.controller.discardSelectedDraftIfAny();
    }

    final selectedOrderId = widget.controller.selectedOrderId;
    if (selectedOrderId != null) {
      await widget.controller.loadData(selectOrderId: selectedOrderId);
    } else {
      await widget.controller.loadData();
    }
    if (!mounted) {
      return;
    }
    _setState(() {
      _isEditing = false;
      _editingOrderId = null;
    });
    _showMessage('Edicao cancelada.');
  }

  Future<bool?> _confirmDiscardDraft() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Descartar OS'),
          content: const Text('Voce quer descartar esta OS nao gravada?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _closeOrder() async {
    try {
      final saved = await _saveOrder();
      if (!saved) {
        return;
      }
      await widget.controller.closeSelectedOrder();
      if (!mounted) {
        return;
      }
      _setState(() => _editingOrderId = null);
      _showMessage('OS encerrada com sucesso.');
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _reopenOrder() async {
    final selected = widget.controller.selectedDetails;
    if (selected == null) {
      return;
    }
    if (!_isClosedStatus(selected.status)) {
      return;
    }

    final targetStatus = selected.status == ServiceOrderStatus.canceled
        ? ServiceOrderStatus.open
        : ServiceOrderStatus.inProgress;
    try {
      await widget.controller.changeStatus(
        targetStatus,
        note: 'OS reaberta manualmente.',
      );
      if (!mounted) {
        return;
      }
      _setState(() => _editingOrderId = null);
      _showMessage('OS reaberta com sucesso.');
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _exportOrder() async {
    try {
      final selected = widget.controller.selectedDetails;
      if (selected == null) {
        return;
      }
      final bytes = await widget.controller.exportCurrentOrderPdf();
      if (!mounted) {
        return;
      }
      await _showPdfPreviewDialog(
        bytes,
        title: 'OS ${selected.orderNumber}',
        suggestedName: _buildPdfFileName(selected.orderNumber, 'os'),
      );
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _exportBudget() async {
    try {
      final selected = widget.controller.selectedDetails;
      if (selected == null) {
        return;
      }
      final bytes = await widget.controller.exportCurrentBudgetPdf();
      if (!mounted) {
        return;
      }
      await _showPdfPreviewDialog(
        bytes,
        title: 'Orcamento OS ${selected.orderNumber}',
        suggestedName: _buildPdfFileName(selected.orderNumber, 'orcamento'),
      );
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _pickAttachments() async {
    final files = await openFiles();
    if (files.isEmpty || !mounted) {
      return;
    }

    _setState(() {
      _attachments = [
        ..._attachments,
        for (final file in files)
          ServiceOrderAttachmentDraft(
            id: null,
            filePath: file.path,
            fileName: file.name,
            createdAt: DateTime.now(),
            createdBy: _operatorController.text.trim().isEmpty
                ? widget.controller.operatorName
                : _operatorController.text.trim(),
          ),
      ];
    });
  }

  Future<void> _openCreateCustomer() async {
    final draft = await showDialog<ServiceOrderCustomerDraft>(
      context: context,
      builder: (context) => const ServiceOrderCustomerDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }

    try {
      await widget.controller.createCustomer(draft);
      if (!mounted) {
        return;
      }
      _showMessage('Cliente criado com sucesso.');
    } catch (error) {
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _openCustomerLookup() async {
    final selectedCustomer = await _showCustomerLookupDialog(
      title: 'Selecionar cliente',
      initialCustomerId: _selectedCustomerId,
    );
    if (selectedCustomer == null || !mounted) {
      return;
    }

    _setState(() {
      _selectedCustomerId = selectedCustomer.id;
    });
  }

  Future<void> _openServiceLineDialog({
    ServiceOrderServiceLineDraft? initialLine,
    int? index,
  }) async {
    final selected = widget.controller.selectedDetails;
    if (selected != null && _isClosedStatus(selected.status)) {
      return;
    }

    final draft = await showDialog<ServiceOrderServiceLineDraft>(
      context: context,
      builder: (context) => ServiceLineDialog(
        initialLine: initialLine,
        technicianName: _operatorController.text.trim().isEmpty
            ? widget.controller.operatorName
            : _operatorController.text.trim(),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }

    _setState(() {
      if (index == null) {
        _serviceLines = [..._serviceLines, draft];
      } else {
        _serviceLines = [
          for (var i = 0; i < _serviceLines.length; i++)
            if (i == index) draft else _serviceLines[i],
        ];
      }
    });
  }

  Future<void> _openPartLineDialog({
    ServiceOrderPartLineDraft? initialLine,
    int? index,
  }) async {
    final selected = widget.controller.selectedDetails;
    if (selected != null && _isClosedStatus(selected.status)) {
      return;
    }

    final draft = await showDialog<ServiceOrderPartLineDraft>(
      context: context,
      builder: (context) => ServicePartDialog(
        initialLine: initialLine,
        stockItems: widget.controller.lookupData.stockItems,
        technicianName: _operatorController.text.trim().isEmpty
            ? widget.controller.operatorName
            : _operatorController.text.trim(),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }

    _setState(() {
      if (index == null) {
        _partLines = [..._partLines, draft];
      } else {
        _partLines = [
          for (var i = 0; i < _partLines.length; i++)
            if (i == index) draft else _partLines[i],
        ];
      }
    });
  }

  Future<void> _pickDate({
    bool ready = false,
    bool exit = false,
    bool warranty = false,
    bool onlyDate = false,
  }) async {
    final now = DateTime.now();
    final current = warranty
        ? _warrantyUntil
        : ready
        ? _readyAt
        : exit
        ? _exitAt
        : _entryAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }

    DateTime value = date;
    if (!onlyDate) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current ?? now),
      );
      if (time != null) {
        value = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }

    _setState(() {
      if (warranty) {
        _warrantyUntil = value;
        return;
      }
      if (ready) {
        _readyAt = value;
        return;
      }
      if (exit) {
        _exitAt = value;
        return;
      }
      _entryAt = value;
    });
  }

  Widget _filterDateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.event_rounded),
      label: Text(
        value == null
            ? '$label: todas'
            : '$label: ${AppFormatters.date(value)}',
      ),
    );
  }

  Future<void> _pickFilterEntryDate() => _pickFilterDate(
    currentValue: _filterEntryDate,
    onSelected: (value) => _setState(() => _filterEntryDate = value),
  );

  Future<void> _pickFilterReadyDate() => _pickFilterDate(
    currentValue: _filterReadyDate,
    onSelected: (value) => _setState(() => _filterReadyDate = value),
  );

  Future<void> _pickFilterExitDate() => _pickFilterDate(
    currentValue: _filterExitDate,
    onSelected: (value) => _setState(() => _filterExitDate = value),
  );

  Future<void> _pickFilterDate({
    required DateTime? currentValue,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }

    onSelected(picked);
  }

  Future<void> _pickEntryDate() => _pickDate();

  Future<void> _pickReadyDate() => _pickDate(ready: true);

  Future<void> _pickExitDate() => _pickDate(exit: true);

  Future<void> _pickWarrantyDate() => _pickDate(warranty: true, onlyDate: true);

  Future<ServiceOrderCustomer?> _showCustomerLookupDialog({
    required String title,
    int? initialCustomerId,
  }) async {
    while (mounted) {
      final result = await showDialog<Object>(
        context: context,
        builder: (context) => ServiceOrderCustomerLookupDialog(
          title: title,
          customers: widget.controller.customers,
          initialCustomerId: initialCustomerId,
        ),
      );

      if (result is ServiceOrderCustomer) {
        return result;
      }

      if (result == CustomerLookupDialogAction.requestNewCustomer) {
        await _openCreateCustomer();
        if (!mounted) {
          return null;
        }
        continue;
      }

      return null;
    }

    return null;
  }

  Future<void> _showPdfPreviewDialog(
    Uint8List bytes, {
    required String title,
    required String suggestedName,
    bool allowSave = true,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogSize = _responsivePreviewDialogSize(
          context,
          preferredWidth: 1100,
          preferredHeight: 760,
        );
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SizedBox(
            width: dialogSize.width,
            height: dialogSize.height,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (allowSave)
                        OutlinedButton.icon(
                          onPressed: () => _savePdfBytes(
                            bytes,
                            suggestedName: suggestedName,
                          ),
                          icon: const Icon(Icons.save_alt_rounded),
                          label: const Text('Salvar PDF'),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PdfPreview(
                    build: (_) async => bytes,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    allowSharing: false,
                    allowPrinting: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePdfBytes(
    Uint8List bytes, {
    required String suggestedName,
  }) async {
    final saveLocation = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: _ServiceOrdersPageState._pdfTypeGroups,
    );
    if (saveLocation == null) {
      return;
    }

    final file = File(saveLocation.path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) {
      return;
    }
    _showMessage('PDF salvo em:\n${saveLocation.path}');
  }

  String _buildPdfFileName(int orderNumber, String suffix) {
    final now = DateTime.now();
    final datePart =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'os-$orderNumber-$suffix-$datePart.pdf';
  }

  Future<void> _openAttachment(ServiceOrderAttachmentDraft attachment) async {
    try {
      final file = File(attachment.filePath);
      final exists = await file.exists();
      if (!exists) {
        _showMessage(
          'Arquivo nao encontrado:\n${attachment.filePath}',
          error: true,
        );
        return;
      }

      final extension = attachment.fileName.split('.').last.toLowerCase();
      const imageExtensions = {'png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp'};
      const textExtensions = {'txt', 'csv', 'json', 'log', 'md'};

      if (extension == 'pdf') {
        final bytes = await file.readAsBytes();
        if (!mounted) {
          return;
        }
        await _showPdfPreviewDialog(
          bytes,
          title: attachment.fileName,
          suggestedName: attachment.fileName,
          allowSave: false,
        );
        return;
      }

      if (imageExtensions.contains(extension)) {
        if (!mounted) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (context) {
            final dialogSize = _responsivePreviewDialogSize(
              context,
              preferredWidth: 980,
              preferredHeight: 700,
            );
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: SizedBox(
                width: dialogSize.width,
                height: dialogSize.height,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(attachment.fileName)),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 0.4,
                        maxScale: 6,
                        child: Center(child: Image.file(file)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        return;
      }

      if (textExtensions.contains(extension)) {
        final content = await file.readAsString();
        if (!mounted) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (context) {
            final dialogSize = _responsivePreviewDialogSize(
              context,
              preferredWidth: 900,
              preferredHeight: 560,
              horizontalMargin: 80,
              verticalMargin: 120,
            );
            return AlertDialog(
              title: Text(attachment.fileName),
              content: SizedBox(
                width: dialogSize.width,
                height: dialogSize.height,
                child: SingleChildScrollView(child: Text(content)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
        return;
      }

      final result = await OpenFilex.open(attachment.filePath);
      if (result.type != ResultType.done) {
        _showMessage(
          'Nao foi possivel abrir o anexo automaticamente.',
          error: true,
        );
      }
    } catch (_) {
      _showMessage(
        'Falha ao abrir o anexo. Verifique o arquivo e tente novamente.',
        error: true,
      );
    }
  }

  Size _responsivePreviewDialogSize(
    BuildContext context, {
    required double preferredWidth,
    required double preferredHeight,
    double horizontalMargin = 48,
    double verticalMargin = 48,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final availableWidth = screenSize.width - horizontalMargin;
    final availableHeight = screenSize.height - verticalMargin;
    final width = availableWidth > 0
        ? min(preferredWidth, availableWidth)
        : preferredWidth;
    final height = availableHeight > 0
        ? min(preferredHeight, availableHeight)
        : preferredHeight;
    return Size(width, height);
  }
}
