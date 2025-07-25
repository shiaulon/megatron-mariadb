import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';

class TabelaCondicaoPagamento extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole; // Se precisar usar a permissão aqui também

  const TabelaCondicaoPagamento({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaCondicaoPagamento> createState() => _TabelaCondicaoPagamentoState();
}

class _TabelaCondicaoPagamentoState extends State<TabelaCondicaoPagamento> {
  static const double _breakpoint = 700.0;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _currentDate;

  final TextEditingController _dataAtualController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  String? _selectedOpcaoOption; 

  final List<TextEditingController> _nroDiasControllers = [];
  static const int _maxNroDiasFields = 12;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _codigoController.addListener(_updateEmpresaCounter);
    _descricaoController.addListener(_updateEmpresaCounter);

    _selectedOpcaoOption = 'Dias Líquido';

    _addNroDiasField();
  }

  void _updateEmpresaCounter() {
    setState(() {});
  }

  void _addNroDiasField() {
    if (_nroDiasControllers.length < _maxNroDiasFields) {
      setState(() {
        final newController = TextEditingController();
        _nroDiasControllers.add(newController);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite máximo de 12 campos de Nro Dias atingido.')),
      );
    }
  }

  void _removeNroDiasField(int index) {
    if (_nroDiasControllers.length > 1) {
      setState(() {
        _nroDiasControllers[index].dispose();
        _nroDiasControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelo menos um campo de Nro Dias deve ser mantido.')),
      );
    }
  }

  @override
  void dispose() {
    _dataAtualController.dispose();
    _codigoController.dispose();
    _descricaoController.dispose();

    for (var controller in _nroDiasControllers) {
      controller.dispose();
    }
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
    );
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
                              child: AppDrawer(parentMaxWidth: constraints.maxWidth,
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
                                        'Condição Pagamento',
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
                              'Condição Pagamento',
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

  @override
  Widget _buildCentralInputArea() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150),
                            Expanded(
                              child: CustomInputField(
                                controller: _codigoController,
                                label: 'Código',
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                suffixText: '${_codigoController.text.length}/2',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Row(
                          children: [
                            const SizedBox(width: 150),
                            Expanded(
                              child: CustomInputField(
                                controller: _descricaoController,
                                label: 'Descrição',
                                maxLength: 30,
                                suffixText: '${_descricaoController.text.length}/30',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 150),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),


                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        // O container azul que queremos que ocupe a largura total
                        child: Container(
                          // Adicione esta linha para que o Container ocupe a largura total do seu pai
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 153, 205, 248),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.blue, width: 2.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Center(child: Text('Nro. Dias :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black))),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                                child: Wrap(
                                  spacing: 10.0,
                                  runSpacing: 10.0,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    ..._nroDiasControllers.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      TextEditingController controller = entry.value;
                                      return SizedBox(
                                        width: 150,
                                        child: Stack(
                                          children: [
                                            CustomInputField(
                                              controller: controller,
                                              label: 'Dia ${index + 1}',
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                              ],
                                              maxLength: 4,
                                              keyboardType: TextInputType.number,
                                              suffixText: '${controller.text.length}/4',
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Obrigatório';
                                                }
                                                return null;
                                              },
                                            ),
                                            if (_nroDiasControllers.length > 1)
                                              Positioned(
                                                right: -10,
                                                top: -10,
                                                child: Container(
                                                  
                                                  child: IconButton(
                                                    padding: EdgeInsets.only(top: 8),
                                                    icon: const Icon(Icons.remove, color: Colors.black, size: 24),
                                                    onPressed: () => _removeNroDiasField(index),
                                                    tooltip: 'Remover Campo',
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    if (_nroDiasControllers.length < _maxNroDiasFields)
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: Colors.black, width: 3.0),
                                        ),
                                        child: IconButton(
                                          iconSize: 18,
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.add, color: Colors.black),
                                          onPressed: _addNroDiasField,
                                          tooltip: 'Adicionar novo campo de dia',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 25),
                        child: Container(
                          decoration: BoxDecoration(
                                              color: const Color.fromARGB(255, 153, 205, 248), // Cor de fundo do container de integração
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: Colors.blue, width: 2.0),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Text('Opção :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),

                                                      

                                                    ],
                                                  ),
                                                  Row( // Alterado para Column para empilhar os RadioListTile
                                                    crossAxisAlignment: CrossAxisAlignment.start, // Alinha os RadioListTile à esquerda
                                                    children: [
                                                      Expanded(
                                                        child: RadioListTile<String>(
                                                          title: const Text('Dias Líquido', style: TextStyle(color: Colors.black)),
                                                          value: 'Dias Líquido',
                                                          groupValue: _selectedOpcaoOption,
                                                          contentPadding: EdgeInsets.zero, // Remove todo o padding interno
                                                          
                                                          onChanged: (String? value) {
                                                            setState(() {
                                                              _selectedOpcaoOption = value;
                                                            });
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: RadioListTile<String>(
                                                          title: const Text('Dias Faturamento', style: TextStyle(color: Colors.black)),
                                                          value: 'Dias Faturamento',
                                                          groupValue: _selectedOpcaoOption,
                                                          contentPadding: EdgeInsets.zero, // Remove todo o padding interno
                                      
                                                          onChanged: (String? value) {
                                                            setState(() {
                                                              _selectedOpcaoOption = value;
                                                            });
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: RadioListTile<String>(
                                                          title: const Text('Dias Fora Semana', style: TextStyle(color: Colors.black)),
                                                          value: 'Dias Fora Semana',
                                                          groupValue: _selectedOpcaoOption,
                                                          contentPadding: EdgeInsets.zero,
                                                          onChanged: (String? value) {
                                                            setState(() {
                                                              _selectedOpcaoOption = value;
                                                            });
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: RadioListTile<String>(
                                                          title: const Text('Dias Fora Quinzena', style: TextStyle(color: Colors.black)),
                                                          value: 'Dias Fora Quinzena',
                                                          groupValue: _selectedOpcaoOption,
                                                          contentPadding: EdgeInsets.zero,
                                                          onChanged: (String? value) {
                                                            setState(() {
                                                              _selectedOpcaoOption = value;
                                                            });
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: RadioListTile<String>(
                                                          title: const Text('Dias Fora Mês', style: TextStyle(color: Colors.black)),
                                                          value: 'Dias Fora Mês',
                                                          groupValue: _selectedOpcaoOption,
                                                          contentPadding: EdgeInsets.zero,
                                                          onChanged: (String? value) {
                                                            setState(() {
                                                              _selectedOpcaoOption = value;
                                                            });
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: RadioListTile<String>(
                                                          title: const Text('Sem Pagamento', style: TextStyle(color: Colors.black)),
                                                          value: 'Sem Pagamento',
                                                          groupValue: _selectedOpcaoOption,
                                                          contentPadding: EdgeInsets.zero,
                                                          onChanged: (String? value) {
                                                            setState(() {
                                                              _selectedOpcaoOption= value;
                                                            });
                                                          },
                                                          activeColor: Colors.blue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            )
                        ),
                      ),
                      SizedBox(height: 30,)
                    ],
                  ),
                ),
              ),
              Center(
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              print('--- Dados Salvos ---');
                              print('Data Atual: ${_dataAtualController.text}');
                              print('codigo Cargo: ${_codigoController.text}');
                              print('Descrição cargo: ${_descricaoController.text}');
                              for (int i = 0; i < _nroDiasControllers.length; i++) {
                                print('Nro Dia ${i + 1}: ${_nroDiasControllers[i].text}');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, corrija os erros nos campos antes de salvar.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 50),
                            side: const BorderSide(
                              width: 1.0,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('EXCLUIR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              print('--- Dados Salvos ---');
                              print('Data Atual: ${_dataAtualController.text}');
                              print('codigo Cargo: ${_codigoController.text}');
                              print('Descrição cargo: ${_descricaoController.text}');
                              for (int i = 0; i < _nroDiasControllers.length; i++) {
                                print('Nro Dia ${i + 1}: ${_nroDiasControllers[i].text}');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, corrija os erros nos campos antes de salvar.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 50),
                            side: const BorderSide(
                              width: 1.0,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('SALVAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              print('--- Dados Salvos ---');
                              print('Data Atual: ${_dataAtualController.text}');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, corrija os erros nos campos antes de salvar.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 50),
                            side: const BorderSide(
                              width: 1.0,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('RELATÓRIO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}