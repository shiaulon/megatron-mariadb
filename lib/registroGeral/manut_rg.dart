import 'dart:io';

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
import 'package:collection/collection.dart';

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

    // Se o valor estiver vazio ou a seleção for no início, apenas retorne o novo valor
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Remove todos os caracteres não-dígitos
    String cleanText = text.replaceAll(RegExp(r'\D'), '');
    var buffer = StringBuffer();

    // Adiciona a primeira barra após os dois primeiros dígitos (dia)
    if (cleanText.length >= 1) {
      buffer.write(cleanText.substring(0, 1));
    }
    if (cleanText.length >= 2) {
      buffer.write(cleanText.substring(1, 2));
      // Se houver pelo menos 2 dígitos e ainda não for a string final, adicione '/'
      if (cleanText.length > 2) {
        buffer.write('/');
      }
    }
    // Adiciona o mês
    if (cleanText.length >= 3) {
      buffer.write(cleanText.substring(2, 3));
    }
    if (cleanText.length >= 4) {
      buffer.write(cleanText.substring(3, 4));
    }

    var string = buffer.toString();

    // Garante que o comprimento máximo seja respeitado (DD/MM = 5 caracteres)
    if (string.length > 5) {
      string = string.substring(0, 5);
    }

    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length <= 5) return newValue;
    return newValue.copyWith(
      text:
          '${text.substring(0, 5)}-${text.substring(5, text.length > 8 ? 8 : text.length)}',
      selection: TextSelection.collapsed(offset: newValue.selection.end + 1),
    );
  }
}

class PercentageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return TextEditingValue.empty;
    }

    double value = double.parse(newText) / 100.0;
    String formattedText = NumberFormat("#,##0.00", "pt_BR").format(value);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// NOVO FORMATTER: Para o campo de nome que precisa de apenas dígitos
class DigitsOnlyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Permite apenas dígitos
    final newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
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

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    var newText = '';
    if (text.length > 9) {
      newText =
          '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6, 9)}-${text.substring(9, text.length)}';
    } else if (text.length > 6) {
      newText =
          '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6, text.length)}';
    } else if (text.length > 3) {
      newText = '${text.substring(0, 3)}.${text.substring(3, text.length)}';
    } else {
      newText = text;
    }
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}


// NOVO: Validador unificado para CPF ou CNPJ


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
String _pageTitle = 'Dados Gerais'; // NOVO: Título inicial da página

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
  List<Map<String, dynamic>> _allSituacoes = [];
  Map<String, bool> _isFieldSelectedFromDropdown = {};

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

  final TextEditingController _codigoGeradoController = TextEditingController();
  final TextEditingController _dataInclusaoController = TextEditingController();

  final TextEditingController _sequenciaRefComercialController = TextEditingController();
  final TextEditingController _nomeRefComercialController = TextEditingController();
  final TextEditingController _resulNomeRefComercialController = TextEditingController();
  final TextEditingController _enderecoRefComercialController = TextEditingController();
  final TextEditingController _cidadeRefComercialController = TextEditingController();
  final TextEditingController _resulcidadeRefComercialController = TextEditingController();
  final TextEditingController _contatoRefComercialController = TextEditingController();
  final TextEditingController _telefoneRefComercialController = TextEditingController();
  final TextEditingController _emailRefComercialController = TextEditingController();
  final TextEditingController _obsRefComercialController = TextEditingController();

  String? _selectedContribIcms;
  String? _selectedRevenda;

  Map<String, String>? _editingCell;
  final TextEditingController _cellEditController = TextEditingController();
  final FocusNode _cellFocusNode = FocusNode();

  Stream<QuerySnapshot>? _telefonesStream;
  Stream<QuerySnapshot>? _sociosStream;
  Stream<QuerySnapshot>? _referenciasStream;
  Stream<QuerySnapshot>? _contatosStream;
  Stream<QuerySnapshot>? _referenciasComerciaisStream;

  bool _possuiEndCobran = false;
  bool _possuiEndCorrespondencia = false;
  bool _possuiEndEntrega = false;
  bool _hasUnsavedChanges = false;

  

  @override
  void initState() {
  super.initState();
  _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  _fetchAllControlData();
  _fetchAllCidades();
  _fetchAllCargos();
  _fetchAllSituacoes(); 

  _isFieldSelectedFromDropdown = {
        'campoComum1': false,
        'campoComum2': false,
        'campoComum3': false,
    };

  // Mantenha os listeners para os campos de busca que controlam a população/limpeza
  _campoComum1Controller.addListener(_updateStreams);
  _campoComum2Controller.addListener(_handleClearCheck);
  _campoComum3Controller.addListener(_handleClearCheck);
  _codigoGeradoController.addListener(_handleClearCheck);

  // NOVO: Apenas os campos de subcoleção que precisam da validação de input pendente.
  // Mantenha APENAS os listeners para `_checkSubcollectionInputChanges()`:
  _sqController.addListener(() => _checkSubcollectionInputChanges());
  _paisController.addListener(() => _checkSubcollectionInputChanges());
  _operadoraController.addListener(() => _checkSubcollectionInputChanges());
  _dddController.addListener(() => _checkSubcollectionInputChanges());
  _nroController.addListener(() => _checkSubcollectionInputChanges());
  _ramalController.addListener(() => _checkSubcollectionInputChanges());
  _tipoController.addListener(() => _checkSubcollectionInputChanges());
  _contatoController.addListener(() => _checkSubcollectionInputChanges());
  _socioController.addListener(() => _checkSubcollectionInputChanges());
  _nomeController.addListener(() => _checkSubcollectionInputChanges());
  _cpfController.addListener(() => _checkSubcollectionInputChanges());
  _cargoController.addListener(() => _checkSubcollectionInputChanges());
  _resulCargoController.addListener(() => _checkSubcollectionInputChanges());
  _participacaoController.addListener(() => _checkSubcollectionInputChanges());

  _sequenciaController.addListener(() => _checkSubcollectionInputChanges());
  _nomeRefBancariaController.addListener(() => _checkSubcollectionInputChanges());
  _resulNomeController.addListener(() => _checkSubcollectionInputChanges());
  _enderecoRefBancariaController.addListener(() => _checkSubcollectionInputChanges()); // Este agora chama _checkSubcollectionInputChanges
  _cidadeRefBancariaController.addListener(() => _checkSubcollectionInputChanges());
  //_resulEnderecoController.addListener(() => _checkSubcollectionInputChanges());
  _contatoRefBancariaController.addListener(() => _checkSubcollectionInputChanges());
  _telefoneRefBancariaController.addListener(() => _checkSubcollectionInputChanges());
  _emailRefBancariaController.addListener(() => _checkSubcollectionInputChanges());
  _obsRefBancariaController.addListener(() => _checkSubcollectionInputChanges());

  _sequenciaRefComercialController.addListener(() => _checkSubcollectionInputChanges());
  _nomeRefComercialController.addListener(() => _checkSubcollectionInputChanges());
  _resulNomeRefComercialController.addListener(() => _checkSubcollectionInputChanges());
  _enderecoRefComercialController.addListener(() => _checkSubcollectionInputChanges()); // Este agora chama _checkSubcollectionInputChanges
  _cidadeRefComercialController.addListener(() => _checkSubcollectionInputChanges());
  _contatoRefComercialController.addListener(() => _checkSubcollectionInputChanges());
  _telefoneRefComercialController.addListener(() => _checkSubcollectionInputChanges());
  _emailRefComercialController.addListener(() => _checkSubcollectionInputChanges());
  _obsRefComercialController.addListener(() => _checkSubcollectionInputChanges());

  _sequenciaContatoController.addListener(() => _checkSubcollectionInputChanges());
  _nomeContatoController.addListener(() => _checkSubcollectionInputChanges());
  _dataNascimentoContatoController.addListener(() => _checkSubcollectionInputChanges());
  _emailContatoController.addListener(() => _checkSubcollectionInputChanges());
  _obsContatoController.addListener(() => _checkSubcollectionInputChanges());

  /////////////////////////////////////////////////////////////
   _cepController.addListener(_updateCounters);
   _enderecoController.addListener(_updateCounters);
   _numeroController.addListener(_updateCounters);
   _complementoController.addListener(_updateCounters);
   _bairroController.addListener(_updateCounters);
   _cidadeController.addListener(_updateCounters);
   _ufController.addListener(_updateCounters);
   _cxPostalController.addListener(_updateCounters);
   _comoNosConheceuController.addListener(_updateCounters);
   _portadorController.addListener(_updateCounters);
   _tabDescontoController.addListener(_updateCounters);
   _inscSuframaController.addListener(_updateCounters);
   _inscProdutorController.addListener(_updateCounters);
   _inscMunicipalController.addListener(_updateCounters);
   _vendedorController.addListener(_updateCounters);
   _atendenteController.addListener(_updateCounters);
   _areaController.addListener(_updateCounters);
   _situacaoController.addListener(_updateCounters);
   _sqController.addListener(_updateCounters);
   _paisController.addListener(_updateCounters);
   _operadoraController.addListener(_updateCounters);
   _dddController.addListener(_updateCounters);
   _nroController.addListener(_updateCounters);
   _ramalController.addListener(_updateCounters);
   _tipoController.addListener(_updateCounters);
   _contatoController.addListener(_updateCounters);
   _cnpjController.addListener(_updateCounters);
   _inscEstadualController.addListener(_updateCounters);
   _contribIcmsController.addListener(_updateCounters);
   _revendaController.addListener(_updateCounters);
   _confidencialController.addListener(_updateCounters);
   _observacaoController.addListener(_updateCounters);
   _observacaoNfController.addListener(_updateCounters);
   _eMailController.addListener(_updateCounters);
   _eMailCobranController.addListener(_updateCounters);
   _eMailNfController.addListener(_updateCounters);
   _socioController.addListener(_updateCounters);
   _nomeController.addListener(_updateCounters);
   _cpfController.addListener(_updateCounters);
   _cargoController.addListener(_updateCounters);
   _resulCargoController.addListener(_updateCounters);
   _participacaoController.addListener(_updateCounters);
   _sequenciaController.addListener(_updateCounters);
   _nomeRefBancariaController.addListener(_updateCounters);
   _resulNomeController.addListener(_updateCounters);
   _enderecoRefBancariaController.addListener(_updateCounters);
   _resulEnderecoController.addListener(_updateCounters);
   _cidadeRefBancariaController.addListener(_updateCounters);
   _contatoRefBancariaController.addListener(_updateCounters);
   _telefoneRefBancariaController.addListener(_updateCounters);
   _emailRefBancariaController.addListener(_updateCounters);
   _obsRefBancariaController.addListener(_updateCounters);
   _siteController.addListener(_updateCounters);

   _1Controller.addListener(_updateCounters);
   _2Controller.addListener(_updateCounters);
   _3Controller.addListener(_updateCounters);
   _4Controller.addListener(_updateCounters);
   _5Controller.addListener(_updateCounters);
   _enderecoCobrancaController.addListener(_updateCounters);
   _numeroCobrancaController.addListener(_updateCounters);
   _complementoCobrancaController.addListener(_updateCounters);
   _bairroCobrancaController.addListener(_updateCounters);
   _cidadeCobrancaController.addListener(_updateCounters);
   _respCidadeCobrancaController.addListener(_updateCounters);
   _cepCobrancaController.addListener(_updateCounters);
   _attController.addListener(_updateCounters);

   _enderecoCorrespondenciaController.addListener(_updateCounters);
   _numeroCorrespondenciaController.addListener(_updateCounters);
   _complementoCorrespondenciaController.addListener(_updateCounters);
   _bairroCorrespondenciaController.addListener(_updateCounters);
   _cidadeCorrespondenciaController.addListener(_updateCounters);
   _respCidadeCorrespondenciaController.addListener(_updateCounters);
   _cepCorrespondenciaController.addListener(_updateCounters);
   _attCorrespondenciaController.addListener(_updateCounters);

   _enderecoEntregaController.addListener(_updateCounters);
   _numeroEntregaController.addListener(_updateCounters);
   _complementoEntregaController.addListener(_updateCounters);
   _bairroEntregaController.addListener(_updateCounters);
   _cidadeEntregaController.addListener(_updateCounters);
   _respCidadeEntregaController.addListener(_updateCounters);
   _cepEntregaController.addListener(_updateCounters);
   _attEntregaController.addListener(_updateCounters);

   _sequenciaContatoController.addListener(_updateCounters);
   _nomeContatoController.addListener(_updateCounters);
   _dataNascimentoContatoController.addListener(_updateCounters);
   _cargoContatoController.addListener(_updateCounters);
   _resulCargoContatoController.addListener(_updateCounters);
   _emailContatoController.addListener(_updateCounters);
   _obsContatoController.addListener(_updateCounters);

   _campoComum1Controller.addListener(_updateCounters);
   _campoComum2Controller.addListener(_updateCounters);
   _campoComum3Controller.addListener(_updateCounters);

   _codigoGeradoController.addListener(_updateCounters);
   _dataInclusaoController.addListener(_updateCounters);

   _sequenciaRefComercialController.addListener(_updateCounters);
   _nomeRefComercialController.addListener(_updateCounters);
   _resulNomeRefComercialController.addListener(_updateCounters);
   _enderecoRefComercialController.addListener(_updateCounters);
   _cidadeRefComercialController.addListener(_updateCounters);
   _resulcidadeRefComercialController.addListener(_updateCounters);
   _contatoRefComercialController.addListener(_updateCounters);
   _telefoneRefComercialController.addListener(_updateCounters);
   _emailRefComercialController.addListener(_updateCounters);
   _obsRefComercialController.addListener(_updateCounters);

  // ADICIONAL: Adicione o listener para carregar os estados dos checkboxes de endereço
  _campoComum1Controller.addListener(_loadCheckboxStates);
}

void _updateCounters() {
    setState(() {});
  }

  bool _hasSubcollectionInputChanges = false;

  void _checkSubcollectionInputChanges() {
    bool anyFieldHasContent = false;
    // Verifique os controllers da aba de Telefone
    if (_selectedIndex == 1 &&
        (_sqController.text.isNotEmpty ||
            _paisController.text.isNotEmpty ||
            _operadoraController.text.isNotEmpty ||
            _dddController.text.isNotEmpty ||
            _nroController.text.isNotEmpty ||
            _ramalController.text.isNotEmpty ||
            _tipoController.text.isNotEmpty ||
            _contatoController.text.isNotEmpty)) {
      anyFieldHasContent = true;
    }
    // Verifique os controllers da aba de Composição Acionária
    if (_selectedIndex == 4 &&
        (_sqController.text.isNotEmpty || // SQ é compartilhado
            _socioController.text.isNotEmpty ||
            _nomeController.text.isNotEmpty ||
            _cpfController.text.isNotEmpty ||
            _cargoController.text.isNotEmpty || // Cargo é compartilhado
            _resulCargoController.text.isNotEmpty || // Cargo res é compartilhado
            _participacaoController.text.isNotEmpty)) {
      anyFieldHasContent = true;
    }
    // Verifique os controllers da aba de Contatos
    if (_selectedIndex == 11 && // <-- Corrigido o index para a aba de Contatos
        (_sequenciaContatoController.text.isNotEmpty ||
            _nomeContatoController.text.isNotEmpty ||
            _dataNascimentoContatoController.text.isNotEmpty ||
            _cargoContatoController.text.isNotEmpty || // ADICIONADO: Campo 'cargo' da aba de Contatos
            _resulCargoContatoController.text.isNotEmpty ||
            _emailContatoController.text.isNotEmpty ||
            _obsContatoController.text.isNotEmpty)) {
      anyFieldHasContent = true;
    }
    // Verifique os controllers da aba de Referência Bancária
    if (_selectedIndex == 5 &&
        (_sequenciaController.text.isNotEmpty || // Sequencia é compartilhado
            _nomeRefBancariaController.text.isNotEmpty ||
            _resulNomeController.text.isNotEmpty ||
            _enderecoRefBancariaController.text.isNotEmpty ||
            _cidadeRefBancariaController.text.isNotEmpty ||
            //_resulEnderecoController.text.isNotEmpty ||
            _contatoRefBancariaController.text.isNotEmpty ||
            _telefoneRefBancariaController.text.isNotEmpty ||
            _emailRefBancariaController.text.isNotEmpty ||
            _obsRefBancariaController.text.isNotEmpty)) {
      anyFieldHasContent = true;
    }
    // NOVO: Verifique os controllers da aba de Referência Comercial
    if (_selectedIndex == 6 && // <-- NOVO: Index da aba Comercial
        (_sequenciaRefComercialController.text.isNotEmpty ||
            _nomeRefComercialController.text.isNotEmpty ||
            _resulNomeRefComercialController.text.isNotEmpty ||
            _enderecoRefComercialController.text.isNotEmpty ||
            _cidadeRefComercialController.text.isNotEmpty ||
            _contatoRefComercialController.text.isNotEmpty ||
            _telefoneRefComercialController.text.isNotEmpty ||
            _emailRefComercialController.text.isNotEmpty ||
            _obsRefComercialController.text.isNotEmpty)) {
      anyFieldHasContent = true;
    }

    if (_hasSubcollectionInputChanges != anyFieldHasContent) {
      setState(() {
        _hasSubcollectionInputChanges = anyFieldHasContent;
      });
    }
  }

  void _setUnsavedChanges(bool hasChanges) {
    if (_hasUnsavedChanges != hasChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  

  // NOVO MÉTODO: Para carregar o estado dos checkboxes baseado nos dados da empresa
  // Isso deve ser chamado quando uma empresa é carregada (e não apenas quando um campo é modificado).
  void _loadCheckboxStates() {
      final docId = _campoComum1Controller.text.trim();
      if (docId.isNotEmpty) {
          _collectionRef.doc(docId).get().then((docSnapshot) {
              if (docSnapshot.exists) {
                  final data = docSnapshot.data() as Map<String, dynamic>;
                  setState(() {
                      _possuiEndCobran = (data['endereco cobranca']?.isNotEmpty ?? false);
                      _possuiEndCorrespondencia = (data['endereco correspondencia']?.isNotEmpty ?? false);
                      _possuiEndEntrega = (data['endereco entrega']?.isNotEmpty ?? false);
                      _setUnsavedChanges(false); // Resetar flag após carregar dados
                  });
              } else {
                  // Se o documento não existir, resetar os checkboxes e a flag
                  setState(() {
                      _possuiEndCobran = false;
                      _possuiEndCorrespondencia = false;
                      _possuiEndEntrega = false;
                      _setUnsavedChanges(false);
                  });
              }
          });
      } else {
          // Se o campo de busca estiver vazio, resetar os checkboxes e a flag
          setState(() {
              _possuiEndCobran = false;
              _possuiEndCorrespondencia = false;
              _possuiEndEntrega = false;
              _setUnsavedChanges(false);
          });
      }
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
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('cidades')
      .collection('items');

  CollectionReference get _cargosCollectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('cargos')
      .collection('items');

  CollectionReference get _situacoesCollectionRef => FirebaseFirestore.instance
    .collection('companies')
    .doc(widget.mainCompanyId)
    .collection('secondaryCompanies')
    .doc(widget.secondaryCompanyId)
    .collection('data')
    .doc('situacoes') // Assumindo 'situacoes' como nome do documento pai
    .collection('items');

  // Busca todos os dados para popular os dropdowns
  Future<void> _fetchAllControlData() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _collectionRef.get();
      _allControlData = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cidades: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cargos: $e')));
    }
  }

  Future<void> _fetchAllSituacoes() async {
  try {
    final querySnapshot = await _situacoesCollectionRef.get();
    _allSituacoes = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Ajuste os campos 'id' e 'descricao' conforme a sua estrutura real de "situacoes"
      return {'id': doc.id, 'descricao': data['descricao'] ?? 'Situação sem descrição'};
    }).toList();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar situações: $e')));
  }
}

  // Preenche todos os campos com base no item selecionado no dropdown
  void _populateAllFields(Map<String, dynamic> data) {
    setState(() {
      _campoComum1Controller.text = data['campoComum1'] ?? '';
      _campoComum2Controller.text = data['campoComum2'] ?? '';
      _campoComum3Controller.text = data['campoComum3'] ?? '';
      _codigoGeradoController.text = data['codigoGerado'] ?? '';
      if (data['dataInclusao'] != null) {
        final timestamp = data['dataInclusao'] as Timestamp;
        _dataInclusaoController.text = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
      } else {
        _dataInclusaoController.clear();
      }

      _isFieldSelectedFromDropdown['campoComum1'] = true;
      _isFieldSelectedFromDropdown['campoComum2'] = true;
      _isFieldSelectedFromDropdown['campoComum3'] = true;

      // Resetar flags de alteração, pois os dados foram carregados (estado "limpo").
      _hasUnsavedChanges = false;
      _hasSubcollectionInputChanges = false;

      

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
      _2Controller.text = data['2c'] ?? '';
      _3Controller.text = data['3'] ?? '';
      _4Controller.text = data['4'] ?? '';
      _5Controller.text = data['5'] ?? '';

      _enderecoCobrancaController.text = data['endereco cobranca'] ?? '';
      _numeroCobrancaController.text = data['numero cobranca'] ?? '';
      _complementoCobrancaController.text = data['complemento cobranca'] ?? '';
      _bairroCobrancaController.text = data['bairro cobranca'] ?? '';
      _cidadeCobrancaController.text = data['cidade cobranca'] ?? '';
      _respCidadeCobrancaController.text = data['resp cidade cobranca'] ?? '';
      _cepCobrancaController.text = data['cep cobranca'] ?? '';
      _attController.text = data['att'] ?? '';

      _enderecoCorrespondenciaController.text = data['endereco correspondencia'] ?? '';
      _numeroCorrespondenciaController.text = data['numero correspondencia'] ?? '';
      _complementoCorrespondenciaController.text = data['complemento correspondencia'] ?? '';
      _bairroCorrespondenciaController.text = data['bairro correspondencia'] ?? '';
      _cidadeCorrespondenciaController.text = data['cidade correspondencia'] ?? '';
      _respCidadeCorrespondenciaController.text = data['resp cidade correspondencia'] ?? '';
      _cepCorrespondenciaController.text = data['cep correspondencia'] ?? '';
      _attCorrespondenciaController.text = data['att correspondencia'] ?? '';

      _enderecoEntregaController.text = data['endereco entrega'] ?? '';
      _numeroEntregaController.text = data['numero entrega'] ?? '';
      _complementoEntregaController.text = data['complemento entrega'] ?? '';
      _bairroEntregaController.text = data['bairro entrega'] ?? '';
      _cidadeEntregaController.text = data['cidade entrega'] ?? '';
      _respCidadeEntregaController.text = data['resp cidade entrega'] ?? '';
      _cepEntregaController.text = data['cep entrega'] ?? '';
      _attEntregaController.text = data['att entrega'] ?? '';

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
      /*_socioController.text = data['socio'] ?? '';
      _nomeController.text = data['nome'] ?? '';
      _cpfController.text = data['cpf'] ?? '';
      _cargoController.text = data['cargo'] ?? '';
      _resulCargoController.text = data['cargo res'] ?? '';
      _participacaoController.text = data['participacao'] ?? '';*/

      /*_sequenciaController.text = data['sequencia ref banc'] ?? '';
      _nomeRefBancariaController.text = data['nome ref banc'] ?? '';
      _enderecoRefBancariaController.text = data['endereco ref banc'] ?? '';
      _cidadeRefBancariaController.text = data['cidade ref banc'] ?? '';
      _contatoRefBancariaController.text = data['contato ref banc'] ?? '';
      _telefoneRefBancariaController.text = data['telefone ref banc'] ?? '';
      _emailRefBancariaController.text = data['email ref banc'] ?? '';
      _obsRefBancariaController.text = data['obs ref banc'] ?? '';

      _sequenciaRefComercialController.text = data['sequencia ref comercial'] ?? '';
      _nomeRefComercialController.text = data['nome ref comercial'] ?? '';
      //_resulNomeRefComercialController.text = data['resul nome ref comercial'] ?? '';
      _enderecoRefComercialController.text = data['endereco ref comercial'] ?? '';
      _cidadeRefComercialController.text = data['cidade ref comercial'] ?? '';
      _contatoRefComercialController.text = data['contato ref comercial'] ?? '';
      _telefoneRefComercialController.text = data['telefone ref comercial'] ?? '';
      _emailRefComercialController.text = data['email ref comercial'] ?? '';
      _obsRefComercialController.text = data['obs ref comercial'] ?? '';

      _sequenciaContatoController.text = data['sequencia contato'] ?? '';
      _nomeContatoController.text = data['nome contato'] ?? '';
      _dataNascimentoContatoController.text = data['data nasc contato'] ?? '';
      _cargoContatoController.text = data['cargo contato'] ?? '';
      _resulCargoContatoController.text = data['cargo res contato'] ?? '';
      _emailContatoController.text = data['email contato'] ?? '';
      _obsContatoController.text = data['obs contato'] ?? '';*/

      // ADICIONAR: Atualizar o estado dos checkboxes de endereço ao popular os campos
      _possuiEndCobran = (data['endereco cobranca']?.isNotEmpty ?? false);
      _possuiEndCorrespondencia = (data['endereco correspondencia']?.isNotEmpty ?? false);
      _possuiEndEntrega = (data['endereco entrega']?.isNotEmpty ?? false);

      //_setUnsavedChanges(false); // Resetar flag após carregar um item do banco
      // Resetar flags após o preenchimento programático.
    _hasUnsavedChanges = false;
    _hasSubcollectionInputChanges = false;
    });
  }

  void _populateCidadeGeralFields(Map<String, dynamic> cidadeData) {
    setState(() {
      _cidadeController.text = cidadeData['id'] ?? ''; // Ou cidadeData['cidade'] se você quiser o nome completo
      // Se você tiver um campo de "descrição" para a cidade, pode ser preenchido aqui.
      // Por exemplo: _resulCidadeController.text = cidadeData['cidade'] ?? '';
    });
  }

  void _populateSituacaoFields(Map<String, dynamic> situacaoData) {
    setState(() {
      _situacaoController.text = situacaoData['id'] ?? ''; // Assumindo que o ID é o valor que vai no campo de entrada
      // Se houver um campo de 'descrição' adicional para situação, preencha-o aqui.
      // Ex: _resulSituacaoController.text = situacaoData['descricao'] ?? '';
    });
  }

  void _populateCidadeFields(Map<String, dynamic> cidadeData) {
    setState(() {
      _cidadeRefBancariaController.text = cidadeData['id'] ?? '';
      _resulEnderecoController.text = cidadeData['cidade'] ?? '';
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
    // ... (limpeza de todos os controladores existentes)

    _sequenciaRefComercialController.clear();
    _nomeRefComercialController.clear();
    _resulNomeRefComercialController.clear();
    _enderecoRefComercialController.clear();
    _cidadeRefComercialController.clear();
    _contatoRefComercialController.clear();
    _telefoneRefComercialController.clear();
    _emailRefComercialController.clear();
    _obsRefComercialController.clear();

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
    _dataInclusaoController.clear();


    setState(() {
    _selectedContribIcms = null;
    _selectedRevenda = null;
    _possuiEndCobran = false;
    _possuiEndCorrespondencia = false;
    _possuiEndEntrega = false;
    _hasUnsavedChanges = false; // Resetar flag de campos principais
    _hasSubcollectionInputChanges = false; // Resetar flag de campos de subcoleção
  });
  }

  // NOVA FUNÇÃO: Limpa apenas os campos de busca
  void _clearSearchFields() {
    _campoComum1Controller.clear();
    _campoComum2Controller.clear();
    _campoComum3Controller.clear();
    _codigoGeradoController.clear();
    // NEW: Clear selection status for search fields
    setState(() {
        _isFieldSelectedFromDropdown['campoComum1'] = false;
        _isFieldSelectedFromDropdown['campoComum2'] = false;
        _isFieldSelectedFromDropdown['campoComum3'] = false;
    });
}

  // Verifica se os campos de busca estão vazios para limpar o formulário
  void _handleClearCheck() {
  if (_campoComum1Controller.text.isEmpty &&
      _campoComum2Controller.text.isEmpty &&
      _campoComum3Controller.text.isEmpty && _codigoGeradoController.text.isEmpty) {
    setState(() {
      _clearDependentFields();
    });
  }
}

  Future<void> _generateNewCodigo() async {
    if (_codigoGeradoController.text.isNotEmpty) return; // Não gera se já houver um código
    setState(() => _isLoading = true);
    try {
      // Busca todos os documentos para encontrar o maior código
      final querySnapshot = await _collectionRef.get();
      int maxCode = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final codeStr = data['codigoGerado'];
        if (codeStr != null) {
          final code = int.tryParse(codeStr);
          if (code != null && code > maxCode) {
            maxCode = code;
          }
        }
      }
      // Novo código é o maior encontrado + 1
      final newCode = (maxCode + 1).toString();
      final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      setState(() {
        _codigoGeradoController.text = newCode;
        _dataInclusaoController.text = formattedDate;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao gerar novo código: $e')));
    } finally {
      setState(() => _isLoading = false);
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
      'codigoGerado': _codigoGeradoController.text,

      /*'sequencia ref comercial': _sequenciaRefComercialController.text,
      'nome ref comercial': _nomeRefComercialController.text,
      'resul nome ref comercial': _resulNomeRefComercialController.text,
      'endereco ref comercial': _enderecoRefComercialController.text,
      'cidade ref comercial': _cidadeRefComercialController.text,
      'contato ref comercial': _contatoRefComercialController.text,
      'telefone ref comercial': _telefoneRefComercialController.text,
      'email ref comercial': _emailRefComercialController.text,
      'obs ref comercial': _obsRefComercialController.text,*/

      'cep': _cepController.text,
      'endereco': _enderecoController.text,
      'numero': _numeroController.text,
      'complemento': _complementoController.text,
      'bairro': _bairroController.text,
      'cidade': _cidadeController.text,
      'uf': _ufController.text,
      'cx. Postal': _cxPostalController.text,
      'como nos conheceu': _comoNosConheceuController.text,
      'portador': _portadorController.text,
      'tab desconto': _tabDescontoController.text,
      'insc suframa': _inscSuframaController.text,
      'insc produtor': _inscProdutorController.text,
      'insc municipal': _inscMunicipalController.text,
      'vendedor': _vendedorController.text,
      'atendente': _atendenteController.text,
      'area': _areaController.text,
      'situacao': _situacaoController.text,
      'sq': _sqController.text,
      'pais': _paisController.text,
      'operadora': _operadoraController.text,
      'ddd': _dddController.text,
      'nro': _nroController.text,
      'ramal': _ramalController.text,
      'tipo': _tipoController.text,
      'contato': _contatoController.text,
      'cnpj': _cnpjController.text,
      'insc estadual': _inscEstadualController.text,
      'contrib ICMS': _selectedContribIcms,
      'revenda': _selectedRevenda,
      'confidencial': _confidencialController.text,
      'observacao': _observacaoController.text,
      'observacao Nf': _observacaoNfController.text,
      'email': _eMailController.text,
      'email cobranca': _eMailCobranController.text,
      'email Nf': _eMailNfController.text,
      'socio': _socioController.text,
      'nome': _nomeController.text,
      'cpf': _cpfController.text,
      'cargo': _cargoController.text,
      'cargo res': _resulCargoController.text,
      'participacao': _participacaoController.text,

      'sequencia ref banc': _sequenciaController.text,
      'nome ref banc': _nomeRefBancariaController.text,
      //'resul nome ref banc' :_resulNomeController.text,
      'endereco ref banc': _enderecoRefBancariaController.text,
      'resul endereco ref banc' :_resulEnderecoController.text,
      'cidade ref banc': _cidadeRefBancariaController.text,
      'contato ref banc': _contatoRefBancariaController.text,
      'telefone ref banc': _telefoneRefBancariaController.text,
      'email ref banc': _emailRefBancariaController.text,
      'obs ref banc': _obsRefBancariaController.text,
      'site': _siteController.text,

      '1': _1Controller.text,
      '2c': _2Controller.text,
      '3': _3Controller.text,
      '4': _4Controller.text,
      '5': _5Controller.text,

      'endereco cobranca': _enderecoCobrancaController.text,
      'numero cobranca': _numeroCobrancaController.text,
      'complemento cobranca': _complementoCobrancaController.text,
      'bairro cobranca': _bairroCobrancaController.text,
      'cidade cobranca': _cidadeCobrancaController.text,
      'resp cidade cobranca': _respCidadeCobrancaController.text,
      'cep cobranca': _cepCobrancaController.text,
      'att': _attController.text,

      'endereco correspondencia': _enderecoCorrespondenciaController.text,
      'numero correspondencia': _numeroCorrespondenciaController.text,
      'complemento correspondencia': _complementoCorrespondenciaController.text,
      'bairro correspondencia': _bairroCorrespondenciaController.text,
      'cidade correspondencia': _cidadeCorrespondenciaController.text,
      'resp cidade correspondencia': _respCidadeCorrespondenciaController.text,
      'cep correspondencia': _cepCorrespondenciaController.text,
      'att correspondencia': _attCorrespondenciaController.text,

      'endereco entrega': _enderecoEntregaController.text,
      'numero entrega': _numeroEntregaController.text,
      'complemento entrega': _complementoEntregaController.text,
      'bairro entrega': _bairroEntregaController.text,
      'cidade entrega': _cidadeEntregaController.text,
      'resp cidade entrega': _respCidadeEntregaController.text,
      'cep entrega': _cepEntregaController.text,
      'att entrega': _attEntregaController.text,

      'sequencia contato': _sequenciaContatoController.text,
      'nome contato': _nomeContatoController.text,
      'data nasc contato': _dataNascimentoContatoController.text,
      'cargo contato': _cargoContatoController.text,
      'cargo res contato': _resulCargoContatoController.text,
      'email contato': _emailContatoController.text,
      'obs contato': _obsContatoController.text,

      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'atualizado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      await _collectionRef.doc(docId).set(dataToSave, SetOptions(merge: true));
      await _fetchAllControlData(); // Atualiza a lista de sugestões
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados de controle salvos com sucesso!')),
      );
      _setUnsavedChanges(false); // Resetar flag após salvar com sucesso
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final socioData = {
      'sq': _sqController.text,
      'socio': _socioController.text,
      'nome': _nomeController.text,
      'cpf': _cpfController.text,
      'cargo': _cargoController.text,
      'cargo res': _resulCargoController.text,
      'participacao': _participacaoController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('composicao_acionaria').add(socioData);
      _socioController.clear();
      _nomeController.clear();
      _sqController.clear();
      _cargoController.clear();
      _resulCargoController.clear();
      _participacaoController.clear();
      _cpfController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao adicionar sócio: $e')));
    }
  }

  Future<void> _deleteSocio(String itemId, String socioId) async {
    try {
      await _collectionRef.doc(itemId).collection('composicao_acionaria').doc(socioId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao deletar sócio: $e')));
    }
  }

  Future<void> _addTelefone() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final telefoneData = {
      'sq': _sqController.text, 'pais': _paisController.text, 'operadora': _operadoraController.text,
      'ddd': _dddController.text, 'nro': _nroController.text, 'ramal': _ramalController.text,
      'tipo': _tipoController.text, 'contato': _contatoController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('telefones').add(telefoneData);
      _sqController.clear();
      _paisController.clear();
      _operadoraController.clear();
      _dddController.clear();
      _nroController.clear();
      _ramalController.clear();
      _tipoController.clear();
      _contatoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao adicionar telefone: $e')));
    }
  }

  Future<void> _deleteTelefone(String itemId, String telefoneId) async {
    try {
      await _collectionRef.doc(itemId).collection('telefones').doc(telefoneId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao deletar telefone: $e')));
    }
  }

  Future<void> _updateSubcollectionField(
      String subcollection, String parentItemId, String docId, String field, String newValue) async {
    if (parentItemId.isEmpty) return;

    try {
      await _collectionRef
          .doc(parentItemId)
          .collection(subcollection)
          .doc(docId)
          .update({field: newValue});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar campo: $e')),
      );
    }
  }

  void _updateStreams() {
    final docId = _campoComum1Controller.text.trim();
    setState(() {
      if (docId.isNotEmpty) {
        _telefonesStream = _collectionRef.doc(docId).collection('telefones').snapshots();
        _sociosStream = _collectionRef.doc(docId).collection('composicao_acionaria').snapshots();
        _referenciasStream = _collectionRef.doc(docId).collection('referencias_bancarias').snapshots();
        _contatosStream = _collectionRef.doc(docId).collection('contatos').snapshots();
        _referenciasComerciaisStream = _collectionRef.doc(docId).collection('referencias_comerciais').snapshots(); // NOVO STREAM

      } else {
        _telefonesStream = null;
        _sociosStream = null;
        _referenciasStream = null;
        _contatosStream = null;
        _referenciasComerciaisStream = null;
      }
    });
  }

  Future<void> _addReferenciaComercial() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')),
      );
      return;
    }

    final refData = {
      'sequencia ref comercial': _sequenciaRefComercialController.text,
      'nome ref comercial': _nomeRefComercialController.text,
      'resul nome ref comercial': _resulNomeRefComercialController.text, // Campo "..."
      'endereco ref comercial': _enderecoRefComercialController.text,
      'cidade ref comercial': _resulcidadeRefComercialController.text,
      'contato ref comercial': _contatoRefComercialController.text,
      'telefone ref comercial': _telefoneRefComercialController.text,
      'email ref comercial': _emailRefComercialController.text,
      'obs ref comercial': _obsRefComercialController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('referencias_comerciais').add(refData);
      // Limpar os campos após adicionar
      _sequenciaRefComercialController.clear();
      _nomeRefComercialController.clear();
      _resulNomeRefComercialController.clear();
      _enderecoRefComercialController.clear();
      _cidadeRefComercialController.clear();
      _resulcidadeRefComercialController.clear();
      _contatoRefComercialController.clear();
      _telefoneRefComercialController.clear();
      _emailRefComercialController.clear();
      _obsRefComercialController.clear();
      _checkSubcollectionInputChanges(); // Recalcula a flag após limpar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referência comercial adicionada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar referência comercial: $e')),
      );
    }
  }

// NOVO MÉTODO: _deleteReferenciaComercial
Future<void> _deleteReferenciaComercial(String itemId, String refId) async {
    try {
      await _collectionRef.doc(itemId).collection('referencias_comerciais').doc(refId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referência comercial deletada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar referência comercial: $e')),
      );
    }
  }

  Future<void> _addReferenciaBancaria() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final refData = {
      'sequencia ref banc': _sequenciaController.text, 'nome ref banc': _nomeRefBancariaController.text,
      'endereco ref banc': _enderecoRefBancariaController.text, 'resul endereco ref banc': _resulEnderecoController.text,
      'contato ref banc': _contatoRefBancariaController.text, 'telefone ref banc': _telefoneRefBancariaController.text,
      'email ref banc': _emailRefBancariaController.text, 'obs ref banc': _obsRefBancariaController.text,
    };

    try {
      await _collectionRef.doc(docId).collection('referencias_bancarias').add(refData);
      _sequenciaController.clear();
      _nomeRefBancariaController.clear();
      _enderecoRefBancariaController.clear();
      _cidadeRefBancariaController.clear();
      _resulEnderecoController.clear();
      _cidadeController.clear();
      _contatoRefBancariaController.clear();
      _telefoneRefBancariaController.clear();
      _emailRefBancariaController.clear();
      _obsRefBancariaController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao adicionar referência: $e')));
    }
  }

  Future<void> _deleteReferenciaBancaria(String itemId, String refId) async {
    try {
      await _collectionRef.doc(itemId).collection('referencias_bancarias').doc(refId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao deletar referência: $e')));
    }
  }

  Future<void> _addContato() async {
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
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
      _sequenciaContatoController.clear();
      _nomeContatoController.clear();
      _dataNascimentoContatoController.clear();
      _cargoContatoController.clear();
      _resulCargoContatoController.clear();
      _emailContatoController.clear();
      _obsContatoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao adicionar referência: $e')));
    }
  }

  Future<void> _deleteContato(String itemId, String refId) async {
    try {
      await _collectionRef.doc(itemId).collection('contatos').doc(refId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao deletar referência: $e')));
    }
  }

  String? _cpfCnpjValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo CPF/CNPJ é obrigatório.';
  }

  String cleanValue = value.replaceAll(RegExp(r'\D'), ''); // Remove all non-digits

  if (cleanValue.length < 11) {
    return 'O CPF deve ter 11 dígitos ou o CNPJ 14 dígitos.'; // More generic initial message
  } else if (cleanValue.length > 14) {
      return 'CPF/CNPJ não pode ter mais de 14 dígitos.';
  }

  if (cleanValue.length == 11) {
    // It's likely a CPF, perform CPF validation
    return _cpfValidator(value); // Delegate to your existing CPF validator
  } else if (cleanValue.length == 14) {
    // It's likely a CNPJ, perform CNPJ validation
    return _cnpjValidator(value); // Delegate to your existing CNPJ validator
  } else {
    // If length is between 11 and 14 (e.g., 12 or 13), it's invalid
    return 'CPF deve ter 11 dígitos ou CNPJ 14 dígitos.';
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
            //userRole: widget.userRole,
                          ),
        ),
        Expanded(
          flex: 4,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding( // MODIFICAÇÃO AQUI
                padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: Text(_pageTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), // Usa a variável _pageTitle
              ),
                //_buildCamposDeBusca(),
                Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildDynamicCentralArea(),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildVerticalTabMenu(),
                      ),
                    ],
                  ),
                ),
                //_buildSaveButton(),
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
          Padding( // MODIFICAÇÃO AQUI
          padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
          child: Text(_pageTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // Usa a variável _pageTitle
        ),
          //_buildCamposDeBusca(),
          Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
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
                        _buildAbaReferenciaComercial(),
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
          //_buildSaveButton(),
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
            _buildTabButton(title: 'Composição Acionária', index: 4),
            _buildTabButton(title: 'Bancária', index: 5),
            _buildTabButton(title: 'Comercial', index: 6), // Novo botão de aba
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
      onPressed: () async {
        // Verifica se está mudando para uma aba diferente
        if (_selectedIndex != index) {
          bool shouldProceed = true; // Assume que pode prosseguir por padrão

          // --- NOVO: Verificação e Reset antes de qualquer validação de saída ---
          // Antes de decidir se há um alerta, resetamos a flag de subcoleção
          // para a ABA ATUAL se não houver dados nos campos.
          // Isso evita que o alerta "seja levado" para a próxima aba.
          if ([1, 4, 11, 6, 5].contains(_selectedIndex)) { // Se a aba atual É uma aba de subcoleção
             // Reavalia o estado dos campos de entrada da subcoleção para a aba atual
             _checkSubcollectionInputChanges(); // Isso pode setar _hasSubcollectionInputChanges para false se os campos estiverem vazios
          }
          // --- FIM DO NOVO BLOCO ---


          // Lógica para abas com o botão SALVAR (Dados Gerais, Jurídica, Complemento, Nome Fantasia, Endereços, Referencia Bancaria)
          if ([0, 2, 3, 7, 8, 9, 10].contains(_selectedIndex) && _hasUnsavedChanges) {
            final result = await _showUnsavedChangesDialog();
            if (result == true) { // Usuário quer salvar
              await _saveData();
              shouldProceed = !_hasUnsavedChanges; // Procede se salvou com sucesso
            } else if (result == false) { // Usuário quer sair sem salvar
              _setUnsavedChanges(false); // Descarta alterações
              shouldProceed = true;
            } else { // Usuário cancelou
              shouldProceed = false;
            }
          }
          // Lógica para abas SEM o botão SALVAR (Telefone, Composição Acionária, Contatos, Referência Comercial)
          else if ([1, 4, 11, 6, 5].contains(_selectedIndex) && _hasSubcollectionInputChanges) {
            final result = await _showUnsavedSubcollectionChangesDialog();
            if (result == false) { // Usuário quer descartar
              _clearSubcollectionInputFields(_selectedIndex); // Limpa os campos da aba atual
              // _hasSubcollectionInputChanges = false; // Já é feito dentro de _clearSubcollectionInputFields
              shouldProceed = true;
            } else if (result == null) { // Usuário cancelou
              shouldProceed = false;
            }
          }

          if (shouldProceed) {
            setState(() {
              _selectedIndex = index;
              _pageTitle = title;
            });
            // Após mudar a aba, reavalie os campos da NOVA aba.
            // Isso é especialmente importante se a nova aba também for de subcoleção.
            _checkSubcollectionInputChanges();
          }
        }
      },
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

  // NOVO MÉTODO: Diálogo para alterações não salvas em campos de subcoleção
  Future<bool?> _showUnsavedSubcollectionChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dados de Entrada Não Adicionados'),
          content: const Text('Você tem dados nos campos de entrada que não foram adicionados à lista. Deseja descartá-los?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Descartar
              },
              child: const Text('Descartar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancelar
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // NOVO MÉTODO: Para limpar os campos de entrada de subcoleção da aba atual
  void _clearSubcollectionInputFields(int tabIndex) {
    setState(() {
      switch (tabIndex) {
        case 1: // Telefone
          _sqController.clear();
          _paisController.clear();
          _operadoraController.clear();
          _dddController.clear();
          _nroController.clear();
          _ramalController.clear();
          _tipoController.clear();
          _contatoController.clear();
          break;
        case 4: // Composição Acionária
          _sqController.clear();
          _socioController.clear();
          _nomeController.clear();
          _cpfController.clear();
          _cargoController.clear();
          _resulCargoController.clear();
          _participacaoController.clear();
          break;
        case 5: // Referência Bancária
          _sequenciaController.clear();
          _nomeRefBancariaController.clear();
          _resulNomeController.clear();
          _enderecoRefBancariaController.clear();
          //_resulEnderecoController.clear();
          _cidadeRefBancariaController.clear();
          _contatoRefBancariaController.clear();
          _telefoneRefBancariaController.clear();
          _emailRefBancariaController.clear();
          _obsRefBancariaController.clear();
          break;
        case 11: // Contatos // ALTERADO: Index para Contatos
          _sequenciaContatoController.clear();
          _nomeContatoController.clear();
          _dataNascimentoContatoController.clear();
          _cargoContatoController.clear();
          _resulCargoContatoController.clear();
          _emailContatoController.clear();
          _obsContatoController.clear();
          break;
        case 6: // Referência Comercial (NOVA ABA) // ADICIONADO: Nova aba Comercial
          _sequenciaRefComercialController.clear();
          _nomeRefComercialController.clear();
          _resulNomeRefComercialController.clear();
          _enderecoRefComercialController.clear();
          _cidadeRefComercialController.clear();
          _contatoRefComercialController.clear();
          _telefoneRefComercialController.clear();
          _emailRefComercialController.clear();
          _obsRefComercialController.clear();
          break;
      }
      _hasSubcollectionInputChanges = false; // Resetar a flag após limpar
    });
  }

  // NOVO MÉTODO: Diálogo para alterações não salvas
  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alterações Não Salvas'),
          content: const Text('Você tem alterações não salvas. Deseja salvá-las antes de sair?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Sair sem salvar
              },
              child: const Text('Sair sem Salvar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Salvar
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancelar
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
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
        6 => _buildAbaReferenciaComercial(key: const ValueKey('aba6')), // Nova aba aqui
        7 => _buildAbaNomeFantasia(key: const ValueKey('aba7')),
        8 => _buildAbaEnderecoCobranca(key: const ValueKey('aba8')),
        9 => _buildAbaCorrespondencia(key: const ValueKey('aba9')),
        10 => _buildAbaEntrega(key: const ValueKey('aba10')),
        11 => _buildAbaContatos(key: const ValueKey('aba11')),
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
  Widget _buildAutocompleteField(
    TextEditingController controller,
    String label,
    String fieldKey, {
    bool isRequired = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    VoidCallback? onUserInteraction,
}) {
    return Autocomplete<Map<String, dynamic>>(
        displayStringForOption: (option) => option[fieldKey] as String,
        optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
                // Reset selection status if the field is cleared
                _isFieldSelectedFromDropdown[fieldKey] = false; // NEW
                return const Iterable.empty();
            }
            return _allControlData.where((option) {
                final fieldValue = option[fieldKey]?.toString().toLowerCase() ?? '';
                return fieldValue.contains(textEditingValue.text.toLowerCase());
            });
        },
        onSelected: (selection) {
          _populateAllFields(selection);
          FocusScope.of(context).unfocus();
          setState(() {
            // NOVO: Quando uma opção é selecionada em QUALQUER campo de busca,
            // consideramos que TODO o registro foi carregado e os campos de busca
            // devem ser tratados como "selecionados" para evitar a validação de duplicidade.
            _isFieldSelectedFromDropdown['campoComum1'] = true;
            _isFieldSelectedFromDropdown['campoComum2'] = true;
            _isFieldSelectedFromDropdown['campoComum3'] = true;

            // Resetar flags de alterações para um estado "limpo" após carregar um registro.
            _hasUnsavedChanges = false;
            _hasSubcollectionInputChanges = false;
          });
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
                validator: (value) {
                    // Combine existing validator with new duplicate check
                    final existingValidationError = validator?.call(value);
                    if (existingValidationError != null) {
                        return existingValidationError;
                    }

                    // NEW VALIDATION LOGIC
                    if (value != null && value.isNotEmpty) {
                        final lowerCaseValue = value.toLowerCase();
                        final isDuplicate = _allControlData.any((option) =>
                            (option[fieldKey]?.toString().toLowerCase() == lowerCaseValue));

                        final isSelected = _isFieldSelectedFromDropdown[fieldKey] ?? false;

                        if (isDuplicate && !isSelected) {
                            // Clear the selection status if user types over an existing value
                            // without selecting from dropdown again.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                    _isFieldSelectedFromDropdown[fieldKey] = false;
                                });
                            });
                            return 'Este registro já existe. Selecione do dropdown ou mude o valor.';
                        }
                    }
                    return null; // No validation error
                },
                inputFormatters: inputFormatters,
                maxLength: maxLength,
                onUserInteraction: onUserInteraction,
                onChanged: (value) {
                  controller.text = value;
                  // REMOVIDO: A lógica abaixo, pois queremos que _isFieldSelectedFromDropdown seja true
                  // apenas se houver uma seleção explícita, e false caso contrário (se o usuário digitar).
                  /*
                  if (_isFieldSelectedFromDropdown[fieldKey] == true) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _isFieldSelectedFromDropdown[fieldKey] = false; // Remova esta linha
                      });
                    });
                  }
                  */
                  // ADICIONADO: Se o usuário digita, a "seleção" se perde, então marque como false.
                  // Isso é crucial para que a validação dispare se o valor digitado corresponder a um existente
                  // E o usuário não selecionar do dropdown.
                  setState(() {
                      _isFieldSelectedFromDropdown[fieldKey] = false;
                  });

                  _formKey.currentState?.validate(); // Force validation check
                },
            );
        },
    );
  }

  Widget _buildAbaDadosGerais({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
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
                        Expanded(
                          flex: 1,
                          child: _buildAutocompleteField(
                              _campoComum1Controller,
                              "CPF/CNPJ",
                              'campoComum1',
                              isRequired: true,
                              validator: _cpfCnpjValidator, // Use the unified validator
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfCnpjFormatter()], // Use the unified formatter
                              maxLength: 18, 
                              onUserInteraction: () => _setUnsavedChanges(true),
                          )),
                                
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'campoComum3')),
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
              Row(children: [
                Expanded(
                    flex: 1,
                    child:
                        CustomInputField(controller: _codigoGeradoController, label: "Código Gerado", readOnly: true,)),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: CustomInputField(
                    controller: _dataInclusaoController,
                    label: "Data Inclusão",
                    readOnly: true,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _generateNewCodigo,
                  child: Text("Gerar"),
                ),
              ]),
              const SizedBox(height: 20), 
              Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      flex: 1,
                      child: CustomInputField(
                          controller: _cepController,
                          label: "CEP",
                          suffixText: '${_cepController.text.length}/9',
                  maxLength: 9,
                  // NOVO: readOnly baseado no checkbox
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CepInputFormatter(),
                  ],
                  validator: (value) {
                    if (_possuiEndCobran) { // Só valida se o checkbox estiver marcado
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value) || value.length != 9) {
                        return 'Formato de CEP inválido (#####-###)';
                      }
                    }
                    return null;
                  },
                          onUserInteraction: () => _setUnsavedChanges(true), 
                          )),
                          
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                          controller: _enderecoController,
                          label: "Endereço",
                          maxLength: 45,
                          suffixText: '${_enderecoController.text.length}/45',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true), )),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 1,
                      child: CustomInputField(
                          controller: _numeroController,
                          label: "Número",
                          inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                          maxLength: 5,
                           suffixText: '${_numeroController.text.length}/5',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 1,
                      child: CustomInputField(
                          controller: _complementoController,
                          label: "Complemento",
                          suffixText: '${_numeroController.text.length}/20',
                          maxLength: 20,
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
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
                          suffixText: '${_bairroController.text.length}/25',
                          maxLength: 25,
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 3,
                      child: _buildCidadeAutocompleteGeral(
                    onUserInteraction: () => _setUnsavedChanges(true),
                  ),),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 1,
                      child: CustomInputField(
                          controller: _ufController,
                          suffixText: '${_ufController.text.length}/2',
                          maxLength: 2,
                          label: "UF",
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 1,
                      child: CustomInputField(
                          controller: _cxPostalController,
                          suffixText: '${_cxPostalController.text.length}/6',
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          label: "Cx. Postal",
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                ],
              ),
              const SizedBox(height: 20), 
              Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      flex: 2,
                      child: CustomInputField(
                          controller: _comoNosConheceuController,
                          label: "Como nos conheceu",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 5,
                          suffixText: '${_comoNosConheceuController.text.length}/5',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 1,
                      child: CustomInputField(
                          controller: _portadorController,
                          label: "Portador",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          suffixText: '${_portadorController.text.length}/3',
                          maxLength: 3,
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 2,
                      child: CustomInputField(
                          controller: _tabDescontoController,
                          label: "Tab Desconto",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 5,
                          suffixText: '${_tabDescontoController.text.length}/5',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
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
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 16,
                          suffixText: '${_inscSuframaController.text.length}/16',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                          controller: _inscProdutorController,
                          label: "Inscr. Produtor.",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 16,
                          suffixText: '${_inscProdutorController.text.length}/16',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                          controller: _inscMunicipalController,
                          label: "Inscr. Municipal",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 16,
                          suffixText: '${_inscMunicipalController.text.length}/16',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                ],
              ),
              const SizedBox(height: 20), 
              Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                          controller: _vendedorController,
                          label: "Vendedor",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 5,
                          suffixText: '${_vendedorController.text.length}/5',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                          controller: _atendenteController,
                          label: "Atendente",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 5,
                          suffixText: '${_atendenteController.text.length}/5',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                          controller: _areaController,
                          label: "Área",
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 5,
                          suffixText: '${_areaController.text.length}/5',
                          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,onUserInteraction: () => _setUnsavedChanges(true),)),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 3,
                      child: _buildSituacaoAutocomplete(
                    onUserInteraction: () => _setUnsavedChanges(true),
                  ),),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modificado para aceitar maxLengh e inputFormatters
  DataCell _buildEditableCell(
    String subcollection, DocumentSnapshot doc, String field, String initialValue,
    {int? maxLength, List<TextInputFormatter>? inputFormatters}) {
  final docId = doc.id;
  final parentItemId = _campoComum1Controller.text.trim();
  final isEditing =
      _editingCell != null && _editingCell!['docId'] == docId && _editingCell!['field'] == field;

  return DataCell(
    isEditing
        ? TextField(
            controller: _cellEditController,
            focusNode: _cellFocusNode,
            autofocus: true,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onSubmitted: (newValue) {
              _updateSubcollectionField(subcollection, parentItemId, docId, field, newValue);
              setState(() {
                _editingCell = null;
              });
            },
            onTapOutside: (_) {
              _updateSubcollectionField(subcollection, parentItemId, docId, field, _cellEditController.text);
              if (mounted) {
                setState(() {
                  _editingCell = null;
                });
              }
            },
          )
        : SizedBox(
            // Manter SizedBox com largura fixa aqui
            width: _getColumnWidth(field),
            child: Text(initialValue, overflow: TextOverflow.ellipsis)), // Adicionado overflow: TextOverflow.ellipsis
    onTap: () {
      setState(() {
        _editingCell = {'docId': docId, 'field': field};
        _cellEditController.text = initialValue;
        _cellFocusNode.requestFocus();
      });
    },
  );
}

  // Função auxiliar para definir larguras de coluna
  double _getColumnWidth(String field) {
  switch (field) {
    case 'sq':
      return 25.0;
    case 'pais':
      return 40.0; // Aumentado um pouco
    case 'ddd':
      return 40.0;
    case 'nro':
      return 40.0;
    case 'operadora':
      return 40.0;
    case 'ramal':
      return 40.0;
    case 'tipo':
      return 40.0;
    case 'contato':
      return 40.0;
    case 'socio':
      return 50.0;
    case 'nome':
      return 50.0;
    case 'cpf':
      return 50.0; // Considerando a formatação
    case 'cargo':
      return 50.0;
    case 'cargo res':
      return 50.0; // Aumentado para nomes de cargo mais longos
    case 'participacao':
      return 50.0;
    case 'sequencia ref banc':
      return 25.0;
    case 'nome ref banc':
      return 40.0;
    case 'endereco ref banc':
      return 40.0;
    case 'resul endereco ref banc':
      return 40.0;
    case 'contato ref banc':
      return 40.0;
    case 'telefone ref banc':
      return 40.0;
    case 'email ref banc':
      return 40.0;
    case 'obs ref banc':
      return 40.0;
    case 'sequencia ref comercial':
      return 25.0;
    case 'nome ref comercial':
      return 40.0;
    case 'resul nome ref comercial': // Campo "..." na aba comercial
      return 40.0;
    case 'endereco ref comercial':
      return 40.0;
    case 'cidade ref comercial':
      return 40.0;
    case 'contato ref comercial':
      return 40.0;
    case 'telefone ref comercial':
      return 40.0;
    case 'email ref comercial':
      return 40.0;
    case 'obs ref comercial':
      return 40.0;
    case 'sequencia contato':
      return 30.0;
    case 'nome contato':
      return 50.0;
    case 'data nasc contato':
      return 50.0;
    case 'cargo contato':
      return 50.0;
    case 'cargo res contato':
      return 50.0;
    case 'email contato':
      return 50.0;
    case 'obs contato':
      return 50.0;
    default:
      return 50.0; // Largura padrão
  }
}
  Widget _buildAbaTelefone({Key? key}) {
    return Form(
      child: Padding(
        key: key,
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
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
                          Expanded(
                              flex: 1,
                              child: _buildAutocompleteField(
                                  _campoComum1Controller, "CPF/CNPJ", 'campoComum1',
                                  isRequired: true)),
                          const SizedBox(width: 10),
                          Expanded(
                              flex: 2,
                              child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                          const SizedBox(width: 10),
                          Expanded(
                              flex: 3,
                              child: _buildAutocompleteField(
                                  _campoComum3Controller, "Razao Social", 'campoComum3')),
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
                const SizedBox(height: 20), 
                Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        flex: 1,
                        child: CustomInputField(
                            controller: _sqController,
                            label: "SQ",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 1,
                          suffixText: '${_sqController.text.length}/1',
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 3,
                        child: CustomInputField(
                            controller: _paisController,
                            label: "País",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 2,
                          suffixText: '${_paisController.text.length}/2',
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 1,
                        child: CustomInputField(
                            controller: _operadoraController,
                            label: "Operadora",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 2,
                          suffixText: '${_operadoraController.text.length}/2',
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 1,
                        child: CustomInputField(
                            controller: _dddController,
                            label: "DDD",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 3,
                          suffixText: '${_dddController.text.length}/3',
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
                            label: "Nro",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 12,
                          suffixText: '${_nroController.text.length}/12',
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 3,
                        child: CustomInputField(
                            controller: _ramalController,
                            label: "Ramal",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 4,
                          suffixText: '${_ramalController.text.length}/4',
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 1,
                        child: CustomInputField(
                            controller: _tipoController,
                            label: "Tipo",onUserInteraction: () => _checkSubcollectionInputChanges(),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 1,
                          suffixText: '${_tipoController.text.length}/1', 
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 1,
                        child: CustomInputField(
                            controller: _contatoController,
                            label: "Contato",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 15,
                          suffixText: '${_contatoController.text.length}/15',
                            validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),onPressed: _addTelefone, child: const Text("Adicionar Telefone")),
                
                Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
                StreamBuilder<QuerySnapshot>(
                  stream: _telefonesStream,
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
                
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      
                      child: Align(alignment: Alignment.center,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all<Color>(Colors.blue[200]!), // Cor do cabeçalho
                          dataRowColor: WidgetStateProperty.all<Color>(Colors.white),       // Cor do corpo da tabela
                          // --- FIM DAS MODIFICAÇÕES ---
                          border: TableBorder(
                            top: BorderSide(color: Colors.black),
                            right: BorderSide(color: Colors.black),
                            left: BorderSide(color: Colors.black),
                            bottom: BorderSide(color: Colors.black),
                            horizontalInside: BorderSide(color: Colors.blue)),
                          columns: [
                            DataColumn(label: SizedBox(width: _getColumnWidth('sq'), child: Text('SQ', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: SizedBox(width: _getColumnWidth('pais'), child: Text('País', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: SizedBox(width: _getColumnWidth('operadora'), child: Text('Operadora', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: SizedBox(width: _getColumnWidth('ddd'), child: Text('DDD', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: SizedBox(width: _getColumnWidth('nro'), child: Text('Número', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: SizedBox(width: _getColumnWidth('ramal'), child: Text('Ramal', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: SizedBox(width: _getColumnWidth('tipo'), child: Text('Tipo', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: SizedBox(width: _getColumnWidth('contato'), child: Text('Contato', overflow: TextOverflow.ellipsis,))),
                            DataColumn(label: Text('Ação')),
                          ],
                          rows: telefones.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DataRow(cells: [
                              _buildEditableCell('telefones', doc, 'sq', data['sq'] ?? '',
                                  maxLength: 2, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                              _buildEditableCell('telefones', doc, 'pais', data['pais'] ?? '', maxLength: 30),
                              _buildEditableCell('telefones', doc, 'operadora', data['operadora'] ?? '', maxLength: 30),
                              _buildEditableCell('telefones', doc, 'ddd', data['ddd'] ?? '',
                                  maxLength: 3, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                              _buildEditableCell('telefones', doc, 'nro', data['nro'] ?? '',
                                  maxLength: 10, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                              _buildEditableCell('telefones', doc, 'ramal', data['ramal'] ?? '',
                                  maxLength: 10, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                              _buildEditableCell('telefones', doc, 'tipo', data['tipo'] ?? '',
                                  maxLength: 30),
                              _buildEditableCell('telefones', doc, 'contato', data['contato'] ?? '',
                                  maxLength: 30),
                              DataCell(IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteTelefone(_campoComum1Controller.text.trim(), doc.id),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
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
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
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
                        Expanded(
                            flex: 1,
                            child: _buildAutocompleteField(
                                _campoComum1Controller, "CPF/CNPJ", 'campoComum1',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'campoComum3')),
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
              const SizedBox(height: 20), 
              Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                          controller: _cnpjController,
                          maxLength: 18,
                          suffixText: '${_cnpjController.text.length}/18',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            CnpjInputFormatter(), // Adiciona pontos, barra e hífen automaticamente
                          ],
                          label: "CNPJ",
                          validator: _cnpjValidator,onUserInteraction: () => _setUnsavedChanges(true),)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _inscEstadualController,
                        label: "Insc. Estadual",
                        suffixText: '${_inscEstadualController.text.length}/16',
                        maxLength: 16,onUserInteraction: () => _setUnsavedChanges(true),
                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
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
              SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  Expanded(
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
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
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
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
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
                        Expanded(
                            flex: 1,
                            child: _buildAutocompleteField(
                                _campoComum1Controller, "CPF/CNPJ", 'campoComum1',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'campoComum3')),
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
              const SizedBox(height: 20), 
              Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _confidencialController,
                        label: "Confidencial",
                        maxLength: 60,
                        suffixText: '${_confidencialController.text.length}/60',onUserInteraction: () => _setUnsavedChanges(true),

                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _observacaoController,
                        label: "Observação",
                        maxLength: 60,
                        suffixText: '${_observacaoController.text.length}/60',onUserInteraction: () => _setUnsavedChanges(true),
                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _observacaoNfController,
                        label: "ObservacaoNf",
                        maxLength: 180,
                        suffixText: '${_observacaoNfController.text.length}/180',onUserInteraction: () => _setUnsavedChanges(true),
                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _eMailController,
                        label: "E-mail",
                        maxLength: 60,
                        suffixText: '${_eMailController.text.length}/60',onUserInteraction: () => _setUnsavedChanges(true),
                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _eMailCobranController,
                        label: "E-mail Cobran",
                        maxLength: 60,
                        suffixText: '${_eMailCobranController.text.length}/60',onUserInteraction: () => _setUnsavedChanges(true),
                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _eMailNfController,
                        label: "E-mail Nf-e",
                        maxLength: 180,
                        suffixText: '${_eMailNfController.text.length}/180',onUserInteraction: () => _setUnsavedChanges(true),
                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _siteController,
                        label: "Site",
                        maxLength: 60,
                        suffixText: '${_siteController.text.length}/60',onUserInteraction: () => _setUnsavedChanges(true),
                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                    label: "SQ",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    suffixText: '${_sqController.text.length}/1',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 3,
                child: CustomInputField(
                    controller: _socioController,
                    maxLength: 5,
                    label: "Sócio",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    suffixText: '${_socioController.text.length}/5',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _nomeController,
                    label: "Nome",onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
                    maxLength: 14,
                    label: "CPF",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()], // Remova o CpfCnpjFormatter se estiver aqui
                    suffixText: '${_cpfController.text.length}/14',
                    validator: _cpfValidator)),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: _buildCargoAutocomplete2(onUserInteraction: () => _checkSubcollectionInputChanges())),
            const SizedBox(width: 10),
            Expanded(
                flex: 3,
                child: CustomInputField(
                    controller: _resulCargoController,
                    //suffixText: '${_participacaoController.text.length}/60',
                    label: "...",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    readOnly: true,
                    //maxLength: 35,
                    //suffixText: '${_participacaoController.text.length}/35',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _participacaoController,
                    suffixText: '${_participacaoController.text.length}/5',
                    label: "Particpação",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    inputFormatters: [PercentageInputFormatter()],
                    maxLength: 5,
                    //suffixText: '${_participacaoController.text.length}/35',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
          onPressed: _addSocio, child: const Text("Adicionar Composição Acionária")),
        Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),

        // Tabela de dados
        StreamBuilder<QuerySnapshot>(
          stream: _sociosStream,
          /*stream: _campoComum1Controller.text.trim().isNotEmpty
                 ? _collectionRef.doc(_campoComum1Controller.text.trim()).collection('composicao_acionaria').snapshots()
                 : null,*/
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

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                              headingRowColor: WidgetStateProperty.all<Color>(Colors.blue[200]!), // Cor do cabeçalho
                              dataRowColor: WidgetStateProperty.all<Color>(Colors.white),       // Cor do corpo da tabela
                              // --- FIM DAS MODIFICAÇÕES ---
                              border: TableBorder(
                                top: BorderSide(color: Colors.black),
                                right: BorderSide(color: Colors.black),
                                left: BorderSide(color: Colors.black),
                                bottom: BorderSide(color: Colors.black),
                                horizontalInside: BorderSide(color: Colors.blue)),
                              columns: [
                  DataColumn(label: SizedBox(width: _getColumnWidth('sq'), child: Text('Sq'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('socio'), child: Text('Sócio'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('nome'), child: Text('Nome'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('cpf'), child: Text('CPF'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('cargo'), child: Text('Cargo'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('cargo res'), child: Text('Cargo res'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('participacao'), child: Text('participacao'))),
                  DataColumn(label: Text('Ação')),
                ],
                /*rows: socios.map((socioDoc) {
                    final socioData = socioDoc.data() as Map<String, dynamic>;*/
                rows: socios.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    _buildEditableCell('composicao_acionaria', doc, 'sq', data['sq'] ?? '',
                        maxLength: 1, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell('composicao_acionaria', doc, 'socio', data['socio'] ?? '',
                        maxLength: 5),
                    _buildEditableCell('composicao_acionaria', doc, 'nome', data['nome'] ?? '',
                        maxLength: 60),
                    _buildEditableCell('composicao_acionaria', doc, 'cpf', data['cpf'] ?? '',
                        maxLength: 14, inputFormatters: [CpfInputFormatter()]), // Usar CpfInputFormatter
                    _buildEditableCell('composicao_acionaria', doc, 'cargo', data['cargo'] ?? '',
                        maxLength: 5, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell('composicao_acionaria', doc, 'cargo res', data['cargo res'] ?? '',
                        maxLength: 35),
                    _buildEditableCell(
                        'composicao_acionaria', doc, 'participacao', data['participacao'] ?? '',
                        maxLength: 5, inputFormatters: [PercentageInputFormatter()]),
                    /*DataCell(Text(socioData['sq'] ?? '')),
                          DataCell(Text(socioData['socio'] ?? '')),
                          DataCell(Text(socioData['nome'] ?? '')),
                          DataCell(Text(socioData['cpf'] ?? '')),
                          DataCell(Text(socioData['cargo'] ?? '')),
                          DataCell(Text(socioData['cargo res'] ?? '')),
                          DataCell(Text(socioData['participacao'] ?? '')),*/
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteSocio(_campoComum1Controller.text.trim(), doc.id),
                    )),
                  ]);
                }).toList(),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildAbaContainer({Key? key, required Color color, required String title, required List<Widget> children}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
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
              // Adiciona os campos de busca e o botão de limpar no topo de cada aba
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: _buildAutocompleteField(
                                _campoComum1Controller, "CPF/CNPJ", 'campoComum1',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'campoComum3')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Limpar Busca',
                    onPressed: _clearSearchFields,
                  ),
                ],
              ),
              const SizedBox(height: 20), // Espaçamento entre os campos de busca e o título da aba
              Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // MODIFICAR MÉTODO: _buildInputField (para ler o estado de readOnly)
  // Certifique-se que o CustomInputField suporte a propriedade readOnly.
  // Assumi que já suporta, mas adicionei a lógica para desabilitar base nos checkboxes.
  /*Widget _buildInputField(TextEditingController controller, String label, int maxLength,
    {String? Function(String?)? validator,
    bool isNumeric = false,
    bool isRequired = false,
    bool readOnly = false,
    bool forceReadOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isMainFormInput = false, // NOVO: Flag para identificar campos que disparam _hasUnsavedChanges
    bool isSubcollectionInput = false, // NOVO: Flag para identificar campos que disparam _hasSubcollectionInputChanges
    }) {
  return CustomInputField(
    controller: controller,
    label: label,
    maxLength: maxLength,
    validator: validator ?? (isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null),
    keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
    suffixText: '${controller.text.length}/$maxLength',
    inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
    readOnly: readOnly || forceReadOnly,
    fillColor: (readOnly || forceReadOnly) ? Colors.grey[300] : Colors.white,
    textCapitalization: textCapitalization,
    onChanged: (value) {
      // Dispara _hasUnsavedChanges para campos principais
      if (isMainFormInput && !readOnly && !forceReadOnly) {
        _setUnsavedChanges(true);
      }
      // Dispara _hasSubcollectionInputChanges para campos de subcoleção
      if (isSubcollectionInput) {
        // Redundante se o listener já estiver no initState, mas garante
        _checkSubcollectionInputChanges();
      }
    },
  );
}*/

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
    final bool isResulNomeEditable = _nomeRefBancariaController.text == '0';
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
                    label: "Sequencia",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    maxLength: 1,
                    suffixText: '${_sequenciaController.text.length}/1',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _nomeRefBancariaController,
                inputFormatters: [DigitsOnlyInputFormatter()], // Permite apenas dígitos
                maxLength: 5,
                suffixText: '${_nomeRefBancariaController.text.length}/5',
                label: "nome",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: CustomInputField(
                controller: _resulNomeController,
                readOnly: !isResulNomeEditable, // Campo "..." editável APENAS se _nomeRefBancariaController.text for '0'
                label: "...",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                validator: (v) => isResulNomeEditable && v!.isEmpty ? 'Campo obrigatório' : null, // Valida apenas se for editável
                fillColor: isResulNomeEditable ? Colors.white : Colors.grey[300], // Cor de fundo para indicar editabilidade
              ),
            ),
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
                    label: "Endereço",onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
            Expanded(flex: 1, child: _buildCidadeAutocomplete(onUserInteraction: () => _checkSubcollectionInputChanges())),
            const SizedBox(width: 10),
            Expanded(
                flex: 5,
                child: CustomInputField(
                    controller: _resulEnderecoController,
                    //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                    //maxLength: 5,
                    readOnly: true,
                    label: "...",onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
                    label: "Contato",onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
                    label: 'Telefone',onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
                    label: "e-mail",onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
                    label: 'Obs',onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    suffixText: '${_obsRefBancariaController.text.length}/40',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
          onPressed: _addReferenciaBancaria, child: const Text("Adicionar Referencia Bancária")),
        Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),

        // Tabela de dados
        StreamBuilder<QuerySnapshot>(
          stream: _referenciasStream,
          /*stream: _campoComum1Controller.text.trim().isNotEmpty
                 ? _collectionRef.doc(_campoComum1Controller.text.trim()).collection('referencias_bancarias').snapshots()
                 : null,*/
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

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all<Color>(Colors.blue[200]!), // Cor do cabeçalho
                dataRowColor: WidgetStateProperty.all<Color>(Colors.white),       // Cor do corpo da tabela
                // --- FIM DAS MODIFICAÇÕES ---
                border: TableBorder(
                  top: BorderSide(color: Colors.black),
                  right: BorderSide(color: Colors.black),
                  left: BorderSide(color: Colors.black),
                  bottom: BorderSide(color: Colors.black),
                  horizontalInside: BorderSide(color: Colors.blue)),
                columns: [
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('sequencia ref banc'), child: Text('Seq.'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('nome ref banc'), child: Text('Nome'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('endereco ref banc'), child: Text('Endereço.'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('resul endereco ref banc'), child: Text('Cidade'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('contato ref banc'), child: Text('Contato'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('telefone ref banc'), child: Text('Telefone'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('email ref banc'), child: Text('E-mail'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('obs ref banc'), child: Text('Obs.'))),
                  DataColumn(label: Text('Ação')),
                ],
                rows: referencias.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    _buildEditableCell('referencias_bancarias', doc, 'sequencia ref banc',
                        data['sequencia ref banc'] ?? '',
                        maxLength: 2, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell(
                        'referencias_bancarias', doc, 'nome ref banc', data['nome ref banc'] ?? '',
                        maxLength: 60),
                    _buildEditableCell('referencias_bancarias', doc, 'endereco ref banc',
                        data['endereco ref banc'] ?? '',
                        maxLength: 45),
                    _buildEditableCell('referencias_bancarias', doc, 'resul endereco ref banc',
                        data['resul endereco ref banc'] ?? '',
                        maxLength: 5, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell('referencias_bancarias', doc, 'contato ref banc',
                        data['contato ref banc'] ?? '',
                        maxLength: 20),
                    _buildEditableCell('referencias_bancarias', doc, 'telefone ref banc',
                        data['telefone ref banc'] ?? '',
                        maxLength: 20),
                    _buildEditableCell('referencias_bancarias', doc, 'email ref banc',
                        data['email ref banc'] ?? '',
                        maxLength: 40),
                    _buildEditableCell(
                        'referencias_bancarias', doc, 'obs ref banc', data['obs ref banc'] ?? '',
                        maxLength: 40),
                    /*DataCell(Text(data['sequencia ref banc'] ?? '')), DataCell(Text(data['nome ref banc'] ?? '')),
                          DataCell(Text(data['endereco ref banc'] ?? '')), DataCell(Text(data['cidade ref banc'] ?? '')),
                          DataCell(Text(data['contato ref banc'] ?? '')), DataCell(Text(data['telefone ref banc'] ?? '')),
                          DataCell(Text(data['email ref banc'] ?? '')), DataCell(Text(data['obs ref banc'] ?? '')),*/
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReferenciaBancaria(
                          _campoComum1Controller.text.trim(), doc.id),
                    )),
                  ]);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // NOVO MÉTODO: _buildAbaReferenciaComercial
Widget _buildAbaReferenciaComercial({Key? key}) {
    final bool isResulNomeRefComercialEditable = _nomeRefComercialController.text == '0';

    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Referência Comercial",
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _sequenciaRefComercialController,
                label: "Sequencia",
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                maxLength: 1,
                suffixText: '${_sequenciaRefComercialController.text.length}/1',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _nomeRefComercialController,
                inputFormatters: [DigitsOnlyInputFormatter()],
                maxLength: 5,
                suffixText: '${_nomeRefComercialController.text.length}/5',
                label: "nome",
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: CustomInputField(
                controller: _resulNomeRefComercialController,
                readOnly: !isResulNomeRefComercialEditable,
                label: "...",
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                validator: (v) => isResulNomeRefComercialEditable && v!.isEmpty ? 'Campo obrigatório' : null,
                fillColor: isResulNomeRefComercialEditable ? Colors.white : Colors.grey[300],
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _enderecoRefComercialController,
                label: "Endereço",
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                suffixText: '${_enderecoRefComercialController.text.length}/45',
                maxLength: 45,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 1, child: _buildCidadeAutocompleteRefComercial(onUserInteraction: () => _checkSubcollectionInputChanges())),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: CustomInputField(
                controller: _resulcidadeRefComercialController,
                readOnly: true,
                label: "...",
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _contatoRefComercialController,
                label: "Contato",
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                suffixText: '${_contatoRefComercialController.text.length}/20',
                maxLength: 20,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _telefoneRefComercialController,
                maxLength: 20,
                suffixText: '${_telefoneRefComercialController.text.length}/20',
                label: 'Telefone',
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _emailRefComercialController,
                label: "e-mail",
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                suffixText: '${_emailRefComercialController.text.length}/40',
                maxLength: 40,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: CustomInputField(
                controller: _obsRefComercialController,
                maxLength: 40,
                label: 'Obs',
                onUserInteraction: () => _checkSubcollectionInputChanges(),
                suffixText: '${_obsRefComercialController.text.length}/40',
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _addReferenciaComercial,
          child: const Text("Adicionar Referência Comercial"),
        ),
        Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),

        StreamBuilder<QuerySnapshot>(
          stream: _referenciasComerciaisStream,
          builder: (context, snapshot) {
            if (_campoComum1Controller.text.trim().isEmpty) {
              return const Center(child: Text("Busque por um CPF/CNPJ para ver as referências comerciais."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Nenhuma referência comercial cadastrada."));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erro: ${snapshot.error}"));
            }

            final referencias = snapshot.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all<Color>(Colors.blue[200]!),
                dataRowColor: WidgetStateProperty.all<Color>(Colors.white),
                border: const TableBorder(
                    top: BorderSide(color: Colors.black),
                    right: BorderSide(color: Colors.black),
                    left: BorderSide(color: Colors.black),
                    bottom: BorderSide(color: Colors.black),
                    horizontalInside: BorderSide(color: Colors.blue)),
                columns: [
                  DataColumn(label: SizedBox(width: _getColumnWidth('sequencia ref comercial'), child: Text('Seq.'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('resul nome ref comercial'), child: Text('Nome'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('endereco ref comercial'), child: Text('Endereço.'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('cidade ref comercial'), child: Text('Cidade'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('contato ref comercial'), child: Text('Contato'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('telefone ref comercial'), child: Text('Telefone'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('email ref comercial'), child: Text('E-mail'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('obs ref comercial'), child: Text('Obs.'))),
                  const DataColumn(label: Text('Ação')),
                ],
                rows: referencias.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    _buildEditableCell('referencias_comerciais', doc, 'sequencia ref comercial', data['sequencia ref comercial'] ?? '',
                        maxLength: 2, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell('referencias_comerciais', doc, 'resul nome ref comercial', data['resul nome ref comercial'] ?? '',
                        maxLength: 60),
                    _buildEditableCell('referencias_comerciais', doc, 'endereco ref comercial', data['endereco ref comercial'] ?? '',
                        maxLength: 45),
                    _buildEditableCell('referencias_comerciais', doc, 'cidade ref comercial', data['cidade ref comercial'] ?? '',
                        maxLength: 5, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell('referencias_comerciais', doc, 'contato ref comercial', data['contato ref comercial'] ?? '',
                        maxLength: 20),
                    _buildEditableCell('referencias_comerciais', doc, 'telefone ref comercial', data['telefone ref comercial'] ?? '',
                        maxLength: 20),
                    _buildEditableCell('referencias_comerciais', doc, 'email ref comercial', data['email ref comercial'] ?? '',
                        maxLength: 40),
                    _buildEditableCell('referencias_comerciais', doc, 'obs ref comercial', data['obs ref comercial'] ?? '',
                        maxLength: 40),
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReferenciaComercial(_campoComum1Controller.text.trim(), doc.id),
                    )),
                  ]);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCidadeAutocompleteGeral({VoidCallback? onUserInteraction}) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['cidade'] as String, // EXIBE O NOME DA CIDADE
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
        _populateCidadeGeralFields(selection); // Usa o novo método de população
        FocusScope.of(context).unfocus();
        _setUnsavedChanges(true); // Indica que houve interação e alteração
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        // Garante que o controller do campo Autocomplete reflita o estado do _cidadeController
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeController.text != fieldController.text) {
            // Verifica se a cidade no controller principal corresponde a um nome de cidade no allCidades
            // Se sim, preenche com o nome completo, caso contrário, usa o ID ou o que estiver no controller
            final matchedCity = _allCidades.firstWhereOrNull(
                (element) => element['id'] == _cidadeController.text);
            fieldController.text = matchedCity != null ? matchedCity['cidade'] : _cidadeController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Cidade",
          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
          onUserInteraction: onUserInteraction, // Passa o listener de interação
          onChanged: (value) {
            // Ao digitar, atualiza o controller principal (id)
            // E tenta encontrar uma cidade exata para preencher o nome completo
            final exactMatch = _allCidades.firstWhereOrNull(
                (item) => (item['cidade'] as String?)?.toLowerCase() == value.toLowerCase());

            if (exactMatch != null) {
              _cidadeController.text = exactMatch['id'] ?? ''; // Salva o ID no controller principal
            } else {
              _cidadeController.text = value; // Se não houver match exato, salva o que foi digitado
            }
            _setUnsavedChanges(true); // Indica que houve interação e alteração
          },
        );
      },
    );
  }

  Widget _buildSituacaoAutocomplete({VoidCallback? onUserInteraction}) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['descricao'] as String, // EXIBE A DESCRIÇÃO DA SITUAÇÃO
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allSituacoes.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final descricao = option['descricao']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || descricao.contains(input);
        });
      },
      onSelected: (selection) {
        _populateSituacaoFields(selection);
        FocusScope.of(context).unfocus();
        _setUnsavedChanges(true); // Indica que houve interação e alteração
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        // Garante que o controller do campo Autocomplete reflita o estado do _situacaoController
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_situacaoController.text != fieldController.text) {
            final matchedSituacao = _allSituacoes.firstWhereOrNull(
                (element) => element['id'] == _situacaoController.text);
            fieldController.text = matchedSituacao != null ? matchedSituacao['descricao'] : _situacaoController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: "Situação",
          validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
          onUserInteraction: onUserInteraction, // Passa o listener de interação
          onChanged: (value) {
            // Ao digitar, atualiza o controller principal (id)
            final exactMatch = _allSituacoes.firstWhereOrNull(
                (item) => (item['descricao'] as String?)?.toLowerCase() == value.toLowerCase());

            if (exactMatch != null) {
              _situacaoController.text = exactMatch['id'] ?? ''; // Salva o ID no controller principal
            } else {
              _situacaoController.text = value; // Se não houver match exato, salva o que foi digitado
            }
            _setUnsavedChanges(true); // Indica que houve interação e alteração
          },
        );
      },
    );
  }

  Widget _buildCidadeAutocomplete({bool readOnly = false,VoidCallback? onUserInteraction}) { 
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (readOnly || textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeFields(selection);
        _checkSubcollectionInputChanges(); // Adicionado para detectar mudanças na subcoleção
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeRefBancariaController.text != fieldController.text) {
            fieldController.text = _cidadeRefBancariaController.text;
          }
        });
        return CustomInputField(
          maxLength: 5,
          suffixText: '${_cidadeRefBancariaController.text.length}/5',
          controller: fieldController,
          focusNode: focusNode,
          label: "Cidade",
          readOnly: readOnly,
          onUserInteraction: onUserInteraction,
          onChanged: (value) {
            _cidadeRefBancariaController.text = value;
            _checkSubcollectionInputChanges(); // Adicionado para detectar mudanças na subcoleção
            final exactMatches = _allCidades
                .where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase())
                .toList();
            if (exactMatches.length == 1) {
              _populateCidadeFields(exactMatches.first);
            }
          },
        );
      },
    );
  }

  // NOVO MÉTODO: _buildCidadeAutocompleteRefComercial (cópia de _buildCidadeAutocomplete)
Widget _buildCidadeAutocompleteRefComercial({VoidCallback? onUserInteraction}) {
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
        _populateCidadeRefComercialFields(selection); // NOVO método de população
        _checkSubcollectionInputChanges(); // Adicionado para detectar mudanças na subcoleção
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeRefComercialController.text != fieldController.text) {
            fieldController.text = _cidadeRefComercialController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          maxLength: 5,
          suffixText: '${_cidadeRefComercialController.text.length}/5',
          focusNode: focusNode,
          label: "Cidade",
          onUserInteraction: onUserInteraction,
          onChanged: (value) {
            _cidadeRefComercialController.text = value;
            _checkSubcollectionInputChanges(); // Adicionado para detectar mudanças na subcoleção
            final exactMatches = _allCidades
                .where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase())
                .toList();
            if (exactMatches.length == 1) {
              _populateCidadeRefComercialFields(exactMatches.first);
            }
          },
        );
      },
    );
  }

// NOVO MÉTODO: _populateCidadeRefComercialFields
void _populateCidadeRefComercialFields(Map<String, dynamic> cidadeData) {
    setState(() {
      _cidadeRefComercialController.text = cidadeData['id'] ?? '';
      _resulcidadeRefComercialController.text = cidadeData['cidade'] ?? ''; // Pode ser o nome da cidade aqui
    });
  }

  // MODIFICAR MÉTODO: _buildCidadeAutocompleteEnderecoCobranca (Adicionar readOnly)
  Widget _buildCidadeAutocompleteEnderecoCobranca({bool readOnly = false,VoidCallback? onUserInteraction}) { // Adicionar readOnly aqui
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (readOnly || textEditingValue.text.isEmpty) return const Iterable.empty(); // Se readOnly, não oferece sugestões
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeCobranFields(selection);
        _setUnsavedChanges(true); // Marcar como alterado
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeCobrancaController.text != fieldController.text) {
            fieldController.text = _cidadeCobrancaController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          maxLength: 5,
          suffixText: '${_cidadeCobrancaController.text.length}/5',
          focusNode: focusNode,
          label: "Cidade",
          readOnly: readOnly, // Passar o readOnly para o CustomInputField
          fillColor: readOnly ? Colors.grey[300] : Colors.white,
          onUserInteraction: onUserInteraction,
          onChanged: (value) {
            _cidadeCobrancaController.text = value;
            _setUnsavedChanges(true); // Marcar como alterado
            final exactMatches = _allCidades
                .where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase())
                .toList();
            if (exactMatches.length == 1) {
              _populateCidadeCobranFields(exactMatches.first);
            }
          },
        );
      },
    );
  }

  // MODIFICAR MÉTODO: _buildCidadeAutocompleteCorrespondencia (Adicionar readOnly)
  Widget _buildCidadeAutocompleteCorrespondencia({bool readOnly = false,VoidCallback? onUserInteraction}) { // Adicionar readOnly aqui
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (readOnly || textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeCorrespondenciaFields(selection);
        _setUnsavedChanges(true); // Marcar como alterado
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeCorrespondenciaController.text != fieldController.text) {
            fieldController.text = _cidadeCorrespondenciaController.text;
          }
        });
        return CustomInputField(
          maxLength: 5,
          suffixText: '${_cidadeCorrespondenciaController.text.length}/5',
          controller: fieldController,
          focusNode: focusNode,
          label: "Cidade",
          readOnly: readOnly, // Passar o readOnly para o CustomInputField
          fillColor: readOnly ? Colors.grey[300] : Colors.white,
          onUserInteraction: onUserInteraction,
          onChanged: (value) {
            _cidadeCorrespondenciaController.text = value;
            _setUnsavedChanges(true); // Marcar como alterado
            final exactMatches = _allCidades
                .where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase())
                .toList();
            if (exactMatches.length == 1) {
              _populateCidadeCorrespondenciaFields(exactMatches.first);
            }
          },
        );
      },
    );
  }


  // MODIFICAR MÉTODO: _buildCidadeAutocompleteEntrega (Adicionar readOnly)
  Widget _buildCidadeAutocompleteEntrega({bool readOnly = false,VoidCallback? onUserInteraction}) { // Adicionar readOnly aqui
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['id'] as String,
      optionsBuilder: (textEditingValue) {
        if (readOnly || textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allCidades.where((option) {
          final id = option['id']?.toString().toLowerCase() ?? '';
          final cidade = option['cidade']?.toString().toLowerCase() ?? '';
          final input = textEditingValue.text.toLowerCase();
          return id.contains(input) || cidade.contains(input);
        });
      },
      onSelected: (selection) {
        _populateCidadeEntregaFields(selection);
        _setUnsavedChanges(true); // Marcar como alterado
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cidadeEntregaController.text != fieldController.text) {
            fieldController.text = _cidadeEntregaController.text;
          }
        });
        return CustomInputField(
          controller: fieldController,
          maxLength: 5,
          suffixText: '${_cidadeEntregaController.text.length}/5',
          focusNode: focusNode,
          label: "Cidade",
          readOnly: readOnly, // Passar o readOnly para o CustomInputField
          fillColor: readOnly ? Colors.grey[300] : Colors.white,
          onUserInteraction: onUserInteraction,
          onChanged: (value) {
            _cidadeEntregaController.text = value;
            _setUnsavedChanges(true); // Marcar como alterado
            final exactMatches = _allCidades
                .where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase())
                .toList();
            if (exactMatches.length == 1) {
              _populateCidadeEntregaFields(exactMatches.first);
            }
          },
        );
      },
    );
  }


  Widget _buildCargoAutocomplete({VoidCallback? onUserInteraction}) {
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
          maxLength: 5,
          suffixText: '${_cargoContatoController.text.length}/5',
          controller: fieldController,
          focusNode: focusNode,
          label: "Cargo",
          onUserInteraction: onUserInteraction,
          onChanged: (value) {
            _cargoContatoController.text = value;
            final exactMatches = _allCargos
                .where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase())
                .toList();
            if (exactMatches.length == 1) {
              _populateCargoFields(exactMatches.first);
            } else {
              setState(() {
                _resulCargoContatoController.clear();
              });
            }
          },
        );
      },
    );
  }

  Widget _buildCargoAutocomplete2({VoidCallback? onUserInteraction}) {
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
          maxLength: 5,
          suffixText: '${_cargoController.text.length}/5',
          controller: fieldController,
          focusNode: focusNode,
          label: "Cargo",
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onUserInteraction: onUserInteraction,
          onChanged: (value) {
            _cargoController.text = value;
            final exactMatches = _allCargos
                .where((item) => (item['id'] as String?)?.toLowerCase() == value.toLowerCase())
                .toList();
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
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
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
                        Expanded(
                            flex: 1,
                            child: _buildAutocompleteField(
                                _campoComum1Controller, "CPF/CNPJ", 'campoComum1',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'campoComum2')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'campoComum3')),
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
              const SizedBox(height: 20), 
              Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _1Controller,
                        label: "1",onUserInteraction: () => _setUnsavedChanges(true),
                        maxLength: 60,
                        suffixText: '${_1Controller.text.length}/60',

                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _2Controller,
                        label: "2",onUserInteraction: () => _setUnsavedChanges(true),
                        maxLength: 60,
                        suffixText: '${_2Controller.text.length}/60',

                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _3Controller,
                        label: "3",onUserInteraction: () => _setUnsavedChanges(true),
                        maxLength: 60,
                        suffixText: '${_3Controller.text.length}/60',

                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _4Controller,
                        label: "4",onUserInteraction: () => _setUnsavedChanges(true),
                        maxLength: 60,
                        suffixText: '${_4Controller.text.length}/60',

                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: CustomInputField(
                        controller: _5Controller,
                        label: "5",onUserInteraction: () => _setUnsavedChanges(true),
                        maxLength: 60,
                        suffixText: '${_5Controller.text.length}/60',

                        //validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
                      )),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                    color: const Color.fromARGB(255, 153, 205, 248),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blue, width: 2.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text('Possui Endereço? :',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _possuiEndCobran == true,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _possuiEndCobran = newValue!;
                                        _setUnsavedChanges(true); // Marcar como alterado
                                        if (newValue == false) { // Se desmarcar, limpar os campos
                                            _enderecoCobrancaController.clear();
                                            _numeroCobrancaController.clear();
                                            _complementoCobrancaController.clear();
                                            _bairroCobrancaController.clear();
                                            _cidadeCobrancaController.clear();
                                            _respCidadeCobrancaController.clear();
                                            _cepCobrancaController.clear();
                                            _attController.clear();
                                        }
                                      });
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
                                      setState(() {
                                        _possuiEndCobran = !newValue!;
                                        _setUnsavedChanges(true); // Marcar como alterado
                                        if (newValue == true) { // Se marcar "Não", limpar os campos
                                            _enderecoCobrancaController.clear();
                                            _numeroCobrancaController.clear();
                                            _complementoCobrancaController.clear();
                                            _bairroCobrancaController.clear();
                                            _cidadeCobrancaController.clear();
                                            _respCidadeCobrancaController.clear();
                                            _cepCobrancaController.clear();
                                            _attController.clear();
                                        }
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                  const Text('Não', style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _enderecoCobrancaController,
                    label: "Endereço",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_enderecoCobrancaController.text.length}/45',
                    maxLength: 45,
                    readOnly: !_possuiEndCobran, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndCobran && v!.isEmpty) ? 'Campo obrigatório' : null)),
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
                    label: "Numero",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_numeroCobrancaController.text.length}/10',
                    maxLength: 10,
                    readOnly: !_possuiEndCobran, // NOVO: readOnly baseado no checkbox
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) => (_possuiEndCobran && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _complementoCobrancaController,
                    label: "Complemento",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_complementoCobrancaController.text.length}/20',
                    maxLength: 20,
                    readOnly: !_possuiEndCobran, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndCobran && v!.isEmpty) ? 'Campo obrigatório' : null)),
                    SizedBox(width: 10,),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _bairroCobrancaController,
                    label: "Bairro",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_bairroCobrancaController.text.length}/25',
                    maxLength: 25,
                    readOnly: !_possuiEndCobran, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndCobran && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 1,
                child: _buildCidadeAutocompleteEnderecoCobranca(
                    readOnly: !_possuiEndCobran,onUserInteraction: () => _setUnsavedChanges(true))), // NOVO: readOnly no autocomplete
            const SizedBox(width: 10),
            Expanded(
                flex: 5,
                child: CustomInputField(
                    controller: _respCidadeCobrancaController,
                    readOnly: true, // Sempre readOnly, mas o autocomplete só funciona se a cidade principal for editável
                    label: "...",onUserInteraction: () => _setUnsavedChanges(true),
                    validator: (v) => (_possuiEndCobran && v!.isEmpty) ? 'Campo obrigatório' : null)),
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
                  label: "CEP",onUserInteraction: () => _setUnsavedChanges(true),
                  suffixText: '${_cepCobrancaController.text.length}/9',
                  maxLength: 9,
                  readOnly: !_possuiEndCobran, // NOVO: readOnly baseado no checkbox
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CepInputFormatter(),
                  ],
                  validator: (value) {
                    if (_possuiEndCobran) { // Só valida se o checkbox estiver marcado
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value) || value.length != 9) {
                        return 'Formato de CEP inválido (#####-###)';
                      }
                    }
                    return null;
                  },
                  hintText: '#####-###',
                )),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _attController,
                    suffixText: '${_attController.text.length}/30',
                    maxLength: 30,
                    readOnly: !_possuiEndCobran, // NOVO: readOnly baseado no checkbox
                    label: 'Att',onUserInteraction: () => _setUnsavedChanges(true),
                    validator: (v) => (_possuiEndCobran && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
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
        ),
      ],
    );
  }

  // MODIFICAR MÉTODO: _buildAbaCorrespondencia
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
                    color: const Color.fromARGB(255, 153, 205, 248),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blue, width: 2.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text('Possui Endereço? :',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _possuiEndCorrespondencia == true,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _possuiEndCorrespondencia = newValue!;
                                        _setUnsavedChanges(true); // Marcar como alterado
                                        if (newValue == false) { // Se desmarcar, limpar os campos
                                            _enderecoCorrespondenciaController.clear();
                                            _numeroCorrespondenciaController.clear();
                                            _complementoCorrespondenciaController.clear();
                                            _bairroCorrespondenciaController.clear();
                                            _cidadeCorrespondenciaController.clear();
                                            _respCidadeCorrespondenciaController.clear();
                                            _cepCorrespondenciaController.clear();
                                            _attCorrespondenciaController.clear();
                                        }
                                      });
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
                                      setState(() {
                                        _possuiEndCorrespondencia = !newValue!;
                                        _setUnsavedChanges(true); // Marcar como alterado
                                        if (newValue == true) { // Se marcar "Não", limpar os campos
                                            _enderecoCorrespondenciaController.clear();
                                            _numeroCorrespondenciaController.clear();
                                            _complementoCorrespondenciaController.clear();
                                            _bairroCorrespondenciaController.clear();
                                            _cidadeCorrespondenciaController.clear();
                                            _respCidadeCorrespondenciaController.clear();
                                            _cepCorrespondenciaController.clear();
                                            _attCorrespondenciaController.clear();
                                        }
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                  const Text('Não', style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _enderecoCorrespondenciaController,
                    label: "Endereço",onUserInteraction: () => _setUnsavedChanges(true),
                    maxLength: 45,
                    suffixText: '${_enderecoCorrespondenciaController.text.length}/45',
                    readOnly: !_possuiEndCorrespondencia, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndCorrespondencia && v!.isEmpty) ? 'Campo obrigatório' : null)),
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
                    label: "Numero",onUserInteraction: () => _setUnsavedChanges(true),
                    maxLength: 10,
                    suffixText: '${_numeroCorrespondenciaController.text.length}/10',
                    readOnly: !_possuiEndCorrespondencia, // NOVO: readOnly baseado no checkbox
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) => (_possuiEndCorrespondencia && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _complementoCorrespondenciaController,
                    label: "Complemento",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_complementoCorrespondenciaController.text.length}/20',
                    maxLength: 20,
                    readOnly: !_possuiEndCorrespondencia, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndCorrespondencia && v!.isEmpty) ? 'Campo obrigatório' : null)),
            SizedBox(width: 10,),

          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _bairroCorrespondenciaController,
                    label: "Bairro",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_bairroCorrespondenciaController.text.length}/25',
                    maxLength: 25,
                    readOnly: !_possuiEndCorrespondencia, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndCorrespondencia && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 1,
                child: _buildCidadeAutocompleteCorrespondencia(
                    readOnly: !_possuiEndCorrespondencia,onUserInteraction: () => _setUnsavedChanges(true))), // NOVO: readOnly no autocomplete
            const SizedBox(width: 10),
            Expanded(
                flex: 5,
                child: CustomInputField(
                    controller: _respCidadeCorrespondenciaController,
                    readOnly: true, // Sempre readOnly
                    label: "...",onUserInteraction: () => _setUnsavedChanges(true),
                    validator: (v) => (_possuiEndCorrespondencia && v!.isEmpty) ? 'Campo obrigatório' : null)),
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
                  label: "CEP",onUserInteraction: () => _setUnsavedChanges(true),
                  maxLength: 20,
                  suffixText: '${_cepCorrespondenciaController.text.length}/9',
                  readOnly: !_possuiEndCorrespondencia, // NOVO: readOnly baseado no checkbox
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CepInputFormatter(),
                  ],
                  validator: (value) {
                    if (_possuiEndCorrespondencia) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value) || value.length != 9) {
                        return 'Formato de CEP inválido (#####-###)';
                      }
                    }
                    return null;
                  },
                  hintText: '#####-###',
                )),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _attCorrespondenciaController,
                    maxLength: 30,
                    suffixText: '${_attCorrespondenciaController.text.length}/30',
                    readOnly: !_possuiEndCorrespondencia, // NOVO: readOnly baseado no checkbox
                    label: 'Att',onUserInteraction: () => _setUnsavedChanges(true),
                    validator: (v) => (_possuiEndCorrespondencia && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
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
        ),
      ],
    );
  }


  // MODIFICAR MÉTODO: _buildAbaEntrega
  // Aba Entrega (exemplo de como adicionar o botão Salvar)
  Widget _buildAbaEntrega({Key? key}) {
    return _buildAbaContainer(
      key: key,
      color: Colors.blue[100]!,
      title: "Entrega",
      children: [
        // ... (conteúdo existente da aba Entrega)
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 250, right: 250),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 153, 205, 248),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blue, width: 2.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text('Possui Endereço? :',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _possuiEndEntrega == true,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _possuiEndEntrega = newValue!;
                                        _setUnsavedChanges(true); // Marcar como alterado
                                        if (newValue == false) { // Se desmarcar, limpar os campos
                                            _enderecoEntregaController.clear();
                                            _numeroEntregaController.clear();
                                            _complementoEntregaController.clear();
                                            _bairroEntregaController.clear();
                                            _cidadeEntregaController.clear();
                                            _respCidadeEntregaController.clear();
                                            _cepEntregaController.clear();
                                            _attEntregaController.clear();
                                        }
                                      });
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
                                      setState(() {
                                        _possuiEndEntrega = !newValue!;
                                        _setUnsavedChanges(true); // Marcar como alterado
                                        if (newValue == true) { // Se marcar "Não", limpar os campos
                                            _enderecoEntregaController.clear();
                                            _numeroEntregaController.clear();
                                            _complementoEntregaController.clear();
                                            _bairroEntregaController.clear();
                                            _cidadeEntregaController.clear();
                                            _respCidadeEntregaController.clear();
                                            _cepEntregaController.clear();
                                            _attEntregaController.clear();
                                        }
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                  const Text('Não', style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _enderecoEntregaController,
                    label: "Endereço",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_enderecoEntregaController.text.length}/45',
                    maxLength: 45,
                    readOnly: !_possuiEndEntrega, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndEntrega && v!.isEmpty) ? 'Campo obrigatório' : null)),
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
                    label: "Numero",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_numeroEntregaController.text.length}/10',
                    maxLength: 10,
                    readOnly: !_possuiEndEntrega, // NOVO: readOnly baseado no checkbox
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) => (_possuiEndEntrega && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _complementoEntregaController,
                    label: "Complemento",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_complementoEntregaController.text.length}/20',
                    maxLength: 20,
                    readOnly: !_possuiEndEntrega, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndEntrega && v!.isEmpty) ? 'Campo obrigatório' : null)),
            SizedBox(width: 10,),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _bairroEntregaController,
                    label: "Bairro",onUserInteraction: () => _setUnsavedChanges(true),
                    suffixText: '${_bairroEntregaController.text.length}/25',
                    maxLength: 25,
                    readOnly: !_possuiEndEntrega, // NOVO: readOnly baseado no checkbox
                    validator: (v) => (_possuiEndEntrega && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 1,
                child: _buildCidadeAutocompleteEntrega(
                    readOnly: !_possuiEndEntrega,onUserInteraction: () => _setUnsavedChanges(true))), // NOVO: readOnly no autocomplete
            const SizedBox(width: 10),
            Expanded(
                flex: 5,
                child: CustomInputField(
                    controller: _respCidadeEntregaController,
                    readOnly: true, // Sempre readOnly
                    label: "...",onUserInteraction: () => _setUnsavedChanges(true),
                    validator: (v) => (_possuiEndEntrega && v!.isEmpty) ? 'Campo obrigatório' : null)),
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
                  label: "CEP",onUserInteraction: () => _setUnsavedChanges(true),
                  maxLength: 20,
                  suffixText: '${_cepEntregaController.text.length}/9',
                  readOnly: !_possuiEndEntrega, // NOVO: readOnly baseado no checkbox
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CepInputFormatter(),
                  ],
                  validator: (value) {
                    if (_possuiEndEntrega) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value) || value.length != 9) {
                        return 'Formato de CEP inválido (#####-###)';
                      }
                    }
                    return null;
                  },
                  hintText: '#####-###',
                )),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _attEntregaController,
                    maxLength: 30,
                    suffixText: '${_attEntregaController.text.length}/30',
                    readOnly: !_possuiEndEntrega, // NOVO: readOnly baseado no checkbox
                    label: 'Att',onUserInteraction: () => _setUnsavedChanges(true),
                    validator: (v) => (_possuiEndEntrega && v!.isEmpty) ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        // BOTÃO SALVAR ADICIONADO AQUI
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
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
        ),
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
                    label: "Sequencia",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    maxLength: 1,
                    suffixText: '${_sequenciaContatoController.text.length}/1',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 3,
                child: CustomInputField(
                    controller: _nomeContatoController,
                    //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                    maxLength: 40,
                    label: "Nome",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    suffixText: '${_nomeContatoController.text.length}/40',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
            Expanded(
                flex: 1,
                child: CustomInputField(
                    controller: _dataNascimentoContatoController,
                    //readOnly: true,
                    label: "Dt Nasc D/M",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    suffixText: '${_dataNascimentoContatoController.text.length}/5',
                    maxLength: 5,
                    inputFormatters: [DateInputFormatter()], // Aplicar DateInputFormatter
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 1, child: _buildCargoAutocomplete(onUserInteraction: () => _checkSubcollectionInputChanges())),
            const SizedBox(width: 10),
            Expanded(
                flex: 5,
                child: CustomInputField(
                    controller: _resulCargoContatoController,
                    //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                    //maxLength: 5,
                    readOnly: true,
                    label: "...",onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
                    label: "E-mail",onUserInteraction: () => _checkSubcollectionInputChanges(), 
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
                    label: "Obs",onUserInteraction: () => _checkSubcollectionInputChanges(), 
                    suffixText: '${_obsContatoController.text.length}/40',
                    maxLength: 40,
                    //inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 10),
          ],
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),onPressed: _addContato, child: const Text("Adicionar Contato")),
        
        Divider(thickness: 2, color: Colors.blue, height: 10, indent: 40, endIndent: 40),

        // Tabela de dados
        StreamBuilder<QuerySnapshot>(
          stream: _contatosStream,
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

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
              headingRowColor: WidgetStateProperty.all<Color>(Colors.blue[200]!), // Cor do cabeçalho
              dataRowColor: WidgetStateProperty.all<Color>(Colors.white),       // Cor do corpo da tabela
              // --- FIM DAS MODIFICAÇÕES ---
              border: TableBorder(
                top: BorderSide(color: Colors.black),
                right: BorderSide(color: Colors.black),
                left: BorderSide(color: Colors.black),
                bottom: BorderSide(color: Colors.black),
                horizontalInside: BorderSide(color: Colors.blue)),
              columns: [
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('sequencia contato'), child: Text('Seq.'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('nome contato'), child: Text('Nome'))),
                  DataColumn(
                      label:
                          SizedBox(width: _getColumnWidth('data nasc contato'), child: Text('Data Nasc.'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('cargo contato'), child: Text('Cd. Cargo'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('cargo res contato'), child: Text('Cargo'))),
                  DataColumn(
                      label: SizedBox(width: _getColumnWidth('email contato'), child: Text('E-mail'))),
                  DataColumn(label: SizedBox(width: _getColumnWidth('obs contato'), child: Text('Obs.'))),
                  DataColumn(label: Text('Ação')),
                ],
                rows: referencias.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    _buildEditableCell('contatos', doc, 'sequencia contato', data['sequencia contato'] ?? '',
                        maxLength: 2, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell(
                        'contatos', doc, 'nome contato', data['nome contato'] ?? '',
                        maxLength: 40),
                    _buildEditableCell('contatos', doc, 'data nasc contato',
                        data['data nasc contato'] ?? '',
                        maxLength: 5, inputFormatters: [DateInputFormatter()]),
                    _buildEditableCell(
                        'contatos', doc, 'cargo contato', data['cargo contato'] ?? '',
                        maxLength: 5, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildEditableCell('contatos', doc, 'cargo res contato',
                        data['cargo res contato'] ?? '',
                        maxLength: 35),
                    _buildEditableCell('contatos', doc, 'email contato', data['email contato'] ?? '',
                        maxLength: 40),
                    _buildEditableCell('contatos', doc, 'obs contato', data['obs contato'] ?? '',
                        maxLength: 40),
                    /*DataCell(Text(data['sequencia contato'] ?? '')), DataCell(Text(data['nome contato'] ?? '')),
                          DataCell(Text(data['data nasc contato'] ?? '')), DataCell(Text(data['cargo contato'] ?? '')),
                          DataCell(Text(data['cargo res contato'] ?? '')),
                          DataCell(Text(data['email contato'] ?? '')), DataCell(Text(data['obs contato'] ?? '')),*/
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteContato(_campoComum1Controller.text.trim(), doc.id),
                    )),
                  ]);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Novo InputFormatter para CPF (exemplo, você já tem um para CNPJ)
class CpfCnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), ''); // Remove tudo que não é dígito

    if (text.length <= 11) { // Assume CPF
      return CpfInputFormatter().formatEditUpdate(oldValue, newValue);
    } else { // Assume CNPJ
      return CnpjInputFormatter().formatEditUpdate(oldValue, newValue);

    }
  }

  
}
