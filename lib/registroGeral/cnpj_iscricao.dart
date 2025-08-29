import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../reutilizaveis/barraSuperior.dart';
import '../reutilizaveis/customImputField.dart';
import '../reutilizaveis/menuLateral.dart';
import '../reutilizaveis/tela_base.dart';
import '../services/manut_rg_service.dart';

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length <= 5) return newValue;
    
    // Cria o texto formatado primeiro
    final formattedText = '${text.substring(0, 5)}-${text.substring(5, text.length > 8 ? 8 : text.length)}';
    
    // Retorna o texto formatado e posiciona o cursor no final dele
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    var newText = '';
    if (text.length > 12) {
      newText =
          '${text.substring(0, 2)}.${text.substring(2, 5)}.${text.substring(5, 8)}/${text.substring(8, 12)}-${text.substring(12, text.length)}';
    } else if (text.length > 8) {
      newText =
          '${text.substring(0, 2)}.${text.substring(2, 5)}.${text.substring(5, 8)}/${text.substring(8, text.length)}';
    } else if (text.length > 5) {
      newText =
          '${text.substring(0, 2)}.${text.substring(2, 5)}.${text.substring(5, text.length)}';
    } else if (text.length > 2) {
      newText = '${text.substring(0, 2)}.${text.substring(2, text.length)}';
    } else {
      newText = text;
    }
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// Reutilizando os formatters do seu outro arquivo


class ManutRgCnpjInscricao extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  static const double _breakpoint = 700.0;

  const ManutRgCnpjInscricao({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<ManutRgCnpjInscricao> createState() => _ManutRgCnpjInscricaoState();
}

class _ManutRgCnpjInscricaoState extends State<ManutRgCnpjInscricao> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ManutRgService _manutRgService = ManutRgService();

  static const double _breakpoint = 700.0;

  bool _isLoading = false;
  Map<String, dynamic>? _rgData;
  List<Map<String, dynamic>> _rgSuggestions = [];
  List<Map<String, dynamic>> _allCidades = [];
  List<Map<String, dynamic>> _allSituacoes = [];
  List<Map<String, dynamic>> _allVendedores = []; // Assumindo que você terá uma tabela de vendedores

  

  // --- Controllers para todos os campos da tela ---
  final _codigoController = TextEditingController();
  final _fisicaJuridicaController = TextEditingController();
  final _dataInclusaoController = TextEditingController();

  // Coluna Esquerda
  final _razaoCompletoController = TextEditingController();
  final _razaoController = TextEditingController();
  final _vendedorController = TextEditingController();
  final _situacaoController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cepController = TextEditingController();
  final _municipioController = TextEditingController();
  final _cnpjEsquerdaController = TextEditingController();
  final _inscEstadualEsquerdaController = TextEditingController();
  
  // Coluna Direita
  final _cnpjDireitaController = TextEditingController();
  final _inscEstadualDireitaController = TextEditingController();
  
  // Variáveis de estado para os checkboxes
  String? _selectedContribIcms;
  String? _selectedRevenda;
  
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado");

      // Carrega dados para sugestões e dropdowns
      final results = await Future.wait([
        _manutRgService.getRgSuggestions(token),
        _manutRgService.getDadosAuxiliares('cidades', token),
        _manutRgService.getDadosAuxiliares('situacoes', token),
        // Adicione aqui a busca por vendedores se tiver um endpoint
      ]);

      _rgSuggestions = results[0];
      _allCidades = results[1];
      _allSituacoes = results[2];

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados iniciais: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  

  void _populateFields(Map<String, dynamic> data) {
    setState(() {
      _rgData = data; // Armazena todos os dados carregados

      // Popula os controllers com os dados
      _codigoController.text = data['codigo_interno'] ?? '';
      _dataInclusaoController.text = data['data_inclusao'] != null 
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(data['data_inclusao'])) 
          : '';
      
      if (data['tipo_pessoa'] == 'fisica') {
        _fisicaJuridicaController.text = 'Física';
      } else if (data['tipo_pessoa'] == 'juridica') {
        _fisicaJuridicaController.text = 'Jurídica';
      } else {
        _fisicaJuridicaController.text = '';
      }

      // Coluna Esquerda
      _razaoCompletoController.text = data['razao_social'] ?? '';
      _razaoController.text = data['razao_social'] ?? ''; // Ou um campo de nome fantasia se preferir
      _vendedorController.text = data['vendedor_id'] ?? '';
      _situacaoController.text = data['situacao_id'] ?? '';
      _enderecoController.text = data['endereco'] ?? '';
      _bairroController.text = data['bairro'] ?? '';
      _cepController.text = data['cep'] ?? '';
      _cnpjEsquerdaController.text = data['id'] ?? ''; // O ID principal é o CPF/CNPJ
      _inscEstadualEsquerdaController.text = data['insc_estadual'] ?? '';
      
      // Lógica para exibir nome do município em vez do ID
      final cidade = _allCidades.firstWhereOrNull((c) => c['id'] == data['cidade_id']);
      _municipioController.text = cidade != null ? cidade['cidade'] : data['cidade_id'] ?? '';

      // Coluna Direita
      _cnpjDireitaController.text = data['cnpj_juridico'] ?? '';
      _inscEstadualDireitaController.text = data['insc_estadual'] ?? '';
      _selectedContribIcms = data['contrib_icms'];
      _selectedRevenda = data['revenda'];
    });
  }

  void _clearFields() {
    setState(() {
      _rgData = null;
      _codigoController.clear();
      _fisicaJuridicaController.clear();
      _dataInclusaoController.clear();
      _razaoCompletoController.clear();
      _razaoController.clear();
      _vendedorController.clear();
      _situacaoController.clear();
      _enderecoController.clear();
      _bairroController.clear();
      _cepController.clear();
      _municipioController.clear();
      _cnpjEsquerdaController.clear();
      _inscEstadualEsquerdaController.clear();
      _cnpjDireitaController.clear();
      _inscEstadualDireitaController.clear();
      _selectedContribIcms = null;
      _selectedRevenda = null;
    });
  }

  Future<void> _loadDataByCodigo(String codigo) async {
    final rg = _rgSuggestions.firstWhereOrNull((r) => r['codigo_interno'] == codigo);
    if (rg != null && rg['id'] != null) {
      await _loadDataById(rg['id']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código não encontrado.')));
    }
  }

  Future<void> _loadDataById(String rgId) async {
    if (rgId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _manutRgService.getRgCompleto(rgId, token);
      if (data.isNotEmpty) {
        _populateFields(data);
      } else {
        _clearFields();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro não encontrado.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false) || _rgData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, carregue um registro e corrija os erros antes de salvar.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Reconstruir o mapa de dados com as alterações da tela
    final dataToSave = Map<String, dynamic>.from(_rgData!);
    dataToSave.addAll({
      'codigo_interno': _codigoController.text,
      'razao_social': _razaoCompletoController.text,
      'vendedor_id': _vendedorController.text,
      'situacao_id': _situacaoController.text,
      'endereco': _enderecoController.text,
      'bairro': _bairroController.text,
      'cep': _cepController.text,
      'cidade_id': _allCidades.firstWhereOrNull((c) => c['cidade'] == _municipioController.text)?['id'] ?? _rgData!['cidade_id'],
      'id': _cnpjEsquerdaController.text,
      'cnpj_juridico': _cnpjDireitaController.text,
      'insc_estadual': _inscEstadualDireitaController.text,
      'contrib_icms': _selectedContribIcms,
      'revenda': _selectedRevenda,
    });
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      await _manutRgService.saveData(dataToSave, token);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados salvos com sucesso!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Stack(
        children: [
          Column(
            children: [
              TopAppBar(
                currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                onBackPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaSubPrincipal(
                        mainCompanyId: widget.mainCompanyId,
                        secondaryCompanyId: widget.secondaryCompanyId,
                        userRole: widget.userRole,
                      ),
                    ),
                  ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > _breakpoint) {
                      return _buildDesktopLayout(constraints);
                    } else {
                      return _buildDesktopLayout(constraints);
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
            ),
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
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: _buildMainContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Manut RG "CNPJ e Inscrição"',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 20),
          _buildTopFields(),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLeftColumn()),
              const SizedBox(width: 20),
              Expanded(child: _buildRightColumn()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopFields() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (option) => option['codigo_interno'] ?? '',
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable.empty();
              }
              return _rgSuggestions.where((option) {
                return option['codigo_interno']
                    .toString()
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (selection) {
              _loadDataById(selection['id']);
              FocusScope.of(context).unfocus();
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              // Sincroniza o controller do autocomplete com o nosso controller principal
              if (_codigoController.text != controller.text) {
                 controller.text = _codigoController.text;
              }
              return CustomInputField(
                controller: controller,
                focusNode: focusNode,
                label: 'Código',
                //onSubmitted: (_) => onFieldSubmitted(),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: CustomInputField(
            controller: _fisicaJuridicaController,
            label: 'Física/Jurídica',
            readOnly: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: CustomInputField(
            controller: _dataInclusaoController,
            label: 'Data de Inclusão',
            readOnly: true,
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        CustomInputField(controller: _razaoCompletoController, label: 'Razão Completo'),
        const SizedBox(height: 0),
        CustomInputField(controller: _razaoController, label: 'Razão'),
        const SizedBox(height: 0),
        CustomInputField(controller: _vendedorController, label: 'Vendedor'),
        const SizedBox(height: 00),
        CustomInputField(controller: _situacaoController, label: 'Situação'),
        const SizedBox(height: 0),
        CustomInputField(controller: _enderecoController, label: 'Endereço'),
        const SizedBox(height: 0),
        CustomInputField(controller: _bairroController, label: 'Bairro'),
        const SizedBox(height: 0),
        CustomInputField(controller: _cepController, label: 'CEP', inputFormatters: [CepInputFormatter()], maxLength: 9,),
        const SizedBox(height: 0),
        CustomInputField(controller: _municipioController, label: 'Município'),
        const SizedBox(height: 0),
        CustomInputField(controller: _cnpjEsquerdaController, label: 'CNPJ', inputFormatters: [CnpjInputFormatter()], maxLength: 18,),
        const SizedBox(height: 0),
        CustomInputField(controller: _inscEstadualEsquerdaController, label: 'Inscrição Estadual'),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        CustomInputField(controller: _cnpjDireitaController, label: 'CNPJ', inputFormatters: [CnpjInputFormatter()], maxLength: 18,),
        const SizedBox(height: 0),
        CustomInputField(controller: _inscEstadualDireitaController, label: 'Inscrição Estadual'),
        const SizedBox(height: 20),
        _buildSimNaoCheckboxGroup(
          label: 'Contribuinte ICMS',
          value: _selectedContribIcms,
          onChanged: (newValue) {
            setState(() {
              _selectedContribIcms = newValue;
            });
          },
        ),
        const SizedBox(height: 10),
        _buildSimNaoCheckboxGroup(
          label: 'Revenda',
          value: _selectedRevenda,
          onChanged: (newValue) {
            setState(() {
              _selectedRevenda = newValue;
            });
          },
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _saveData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(150, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  // Widget auxiliar para criar os grupos de checkbox "Sim/Não"
  Widget _buildSimNaoCheckboxGroup({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sim'),
              Checkbox(
                value: value == 'Sim',
                onChanged: (bool? isChecked) {
                  if (isChecked ?? false) {
                    onChanged('Sim');
                  }
                },
              ),
              const SizedBox(width: 20),
              const Text('Não'),
              Checkbox(
                value: value == 'Não',
                onChanged: (bool? isChecked) {
                  if (isChecked ?? false) {
                    onChanged('Não');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}