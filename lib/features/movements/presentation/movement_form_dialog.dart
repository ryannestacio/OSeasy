import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../items/domain/items.dart';
import '../domain/movements.dart';

class MovementFormDialog extends StatefulWidget {
  const MovementFormDialog({super.key, required this.items});

  final List<InventoryItem> items;

  @override
  State<MovementFormDialog> createState() => _MovementFormDialogState();
}

class _MovementFormDialogState extends State<MovementFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late int _selectedItemId;
  MovementType _selectedType = MovementType.entry;
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedItemId = widget.items.isEmpty ? 0 : (widget.items.first.id ?? 0);
    _quantityController = TextEditingController(text: '1');
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return AlertDialog(
        title: const Text('Registrar movimentacao'),
        content: const Text(
          'Nao ha itens ativos disponiveis para movimentacao.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    }

    final selectedItem = widget.items.firstWhere(
      (item) => item.id == _selectedItemId,
      orElse: () => widget.items.first,
    );

    return AlertDialog(
      title: const Text('Registrar movimentacao'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedItemId,
                  decoration: const InputDecoration(labelText: 'Item'),
                  items: [
                    for (final item in widget.items)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.sku})'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedItemId = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<MovementType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimentacao',
                  ),
                  items: MovementType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: Text(
                    'Saldo atual de ${selectedItem.name}: ${AppFormatters.quantity(selectedItem.quantity)} ${selectedItem.unit}',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _selectedType == MovementType.adjustment
                        ? 'Ajuste de estoque'
                        : 'Quantidade',
                    helperText: _selectedType == MovementType.adjustment
                        ? 'Use valor positivo ou negativo para corrigir o saldo.'
                        : 'Informe a quantidade movimentada.',
                  ),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Observacao',
                    hintText: 'Ex.: compra do fornecedor, venda, inventario.',
                  ),
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
        FilledButton(onPressed: _submit, child: const Text('Registrar')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = AppFormatters.parseDecimal(_quantityController.text);
    final draft = InventoryMovementDraft(
      itemId: _selectedItemId,
      type: _selectedType,
      quantity: quantity,
      note: _noteController.text.trim(),
    );

    Navigator.of(context).pop(draft);
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }

    try {
      final parsed = AppFormatters.parseDecimal(value);
      if (_selectedType == MovementType.adjustment) {
        if (parsed == 0) {
          return 'Use um ajuste diferente de zero';
        }
      } else if (parsed <= 0) {
        return 'Use um valor maior que zero';
      }
    } catch (_) {
      return 'Numero invalido';
    }

    return null;
  }
}
