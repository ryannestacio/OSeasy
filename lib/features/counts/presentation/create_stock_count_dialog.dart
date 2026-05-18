import 'package:flutter/material.dart';

import '../domain/stock_counts.dart';

class CreateStockCountDialog extends StatefulWidget {
  const CreateStockCountDialog({super.key});

  @override
  State<CreateStockCountDialog> createState() => _CreateStockCountDialogState();
}

class _CreateStockCountDialogState extends State<CreateStockCountDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _openedByController;
  late final TextEditingController _notesController;

  bool _blindMode = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _openedByController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova contagem'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O sistema vai congelar uma foto dos itens ativos neste momento para voce contar com seguranca.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da contagem',
                    hintText: 'Opcional',
                    helperText:
                        'Se deixar em branco, o sistema gera um nome automatico.',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _openedByController,
                  decoration: const InputDecoration(labelText: 'Quem iniciou'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observacoes de abertura',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _blindMode,
                  title: const Text('Contagem cega'),
                  subtitle: const Text(
                    'Oculta o saldo do sistema enquanto a contagem estiver aberta.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _blindMode = value;
                    });
                  },
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
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.fact_check_rounded),
          label: const Text('Abrir contagem'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      CreateStockCountDraft(
        name: _nameController.text.trim(),
        openedBy: _openedByController.text.trim(),
        notes: _notesController.text.trim(),
        blindMode: _blindMode,
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
