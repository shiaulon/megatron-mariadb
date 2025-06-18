// lib/tabela_estado_imposto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart'; // Para formatar a data

// Importar os componentes reutilizáveis
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/informacoesInferioresPagina.dart';


//Validator para UF
String? _ufValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O campo é obrigatório.';
  }
  final List<String> validUFs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO', 'EX'
  ];
  if (!validUFs.contains(value.toUpperCase())) {
    return 'UF inválida. Use um formato como SP, RJ, etc.';
  }
  
  return null;

}




class PercentageInputFormatter4CasasDecimais extends TextInputFormatter {
  final int decimalDigits = 4; // Casas decimais fixas

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newTextCleaned = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Caso de texto vazio ou apenas zeros
    if (newTextCleaned.isEmpty) {
      return TextEditingValue.empty;
    }

    // Se o usuário digitou apenas zeros e não há outros dígitos, pode ser "0,0000"
    if (int.tryParse(newTextCleaned) == 0) {
      return const TextEditingValue(
        text: '0,0000',
        selection: TextSelection.collapsed(offset: 6), // Cursor no final
      );
    }

    String formattedText;
    int newCursorOffset;

    // Garante que a string limpa tenha pelo menos o número de dígitos decimais
    // para que a vírgula possa ser inserida corretamente da direita para a esquerda.
    // Ex: "1" -> "0001", "12" -> "0012", "123" -> "0123", "1234" -> "1234"
    String tempCleanedText = newTextCleaned.padLeft(decimalDigits, '0');

    // A vírgula sempre será inserida 'decimalDigits' posições da direita para a esquerda.
    // Se a string tem menos que 'decimalDigits' + 1, significa que a parte inteira é '0'
    if (tempCleanedText.length <= decimalDigits) {
        formattedText = '0,$tempCleanedText'; // Ex: "0,0001", "0,0012", "0,0123", "0,1234"
    } else {
        // Divide a string em parte inteira e parte decimal
        int integerPartLength = tempCleanedText.length - decimalDigits;
        String integerPart = tempCleanedText.substring(0, integerPartLength);
        String decimalPart = tempCleanedText.substring(integerPartLength);

        // Remove zeros à esquerda da parte inteira, a menos que seja apenas "0"
        if (integerPart.length > 1 && integerPart.startsWith('0')) {
             integerPart = integerPart.substring(1); // Ex: "01" vira "1"
        }
        if (integerPart.isEmpty) integerPart = '0'; // Garante que não fique vazio se virar "0"

        formattedText = '$integerPart,$decimalPart';
    }


    // --- Ajuste da Posição do Cursor ---
    // A lógica mais simples e robusta para este tipo de formatador
    // é manter o cursor sempre no final.
    // Se o usuário precisa editar no meio, a experiência pode ser prejudicada,
    // mas tentar calcular posições intermediárias com preenchimento de zero e vírgula
    // é extremamente complexo e propenso a bugs visuais.
    newCursorOffset = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}

class TabelaCidade extends StatefulWidget {
  const TabelaCidade({super.key});

  @override
  State<TabelaCidade> createState() => _TabelaCidadeState();
}

class _TabelaCidadeState extends State<TabelaCidade> {
  static const double _breakpoint = 700.0; // Desktop breakpoint

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _currentDate;

  // Controllers para os campos da tela "Estado X Imposto"
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _abreviadoController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _issController = TextEditingController();
  final TextEditingController _tabelaIBGEController = TextEditingController();
  
  // Variável para controlar se o campo 'País' é somente leitura
  bool _paisReadOnly = true; // Inicia como true (desabilitado)

  // Variáveis para os Radio Buttons (Sim/Não para Cálculo DIFAL Dentro)
  bool? _cartorio = false; // Valor inicial para "Não"

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _codigoController.addListener(_updateFieldCounters);
    _cidadeController.addListener(_updateFieldCounters);
    _abreviadoController.addListener(_updateFieldCounters);
    _estadoController.addListener(_onEstadoChanged); // Adiciona o listener aqui
    _paisController.addListener(_updateFieldCounters);
    _issController.addListener(_updateFieldCounters);
    _tabelaIBGEController.addListener(_updateFieldCounters);
    
    // O campo País deve começar vazio, mas desativado (cinza)
    _paisController.text = ''; 
    _paisReadOnly = true; // Já está assim, mas explicitando.
  }

  void _onEstadoChanged() {
    setState(() {
      final String estado = _estadoController.text.toUpperCase();
      final List<String> ufsBrasileiras = [
        'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
        'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
        'SP', 'SE', 'TO'
      ];

      if (estado == 'EX') {
        _paisController.text = ''; // Limpa o campo para o usuário digitar
        _paisReadOnly = false; // Ativa o campo (ficará branco)
      } else if (ufsBrasileiras.contains(estado)) {
        _paisController.text = 'Brasil';
        _paisReadOnly = true; // Mantém o campo ineditável (ficará cinza)
      } else {
        _paisController.text = ''; // Limpa se for algo diferente de EX ou UF
        _paisReadOnly = true; // Desativa (ficará cinza)
      }
    });
    _updateFieldCounters(); // Para atualizar o suffixText se necessário
  }

  void _updateFieldCounters() {
    setState(() {
      // Força a reconstrução para atualizar o suffixText dos CustomInputField
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _cidadeController.dispose();
    _abreviadoController.dispose();
    _estadoController.removeListener(_onEstadoChanged); // Remove o listener
    _estadoController.dispose();
    _issController.dispose();
    _paisController.dispose();
    _tabelaIBGEController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        children: [
          TopAppBar(
            onBackPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TelaSubPrincipal()),);
            },
            currentDate: _currentDate,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth > _breakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AppDrawer(
                                parentMaxWidth: constraints.maxWidth,
                                breakpoint: _breakpoint,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 20.0, bottom: 0.0),
                                    child: Center(
                                      child: Text(
                                        'Cidade',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCentralInputArea(),
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
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
                          child: Center(
                            child: Text(
                              'Cidade',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        AppDrawer(
                            parentMaxWidth: constraints.maxWidth,
                            breakpoint: _breakpoint),
                        _buildCentralInputArea(),
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

  Widget _buildCentralInputArea() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(0.0), // Remove o padding externo
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          // UM ÚNICO SingleChildScrollView para toda a área de conteúdo que rola
          child: Column( // A coluna que contém todo o conteúdo rolante e fixo
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded( // Este Expanded empurra o conteúdo fixo para baixo
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 15, bottom: 0), // Padding interno para o conteúdo rolante
                  child: Column( // Coluna para organizar todos os elementos que devem rolar
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      
                      SizedBox(height: 5,),
                      // Linha que conterá as duas colunas ICMS e ST
                      Padding(
                        padding: const EdgeInsets.only(right: 8,left: 8),
                        child: IntrinsicHeight( // Permite que as colunas dentro do Row tenham a mesma altura
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start, // Alinha o topo das colunas
                            children: [
                              // Coluna ICMS
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    const SizedBox(height: 50),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _codigoController,
                                        label: 'Código',
                                        maxLength: 5,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }},
                                       suffixText: '${_codigoController.text.length}/5',
                                       // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _cidadeController,
                                        label: 'Cidade',
                                        maxLength: 35,
                                        validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }},
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       suffixText: '${_cidadeController.text.length}/35',
                                       // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _abreviadoController,
                                        label: 'Abreviado',
                                        maxLength: 15,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       suffixText: '${_abreviadoController.text.length}/15',
                                       // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _estadoController,
                                        label: 'Estado',
                                        maxLength: 2,
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))], // Permite apenas letras para UF
                                        textCapitalization: TextCapitalization.characters, // Garante que seja maiúsculo
                                        suffixText: '${_estadoController.text.length}/2',
                                        validator: _ufValidator,
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                
                                    
                                    const SizedBox(height: 10),


                                    
                                
                                  ],
                                ),
                              ),
                          
                              // Divisor Vertical
                              const VerticalDivider(width: 60, thickness: 2, color: Colors.blue),
                          
                              // Coluna ST - Substituição Tributária ICMS
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    const SizedBox(height: 50),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _paisController,
                                        label: 'País',
                                        maxLength: 3, // Aumentado para "Brasil" ou outros nomes
                                        keyboardType: TextInputType.text, // Mudado para texto
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                                        validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }},
                                        readOnly: _paisReadOnly, // Aplica a propriedade readOnly
                                        // AQUI ESTÁ A LÓGICA CONDICIONAL: Branco se habilitado, Cinza se desabilitado
                                        fillColor: _paisReadOnly ? const Color.fromARGB(255, 168, 155, 155) : Colors.white, 
                                        suffixText: '${_paisController.text.length}/3',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _issController,
                                        label: 'ISS',
                                        maxLength: 4,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_issController.text.length}/4',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _tabelaIBGEController,
                                        label: 'Tabela IBGE',
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        maxLength: 7,
                                        validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                  if (value.length != 7) {
                                    return 'A sigla deve ter exatamente 7 caracteres/dígitos.';
                                  }
                                  return null;
                            },
                            
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_tabelaIBGEController.text.length}/7',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    const SizedBox(height: 10),


                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                                                        const Text('Cartório :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
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
                                                      value: _cartorio == true,
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          _cartorio = value;
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
                                                      value: _cartorio == false, // Condição para "Não"
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          _cartorio = !(value ?? false);
                                                        });
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
                                        const SizedBox(width: 250),
                                      ],
                                    ),
                                      
                                    
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40,),
                      // Botões de Ação - nao mais FIXOS na parte inferior da área central
                      
                      
                    ],
                  ),
                ),
              ),

              // Botões de Ação - FIXOS na parte inferior da área central
              

              // Informações Inferiores - FIXAS na parte inferior da área central
              const SizedBox(height: 0),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton('EXCLUIR', Colors.red),
                        const SizedBox(width: 30),
                        _buildActionButton('SALVAR', Colors.green),
                        const SizedBox(width: 30),
                        _buildActionButton('RELATÓRIO', Colors.yellow),
                        
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
              /// SE QUISER COLOCAR A BARRA INFERIOR FIXA, COLOCA AQUI
              //////////////////////////////////////////////////////////////////////////////////////////////////////////////
              //BottomInfoContainers(tablePath: 'Tabela > Estado X Imposto'),
            ],
          ),
        ),
      ),
    );
  }

  // Novo método auxiliar para construir CustomInputField com o círculo 'H'
  

  // Função auxiliar para construir botões de ação
  Widget _buildActionButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          print('Botão $text pressionado. Formulário válido.');
          _printFormValues();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, corrija os erros nos campos antes de prosseguir.')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(200, 50),
        side: const BorderSide(width: 1.0, color: Colors.black),
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _printFormValues() {
    print('--- Dados do Formulário Estado X Imposto ---');
    print('Estado Origem: ${_codigoController.text}');
    print('Estado Destino: ${_estadoController.text}');
    print('Aliq. Interestadual: ${_cidadeController.text}');
    print('Aliq. Interna - DIFAL: ${_abreviadoController.text}');
    print('Desc. Diferença ICMS Revenda: ${_paisController.text}');
    print('Desc. Diferença ICMS Outros: ${_issController.text}');
    print('Cálculo DIFAL Dentro: ${_cartorio == true ? 'Sim' : 'Não'}');
    print('Aliq. ICMS Substituição: ${_tabelaIBGEController.text}');
    
    print('------------------------------------------');
  }
}