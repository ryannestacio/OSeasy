import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../domain/stock_counts.dart';

class CloseStockCountDialog extends StatefulWidget {
  const CloseStockCountDialog({super.key, required this.session});

  final StockCountSession session;

  @override
  State<CloseStockCountDialog> createState() => _CloseStockCountDialogState();
}

class _CloseStockCountDialogState extends State<CloseStockCountDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _closedByController;
  late final TextEditingController _notesController;

  bool get _canClose => widget.session.pendingItems == 0;

  @override
  void initState() {
    super.initState();
    _closedByController = TextEditingController(text: widget.session.openedBy);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _closedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fechar contagem'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Itens previstos: ${widget.session.totalItems}\n'
                  'Itens conferidos: ${widget.session.countedItems}\n'
                  'Divergencias: ${widget.session.divergentItems}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                if (!_canClose)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.subtleGold,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppPalette.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Conclua os ${widget.session.pendingItems} itens pendentes antes de encerrar a contagem.',
                    ),
                  ),
                if (!_canClose) const SizedBox(height: 14),
                TextFormField(
                  controller: _closedByController,
                  decoration: const InputDecoration(labelText: 'Quem encerrou'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observacoes de fechamento',
                  ),
                  maxLines: 3,
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
          onPressed: _canClose ? _submit : null,
          icon: const Icon(Icons.lock_rounded),
          label: const Text('Fechar contagem'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      CloseStockCountDraft(
        closedBy: _closedByController.text.trim(),
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
