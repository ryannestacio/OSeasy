import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../domain/items.dart';

class ItemFormDialog extends StatefulWidget {
  const ItemFormDialog({super.key, this.item});

  final InventoryItem? item;

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _categoryController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumStockController;
  late final TextEditingController _priceController;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _unitController = TextEditingController(text: item?.unit ?? 'un');
    _quantityController = TextEditingController(
      text: item == null ? '0' : AppFormatters.quantity(item.quantity),
    );
    _minimumStockController = TextEditingController(
      text: item == null ? '0' : AppFormatters.quantity(item.minimumStock),
    );
    _priceController = TextEditingController(
      text: item == null ? '0' : item.price.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _minimumStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AlertDialog(
      title: Text(_isEditing ? 'Editar item' : 'Novo item'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do item'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'Codigo do item',
                          hintText: 'Opcional',
                          helperText:
                              'Deixe em branco para gerar automaticamente.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        validator: _requiredValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unidade'),
                        validator: _requiredValidator,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumStockController,
                        decoration: const InputDecoration(
                          labelText: 'Estoque minimo',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_isEditing && item != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Text(
                      'Estoque atual: ${AppFormatters.quantity(item.quantity)} ${item.unit}. Para alterar o saldo, use a tela de movimentacoes.',
                    ),
                  )
                else
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Estoque inicial',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _numberValidator,
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Valor de custo',
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator,
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
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = InventoryItemDraft(
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      category: _categoryController.text.trim(),
      unit: _unitController.text.trim(),
      initialQuantity: _isEditing && widget.item != null
          ? widget.item!.quantity
          : AppFormatters.parseDecimal(_quantityController.text),
      minimumStock: AppFormatters.parseDecimal(_minimumStockController.text),
      price: AppFormatters.parseDecimal(_priceController.text),
    );

    Navigator.of(context).pop(draft);
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
      AppFormatters.parseDecimal(value);
    } catch (_) {
      return 'Numero invalido';
    }

    return null;
  }
}
