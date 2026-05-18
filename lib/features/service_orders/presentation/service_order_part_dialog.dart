part of 'service_order_dialogs.dart';

class ServicePartDialog extends StatefulWidget {
  const ServicePartDialog({
    super.key,
    this.initialLine,
    required this.stockItems,
    required this.technicianName,
  });

  final ServiceOrderPartLineDraft? initialLine;
  final List<InventoryItem> stockItems;
  final String technicianName;

  @override
  State<ServicePartDialog> createState() => _ServicePartDialogState();
}

class _ServicePartDialogState extends State<ServicePartDialog> {
  final _formKey = GlobalKey<FormState>();

  late ServiceOrderPartOrigin _origin;
  int? _itemId;
  late final TextEditingController _partNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLine;
    _origin = initial?.origin ?? ServiceOrderPartOrigin.loose;
    _itemId = initial?.itemId;
    _partNameController = TextEditingController(text: initial?.partName ?? '');
    _quantityController = TextEditingController(
      text: initial == null ? '1' : AppFormatters.quantity(initial.quantity),
    );
    _unitPriceController = TextEditingController(
      text: initial == null ? '0' : initial.unitPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialLine == null ? 'Nova peca' : 'Editar peca'),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ServiceOrderPartOrigin>(
                  initialValue: _origin,
                  decoration: const InputDecoration(labelText: 'Origem'),
                  items: [
                    for (final origin in ServiceOrderPartOrigin.values)
                      DropdownMenuItem(
                        value: origin,
                        child: Text(origin.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _origin = value;
                      if (value == ServiceOrderPartOrigin.loose) {
                        _itemId = null;
                      }
                    });
                  },
                ),
                if (_origin == ServiceOrderPartOrigin.stock) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Item de estoque',
                          ),
                          child: Text(_selectedStockItemLabel()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _openStockItemLookup,
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Buscar'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _partNameController,
                  decoration: const InputDecoration(labelText: 'Peca'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Qtd'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Valor unitario',
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: widget.technicianName,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Tecnico'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }

  String _selectedStockItemLabel() {
    final selected = widget.stockItems.where((item) => item.id == _itemId);
    if (selected.isEmpty) {
      return 'Nao selecionado';
    }
    final item = selected.first;
    final skuPart = item.sku.trim().isEmpty ? '' : ' (${item.sku})';
    return '${item.name}$skuPart';
  }

  Future<void> _openStockItemLookup() async {
    final selectedItem = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => StockItemLookupDialog(
        stockItems: widget.stockItems,
        initialItemId: _itemId,
      ),
    );
    if (selectedItem == null || !mounted) {
      return;
    }

    setState(() {
      _itemId = selectedItem.id;
      _partNameController.text = selectedItem.name;
      _unitPriceController.text = selectedItem.price.toStringAsFixed(2);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_origin == ServiceOrderPartOrigin.stock && _itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o item de estoque.')),
      );
      return;
    }

    Navigator.of(context).pop(
      ServiceOrderPartLineDraft(
        id: widget.initialLine?.id,
        itemId: _origin == ServiceOrderPartOrigin.stock ? _itemId : null,
        partName: _partNameController.text.trim(),
        origin: _origin,
        quantity: AppFormatters.parseDecimal(_quantityController.text),
        unitPrice: AppFormatters.parseDecimal(_unitPriceController.text),
        technicianId: null,
        technicianName: widget.technicianName,
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }

    try {
      final parsed = AppFormatters.parseDecimal(value);
      if (parsed <= 0) {
        return 'Use valor maior que zero';
      }
    } catch (_) {
      return 'Numero invalido';
    }

    return null;
  }
}
