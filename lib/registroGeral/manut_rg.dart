import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- FORMATTERS E VALIDATORS (Copiados do seu código original) ---

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length) {
         if(nonZeroIndex <= 4) buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length <= 5) return newValue;
    return newValue.copyWith(
      text: '${text.substring(0, 5)}-${text.substring(5, text.length > 8 ? 8 : text.length)}',
      selection: TextSelection.collapsed(offset: newValue.selection.end + 1),
    );
  }
}

// --- FIM DOS FORMATTERS E VALIDATORS ---


class PaginaComAbasLaterais extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const PaginaComAbasLaterais({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<PaginaComAbasLaterais> createState() => _PaginaComAbasLateraisState();
}

class _PaginaComAbasLateraisState extends State<PaginaComAbasLaterais> {
  static const double _breakpoint = 700.0;
  late String _currentDate;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  int _selectedIndex = 0;
  bool _isLoading = false;
  
  // Lista para popular os dropdowns de busca
  List<Map<String, dynamic>> _allControlData = [];

  // --- Controllers para todos os campos ---
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _bancoController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _transportadoraController = TextEditingController();
  
  final TextEditingController _campoComum1Controller = TextEditingController();
  final TextEditingController _campoComum2Controller = TextEditingController();
  final TextEditingController _campoComum3Controller = TextEditingController();


  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllControlData();
    // Adiciona listeners para os campos de busca para lidar com a limpeza
    _campoComum1Controller.addListener(_handleClearCheck);
    _campoComum2Controller.addListener(_handleClearCheck);
    _campoComum3Controller.addListener(_handleClearCheck);
  }
  
  // Helper para obter a referência da coleção
  CollectionReference get _collectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('manut_rg')
      .collection('items');

  // Busca todos os dados para popular os dropdowns
  Future<void> _fetchAllControlData() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _collectionRef.get();
      _allControlData = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar sugestões: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Preenche todos os campos com base no item selecionado no dropdown
  void _populateAllFields(Map<String, dynamic> data) {
    setState(() {
      _campoComum1Controller.text = data['campoComum1'] ?? '';
      _campoComum2Controller.text = data['campoComum2'] ?? '';
      _campoComum3Controller.text = data['campoComum3'] ?? '';
      _empresaController.text = data['empresa'] ?? '';
      _cnpjController.text = data['cnpj'] ?? '';
      _bancoController.text = data['banco'] ?? '';
      _clienteController.text = data['naturezaCliente'] ?? '';
      _transportadoraController.text = data['naturezaTransportadora'] ?? '';
    });
  }

  // Limpa os campos dependentes quando a busca é limpa
  void _clearDependentFields() {
    _empresaController.clear();
    _cnpjController.clear();
    _bancoController.clear();
    _clienteController.clear();
    _transportadoraController.clear();
  }

  // NOVA FUNÇÃO: Limpa apenas os campos de busca
  void _clearSearchFields() {
    _campoComum1Controller.clear();
    _campoComum2Controller.clear();
    _campoComum3Controller.clear();
  }

  // Verifica se os campos de busca estão vazios para limpar o formulário
  void _handleClearCheck() {
    if (_campoComum1Controller.text.isEmpty &&
        _campoComum2Controller.text.isEmpty &&
        _campoComum3Controller.text.isEmpty) {
      setState(() {
        _clearDependentFields();
      });
    }
  }
  
  // Salva os dados de TODAS as abas no Firebase
  Future<void> _saveData() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O campo "Info Comum 1" é obrigatório para salvar.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, corrija os erros antes de salvar.')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    final dataToSave = {
      'campoComum1': _campoComum1Controller.text,
      'campoComum2': _campoComum2Controller.text,
      'campoComum3': _campoComum3Controller.text,
      'empresa': _empresaController.text,
      'cnpj': _cnpjController.text,
      'banco': _bancoController.text,
      'naturezaCliente': _clienteController.text,
      'naturezaTransportadora': _transportadoraController.text,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'atualizado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      await _collectionRef.doc(docId).set(dataToSave, SetOptions(merge: true));
      await _fetchAllControlData(); // Atualiza a lista de sugestões
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados de controle salvos com sucesso!')),
      );
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _empresaController.dispose();
    _cnpjController.dispose();
    _bancoController.dispose();
    _clienteController.dispose();
    _transportadoraController.dispose();
    // Remove os listeners antes de fazer o dispose
    _campoComum1Controller.removeListener(_handleClearCheck);
    _campoComum2Controller.removeListener(_handleClearCheck);
    _campoComum3Controller.removeListener(_handleClearCheck);
    _campoComum1Controller.dispose();
    _campoComum2Controller.dispose();
    _campoComum3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Stack(
        children: [
          Column(
            children: [
              TopAppBar(
                onBackPressed: () {
                   Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaSubPrincipal(
                        mainCompanyId: widget.mainCompanyId,
                        secondaryCompanyId: widget.secondaryCompanyId,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                },
                currentDate: _currentDate,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > _breakpoint) {
                      return _buildDesktopLayout(constraints);
                    } else {
                      return _buildMobileLayout();
                    }
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: AppDrawer(
            parentMaxWidth: constraints.maxWidth,
            breakpoint: _breakpoint,
            mainCompanyId: widget.mainCompanyId,
            secondaryCompanyId: widget.secondaryCompanyId,
            userRole: widget.userRole,
          ),
        ),
        Expanded(
          flex: 3,
          child: Form( 
            key: _formKey,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                  child: Text('Controle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
                //_buildCamposDeBusca(),
                const Divider(height: 20, thickness: 2),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildDynamicCentralArea(),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildVerticalTabMenu(),
                      ),
                    ],
                  ),
                ),
                _buildSaveButton(), 
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout() {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
              child: Text('Controle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            //_buildCamposDeBusca(),
            const Divider(height: 20, thickness: 2),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: 'Geral'),
                        Tab(text: 'Financeiro'),
                        Tab(text: 'Operacional'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildAbaDadosGerais(),
                          _buildAbaTelefone(),
                          _buildAbaFisicaJuridica(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
             _buildSaveButton(),
          ],
        ),
    );
  }
  
  Widget _buildVerticalTabMenu() {
    return Container(
      margin: const EdgeInsets.only(top: 0, right: 25, bottom: 0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabButton(title: 'Dados Gerais', index: 0),
            _buildTabButton(title: 'Telefone', index: 1),
            _buildTabButton(title: 'Físisca/Jurídica', index: 2),
            _buildTabButton(title: 'Observação', index: 3),
            _buildTabButton(title: 'Adicional', index: 4),
            _buildTabButton(title: 'Bancária', index: 5),
            _buildTabButton(title: 'Comercial', index: 6),
            _buildTabButton(title: 'Apelido/fantasia', index: 7),
            _buildTabButton(title: 'Cobrança', index: 8),
            _buildTabButton(title: 'Correspondência', index: 9),
            _buildTabButton(title: 'Endereço entrega', index: 10),
            _buildTabButton(title: 'Contatos', index: 11),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, right: 8, left: 8),
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedIndex = index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.blue[100],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(title),
      ),
    );
  }

  Widget _buildDynamicCentralArea() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (_selectedIndex) {
        0 => _buildAbaDadosGerais(key: const ValueKey('aba0')),
        1 => _buildAbaTelefone(key: const ValueKey('aba1')),
        2 => _buildAbaFisicaJuridica(key: const ValueKey('aba2')),
        /*3 => _buildAbaObservacao(key: const ValueKey('aba3')),
        4 => _buildAbaAdicional(key: const ValueKey('aba4')),
        5 => _buildAbaBancaria(key: const ValueKey('aba5')),
        6 => _buildAbaComercial(key: const ValueKey('aba6')),
        7 => _buildAbaApelidoFantasia(key: const ValueKey('aba7')),
        8 => _buildAbaCobranca(key: const ValueKey('aba8')),
        9 => _buildAbaCorrespondencia(key: const ValueKey('aba9')),
        10 => _buildAbaEnderecoEntrega(key: const ValueKey('aba10')),
        11 => _buildAbaContatos(key: const ValueKey('aba11')),*/
        _ => _buildAbaDadosGerais(key: const ValueKey('default')),
      },
    );
  }
  
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: _saveData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('SALVAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget para a nova linha de campos de busca com Autocomplete
 /* Widget _buildCamposDeBusca() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dados de Busca", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildAutocompleteField(_campoComum1Controller, "Info Comum 1 (ID)", 'campoComum1', isRequired: true),
                    const SizedBox(width: 10),
                    _buildAutocompleteField(_campoComum2Controller, "Info Comum 2", 'campoComum2'),
                    const SizedBox(width: 10),
                    _buildAutocompleteField(_campoComum3Controller, "Info Comum 3", 'campoComum3'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Botão para limpar os campos de busca
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Limpar Busca',
                onPressed: _clearSearchFields,
              ),
            ],
          ),
        ],
      ),
    );
  }*/
  
  // Widget reutilizável para criar um campo Autocomplete
  Widget _buildAutocompleteField(TextEditingController controller, String label, String fieldKey, {bool isRequired = false}) {
    return Expanded(
      child: Autocomplete<Map<String, dynamic>>(
        displayStringForOption: (option) => option[fieldKey] as String,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Map<String, dynamic>>.empty();
          }
          // Filtra a lista de dados para sugestões
          return _allControlData.where((Map<String, dynamic> option) {
            final fieldValue = option[fieldKey]?.toString().toLowerCase() ?? '';
            return fieldValue.contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (Map<String, dynamic> selection) {
          _populateAllFields(selection);
          // Tira o foco para fechar o dropdown
          FocusScope.of(context).unfocus();
        },
        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.text != fieldController.text) {
                fieldController.text = controller.text;
              }
           });

          return CustomInputField(
            controller: fieldController,
            focusNode: focusNode,
            label: label,
            validator: isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null,
            onChanged: (value) {
              controller.text = value; 
              
              // Lógica de busca por digitação
              final exactMatches = _allControlData.where((item) => 
                (item[fieldKey] as String?)?.trim().toLowerCase() == value.trim().toLowerCase()
              ).toList();

              if (exactMatches.length == 1) {
                _populateAllFields(exactMatches.first);
                FocusScope.of(context).unfocus();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildAbaDadosGerais({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25,0,25,25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[100],
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 1,
                      child: _buildAutocompleteField(_campoComum1Controller, "CPF/CNPJ", 'campoComum1', isRequired: true)),
                    const SizedBox(width: 10),
                    Expanded(flex: 2,
                      child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                    const SizedBox(width: 10),
                    Expanded(flex: 3,
                      child: _buildAutocompleteField(_campoComum3Controller, "Razao Social", 'campoComum3')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Botão para limpar os campos de busca
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Limpar Busca',
                onPressed: _clearSearchFields,
              ),
            ],
          ),
              const Text("Aba: Dados Gerais", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "CEP", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Endereço", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Número", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Complemento", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                ],
              ),
              //const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Bairro", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Cidade", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "UF", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Cx. Postal", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                ],
              ),
              Divider(thickness: 2,color: Colors.blue,height: 10,indent: 40,endIndent: 40,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Como nos conheceu", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Portador", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 2,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Tab Desconto", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  
                  
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Inscr. Suframa", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Inscr. Produtor.", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Inscr. Municipal", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),               
                ],
              ),
              Divider(thickness: 2,color: Colors.blue,height: 10,indent: 40,endIndent: 40,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Vendedor", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Atendente", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Área", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Situação", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbaTelefone({Key? key}) {
     return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25,0,25,25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[100],
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 1,
                      child: _buildAutocompleteField(_campoComum1Controller, "CPF/CNPJ", 'campoComum1', isRequired: true)),
                    const SizedBox(width: 10),
                    Expanded(flex: 2,
                      child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                    const SizedBox(width: 10),
                    Expanded(flex: 3,
                      child: _buildAutocompleteField(_campoComum3Controller, "Razao Social", 'campoComum3')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Botão para limpar os campos de busca
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Limpar Busca',
                onPressed: _clearSearchFields,
              ),
            ],
          ),
              const Text("Aba: Telefone", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "SQ", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "País", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Operadora", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "DDD", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                ],
              ),
              //const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Nro", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Ramal", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Tipo", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _empresaController, 
                      label: "Contato", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                ],
              ),
              Divider(thickness: 2,color: Colors.blue,height: 10,indent: 40,endIndent: 40,),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbaFisicaJuridica({Key? key}) {
     return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25,0,25,25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange[100],
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildAutocompleteField(_campoComum1Controller, "Info Comum 1 (ID)", 'campoComum1', isRequired: true),
                    const SizedBox(width: 10),
                    _buildAutocompleteField(_campoComum2Controller, "Info Comum 2", 'campoComum2'),
                    const SizedBox(width: 10),
                    _buildAutocompleteField(_campoComum3Controller, "Info Comum 3", 'campoComum3'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Botão para limpar os campos de busca
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Limpar Busca',
                onPressed: _clearSearchFields,
              ),
            ],
          ),
              const Text("Aba: Operacional", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              CustomInputField(controller: _transportadoraController, label: "Natureza Transportadora"),
            ],
          ),
        ),
      ),
    );
  }
}
