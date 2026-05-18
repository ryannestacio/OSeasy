part of 'service_order_dialogs.dart';

class ServiceOrderCustomerDialog extends StatefulWidget {
  const ServiceOrderCustomerDialog({super.key});

  @override
  State<ServiceOrderCustomerDialog> createState() =>
      _ServiceOrderCustomerDialogState();
}

class _ServiceOrderCustomerDialogState
    extends State<ServiceOrderCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _tradeNameController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _documentController;
  late final TextEditingController _stateRegistrationController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _streetController;
  late final TextEditingController _streetNumberController;
  late final TextEditingController _complementController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateCodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _businessPhoneController;
  late final TextEditingController _mobilePhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _fiscalEmailController;
  late final TextEditingController _notesController;
  late final TextEditingController _groupController;
  late final TextEditingController _addressController;
  String _personType = 'Pessoa Fisica';
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _tradeNameController = TextEditingController();
    _contactNameController = TextEditingController();
    _birthdayController = TextEditingController();
    _documentController = TextEditingController();
    _stateRegistrationController = TextEditingController();
    _zipCodeController = TextEditingController();
    _streetController = TextEditingController();
    _streetNumberController = TextEditingController();
    _complementController = TextEditingController();
    _neighborhoodController = TextEditingController();
    _cityController = TextEditingController();
    _stateCodeController = TextEditingController();
    _countryController = TextEditingController(text: 'Brasil');
    _phoneController = TextEditingController();
    _businessPhoneController = TextEditingController();
    _mobilePhoneController = TextEditingController();
    _emailController = TextEditingController();
    _fiscalEmailController = TextEditingController();
    _notesController = TextEditingController();
    _groupController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tradeNameController.dispose();
    _contactNameController.dispose();
    _birthdayController.dispose();
    _documentController.dispose();
    _stateRegistrationController.dispose();
    _zipCodeController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _businessPhoneController.dispose();
    _mobilePhoneController.dispose();
    _emailController.dispose();
    _fiscalEmailController.dispose();
    _notesController.dispose();
    _groupController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Colors.green.shade700),
      ),
      child: SizedBox(
        width: 920,
        height: 650,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFE3E4D2)),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildNameSection(),
                          const SizedBox(height: 8),
                          _buildContactSection(),
                          const SizedBox(height: 8),
                          _buildDocumentSection(),
                          const SizedBox(height: 8),
                          _buildAddressSection(),
                          const SizedBox(height: 8),
                          _buildPhonesSection(),
                          const SizedBox(height: 8),
                          _buildEmailsSection(),
                          const SizedBox(height: 8),
                          _buildNotesSection(),
                          const SizedBox(height: 8),
                          _buildBottomBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 28,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade300],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Incluindo um novo cliente.',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      children: [
        _fieldBlock(
          label: 'Razao Social/Nome',
          child: _input(
            controller: _nameController,
            validator: _requiredValidator,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 6),
        _fieldBlock(
          label: 'Nome Fantasia',
          optionalLabel: '(opcional)',
          child: _input(controller: _tradeNameController),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _fieldBlock(
            label: 'Contato',
            child: _input(controller: _contactNameController),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _fieldBlock(
            label: 'Aniversario',
            child: _input(
              controller: _birthdayController,
              hintText: 'dd/mm/aaaa',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _fieldBlock(
            label: 'CNPJ/CPF',
            child: _input(controller: _documentController),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _fieldBlock(
            label: 'Ins. Est./RG',
            child: _input(controller: _stateRegistrationController),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _fieldBlock(
            label: 'Pessoa',
            child: _dropdown(
              initialValue: _personType,
              items: const ['Pessoa Fisica', 'Pessoa Juridica'],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _personType = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _fieldBlock(
                label: 'CEP',
                child: _input(controller: _zipCodeController),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 9,
              child: _fieldBlock(
                label: 'Endereco',
                child: _input(controller: _streetController),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _fieldBlock(
                label: 'Numero',
                child: _input(controller: _streetNumberController),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _fieldBlock(
                label: 'Complemento',
                child: _input(controller: _complementController),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _fieldBlock(
                label: 'Bairro',
                child: _input(controller: _neighborhoodController),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: _fieldBlock(
                label: 'Cidade',
                child: _input(controller: _cityController),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _fieldBlock(
                label: 'UF',
                child: _input(controller: _stateCodeController),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _fieldBlock(
                label: 'Pais',
                child: _input(controller: _countryController),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhonesSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _fieldBlock(
            label: 'Telefone',
            child: _input(controller: _phoneController),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _fieldBlock(
            label: 'Comercial/FAX',
            child: _input(controller: _businessPhoneController),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _fieldBlock(
            label: 'Celular/Whatsapp',
            child: _input(controller: _mobilePhoneController),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _fieldBlock(
            label: 'Email',
            child: _input(controller: _emailController),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _fieldBlock(
            label: 'Email para notas fiscais',
            child: _input(controller: _fiscalEmailController),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _fieldBlock(
      label: 'Observacoes',
      child: TextFormField(
        controller: _notesController,
        minLines: 4,
        maxLines: 4,
        style: const TextStyle(fontSize: 14),
        decoration: _inputDecoration(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _fieldBlock(
            label: 'Grupo',
            child: _input(controller: _groupController),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: _fieldBlock(
            label: 'Sexo',
            child: _dropdown(
              initialValue: _gender.isEmpty ? null : _gender,
              hintText: 'Selecione',
              items: const ['Masculino', 'Feminino', 'Outro'],
              onChanged: (value) {
                setState(() {
                  _gender = value ?? '';
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Gravar'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _fieldBlock({
    required String label,
    required Widget child,
    String? optionalLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (optionalLabel != null) ...[
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: optionalLabel,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? hintText,
    bool autofocus = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  Widget _dropdown({
    required String? initialValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hintText,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(
        initialValue == null ? null : '$initialValue-${items.length}',
      ),
      initialValue: initialValue,
      isExpanded: true,
      onChanged: onChanged,
      hint: hintText == null ? null : Text(hintText),
      decoration: _inputDecoration(),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      style: const TextStyle(fontSize: 14, color: Colors.black),
      dropdownColor: const Color(0xFFF0F0E8),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black54),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black45),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black87),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final address = _composeAddress();

    Navigator.of(context).pop(
      ServiceOrderCustomerDraft(
        name: _nameController.text.trim(),
        tradeName: _tradeNameController.text.trim(),
        contactName: _contactNameController.text.trim(),
        birthday: _birthdayController.text.trim(),
        document: _documentController.text.trim(),
        stateRegistration: _stateRegistrationController.text.trim(),
        personType: _personType.trim(),
        zipCode: _zipCodeController.text.trim(),
        street: _streetController.text.trim(),
        streetNumber: _streetNumberController.text.trim(),
        complement: _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        stateCode: _stateCodeController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
        mobilePhone: _mobilePhoneController.text.trim(),
        email: _emailController.text.trim(),
        fiscalEmail: _fiscalEmailController.text.trim(),
        notes: _notesController.text.trim(),
        customerGroup: _groupController.text.trim(),
        gender: _gender.trim(),
        address: address,
      ),
    );
  }

  String _composeAddress() {
    final legacyAddress = _addressController.text.trim();
    if (legacyAddress.isNotEmpty) {
      return legacyAddress;
    }

    final firstLineParts = <String>[
      _streetController.text.trim(),
      _streetNumberController.text.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (_complementController.text.trim().isNotEmpty) {
      firstLineParts.add(_complementController.text.trim());
    }

    final lines = <String>[
      if (firstLineParts.isNotEmpty) firstLineParts.join(', '),
      if (_neighborhoodController.text.trim().isNotEmpty)
        _neighborhoodController.text.trim(),
      if (_zipCodeController.text.trim().isNotEmpty ||
          _countryController.text.trim().isNotEmpty)
        [
          if (_zipCodeController.text.trim().isNotEmpty)
            'CEP ${_zipCodeController.text.trim()}',
          if (_countryController.text.trim().isNotEmpty)
            _countryController.text.trim(),
        ].join(' - '),
      if (_cityController.text.trim().isNotEmpty ||
          _stateCodeController.text.trim().isNotEmpty)
        [
          _cityController.text.trim(),
          _stateCodeController.text.trim(),
        ].where((part) => part.isNotEmpty).join(', '),
    ];

    return lines.join('\n').trim();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }
}
