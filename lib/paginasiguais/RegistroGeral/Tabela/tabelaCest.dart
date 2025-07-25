import 'package:flutter/material.dart';
//import 'package:flutter_application_1/reutilizaveis/informacoesInferioresPagina.dart';
//import 'package:flutter_application_1/menu.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart'; // Importe para formatar a data
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter



class CestInputFormatter extends TextInputFormatter {
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


class TabelaCest extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Se precisar usar a permissão aqui também

  const TabelaCest({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaCest> createState() => _TabelaCestState();
}



class _TabelaCestState extends State<TabelaCest> {
  // Define o breakpoint para alternar entre layouts
  static const double _breakpoint = 700.0; // Desktop breakpoint

  // GlobalKey para o Form (necessário para validar todos os campos)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Variável para armazenar a data atual formatada
  late String _currentDate;

  // Controllers para os novos campos de texto na área central
  final TextEditingController _dataAtualController = TextEditingController();
  final TextEditingController _cestController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _segmentoController = TextEditingController();

  



  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _cestController.addListener(_onCestChanged);

    // Adiciona listener para o campo Empresa para atualizar o contador
    _cestController.addListener(_updateEmpresaCounter);
    _descricaoController.addListener(_updateEmpresaCounter);
    _segmentoController.addListener(_updateEmpresaCounter);
  }

  void _onCestChanged() {
    String cestText = _cestController.text;
    String digitsOnly = cestText.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length >= 2) {
      _segmentoController.text = digitsOnly.substring(0, 2);
    } else {
      _segmentoController.text = '';
    }
    
    setState(() {});
  }

  void _updateEmpresaCounter() {
    // Força a reconstrução do widget para que o suffixText seja atualizado
    setState(() {});
  }

  @override
  void dispose() {
    //_lembretesController.dispose(); // Descarta o controller

    // Descarte os novos controllers de campo de texto
    _dataAtualController.dispose();
    _cestController.removeListener(_onCestChanged);
    //_empresaController.removeListener(_updateEmpresaCounter); // Remover listener
    _cestController.dispose();
    _segmentoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        // Este Column é o body passado para a TelaBase
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
                  return Column(
                    // Coluna principal da área de conteúdo
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        // Expande para o restante do espaço vertical
                        child: Row(
                          // Row para menu, área central e lembretes
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Menu Lateral (flex 1)
                            Expanded(
                              flex: 1,
                              child: AppDrawer(parentMaxWidth: constraints.maxWidth,
                          breakpoint: 700.0,
                          mainCompanyId: widget.mainCompanyId, // Passa
                          secondaryCompanyId: widget.secondaryCompanyId, // Passa
                          //userRole: widget.userRole,
                          ),
                            ),
                            // Área Central: Agora com o retângulo de informações E o título
                            Expanded(
                              // <-- ONDE A MUDANÇA OCORRE: Este Expanded é o pai do título e do container azul
                              flex: 3,
                              child: Column(
                                // Column para empilhar o título e o container
                                crossAxisAlignment: CrossAxisAlignment.start,
                                // Alinha os filhos à esquerda (Text e Padding)
                                children: [
                                  const Padding(
                                    // Título "Controle"
                                    padding:  EdgeInsets.only(
                                        top: 20.0, bottom: 0.0), // Padding vertical
                                    child: Center(
                                      // <-- Centraliza o texto APENAS dentro deste Expanded
                                      child: Text(
                                        'Tabela CEST', // Título alterado para "Controle"
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
                        const Padding(
                          padding:
                               EdgeInsets.only(top: 15.0, bottom: 8.0),
                          child: Center(
                            child: Text(
                              'Tabela CEST', // Título alterado para "Controle"
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
                          //userRole: widget.userRole,
                          ),
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


  Widget _buildCentralInputArea() {
    return Form(
      // Envolve toda a área de entrada de dados com um Form
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
          child: Column(
            // Use Column para empilhar os elementos e permitir o posicionamento no final
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                // Este Expanded fará com que a parte superior dos campos de entrada ocupe o espaço disponível
                child: SingleChildScrollView(
                  // Para permitir rolagem se os campos forem muitos
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      const SizedBox(height: 40,),
                      // código----------------------------------------------------------------------
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _cestController,
                                label: 'CEST',
                                inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Aceita apenas dígitos
                            CestInputFormatter(), // Adiciona barras automaticamente
                          ],
                                maxLength: 9,
                                keyboardType: TextInputType.number,
                                suffixText: '${_cestController.text.length}/9',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  if (value.length != 9) {
                                                        return 'A sigla deve ter exatamente 9 dígitos.';
                                                }
                                                return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      //resumo---------------------------------------------------------------------------------------------
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _segmentoController,
                                label: 'Segmento',
                                readOnly: true,
                                
                                maxLength: 2,
                                suffixText: '${_segmentoController.text.length}/2',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                  
                                  return null;
                                },
                                
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),
                      ///-----------------------------------------------------
                      const SizedBox(height: 35,),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _descricaoController,
                                label: 'Descrição',
                                
                                keyboardType: TextInputType.multiline, // 1. Muda o tipo de teclado
                          maxLines: 5,
                          minLines: 5,
                                
                                maxLength: 200,
                                
                                suffixText: '${_descricaoController.text.length}/200',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  // **VALIDAÇÃO EXTRA AQUI:** Deve ter exatamente 2 caracteres
                                  
                                  return null;
                                },
                                
                              ),
                            ),
                            const SizedBox(width: 150,),
                          ],
                        ),
                      ),
                      

                    

                      
                      const SizedBox(height: 45), // Espaçamento antes dos rádios

                      
                    ],
                  ),
                ),
              ),
              // Botões EXCLUIR, SALVAR, RELATÓRIO
                      Center(
                        child: IntrinsicHeight(
                          // Garante que a altura das colunas filhas seja a mesma
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch, // Faz com que as colunas se estiquem para a altura máxima
                            children: [
                              
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Valida todos os campos do formulário
                                    if (_formKey.currentState?.validate() ?? false) {
                                      // Todos os campos são válidos, prossiga com o salvamento
                                      print('--- Dados Salvos ---');
                                      print('Data Atual: ${_dataAtualController.text}');
                                      print('codigo Cargo: ${_cestController ?? 'Nenhum selecionado'}');
                                      print('codigo Cargo: ${_segmentoController ?? 'Nenhum selecionado'}');
                                      print('Descrição cargo: ${_descricaoController ?? 'Nenhum selecionado'}');
                                    } else {
                                      // Exibe uma mensagem ou snackbar indicando erros de validação
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Por favor, corrija os erros nos campos antes de salvar.')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: const Size(200, 50),
                                    side: const BorderSide(
                                      width: 1.0,
                                      color: Colors.black,
                                    ),
                                    backgroundColor: Colors.green, // Cor de fundo do botão
                                    foregroundColor: Colors.black, // Cor do texto
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  child: const Text('SALVAR',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              
                            ],
                          ),
                        ),
                      ),

              // Estes dois containers ficarão fixos na parte inferior
              // Você pode usar `Align` ou simplesmente colocá-los no final da Column
              // como eles já são agora, mas removendo-os do SingleChildScrollView.
              const SizedBox(height: 40),
              //BottomInfoContainers(tablePath: 'Tabela > Estado'),
              
            ],
          ),
        ),
      ),
    );
  }

  
}