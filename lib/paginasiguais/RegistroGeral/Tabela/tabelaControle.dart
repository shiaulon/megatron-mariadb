import 'package:flutter/material.dart';
import 'package:flutter_application_1/reutilizaveis/informacoesInferioresPagina.dart';
import 'package:flutter_application_1/menu.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart'; // Importe para formatar a data
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter

// --- NOVOS FORMATTERS E VALIDATORS ---

// Custom Formatter para Data (dd/MM/yyyy)
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    int offset = 0; // Para ajustar a posição do cursor

    // Remove caracteres não numéricos antes de formatar
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 2 || i == 4) { // Adiciona '/' após o dia e o mês
        newText += '/';
      }
      newText += cleanedText[i];
    }

    // Limita o comprimento total a 10 caracteres (dd/MM/yyyy)
    if (newText.length > 10) {
      newText = newText.substring(0, 10);
    }

    // Ajusta a posição do cursor
    final newSelectionOffset = newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

// Custom Formatter para CEP (#####-###)
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    int offset = 0; // Para ajustar a posição do cursor

    // Remove caracteres não numéricos antes de formatar
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 5) { // Adiciona '-' após 5 dígitos
        newText += '-';
      }
      newText += cleanedText[i];
    }

    // Limita o comprimento total a 9 caracteres (#####-###)
    if (newText.length > 9) {
      newText = newText.substring(0, 9);
    }

    // Ajusta a posição do cursor
    final newSelectionOffset = newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

// Custom Formatter para CNPJ (XX.XXX.XXX/YYYY-ZZ)
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    // Remove caracteres não numéricos antes de formatar
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 2 || i == 5) { // Adiciona '.' após 2 e 5 dígitos
        newText += '.';
      } else if (i == 8) { // Adiciona '/' após 8 dígitos (total de 11 numéricos até aqui)
        newText += '/';
      } else if (i == 12) { // Adiciona '-' após 12 dígitos (total de 16 numéricos até aqui)
        newText += '-';
      }
      newText += cleanedText[i];
    }

    // Limita o comprimento total a 18 caracteres (XX.XXX.XXX/YYYY-ZZ)
    if (newText.length > 18) {
      newText = newText.substring(0, 18);
    }

    // Ajusta a posição do cursor
    final newSelectionOffset = newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

// Custom Formatter para CPF (XXX.XXX.XXX-XX)
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String newText = '';
    // Remove caracteres não numéricos antes de formatar
    String cleanedText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 3 || i == 6) { // Adiciona '.' após 3 e 6 dígitos
        newText += '.';
      } else if (i == 9) { // Adiciona '-' após 9 dígitos
        newText += '-';
      }
      newText += cleanedText[i];
    }

    // Limita o comprimento total a 14 caracteres (XXX.XXX.XXX-XX)
    if (newText.length > 14) {
      newText = newText.substring(0, 14);
    }

    // Ajusta a posição do cursor
    final newSelectionOffset = newValue.selection.baseOffset + newText.length - text.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

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

// Validator para CPF
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

// Validator para UF
String? _ufValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo UF é obrigatório.';
  }
  final List<String> validUFs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
  ];
  if (!validUFs.contains(value.toUpperCase())) {
    return 'UF inválida. Use um formato como SP, RJ, etc.';
  }
  return null;
}

// --- FIM DOS NOVOS FORMATTERS E VALIDATORS ---

class TabelaControle extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Se precisar usar a permissão aqui também

  const TabelaControle({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaControle> createState() => _TabelaControleState();
}

class _TabelaControleState extends State<TabelaControle> {
  // Define o breakpoint para alternar entre layouts
  static const double _breakpoint = 700.0; // Desktop breakpoint

  // GlobalKey para o Form (necessário para validar todos os campos)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // TextEditingController para o campo de texto de lembretes
  final TextEditingController _lembretesController = TextEditingController();
  // Variável para armazenar a data atual formatada
  late String _currentDate;

  // A lista de dados para os botões não será mais usada na tela principal, mas mantenho a classe ButtonData caso seja usada em outro lugar
  

  // Controllers para os novos campos de texto na área central
  final TextEditingController _dataAtualController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _cepController = TextEditingController(); // Adicionado controller para CEP
  final TextEditingController _ufController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _inscricaoEstadualController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _fornecedorController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final TextEditingController _bancoController = TextEditingController();
  final TextEditingController _transportadoraController = TextEditingController();
  final TextEditingController _motoristaController = TextEditingController();
  final TextEditingController _funcionarioController = TextEditingController();
  final TextEditingController _codRgPjTrabalhoController = TextEditingController();
  final TextEditingController _ultimoCadastroController = TextEditingController();
  final TextEditingController _crmChamadaController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController(); // Adicionado controller para CPF

  // Variáveis para os Radio Buttons
  String? _integracaoSelection; // CRM, WEB
  String? _nrgRgErpSelection; // Normal, Par, Impar


  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    

    
    
    // Adiciona listener para o campo Empresa para atualizar o contador
    _empresaController.addListener(_updateEmpresaCounter);
    _enderecoController.addListener(_updateEmpresaCounter);
    _cidadeController.addListener(_updateEmpresaCounter);
    _inscricaoEstadualController.addListener(_updateEmpresaCounter);
    _clienteController.addListener(_updateEmpresaCounter);
    _vendedorController.addListener(_updateEmpresaCounter);
    _bancoController.addListener(_updateEmpresaCounter);
    _transportadoraController.addListener(_updateEmpresaCounter);
    _motoristaController.addListener(_updateEmpresaCounter);
    _fornecedorController.addListener(_updateEmpresaCounter);
    _funcionarioController.addListener(_updateEmpresaCounter);
    _codRgPjTrabalhoController.addListener(_updateEmpresaCounter);
    _ultimoCadastroController.addListener(_updateEmpresaCounter);
    _crmChamadaController.addListener(_updateEmpresaCounter);
  }
  
  

  void _updateEmpresaCounter() {
    // Força a reconstrução do widget para que o suffixText seja atualizado
    setState(() {});
  }

  

  @override
  void dispose() {
    _lembretesController.dispose(); // Descarta o controller

    // Descarte os novos controllers de campo de texto
    _dataAtualController.dispose();
    _empresaController.removeListener(_updateEmpresaCounter); // Remover listener
    _empresaController.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _cepController.dispose(); // Dispose do CEP controller
    _ufController.dispose();
    _cnpjController.dispose();
    _inscricaoEstadualController.dispose();
    _clienteController.dispose();
    _fornecedorController.dispose();
    _vendedorController.dispose();
    _bancoController.dispose();
    _transportadoraController.dispose();
    _motoristaController.dispose();
    _funcionarioController.dispose();
    _codRgPjTrabalhoController.dispose();
    _ultimoCadastroController.dispose();
    _crmChamadaController.dispose();
    _cpfController.dispose(); // Dispose do CPF controller

    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column( // Este Column é o body passado para a TelaBase
        children: [
          TopAppBar(
            onBackPressed: () {
              Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TelaSubPrincipal(
          mainCompanyId: widget.mainCompanyId, // Repassa o ID da empresa principal
          secondaryCompanyId: widget.secondaryCompanyId, // Repassa o ID da empresa secundária
          userRole: widget.userRole, // Repassa o papel do usuário
        ),
      ),
    );
            },
            currentDate: _currentDate,
            // userName: 'MRAFAEL', // Opcional, se quiser sobrescrever o padrão
            // userAvatar: AssetImage('assets/images/another_user.png'), // Opcional
          ),

          // Área de conteúdo principal (flexível, abaixo da barra superior)
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth > _breakpoint) {
                  // Layout para telas largas (Desktop/Tablet)
                  return Column( // Coluna principal da área de conteúdo
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded( // Expande para o restante do espaço vertical
                        child: Row( // Row para menu, área central e lembretes
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Menu Lateral (flex 1)
                            Expanded(
                              flex: 1,
                              child: AppDrawer(
                          parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          userRole: widget.userRole, // Passa
                        ),
                            ),
                            // Área Central: Agora com o retângulo de informações E o título
                            Expanded( // <-- ONDE A MUDANÇA OCORRE: Este Expanded é o pai do título e do container azul
                              flex: 3,
                              child: Column( // Column para empilhar o título e o container
                                crossAxisAlignment: CrossAxisAlignment.start, // Alinha os filhos à esquerda (Text e Padding)
                                children: [
                                  Padding( // Título "Controle"
                                    padding: const EdgeInsets.only(top: 20.0, bottom: 0.0), // Padding vertical
                                    child: Center( // <-- Centraliza o texto APENAS dentro deste Expanded
                                      child: Text(
                                        'Controle', // Título alterado para "Controle"
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded( // O Container azul ocupará o restante do espaço vertical
                                    child: _buildCentralInputArea(), // Chamando a nova área de entrada de dados
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout para telas pequenas (Mobile)
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Título "Controle" centralizado para mobile
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
                          child: Center(
                            child: Text(
                              'Controle', // Título alterado para "Controle"
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        AppDrawer(parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          userRole: widget.userRole,),
                        _buildCentralInputArea(), // Área de entrada de dados abaixo do menu
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  

  

  

  
Set<String> _integracaoSelections = {};
  // NOVO MÉTODO: Constrói a área central com campos de entrada de dados
  Widget _buildCentralInputArea() {
    return Form( // Envolve toda a área de entrada de dados com um Form
      key: _formKey, // Atribui a GlobalKey ao Form
      child: Padding(
        padding: const EdgeInsets.all(25), // Padding ao redor do retângulo
        child: Container(
          padding: const EdgeInsets.all(0.0), // Padding interno do container azul
          decoration: BoxDecoration(
            color: Colors.blue[100], // Fundo azul claro
            border: Border.all(color: Colors.black, width: 1.0), // Borda preta
            borderRadius: BorderRadius.circular(10.0), // Cantos arredondados
          ),
          child: SingleChildScrollView( // Para permitir rolagem se os campos forem muitos
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Data Atual, Empresa
                Padding(
                  padding: const EdgeInsets.only(left: 25,right: 25,top: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          controller: _dataAtualController,
                          label: 'Data Atual',
                          readOnly: false, // Permite edição para demonstração do formatter
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            DateInputFormatter(), // Adiciona barras automaticamente
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            // Validação básica do formato dd/MM/yyyy
                            if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value) || value.length != 10) {
                              return 'Formato de data inválido (DD/MM/AAAA)';
                            }
                            return null;
                          },
                          hintText: 'DD/MM/AAAA', // Adiciona hintText para data
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: CustomInputField(
                          controller: _empresaController,
                          label: 'Empresa',
                          maxLength: 35, // Máximo de 40 caracteres
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            if (value.length > 35) {
                              return 'Máximo de 35 caracteres';
                            }
                            return null;
                          },
                          // Adiciona LengthLimitingTextInputFormatter para controlar o tamanho
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(35),
                          ],
                          // O suffixText será atualizado pelo listener no controller
                          suffixText: '${_empresaController.text.length}/35',
                          hintText: 'Máx. 35 caracteres', // Adiciona hintText para empresa
                        ),
                      ),
                    ],
                  ),
                ),
                // Linha 2: Endereço, Cidade, CEP, UF
                Padding(
                  padding: const EdgeInsets.only(left: 25,right: 25),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: CustomInputField(controller: _enderecoController, label: 'Endereço',maxLength: 35,suffixText: '${_enderecoController.text.length}/35',validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                      },)),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: CustomInputField(controller: _cidadeController, label: 'Cidade',maxLength: 15,suffixText: '${_cidadeController.text.length}/15',validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                      },)),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: CustomInputField(
                          controller: _cepController,
                          label: 'CEP',
                          keyboardType: TextInputType.number,
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
                          hintText: '#####-###', // Adiciona hintText para CEP
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 70, // Largura fixa para UF
                        child: CustomInputField(
                          controller: _ufController,
                          label: 'UF',
                          maxLength: 2, // UF tem 2 caracteres
                          textCapitalization: TextCapitalization.characters, // Capitaliza automaticamente
                          validator: _ufValidator, // Aplica o validador de UF
                          hintText: 'Máx. 2 caracteres', // Adiciona hintText para UF
                        ),
                      ),
                    ],
                  ),
                ),
                // Linha 3: CNPJ, Inscr. Estadual
                Padding(
                  padding: const EdgeInsets.only(left: 25.0,right: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          controller: _cnpjController,
                          label: 'CNPJ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            CnpjInputFormatter(), // Adiciona pontos, barra e hífen automaticamente
                          ],
                          validator: _cnpjValidator, // Aplica o validador de CNPJ
                          hintText: 'XX.XXX.XXX/YYYY-ZZ', // Adiciona hintText para CNPJ
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: CustomInputField(controller: _inscricaoEstadualController, label: 'Inscr. Estadual',maxLength: 15,suffixText: '${_inscricaoEstadualController.text.length}/15',validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                      },)),
                    ],
                  ),
                ),
                // Adicionado campo CPF
                /*Padding(
                  padding: const EdgeInsets.only(left: 25.0, right: 25),
                  child: _buildInputField(
                    controller: _cpfController,
                    label: 'CPF',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                      CpfInputFormatter(), // Adiciona pontos e hífen automaticamente
                    ],
                    validator: _cpfValidator, // Aplica o validador de CPF
                    hintText: 'XXX.XXX.XXX-XX', // Adiciona hintText para CPF
                  ),
                ),*/
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: const Divider(height: 20, thickness: 3, color: Colors.blue,),
                ),
                Center(child: Text('Natureza', style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),
                // Linha 4: Cliente, Fornecedor, Vendedor, Banco (ajustado para 4 campos)
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(child: CustomInputField(controller: _clienteController,inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                  ], label: 'Cliente',maxLength: 2,keyboardType: TextInputType.number,suffixText: '${_clienteController.text.length}/2',)),
                    const SizedBox(width: 10),
                    Expanded(child: CustomInputField(controller: _fornecedorController, label: 'Fornecedor',inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                  ],maxLength: 2,keyboardType: TextInputType.number,suffixText: '${_fornecedorController.text.length}/2',)),
                    const SizedBox(width: 10,),
                    Expanded(child: CustomInputField(controller: _vendedorController, label: 'Vendedor',inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                  ],maxLength: 2,keyboardType: TextInputType.number,suffixText: '${_vendedorController.text.length}/2',)),
                    const SizedBox(width: 10),
                    Expanded(child: CustomInputField(controller: _bancoController, label: 'Banco',inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                  ],maxLength: 2,keyboardType: TextInputType.number,suffixText: '${_bancoController.text.length}/2',)),
                    const SizedBox(width: 40),
                  ],
                ),
                // Linha 6: Transportadora, Motorista, Funcionário
                Row(
                  children: [
                    const SizedBox(width: 100),
                    Expanded(child: CustomInputField(controller: _transportadoraController, label: 'Transportadora',inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                  ],maxLength: 2,keyboardType: TextInputType.number,suffixText: '${_transportadoraController.text.length}/2',)),
                    const SizedBox(width: 10),
                    Expanded(child: CustomInputField(controller: _motoristaController, label: 'Motorista',inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                  ],maxLength: 2,keyboardType: TextInputType.number,suffixText: '${_motoristaController.text.length}/2',)),
                    const SizedBox(width: 10,),
                    Expanded(child: CustomInputField(controller: _funcionarioController, label: 'Funcionário',inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                  ],maxLength: 2,keyboardType: TextInputType.number,suffixText: '${_funcionarioController.text.length}/2',)),
                    const SizedBox(width: 100),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: const Divider(height: 20, thickness: 3, color: Colors.blue,),
                ),
                // Linha 8: Cod RG Pj/Trabalho, Último Cadastro, CRM Chamada
                Padding(
                  padding: const EdgeInsets.only(left: 25,right: 25),
                  child: Row(
                    children: [
                      Expanded(child: CustomInputField(controller: _codRgPjTrabalhoController, label: 'Cod RG Pj/Trabalho',inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                    ],maxLength: 5,keyboardType: TextInputType.number,suffixText: '${_codRgPjTrabalhoController.text.length}/5',)),
                      const SizedBox(width: 80),
                      Expanded(child: CustomInputField(controller: _ultimoCadastroController, label: 'Último Cadastro',inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                    ],maxLength: 5,keyboardType: TextInputType.number,suffixText: '${_ultimoCadastroController.text.length}/5',)),
                      const SizedBox(width: 80),
                      Expanded(child: CustomInputField(controller: _crmChamadaController, label: 'CRM Chamada',inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                    ],maxLength: 9,keyboardType: TextInputType.number,suffixText: '${_crmChamadaController.text.length}/9',)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10), // Espaçamento antes dos rádios

                // ... (código anterior)

                // Integração e NRG RG ERP na mesma linha com rádios verticais e alturas iguais
                IntrinsicHeight( // Garante que a altura das colunas filhas seja a mesma
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Faz com que as colunas se estiquem para a altura máxima
                    children: [
                      const SizedBox(width: 100), // Mantém o espaçamento lateral
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                  const Text('Integração:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                  // Removido SizedBox(width: 16) para compactar mais, você pode ajustar
                                  Expanded( // <-- O Expanded é importante para dar espaço aos CheckboxListTile
                                    child: Column( // Column para empilhar os CheckboxListTile
                                      crossAxisAlignment: CrossAxisAlignment.start, // Alinha os CheckboxListTile à esquerda
                                      mainAxisAlignment: MainAxisAlignment.center, // Centraliza os checkboxes na coluna
                                      children: [
                                        CheckboxListTile(
                                          title: const Text('CRM', style: TextStyle(color: Colors.black)),
                                          value: _integracaoSelections.contains('CRM'),
                                          checkboxShape: CircleBorder(),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _integracaoSelections.add('CRM');
                                              } else {
                                                _integracaoSelections.remove('CRM');
                                              }
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          activeColor: Colors.black,
                                          checkColor: Colors.white,
                                          controlAffinity: ListTileControlAffinity.leading, // Força o checkbox para a esquerda
                                        ),
                                        CheckboxListTile(
                                          title: const Text('WEB', style: TextStyle(color: Colors.black)),
                                          value: _integracaoSelections.contains('WEB'),
                                          checkboxShape: CircleBorder(),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _integracaoSelections.add('WEB');
                                              } else {
                                                _integracaoSelections.remove('WEB');
                                              }
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          activeColor: Colors.black,
                                          checkColor: Colors.white,
                                          controlAffinity: ListTileControlAffinity.leading, // Força o checkbox para a esquerda
                                        ),
                                      ],
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
                                      SizedBox(width: 130,),

                      Center(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      
                      onPressed: () {
                        // Valida todos os campos do formulário
                        if (_formKey.currentState?.validate() ?? false) {
                          // Todos os campos são válidos, prossiga com o salvamento
                          print('--- Dados Salvos ---');
                          print('Data Atual: ${_dataAtualController.text}');
                          print('Empresa: ${_empresaController.text}');
                          print('Endereço: ${_enderecoController.text}');
                          print('Cidade: ${_cidadeController.text}');
                          print('CEP: ${_cepController.text}');
                          print('UF: ${_ufController.text}');
                          print('CNPJ: ${_cnpjController.text}');
                          print('Inscrição Estadual: ${_inscricaoEstadualController.text}');
                          print('Cliente: ${_clienteController.text}');
                          print('Fornecedor: ${_fornecedorController.text}');
                          print('Vendedor: ${_vendedorController.text}');
                          print('Banco: ${_bancoController.text}');
                          print('Transportadora: ${_transportadoraController.text}');
                          print('Motorista: ${_motoristaController.text}');
                          print('Funcionário: ${_funcionarioController.text}');
                          print('Cod RG Pj/Trabalho: ${_codRgPjTrabalhoController.text}');
                          print('Último Cadastro: ${_ultimoCadastroController.text}');
                          print('CRM Chamada: ${_crmChamadaController.text}');
                          print('CPF: ${_cpfController.text}');
                          print('Integração: ${_integracaoSelection ?? 'Nenhum selecionado'}');
                          print('Nrg RG ERP: ${_nrgRgErpSelection ?? 'Nenhum selecionado'}');
                        } else {
                          // Exibe uma mensagem ou snackbar indicando erros de validação
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, corrija os erros nos campos antes de salvar.')),
                          );
                        }
                      },
                      
                      style: ElevatedButton.styleFrom(
                        side: BorderSide(
                  width: 1.0,
                  color: Colors.black,
                ),
                        backgroundColor: Colors.green, // Cor de fundo do botão
                        foregroundColor: Colors.black, // Cor do texto
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text('SALVAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                SizedBox(width: 130,),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.blue, width: 2.0),
                              color: const Color.fromARGB(255, 153, 205, 248),// Cor de fundo do container NRG RG ERP
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0), // Padding interno para o conteúdo
                              child: Row( // <-- Voltando para Row para manter o texto 'Nrg RG ERP' ao lado
                                crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente o conteúdo da Row
                                children: [
                                  const Text('Nrg RG ERP:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)), // Título corrigido
                                  // Removido SizedBox(width: 16) para compactar mais, você pode ajustar
                                  Expanded( // <-- O Expanded é importante para dar espaço aos RadioListTile
                                    child: Column( // Column para empilhar os RadioListTile
                                      crossAxisAlignment: CrossAxisAlignment.start, // Alinha os RadioListTile à esquerda
                                      mainAxisAlignment: MainAxisAlignment.center, // Centraliza os rádios na coluna
                                      children: [
                                        RadioListTile<String>(
                                          title: const Text('Normal', style: TextStyle(color: Colors.black)),
                                          value: 'Normal',
                                          groupValue: _integracaoSelection,
                                          onChanged: (String? value) {
                                            setState(() {
                                              _integracaoSelection = value;
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero, // Remove o padding extra para compactar
                                          activeColor: Colors.black,
                                        ),
                                        RadioListTile<String>(
                                          title: const Text('Par', style: TextStyle(color: Colors.black)),
                                          value: 'Par',
                                          groupValue: _integracaoSelection,
                                          onChanged: (String? value) {
                                            setState(() {
                                              _integracaoSelection = value;
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero, // Remove o padding extra para compactar
                                          activeColor: Colors.black,
                                        ),
                                        RadioListTile<String>(
                                          title: const Text('Ímpar', style: TextStyle(color: Colors.black)),
                                          value: 'ìmpar',
                                          groupValue: _integracaoSelection,
                                          onChanged: (String? value) {
                                            setState(() {
                                              _integracaoSelection = value;
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero, // Remove o padding extra para compactar
                                          activeColor: Colors.black,
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
                      const SizedBox(width: 100),
                      
                    ],
                  ),
                ),

// ... (restante do código)

                const SizedBox(height: 20), // Espaçamento antes do botão SALVAR
                //BottomInfoContainers(tablePath: 'Tabela > Controle'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}
