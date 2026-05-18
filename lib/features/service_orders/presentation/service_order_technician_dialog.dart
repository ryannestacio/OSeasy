part of 'service_order_dialogs.dart';

class ServiceOrderTechnicianDialog extends StatefulWidget {
  const ServiceOrderTechnicianDialog({super.key});

  @override
  State<ServiceOrderTechnicianDialog> createState() =>
      _ServiceOrderTechnicianDialogState();
}

class _ServiceOrderTechnicianDialogState
    extends State<ServiceOrderTechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = _responsiveDialogWidth(context, 420);

    return AlertDialog(
      title: const Text('Novo tecnico'),
      content: SizedBox(
        width: contentWidth,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome do tecnico'),
            validator: _requiredValidator,
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

    Navigator.of(
      context,
    ).pop(ServiceOrderTechnicianDraft(name: _nameController.text.trim()));
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }
}
