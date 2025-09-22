import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaEstadoXImposto.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/botao_ajuda_flutuante.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/services/manut_rg_service.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

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

class DateInputFormatterDDMMYYYY extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Se o novo valor estiver vazio, não faça nada
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não for dígito
    String cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limita o tamanho para 8 dígitos (DDMMYYYY)
    if (cleanText.length > 8) {
      cleanText = cleanText.substring(0, 8);
    }

    var buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      // Adiciona a primeira barra depois do dia (2 dígitos)
      if (i == 1 && cleanText.length > 2) {
        buffer.write('/');
      }
      // Adiciona a segunda barra depois do mês (4 dígitos)
      if (i == 3 && cleanText.length > 4) {
        buffer.write('/');
      }
    }

    String formattedText = buffer.toString();
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

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
  final String? initialRgId;  
  

  const PaginaComAbasLaterais({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
    this.initialRgId,
  });

  @override
  State<PaginaComAbasLaterais> createState() => _PaginaComAbasLateraisState();
}
String _pageTitle = 'Dados Gerais'; // NOVO: Título inicial da página

class _PaginaComAbasLateraisState extends State<PaginaComAbasLaterais> {
  static const double _breakpoint = 700.0;
  late String _currentDate;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ManutRgService _manutRgService = ManutRgService();

  final TextEditingController _tipoPessoaController = TextEditingController();
  String? _tipoPessoa; // Armazena 'fisica' ou 'juridica'

  bool _isCodigoEditable = true; // Controla se o campo "Código" pode ser editado
  Timer? _debounce; // Controla o tempo de espera após o usuário parar de digitar no CPF/CNPJ

  int _selectedIndex = 0;
  bool _isLoading = false;

  // Lista para popular os dropdowns de busca
  List<Map<String, dynamic>> _allControlData = [];
  List<Map<String, dynamic>> _allCidades = [];
  List<Map<String, dynamic>> _allCargos = [];
  List<Map<String, dynamic>> _allSituacoes = [];
  List<Map<String, dynamic>> _allPaises = [];
  Map<String, bool> _isFieldSelectedFromDropdown = {};
  Map<String, dynamic>? _rgData;

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

  // ▼▼▼ ADICIONE ESTES CONTROLLERS ▼▼▼
final TextEditingController _estadoCivilController = TextEditingController();
final TextEditingController _rgController = TextEditingController();
final TextEditingController _dataExpedicaoController = TextEditingController();
final TextEditingController _dataNascimentoController = TextEditingController();
final TextEditingController _profissaoController = TextEditingController();
// ▲▲▲ FIM DA ADIÇÃO ▲▲▲

  String? _selectedContribIcms;
  String? _selectedRevenda;

  Map<String, String>? _editingCell;
  final TextEditingController _cellEditController = TextEditingController();
  final FocusNode _cellFocusNode = FocusNode();

  

  bool _possuiEndCobran = false;
  bool _possuiEndCorrespondencia = false;
  bool _possuiEndEntrega = false;
  bool _hasUnsavedChanges = false;

  

  @override
  void initState() {
  super.initState();
  _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  _fetchAllInitialData();
  //_fetchAllControlData();
  //_fetchAllCidades();
 // _fetchAllCargos();
  //_fetchAllSituacoes(); 

  // ▼▼▼ ADICIONE ESTA LÓGICA DE VERIFICAÇÃO INICIAL ▼▼▼
    // Se a página foi aberta com um ID, carrega os dados dele.
    if (widget.initialRgId != null && widget.initialRgId!.isNotEmpty) {
      // Usamos um post-frame callback para garantir que o contexto está pronto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialRecord(widget.initialRgId!);
      });
    }
    // ▲▲▲ FIM DA ADIÇÃO ▲▲▲

  _isFieldSelectedFromDropdown = {
        'campoComum1': false,
        'campoComum2': false,
        'campoComum3': false,
    };

  // Mantenha os listeners para os campos de busca que controlam a população/limpeza
  //_campoComum1Controller.addListener(_updateStreams);
  _campoComum1Controller.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 1500), () {
        _handleCpfCnpjExit();
      });
      _determinarTipoPessoa();
    });
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
  //_campoComum1Controller.addListener(_loadCheckboxStates);
}

// ▼▼▼ ADICIONE ESTE NOVO MÉTODO À CLASSE _PaginaComAbasLateraisState ▼▼▼
  /// Carrega um registro inicial e bloqueia os campos de busca.
  Future<void> _loadInitialRecord(String rgId) async {
    _campoComum1Controller.text = rgId; // Preenche o campo de CPF/CNPJ
    _determinarTipoPessoa();
    setState(() {
      _isCodigoEditable = false; // Bloqueia o campo de código
    });
    await _loadRgData(rgId); // Chama a função que já busca e preenche os dados
  }

void _updateCounters() {
    setState(() {});
  }

  Widget _buildHelpContent() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ajuda - Envio de Avisos',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(height: 20),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Esta tela permite enviar uma mensagem em tempo real para todos os usuários que estiverem online no sistema.'),
        ),
        const ListTile(
          leading: Icon(Icons.history),
          title: Text('Abaixo do campo de envio, você pode visualizar um histórico dos últimos avisos enviados.'),
        ),
         ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          title: RichText(
            text: TextSpan(
              style: textTheme.bodyMedium,
              children: const [
                TextSpan(text: 'Atenção: '),
                TextSpan(text: 'As mensagens são enviadas instantaneamente e não podem ser desfeitas.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /*Future<void> _loadDataByCodigo(String codigo) async {
    if (codigo.isEmpty) return;

    final rgSuggestion = _allControlData.firstWhereOrNull(
      (rg) => rg['codigo_interno'] == codigo
    );

    if (rgSuggestion != null) {
      await _loadRgData(rgSuggestion['id']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código não encontrado.'))
      );
    }
  }*/

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

  void _determinarTipoPessoa() {
  final cleanValue = _campoComum1Controller.text.replaceAll(RegExp(r'\D'), '');
  if (mounted) {
    setState(() {
      if (cleanValue.length == 11) {
        _tipoPessoaController.text = 'Física';
        _tipoPessoa = 'fisica';
      } else if (cleanValue.length == 14) {
        _tipoPessoaController.text = 'Jurídica';
        _tipoPessoa = 'juridica';
      } else {
        _tipoPessoaController.text = '';
        _tipoPessoa = null;
      }
    });
  }
}

Future<void> _handleCpfCnpjExit() async {
    final cpfCnpj = _campoComum1Controller.text.trim();
    if (cpfCnpj.isEmpty || (_cpfCnpjValidator(cpfCnpj) != null)) {
      return; // Sai se o campo estiver vazio ou for inválido
    }

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _manutRgService.getRgCompleto(cpfCnpj, token);

      if (data.isNotEmpty) {
        // --- CASO 1: CPF/CNPJ EXISTE ---
        _populateAllFields(data);
        setState(() {
          _isCodigoEditable = false; // Bloqueia o campo Código pois o registro já existe
        });
      } else {
        // --- CASO 2: CPF/CNPJ É NOVO ---
        _clearDependentFields(); // Limpa campos de um registro anterior
        _campoComum1Controller.text = cpfCnpj; // Repõe o CPF/CNPJ que foi limpo
        _determinarTipoPessoa();
        
        // Gera o novo código interno
        final newCode = await _manutRgService.getNextCodigoInterno(token);
        
        setState(() {
          _campoComum2Controller.text = newCode;
          _dataInclusaoController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
          _isCodigoEditable = false; // Bloqueia o campo Código pois um novo será criado
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na verificação: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setUnsavedChanges(bool hasChanges) {
    if (_hasUnsavedChanges != hasChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  // Adicionar uma nova função para carregar os dados via API
Future<void> _loadRgData(String rgId) async {
    if (rgId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Usuário não autenticado.');

      final data = await _manutRgService.getRgCompleto(rgId, token);
      
      setState(() {
        if (data.isNotEmpty) {
          _rgData = data;
          _populateAllFields(_rgData!);
        } else {
          _rgData = null;
          _clearDependentFields();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CPF/CNPJ não encontrado. Você pode criar um novo registro.')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  

  // NOVO MÉTODO: Para carregar o estado dos checkboxes baseado nos dados da empresa
  // Isso deve ser chamado quando uma empresa é carregada (e não apenas quando um campo é modificado).
  /*void _loadCheckboxStates() {
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
  }*/

  void _updateEmpresaCounter() {
    // Força a reconstrução do widget para que o suffixText seja atualizado
    setState(() {});
  }

  // Helper para obter a referência da coleção
  

  

  

  

  // Busca todos os dados para popular os dropdowns
  Future<void> _fetchAllControlData() async {
  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    // Usa o novo endpoint de sugestões
    _allControlData = await _manutRgService.getRgSuggestions(token);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao carregar sugestões: $e')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _fetchAllInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado");

      // Carrega todos os dados auxiliares em paralelo
      final results = await Future.wait([
        _manutRgService.getRgSuggestions(token),
        _manutRgService.getDadosAuxiliares('cidades', token),
        _manutRgService.getDadosAuxiliares('cargos', token),
        _manutRgService.getDadosAuxiliares('situacoes', token),
        _manutRgService.getDadosAuxiliares('paises', token), // <-- ADICIONE ESTA LINHA
      ]);

      _allControlData = results[0];
      _allCidades = results[1];
      _allCargos = results[2];
      _allSituacoes = results[3];
      _allPaises = results[4]; 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados iniciais: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPaisAutocomplete({VoidCallback? onUserInteraction}) {
  return Autocomplete<Map<String, dynamic>>(
    displayStringForOption: (option) => option['nome'] as String? ?? '',
    optionsBuilder: (textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return const Iterable.empty();
      }
      return _allPaises.where((option) {
        final nome = option['nome']?.toString().toLowerCase() ?? '';
        final id = option['id']?.toString().toLowerCase() ?? '';
        final input = textEditingValue.text.toLowerCase();
        return nome.contains(input) || id.contains(input);
      });
    },
    onSelected: (selection) {
      setState(() {
        _paisController.text = selection['id'] ?? '';
      });
      FocusScope.of(context).unfocus();
      onUserInteraction?.call();
    },
    fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final matchedPais = _allPaises.firstWhereOrNull(
          (element) => element['id'] == _paisController.text
        );
        final displayText = matchedPais != null ? matchedPais['nome'] : _paisController.text;
        if (fieldController.text != displayText) {
          fieldController.text = displayText;
        }
      });

      return CustomInputField(
        controller: fieldController,
        focusNode: focusNode,
        label: "País",
        onUserInteraction: onUserInteraction,
        onChanged: (value) {
          // ATUALIZAÇÃO SUTIL: Não mexa no _paisController aqui para evitar o loop
          // Apenas deixe o Autocomplete gerenciar o texto digitado
        },
      );
    },
  );
}

  Future<void> _fetchAllCidades() async {
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    // Chama o novo método do service
    _allCidades = await _manutRgService.getCidades(token);
    if (mounted) setState(() {});
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao carregar cidades: $e')),
    );
  }
}

  Future<void> _fetchAllCargos() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    // Chama o novo método do service
    _allCargos = await _manutRgService.getCargos(token);
    if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cargos: $e')));
    }
  }

  Future<void> _fetchAllSituacoes() async {
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    // Chama o novo método do service
    _allSituacoes = await _manutRgService.getSituacoes(token);
    if (mounted) setState(() {});
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar situações: $e')));
  }
}

  // Preenche todos os campos com base no item selecionado no dropdown
  void _populateAllFields(Map<String, dynamic> data) {
  setState(() {
    _campoComum1Controller.text = data['id'] ?? '';
    _campoComum2Controller.text = data['codigo_interno'] ?? '';
    _campoComum3Controller.text = data['razao_social'] ?? '';
    _codigoGeradoController.text = data['codigo_gerado']?.toString() ?? '';

    // LÓGICA ATUALIZADA AQUI
    _tipoPessoa = data['tipo_pessoa'];
    if (_tipoPessoa == 'fisica') {
      _tipoPessoaController.text = 'Física';
    } else if (_tipoPessoa == 'juridica') {
      _tipoPessoaController.text = 'Jurídica';
    } else {
      _tipoPessoaController.text = '';
    }
    // FIM DA LÓGICA ATUALIZADA
    
    if (data['data_inclusao'] != null) {
      final dataInclusao = DateTime.tryParse(data['data_inclusao']);
      if (dataInclusao != null) {
        _dataInclusaoController.text = DateFormat('dd/MM/yyyy').format(dataInclusao);
      }
    } else {
      _dataInclusaoController.clear();
    }

    // --- Aba Dados Gerais ---
    _cepController.text = data['cep'] ?? '';
    _enderecoController.text = data['endereco'] ?? '';
    _numeroController.text = data['numero'] ?? '';
    _complementoController.text = data['complemento'] ?? '';
    _bairroController.text = data['bairro'] ?? '';
    _cidadeController.text = data['cidade_id'] ?? '';
    _ufController.text = data['uf'] ?? '';
    _cxPostalController.text = data['caixa_postal'] ?? '';
    _comoNosConheceuController.text = data['como_nos_conheceu'] ?? '';
    _portadorController.text = data['portador'] ?? '';
    _tabDescontoController.text = data['tab_desconto'] ?? '';
    _inscSuframaController.text = data['insc_suframa'] ?? '';
    _inscProdutorController.text = data['insc_produtor'] ?? '';
    _inscMunicipalController.text = data['insc_municipal'] ?? '';
    _vendedorController.text = data['vendedor_id'] ?? '';
    _atendenteController.text = data['atendente_id'] ?? '';
    _areaController.text = data['area_id'] ?? '';
    _situacaoController.text = data['situacao_id'] ?? '';

    // --- Aba Jurídica ---
    _cnpjController.text = data['cnpj_juridico'] ?? ''; // CORRIGIDO
    _inscEstadualController.text = data['insc_estadual'] ?? '';
    String? contribValue = data['contrib_icms'];
    _selectedContribIcms = (contribValue == 'Sim' || contribValue == 'Não') ? contribValue : null;
    String? revendaValue = data['revenda'];
    _selectedRevenda = (revendaValue == 'Sim' || revendaValue == 'Não') ? revendaValue : null;

    // --- Aba Complemento ---
    _confidencialController.text = data['confidencial'] ?? '';
    _observacaoController.text = data['observacao'] ?? '';
    _observacaoNfController.text = data['observacao_nf'] ?? '';
    _eMailController.text = data['email_principal'] ?? '';
    _eMailCobranController.text = data['email_cobranca'] ?? '';
    _eMailNfController.text = data['email_nfe'] ?? '';
    _siteController.text = data['site'] ?? '';

    // --- Aba Apelido/Fantasia ---
    _1Controller.text = data['fantasia1'] ?? '';
    _2Controller.text = data['fantasia2'] ?? '';
    _3Controller.text = data['fantasia3'] ?? '';
    _4Controller.text = data['fantasia4'] ?? '';
    _5Controller.text = data['fantasia5'] ?? '';

    // --- Abas de Endereço ---
    _possuiEndCobran = data['possui_end_cobranca'] ?? false;
    _enderecoCobrancaController.text = data['cobranca_endereco'] ?? '';
    _numeroCobrancaController.text = data['cobranca_numero'] ?? '';
    _complementoCobrancaController.text = data['cobranca_complemento'] ?? '';
    _bairroCobrancaController.text = data['cobranca_bairro'] ?? '';
    _cidadeCobrancaController.text = data['cobranca_cidade_id'] ?? '';
    _cepCobrancaController.text = data['cobranca_cep'] ?? '';
    _attController.text = data['cobranca_att'] ?? '';
    
    // CORREÇÃO ABA CORRESPONDÊNCIA
    _possuiEndCorrespondencia = data['possui_end_correspondencia'] ?? false;
    _enderecoCorrespondenciaController.text = data['correspondencia_endereco'] ?? '';
    _numeroCorrespondenciaController.text = data['correspondencia_numero'] ?? '';
    _complementoCorrespondenciaController.text = data['correspondencia_complemento'] ?? '';
    _bairroCorrespondenciaController.text = data['correspondencia_bairro'] ?? '';
    _cidadeCorrespondenciaController.text = data['correspondencia_cidade_id'] ?? '';
    _cepCorrespondenciaController.text = data['correspondencia_cep'] ?? '';
    _attCorrespondenciaController.text = data['correspondencia_att'] ?? '';

    // CORREÇÃO ABA ENTREGA
    _possuiEndEntrega = data['possui_end_entrega'] ?? false;
    _enderecoEntregaController.text = data['entrega_endereco'] ?? '';
    _numeroEntregaController.text = data['entrega_numero'] ?? '';
    _complementoEntregaController.text = data['entrega_complemento'] ?? '';
    _bairroEntregaController.text = data['entrega_bairro'] ?? '';
    _cidadeEntregaController.text = data['entrega_cidade_id'] ?? '';
    _cepEntregaController.text = data['entrega_cep'] ?? '';
    _attEntregaController.text = data['entrega_att'] ?? '';

    // ▼▼▼ ADICIONE ESTE NOVO BLOCO ▼▼▼
// --- Aba Física ---
_estadoCivilController.text = data['estado_civil'] ?? '';
_rgController.text = data['rg'] ?? '';
_profissaoController.text = data['profissao'] ?? '';

if (data['data_expedicao_rg'] != null) {
  final dataExp = DateTime.tryParse(data['data_expedicao_rg']);
  if (dataExp != null) {
    _dataExpedicaoController.text = DateFormat('dd/MM/yyyy').format(dataExp);
  }
} else {
  _dataExpedicaoController.clear();
}

if (data['data_nascimento'] != null) {
  final dataNasc = DateTime.tryParse(data['data_nascimento']);
  if (dataNasc != null) {
    _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(dataNasc);
  }
} else {
  _dataNascimentoController.clear();
}
// ▲▲▲ FIM DO NOVO BLOCO ▲▲▲

    // Resetar flags de alteração
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

    _tipoPessoaController.clear();

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

    // ▼▼▼ ADICIONE ESTE NOVO BLOCO ▼▼▼
_estadoCivilController.clear();
_rgController.clear();
_dataExpedicaoController.clear();
_dataNascimentoController.clear();
_profissaoController.clear();
// ▲▲▲ FIM DO NOVO BLOCO ▲▲▲


    setState(() {
      _tipoPessoa = null;
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
    _clearDependentFields(); // Limpa todo o resto do formulário
    
    setState(() {
      _isFieldSelectedFromDropdown['campoComum1'] = false;
      _isFieldSelectedFromDropdown['campoComum2'] = false;
      _isFieldSelectedFromDropdown['campoComum3'] = false;
      _isCodigoEditable = true; // ALTERAÇÃO: Libera o campo Código para pesquisa
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
  if (_codigoGeradoController.text.isNotEmpty) return;
  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    // Simplesmente chama o service que pergunta ao backend
    final newCode = await _manutRgService.getNextCodigo(token);
    
    setState(() {
      _codigoGeradoController.text = newCode;
      _dataInclusaoController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    });
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Erro ao gerar novo código: $e')));
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  // Função unificada para Adicionar sub-itens
  Future<void> _addSubItem(String path, Map<String, dynamic> data) async {
    final rgId = _campoComum1Controller.text.trim();
    if (rgId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primeiro, selecione um RG.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Não autenticado');
      
      await _manutRgService.addSubItem(rgId, path, data, token);
      await _loadRgData(rgId); // Recarrega para atualizar a UI
      _clearSubcollectionInputFields(_selectedIndex); // Limpa os campos de entrada

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar item: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Função unificada para Deletar sub-itens
  Future<void> _deleteSubItem(String itemId, String path) async {
    final rgId = _campoComum1Controller.text.trim();
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Não autenticado');

      await _manutRgService.deleteSubItem(itemId, path, token);
      await _loadRgData(rgId); // Recarrega para atualizar a UI

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir item: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSubcollectionField(String subcollectionPath, Map<String, dynamic> itemData, String field, String newValue) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sessão expirada.')));
        return;
    }

    setState(() { itemData[field] = newValue; }); 

    final String itemId = itemData['id'].toString();

    try {
        await _manutRgService.updateSubItem(itemId, subcollectionPath, itemData, token);
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar campo: $e')));
        await _loadRgData(_campoComum1Controller.text.trim());
    }
  }


  // Salva os dados de TODAS as abas no Firebase
  // SUBSTITUA SUA FUNÇÃO INTEIRA POR ESTA
Future<void> _saveData() async {
  final docId = _campoComum1Controller.text.trim();
  if (docId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('O campo "CPF/CNPJ" é obrigatório para salvar.')),
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
    // Bloco 1: Identificação
    'id': docId,
    'codigo_interno': _campoComum2Controller.text,
    'razao_social': _campoComum3Controller.text,
    'tipo_pessoa': _tipoPessoa, // <<< ADICIONE ESTA LINHA
    'codigo_gerado': _codigoGeradoController.text,
    'data_inclusao': _dataInclusaoController.text.isNotEmpty
        ? DateFormat('dd/MM/yyyy').parse(_dataInclusaoController.text).toUtc().toIso8601String()
        : null,

    // ▼▼▼ ADICIONE ESTE NOVO BLOCO ▼▼▼
    // Bloco 1.5: Dados Pessoa Física
    'estado_civil': _estadoCivilController.text,
    'rg': _rgController.text,
    'profissao': _profissaoController.text,
    'data_expedicao_rg': _dataExpedicaoController.text.isNotEmpty
        ? DateFormat('dd/MM/yyyy').parse(_dataExpedicaoController.text).toUtc().toIso8601String()
        : null,
    'data_nascimento': _dataNascimentoController.text.isNotEmpty
        ? DateFormat('dd/MM/yyyy').parse(_dataNascimentoController.text).toUtc().toIso8601String()
        : null,
    // ▲▲▲ FIM DO NOVO BLOCO ▲▲▲
    
    // Bloco 2: Endereço Principal
    'cep': _cepController.text,
    'endereco': _enderecoController.text,
    'numero': _numeroController.text,
    'complemento': _complementoController.text,
    'bairro': _bairroController.text,
    'cidade_id': _cidadeController.text,
    'uf': _ufController.text,
    'caixa_postal': _cxPostalController.text,

    // Bloco 3: Jurídico
    'insc_estadual': _inscEstadualController.text,
    'cnpj_juridico': _cnpjController.text,
    'contrib_icms': _selectedContribIcms,
    'revenda': _selectedRevenda,

    // Bloco 4: Complemento
    'confidencial': _confidencialController.text,
    'observacao': _observacaoController.text,
    'observacao_nf': _observacaoNfController.text,
    'email_principal': _eMailController.text,
    'email_cobranca': _eMailCobranController.text,
    'email_nfe': _eMailNfController.text,
    'site': _siteController.text,

    // Bloco 5: Fantasia
    'fantasia1': _1Controller.text,
    'fantasia2': _2Controller.text,
    'fantasia3': _3Controller.text,
    'fantasia4': _4Controller.text,
    'fantasia5': _5Controller.text,

    // Bloco 6: Dados Gerais Adicionais
    'como_nos_conheceu': _comoNosConheceuController.text,
    'portador': _portadorController.text,
    'tab_desconto': _tabDescontoController.text,
    'insc_suframa': _inscSuframaController.text,
    'insc_produtor': _inscProdutorController.text,
    'insc_municipal': _inscMunicipalController.text,
    'vendedor_id': _vendedorController.text,
    'atendente_id': _atendenteController.text,
    'area_id': _areaController.text,
    'situacao_id': _situacaoController.text,

    // Bloco 7: Endereço Cobrança
    'possui_end_cobranca': _possuiEndCobran,
    'cobranca_cep': _cepCobrancaController.text,
    'cobranca_endereco': _enderecoCobrancaController.text,
    'cobranca_numero': _numeroCobrancaController.text,
    'cobranca_complemento': _complementoCobrancaController.text,
    'cobranca_bairro': _bairroCobrancaController.text,
    'cobranca_cidade_id': _cidadeCobrancaController.text,
    'cobranca_att': _attController.text,

    // Bloco 8: Endereço Correspondência (CAMPOS ADICIONADOS)
    'possui_end_correspondencia': _possuiEndCorrespondencia,
    'correspondencia_cep': _cepCorrespondenciaController.text,
    'correspondencia_endereco': _enderecoCorrespondenciaController.text,
    'correspondencia_numero': _numeroCorrespondenciaController.text,
    'correspondencia_complemento': _complementoCorrespondenciaController.text,
    'correspondencia_bairro': _bairroCorrespondenciaController.text,
    'correspondencia_cidade_id': _cidadeCorrespondenciaController.text,
    'correspondencia_att': _attCorrespondenciaController.text,

    // Bloco 9: Endereço Entrega (CAMPOS ADICIONADOS)
    'possui_end_entrega': _possuiEndEntrega,
    'entrega_cep': _cepEntregaController.text,
    'entrega_endereco': _enderecoEntregaController.text,
    'entrega_numero': _numeroEntregaController.text,
    'entrega_complemento': _complementoEntregaController.text,
    'entrega_bairro': _bairroEntregaController.text,
    'entrega_cidade_id': _cidadeEntregaController.text,
    'entrega_att': _attEntregaController.text,

    // Bloco 10: Auditoria
    'id_empresa_principal': widget.mainCompanyId,
    'id_empresa_secundaria': widget.secondaryCompanyId,
  };

  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    await _manutRgService.saveData(dataToSave, token);
    await _fetchAllControlData();
    
    _setUnsavedChanges(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados salvos com sucesso!')),
    );
    await _loadRgData(docId);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao salvar dados: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _addSocio() async {
    final rgId = _campoComum1Controller.text.trim();
    final docId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final socioData = {
    'sequencia': _sqController.text,
    'socio_id': _socioController.text,
    'nome': _nomeController.text,
    'cpf': _cpfController.text,
    'cargo_id': _cargoController.text,
    'participacao': _participacaoController.text,
  };
  
    String socioNome = _nomeController.text.trim(); // Pega o nome para o log
    setState(() => _isLoading = true);

    try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    await _manutRgService.addSubItem(rgId, 'socios', socioData, token); // <-- LINHA CORRIGIDA

    // Limpa os campos de entrada
    _sqController.clear();
    _socioController.clear();
    // ... limpar outros controllers ...

    // Recarrega todos os dados para atualizar a tabela na UI
    await _loadRgData(rgId);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar sócio: $e')));
  } finally {
    setState(() => _isLoading = false);
  }
  }

  Future<void> _deleteSocio(String socioId) async {
  final rgId = _campoComum1Controller.text.trim();
  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    await _manutRgService.deleteSubItem(socioId, 'socios', token); // <-- LINHA CORRIGIDA
    
    // Recarrega para atualizar a UI
    await _loadRgData(rgId);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir sócio: $e')));
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _addTelefone() async {
    final docId = _campoComum1Controller.text.trim();
     final rgId = _campoComum1Controller.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
      return;
    }

    final telefoneData = {
  'sequencia': _sqController.text, // <-- CORRIGIDO
  'pais': _paisController.text,
  'operadora': _operadoraController.text,
  'ddd': _dddController.text,
  'numero': _nroController.text, // <-- CORRIGIDO
  'ramal': _ramalController.text,
  'tipo': _tipoController.text,
  'contato': _contatoController.text,
};
    setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    await _manutRgService.addTelefone(rgId, telefoneData, token);

      
      _sqController.clear();
      _paisController.clear();
      _operadoraController.clear();
      _dddController.clear();
      _nroController.clear();
      _ramalController.clear();
      _tipoController.clear();
      _contatoController.clear();
      await _loadRgData(rgId);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar sócio: $e')));
  } finally {
    setState(() => _isLoading = false);
  }
  }

  Future<void> _deleteTelefone(String itemId, String telefoneId) async {
    final rgId = _campoComum1Controller.text.trim();
  setState(() => _isLoading = true);
    try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    await _manutRgService.deleteTelefone(telefoneId, token);
    
    // Recarrega para atualizar a UI
    await _loadRgData(rgId);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir telefone: $e')));
  } finally {
    setState(() => _isLoading = false);
  }
  }

  /*Future<void> _updateSubcollectionField(
    String subcollection, Map<String, dynamic> itemData, String field, String newValue) async {
  
  final token = Provider.of<AuthProvider>(context, listen: false).token;
  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sessão expirada.')));
    return;
  }

  // 1. Atualiza o valor no Map local para a UI responder imediatamente.
  setState(() {
    itemData[field] = newValue;
  });

  // 2. Envia a atualização completa para o backend.
  final String itemId = itemData['id'].toString();

  try {
    // Decide qual método de atualização chamar baseado na sub-coleção
    switch (subcollection) {
      case 'telefones':
        await _manutRgService.updateTelefone(itemId, itemData, token);
        break;
      // case 'socios':
      //   await _manutRgService.updateSocio(itemId, itemData, token);
      //   break;
      // Adicione casos para 'contatos', 'referencias_bancarias', etc.
      default:
        throw Exception('Tipo de atualização desconhecido: $subcollection');
    }
    // Opcional: mostrar um feedback sutil de sucesso
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campo atualizado!'), duration: Duration(seconds: 1)));

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao atualizar campo: $e')),
    );
    // Opcional: Reverter a mudança na UI se a chamada à API falhar
    // _loadRgData(_campoComum1Controller.text.trim());
  }
}*/

  

  Future<void> _addReferenciaComercial() async {
  final rgId = _campoComum1Controller.text.trim();
  if (rgId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
    return;
  }

  // CORREÇÃO: Chaves do mapa atualizadas para corresponder às colunas do banco de dados
  final refData = {
    'sequencia': _sequenciaRefComercialController.text,
    'nome_empresa': _nomeRefComercialController.text,
    'endereco': _enderecoRefComercialController.text,
    'cidade_id': _cidadeRefComercialController.text,
    'contato': _contatoRefComercialController.text,
    'telefone': _telefoneRefComercialController.text,
    'email': _emailRefComercialController.text,
    'observacao': _obsRefComercialController.text,
  };

  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    // CORREÇÃO: Usando a função genérica addSubItem com o caminho correto
    await _manutRgService.addSubItem(rgId, 'referencias-comerciais', refData, token);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referência comercial adicionada com sucesso!')));
    
    _clearSubcollectionInputFields(_selectedIndex); // Limpa os campos de entrada
    await _loadRgData(rgId); // Recarrega os dados para atualizar a tabela

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar referência: $e')));
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

// NOVO MÉTODO: _deleteReferenciaComercial
Future<void> _deleteReferenciaComercial(String refId) async {
  final rgId = _campoComum1Controller.text.trim();
  if (rgId.isEmpty) return;

  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    // CORREÇÃO: Usando a função genérica deleteSubItem com o caminho correto
    await _manutRgService.deleteSubItem(refId, 'referencias-comerciais', token);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referência comercial excluída com sucesso!')));
    await _loadRgData(rgId); // Recarrega para atualizar a UI

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir referência: $e')));
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _addReferenciaBancaria() async {
  final rgId = _campoComum1Controller.text.trim();
  if (rgId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
    return;
  }

  // CORREÇÃO: Chaves do mapa atualizadas para corresponder às colunas do banco de dados
  final refData = {
    'sequencia': _sequenciaController.text,
    'nome_banco': _nomeRefBancariaController.text,
    //'resul_nome': _resulNomeController.text, // O campo '...' não precisa ser salvo
    'endereco': _enderecoRefBancariaController.text,
    'cidade_id': _cidadeRefBancariaController.text,
    'contato': _contatoRefBancariaController.text,
    'telefone': _telefoneRefBancariaController.text,
    'email': _emailRefBancariaController.text,
    'observacao': _obsRefBancariaController.text,
  };

  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    // CORREÇÃO: Usando a função genérica addSubItem com o caminho correto
    await _manutRgService.addSubItem(rgId, 'referencias-bancarias', refData, token);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referência bancária adicionada com sucesso!')));
    
    _clearSubcollectionInputFields(_selectedIndex); // Limpa os campos de entrada
    await _loadRgData(rgId); // Recarrega todos os dados para atualizar a tabela

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar referência: $e')));
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _deleteReferenciaBancaria(String refId) async {
  final rgId = _campoComum1Controller.text.trim();
  if (rgId.isEmpty) return;

  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    // CORREÇÃO: Usando a função genérica deleteSubItem com o caminho correto
    await _manutRgService.deleteSubItem(refId, 'referencias-bancarias', token);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referência bancária excluída com sucesso!')));
    await _loadRgData(rgId); // Recarrega para atualizar a UI

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir referência: $e')));
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _addContato() async {
  final rgId = _campoComum1Controller.text.trim();
  if (rgId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primeiro, busque ou cadastre uma empresa (CPF/CNPJ).')));
    return;
  }

  // CORREÇÃO: Chaves do mapa atualizadas para corresponder às colunas do banco de dados
  final contatoData = {
    'sequencia': _sequenciaContatoController.text,
    'nome': _nomeContatoController.text,
    'data_nascimento': _dataNascimentoContatoController.text,
    'cargo_id': _cargoContatoController.text,
    'email': _emailContatoController.text,
    'observacao': _obsContatoController.text,
  };

  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    // CORREÇÃO: Usando a função genérica addSubItem com o caminho correto
    await _manutRgService.addSubItem(rgId, 'contatos', contatoData, token);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contato adicionado com sucesso!')));
    
    _clearSubcollectionInputFields(_selectedIndex); // Limpa os campos de entrada
    await _loadRgData(rgId); // Recarrega os dados para atualizar a tabela

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar contato: $e')));
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _deleteContato(String contatoId) async {
  final rgId = _campoComum1Controller.text.trim();
  if (rgId.isEmpty) return;

  setState(() => _isLoading = true);
  try {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) throw Exception('Usuário não autenticado.');

    // CORREÇÃO: Usando a função genérica deleteSubItem com o caminho correto
    await _manutRgService.deleteSubItem(contatoId, 'contatos', token);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contato excluído com sucesso!')));
    await _loadRgData(rgId); // Recarrega para atualizar a UI

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir contato: $e')));
  } finally {
    if (mounted) setState(() => _isLoading = false);
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
      body: BotaoAjudaFlutuante(helpContent: _buildHelpContent(),
        child: Stack(
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
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final theme = Theme.of(context);
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
                child: Text(_pageTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
                //_buildCamposDeBusca(),
                Divider(thickness: 2, color: theme.colorScheme.primary, height: 10, indent: 40, endIndent: 40),
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 0, right: 25, bottom: 0),
      decoration: BoxDecoration(
        // ▼▼▼ ALTERAÇÃO DE COR ▼▼▼
        color: theme.colorScheme.surface.withOpacity(0.5),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabButton(title: 'Dados Gerais', index: 0),
            _buildTabButton(title: 'Telefone', index: 1),
            // LÓGICA DE EXIBIÇÃO CONDICIONAL DAS ABAS
          if (_tipoPessoa == 'fisica')
            _buildTabButton(title: 'Física', index: 12), // Usando um novo índice

          if (_tipoPessoa != 'fisica')
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
    final theme = Theme.of(context);
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
        backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          foregroundColor: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
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
        12 => _buildAbaFisica(key: const ValueKey('aba12')), // <<< ADICIONE ESTA LINHA
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
  bool isEnabled = true, // ALTERAÇÃO 1: Adicione o novo parâmetro com valor padrão 'true'
}) {
  return Autocomplete<Map<String, dynamic>>(
    displayStringForOption: (option) => option[fieldKey] as String? ?? '',
    optionsBuilder: (textEditingValue) {
      // ALTERAÇÃO 2: Impede a busca se o campo não estiver habilitado
      if (!isEnabled || textEditingValue.text.isEmpty) {
        return const Iterable.empty();
      }
      return _allControlData.where((option) {
        final fieldValue = option[fieldKey]?.toString().toLowerCase() ?? '';
        return fieldValue.contains(textEditingValue.text.toLowerCase());
      });
    },
    onSelected: (selection) {
      final String rgId = selection['id'] as String? ?? '';
      
      setState(() {
        _isFieldSelectedFromDropdown['id'] = true;
        _isFieldSelectedFromDropdown['codigo_interno'] = true;
        _isFieldSelectedFromDropdown['razao_social'] = true;
      });

      _loadRgData(rgId);
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
        // ALTERAÇÃO 3: Controle a propriedade readOnly com base no parâmetro isEnabled
        readOnly: !isEnabled, 
        validator: (value) {
          // ... (a lógica de validação continua a mesma)
          return null; 
        },
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        onChanged: (value) {
          controller.text = value;
          setState(() {
            _isFieldSelectedFromDropdown['id'] = false;
            _isFieldSelectedFromDropdown['codigo_interno'] = false;
            _isFieldSelectedFromDropdown['razao_social'] = false;
          });
          _formKey.currentState?.validate();
        },
      );
    },
  );
}

  Widget _buildAbaDadosGerais({Key? key}) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5), // Cor de fundo da aba
          border: Border.all(color: theme.dividerColor), // Cor da borda
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
                              'id',
                              isRequired: true,
                              validator: _cpfCnpjValidator, // Use the unified validator
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfCnpjFormatter()], // Use the unified formatter
                              maxLength: 18, 
                              //onUserInteraction: () => _setUnsavedChanges(true),
                          )),
                                
                        const SizedBox(width: 10),
                        // ▼▼▼ SUBSTITUA TODO O 'Expanded' DO CAMPO "CÓDIGO" POR ESTE TRECHO ▼▼▼
      Expanded(
        flex: 2,
        child: _buildAutocompleteField(
          _campoComum2Controller,
          "Código",
          'codigo_interno', // A chave para buscar na lista de sugestões
          isEnabled: _isCodigoEditable, // Ligando o estado de edição à nossa variável!
        ),
      ),
      // ▲▲▲ FIM DA SUBSTITUIÇÃO ▲▲▲
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'razao_social')),
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
    flex: 2, // Dando um pouco mais de espaço
    child: CustomInputField(
      controller: _tipoPessoaController,
      label: "Tipo Pessoa",
      readOnly: true,
      //fillColor: Colors.grey[300], // Cor para indicar que é desabilitado
    ),
  ),
  const SizedBox(width: 10),
                /*Expanded(
                    flex: 1,
                    child:
                        CustomInputField(controller: _codigoGeradoController, label: "Código Gerado", readOnly: true,)),*/
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
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

  // Substitua o método _buildAbaFisica inteiro por este:
// Substitua completamente o seu método _buildAbaFisica por este:

Widget _buildAbaFisica({Key? key}) {
  return _buildAbaContainer(
    key: key,
    color: Colors.blue[100]!,
    title: "Dados Pessoa Física",
    children: [
      Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomInputField(
              controller: _estadoCivilController,
              label: "Estado Civil",
              maxLength: 20,
              suffixText: '${_estadoCivilController.text.length}/20',
              onUserInteraction: () => _setUnsavedChanges(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: CustomInputField(
              controller: _profissaoController,
              label: "Profissão",
              maxLength: 50,
              suffixText: '${_profissaoController.text.length}/50',
              onUserInteraction: () => _setUnsavedChanges(true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomInputField(
              controller: _rgController,
              label: "RG",
              maxLength: 20,
              suffixText: '${_rgController.text.length}/20',
              onUserInteraction: () => _setUnsavedChanges(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: CustomInputField(
              controller: _dataExpedicaoController,
              label: "Data Expedição",
              // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                DateInputFormatterDDMMYYYY(), // Usando o NOVO formatador
              ],
              hintText: 'dd/mm/aaaa',
              onUserInteraction: () => _setUnsavedChanges(true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomInputField(
              controller: _dataNascimentoController,
              label: "Data Nascimento",
              // ▼▼▼ ALTERAÇÃO AQUI ▼▼▼
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                DateInputFormatterDDMMYYYY(), // Usando o NOVO formatador
              ],
              hintText: 'dd/mm/aaaa',
              onUserInteraction: () => _setUnsavedChanges(true),
            ),
          ),
          // Espaço para alinhar com o botão de salvar
          const Expanded(flex: 1, child: SizedBox()),
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
  // Modificado para aceitar maxLengh e inputFormatters
  DataCell _buildEditableCell(
    String subcollection, Map<String, dynamic> docData, String field, String initialValue, String uniqueRowId,
  {int? maxLength, List<TextInputFormatter>? inputFormatters}) {
    
    final docId = docData['id'].toString();
    final isEditing =
      _editingCell != null && _editingCell!['docId'] == uniqueRowId && _editingCell!['field'] == field;

    return DataCell(
      isEditing
          ? TextField(
              controller: _cellEditController,
              focusNode: _cellFocusNode,
              autofocus: true,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              onSubmitted: (newValue) {
                // CORREÇÃO NA CHAMADA
                _updateSubcollectionField(subcollection, docData, field, newValue);
                setState(() { _editingCell = null; });
              },
              onTapOutside: (_) {
                // CORREÇÃO NA CHAMADA
                _updateSubcollectionField(subcollection, docData, field, _cellEditController.text);
                if (mounted) {
                  setState(() { _editingCell = null; });
                }
              },
            )
          : SizedBox(
              width: _getColumnWidth(field),
              child: Text(initialValue, overflow: TextOverflow.ellipsis)),
      onTap: () {
    setState(() {
      _editingCell = {'docId': uniqueRowId, 'field': field};
      // Pega o valor original (o ID) do mapa de dados, em vez do valor de exibição.
      _cellEditController.text = docData[field]?.toString() ?? ''; // <-- LINHA CORRIGIDA
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
    final theme = Theme.of(context);
    return Form(
      child: Padding(
        key: key,
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
        child: Container(
          decoration: BoxDecoration(
            //color: Colors.blue[100],
            color: theme.colorScheme.surface.withOpacity(0.5), // Cor de fundo da aba
          border: Border.all(color: theme.dividerColor), // Cor da borda
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
                                  _campoComum1Controller, "CPF/CNPJ", 'id',
                                  isRequired: true)),
                          const SizedBox(width: 10),
                          Expanded(
                              flex: 2,
                              child: _buildAutocompleteField(_campoComum2Controller, "Código", 'codigo_interno')),
                          const SizedBox(width: 10),
                          Expanded(
                              flex: 3,
                              child: _buildAutocompleteField(
                                  _campoComum3Controller, "Razao Social", 'razao_social')),
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
                        child: _buildPaisAutocomplete(
    onUserInteraction: () => _checkSubcollectionInputChanges(),
  )),
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
                
                
// ▼▼▼ SUBSTITUA TODO ESTE BLOCO 'Builder' ▼▼▼
Builder(
  builder: (context) {
    final telefones = _rgData?['telefones'] as List<dynamic>? ?? [];
    final theme = Theme.of(context); // Pega o tema atual

    if (_campoComum1Controller.text.trim().isEmpty && !_isLoading) {
      return const Center(child: Text("Busque por um CPF/CNPJ para ver os telefones."));
    }
    if (_isLoading && telefones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (telefones.isEmpty) {
      return const Center(child: Text("Nenhum telefone cadastrado para esta empresa."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all<Color>(theme.primaryColor.withOpacity(0.2)),
        border: TableBorder.all(color: theme.dividerColor),
        columns: const [
          DataColumn(label: Text('SQ')),
          DataColumn(label: Text('País')),
          DataColumn(label: Text('Operadora')),
          DataColumn(label: Text('DDD')),
          DataColumn(label: Text('Número')),
          DataColumn(label: Text('Ramal')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Contato')),
          DataColumn(label: Text('Ação')),
        ],
        // ALTERAÇÃO PRINCIPAL: Usando List.generate para obter o índice de forma segura
        rows: List.generate(telefones.length, (index) {
          final data = telefones[index] as Map<String, dynamic>;
          final uniqueRowId = data['id'].toString();

          // Lógica para traduzir o ID do país para o nome
          final paisId = data['pais']?.toString() ?? '';
          final paisMap = _allPaises.firstWhere((p) => p['id']?.toString() == paisId, orElse: () => {});
          final paisDisplayText = paisMap['nome']?.toString() ?? paisId;
          
          // Define a cor da linha com base no índice (par ou ímpar)
          final Color rowColor = index.isEven 
              ? theme.colorScheme.surface.withOpacity(0.5) 
              : Colors.transparent;

          return DataRow(
            color: MaterialStateProperty.all(rowColor),
            cells: [
              _buildEditableCell('telefones', data, 'sequencia', data['sequencia']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('telefones', data, 'pais', paisDisplayText, uniqueRowId),
              _buildEditableCell('telefones', data, 'operadora', data['operadora']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('telefones', data, 'ddd', data['ddd']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('telefones', data, 'numero', data['numero']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('telefones', data, 'ramal', data['ramal']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('telefones', data, 'tipo', data['tipo']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('telefones', data, 'contato', data['contato']?.toString() ?? '', uniqueRowId),
              DataCell(IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteSubItem(uniqueRowId, 'telefones'),
              )),
            ],
          );
        }),
      ),
    );
  },
),
// ▲▲▲ FIM DO BLOCO DE SUBSTITUIÇÃO ▲▲▲
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbaJuridica({Key? key}) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5), // Cor de fundo da aba
          border: Border.all(color: theme.dividerColor), // Cor da borda
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
                                _campoComum1Controller, "CPF/CNPJ", 'id',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'codigo_interno')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'razao_social')),
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
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5), // Cor de fundo da aba
          border: Border.all(color: theme.dividerColor), // Cor da borda
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
                                _campoComum1Controller, "CPF/CNPJ", 'id',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'codigo_interno')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'razao_social')),
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
        Builder(
  builder: (context) {
    final socios = _rgData?['socios'] as List<dynamic>? ?? [];
    final theme = Theme.of(context);

    if (_campoComum1Controller.text.trim().isEmpty) {
      return const Center(child: Text("Busque por um CPF/CNPJ para ver os sócios."));
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (socios.isEmpty) {
      return const Center(child: Text("Nenhum sócio cadastrado para esta empresa."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all<Color>(theme.primaryColor.withOpacity(0.2)),
        border: TableBorder.all(color: theme.dividerColor),
        columns: const [
          DataColumn(label: Text('Sq')),
          DataColumn(label: Text('Sócio')),
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('CPF')),
          DataColumn(label: Text('Cargo')),
          DataColumn(label: Text('Participação (%)')),
          DataColumn(label: Text('Ação')),
        ],
        rows: List.generate(socios.length, (index) {
          final data = socios[index] as Map<String, dynamic>;
          final uniqueRowId = data['id'].toString();
          final Color rowColor = index.isEven 
              ? theme.colorScheme.surface.withOpacity(0.5) 
              : Colors.transparent;

          return DataRow(
            color: MaterialStateProperty.all(rowColor),
            cells: [
              _buildEditableCell('socios', data, 'sequencia', data['sequencia']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('socios', data, 'socio_id', data['socio_id']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('socios', data, 'nome', data['nome']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('socios', data, 'cpf', data['cpf']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('socios', data, 'cargo_id', data['cargo_id']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('socios', data, 'participacao', data['participacao']?.toString() ?? '', uniqueRowId),
              DataCell(IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteSubItem(uniqueRowId, 'socios'),
              )),
            ],
          );
        }),
      ),
    );
  },
),
// ▲▲▲ FIM DA SUBSTITUIÇÃO ▲▲▲
        
      ],
    );
  }

  Widget _buildAbaContainer({Key? key, required Color color, required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5), // Cor de fundo da aba
          border: Border.all(color: theme.dividerColor), // Cor da borda
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
                                _campoComum1Controller, "CPF/CNPJ", 'id',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'codigo_interno')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'razao_social')),
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
              Divider(thickness: 2, color: theme.colorScheme.primary, height: 10, indent: 40, endIndent: 40),
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
        //fillColor: Colors.white,
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
                //fillColor: isResulNomeEditable ? Colors.white : Colors.grey[300], // Cor de fundo para indicar editabilidade
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
        
        // ▼▼▼ SUBSTITUA TODO O BLOCO 'Builder' POR ESTE ▼▼▼
Builder(
  builder: (context) {
    final referencias = _rgData?['referencias_bancarias'] as List<dynamic>? ?? [];
    final theme = Theme.of(context);

    if (_campoComum1Controller.text.trim().isEmpty && !_isLoading) {
      return const Center(child: Text("Busque por um CPF/CNPJ para ver as referências."));
    }
    if (_isLoading && referencias.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (referencias.isEmpty) {
      return const Center(child: Text("Nenhuma referência bancária cadastrada."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all<Color>(theme.primaryColor.withOpacity(0.2)),
        border: TableBorder.all(color: theme.dividerColor),
        columns: const [
          DataColumn(label: Text('Seq.')),
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Endereço')),
          DataColumn(label: Text('Cidade')),
          DataColumn(label: Text('Contato')),
          DataColumn(label: Text('Telefone')),
          DataColumn(label: Text('E-mail')),
          DataColumn(label: Text('Obs.')),
          DataColumn(label: Text('Ação')),
        ],
        rows: List.generate(referencias.length, (index) {
          final data = referencias[index] as Map<String, dynamic>;
          final uniqueRowId = data['id'].toString();
          final Color rowColor = index.isEven 
              ? theme.colorScheme.surface.withOpacity(0.5) 
              : Colors.transparent;
              
          return DataRow(
            color: MaterialStateProperty.all(rowColor),
            cells: [
              _buildEditableCell('referencias-bancarias', data, 'sequencia', data['sequencia']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-bancarias', data, 'nome_banco', data['nome_banco']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-bancarias', data, 'endereco', data['endereco']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-bancarias', data, 'cidade_id', data['cidade_id']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-bancarias', data, 'contato', data['contato']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-bancarias', data, 'telefone', data['telefone']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-bancarias', data, 'email', data['email']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-bancarias', data, 'observacao', data['observacao']?.toString() ?? '', uniqueRowId),
              DataCell(IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteReferenciaBancaria(uniqueRowId),
              )),
            ],
          );
        }),
      ),
    );
  },
),
// ▲▲▲ FIM DA SUBSTITUIÇÃO ▲▲▲
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
                //fillColor: isResulNomeRefComercialEditable ? Colors.white : Colors.grey[300],
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

        
       // ▼▼▼ SUBSTITUA TODO O BLOCO 'Builder' POR ESTE ▼▼▼
Builder(
  builder: (context) {
    final referencias = _rgData?['referencias_comerciais'] as List<dynamic>? ?? [];
    final theme = Theme.of(context);

    if (_campoComum1Controller.text.trim().isEmpty && !_isLoading) {
      return const Center(child: Text("Busque por um CPF/CNPJ para ver as referências."));
    }
    if (_isLoading && referencias.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (referencias.isEmpty) {
      return const Center(child: Text("Nenhuma referência comercial cadastrada."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all<Color>(theme.primaryColor.withOpacity(0.2)),
        border: TableBorder.all(color: theme.dividerColor),
        columns: const [
          DataColumn(label: Text('Seq.')),
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Endereço')),
          DataColumn(label: Text('Cidade')),
          DataColumn(label: Text('Contato')),
          DataColumn(label: Text('Telefone')),
          DataColumn(label: Text('E-mail')),
          DataColumn(label: Text('Obs.')),
          DataColumn(label: Text('Ação')),
        ],
        rows: List.generate(referencias.length, (index) {
          final data = referencias[index] as Map<String, dynamic>;
          final uniqueRowId = data['id'].toString();
          final Color rowColor = index.isEven 
              ? theme.colorScheme.surface.withOpacity(0.5) 
              : Colors.transparent;

          return DataRow(
            color: MaterialStateProperty.all(rowColor),
            cells: [
              _buildEditableCell('referencias-comerciais', data, 'sequencia', data['sequencia']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-comerciais', data, 'nome_empresa', data['nome_empresa']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-comerciais', data, 'endereco', data['endereco']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-comerciais', data, 'cidade_id', data['cidade_id']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-comerciais', data, 'contato', data['contato']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-comerciais', data, 'telefone', data['telefone']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-comerciais', data, 'email', data['email']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('referencias-comerciais', data, 'observacao', data['observacao']?.toString() ?? '', uniqueRowId),
              DataCell(IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteReferenciaComercial(uniqueRowId),
              )),
            ],
          );
        }),
      ),
    );
  },
),
// ▲▲▲ FIM DA SUBSTITUIÇÃO ▲▲▲
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
          //fillColor: readOnly ? Colors.grey[300] : Colors.white,
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
          //fillColor: readOnly ? Colors.grey[300] : Colors.white,
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
          //fillColor: readOnly ? Colors.grey[300] : Colors.white,
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
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5), // Cor de fundo da aba
          border: Border.all(color: theme.dividerColor), // Cor da borda
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
                                _campoComum1Controller, "CPF/CNPJ", 'id',
                                isRequired: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: _buildAutocompleteField(_campoComum2Controller, "Código", 'codigo_interno')),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 3,
                            child: _buildAutocompleteField(
                                _campoComum3Controller, "Razao Social", 'razao_social')),
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
    final theme = Theme.of(context);
    return _buildAbaContainer(
      key: key,
      color: Colors.transparent,
      title: "Endereço cobrança",
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 250, right: 250),
                child: Container(
                  decoration: BoxDecoration(
                     color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                  
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                             Text('Possui Endereço? :',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
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
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                   Text('Sim', style: TextStyle(color: theme.colorScheme.onSurface)),
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
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  Text('Não', style: TextStyle(color: theme.colorScheme.onSurface)),
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
    final theme = Theme.of(context);
    return _buildAbaContainer(
      key: key,
      color: Colors.transparent,
      title: "Correspondência",
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 250, right: 250),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                             Text('Possui Endereço? :',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                        // Checkbox Sim
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
                                    activeColor: theme.colorScheme.primary,

                                  ),
                                  Text('Sim', style: TextStyle(color: theme.colorScheme.onSurface)),
                        // Checkbox Não
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
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  Text('Não', style: TextStyle(color: theme.colorScheme.onSurface)),
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
    final theme = Theme.of(context); // Pega o tema
    return _buildAbaContainer(
      key: key,
      color: Colors.transparent,
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
                    // ▼▼▼ ALTERAÇÃO DE COR ▼▼▼
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                             Text('Possui Endereço? :',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                        // Chec
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
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  Text('Sim', style: TextStyle(color: theme.colorScheme.onSurface)),
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
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  Text('Não', style: TextStyle(color: theme.colorScheme.onSurface)),
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
        
        // Dentro de _buildAbaContatos()

// ▼▼▼ SUBSTITUA TODO O BLOCO 'Builder' POR ESTE ▼▼▼
Builder(
  builder: (context) {
    final contatos = _rgData?['contatos'] as List<dynamic>? ?? [];
    final theme = Theme.of(context);

    if (_campoComum1Controller.text.trim().isEmpty && !_isLoading) {
      return const Center(child: Text("Busque por um CPF/CNPJ para ver os contatos."));
    }
    if (_isLoading && contatos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (contatos.isEmpty) {
      return const Center(child: Text("Nenhum contato cadastrado."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all<Color>(theme.primaryColor.withOpacity(0.2)),
        border: TableBorder.all(color: theme.dividerColor),
        columns: const [
          DataColumn(label: Text('Seq.')),
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Dt. Nasc.')),
          DataColumn(label: Text('Cargo')),
          DataColumn(label: Text('E-mail')),
          DataColumn(label: Text('Obs.')),
          DataColumn(label: Text('Ação')),
        ],
        rows: List.generate(contatos.length, (index) {
          final data = contatos[index] as Map<String, dynamic>;
          final uniqueRowId = data['id'].toString();
          final Color rowColor = index.isEven 
              ? theme.colorScheme.surface.withOpacity(0.5) 
              : Colors.transparent;
              
          final cargoId = data['cargo_id']?.toString() ?? '';
          final cargoMap = _allCargos.firstWhere((c) => c['id']?.toString() == cargoId, orElse: () => {});
          final cargoDisplayText = cargoMap['descricao']?.toString() ?? cargoId;

          return DataRow(
            color: MaterialStateProperty.all(rowColor),
            cells: [
              _buildEditableCell('contatos', data, 'sequencia', data['sequencia']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('contatos', data, 'nome', data['nome']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('contatos', data, 'data_nascimento', data['data_nascimento']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('contatos', data, 'cargo_id', cargoDisplayText, uniqueRowId),
              _buildEditableCell('contatos', data, 'email', data['email']?.toString() ?? '', uniqueRowId),
              _buildEditableCell('contatos', data, 'observacao', data['observacao']?.toString() ?? '', uniqueRowId),
              DataCell(IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteContato(uniqueRowId),
              )),
            ],
          );
        }),
      ),
    );
  },
),
// ▲▲▲ FIM DA SUBSTITUIÇÃO ▲▲▲
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
