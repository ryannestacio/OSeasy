part of 'service_order_dialogs.dart';

class ServiceLineDialog extends StatefulWidget {
  const ServiceLineDialog({
    super.key,
    this.initialLine,
    required this.technicianName,
  });

  final ServiceOrderServiceLineDraft? initialLine;
  final String technicianName;

  @override
  State<ServiceLineDialog> createState() => _ServiceLineDialogState();
}

class _ServiceLineDialogState extends State<ServiceLineDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descriptionController;
  late final TextEditingController _typeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLine;
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _typeController = TextEditingController(
      text: (initial?.serviceType.trim().isNotEmpty ?? false)
          ? initial!.serviceType
          : 'Avulso',
    );
    _quantityController = TextEditingController(
      text: initial == null ? '1' : AppFormatters.quantity(initial.quantity),
    );
    _unitPriceController = TextEditingController(
      text: initial == null ? '0' : initial.unitPrice.toStringAsFixed(2),
    );
    _startTime = initial?.startTime;
    _endTime = initial?.endTime;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _typeController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialLine == null ? 'Novo servico' : 'Editar servico',
      ),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _typeController,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.technicianName,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Tecnico'),
                      ),
                    ),
                  ],
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(start: true),
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          _startTime == null
                              ? 'Inicio'
                              : _formatTime(_startTime!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(start: false),
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          _endTime == null ? 'Fim' : _formatTime(_endTime!),
                        ),
                      ),
                    ),
                  ],
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

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        start
            ? (_startTime ?? DateTime.now())
            : (_endTime ?? _startTime ?? DateTime.now()),
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    final baseDate = DateTime.now();
    final value = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      picked.hour,
      picked.minute,
    );

    setState(() {
      if (start) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = AppFormatters.parseDecimal(_quantityController.text);
    final unitPrice = AppFormatters.parseDecimal(_unitPriceController.text);

    Navigator.of(context).pop(
      ServiceOrderServiceLineDraft(
        id: widget.initialLine?.id,
        description: _descriptionController.text.trim(),
        serviceType: _typeController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        quantity: quantity,
        unitPrice: unitPrice,
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
      if (parsed < 0) {
        return 'Valor invalido';
      }
    } catch (_) {
      return 'Numero invalido';
    }

    return null;
  }
}
