part of 'service_order_dialogs.dart';

class StockItemLookupDialog extends StatefulWidget {
  const StockItemLookupDialog({
    super.key,
    required this.stockItems,
    this.initialItemId,
  });

  final List<InventoryItem> stockItems;
  final int? initialItemId;

  @override
  State<StockItemLookupDialog> createState() => _StockItemLookupDialogState();
}

class _StockItemLookupDialogState extends State<StockItemLookupDialog> {
  late final TextEditingController _queryController;
  String _appliedQuery = '';
  String? _categoryFilter;
  bool _onlyWithBalance = true;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        widget.stockItems
            .map((item) => item.category.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final query = _appliedQuery.trim().toLowerCase();
    final filtered = widget.stockItems.where((item) {
      if (_onlyWithBalance && item.quantity <= 0) {
        return false;
      }
      if (_categoryFilter != null && item.category.trim() != _categoryFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack = '${item.name} ${item.sku} ${item.category} ${item.unit}'
          .toLowerCase();
      return haystack.contains(query);
    }).toList();

    return AlertDialog(
      title: const Text('Buscar peca do estoque'),
      content: SizedBox(
        width: 900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome, SKU, categoria ou unidade',
                    ),
                    onSubmitted: (_) => _applySearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _applySearch,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _categoryFilter,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      for (final category in categories)
                        DropdownMenuItem<String?>(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _categoryFilter = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Somente com saldo'),
                    value: _onlyWithBalance,
                    onChanged: (value) {
                      setState(() => _onlyWithBalance = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 360,
              child: filtered.isEmpty
                  ? const Center(child: Text('Nenhum item encontrado.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final selected = item.id == widget.initialItemId;
                        return ListTile(
                          selected: selected,
                          dense: true,
                          title: Text(item.name),
                          subtitle: Text(
                            'SKU: ${item.sku.isEmpty ? '-' : item.sku} | Cat: ${item.category.isEmpty ? '-' : item.category} | Saldo: ${AppFormatters.quantity(item.quantity)} ${item.unit}',
                          ),
                          trailing: Text(AppFormatters.currency(item.price)),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  void _applySearch() {
    setState(() {
      _appliedQuery = _queryController.text;
    });
  }
}
