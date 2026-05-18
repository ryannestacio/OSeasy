part of 'service_orders_page.dart';

extension _ServiceOrdersPageSections on _ServiceOrdersPageState {
  Widget _buildFiltersCard(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Listagem de OS',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (widget.controller.isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchFilterController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Buscar por OS, cliente ou equipamento',
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _filterCustomerId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    for (final customer in widget.controller.customers)
                      DropdownMenuItem<int?>(
                        value: customer.id,
                        child: Text(customer.name),
                      ),
                  ],
                  onChanged: (value) =>
                      _setState(() => _filterCustomerId = value),
                ),
              ),
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<ServiceOrderStatus?>(
                  isExpanded: true,
                  initialValue: _filterStatus,
                  decoration: const InputDecoration(labelText: 'Situacao'),
                  items: [
                    const DropdownMenuItem<ServiceOrderStatus?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final status in ServiceOrderStatus.values)
                      DropdownMenuItem<ServiceOrderStatus?>(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) => _setState(() => _filterStatus = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<ServiceOrderPriority?>(
                  isExpanded: true,
                  initialValue: _filterPriority,
                  decoration: const InputDecoration(labelText: 'Prioridade'),
                  items: [
                    const DropdownMenuItem<ServiceOrderPriority?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final priority in ServiceOrderPriority.values)
                      DropdownMenuItem<ServiceOrderPriority?>(
                        value: priority,
                        child: Text(priority.label),
                      ),
                  ],
                  onChanged: (value) =>
                      _setState(() => _filterPriority = value),
                ),
              ),
              _filterDateButton(
                label: 'Entrada',
                value: _filterEntryDate,
                onTap: _pickFilterEntryDate,
              ),
              _filterDateButton(
                label: 'Pronto',
                value: _filterReadyDate,
                onTap: _pickFilterReadyDate,
              ),
              _filterDateButton(
                label: 'Saida',
                value: _filterExitDate,
                onTap: _pickFilterExitDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: widget.controller.isBusy ? null : _applyFilters,
                icon: const Icon(Icons.filter_alt_rounded),
                label: const Text('Aplicar filtros'),
              ),
              OutlinedButton.icon(
                onPressed: widget.controller.isBusy ? null : _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Limpar'),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _operatorController,
                  decoration: const InputDecoration(labelText: 'Operador'),
                  onChanged: widget.controller.setOperatorName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderListCard(BuildContext context) {
    final orders = widget.controller.orders;
    if (orders.isEmpty) {
      return const AppSurfaceCard(
        child: EmptyStateCard(
          icon: Icons.inventory_2_outlined,
          title: 'Nenhuma OS encontrada',
          message: 'Ajuste os filtros ou crie uma nova OS.',
        ),
      );
    }

    return AppSurfaceCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('OS')),
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Equipamento')),
            DataColumn(label: Text('Entrada')),
            DataColumn(label: Text('Situacao')),
            DataColumn(label: Text('Prioridade')),
            DataColumn(label: Text('Total')),
          ],
          rows: [
            for (final order in orders)
              DataRow(
                selected:
                    _isEditing && order.id == widget.controller.selectedOrderId,
                onSelectChanged: (_) => _openOrderForEdit(order.id),
                cells: [
                  DataCell(Text(order.orderNumber.toString())),
                  DataCell(Text(order.customerName)),
                  DataCell(Text(order.equipmentModel)),
                  DataCell(Text(AppFormatters.dateTime(order.entryAt))),
                  DataCell(Text(order.status.label)),
                  DataCell(Text(order.priority.label)),
                  DataCell(Text(AppFormatters.currency(order.totalAmount))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, ServiceOrderDetails selected) {
    final isReadOnly = _isClosedStatus(selected.status);
    final laborAmount = _serviceLines.fold<double>(
      0,
      (sum, line) => sum + line.totalPrice,
    );
    final partsAmount = _partLines.fold<double>(
      0,
      (sum, line) => sum + line.totalPrice,
    );
    final travelAmount = _parseDecimal(_travelController.text);
    final thirdAmount = _parseDecimal(_thirdController.text);
    final otherAmount = _parseDecimal(_otherController.text);
    final advanceAmount = _parseDecimal(_advanceController.text);
    final totalAmount = max<double>(
      0,
      laborAmount +
          partsAmount +
          travelAmount +
          thirdAmount +
          otherAmount -
          advanceAmount,
    );

    final baseTheme = Theme.of(context);
    final inputDecorationTheme = baseTheme.inputDecorationTheme.copyWith(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    return Theme(
      data: baseTheme.copyWith(inputDecorationTheme: inputDecorationTheme),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1180;
                final title = Text(
                  'O.S. n${selected.orderNumber}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (isReadOnly)
                      OutlinedButton.icon(
                        onPressed: widget.controller.isBusy
                            ? null
                            : _reopenOrder,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Reabrir OS'),
                      ),
                    if (!isReadOnly)
                      OutlinedButton.icon(
                        onPressed: widget.controller.isBusy
                            ? null
                            : _closeOrder,
                        icon: const Icon(Icons.lock_rounded),
                        label: const Text('Encerrar OS'),
                      ),
                    if (!isReadOnly)
                      OutlinedButton.icon(
                        onPressed: widget.controller.isBusy
                            ? null
                            : _exportBudget,
                        icon: const Icon(Icons.request_quote_rounded),
                        label: const Text('Gerar orcamento'),
                      ),
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy ? null : _exportOrder,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Reimprimir'),
                    ),
                    if (!isReadOnly)
                      FilledButton.icon(
                        onPressed: widget.controller.isBusy ? null : _saveOrder,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Gravar OS'),
                      ),
                    if (!isReadOnly)
                      TextButton(
                        onPressed: widget.controller.isBusy
                            ? null
                            : _discardChanges,
                        child: const Text('Cancelar'),
                      ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 8), actions],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    Flexible(child: actions),
                  ],
                );
              },
            ),
            if (isReadOnly) ...[
              const SizedBox(height: 6),
              Text(
                'OS fechada. Reabra a OS para liberar edicao.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.black),
              ),
            ],
            const SizedBox(height: 12),
            _buildHeaderForm(
              selected,
              laborAmount,
              partsAmount,
              totalAmount,
              isReadOnly: isReadOnly,
            ),
            const SizedBox(height: 12),
            _buildTabs(context, isReadOnly: isReadOnly),
            const SizedBox(height: 12),
            _buildHistory(context, selected),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderForm(
    ServiceOrderDetails selected,
    double laborAmount,
    double partsAmount,
    double totalAmount, {
    required bool isReadOnly,
  }) {
    final customer = widget.controller.customers.firstWhere(
      (item) => item.id == _selectedCustomerId,
      orElse: () => ServiceOrderCustomer(
        id: null,
        name: selected.customerName,
        document: selected.customerDocument,
        phone: selected.customerPhone,
        email: selected.customerEmail,
        address: selected.customerAddress,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            final left = _buildClientCard(customer, isReadOnly: isReadOnly);
            final right = _buildFinancialSummary(
              laborAmount,
              partsAmount,
              totalAmount,
              isReadOnly: isReadOnly,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 12), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: left),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _dateField(
              label: 'Entrada',
              value: _entryAt,
              onTap: _pickEntryDate,
              enabled: !isReadOnly,
            ),
            _dateField(
              label: 'Pronto',
              value: _readyAt,
              onTap: _pickReadyDate,
              enabled: !isReadOnly,
            ),
            _dateField(
              label: 'Saida',
              value: _exitAt,
              onTap: _pickExitDate,
              enabled: !isReadOnly,
            ),
            _dateField(
              label: 'Garantia ate',
              value: _warrantyUntil,
              onTap: _pickWarrantyDate,
              enabled: !isReadOnly,
            ),
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<ServiceOrderStatus>(
                isExpanded: true,
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Situacao da OS'),
                items: [
                  for (final status in ServiceOrderStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: isReadOnly
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        _setState(() => _selectedStatus = value);
                      },
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<ServiceOrderPriority>(
                isExpanded: true,
                initialValue: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: [
                  for (final priority in ServiceOrderPriority.values)
                    DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    ),
                ],
                onChanged: isReadOnly
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        _setState(() => _selectedPriority = value);
                      },
              ),
            ),
            SizedBox(
              width: 260,
              child: TextFormField(
                initialValue: _operatorController.text.trim().isEmpty
                    ? widget.controller.operatorName
                    : _operatorController.text.trim(),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tecnico responsavel',
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: TextField(
                controller: _situationController,
                readOnly: isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Observacao da situacao',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientCard(
    ServiceOrderCustomer customer, {
    required bool isReadOnly,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: _readOnlyField(label: 'Cliente', value: customer.name),
              ),
              OutlinedButton.icon(
                onPressed: isReadOnly || widget.controller.isBusy
                    ? null
                    : _openCustomerLookup,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Buscar cliente'),
              ),
              OutlinedButton.icon(
                onPressed: isReadOnly || widget.controller.isBusy
                    ? null
                    : _openCreateCustomer,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Novo cliente'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Documento: ${customer.document.isEmpty ? '-' : customer.document}',
          ),
          Text('Telefone: ${customer.phone.isEmpty ? '-' : customer.phone}'),
          Text('E-mail: ${customer.email.isEmpty ? '-' : customer.email}'),
          Text(
            'Endereco: ${customer.address.isEmpty ? '-' : customer.address}',
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(
    double laborAmount,
    double partsAmount,
    double totalAmount, {
    required bool isReadOnly,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moneyField(
            'Adiantamento',
            _advanceController,
            isReadOnly: isReadOnly,
          ),
          const SizedBox(height: 8),
          _summaryLine('Mao de obra', laborAmount),
          _summaryLine('Pecas', partsAmount),
          _moneyField(
            'Deslocamento',
            _travelController,
            isReadOnly: isReadOnly,
          ),
          const SizedBox(height: 8),
          _moneyField('Terceiros', _thirdController, isReadOnly: isReadOnly),
          const SizedBox(height: 8),
          _moneyField('Outros', _otherController, isReadOnly: isReadOnly),
          const SizedBox(height: 12),
          Text(
            AppFormatters.currency(totalAmount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppPalette.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyField(
    String label,
    TextEditingController controller, {
    required bool isReadOnly,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              prefixText: 'R\$ ',
            ),
            onChanged: isReadOnly ? null : (_) => _setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _summaryLine(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(AppFormatters.currency(value)),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return SizedBox(
      width: 190,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: IgnorePointer(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              enabled: enabled,
              suffixIcon: const Icon(Icons.event_rounded),
            ),
            child: Text(value == null ? '' : AppFormatters.dateTime(value)),
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value}) {
    final normalized = value.trim().isEmpty ? '-' : value.trim();
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(normalized),
    );
  }

  Widget _buildTabs(BuildContext context, {required bool isReadOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Equipamento'),
            Tab(text: 'Mao de obra/Servicos'),
            Tab(text: 'Pecas utilizadas'),
            Tab(text: 'Obs/Laudo tecnico'),
            Tab(text: 'Fotos/Docs'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEquipmentTab(isReadOnly: isReadOnly),
              _buildServicesTab(isReadOnly: isReadOnly),
              _buildPartsTab(isReadOnly: isReadOnly),
              _buildTechnicalNotesTab(isReadOnly: isReadOnly),
              _buildAttachmentsTab(isReadOnly: isReadOnly),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentTab({required bool isReadOnly}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _equipmentModelController,
                  readOnly: isReadOnly,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _equipmentBrandController,
                  readOnly: isReadOnly,
                  decoration: const InputDecoration(
                    labelText: 'Fabricante/Marca',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _equipmentMicroCpuController,
                  readOnly: isReadOnly,
                  decoration: const InputDecoration(labelText: 'Micro/CPU'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _equipmentRamHdController,
                  readOnly: isReadOnly,
                  decoration: const InputDecoration(labelText: 'RAM/HD'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _equipmentSerialController,
                  readOnly: isReadOnly,
                  decoration: const InputDecoration(labelText: 'N serie'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _equipmentAssetController,
                  readOnly: isReadOnly,
                  decoration: const InputDecoration(labelText: 'N patrimonio'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _equipmentAccessoriesController,
            readOnly: isReadOnly,
            decoration: const InputDecoration(labelText: 'Acessorios'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _defectController,
            readOnly: isReadOnly,
            decoration: const InputDecoration(labelText: 'Defeito/Reclamacao'),
            minLines: 3,
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _equipmentObsController,
            readOnly: isReadOnly,
            decoration: const InputDecoration(labelText: 'Observacoes'),
            minLines: 3,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab({required bool isReadOnly}) {
    final totalDuration = _serviceLines.fold<Duration>(Duration.zero, (
      sum,
      line,
    ) {
      if (line.startTime == null || line.endTime == null) {
        return sum;
      }
      final diff = line.endTime!.difference(line.startTime!);
      return sum + (diff.isNegative ? Duration.zero : diff);
    });
    final totalHours = totalDuration.inMinutes / 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: isReadOnly ? null : () => _openServiceLineDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar servico'),
            ),
            const SizedBox(width: 12),
            Text('Total de horas: ${totalHours.toStringAsFixed(2)}'),
            const SizedBox(width: 20),
            Text(
              'Total servicos: ${AppFormatters.currency(_serviceLines.fold(0, (sum, line) => sum + line.totalPrice))}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _serviceLines.isEmpty
              ? const EmptyStateCard(
                  icon: Icons.build_circle_outlined,
                  title: 'Nenhum servico adicionado',
                  message: 'Inclua os servicos executados nesta OS.',
                )
              : SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Descricao')),
                      DataColumn(label: Text('Tipo')),
                      DataColumn(label: Text('Inicio')),
                      DataColumn(label: Text('Fim')),
                      DataColumn(label: Text('Qtd')),
                      DataColumn(label: Text('Valor')),
                      DataColumn(label: Text('Tecnico')),
                      DataColumn(label: Text('Acoes')),
                    ],
                    rows: [
                      for (var index = 0; index < _serviceLines.length; index++)
                        DataRow(
                          cells: [
                            DataCell(Text(_serviceLines[index].description)),
                            DataCell(Text(_serviceLines[index].serviceType)),
                            DataCell(
                              Text(
                                _serviceLines[index].startTime == null
                                    ? '-'
                                    : AppFormatters.dateTime(
                                        _serviceLines[index].startTime!,
                                      ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _serviceLines[index].endTime == null
                                    ? '-'
                                    : AppFormatters.dateTime(
                                        _serviceLines[index].endTime!,
                                      ),
                              ),
                            ),
                            DataCell(
                              Text(
                                AppFormatters.quantity(
                                  _serviceLines[index].quantity,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                AppFormatters.currency(
                                  _serviceLines[index].totalPrice,
                                ),
                              ),
                            ),
                            DataCell(Text(_serviceLines[index].technicianName)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: isReadOnly
                                        ? null
                                        : () => _openServiceLineDialog(
                                            initialLine: _serviceLines[index],
                                            index: index,
                                          ),
                                    icon: const Icon(Icons.edit_rounded),
                                  ),
                                  IconButton(
                                    onPressed: isReadOnly
                                        ? null
                                        : () => _setState(
                                            () => _serviceLines = [
                                              for (
                                                var i = 0;
                                                i < _serviceLines.length;
                                                i++
                                              )
                                                if (i != index)
                                                  _serviceLines[i],
                                            ],
                                          ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPartsTab({required bool isReadOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: isReadOnly ? null : () => _openPartLineDialog(),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Adicionar peca'),
            ),
            const SizedBox(width: 12),
            Text(
              'Total pecas: ${AppFormatters.currency(_partLines.fold(0, (sum, line) => sum + line.totalPrice))}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _partLines.isEmpty
              ? const EmptyStateCard(
                  icon: Icons.build_outlined,
                  title: 'Nenhuma peca adicionada',
                  message: 'Inclua pecas de estoque ou avulsas para esta OS.',
                )
              : SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Peca')),
                      DataColumn(label: Text('Origem')),
                      DataColumn(label: Text('Qtd')),
                      DataColumn(label: Text('Valor un')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Tecnico')),
                      DataColumn(label: Text('Acoes')),
                    ],
                    rows: [
                      for (var index = 0; index < _partLines.length; index++)
                        DataRow(
                          cells: [
                            DataCell(Text(_partLines[index].partName)),
                            DataCell(Text(_partLines[index].origin.label)),
                            DataCell(
                              Text(
                                AppFormatters.quantity(
                                  _partLines[index].quantity,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                AppFormatters.currency(
                                  _partLines[index].unitPrice,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                AppFormatters.currency(
                                  _partLines[index].totalPrice,
                                ),
                              ),
                            ),
                            DataCell(Text(_partLines[index].technicianName)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: isReadOnly
                                        ? null
                                        : () => _openPartLineDialog(
                                            initialLine: _partLines[index],
                                            index: index,
                                          ),
                                    icon: const Icon(Icons.edit_rounded),
                                  ),
                                  IconButton(
                                    onPressed: isReadOnly
                                        ? null
                                        : () => _setState(
                                            () => _partLines = [
                                              for (
                                                var i = 0;
                                                i < _partLines.length;
                                                i++
                                              )
                                                if (i != index) _partLines[i],
                                            ],
                                          ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTechnicalNotesTab({required bool isReadOnly}) {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _technicalReportController,
            readOnly: isReadOnly,
            decoration: const InputDecoration(
              labelText: 'Laudo tecnico',
              alignLabelWithHint: true,
            ),
            minLines: null,
            maxLines: null,
            expands: true,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _internalNotesController,
            readOnly: isReadOnly,
            decoration: const InputDecoration(
              labelText: 'Observacoes internas',
              alignLabelWithHint: true,
            ),
            minLines: null,
            maxLines: null,
            expands: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsTab({required bool isReadOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: isReadOnly ? null : _pickAttachments,
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text('Anexar arquivo'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _attachments.isEmpty
              ? const EmptyStateCard(
                  icon: Icons.folder_open_rounded,
                  title: 'Nenhum anexo',
                  message: 'Adicione fotos e documentos relacionados a OS.',
                )
              : ListView.separated(
                  itemCount: _attachments.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final attachment = _attachments[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(attachment.fileName),
                      subtitle: Text(
                        '${attachment.filePath}\n${AppFormatters.dateTime(attachment.createdAt)} - ${attachment.createdBy}',
                      ),
                      isThreeLine: true,
                      onTap: () => _openAttachment(attachment),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Visualizar',
                            onPressed: () => _openAttachment(attachment),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                          IconButton(
                            tooltip: 'Excluir',
                            onPressed: isReadOnly
                                ? null
                                : () => _setState(
                                    () => _attachments = [
                                      for (
                                        var i = 0;
                                        i < _attachments.length;
                                        i++
                                      )
                                        if (i != index) _attachments[i],
                                    ],
                                  ),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistory(BuildContext context, ServiceOrderDetails selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historico da OS', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (selected.history.isEmpty)
          const Text('Nenhuma alteracao registrada.')
        else
          Column(
            children: [
              for (final entry in selected.history.take(6))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.message),
                  subtitle: Text(
                    '${AppFormatters.dateTime(entry.createdAt)} - ${entry.createdBy}',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
