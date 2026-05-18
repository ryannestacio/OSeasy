part of 'service_order_dialogs.dart';

class ServiceOrderEquipmentDialog extends StatefulWidget {
  const ServiceOrderEquipmentDialog({
    super.key,
    required this.customers,
    this.initialCustomerId,
  });

  final List<ServiceOrderCustomer> customers;
  final int? initialCustomerId;

  @override
  State<ServiceOrderEquipmentDialog> createState() =>
      _ServiceOrderEquipmentDialogState();
}

class _ServiceOrderEquipmentDialogState
    extends State<ServiceOrderEquipmentDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _customerId;
  late final TextEditingController _modelController;
  late final TextEditingController _brandController;
  late final TextEditingController _microCpuController;
  late final TextEditingController _ramHdController;
  late final TextEditingController _serialController;
  late final TextEditingController _assetController;
  late final TextEditingController _accessoriesController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    _modelController = TextEditingController();
    _brandController = TextEditingController();
    _microCpuController = TextEditingController();
    _ramHdController = TextEditingController();
    _serialController = TextEditingController();
    _assetController = TextEditingController();
    _accessoriesController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _brandController.dispose();
    _microCpuController.dispose();
    _ramHdController.dispose();
    _serialController.dispose();
    _assetController.dispose();
    _accessoriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = _responsiveDialogWidth(context, 640);

    return AlertDialog(
      title: const Text('Novo equipamento'),
      content: SizedBox(
        width: contentWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: _customerId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: [
                    for (final customer in widget.customers)
                      DropdownMenuItem<int?>(
                        value: customer.id,
                        child: Text(customer.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _customerId = value;
                    });
                  },
                  validator: (value) => (value == null || value <= 0)
                      ? 'Campo obrigatorio'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                        validator: _requiredValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Marca/Fabricante',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _microCpuController,
                        decoration: const InputDecoration(
                          labelText: 'Micro/CPU',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ramHdController,
                        decoration: const InputDecoration(labelText: 'RAM/HD'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _serialController,
                        decoration: const InputDecoration(labelText: 'N serie'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _assetController,
                        decoration: const InputDecoration(
                          labelText: 'N patrimonio',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accessoriesController,
                  decoration: const InputDecoration(labelText: 'Acessorios'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observacoes do equipamento',
                  ),
                  maxLines: 2,
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ServiceOrderEquipmentDraft(
        customerId: _customerId ?? 0,
        model: _modelController.text.trim(),
        brand: _brandController.text.trim(),
        microCpu: _microCpuController.text.trim(),
        ramHd: _ramHdController.text.trim(),
        serialNumber: _serialController.text.trim(),
        assetTag: _assetController.text.trim(),
        accessories: _accessoriesController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }
}
