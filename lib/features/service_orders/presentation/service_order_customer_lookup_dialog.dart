part of 'service_order_dialogs.dart';

enum CustomerLookupDialogAction { requestNewCustomer }

enum _CustomerSearchMode {
  startsWithName,
  containsName,
  endsWithName,
  phone,
  document,
}

class ServiceOrderCustomerLookupDialog extends StatefulWidget {
  const ServiceOrderCustomerLookupDialog({
    super.key,
    required this.title,
    required this.customers,
    this.initialCustomerId,
  });

  final String title;
  final List<ServiceOrderCustomer> customers;
  final int? initialCustomerId;

  @override
  State<ServiceOrderCustomerLookupDialog> createState() =>
      _ServiceOrderCustomerLookupDialogState();
}

class _ServiceOrderCustomerLookupDialogState
    extends State<ServiceOrderCustomerLookupDialog> {
  late final TextEditingController _queryController;
  String _appliedQuery = '';
  _CustomerSearchMode _searchMode = _CustomerSearchMode.startsWithName;

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
    final dialogWidth = _responsiveDialogWidth(
      context,
      900,
      horizontalMargin: 88,
    );
    final dialogHeight = _responsiveDialogHeight(
      context,
      560,
      verticalMargin: 48,
    );
    final filteredCustomers = _buildFilteredCustomers();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade500),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildWindowHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  children: [
                    _buildTopSearchSection(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildResultsGrid(filteredCustomers)),
                    const SizedBox(height: 8),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowHeader() {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECD3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade500)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            splashRadius: 16,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }

  Widget _buildTopSearchSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout = constraints.maxWidth < 760;
        if (compactLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuerySection(),
              const SizedBox(height: 8),
              _buildSearchModeSection(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 10, child: _buildQuerySection()),
            const SizedBox(width: 8),
            Expanded(flex: 7, child: _buildSearchModeSection()),
          ],
        );
      },
    );
  }

  Widget _buildQuerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Digite abaixo o nome ou parte do nome do cliente a ser localizado:',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        const Text(
          '(F2=Novo cliente)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: _queryController,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _applySearch(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchModeSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forma de busca',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchModeOption(
                      _CustomerSearchMode.startsWithName,
                      'Inicio do nome',
                    ),
                    _searchModeOption(
                      _CustomerSearchMode.containsName,
                      'Qualquer parte do nome',
                    ),
                    _searchModeOption(
                      _CustomerSearchMode.endsWithName,
                      'Fim do nome/Sobrenome',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchModeOption(_CustomerSearchMode.phone, 'Telefone'),
                    _searchModeOption(_CustomerSearchMode.document, 'CNPJ/CPF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchModeOption(_CustomerSearchMode mode, String label) {
    final selected = _searchMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _searchMode = mode;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
            ),
            const SizedBox(width: 4),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid(List<ServiceOrderCustomer> filteredCustomers) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: Column(
        children: [
          _buildGridHeader(),
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum cliente encontrado.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                    ),
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final isSelected =
                          customer.id == widget.initialCustomerId;
                      return Material(
                        color: isSelected
                            ? const Color(0xFFE5EEF9)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(customer),
                          child: SizedBox(
                            height: 30,
                            child: Row(
                              children: [
                                _gridCell(customer.name, flex: 6),
                                _verticalDivider(),
                                _gridCell(_fallback(customer.phone), flex: 2),
                                _verticalDivider(),
                                _gridCell(
                                  _fallback(customer.document),
                                  flex: 2,
                                ),
                                _verticalDivider(),
                                _gridCell(_cityUf(customer.address), flex: 2),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridHeader() {
    return Container(
      height: 28,
      color: Colors.grey.shade200,
      child: Row(
        children: [
          _gridHeaderCell('Nome', flex: 6),
          _verticalDivider(),
          _gridHeaderCell('Telefone', flex: 2),
          _verticalDivider(),
          _gridHeaderCell('CPF/CNPJ', flex: 2),
          _verticalDivider(),
          _gridHeaderCell('Cidade-UF', flex: 2),
        ],
      ),
    );
  }

  Widget _gridHeaderCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _gridCell(String value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, color: Colors.grey.shade500);
  }

  Widget _buildBottomActions() {
    final newCustomerAction = TextButton.icon(
      onPressed: () {
        Navigator.of(
          context,
        ).pop(CustomerLookupDialogAction.requestNewCustomer);
      },
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
      label: const Text(
        'Novo cliente',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );

    final listButton = OutlinedButton(
      onPressed: _applySearch,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(92, 38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: const Text(
        'Listar',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );

    final cancelButton = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(100, 38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: const Text(
        'Cancelar',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout = constraints.maxWidth < 560;
        if (compactLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              newCustomerAction,
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [listButton, const SizedBox(width: 8), cancelButton],
              ),
            ],
          );
        }

        return Row(
          children: [
            newCustomerAction,
            const Spacer(),
            listButton,
            const SizedBox(width: 8),
            cancelButton,
          ],
        );
      },
    );
  }

  List<ServiceOrderCustomer> _buildFilteredCustomers() {
    final normalizedQuery = _appliedQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return widget.customers;
    }

    return widget.customers.where((customer) {
      final name = customer.name.toLowerCase();
      final document = customer.document.toLowerCase();
      final phone = customer.phone.toLowerCase();

      switch (_searchMode) {
        case _CustomerSearchMode.startsWithName:
          return name.startsWith(normalizedQuery);
        case _CustomerSearchMode.containsName:
          return name.contains(normalizedQuery);
        case _CustomerSearchMode.endsWithName:
          final nameParts = name
              .split(RegExp(r'\s+'))
              .where((part) => part.trim().isNotEmpty)
              .toList();
          return name.endsWith(normalizedQuery) ||
              nameParts.any((part) => part.endsWith(normalizedQuery));
        case _CustomerSearchMode.phone:
          return phone.contains(normalizedQuery);
        case _CustomerSearchMode.document:
          return document.contains(normalizedQuery);
      }
    }).toList();
  }

  void _applySearch() {
    setState(() {
      _appliedQuery = _queryController.text;
    });
  }

  String _fallback(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? '-' : normalized;
  }

  String _cityUf(String address) {
    final normalized = address.trim();
    if (normalized.isEmpty) {
      return '-';
    }

    final line = normalized.split('\n').last.trim();
    if (line.isEmpty) {
      return normalized;
    }

    final parts = line
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      final city = parts[parts.length - 2];
      final uf = parts.last;
      return '$city-$uf';
    }

    return line;
  }
}
