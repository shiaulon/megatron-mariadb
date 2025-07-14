import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaEstadoXImposto.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- FORMATTERS E VALIDATORS (Copiados do seu código original) ---

// Validator para CNPJ
String? _cnpjValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo CNPJ é obrigatório.';
  }
  // Remove formatação para validação
  String cnpj = value.replaceAll(RegExp(r'\D'), '');

  if (cnpj.length != 14) {
    return 'CNPJ deve ter 14 dígitos.';
  }

  // Verifica se todos os dígitos são iguais (CNPJs inválidos comuns)
  if (RegExp(r'^(\d)\1*$').hasMatch(cnpj)) {
    return 'CNPJ inválido.';
  }

  List<int> numbers = cnpj.split('').map(int.parse).toList();

  // Validação do primeiro dígito verificador
  int sum = 0;
  List<int> weight1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  for (int i = 0; i < 12; i++) {
    sum += numbers[i] * weight1[i];
  }
  int remainder = sum % 11;
  int dv1 = remainder < 2 ? 0 : 11 - remainder;

  if (dv1 != numbers[12]) {
    return 'CNPJ inválido.';
  }

  // Validação do segundo dígito verificador
  sum = 0;
  List<int> weight2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  for (int i = 0; i < 13; i++) {
    sum += numbers[i] * weight2[i];
  }
  remainder = sum % 11;
  int dv2 = remainder < 2 ? 0 : 11 - remainder;

  if (dv2 != numbers[13]) {
    return 'CNPJ inválido.';
  }

  return null; // CNPJ válido
}


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
  List<Map<String, dynamic>> _allCidades = [];
  List<Map<String, dynamic>> _allCargos = []; 

  // --- Controllers para todos os campos ---
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();
  final TextEditingController _cxPostalController = TextEditingController();
  final TextEditingController _comoNosConheceuController = TextEditingController();
  final TextEditingController _portadorController = TextEditingController();
  final TextEditingController _tabDescontoController = TextEditingController();
  final TextEditingController _inscSuframaController = TextEditingController();
  final TextEditingController _inscProdutorController = TextEditingController();
  final TextEditingController _inscMunicipalController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final TextEditingController _atendenteController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _situacaoController = TextEditingController();
  final TextEditingController _sqController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _operadoraController = TextEditingController();
  final TextEditingController _dddController = TextEditingController();
  final TextEditingController _nroController = TextEditingController();
  final TextEditingController _ramalController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _contatoController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _inscEstadualController = TextEditingController();
  final TextEditingController _contribIcmsController = TextEditingController();
  final TextEditingController _revendaController = TextEditingController();
  final TextEditingController _confidencialController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _observacaoNfController = TextEditingController();
  final TextEditingController _eMailController = TextEditingController();
  final TextEditingController _eMailCobranController = TextEditingController();
  final TextEditingController _eMailNfController = TextEditingController();
  final TextEditingController _socioController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  final TextEditingController _resulCargoController = TextEditingController();
  final TextEditingController _participacaoController = TextEditingController();
  final TextEditingController _sequenciaController = TextEditingController();
  final TextEditingController _nomeRefBancariaController = TextEditingController();
  final TextEditingController _resulNomeController = TextEditingController();
  final TextEditingController _enderecoRefBancariaController = TextEditingController();
  final TextEditingController _resulEnderecoController = TextEditingController();
  final TextEditingController _cidadeRefBancariaController = TextEditingController();
  final TextEditingController _contatoRefBancariaController = TextEditingController();
  final TextEditingController _telefoneRefBancariaController = TextEditingController();
  final TextEditingController _emailRefBancariaController = TextEditingController();
  final TextEditingController _obsRefBancariaController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();

  final TextEditingController _1Controller = TextEditingController();
  final TextEditingController _2Controller = TextEditingController();
  final TextEditingController _3Controller = TextEditingController();
  final TextEditingController _4Controller = TextEditingController();
  final TextEditingController _5Controller = TextEditingController();
  final TextEditingController _enderecoCobrancaController = TextEditingController();
  final TextEditingController _numeroCobrancaController = TextEditingController();
  final TextEditingController _complementoCobrancaController = TextEditingController();
  final TextEditingController _bairroCobrancaController = TextEditingController();
  final TextEditingController _cidadeCobrancaController = TextEditingController();
  final TextEditingController _respCidadeCobrancaController = TextEditingController();
  final TextEditingController _cepCobrancaController = TextEditingController();
  final TextEditingController _attController = TextEditingController();

  final TextEditingController _enderecoCorrespondenciaController = TextEditingController();
  final TextEditingController _numeroCorrespondenciaController = TextEditingController();
  final TextEditingController _complementoCorrespondenciaController = TextEditingController();
  final TextEditingController _bairroCorrespondenciaController = TextEditingController();
  final TextEditingController _cidadeCorrespondenciaController = TextEditingController();
  final TextEditingController _respCidadeCorrespondenciaController = TextEditingController();
  final TextEditingController _cepCorrespondenciaController = TextEditingController();
  final TextEditingController _attCorrespondenciaController = TextEditingController();
  
  final TextEditingController _enderecoEntregaController = TextEditingController();
  final TextEditingController _numeroEntregaController = TextEditingController();
  final TextEditingController _complementoEntregaController = TextEditingController();
  final TextEditingController _bairroEntregaController = TextEditingController();
  final TextEditingController _cidadeEntregaController = TextEditingController();
  final TextEditingController _respCidadeEntregaController = TextEditingController();
  final TextEditingController _cepEntregaController = TextEditingController();
  final TextEditingController _attEntregaController = TextEditingController();

  final TextEditingController _sequenciaContatoController = TextEditingController();
  final TextEditingController _nomeContatoController = TextEditingController();
  final TextEditingController _dataNascimentoContatoController = TextEditingController();
  final TextEditingController _cargoContatoController = TextEditingController();
  final TextEditingController _resulCargoContatoController = TextEditingController();
  final TextEditingController _emailContatoController = TextEditingController();
  final TextEditingController _obsContatoController = TextEditingController();
  
  final TextEditingController _campoComum1Controller = TextEditingController();
  final TextEditingController _campoComum2Controller = TextEditingController();
  final TextEditingController _campoComum3Controller = TextEditingController();

  String? _selectedContribIcms;
  String? _selectedRevenda;
   bool _possuiEndCobran = false;
   bool _possuiEndCorrespondencia = false;
   bool _possuiEndEntrega = false;


  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllControlData();
    _fetchAllCidades();
    _fetchAllCargos();
   
    // Adiciona listeners para os campos de busca para lidar com a limpeza
    _campoComum1Controller.addListener(_handleClearCheck);
    _campoComum2Controller.addListener(_handleClearCheck);
    _campoComum3Controller.addListener(_handleClearCheck);

    _cepController.addListener(_updateEmpresaCounter);
    _enderecoController.addListener(_updateEmpresaCounter);
    _numeroController.addListener(_updateEmpresaCounter);
    _complementoController.addListener(_updateEmpresaCounter);
    _bairroController.addListener(_updateEmpresaCounter);
    _cidadeController.addListener(_updateEmpresaCounter);
    _ufController.addListener(_updateEmpresaCounter);
    _cxPostalController.addListener(_updateEmpresaCounter);
    _comoNosConheceuController.addListener(_updateEmpresaCounter);
    _portadorController.addListener(_updateEmpresaCounter);
    _tabDescontoController.addListener(_updateEmpresaCounter);
    _inscSuframaController.addListener(_updateEmpresaCounter);
    _inscProdutorController.addListener(_updateEmpresaCounter);
    _inscMunicipalController.addListener(_updateEmpresaCounter);
    _vendedorController.addListener(_updateEmpresaCounter);
    _atendenteController.addListener(_updateEmpresaCounter);
    _areaController.addListener(_updateEmpresaCounter);
    _situacaoController.addListener(_updateEmpresaCounter);
    _sqController.addListener(_updateEmpresaCounter);
    _paisController.addListener(_updateEmpresaCounter);
    _operadoraController.addListener(_updateEmpresaCounter);
    _dddController.addListener(_updateEmpresaCounter);
    _nroController.addListener(_updateEmpresaCounter);
    _ramalController.addListener(_updateEmpresaCounter);
    _tipoController.addListener(_updateEmpresaCounter);
    _contatoController.addListener(_updateEmpresaCounter);
    _cnpjController.addListener(_updateEmpresaCounter);
    _inscEstadualController.addListener(_updateEmpresaCounter);
    _contribIcmsController.addListener(_updateEmpresaCounter);
    _revendaController.addListener(_updateEmpresaCounter);
    _confidencialController.addListener(_updateEmpresaCounter);
    _observacaoController.addListener(_updateEmpresaCounter);
    _observacaoNfController.addListener(_updateEmpresaCounter);
    _eMailController.addListener(_updateEmpresaCounter);
    _eMailCobranController.addListener(_updateEmpresaCounter);
    _eMailNfController.addListener(_updateEmpresaCounter);
    _cnpjController.addListener(_updateEmpresaCounter);
    _socioController.addListener(_updateEmpresaCounter);
    _nomeController.addListener(_updateEmpresaCounter);
    _cpfController.addListener(_updateEmpresaCounter);
    _cargoController.addListener(_updateEmpresaCounter);
    _resulCargoController.addListener(_updateEmpresaCounter);
    _participacaoController.addListener(_updateEmpresaCounter);
    _confidencialController.addListener(_updateEmpresaCounter);
    _sqController.addListener(_updateEmpresaCounter);
    _siteController.addListener(_updateEmpresaCounter);
    _5Controller.addListener(_updateEmpresaCounter);
    _4Controller.addListener(_updateEmpresaCounter);
    _3Controller.addListener(_updateEmpresaCounter);
    _2Controller.addListener(_updateEmpresaCounter);
    _1Controller.addListener(_updateEmpresaCounter);

    _sequenciaController.addListener(_updateEmpresaCounter);
    _nomeRefBancariaController.addListener(_updateEmpresaCounter);
    _resulNomeController.addListener(_updateEmpresaCounter);
    _enderecoRefBancariaController.addListener(_updateEmpresaCounter);
    _resulEnderecoController.addListener(_updateEmpresaCounter);
    _cidadeRefBancariaController.addListener(_updateEmpresaCounter);
    _contatoRefBancariaController.addListener(_updateEmpresaCounter);
    _telefoneRefBancariaController.addListener(_updateEmpresaCounter);
    _emailRefBancariaController.addListener(_updateEmpresaCounter);
    _obsRefBancariaController.addListener(_updateEmpresaCounter);

    _enderecoCobrancaController.addListener(_updateEmpresaCounter);
    _numeroCobrancaController.addListener(_updateEmpresaCounter);
    _complementoCobrancaController.addListener(_updateEmpresaCounter);
    _bairroCobrancaController.addListener(_updateEmpresaCounter);
    _cidadeCobrancaController.addListener(_updateEmpresaCounter);
    _respCidadeCobrancaController.addListener(_updateEmpresaCounter);
    _cepCobrancaController.addListener(_updateEmpresaCounter);
    _attController.addListener(_updateEmpresaCounter);

    _enderecoCorrespondenciaController.addListener(_updateEmpresaCounter);
    _numeroCorrespondenciaController.addListener(_updateEmpresaCounter);
    _complementoCorrespondenciaController.addListener(_updateEmpresaCounter);
    _bairroCorrespondenciaController.addListener(_updateEmpresaCounter);
    _cidadeCorrespondenciaController.addListener(_updateEmpresaCounter);
    _respCidadeCorrespondenciaController.addListener(_updateEmpresaCounter);
    _cepCorrespondenciaController.addListener(_updateEmpresaCounter);
    _attCorrespondenciaController.addListener(_updateEmpresaCounter);
    
    _enderecoEntregaController.addListener(_updateEmpresaCounter);
    _numeroEntregaController.addListener(_updateEmpresaCounter);
    _complementoEntregaController.addListener(_updateEmpresaCounter);
    _bairroEntregaController.addListener(_updateEmpresaCounter);
    _cidadeEntregaController.addListener(_updateEmpresaCounter);
    _respCidadeEntregaController.addListener(_updateEmpresaCounter);
    _cepEntregaController.addListener(_updateEmpresaCounter);
    _attEntregaController.addListener(_updateEmpresaCounter);

    _sequenciaContatoController.addListener(_updateEmpresaCounter);
    _nomeContatoController.addListener(_updateEmpresaCounter);
    _dataNascimentoContatoController.addListener(_updateEmpresaCounter);
    _cargoContatoController.addListener(_updateEmpresaCounter);
    _resulCargoContatoController.addListener(_updateEmpresaCounter);
    _emailContatoController.addListener(_updateEmpresaCounter);
    _obsContatoController.addListener(_updateEmpresaCounter);
  
  }

  void _updateEmpresaCounter() {
    // Força a reconstrução do widget para que o suffixText seja atualizado
    setState(() {});
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
  
  CollectionReference get _cidadesCollectionRef => FirebaseFirestore.instance
      .collection('companies').doc(widget.mainCompanyId)
      .collection('secondaryCompanies').doc(widget.secondaryCompanyId)
      .collection('data').doc('cidades').collection('items');

  CollectionReference get _cargosCollectionRef => FirebaseFirestore.instance
      .collection('companies').doc(widget.mainCompanyId)
      .collection('secondaryCompanies').doc(widget.secondaryCompanyId)
      .collection('data').doc('cargos').collection('items');

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

  Future<void> _fetchAllCidades() async {
    try {
      final querySnapshot = await _cidadesCollectionRef.get();
      _allCidades = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'cidade': data['cidade'] ?? 'Cidade sem nome',
        };
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar cidades: $e')));
    }
  }

  Future<void> _fetchAllCargos() async {
    try {
      final querySnapshot = await _cargosCollectionRef.get();
      _allCargos = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'descricao': data['descricao'] ?? 'Cargo sem descrição'};
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar cargos: $e')));
    }
  }

  // Preenche todos os campos com base no item selecionado no dropdown
  void _populateAllFields(Map<String, dynamic> data) {
    setState(() {
      _campoComum1Controller.text = data['campoComum1'] ?? '';
      _campoComum2Controller.text = data['campoComum2'] ?? '';
      _campoComum3Controller.text = data['campoComum3'] ?? '';
        _cepController.text = data['cep'] ?? '';
    _enderecoController.text = data['endereco'] ?? '';
    _numeroController.text = data['numero'] ?? '';
    _complementoController.text = data['complemento'] ?? '';
    _bairroController.text = data['bairro'] ?? '';
    _cidadeController.text = data['cidade'] ?? '';
    _ufController.text = data['uf'] ?? '';
    _cxPostalController.text = data['cx. Postal'] ?? '';
    _comoNosConheceuController.text = data['como nos conheceu'] ?? '';
    _portadorController.text = data['portador'] ?? '';
    _tabDescontoController.text = data['tab desconto'] ?? '';
    _inscSuframaController.text = data['insc suframa'] ?? '';
    _inscProdutorController.text = data['insc produtor'] ?? '';
    _inscMunicipalController.text = data['insc municipal'] ?? '';
    _vendedorController.text = data['vendedor'] ?? '';
    _atendenteController.text = data['atendente'] ?? '';
    _areaController.text = data['area'] ?? '';
    _situacaoController.text = data['situacao'] ?? '';
    _sqController.text = data['sq'] ?? '';
    _paisController.text = data['pais'] ?? '';
    _operadoraController.text = data['operadora'] ?? '';
    _dddController.text = data['ddd'] ?? '';
    _nroController.text = data['nro'] ?? '';
    _ramalController.text = data['ramal'] ?? '';
    _tipoController.text = data['tipo'] ?? '';
    _contatoController.text = data['contato'] ?? '';
    _cnpjController.text = data['cnpj'] ?? '';
    _inscEstadualController.text = data['insc estadual'] ?? '';
    _siteController.text = data['site'] ?? '';

    _1Controller.text = data['1'] ?? '';
    _2Controller.text = data['2'] ?? '';
    _3Controller.text = data['3'] ?? '';
    _4Controller.text = data['4'] ?? '';
    _5Controller.text = data['5'] ?? '';

    _enderecoCobrancaController.text = data['endereco cobranca'] ?? '';
    _numeroCobrancaController.text = data['numero cobranca'] ?? '';
    _complementoCobrancaController.text = data['complemento cobranca'] ?? '';
    _bairroCobrancaController.text = data['bairro cobranca'] ?? '';
    _cidadeCobrancaController.text = data['cidade cobranca'] ?? '';
    _respCidadeCobrancaController.text = data['cidade cobranca'] ?? '';
    _cepCobrancaController.text = data['cep cobranca'] ?? '';
    _attController.text = data['att'] ?? '';

    _enderecoCorrespondenciaController.text = data['endereco correspondencia'] ?? '';
    _numeroCorrespondenciaController.text = data['numero correspondencia'] ?? '';
    _complementoCorrespondenciaController.text = data['complemento correspondencia'] ?? '';
    _bairroCorrespondenciaController.text = data['bairro correspondencia'] ?? '';
    _cidadeCorrespondenciaController.text = data['cidade correspondencia'] ?? '';
    _respCidadeCorrespondenciaController.text = data['cidade correspondencia'] ?? '';
    _cepCorrespondenciaController.text = data['cep correspondencia'] ?? '';
    _attCorrespondenciaController.text = data['att correspondencia'] ?? '';
    
    _enderecoEntregaController.text = data['endereco entrega'] ?? '';
    _numeroEntregaController.text = data['numero entrega'] ?? '';
    _complementoEntregaController.text = data['complemento entrega'] ?? '';
    _bairroEntregaController.text = data['bairro entrega'] ?? '';
    _cidadeEntregaController.text = data['cidade entrega'] ?? '';
    _respCidadeEntregaController.text = data['cidade entrega'] ?? '';
    _cepEntregaController.text = data['cep entrega'] ?? '';
    _attEntregaController.text = data['att entrega'] ?? '';

    //_selectedContribIcms = data['contrib ICMS'] ?? '';
    //_selectedRevenda = data['revenda'] ?? '';

    String? contribValue = data['contrib ICMS'];
      _selectedContribIcms = (contribValue == 'Sim' || contribValue == 'Não') ? contribValue : null;

      String? revendaValue = data['revenda'];
      _selectedRevenda = (revendaValue == 'Sim' || revendaValue == 'Não') ? revendaValue : null;
    _confidencialController.text = data['confidencial'] ?? '';
    _observacaoController.text = data['observacao'] ?? '';
    _observacaoNfController.text = data['observacao Nf'] ?? '';
    _eMailController.text = data['email'] ?? '';
    _eMailCobranController.text = data['email cobranca'] ?? '';
    _eMailNfController.text = data['email Nf'] ?? '';
    _socioController.text = data['socio'] ?? '';
    _nomeController.text = data['nome'] ?? '';
    _cpfController.text = data['cpf'] ?? '';
    _cargoController.text = data['cargo'] ?? '';
    _resulCargoController.text = data['cargo res'] ?? '';
    _participacaoController.text = data['participacao'] ?? '';

    _sequenciaController.text = data['sequencia ref banc'] ?? '';
    _nomeRefBancariaController.text = data['nome ref banc'] ?? '';
    //_resulNomeController.text = data['resul nome ref banc'] ?? '';
    _enderecoRefBancariaController.text = data['endereco ref banc'] ?? '';
    //_resulEnderecoController.text = data['resul endereco ref banc'] ?? '';
    _cidadeRefBancariaController.text = data['cidade ref banc'] ?? '';
    _contatoRefBancariaController.text = data['contato ref banc'] ?? '';
    _telefoneRefBancariaController.text = data['telefone ref banc'] ?? '';
    _emailRefBancariaController.text = data['email ref banc'] ?? '';
    _obsRefBancariaController.text = data['obs ref banc'] ?? '';

    _sequenciaContatoController.text = data['sequencia contato'] ?? '';
    _nomeContatoController.text = data['nome contato'] ?? '';
    _dataNascimentoContatoController.text = data['data nasc contato'] ?? '';
    _cargoContatoController.text = data['cargo contato'] ?? '';
    _resulCargoContatoController.text = data['cargo res contato'] ?? '';
    _emailContatoController.text = data['email contato'] ?? '';
    _obsContatoController.text = data['obs contato'] ?? '';
  
    });
  }

  void _populateCidadeFields(Map<String, dynamic> cidadeData) {
    setState(() {
      _cidadeController.text = cidadeData['id'] ?? '';
      _cidadeRefBancariaController.text = cidadeData['cidade'] ?? '';
    });
  }

  void _populateCidadeCobranFields(Map<String, dynamic> cidadeData) {
    setState(() {
      _cidadeCobrancaController.text = cidadeData['id'] ?? '';
      _respCidadeCobrancaController.text = cidadeData['cidade'] ?? '';
    });
  }
  void _populateCidadeCorrespondenciaFields(Map<String, dynamic> cidadeData) {
    setState(() {
      _cidadeCorrespondenciaController.text = cidadeData['id'] ?? '';
      _respCidadeCorrespondenciaController.text = cidadeData['cidade'] ?? '';
    });
  }

  void _populateCidadeEntregaFields(Map<String, dynamic> cidadeData) {
    setState(() {
      _cidadeEntregaController.text = cidadeData['id'] ?? '';
      _respCidadeEntregaController.text = cidadeData['cidade'] ?? '';
    });
  }

  void _populateCargoFields(Map<String, dynamic> cargoData) {
    setState(() {
      _cargoContatoController.text = cargoData['id'] ?? '';
      _resulCargoContatoController.text = cargoData['descricao'] ?? '';
    });
  }

  void _populateCargo2Fields(Map<String, dynamic> cargoData) {
    setState(() {
      _cargoController.text = cargoData['id'] ?? '';
      _resulCargoController.text = cargoData['descricao'] ?? '';
    });
  }
  // Limpa os campos dependentes quando a busca é limpa
  void _clearDependentFields() {
     _cepController.clear();
    _enderecoController.clear();
    _numeroController.clear();
    _complementoController.clear();
    _bairroController.clear();
    _cidadeController.clear();
    _ufController.clear();
    _cxPostalController.clear();
    _comoNosConheceuController.clear();
    _portadorController.clear();
    _tabDescontoController.clear();
    _inscSuframaController.clear();
    _inscProdutorController.clear();
    _inscMunicipalController.clear();
    _vendedorController.clear();
    _atendenteController.clear();
    _areaController.clear();
    _situacaoController.clear();
    _sqController.clear();
    _paisController.clear();
    _operadoraController.clear();
    _dddController.clear();
    _nroController.clear();
    _ramalController.clear();
    _tipoController.clear();
    _contatoController.clear();
    _cnpjController.clear();
    _inscEstadualController.clear();
    _contribIcmsController.clear();
    _revendaController.clear();
    _confidencialController.clear();
    _observacaoController.clear();
    _observacaoNfController.clear();
    _eMailController.clear();
    _eMailCobranController.clear();
    _eMailNfController.clear();
    _cnpjController.clear();
    _socioController.clear();
    _nomeController.clear();
    _cpfController.clear();
    _cargoController.clear();
    _resulCargoController.clear();
    _participacaoController.clear();
    _confidencialController.clear();
    _sqController.clear();
    _sequenciaController.clear();
    _nomeRefBancariaController.clear();
    _resulNomeController.clear();
    _enderecoRefBancariaController.clear();
    _resulEnderecoController.clear();
    _cidadeRefBancariaController.clear();
    _contatoRefBancariaController.clear();
    _telefoneRefBancariaController.clear();
    _emailRefBancariaController.clear();
    _obsRefBancariaController.clear();
    _siteController.clear();
    _5Controller.clear();
    _4Controller.clear();
    _3Controller.clear();
    _2Controller.clear();
    _1Controller.clear();
    _enderecoCobrancaController.clear();
    _numeroCobrancaController.clear();
    _complementoCobrancaController.clear();
    _bairroCobrancaController.clear();
    _cidadeCobrancaController.clear();
    _respCidadeCobrancaController.clear();
    _cepCobrancaController.clear();
    _attController.clear();
    
    _enderecoCorrespondenciaController.clear();
    _numeroCorrespondenciaController.clear();
    _complementoCorrespondenciaController.clear();
    _bairroCorrespondenciaController.clear();
    _cidadeCorrespondenciaController.clear();
    _respCidadeCorrespondenciaController.clear();
    _cepCorrespondenciaController.clear();
    _attCorrespondenciaController.clear();
    
    _enderecoEntregaController.clear();
    _numeroEntregaController.clear();
    _complementoEntregaController.clear();
    _bairroEntregaController.clear();
    _cidadeEntregaController.clear();
    _respCidadeEntregaController.clear();
    _cepEntregaController.clear();
    _attEntregaController.clear();

    _sequenciaContatoController.clear();
    _nomeContatoController.clear();
    _dataNascimentoContatoController.clear();
    _cargoContatoController.clear();
    _resulCargoContatoController.clear();
    _emailContatoController.clear();
    _obsContatoController.clear();

    setState(() {
      _selectedContribIcms = null;
      _selectedRevenda = null;
    });
    
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
      'cep' : _cepController.text,
      'endereco' : _enderecoController.text,
      'numero' : _numeroController.text,
      'complemento' : _complementoController.text,
      'bairro' : _bairroController.text,
      'cidade' : _cidadeController.text,
      'uf' : _ufController.text,
      'cx postal' : _cxPostalController.text,
      'como nos conheceu' : _comoNosConheceuController.text,
      'portador' : _portadorController.text,
      'tab desconto' : _tabDescontoController.text,
      'isnc suframa' : _inscSuframaController.text,
      'insc produtor' : _inscProdutorController.text,
      'insc municipal' : _inscMunicipalController.text,
      'vendedor' : _vendedorController.text,
      'atendente' : _atendenteController.text,
      'area' : _areaController.text,
      'situacao' : _situacaoController.text,
      'sq' : _sqController.text,
      'pais' : _paisController.text,
      'operadora' : _operadoraController.text,
      'ddd' : _dddController.text,
      'nro' : _nroController.text,
      'ramal' : _ramalController.text,
      'tipo' : _tipoController.text,
      'contato' : _contatoController.text,
      'cnpj' : _cnpjController.text,
      'insc estadual' : _inscEstadualController.text,
      'contrib ICMS' : _selectedContribIcms,
      'revenda' : _selectedRevenda,
      'confidencial' : _confidencialController.text,
      'observacao' : _observacaoController.text,
      'observacao Nf' : _observacaoNfController.text,
      'email' : _eMailController.text,
      'email cobranca' : _eMailCobranController.text,
      'email Nf' : _eMailNfController.text,
      'socio' : _socioController.text,
      'nome' :_nomeController.text,
      'cpf' :_cpfController.text,
      'cargo' : _cargoController.text,
      'cargo res' : _resulCargoController.text,
      'participacao' :_participacaoController.text ,

      'sequencia ref banc' :_sequenciaController.text,
      'nome ref banc' :_nomeRefBancariaController.text,
      //'resul nome ref banc' :_resulNomeController.text,
      'endereco ref banc' :_enderecoRefBancariaController,
      //'resul endereco ref banc' :_resulEnderecoController.text,
      'cidade ref banc' :_cidadeRefBancariaController.text,
      'contato ref banc' :_contatoRefBancariaController.text,
      'telefone ref banc' :_telefoneRefBancariaController.text,
      'email ref banc' :_emailRefBancariaController.text,
      'obs ref banc' :_obsRefBancariaController.text,
      'site' :_siteController.text,

      '1' :_1Controller.text,
      '2c' :_2Controller.text,
      '3' :_3Controller.text,
      '4' :_4Controller.text,
      '5' :_5Controller.text,

      'endereco cobranca':_enderecoCobrancaController,
      'numero cobranca' :_numeroCobrancaController,
      'complemento cobranca' :_complementoCobrancaController,
      'bairro cobranca' :_bairroCobrancaController,
      'cidade cobranca' :_cidadeCobrancaController,
      'resp cidade cobranca' :_respCidadeCobrancaController,
      'cep cobranca' :_cepCobrancaController,
      'att':_attController,

      'endereco correspondencia':_enderecoCorrespondenciaController,
      'numero correspondencia' :_numeroCorrespondenciaController,
      'complemento correspondencia' :_complementoCorrespondenciaController,
      'bairro correspondencia' :_bairroCorrespondenciaController,
      'cidade correspondencia' :_cidadeCorrespondenciaController,
      'resp cidade correspondencia' :_respCidadeCorrespondenciaController,
      'cep correspondencia' :_cepCorrespondenciaController,
      'att correspondencia':_attCorrespondenciaController,
      
      'endereco entrega':_enderecoEntregaController,
      'numero entrega' :_numeroEntregaController,
      'complemento entrega' :_complementoEntregaController,
      'bairro entrega' :_bairroEntregaController,
      'cidade entrega' :_cidadeEntregaController,
      'resp cidade entrega' :_respCidadeEntregaController,
      'cep entrega' :_cepEntregaController,
      'att entrega':_attEntregaController,

      'sequencia contato' :_sequenciaContatoController,
      'nome contato' :_nomeContatoController,
      'data nasc contato' :_dataNascimentoContatoController,
      'cargo contato' :_cargoContatoController,
      'cargo res contato' :_resulCargoContatoController,
      'email contato' :_emailContatoController,
      'obs contato' :_obsContatoController,

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

  Future<void> _addSocio() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final socioData = {
      'sq': _sqController.text,
      'socio': _socioController.text,
      'nome': _nomeController.text,
      'cpf': _cpfController.text,
      'cargo': _cargoController.text,
      'participacao': _participacaoController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('composicao_acionaria').add(socioData);
      _socioController.clear();
      _nomeController.clear();
      _sqController.clear();
      _cargoController.clear();
      _participacaoController.clear();
      _cpfController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar sócio: $e')));
    }
  }

  Future<void> _deleteSocio(String itemId, String socioId) async {
    try {
      await _collectionRef.doc(itemId).collection('composicao_acionaria').doc(socioId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar sócio: $e')));
    }
  }

  Future<void> _addTelefone() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final telefoneData = {
      'sq': _sqController.text, 'pais': _paisController.text, 'operadora': _operadoraController.text,
      'ddd': _dddController.text, 'nro': _nroController.text, 'ramal': _ramalController.text,
      'tipo': _tipoController.text, 'contato': _contatoController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('telefones').add(telefoneData);
      _sqController.clear();_paisController.clear();_operadoraController.clear();_dddController.clear();
      _nroController.clear();_ramalController.clear();_tipoController.clear();_contatoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar telefone: $e')));
    }
  }

  Future<void> _deleteTelefone(String itemId, String telefoneId) async {
    try {
      await _collectionRef.doc(itemId).collection('telefones').doc(telefoneId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar telefone: $e')));
    }
  }

  Future<void> _addReferenciaBancaria() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final refData = {
      'sequencia ref banc': _sequenciaController.text, 'nome ref banc': _nomeRefBancariaController.text,
      'endereco ref banc': _enderecoRefBancariaController.text, 'cidade ref banc': _cidadeRefBancariaController.text,
      'contato ref banc': _contatoRefBancariaController.text, 'telefone ref banc': _telefoneRefBancariaController.text,
      'email ref banc': _emailRefBancariaController.text, 'obs ref banc': _obsRefBancariaController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('referencias_bancarias').add(refData);
      _sequenciaController.clear();_nomeRefBancariaController.clear();_enderecoRefBancariaController.clear();
      _cidadeRefBancariaController.clear();_contatoRefBancariaController.clear();_telefoneRefBancariaController.clear();
      _emailRefBancariaController.clear();_obsRefBancariaController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar referência: $e')));
    }
  }

  Future<void> _deleteReferenciaBancaria(String itemId, String refId) async {
    try {
      await _collectionRef.doc(itemId).collection('referencias_bancarias').doc(refId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar referência: $e')));
    }
  }

  Future<void> _addContato() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final refData = {
      'sequencia contato': _sequenciaContatoController.text, 'nome contato': _nomeContatoController.text,
      'data nasc contato': _dataNascimentoContatoController.text, 'cargo contato': _cargoContatoController.text,
      'cargo res contato': _resulCargoContatoController.text, 
      'email contato': _emailContatoController.text, 'obs contato': _obsContatoController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('contatos').add(refData);
      _sequenciaContatoController.clear();_nomeContatoController.clear();_dataNascimentoContatoController.clear();
      _cargoContatoController.clear();_resulCargoContatoController.clear();_emailContatoController.clear();
      _obsContatoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar referência: $e')));
    }
  }

  Future<void> _deleteContato(String itemId, String refId) async {
    try {
      await _collectionRef.doc(itemId).collection('contatos').doc(refId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar referência: $e')));
    }
  }

  String? _cpfValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo CPF é obrigatório.';
  }
  // Remove formatação para validação
  String cpf = value.replaceAll(RegExp(r'\D'), '');

  if (cpf.length != 11) {
    return 'CPF deve ter 11 dígitos.';
  }

  // Verifica se todos os dígitos são iguais (CPFs inválidos comuns)
  if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
    return 'CPF inválido.';
  }

  List<int> numbers = cpf.split('').map(int.parse).toList();

  // Validação do primeiro dígito verificador
  int sum = 0;
  for (int i = 0; i < 9; i++) {
    sum += numbers[i] * (10 - i);
  }
  int remainder = sum % 11;
  int dv1 = remainder < 2 ? 0 : 11 - remainder;

  if (dv1 != numbers[9]) {
    return 'CPF inválido.';
  }

  // Validação do segundo dígito verificador
  sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += numbers[i] * (11 - i);
  }
  remainder = sum % 11;
  int dv2 = remainder < 2 ? 0 : 11 - remainder;

  if (dv2 != numbers[10]) {
    return 'CPF inválido.';
  }

  return null; // CPF válido
}


  @override
  void dispose() {
    //_empresaController.dispose();
    _cnpjController.dispose();
    
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
                        Tab(text: 'Complemento'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildAbaDadosGerais(),
                          _buildAbaTelefone(),
                          _buildAbaJuridica(),
                          _buildAbaComplemento(),
                          _buildAbaComposicaoAcionaria(),
                          _buildAbaReferenciaBancaria(),
                          _buildAbaNomeFantasia(),
                          _buildAbaEnderecoCobranca(),
                          _buildAbaCorrespondencia(),
                          _buildAbaEntrega(),
                          _buildAbaContatos(),
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
            _buildTabButton(title: 'Jurídica', index: 2),
            _buildTabButton(title: 'Complemento', index: 3),
            _buildTabButton(title: 'Adicional', index: 4),
            _buildTabButton(title: 'Bancária', index: 5),
            //_buildTabButton(title: 'Comercial', index: 6),
            _buildTabButton(title: 'Apelido/fantasia', index: 6),
            _buildTabButton(title: 'Cobrança', index: 7),
            _buildTabButton(title: 'Correspondência', index: 8),
            _buildTabButton(title: 'Endereço entrega', index: 9),
            _buildTabButton(title: 'Contatos', index: 10),
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
        2 => _buildAbaJuridica(key: const ValueKey('aba2')),
        3 => _buildAbaComplemento(key: const ValueKey('aba3')),
        4 => _buildAbaComposicaoAcionaria(key: const ValueKey('aba4')),
        5 => _buildAbaReferenciaBancaria(key: const ValueKey('aba5')),
        6 => _buildAbaNomeFantasia(key: const ValueKey('aba6')),
        7 => _buildAbaEnderecoCobranca(key: const ValueKey('aba7')),
        8 => _buildAbaCorrespondencia(key: const ValueKey('aba8')),
        9 => _buildAbaEntrega(key: const ValueKey('aba9')),
        10 => _buildAbaContatos(key: const ValueKey('aba10')),
        /*11 => _buildAbaContatos(key: const ValueKey('aba11')),*/
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
                      controller: _cepController, 
                      label: "CEP", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _enderecoController, 
                      label: "Endereço", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _numeroController, 
                      label: "Número", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _complementoController, 
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
                      controller: _bairroController, 
                      label: "Bairro", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _cidadeController, 
                      label: "Cidade", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _ufController, 
                      label: "UF", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _cxPostalController, 
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
                      controller: _comoNosConheceuController, 
                      label: "Como nos conheceu", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 1,
                    child: CustomInputField(
                      controller: _portadorController, 
                      label: "Portador", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 2,
                    child: CustomInputField(
                      controller: _tabDescontoController, 
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
                      controller: _inscSuframaController, 
                      label: "Inscr. Suframa", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _inscProdutorController, 
                      label: "Inscr. Produtor.", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _inscMunicipalController, 
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
                      controller: _vendedorController, 
                      label: "Vendedor", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _atendenteController, 
                      label: "Atendente", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _areaController, 
                      label: "Área", 
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  Expanded(flex: 1,child: SizedBox()) ,
                  Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _situacaoController, 
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
     return Form(
       child: Padding(
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
                        controller: _sqController, 
                        label: "SQ", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _paisController, 
                        label: "País", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _operadoraController, 
                        label: "Operadora", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _dddController, 
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
                        controller: _nroController, 
                        label: "Nro", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _ramalController, 
                        label: "Ramal", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _tipoController, 
                        label: "Tipo", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _contatoController, 
                        label: "Contato", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  ],
                ),
                const SizedBox(height: 10),
        ElevatedButton(onPressed: _addTelefone, child: const Text("Adicionar Telefone")),
        const Divider(thickness: 2, height: 40),

                StreamBuilder<QuerySnapshot>(
          stream: _campoComum1Controller.text.trim().isNotEmpty
              ? _collectionRef.doc(_campoComum1Controller.text.trim()).collection('telefones').snapshots()
              : null,
          builder: (context, snapshot) {
            if (_campoComum1Controller.text.trim().isEmpty) {
              return const Center(child: Text("Busque por um CPF/CNPJ para ver os telefones."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Nenhum telefone cadastrado para esta empresa."));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erro: ${snapshot.error}"));
            }
            
            final telefones = snapshot.data!.docs;

            return DataTable(
              columns: const [
                DataColumn(label: Text('SQ')),
                DataColumn(label: Text('País')),
                DataColumn(label: Text('DDD')),
                DataColumn(label: Text('Número')),
                DataColumn(label: Text('Contato')),
                DataColumn(label: Text('Ação')),
              ],
              rows: telefones.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(data['sq'] ?? '')),
                  DataCell(Text(data['pais'] ?? '')),
                  DataCell(Text(data['ddd'] ?? '')),
                  DataCell(Text(data['nro'] ?? '')),
                  DataCell(Text(data['contato'] ?? '')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTelefone(_campoComum1Controller.text.trim(), doc.id),
                  )),
                ]);
              }).toList(),
            );
          },
        )
                
              ],
            ),
          ),
        ),
           ),
     );
  }

  Widget _buildAbaJuridica({Key? key}) {
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
              const Text("Aba: Física/ Jurídica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _cnpjController, 
                      inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            CnpjInputFormatter(), // Adiciona pontos, barra e hífen automaticamente
                          ],
                      label: "CNPJ", 
                      validator: _cnpjValidator)),],
                      
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _inscEstadualController, 
                      label: "Insc. Estadual", 
                      maxLength: 16,
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              SizedBox(height: 10,),
              Row(
                children: [Expanded(
              flex: 3,
              child: _buildSimNaoDropdown(
                label: "Contrib. ICMS",
                value: _selectedContribIcms,
                onChanged: (newValue) {
                  setState(() {
                    _selectedContribIcms = newValue;
                  });
                },
              ),
            ),
                      ],
              ),
              SizedBox(height: 15,),
              Row(
                children: [Expanded(
              flex: 3,
              child: _buildSimNaoDropdown(
                label: "Revenda",
                value: _selectedRevenda,
                onChanged: (newValue) {
                  setState(() {
                    _selectedRevenda = newValue;
                  });
                },
              ),
            ),],
              ),
              
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbaComplemento({Key? key}) {
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
              const Text("Aba: Física/ Jurídica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _confidencialController, 
                      label: "Confidencial", 
                      maxLength: 60,
                      suffixText: '${_confidencialController.text.length}/60',
                      
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _observacaoController, 
                      label: "Observação", 
                      maxLength: 60,
                      suffixText: '${_observacaoController.text.length}/60',
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _observacaoNfController, 
                      label: "ObservacaoNf", 
                      maxLength: 60,
                      suffixText: '${_observacaoNfController.text.length}/60',
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _eMailController, 
                      label: "E-mail", 
                      maxLength: 60,
                      suffixText: '${_eMailController.text.length}/60',
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _eMailCobranController, 
                      label: "E-mail Cobran", 
                      maxLength: 60,
                      suffixText: '${_eMailCobranController.text.length}/60',
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _eMailNfController, 
                      label: "E-mail Nf-e", 
                      maxLength: 60,
                      suffixText: '${_eMailNfController.text.length}/60',
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _siteController, 
                      label: "Site", 
                      maxLength: 60,
                      suffixText: '${_eMailNfController.text.length}/60',
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbaComposicaoAcionaria({Key? key}) {
    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Composição Acionária",
      children: [
        Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _sqController, 
                        label: "SQ", 
                        maxLength: 1,
                        
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        suffixText: '${_sqController.text.length}/1',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _socioController, 
                        maxLength: 5,
                        label: "Sócio", 
                        suffixText: '${_socioController.text.length}/5',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _nomeController, 
                        label: "Nome", 
                        maxLength: 60,
                        suffixText: '${_nomeController.text.length}/60',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                  ],
                ),
        Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomInputField(
                        controller: _cpfController, 
                        label: "CPF", 
                        
                        suffixText: '${_cpfController.text.length}/14',
                        validator: _cpfValidator)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _buildCargoAutocomplete2()),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _resulCargoController, 
                        //suffixText: '${_participacaoController.text.length}/60',
                        label: "...", 
                        readOnly: true,
                        //inputFormatters: [ PercentageInputFormatter()],
                        //maxLength: 35,
                        //suffixText: '${_participacaoController.text.length}/35',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _participacaoController, 
                        suffixText: '${_participacaoController.text.length}/5',
                        label: "Particpação", 
                        inputFormatters: [ PercentageInputFormatter()],
                        maxLength: 5,
                        //suffixText: '${_participacaoController.text.length}/35',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                        
                    const SizedBox(width: 10),
                    
                  ],
                ),
        
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _addSocio, child: const Text("Adicionar Sócio")),
        const Divider(thickness: 2, height: 40),
        
        // Tabela de dados
        StreamBuilder<QuerySnapshot>(
          stream: _campoComum1Controller.text.trim().isNotEmpty
              ? _collectionRef.doc(_campoComum1Controller.text.trim()).collection('composicao_acionaria').snapshots()
              : null,
          builder: (context, snapshot) {
            if (_campoComum1Controller.text.trim().isEmpty) {
              return const Center(child: Text("Busque por um CPF/CNPJ para ver os sócios."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Nenhum sócio cadastrado para esta empresa."));
            }
            
            final socios = snapshot.data!.docs;

            return DataTable(
              border: TableBorder(top: BorderSide(color: Colors.black), bottom: BorderSide(color: Colors.black), horizontalInside: BorderSide(color: Colors.blue)),
              columns: const [
                DataColumn(label: Text('Sq')),
                DataColumn(label: Text('Sócio')),
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('CPF')),
                DataColumn(label: Text('Cargo')),
                DataColumn(label: Text('Cargo res')),
                DataColumn(label: Text('participacao')),
                DataColumn(label: Text('Ação')),
              ],
              rows: socios.map((socioDoc) {
                final socioData = socioDoc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(socioData['sq'] ?? '')),
                  DataCell(Text(socioData['socio'] ?? '')),
                  DataCell(Text(socioData['nome'] ?? '')),
                  DataCell(Text(socioData['cpf'] ?? '')),
                  DataCell(Text(socioData['cargo'] ?? '')),
                  DataCell(Text(socioData['cargo res'] ?? '')),
                  DataCell(Text(socioData['participacao'] ?? '')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSocio(_campoComum1Controller.text.trim(), socioDoc.id),
                  )),
                ]);
              }).toList(),
            );
          },
        )
      ],
    );
  }
  
  Widget _buildAbaContainer({Key? key, required Color color, required String title, required List<Widget> children}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25,0,25,25),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
  


  Widget _buildInputField(TextEditingController controller, String label, int maxLength, {String? Function(String?)? validator, bool isNumeric = false, bool isRequired = false, bool readOnly = false, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return CustomInputField(
      controller: controller,
      label: label,
      maxLength: maxLength,
      validator: validator ?? (isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null),
      
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            suffixText: '${controller.text.length}/$maxLength',
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
      readOnly: readOnly,
      fillColor: readOnly ? Colors.grey[300] : Colors.white,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildSimNaoDropdown({
    required String label,
    required String? value,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Sim', 'Não'].map<DropdownMenuItem<String>>((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildAbaReferenciaBancaria({Key? key}) {
    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Referencia Bancária",
      children: [
        
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _sequenciaController, 
                        label: "Sequencia", 
                        maxLength: 1,
                        suffixText: '${_sequenciaController.text.length}/1',
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _nomeRefBancariaController, 
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        maxLength: 5,
                        suffixText: '${_nomeRefBancariaController.text.length}/5',
                        label: "nome", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: CustomInputField(
                        controller: _resulNomeController, 
                        readOnly: true,
                        label: "...", 
                        //maxLength: 35,
                        //suffixText: '${_participacaoController.text.length}/35',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                        
                    const SizedBox(width: 10),
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _enderecoRefBancariaController, 
                        label: "Endereço", 
                        suffixText: '${_enderecoRefBancariaController.text.length}/45',
                        maxLength: 45,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),  
                        const SizedBox(width: 10),                                                           
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildCidadeAutocomplete()),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: CustomInputField(
                        controller: _cidadeRefBancariaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        //maxLength: 5,
                        readOnly: true,
                        label: "...", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _contatoRefBancariaController, 
                        label: "Contato", 
                        suffixText: '${_contatoRefBancariaController.text.length}/20',
                        maxLength: 20,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _telefoneRefBancariaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        maxLength: 20,
                        suffixText: '${_telefoneRefBancariaController.text.length}/20',
                        label: 'Telefone' ,
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                        
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _emailRefBancariaController, 
                        label: "e-mail", 
                        suffixText: '${_emailRefBancariaController.text.length}/40',
                        maxLength: 40,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _obsRefBancariaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        maxLength: 40,
                        label: 'Obs' ,
                        suffixText: '${_obsRefBancariaController.text.length}/40',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                        
                    
                    
                  ],
                ),
        
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _addReferenciaBancaria, child: const Text("Adicionar Sócio")),
        const Divider(thickness: 2, height: 40),
        
        // Tabela de dados
        StreamBuilder<QuerySnapshot>(
          stream: _campoComum1Controller.text.trim().isNotEmpty
              ? _collectionRef.doc(_campoComum1Controller.text.trim()).collection('referencias_bancarias').snapshots()
              : null,
          builder: (context, snapshot) {
            if (_campoComum1Controller.text.trim().isEmpty) {
              return const Center(child: Text("Busque por um CPF/CNPJ para ver as referências."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Nenhuma referência bancária cadastrada."));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erro: ${snapshot.error}"));
            }
            
            final referencias = snapshot.data!.docs;

            return DataTable(
              columns: const [
                DataColumn(label: Text('Seq.')), DataColumn(label: Text('Nome')),
                DataColumn(label: Text('Endereço.')), DataColumn(label: Text('Cidade')),
                DataColumn(label: Text('Contato')), DataColumn(label: Text('Telefone')),
                DataColumn(label: Text('E-mail')), DataColumn(label: Text('Obs.')),
                DataColumn(label: Text('Ação')),
              ],
              rows: referencias.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(data['sequencia ref banc'] ?? '')), DataCell(Text(data['nome ref banc'] ?? '')),
                  DataCell(Text(data['endereco ref banc'] ?? '')), DataCell(Text(data['cidade ref banc'] ?? '')),
                  DataCell(Text(data['contato ref banc'] ?? '')), DataCell(Text(data['telefone ref banc'] ?? '')),
                  DataCell(Text(data['email ref banc'] ?? '')), DataCell(Text(data['obs ref banc'] ?? '')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteReferenciaBancaria(_campoComum1Controller.text.trim(), doc.id),
                  )),
                ]);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCidadeAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeFields(selection);
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeController.text != fieldController.text) {
            fieldController.text = _cidadeController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Cidade",
          onChanged: (value) {
            _cidadeController.text = value;
            final exactMatches = _allCidades.where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase()).toList();
            if (exactMatches.length == 1) {
              _populateCidadeFields(exactMatches.first);
            }
          },
        );
      },
    );
  }

  Widget _buildCidadeAutocompleteEnderecoCobranca() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeCobranFields(selection);
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeCobrancaController.text != fieldController.text) {
            fieldController.text = _cidadeCobrancaController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Cidade",
          onChanged: (value) {
            _cidadeCobrancaController.text = value;
            final exactMatches = _allCidades.where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase()).toList();
            if (exactMatches.length == 1) {
              _populateCidadeCobranFields(exactMatches.first);
            }
          },
        );
      },
    );
  }

  Widget _buildCidadeAutocompleteCorrespondencia() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeCorrespondenciaFields(selection);
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeCorrespondenciaController.text != fieldController.text) {
            fieldController.text = _cidadeCorrespondenciaController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Cidade",
          onChanged: (value) {
            _cidadeCorrespondenciaController.text = value;
            final exactMatches = _allCidades.where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase()).toList();
            if (exactMatches.length == 1) {
              _populateCidadeCorrespondenciaFields(exactMatches.first);
            }
          },
        );
      },
    );
  }

  Widget _buildCidadeAutocompleteEntrega() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeEntregaFields(selection);
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeEntregaController.text != fieldController.text) {
            fieldController.text = _cidadeEntregaController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Cidade",
          onChanged: (value) {
            _cidadeEntregaController.text = value;
            final exactMatches = _allCidades.where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase()).toList();
            if (exactMatches.length == 1) {
              _populateCidadeEntregaFields(exactMatches.first);
            }
          },
        );
      },
    );
  }
  
  Widget _buildCargoAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String, // Mostra o código no campo
      //displayStringForOption: (option) => option['descricao'] as String, // Mostra a descrição
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCargos.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final descricao = option['descricao']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || descricao.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCargoFields(selection);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cargoContatoController.text != fieldController.text) {
            fieldController.text = _cargoContatoController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Cargo",
          onChanged: (value) {
            _cargoContatoController.text = value;
            final exactMatches = _allCargos.where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase()).toList();
            if (exactMatches.length == 1) {
              _populateCargoFields(exactMatches.first);
            }else {
              setState(() {
                _resulCargoContatoController.clear();
              });
            }
          },
        );
      },
    );
  }

  Widget _buildCargoAutocomplete2() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCargos.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final descricao = option['descricao']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || descricao.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCargo2Fields(selection);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cargoController.text != fieldController.text) {
            fieldController.text = _cargoController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Cargo",
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            _cargoController.text = value;
            final exactMatches = _allCargos.where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase()).toList();
            if (exactMatches.length == 1) {
              _populateCargo2Fields(exactMatches.first);
            } else {
              setState(() {
                _resulCargoController.clear();
              });
            }
          },
        );
      },
    );
  }

  Widget _buildAbaNomeFantasia({Key? key}) {
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
              const Text("Aba: Nome Fantasia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _1Controller, 
                      label: "1", 
                      maxLength: 35,
                      suffixText: '${_1Controller.text.length}/60',
                      
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _2Controller, 
                      label: "2", 
                      maxLength: 35,
                      suffixText: '${_2Controller.text.length}/60',
                      
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _3Controller, 
                      label: "3", 
                      maxLength: 35,
                      suffixText: '${_3Controller.text.length}/60',
                      
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _4Controller, 
                      label: "4", 
                      maxLength: 35,
                      suffixText: '${_4Controller.text.length}/60',
                      
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              Row(
                children: [Expanded(
                    flex: 3,
                    child: CustomInputField(
                      controller: _5Controller, 
                      label: "5", 
                      maxLength: 35,
                      suffixText: '${_5Controller.text.length}/60',
                      
                      //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),],
              ),
              
              
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbaEnderecoCobranca({Key? key}) {
    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Endereço cobrança",
      children: [
        Row(
                                      children: [
                                        Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 250, right: 250),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(255, 153, 205, 248), // Cor de fundo do container de integração
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(color: Colors.blue, width: 2.0),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(6.0), // Padding interno para o conteúdo
                                                    child: Row( // <-- Voltando para Row para manter o texto 'Integração' ao lado
                                                      crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente o conteúdo da Row
                                                      children: [
                                                        Column(
                                                          children: [
                                                            const Text('Possui Endereço? :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                            //const Text('IPI :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                          ],
                                                        ),
                                                        // Removido SizedBox(width: 16) para compactar mais, você pode ajustar
                                                        Expanded( // <-- O Expanded é importante para dar espaço aos CheckboxListTile
                                                          child: Column( // Column para empilhar os CheckboxListTile
                                                            crossAxisAlignment: CrossAxisAlignment.start, // Alinha os CheckboxListTile à esquerda
                                                            mainAxisAlignment: MainAxisAlignment.center, // Centraliza os checkboxes na coluna
                                                            children: [
                                                              Row(
                                                      children: [
                                                        Checkbox(
                                                          value: _possuiEndCobran == true,
                                                          onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _possuiEndCobran = true;
                                                              });
                                                            }
                                                            
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                        const Text('Sim', style: TextStyle(color: Colors.black)),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Checkbox(
                                                          value: _possuiEndCobran == false,
                                                          onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para false se o usuário CLICAR no "Não" (e o checkbox de "Não" for marcado)
                                                              setState(() {
                                                                _possuiEndCobran = false;
                                                              });
                                                            }
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                        const Text('Não', style: TextStyle(color: Colors.black)),
                                                      ],
                                                    ),]
                                                          ),
                                                        ),
                                                        // Texto de integrações selecionadas movido para a direita, ou pode ser removido se não for essencial aqui
                                                        // Padding(
                                                        //   padding: const EdgeInsets.only(left: 8.0),
                                                        //   child: Text(
                                                        //     'Sel: ${_integracaoSelections.join(', ')}',
                                                        //     style: const TextStyle(color: Colors.white, fontSize: 12),
                                                        //   ),
                                                        // ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                    SizedBox(height: 10,),
        
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _enderecoCobrancaController, 
                        label: "Endereço", 
                        suffixText: '${_enderecoCobrancaController.text.length}/45',
                        maxLength: 45,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _numeroCobrancaController, 
                        label: "Numero", 
                        suffixText: '${_numeroCobrancaController.text.length}/10',
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),  
                        const SizedBox(width: 10),  
                        Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _complementoCobrancaController, 
                        label: "Complemento", 
                        suffixText: '${_complementoCobrancaController.text.length}/20',
                        maxLength: 20,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),                                                          
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _bairroCobrancaController, 
                        label: "Bairro", 
                        suffixText: '${_bairroCobrancaController.text.length}/25',
                        maxLength: 25,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildCidadeAutocompleteEnderecoCobranca()),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: CustomInputField(
                        controller: _respCidadeCobrancaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        //maxLength: 5,
                        readOnly: true,
                        label: "...", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _cepCobrancaController, 
                        label: "CEP", 
                        suffixText: '${_cepCobrancaController.text.length}/9',
                        maxLength: 9,
                        inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            CepInputFormatter(), // Adiciona o hífen automaticamente
                          ],
                        validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            // Validação do formato CEP #####-### e comprimento
                            if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value) || value.length != 9) {
                              return 'Formato de CEP inválido (#####-###)';
                            }
                            return null;
                          },
                          hintText: '#####-###',)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _attController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        suffixText: '${_attController.text.length}/30',
                        maxLength: 30,
                        label: 'Att' ,
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                        
                    
                    
                  ],
                ),

                
        
        
        
        // Tabela de dados
        
      ],
    );
  }


  Widget _buildAbaCorrespondencia({Key? key}) {
    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Correspondência",
      children: [
        Row(
                    children: [
                      Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 250, right: 250),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 153, 205, 248), // Cor de fundo do container de integração
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.blue, width: 2.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0), // Padding interno para o conteúdo
                                  child: Row( // <-- Voltando para Row para manter o texto 'Integração' ao lado
                                    crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente o conteúdo da Row
                                    children: [
                                      Column(
                                        children: [
                                          const Text('Possui Endereço? :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                          //const Text('IPI :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                        ],
                                      ),
                                      // Removido SizedBox(width: 16) para compactar mais, você pode ajustar
                                      Expanded( // <-- O Expanded é importante para dar espaço aos CheckboxListTile
                                        child: Column( // Column para empilhar os CheckboxListTile
                                          crossAxisAlignment: CrossAxisAlignment.start, // Alinha os CheckboxListTile à esquerda
                                          mainAxisAlignment: MainAxisAlignment.center, // Centraliza os checkboxes na coluna
                                          children: [
                                            Row(
                                    children: [
                                      Checkbox(
                                        value: _possuiEndCorrespondencia == true,
                                        onChanged: (bool? newValue) {
                                          if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                            setState(() {
                                              _possuiEndCorrespondencia = true;
                                            });
                                          }
                                          
                                        },
                                        activeColor: Colors.blue,
                                      ),
                                      const Text('Sim', style: TextStyle(color: Colors.black)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _possuiEndCorrespondencia == false,
                                        onChanged: (bool? newValue) {
                                          if (newValue == true) { // Só muda para false se o usuário CLICAR no "Não" (e o checkbox de "Não" for marcado)
                                            setState(() {
                                              _possuiEndCorrespondencia = false;
                                            });
                                          }
                                        },
                                        activeColor: Colors.blue,
                                      ),
                                      const Text('Não', style: TextStyle(color: Colors.black)),
                                    ],
                                  ),]
                                        ),
                                      ),
                                      // Texto de integrações selecionadas movido para a direita, ou pode ser removido se não for essencial aqui
                                      // Padding(
                                      //   padding: const EdgeInsets.only(left: 8.0),
                                      //   child: Text(
                                      //     'Sel: ${_integracaoSelections.join(', ')}',
                                      //     style: const TextStyle(color: Colors.white, fontSize: 12),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                  SizedBox(height: 10,),

                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _enderecoCorrespondenciaController, 
                        label: "Endereço", 
                        maxLength: 45,
                        suffixText: '${_enderecoCorrespondenciaController.text.length}/45',
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _numeroCorrespondenciaController, 
                        label: "Numero", 
                        maxLength: 10,
                        suffixText: '${_numeroCorrespondenciaController.text.length}/10',
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),  
                        const SizedBox(width: 10),  
                        Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _complementoCorrespondenciaController, 
                        label: "Complemento", 
                        suffixText: '${_complementoCorrespondenciaController.text.length}/20',
                        maxLength: 20,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),                                                          
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _bairroCorrespondenciaController, 
                        label: "Bairro", 
                        suffixText: '${_bairroCorrespondenciaController.text.length}/25',
                        maxLength: 25,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildCidadeAutocompleteCorrespondencia()),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: CustomInputField(
                        controller: _respCidadeCorrespondenciaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        //maxLength: 5,
                        readOnly: true,
                        label: "...", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _cepCorrespondenciaController, 
                        label: "CEP", 
                        maxLength: 20,
                        suffixText: '${_cepCorrespondenciaController.text.length}/20',
                        inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            CepInputFormatter(), // Adiciona o hífen automaticamente
                          ],
                        validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            // Validação do formato CEP #####-### e comprimento
                            if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value) || value.length != 9) {
                              return 'Formato de CEP inválido (#####-###)';
                            }
                            return null;
                          },
                          hintText: '#####-###',)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _attCorrespondenciaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        maxLength: 30,
                        suffixText: '${_attCorrespondenciaController.text.length}/30',
                        label: 'Att' ,
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                        
                    
                    
                  ],
                ),

                
        
        
        
        // Tabela de dados
        
      ],
    );
  }

  Widget _buildAbaEntrega({Key? key}) {
    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Entrega",
      children: [
        Row(
                    children: [
                      Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 250, right: 250),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 153, 205, 248), // Cor de fundo do container de integração
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.blue, width: 2.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0), // Padding interno para o conteúdo
                                  child: Row( // <-- Voltando para Row para manter o texto 'Integração' ao lado
                                    crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente o conteúdo da Row
                                    children: [
                                      Column(
                                        children: [
                                          const Text('Possui Endereço? :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                          //const Text('IPI :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                        ],
                                      ),
                                      // Removido SizedBox(width: 16) para compactar mais, você pode ajustar
                                      Expanded( // <-- O Expanded é importante para dar espaço aos CheckboxListTile
                                        child: Column( // Column para empilhar os CheckboxListTile
                                          crossAxisAlignment: CrossAxisAlignment.start, // Alinha os CheckboxListTile à esquerda
                                          mainAxisAlignment: MainAxisAlignment.center, // Centraliza os checkboxes na coluna
                                          children: [
                                            Row(
                                    children: [
                                      Checkbox(
                                        value: _possuiEndEntrega == true,
                                        onChanged: (bool? newValue) {
                                          if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                            setState(() {
                                              _possuiEndEntrega = true;
                                            });
                                          }
                                          
                                        },
                                        activeColor: Colors.blue,
                                      ),
                                      const Text('Sim', style: TextStyle(color: Colors.black)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _possuiEndEntrega == false,
                                        onChanged: (bool? newValue) {
                                          if (newValue == true) { // Só muda para false se o usuário CLICAR no "Não" (e o checkbox de "Não" for marcado)
                                            setState(() {
                                              _possuiEndEntrega = false;
                                            });
                                          }
                                        },
                                        activeColor: Colors.blue,
                                      ),
                                      const Text('Não', style: TextStyle(color: Colors.black)),
                                    ],
                                  ),]
                                        ),
                                      ),
                                      // Texto de integrações selecionadas movido para a direita, ou pode ser removido se não for essencial aqui
                                      // Padding(
                                      //   padding: const EdgeInsets.only(left: 8.0),
                                      //   child: Text(
                                      //     'Sel: ${_integracaoSelections.join(', ')}',
                                      //     style: const TextStyle(color: Colors.white, fontSize: 12),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                  SizedBox(height: 10,),

                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _enderecoEntregaController, 
                        label: "Endereço", 
                        suffixText: '${_enderecoEntregaController.text.length}/45',
                        maxLength: 45,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _numeroEntregaController, 
                        label: "Numero", 
                        suffixText: '${_numeroEntregaController.text.length}/10',
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),  
                        const SizedBox(width: 10),  
                        Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _complementoEntregaController, 
                        label: "Complemento", 
                        suffixText: '${_complementoEntregaController.text.length}/20',
                        maxLength: 20,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),                                                          
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _bairroEntregaController, 
                        label: "Bairro", 
                        suffixText: '${_bairroEntregaController.text.length}/25',
                        maxLength: 25,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildCidadeAutocompleteEntrega()),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: CustomInputField(
                        controller: _respCidadeEntregaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        //maxLength: 5,
                        readOnly: true,
                        label: "...", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _cepEntregaController, 
                        label: "CEP", 
                        maxLength: 20,
                        suffixText: '${_cepEntregaController.text.length}/9',
                        inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            CepInputFormatter(), // Adiciona o hífen automaticamente
                          ],
                        validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            // Validação do formato CEP #####-### e comprimento
                            if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value) || value.length != 9) {
                              return 'Formato de CEP inválido (#####-###)';
                            }
                            return null;
                          },
                          hintText: '#####-###',)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _attEntregaController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        maxLength: 30,
                        suffixText: '${_attEntregaController.text.length}/30',
                        label: 'Att' ,
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                        
                    
                    
                  ],
                ),

                
        
        
        
        // Tabela de dados
        
      ],
    );
  }

  Widget _buildAbaContatos({Key? key}) {
    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Contatos",
      children: [
        
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _sequenciaContatoController, 
                        label: "Sequencia", 
                        maxLength: 1,
                        suffixText: '${_sequenciaContatoController.text.length}/1',
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _nomeContatoController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        maxLength: 40,
                        label: "Nome", 
                        suffixText: '${_nomeContatoController.text.length}/40',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _dataNascimentoContatoController, 
                        //readOnly: true,
                        label: "Dt Nasc D/M", 
                        suffixText: '${_dataNascimentoContatoController.text.length}/5',
                        maxLength: 5,
                        //suffixText: '${_participacaoController.text.length}/35',
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                        
                    const SizedBox(width: 10),
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildCargoAutocomplete()),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: CustomInputField(
                        controller: _resulCargoContatoController, 
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        //maxLength: 5,
                        readOnly: true,
                        label: "...", 
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _emailContatoController, 
                        label: "E-mail", 
                        suffixText: '${_emailContatoController.text.length}/40',
                        maxLength: 40,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),  
                        const SizedBox(width: 10),                                                           
                  ],
                ),

                

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _obsContatoController, 
                        label: "Obs", 
                        suffixText: '${_obsContatoController.text.length}/40',
                        maxLength: 40,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    
                    const SizedBox(width: 10),
                    
                        
                    
                    
                  ],
                ),

                
        ElevatedButton(onPressed: _addContato, child: const Text("Adicionar Contato")),
        const Divider(thickness: 2, height: 40),
        
        // Tabela de dados
        StreamBuilder<QuerySnapshot>(
          stream: _campoComum1Controller.text.trim().isNotEmpty
              ? _collectionRef.doc(_campoComum1Controller.text.trim()).collection('contatos').snapshots()
              : null,
          builder: (context, snapshot) {
            if (_campoComum1Controller.text.trim().isEmpty) {
              return const Center(child: Text("Busque por um CPF/CNPJ para ver as referências."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Nenhum contato cadastrado."));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erro: ${snapshot.error}"));
            }
            
            final referencias = snapshot.data!.docs;

            return DataTable(
              columns: const [
                DataColumn(label: Text('Seq.')), DataColumn(label: Text('Nome')),
                DataColumn(label: Text('Data Nasc.')), DataColumn(label: Text('Cd. Cargo')),
                DataColumn(label: Text('Cargo')), 
                DataColumn(label: Text('E-mail')), DataColumn(label: Text('Obs.')),
                DataColumn(label: Text('Ação')),
              ],
              rows: referencias.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(data['sequencia contato'] ?? '')), DataCell(Text(data['nome contato'] ?? '')),
                  DataCell(Text(data['data nasc contato'] ?? '')), DataCell(Text(data['cargo contato'] ?? '')),
                  DataCell(Text(data['cargo res contato'] ?? '')),
                  DataCell(Text(data['email contato'] ?? '')), DataCell(Text(data['obs contato'] ?? '')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContato(_campoComum1Controller.text.trim(), doc.id),
                  )),
                ]);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

}



