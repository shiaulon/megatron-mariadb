// lib/tabela_estado_imposto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/informacoesInferioresPagina.dart';



class TabelaSituacao extends StatefulWidget {
  const TabelaSituacao({super.key});

  @override
  State<TabelaSituacao> createState() => _TabelaSituacaoState();
}

class _TabelaSituacaoState extends State<TabelaSituacao> {
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

  // Variável para controlar o Radio Button selecionado na seção "Bloqueio"
  String? _selectedBloqueioOption; // 'Normal', 'Mensagem', 'Bloqueio', 'Apenas Dinheiro'

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
                                        'Situação',
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
                              'Situação',
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


                      const SizedBox(height: 5,),
                      // Linha que conterá as duas colunas ICMS e ST
                      Padding(
                        padding: const EdgeInsets.only(right: 8,left: 8),
                        child: IntrinsicHeight( // Permite que as colunas dentro do Row tenham a mesma altura
                          child: Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Alinha o topo das colunas
                              children: [
                                // Coluna ICMS
                                Expanded(
                                  flex: 1,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      const SizedBox(height: 50),

                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 20, left: 20),
                                          child: CustomInputField(
                                            controller: _codigoController,
                                            label: 'Código',
                                            maxLength: 2,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Campo obrigatório';
                                              }},
                                            suffixText: '${_codigoController.text.length}/2',
                                            // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),

                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 20, left: 20),
                                          child: CustomInputField(
                                            controller: _cidadeController,
                                            label: 'Descrição',
                                            maxLength: 30,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Campo obrigatório';
                                              }},
                                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                                            suffixText: '${_cidadeController.text.length}/30',
                                            // fillColor: Colors.white, // Não precisa especificar, CustomInputField já tem padrão branco
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),

                                      const SizedBox(width: 0),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
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
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente o conteúdo da Row
                                                children: [
                                                  Row(mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Text('Bloqueio :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                                    ],
                                                  ),
                                                  Expanded(
                                                    child: Row( // Alterado para Column para empilhar os RadioListTile
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Alinha os RadioListTile à esquerda
                                                      children: [
                                                        Expanded(
                                                          child: RadioListTile<String>(
                                                            title: const Text('Normal', style: TextStyle(color: Colors.black)),
                                                            value: 'Normal',
                                                            groupValue: _selectedBloqueioOption,
                                                            onChanged: (String? value) {
                                                              setState(() {
                                                                _selectedBloqueioOption = value;
                                                              });
                                                            },
                                                            activeColor: Colors.blue,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: RadioListTile<String>(
                                                            title: const Text('Mensagem', style: TextStyle(color: Colors.black)),
                                                            value: 'Mensagem',
                                                            groupValue: _selectedBloqueioOption,
                                                            onChanged: (String? value) {
                                                              setState(() {
                                                                _selectedBloqueioOption = value;
                                                              });
                                                            },
                                                            activeColor: Colors.blue,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: RadioListTile<String>(
                                                            title: const Text('Bloqueio', style: TextStyle(color: Colors.black)),
                                                            value: 'Bloqueio',
                                                            groupValue: _selectedBloqueioOption,
                                                            onChanged: (String? value) {
                                                              setState(() {
                                                                _selectedBloqueioOption = value;
                                                              });
                                                            },
                                                            activeColor: Colors.blue,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: RadioListTile<String>(
                                                            title: const Text('Apenas Dinheiro', style: TextStyle(color: Colors.black)),
                                                            value: 'Apenas Dinheiro',
                                                            groupValue: _selectedBloqueioOption,
                                                            onChanged: (String? value) {
                                                              setState(() {
                                                                _selectedBloqueioOption = value;
                                                              });
                                                            },
                                                            activeColor: Colors.blue,
                                                          ),
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
                                ),


                                const SizedBox(height: 10),


                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40,),



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
    print('Bloqueio: ${_selectedBloqueioOption ?? 'Nenhum selecionado'}'); // Usar a nova variável
    print('Aliq. ICMS Substituição: ${_tabelaIBGEController.text}');

    print('------------------------------------------');
  }
}