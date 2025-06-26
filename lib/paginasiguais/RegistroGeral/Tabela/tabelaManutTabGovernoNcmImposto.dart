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
//import 'package:flutter_application_1/reutilizaveis/informacoesInferioresPagina.dart';

class ManutInputFormatter extends TextInputFormatter {
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
      if (i == 2 || i == 5) { // Adiciona '/' após o dia e o mês
        newText += '.';
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


class TabelaManutTabGovNcmImposto extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Se precisar usar a permissão aqui também

  const TabelaManutTabGovNcmImposto({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaManutTabGovNcmImposto> createState() => _TabelaManutTabGovNcmImpostoState();
}

class _TabelaManutTabGovNcmImpostoState extends State<TabelaManutTabGovNcmImposto> {
  static const double _breakpoint = 700.0; // Desktop breakpoint

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _currentDate;

  // Controllers para os campos da tela "Estado X Imposto"
  final TextEditingController _ncmController = TextEditingController();
  final TextEditingController _exController = TextEditingController();
  final TextEditingController _tabelaController = TextEditingController();
  final TextEditingController _federalNacionalController = TextEditingController();
  final TextEditingController _federalImportadoController = TextEditingController();
  final TextEditingController _estadualController = TextEditingController();
  final TextEditingController _totalNacionalController = TextEditingController();
  final TextEditingController _municipalController = TextEditingController();
  final TextEditingController _totalImportadoController = TextEditingController();
  
   // Inicia como true (desabilitado)

  // Variáveis para os Radio Buttons (Sim/Não para Cálculo DIFAL Dentro)
  bool? _cartorio = false; // Valor inicial para "Não"

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    

    _ncmController.addListener(_updateFieldCounters);
    _exController.addListener(_updateFieldCounters);
    _tabelaController.addListener(_updateFieldCounters);
    _federalNacionalController.addListener(_updateFieldCounters);
    _federalImportadoController.addListener(_updateFieldCounters);
    _estadualController.addListener(_updateFieldCounters);
    _totalNacionalController.addListener(_updateFieldCounters);
    _municipalController.addListener(_updateFieldCounters);
    _totalImportadoController.addListener(_updateFieldCounters);
    
    // O campo País deve começar vazio, mas desativado (cinza)
    
    
  }

  

  void _updateFieldCounters() {
    setState(() {
      // Força a reconstrução para atualizar o suffixText dos CustomInputField
    });
  }

  @override
  void dispose() {
    _ncmController.dispose();
    _exController.dispose();
    _tabelaController.dispose();
    _federalNacionalController.dispose();
    _federalImportadoController.dispose();
    _estadualController.dispose();
    _totalNacionalController.dispose();
    _municipalController.dispose();
    _totalImportadoController.dispose();
    
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
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
    );            },
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
                              child: AppDrawer(parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          userRole: widget.userRole,
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
                                        'Manut Tab Governo NCM Imposto',
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
                              'Manut Tab Governo NCM Imposto',
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
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          userRole: widget.userRole,),
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
                                        controller: _ncmController,
                                        label: 'NCM',
                                        maxLength: 10,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                          ],                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }if (value.length != 10) {
                                                        return 'A sigla deve ter exatamente 10 dígitos.';
                                                }
                                                return null;
                                
                            },
                                       suffixText: '${_ncmController.text.length}/10',
                                       // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _exController,
                                        label: 'Ex',
                                        maxLength: 1,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                          ], 
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       suffixText: '${_exController.text.length}/1',
                                       // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _tabelaController,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                          ], 
                                        label: 'Tabela',
                                        maxLength: 1,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       suffixText: '${_tabelaController.text.length}/1',
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
                                    
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 20,right: 20),
                                      child: const Text('Alíquota',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                                    ),
                                    const SizedBox(height: 10),
                                    
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _federalNacionalController,
                                        label: 'Federal Nacional',
                                        maxLength: 5,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, ManutInputFormatter()],
                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_federalNacionalController.text.length}/5',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _federalImportadoController,
                                        label: 'Federal Importado',
                                        maxLength: 5,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,ManutInputFormatter()],
                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_federalImportadoController.text.length}/5',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _estadualController,
                                        label: 'Estadual',
                                        maxLength: 5,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,ManutInputFormatter()],
                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_estadualController.text.length}/5',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _municipalController,
                                        label: 'Municiapl',
                                        maxLength: 5,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,ManutInputFormatter()],
                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_municipalController.text.length}/5',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _totalNacionalController,
                                        label: 'Total nacional',
                                        maxLength: 5,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,ManutInputFormatter()],
                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_totalNacionalController.text.length}/5',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20,  left: 20),
                                      child: CustomInputField(
                                        controller: _totalImportadoController,
                                        label: 'Total Importado',
                                        maxLength: 5,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,ManutInputFormatter()],
                                       
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_totalImportadoController.text.length}/5',
                                        // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                      
                                    
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
                        //_buildActionButton('EXCLUIR', Colors.red),
                        //const SizedBox(width: 30),
                        _buildActionButton('SALVAR', Colors.green),
                        //const SizedBox(width: 30),
                        //_buildActionButton('RELATÓRIO', Colors.yellow),
                        
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
    /*print('Codigo Cidade: ${_codigoController.text}');
    print('Estado Cidade: ${_estadoController.text}');
    print('Cidade: ${_cidadeController.text}');
    print('Abreviado Cidade: ${_abreviadoController.text}');
    print('Pais Cidade: ${_paisController.text}');
    print('ISS Cidade: ${_issController.text}');
    print('Cartorio Radio: ${_cartorio == true ? 'Sim' : 'Não'}');
    print('Tabela IBGE Cidade: ${_tabelaIBGEController.text}');*/
    
    print('------------------------------------------');
  }
}