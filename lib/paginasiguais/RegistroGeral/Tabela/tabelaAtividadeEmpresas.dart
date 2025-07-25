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


class TabelaAtividadeEmpresas extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Se precisar usar a permissão aqui também

  const TabelaAtividadeEmpresas({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaAtividadeEmpresas> createState() => _TabelaAtividadeEmpresasState();
}

class _TabelaAtividadeEmpresasState extends State<TabelaAtividadeEmpresas> {
  static const double _breakpoint = 700.0; // Desktop breakpoint

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _currentDate;

  // Controllers para os campos da tela "Estado X Imposto"
  final TextEditingController _codigoController =  TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _cstIcmsImportadoController = TextEditingController();
  final TextEditingController _cstIcmsINacionalController = TextEditingController();
  final TextEditingController _baseAtacadistaController= TextEditingController();
  final TextEditingController _baseAtacadistaController1 = TextEditingController();
  final TextEditingController _cargaMediaPctmController = TextEditingController();
  final TextEditingController _reducaoStSimplesController= TextEditingController();
  final TextEditingController _cstPisCofinsController = TextEditingController();
  

  final TextEditingController _motivoDesoneracaoController = TextEditingController();
  final TextEditingController _aliqDiferentePisController = TextEditingController();
  final TextEditingController _aliqDiferenteCofinsController = TextEditingController();
  final TextEditingController _aliqRetenPisController = TextEditingController();
  final TextEditingController _aliqRetenCofinsController = TextEditingController();


  // Variáveis para os Radio Buttons (Sim/Não para Cálculo DIFAL Dentro)
  bool? _calculoDIFALDentro = false; // Valor inicial para "Não"

  bool? _aliqDifPis = false;
  bool? _aliqRetenPis = false;
  bool? _aliqRetenCofins = false;
  bool? _aliqDifCofins = false;

  bool _motivoDes = false;
  bool _acumulaIPI = false;
  bool _temINSS = false;
  bool _temISSQN = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _codigoController.addListener(_updateFieldCounters);
    _descricaoController.addListener(_updateFieldCounters);
    _cstIcmsImportadoController.addListener(_updateFieldCounters);
    _cstIcmsINacionalController.addListener(_updateFieldCounters);
    _baseAtacadistaController.addListener(_updateFieldCounters);
    _baseAtacadistaController1.addListener(_updateFieldCounters);
    _cargaMediaPctmController.addListener(_updateFieldCounters);
    _reducaoStSimplesController.addListener(_updateFieldCounters);
    _cstPisCofinsController.addListener(_updateFieldCounters);
    
    _motivoDesoneracaoController.addListener(_updateFieldCounters); // Adicionado
    _aliqDiferentePisController.addListener(_updateFieldCounters); // Adicionado
    _aliqDiferenteCofinsController.addListener(_updateFieldCounters); // Adicionado
    _aliqRetenPisController.addListener(_updateFieldCounters); // Adicionado
    _aliqRetenCofinsController.addListener(_updateFieldCounters); // Adicionado

  }

  void _updateFieldCounters() {
    setState(() {
      // Força a reconstrução para atualizar o suffixText dos CustomInputField
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descricaoController.dispose();
    _cstIcmsImportadoController.dispose();
    _cstIcmsINacionalController.dispose();
    _baseAtacadistaController.dispose();
    _baseAtacadistaController1.dispose();
    _cargaMediaPctmController.dispose();
    _reducaoStSimplesController.dispose();
    _cstPisCofinsController.dispose();
    _motivoDesoneracaoController.dispose();
    _aliqRetenCofinsController.dispose();
    _aliqRetenPisController.dispose();
    _aliqDiferenteCofinsController.dispose();
    _aliqDiferentePisController.dispose();
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
                              child: AppDrawer(
                                parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          //userRole: widget.userRole,
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
                                        'Atividade Empresa',
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
                              'Atividade Empresa',
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
                          //userRole: widget.userRole,
                          ),
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
                      Padding(
                              padding: const EdgeInsets.only(right: 400, left: 400),
                              child: CustomInputField(
                                controller: _codigoController,
                                label: 'Codigo',
                                maxLength: 2,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                               inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                               suffixText: '${_codigoController.text.length}/2',
                              ),
                            ),
                      // Linha 1: Estado Origem, Estado Destino
                      /*Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 90,),
                          Expanded(
                            child: CustomInputField(
                              inputFormatters: [FilteringTextInputFormatter.deny('1',),FilteringTextInputFormatter.deny('2',),
                              FilteringTextInputFormatter.deny('3',),FilteringTextInputFormatter.deny('4',),FilteringTextInputFormatter.deny('5',),
                              FilteringTextInputFormatter.deny('6',),FilteringTextInputFormatter.deny('7',),FilteringTextInputFormatter.deny('8',),
                              FilteringTextInputFormatter.deny('9',),FilteringTextInputFormatter.deny('0',),],
                              controller: _estadoOrigemController,
                              label: 'Estado Origem',
                              maxLength: 2,
                              suffixText: '${_estadoOrigemController.text.length}/2',
                              
                              validator: ufValidator,
                            ),
                          ),
                          
                          const SizedBox(width: 20), // Espaçamento entre H e Estado Destino
                          Expanded(
                            child: CustomInputField(
                              controller: _estadoDestinoController,
                              inputFormatters: [FilteringTextInputFormatter.deny('1',),FilteringTextInputFormatter.deny('2',),
                              FilteringTextInputFormatter.deny('3',),FilteringTextInputFormatter.deny('4',),FilteringTextInputFormatter.deny('5',),
                              FilteringTextInputFormatter.deny('6',),FilteringTextInputFormatter.deny('7',),FilteringTextInputFormatter.deny('8',),
                              FilteringTextInputFormatter.deny('9',),FilteringTextInputFormatter.deny('0',),],
                              label: 'Estado Destino',
                              maxLength: 2,
                              suffixText: '${_estadoDestinoController.text.length}/2',
                              validator: ufValidator,

                            ),
                          ),
                          SizedBox(width: 90,),

                          
                        ],
                      ),*/
                      //const Divider(height: 6, thickness: 2, color: Colors.blue),

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
                                    
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20, left: 20),
                                      child: CustomInputField(
                                        controller: _descricaoController,
                                        label: 'Descrição',
                                        maxLength: 25,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                       inputFormatters: [],
                                       suffixText: '${_descricaoController.text.length}/25',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
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
                                                        const Text('Tem :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                        const Text('ISSQN :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
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
                                                      value: _temISSQN == true,
                                                      onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _temISSQN = true;
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
                                                      value: _temISSQN == false,
                                                      onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _temISSQN = false;
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
                                        //const SizedBox(width: 20),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0,),
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
                                                        const Text('Tem :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                        const Text('INSS :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
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
                                                      value: _temINSS == true,
                                                      onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _temINSS = true;
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
                                                      value: _temINSS == false,
                                                      onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _temINSS = false;
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
                        
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 0, left: 20),
                                            child: CustomInputField(
                                              controller: _cstIcmsINacionalController,
                                              label: 'CST ICMS Nacional',
                                              maxLength: 3,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              suffixText: '${_cstIcmsINacionalController.text.length}/3',
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return null;
                                                }
                                                // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                if (value.length != 3) {
                                                        return 'A sigla deve ter exatamente 3 caracteres/dígitos.';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 20, left: 0),
                                            child: CustomInputField(
                                              controller: _baseAtacadistaController1,
                                              label: 'Base atacadista',
                                              maxLength: 4,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                             inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                             suffixText: '${_baseAtacadistaController1.text.length}/4',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 0, left: 20),
                                            child: CustomInputField(
                                              controller: _cstIcmsImportadoController,
                                              label: 'CST ICMS Importado',
                                              maxLength: 3,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              suffixText: '${_cstIcmsImportadoController.text.length}/3',
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return null;
                                                }
                                                // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                if (value.length != 3) {
                                                        return 'A sigla deve ter exatamente 3 caracteres/dígitos.';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 20, left: 0),
                                            child: CustomInputField(
                                              controller: _baseAtacadistaController,
                                              label: 'Base atacadista',
                                              maxLength: 4,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                             inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                             suffixText: '${_baseAtacadistaController.text.length}/4',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 0, left: 20),
                                            child: CustomInputField(
                                              controller: _cargaMediaPctmController,
                                              label: 'Carga média PCTM',
                                              maxLength: 4,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              suffixText: '${_cargaMediaPctmController.text.length}/4',
                                              
                                              
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 20, left: 0),
                                            child: CustomInputField(
                                              controller: _reducaoStSimplesController,
                                              label: 'Redução ST Simples',
                                              maxLength: 4,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                             inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                             suffixText: '${_reducaoStSimplesController.text.length}/4',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 10),


                                    
                        
                                    const SizedBox(height: 0),
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
                                    
                        
                                    Padding(
                                      padding: const EdgeInsets.only(right: 120,  left: 120),
                                      child: CustomInputField(
                                        controller: _cstPisCofinsController,
                                        label: 'CST Pis/Cofins',
                                        maxLength: 3,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        suffixText: '${_cstPisCofinsController.text.length}/3',
                                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (value){
                                          if (value == null || value.isEmpty) {
                                                  return null;
                                                }
                                                // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                if (value.length != 3) {
                                                        return 'A sigla deve ter exatamente 3 caracteres/dígitos.';
                                                }
                                                return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                        ///////////////////////////////////////////////////////////////////////////////////
                        ///
                                    Column( // Removido o Expanded aqui
                                      crossAxisAlignment: CrossAxisAlignment.start, // Alinha o conteúdo à esquerda
                                      children: [
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(flex: 1,
                                              child: Padding(
                                                
                                                padding: const EdgeInsets.only(right: 20, left: 20),
                                                child: Text(
                                                  'Alíquota Diferente',
                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                            Expanded(flex: 1,
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 20, left: 20),
                                                child: Text(
                                                  'Alíquota Diferente',
                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Align(alignment: Alignment.centerLeft,
                                              child: Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 5),
                                                  child: Checkbox(
                                                    value: _aliqDifPis == true,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        _aliqDifPis = value;
                                                      });
                                                    },
                                                    activeColor: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            Expanded(
                                          child: Padding(
                                      padding: const EdgeInsets.only(  right: 20,),
                                            child: CustomInputField(
                                              controller: _aliqDiferentePisController,
                                              
                                              label: 'PIS Aliq Dif',
                                              maxLength: 4,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              suffixText: '${_motivoDesoneracaoController.text.length}/4',
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                              
                                              readOnly: !_aliqDifPis!, // Aplica a propriedade readOnly
                                        // AQUI ESTÁ A LÓGICA CONDICIONAL: Branco se habilitado, Cinza se desabilitado
                                        fillColor: !_aliqDifPis! ? const Color.fromARGB(255, 168, 155, 155) : Colors.white, 
                                              validator: (value){
                                                if (value == null || value.isEmpty) {
                                                  return null;
                                                }
                                                // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                if (value.length != 4) {
                                                        return 'O campo deve ter exatamente 4 caracteres/dígitos.';
                                                }
                                                
                                                return null;
                                              },  
                                            ),
                                          ),
                                        ),
                                            Align(alignment: Alignment.centerLeft,
                                              child: Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 5),
                                                  child: Checkbox(
                                                    value: _aliqRetenPis == true,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        _aliqRetenPis = value;
                                                      });
                                                    },
                                                    activeColor: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(  right: 20,),
                                                child: CustomInputField(
                                                  controller: _aliqRetenPisController,
                                                  
                                                  label: 'PIS Aliq Reten',
                                                  maxLength: 4,
                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                  suffixText: '${_motivoDesoneracaoController.text.length}/4',
                                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                                  
                                                  readOnly: !_aliqRetenPis!, // Aplica a propriedade readOnly
                                                  // AQUI ESTÁ A LÓGICA CONDICIONAL: Branco se habilitado, Cinza se desabilitado
                                                  fillColor: !_aliqRetenPis! ? const Color.fromARGB(255, 168, 155, 155) : Colors.white, 
                                                  validator: (value){
                                                    if (value == null || value.isEmpty) {
                                                      return null;
                                                    }
                                                    // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                    if (value.length != 4) {
                                                        return 'O campo deve ter exatamente 4 caracteres/dígitos.';
                                                    }
                                                    
                                                    return null;
                                                  },  
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        ///-----------------------
                                        Row(
                                          children: [
                                            Align(alignment: Alignment.centerLeft,
                                              child: Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 5),
                                                  child: Checkbox(
                                                    value: _aliqDifCofins == true,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        _aliqDifCofins = value;
                                                      });
                                                    },
                                                    activeColor: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(  right: 20,),
                                                child: CustomInputField(
                                                  controller: _aliqDiferenteCofinsController,
                                                  
                                                  label: 'COFINS Aliq Dif',
                                                  maxLength: 4,
                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                  suffixText: '${_motivoDesoneracaoController.text.length}/4',
                                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                                  
                                                  readOnly: !_aliqDifCofins!, // Aplica a propriedade readOnly
                                                  // AQUI ESTÁ A LÓGICA CONDICIONAL: Branco se habilitado, Cinza se desabilitado
                                                  fillColor: !_aliqDifCofins! ? const Color.fromARGB(255, 168, 155, 155) : Colors.white, 
                                                  validator: (value){
                                                    if (value == null || value.isEmpty) {
                                                      return null;
                                                    }
                                                    // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                    if (value.length != 4) {
                                                        return 'O campo deve ter exatamente 4 caracteres/dígitos.';
                                                    }
                                                    
                                                    return null;
                                                  },  
                                                ),
                                              ),
                                            ),
                                            Align(alignment: Alignment.centerLeft,
                                              child: Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 5),
                                                  child: Checkbox(
                                                    value: _aliqRetenCofins == true,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        _aliqRetenCofins = value;
                                                      });
                                                    },
                                                    activeColor: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(  right: 20,),
                                                child: CustomInputField(
                                                  controller: _aliqRetenCofinsController,
                                                  
                                                  label: 'COFINS Aliq Reten',
                                                  maxLength: 4,
                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                  suffixText: '${_motivoDesoneracaoController.text.length}/4',
                                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                                  
                                                  readOnly: !_aliqRetenCofins!, // Aplica a propriedade readOnly
                                                  // AQUI ESTÁ A LÓGICA CONDICIONAL: Branco se habilitado, Cinza se desabilitado
                                                  fillColor: !_aliqRetenCofins! ? const Color.fromARGB(255, 168, 155, 155) : Colors.white, 
                                                  validator: (value){
                                                    if (value == null || value.isEmpty) {
                                                      return null;
                                                    }
                                                    // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                    if (value.length != 4) {
                                                        return 'O campo deve ter exatamente 4 caracteres/dígitos.';
                                                    }
                                                    
                                                    return null;
                                                  },  
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                        
                                    Row(
                                      children: [
                                        Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 270, right: 20),
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
                                                            const Text('Acumula :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                            const Text('IPI :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
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
                                                          value: _acumulaIPI == true,
                                                          onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _acumulaIPI = true;
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
                                                          value: _acumulaIPI == false,
                                                          onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para false se o usuário CLICAR no "Não" (e o checkbox de "Não" for marcado)
                                                              setState(() {
                                                                _acumulaIPI = false;
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
                                    
                                    const SizedBox(height: 3),
                        
                                    Row( // MVA-St e MVA-St Importa (com H)
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only( right: 20),
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
                                                            const Text('Desoneração :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                            const Text('ICMS :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
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
                                                          value: _motivoDes == true,
                                                          onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _motivoDes = true;
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
                                                          value: _motivoDes == false,
                                                          onChanged: (bool? newValue) {
                                                            if (newValue == true) { // Só muda para true se o usuário CLICAR no "Sim"
                                                              setState(() {
                                                                _motivoDes = false;
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


                                        Expanded(
                                          child: Padding(
                                      padding: const EdgeInsets.only(  right: 20, top: 40),
                                            child: CustomInputField(
                                              controller: _motivoDesoneracaoController,
                                              
                                              label: 'Motivo desoneração',
                                              maxLength: 3,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              suffixText: '${_motivoDesoneracaoController.text.length}/3',
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                              
                                              readOnly: !_motivoDes, // Aplica a propriedade readOnly
                                        // AQUI ESTÁ A LÓGICA CONDICIONAL: Branco se habilitado, Cinza se desabilitado
                                        fillColor: !_motivoDes ? const Color.fromARGB(255, 168, 155, 155) : Colors.white, 
                                              validator: (value){
                                                if (value == null || value.isEmpty) {
                                                  return null;
                                                }
                                                // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                                if (value.length != 3) {
                                                        return 'A sigla deve ter exatamente 3 caracteres/dígitos.';
                                                }
                                                
                                                return null;
                                              },  
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botões de Ação - nao mais FIXOS na parte inferior da área central
                      Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton('EXCLUIR', Colors.red),
                      const SizedBox(width: 30),
                      _buildActionButton('SALVAR', Colors.green),
                      
                    ],
                  ),
                ),
              ),
              //BottomInfoContainers(tablePath: 'Tabela > Estado X Imposto'),
                    ],
                  ),
                ),
              ),

              // Botões de Ação - FIXOS na parte inferior da área central
              

              // Informações Inferiores - FIXAS na parte inferior da área central
              const SizedBox(height: 0),
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
    /*print('Estado Origem: ${_estadoOrigemController.text}');
    print('Estado Destino: ${_estadoDestinoController.text}');
    print('Aliq. Interestadual: ${_aliqInterstadualController.text}');
    print('Aliq. Interna - DIFAL: ${_aliqInternaDIFALController.text}');
    print('Desc. Diferença ICMS Revenda: ${_descontoDiferencaICMSRevendaController.text}');
    print('Desc. Diferença ICMS Outros: ${_descontoDiferencaICMSOutrosController.text}');
    print('Cálculo DIFAL Dentro: ${_calculoDIFALDentro == true ? 'Sim' : 'Não'}');
    print('Aliq. ICMS Substituição: ${_aliqICMSSubstituicaoController.text}');
    print('Aliq. Abatimento ICMS: ${_aliqAbatimentoICMSController.text}');
    print('Aliq. Abatimento MS Consumidor: ${_aliqAbatimentoICMSConsumidorController.text}');
    print('MVA-St: ${_mvaSTController.text}');
    print('MVA-St Importa: ${_mvaSTImportaController.text}');
    print('Cta Contabil Subs.Trib.Entr.Deb: ${_ctaContabilSubsTribEntrDebController.text}');
    print('------------------------------------------');*/
  }
}