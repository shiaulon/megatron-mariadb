import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/informacoesInferioresPagina.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importes para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Prefixo 'pw' para widgets do PDF
import 'package:printing/printing.dart'; // Para visualização/download


// ... (resto do seu código NaturezaTelaState)

class NaturezaTela extends StatefulWidget {
  const NaturezaTela({super.key});

  @override
  State<NaturezaTela> createState() => _NaturezaTelaState();
}

class _NaturezaTelaState extends State<NaturezaTela> {
  static const double _breakpoint = 700.0; // Desktop breakpoint

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _currentDate;

  // Controllers para os campos fixos
  final TextEditingController _naturezaController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  // Variáveis para controlar a habilitação/desabilitação dos campos e visibilidade dos botões
  bool _caracteristicasEnabled = false;

  // Limites TOTAIS de campos (incluindo o campo inicial que sempre existe)
  static const int _maxTotalCaracteristicas = 6; // 1 campo inicial + 5 adicionais
  static const int _maxTotalSequenciasPorCaracteristica = 16; // 1 campo inicial de cidade + 15 adicionais, por característica

  // Listas de Controllers para os campos dinâmicos de Característica
  final List<TextEditingController> _caracteristicaControllers = [];
  final List<FocusNode> _caracteristicaFocusNodes = [];

  // Variável para armazenar o índice da característica atualmente selecionada
  int? _selectedCaracteristicaIndex; 

  // Mapa para armazenar as sequências por característica (chave: índice da característica)
  final Map<int, List<TextEditingController>> _sequenciaControllersPorCaracteristica = {};
  final Map<int, List<FocusNode>> _sequenciaFocusNodesPorCaracteristica = {};

  final Map<int, Map<String, dynamic>> _originalCaracteristicaData = {};


  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    _naturezaController.addListener(_onNaturezaChanged);
    _descricaoController.addListener(_updateFieldCounters);
    
    _caracteristicasEnabled = false;
  }

  Future<void> _onNaturezaChanged() async {
    final String naturezaCode = _naturezaController.text.trim();

    if (naturezaCode.isEmpty) {
      setState(() {
        _descricaoController.clear();
        _caracteristicasEnabled = false;
        _selectedCaracteristicaIndex = null;
        _clearAllDynamicFields();
      });
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('naturezas')
          .doc(naturezaCode)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _descricaoController.text = data['descricao'] ?? '';
          _caracteristicasEnabled = true;

          _clearAllDynamicFields();
          
          final List<dynamic> caracteristicasData = data['caracteristicas'] ?? [];
          if (caracteristicasData.isEmpty) {
             _addCaracteristicaField(initialLoad: true);
             _addSequenciaFieldToSpecificCaracteristica(caracteristicaIndex: 0, initialLoad: true);
          } else {
            for (int i = 0; i < caracteristicasData.length; i++) {
              final caracData = caracteristicasData[i];
              _addCaracteristicaField(initialLoad: true, value: caracData['nome']);
              _originalCaracteristicaData[i] = caracData;

              final List<dynamic> sequenciasLoaded = caracData['sequencias'] ?? [];
              if (sequenciasLoaded.isNotEmpty) {
                for (var seqValue in sequenciasLoaded) {
                  _addSequenciaFieldToSpecificCaracteristica(
                    caracteristicaIndex: i, 
                    initialLoad: true, 
                    value: seqValue,
                    shouldRequestFocus: false,
                  );
                }
              } else {
                _addSequenciaFieldToSpecificCaracteristica(
                  caracteristicaIndex: i, 
                  initialLoad: true,
                  shouldRequestFocus: false,
                );
              }
            }
          }
          _selectedCaracteristicaIndex = null;
        });
      } else {
        setState(() {
          _descricaoController.clear();
          _caracteristicasEnabled = true;
          _selectedCaracteristicaIndex = null;
          _clearAllDynamicFields();
          _addCaracteristicaField(initialLoad: true);
          _addSequenciaFieldToSpecificCaracteristica(caracteristicaIndex: 0, initialLoad: true);
        });
      }
    } catch (e) {
      print('Erro ao consultar Natureza no Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao verificar Natureza: $e')),
      );
      setState(() {
        _caracteristicasEnabled = false;
        _selectedCaracteristicaIndex = null;
        _descricaoController.clear();
        _clearAllDynamicFields();
      });
    }
  }

  void _clearAllDynamicFields() {
    for (var controller in _caracteristicaControllers) {
      controller.removeListener(_updateFieldCounters);
      controller.dispose();
    }
    for (var focusNode in _caracteristicaFocusNodes) {
      focusNode.dispose();
    }
    _caracteristicaControllers.clear();
    _caracteristicaFocusNodes.clear();
    _originalCaracteristicaData.clear();

    _sequenciaControllersPorCaracteristica.forEach((key, value) {
      for (var controller in value) {
        controller.removeListener(_updateFieldCounters);
        controller.dispose();
      }
    });
    _sequenciaFocusNodesPorCaracteristica.forEach((key, value) {
      for (var focusNode in value) {
        focusNode.dispose();
      }
    });
    _sequenciaControllersPorCaracteristica.clear();
    _sequenciaFocusNodesPorCaracteristica.clear();
    _selectedCaracteristicaIndex = null;
  }

  void _addCaracteristicaField({bool initialLoad = false, String? value}) {
    if (!initialLoad && _caracteristicaControllers.length >= _maxTotalCaracteristicas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limite máximo de ${_maxTotalCaracteristicas} campos de Característica atingido.')),
      );
      return;
    }

    setState(() {
      final newIndex = _caracteristicaControllers.length;
      final newController = TextEditingController(text: value);
      final newFocusNode = FocusNode();
      newController.addListener(_updateFieldCounters);
      _caracteristicaControllers.add(newController);
      _caracteristicaFocusNodes.add(newFocusNode);
      
      _sequenciaControllersPorCaracteristica[newIndex] = [];
      _sequenciaFocusNodesPorCaracteristica[newIndex] = [];

      if (!initialLoad) {
        _addSequenciaFieldToSpecificCaracteristica(caracteristicaIndex: newIndex);
        _selectedCaracteristicaIndex = newIndex;
      }
    });
  }

  void _removeCaracteristicaField(int index) {
    if (_caracteristicaControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelo menos um campo de Característica deve ser mantido.')),
      );
      return;
    }

    setState(() {
      final controllerToRemove = _caracteristicaControllers.removeAt(index);
      final focusNodeToRemove = _caracteristicaFocusNodes.removeAt(index);
      controllerToRemove.removeListener(_updateFieldCounters);
      controllerToRemove.dispose();
      focusNodeToRemove.dispose();

      _originalCaracteristicaData.remove(index);
      
      final Map<int, List<TextEditingController>> tempSeqControllers = {};
      final Map<int, List<FocusNode>> tempSeqFocusNodes = {};
      final Map<int, Map<String, dynamic>> tempOriginalData = {};

      int newMappedIndex = 0;
      for (int i = 0; i < _caracteristicaControllers.length + 1; i++) {
        if (i == index) {
          if (_sequenciaControllersPorCaracteristica.containsKey(i)) {
            for (var controller in _sequenciaControllersPorCaracteristica[i]!) {
              controller.removeListener(_updateFieldCounters);
              controller.dispose();
            }
            for (var focusNode in _sequenciaFocusNodesPorCaracteristica[i]!) {
              focusNode.dispose();
            }
          }
          continue; 
        }
        
        if (_sequenciaControllersPorCaracteristica.containsKey(i)) { // Check if old index existed
          tempSeqControllers[newMappedIndex] = _sequenciaControllersPorCaracteristica[i]!;
          tempSeqFocusNodes[newMappedIndex] = _sequenciaFocusNodesPorCaracteristica[i]!;
          tempOriginalData[newMappedIndex] = _originalCaracteristicaData.containsKey(i) ? _originalCaracteristicaData[i]! : {};
          newMappedIndex++;
        }
      }

      _sequenciaControllersPorCaracteristica.clear();
      _sequenciaFocusNodesPorCaracteristica.clear();
      _originalCaracteristicaData.clear();

      _sequenciaControllersPorCaracteristica.addAll(tempSeqControllers);
      _sequenciaFocusNodesPorCaracteristica.addAll(tempSeqFocusNodes);
      _originalCaracteristicaData.addAll(tempOriginalData);


      if (_selectedCaracteristicaIndex != null) {
        if (_selectedCaracteristicaIndex == index) {
          _selectedCaracteristicaIndex = null;
        } else if (_selectedCaracteristicaIndex! > index) {
          _selectedCaracteristicaIndex = _selectedCaracteristicaIndex! - 1;
        }
      }
    });
  }

  void _addSequenciaFieldToSpecificCaracteristica({
    required int caracteristicaIndex,
    bool initialLoad = false,
    String? value,
    bool shouldRequestFocus = true,
  }) {
    if (caracteristicaIndex < 0 || !_sequenciaControllersPorCaracteristica.containsKey(caracteristicaIndex)) {
      print("Erro: Índice de característica inválido para adicionar sequência.");
      return;
    }
    
    final currentSequencias = _sequenciaControllersPorCaracteristica[caracteristicaIndex]!;

    if (!initialLoad && currentSequencias.length >= _maxTotalSequenciasPorCaracteristica) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limite máximo de ${_maxTotalSequenciasPorCaracteristica} campos de cidades atingido para esta característica.')),
      );
      return;
    }

    setState(() {
      final newController = TextEditingController(text: value);
      final newFocusNode = FocusNode();
      newController.addListener(_updateFieldCounters);
      currentSequencias.add(newController);
      _sequenciaFocusNodesPorCaracteristica[caracteristicaIndex]!.add(newFocusNode);

      if (!initialLoad && shouldRequestFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          newFocusNode.requestFocus();
        });
      }
    });
  }

  void _removeSequenciaField({required int caracteristicaIndex, required int sequenciaIndex}) {
    if (caracteristicaIndex < 0 || !_sequenciaControllersPorCaracteristica.containsKey(caracteristicaIndex)) {
      return;
    }
    final currentSequencias = _sequenciaControllersPorCaracteristica[caracteristicaIndex]!;

    if (currentSequencias.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelo menos um campo de Cidade deve ser mantido para esta característica.')),
      );
      return;
    }

    setState(() {
      final controllerToRemove = currentSequencias.removeAt(sequenciaIndex);
      final focusNodeToRemove = _sequenciaFocusNodesPorCaracteristica[caracteristicaIndex]!.removeAt(sequenciaIndex);

      controllerToRemove.removeListener(_updateFieldCounters);
      controllerToRemove.dispose();
      focusNodeToRemove.dispose();
    });
  }

  void _updateFieldCounters() {
    setState(() {
      // Força a reconstrução para atualizar o suffixText dos CustomInputField
    });
  }

  void _onCaracteristicaSelected(int index) {
    setState(() {
      if (_selectedCaracteristicaIndex == index) {
        _selectedCaracteristicaIndex = null;
      } else {
        _selectedCaracteristicaIndex = index;
      }
    });
  }


  @override
  void dispose() {
    _naturezaController.removeListener(_onNaturezaChanged);
    _naturezaController.dispose();
    _descricaoController.dispose();

    for (var controller in _caracteristicaControllers) {
      controller.dispose();
    }
    for (var focusNode in _caracteristicaFocusNodes) {
      focusNode.dispose();
    }

    _sequenciaControllersPorCaracteristica.forEach((key, seqList) {
      for (var controller in seqList) {
        controller.dispose();
      }
    });
    _sequenciaFocusNodesPorCaracteristica.forEach((key, focusList) {
      for (var focusNode in focusList) {
        focusNode.dispose();
      }
    });

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
                                        'Natureza',
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
                              'Natureza',
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
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 15, bottom: 0),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coluna para Natureza e Descrição
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(
                                  child: Text(
                                    'Natureza',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20, left: 20),
                                  child: CustomInputField(
                                    controller: _naturezaController,
                                    label: 'Natureza (Código)',
                                    maxLength: 10,
                                    suffixText: '${_naturezaController.text.length}/10',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20, left: 20),
                                  child: CustomInputField(
                                    controller: _descricaoController,
                                    label: 'Descrição (Nome)',
                                    maxLength: 50,
                                    suffixText: '${_descricaoController.text.length}/50',
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),

                          // Divisor Vertical principal (entre Natureza/Descrição e Característica/Sequência)
                          const VerticalDivider(width: 60, thickness: 2, color: Colors.blue),

                          // Coluna para Característica E Sequência (dinâmica)
                          Expanded(
                            flex: 2,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Coluna Característica (esquerda da divisão interna)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Característica (País)',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      // Renderiza os campos de Característica dinamicamente
                                      ..._caracteristicaControllers.asMap().entries.map((entry) {
                                        int caracteristicaIndex = entry.key;
                                        TextEditingController controller = entry.value;
                                        FocusNode focusNode = _caracteristicaFocusNodes[caracteristicaIndex];
                                        
                                        // Determina se esta característica está selecionada para destaque
                                        bool isSelected = _selectedCaracteristicaIndex == caracteristicaIndex;

                                        return Container( // Container para aplicar a cor de seleção
                                          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 20, left: 20, bottom: 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  children: [
                                                    CustomInputField(
                                                      controller: controller,
                                                      focusNode: focusNode,
                                                      label: 'Característica ${caracteristicaIndex + 1}',
                                                      maxLength: 30,
                                                      readOnly: !_caracteristicasEnabled,
                                                      fillColor: _caracteristicasEnabled ? Colors.white : Colors.grey[200],
                                                      suffixText: '${controller.text.length}/30',
                                                      onTap: _caracteristicasEnabled ? () => _onCaracteristicaSelected(caracteristicaIndex) : null,
                                                    ),
                                                    // Botão de remover (-) Característica
                                                    if (_caracteristicaControllers.length > 1 && _caracteristicasEnabled)
                                                      Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: IconButton(
                                                          icon: const Icon(Icons.remove, color: Colors.black, size: 24),
                                                          onPressed: () => _removeCaracteristicaField(caracteristicaIndex),
                                                          tooltip: 'Remover Característica',
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                // Botão de adicionar (+) Característica
                                                if (caracteristicaIndex == _caracteristicaControllers.length - 1 && 
                                                    _caracteristicaControllers.length < _maxTotalCaracteristicas && // <--- CONDIÇÃO AJUSTADA
                                                    _caracteristicasEnabled)
                                                  Align(
                                                    alignment: Alignment.center,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(top: 5),
                                                      child: Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.transparent,
                                                          borderRadius: BorderRadius.circular(5),
                                                          border: Border.all(color: Colors.black, width: 3.0),
                                                        ),
                                                        child: IconButton(
                                                          iconSize: 28,
                                                          padding: EdgeInsets.zero,
                                                          icon: const Icon(Icons.add, color: Colors.black),
                                                          onPressed: _addCaracteristicaField,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),

                                // Divisor Vertical (entre Característica e Sequência)
                                if (_selectedCaracteristicaIndex != null)
                                  const VerticalDivider(width: 60, thickness: 2, color: Colors.blue),

                                // Coluna Sequência (direita da divisão interna)
                                if (_selectedCaracteristicaIndex != null)
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            'Cidades para "${_caracteristicaControllers[_selectedCaracteristicaIndex!].text.isEmpty ? 'este País' : _caracteristicaControllers[_selectedCaracteristicaIndex!].text}"',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        // Renderiza os campos de Sequência da característica selecionada
                                        ...(_sequenciaControllersPorCaracteristica[_selectedCaracteristicaIndex!] ?? [])
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          int sequenciaIndex = entry.key;
                                          TextEditingController seqController = entry.value;
                                          FocusNode seqFocusNode = (_sequenciaFocusNodesPorCaracteristica[_selectedCaracteristicaIndex!] ?? [])[sequenciaIndex];
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 20, left: 20, bottom: 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  children: [
                                                    CustomInputField(
                                                      controller: seqController,
                                                      focusNode: seqFocusNode,
                                                      label: 'Cidade ${sequenciaIndex + 1}',
                                                      maxLength: 30,
                                                      readOnly: false,
                                                      fillColor: Colors.white,
                                                      suffixText: '${seqController.text.length}/30',
                                                    ),
                                                    // Botão de remover (-) Sequência
                                                    if ((_sequenciaControllersPorCaracteristica[_selectedCaracteristicaIndex!] ?? []).length > 1)
                                                      Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: IconButton(
                                                          icon: const Icon(Icons.remove, color: Colors.black, size: 24),
                                                          onPressed: () => _removeSequenciaField(caracteristicaIndex: _selectedCaracteristicaIndex!, sequenciaIndex: sequenciaIndex),
                                                          tooltip: 'Remover Cidade',
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                // Botão de adicionar (+) Sequência
                                                // Mostra o botão + se for o último campo E o número total de campos estiver abaixo do limite
                                                if (sequenciaIndex == (_sequenciaControllersPorCaracteristica[_selectedCaracteristicaIndex!] ?? []).length - 1 &&
                                                    (_sequenciaControllersPorCaracteristica[_selectedCaracteristicaIndex!] ?? []).length < _maxTotalSequenciasPorCaracteristica) // <--- CONDIÇÃO AJUSTADA
                                                  Align(
                                                    alignment: Alignment.center,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(top: 5, bottom: 10),
                                                      child: Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.transparent,
                                                          borderRadius: BorderRadius.circular(5),
                                                          border: Border.all(color: Colors.black, width: 3.0),
                                                        ),
                                                        child: IconButton(
                                                          iconSize: 28,
                                                          padding: EdgeInsets.zero,
                                                          icon: const Icon(Icons.add, color: Colors.black),
                                                          onPressed: () => _addSequenciaFieldToSpecificCaracteristica(caracteristicaIndex: _selectedCaracteristicaIndex!),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
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

              // Botões de Ação - FIXOS na parte inferior da área central
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton('EXCLUIR', Colors.red, _clearAllDynamicFields),
                      const SizedBox(width: 30),
                      _buildActionButton('SALVAR', Colors.green, _saveNaturezaData),
                      const SizedBox(width: 30),
                      _buildActionButton('RELATÓRIO', Colors.yellow, _generateAndDownloadNaturezasPdf), // <--- CHAMADA DO NOVO MÉTODO
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 0),
             // BottomInfoContainers(tablePath: 'Tabela > Natureza'),
            ],
          ),
        ),
      ),
    );
  }

  // NOVO MÉTODO: Gerar e Baixar o PDF com os dados das naturezas
  Future<void> _generateAndDownloadNaturezasPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerando relatório...')),
    );

    try {
      // 1. Buscar todos os dados de Naturezas do Firestore
      final querySnapshot = await FirebaseFirestore.instance.collection('naturezas').get();
      final List<Map<String, dynamic>> allNaturezasData = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final naturezaCode = doc.id;
        final descricao = data['descricao'] ?? 'N/A';
        final caracteristicas = data['caracteristicas'] as List<dynamic>? ?? [];

        List<Map<String, dynamic>> formattedCaracteristicas = [];
        for (var carac in caracteristicas) {
          final nomeCarac = carac['nome'] ?? 'N/A';
          final sequencias = carac['sequencias'] as List<dynamic>? ?? [];
          formattedCaracteristicas.add({
            'nome': nomeCarac,
            'sequencias': sequencias.map((s) => s.toString()).toList(),
          });
        }
        
        allNaturezasData.add({
          'codigo': naturezaCode,
          'descricao': descricao,
          'caracteristicas': formattedCaracteristicas,
        });
      }

      if (allNaturezasData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma Natureza encontrada para gerar o relatório.')),
        );
        return;
      }

      // 2. Criar o documento PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 20, marginTop: 20, marginRight: 20, marginBottom: 20),
          build: (pw.Context context) => [
            pw.Center(
              child: pw.Text(
                'Relatório de Naturezas',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            ...allNaturezasData.map((natureza) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Código: ${natureza['codigo']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Descrição: ${natureza['descricao']}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Características:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...natureza['caracteristicas'].map<pw.Widget>((carac) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('  - País: ${carac['nome']}'),
                          if (carac['sequencias'].isNotEmpty)
                            pw.Text('    Cidades: ${carac['sequencias'].join(', ')}'),
                        ],
                      ),
                    );
                  }).toList(),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
            ),
          ],
        ),
      );

      // 3. Visualizar/Baixar o PDF
      // A biblioteca `printing` lida automaticamente com a melhor forma para cada plataforma.
      // Para web, geralmente abre em uma nova aba ou inicia o download.
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'relatorio_naturezas_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
        // dynamicLayout: true, // Pode ser útil para documentos complexos
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório gerado e aberto no navegador!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
      print('Erro ao gerar PDF: $e');
    }
  }


  Future<void> _saveNaturezaData() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, corrija os erros nos campos antes de salvar.')),
      );
      return;
    }

    final String naturezaCode = _naturezaController.text.trim();
    if (naturezaCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O campo Natureza não pode ser vazio.')),
      );
      return;
    }

    List<Map<String, dynamic>> caracteristicasData = [];
    for (int i = 0; i < _caracteristicaControllers.length; i++) {
      final caracteristicaNome = _caracteristicaControllers[i].text.trim();
      if (caracteristicaNome.isEmpty) continue;

      List<String> sequenciasNomes = [];
      if (_sequenciaControllersPorCaracteristica.containsKey(i)) {
        for (var seqController in _sequenciaControllersPorCaracteristica[i]!) {
          final seqNome = seqController.text.trim();
          if (seqNome.isNotEmpty) {
            sequenciasNomes.add(seqNome);
          }
        }
      }
      caracteristicasData.add({
        'nome': caracteristicaNome,
        'sequencias': sequenciasNomes,
      });
    }

    final Map<String, dynamic> dataToSave = {
      'descricao': _descricaoController.text.trim(),
      'caracteristicas': caracteristicasData,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'criado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      await FirebaseFirestore.instance
          .collection('naturezas')
          .doc(naturezaCode)
          .set(dataToSave, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados da Natureza salvos com sucesso!')),
      );
      print('Dados da Natureza salvos: $dataToSave');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados da Natureza: $e')),
      );
      print('Erro ao salvar Natureza: $e');
    }
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
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
    print('--- Dados do Formulário Natureza ---');
    print('Natureza (Código): ${_naturezaController.text}');
    print('Descrição (Nome): ${_descricaoController.text}');
    
    for (int i = 0; i < _caracteristicaControllers.length; i++) {
      print('Característica ${i + 1}: ${_caracteristicaControllers[i].text}');
      if (_sequenciaControllersPorCaracteristica.containsKey(i)) {
        for (int j = 0; j < _sequenciaControllersPorCaracteristica[i]!.length; j++) {
          print('  Cidade ${j + 1}: ${_sequenciaControllersPorCaracteristica[i]![j].text}');
        }
      }
    }
    print('------------------------------------------');
  }
}