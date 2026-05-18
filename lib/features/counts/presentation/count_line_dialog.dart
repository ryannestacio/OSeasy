import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/stokeasy_logo.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/stock_counts.dart';

class CountLineDialog extends StatefulWidget {
  const CountLineDialog({super.key, required this.session, required this.line});

  final StockCountSession session;
  final StockCountLine line;

  @override
  State<CountLineDialog> createState() => _CountLineDialogState();
}

class _CountLineDialogState extends State<CountLineDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _quantityController;
  late final TextEditingController _countedByController;
  late final TextEditingController _noteController;

  late bool _selectedForExport;

  bool get _showSystemValues =>
      !widget.session.blindMode || !widget.session.isOpen;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.line.countedQuantity == null
          ? ''
          : AppFormatters.quantity(widget.line.countedQuantity!),
    );
    _countedByController = TextEditingController(
      text: widget.line.countedBy ?? widget.session.openedBy,
    );
    _noteController = TextEditingController(text: widget.line.lineNote);
    _selectedForExport = widget.line.selectedForExport;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _countedByController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conferir item'),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.line.itemName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.line.itemSku} | ${widget.line.category} | ${widget.line.unit}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatusChip(
                      label: widget.line.status.label,
                      color: _statusColor(widget.line.status),
                    ),
                    if (_showSystemValues)
                      StatusChip(
                        label:
                            'Sistema: ${AppFormatters.quantity(widget.line.systemQuantity)} ${widget.line.unit}',
                        color: AppPalette.navy,
                        leading: const StokEasyLogoBadge(
                          size: 16,
                          padding: EdgeInsets.all(2),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      )
                    else
                      const StatusChip(
                        label: 'Modo cego ativo',
                        color: AppPalette.navy,
                        icon: Icons.visibility_off_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_showSystemValues)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: const Text(
                      'O saldo do sistema esta oculto durante a contagem cega. Informe apenas o valor contado fisicamente.',
                    ),
                  ),
                if (!_showSystemValues) const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantidade contada (${widget.line.unit})',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _countedByController,
                  decoration: const InputDecoration(labelText: 'Contado por'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Observacoes do item',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedForExport,
                  onChanged: (value) {
                    setState(() {
                      _selectedForExport = value ?? false;
                    });
                  },
                  title: const Text('Selecionar para exportacao em PDF'),
                ),
                if (widget.line.countedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ultima contagem em ${AppFormatters.dateTime(widget.line.countedAt!)} por ${widget.line.countedBy ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
          icon: const Icon(Icons.save_rounded),
          label: const Text('Salvar contagem'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      UpdateStockCountLineDraft(
        countedQuantity: AppFormatters.parseDecimal(_quantityController.text),
        countedBy: _countedByController.text.trim(),
        note: _noteController.text.trim(),
        selectedForExport: _selectedForExport,
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
      AppFormatters.parseDecimal(value);
    } catch (_) {
      return 'Numero invalido';
    }

    return null;
  }

  Color _statusColor(StockCountLineStatus status) => switch (status) {
    StockCountLineStatus.pending => AppPalette.gold,
    StockCountLineStatus.counted => AppPalette.navy,
    StockCountLineStatus.divergent => AppPalette.black,
  };
}
