import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/natureza_service.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Importes para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class NaturezaTela extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const NaturezaTela({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<NaturezaTela> createState() => _NaturezaTelaState();
}

class _NaturezaTelaState extends State<NaturezaTela> {
  // ----- Serviços e Estado da API -----
  final NaturezaService _naturezaService = NaturezaService();
  List<Map<String, dynamic>> _allNaturezas = [];
  bool _isLoading = false;
  // ------------------------------------

  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _naturezaController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  bool _caracteristicasEnabled = false;

  // Gerenciamento de campos dinâmicos (não precisa de alteração)
  static const int _maxTotalCaracteristicas = 6;
  static const int _maxTotalSequenciasPorCaracteristica = 16;
  final List<TextEditingController> _caracteristicaControllers = [];
  final List<FocusNode> _caracteristicaFocusNodes = [];
  int? _selectedCaracteristicaIndex;
  final Map<int, List<TextEditingController>> _sequenciaControllersPorCaracteristica = {};
  final Map<int, List<FocusNode>> _sequenciaFocusNodesPorCaracteristica = {};

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllNaturezas(); // Carrega os dados da API ao iniciar
    _naturezaController.addListener(_onNaturezaChanged);
    _descricaoController.addListener(_updateFieldCounters);
  }

  // Busca todos os dados da API
  Future<void> _fetchAllNaturezas() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");
      
      final naturezas = await _naturezaService.getAll(token);
      if (mounted) {
        setState(() {
          _allNaturezas = naturezas;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar naturezas: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Busca os dados na lista local em vez do Firebase
  void _onNaturezaChanged() {
    final naturezaCode = _naturezaController.text.trim();
    if (naturezaCode.length != 2) {
      if (naturezaCode.isEmpty) {
         _clearForm(clearNaturezaCode: false);
      } else {
        setState(() {
          _caracteristicasEnabled = false;
          _clearAllDynamicFields();
          _descricaoController.clear();
        });
      }
      return;
    }

    final matches = _allNaturezas.where((n) => n['id'].toString() == naturezaCode).toList();

    if (matches.length == 1) {
      _populateForm(matches.first);
    } else {
      _clearForm(clearNaturezaCode: false);
      setState(() {
         _caracteristicasEnabled = true;
         _addCaracteristicaField(initialLoad: true);
         _addSequenciaFieldToSpecificCaracteristica(caracteristicaIndex: 0, initialLoad: true);
      });
    }
  }

  // Preenche o formulário a partir dos dados da API
  void _populateForm(Map<String, dynamic> data) {
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
          
          final List<dynamic> sequenciasLoaded = caracData['sequencias'] ?? [];
          if (sequenciasLoaded.isNotEmpty) {
            for (var seqValue in sequenciasLoaded) {
              _addSequenciaFieldToSpecificCaracteristica(
                caracteristicaIndex: i,
                initialLoad: true,
                value: seqValue.toString(),
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
  }

  // Método centralizado para limpar o formulário
  void _clearForm({bool clearNaturezaCode = true}) {
    setState(() {
      if (clearNaturezaCode) _naturezaController.clear();
      _descricaoController.clear();
      _caracteristicasEnabled = false;
      _clearAllDynamicFields();
    });
  }

  // Salva os dados via API
  Future<void> _saveNaturezaData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final naturezaCode = _naturezaController.text.trim();
    if (naturezaCode.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O código da Natureza deve ter 2 caracteres.')));
      return;
    }

    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
      setState(() => _isLoading = false);
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
          if (seqNome.isNotEmpty) sequenciasNomes.add(seqNome);
        }
      }
      caracteristicasData.add({'nome': caracteristicaNome, 'sequencias': sequenciasNomes});
    }

    final dataToSave = {
      'id': naturezaCode,
      'descricao': _descricaoController.text.trim(),
      'caracteristicas': caracteristicasData,
    };

    try {
      await _naturezaService.saveData(dataToSave, token);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Natureza salva com sucesso!'), backgroundColor: Colors.green));
      await _fetchAllNaturezas(); // Atualiza a lista local
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar natureza: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Deleta os dados via API
  Future<void> _deleteNaturezaData() async {
    final naturezaCode = _naturezaController.text.trim();
    if (naturezaCode.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite um código de 2 caracteres para excluir.')));
      return;
    }

    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Exclusão'),
      content: Text('Tem certeza que deseja excluir a natureza "$naturezaCode"?'),
      actions: [
        TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop(false)),
        TextButton(child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ));

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
        setState(() => _isLoading = false);
        return;
    }

    try {
      await _naturezaService.deleteData(naturezaCode, token);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Natureza "$naturezaCode" excluída com sucesso!')));
      _clearForm();
      await _fetchAllNaturezas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir natureza: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Gera relatório a partir da lista local
  Future<void> _generateAndDownloadNaturezasPdf() async {
    setState(() => _isLoading = true);
    try {
      if (_allNaturezas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma Natureza encontrada para gerar o relatório.')));
        return;
      }
      _allNaturezas.sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Header(level: 0, child: pw.Text('Relatório de Naturezas', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          build: (context) => _allNaturezas.map((natureza) {
            final List caracteristicas = natureza['caracteristicas'] ?? [];
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Código: ${natureza['id']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Descrição: ${natureza['descricao']}'),
                if (caracteristicas.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Text('Características:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...caracteristicas.map<pw.Widget>((carac) {
                    final List sequencias = carac['sequencias'] ?? [];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, top: 2),
                      child: pw.Text(' - ${carac['nome']}: ${sequencias.join(', ')}'),
                    );
                  }).toList(),
                ],
                pw.Divider(height: 20),
              ],
            );
          }).toList(),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  // MÉTODOS DE GERENCIAMENTO DA UI (NÃO PRECISAM DE ALTERAÇÃO)
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
      
      final Map<int, List<TextEditingController>> tempSeqControllers = {};
      final Map<int, List<FocusNode>> tempSeqFocusNodes = {};

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
        
        if (_sequenciaControllersPorCaracteristica.containsKey(i)) {
          tempSeqControllers[newMappedIndex] = _sequenciaControllersPorCaracteristica[i]!;
          tempSeqFocusNodes[newMappedIndex] = _sequenciaFocusNodesPorCaracteristica[i]!;
          newMappedIndex++;
        }
      }

      _sequenciaControllersPorCaracteristica.clear();
      _sequenciaFocusNodesPorCaracteristica.clear();
      _sequenciaControllersPorCaracteristica.addAll(tempSeqControllers);
      _sequenciaFocusNodesPorCaracteristica.addAll(tempSeqFocusNodes);

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

  void _updateFieldCounters() => setState(() {});

  void _onCaracteristicaSelected(int index) {
    setState(() {
      _selectedCaracteristicaIndex = (_selectedCaracteristicaIndex == index) ? null : index;
    });
  }

  @override
  void dispose() {
    _naturezaController.removeListener(_onNaturezaChanged);
    _naturezaController.dispose();
    _descricaoController.dispose();
    _clearAllDynamicFields(); // Garante que todos os dinâmicos sejam limpos
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
                onBackPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TelaSubPrincipal(mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, userRole: widget.userRole)),
                ),
                currentDate: _currentDate,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > _breakpoint) {
                      return _buildDesktopLayout(constraints);
                    } else {
                      return _buildMobileLayout(constraints);
                    }
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
                flex: 1,
                child: AppDrawer(
                  parentMaxWidth: constraints.maxWidth,
                  breakpoint: _breakpoint,
                  mainCompanyId: widget.mainCompanyId,
                  secondaryCompanyId: widget.secondaryCompanyId,
                ),
              ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 0.0),
                child: Text('Natureza', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _buildCentralInputArea()),
            ],
          ),
        ),
        
      ],
    );
  }

  
  Widget _buildMobileLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 1.0),
            child: Text('Natureza', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          AppDrawer(
            parentMaxWidth: constraints.maxWidth,
            breakpoint: _breakpoint,
            mainCompanyId: widget.mainCompanyId,
            secondaryCompanyId: widget.secondaryCompanyId,
          ),
          _buildCentralInputArea(),
        ],
      ),
    );
  }
  
  


  Widget _buildCentralInputArea() {
    final theme = Theme.of(context); // Pega o tema
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
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
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20, left: 20),
                                  child: CustomInputField(
                                    controller: _naturezaController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    label: 'Natureza',
                                    maxLength: 2,
                                    suffixText: '${_naturezaController.text.length}/2',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20, left: 20),
                                  child: CustomInputField(
                                    controller: _descricaoController,
                                    label: 'Descrição',
                                    maxLength: 20,
                                    suffixText: '${_descricaoController.text.length}/20',
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 60, thickness: 2, color: Colors.blue),
                          Expanded(
                            flex: 2,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       Center(
                                        child: Text(
                                          'Característica',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      ..._caracteristicaControllers.asMap().entries.map((entry) {
                                        int caracteristicaIndex = entry.key;
                                        TextEditingController controller = entry.value;
                                        FocusNode focusNode = _caracteristicaFocusNodes[caracteristicaIndex];
                                        bool isSelected = _selectedCaracteristicaIndex == caracteristicaIndex;

                                        return Container(
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
                                                      //fillColor: _caracteristicasEnabled ? Colors.white : Colors.grey[200],
                                                      suffixText: '${controller.text.length}/30',
                                                      onTap: _caracteristicasEnabled ? () => _onCaracteristicaSelected(caracteristicaIndex) : null,
                                                    ),
                                                    if (_caracteristicaControllers.length > 1 && _caracteristicasEnabled)
                                                      Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: IconButton(
                                                          icon:  Icon(Icons.remove, color: theme.colorScheme.onSurface, size: 24),
                                                          onPressed: () => _removeCaracteristicaField(caracteristicaIndex),
                                                          tooltip: 'Remover Característica',
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                if (caracteristicaIndex == _caracteristicaControllers.length - 1 && 
                                                    _caracteristicaControllers.length < _maxTotalCaracteristicas &&
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
                                                          border: Border.all(color: theme.colorScheme.onSurface, width: 3.0),
                                                        ),
                                                        child: IconButton(
                                                          iconSize: 28,
                                                          padding: EdgeInsets.zero,
                                                          icon:  Icon(Icons.add, color: theme.colorScheme.onSurface),
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
                                if (_selectedCaracteristicaIndex != null)
                                  const VerticalDivider(width: 60, thickness: 2, color: Colors.blue),
                                if (_selectedCaracteristicaIndex != null)
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            'Sequência "${_caracteristicaControllers[_selectedCaracteristicaIndex!].text.isEmpty ? 'este País' : _caracteristicaControllers[_selectedCaracteristicaIndex!].text}"',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
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
                                                      label: 'Sequência ${sequenciaIndex + 1}',
                                                      maxLength: 30,
                                                      readOnly: false,
                                                      //fillColor: Colors.white,
                                                      suffixText: '${seqController.text.length}/30',
                                                    ),
                                                    if ((_sequenciaControllersPorCaracteristica[_selectedCaracteristicaIndex!] ?? []).length > 1)
                                                      Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: IconButton(
                                                          icon:  Icon(Icons.remove, color: theme.colorScheme.onSurface, size: 24),
                                                          onPressed: () => _removeSequenciaField(caracteristicaIndex: _selectedCaracteristicaIndex!, sequenciaIndex: sequenciaIndex),
                                                          tooltip: 'Remover Sequência',
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                if (sequenciaIndex == (_sequenciaControllersPorCaracteristica[_selectedCaracteristicaIndex!] ?? []).length - 1 &&
                                                    (_sequenciaControllersPorCaracteristica[_selectedCaracteristicaIndex!] ?? []).length < _maxTotalSequenciasPorCaracteristica)
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
                                                          border: Border.all(color: theme.colorScheme.onSurface, width: 3.0),
                                                        ),
                                                        child: IconButton(
                                                          iconSize: 28,
                                                          padding: EdgeInsets.zero,
                                                          icon:  Icon(Icons.add, color: theme.colorScheme.onSurface),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton('EXCLUIR', Colors.red, _deleteNaturezaData),
                      const SizedBox(width: 30),
                      _buildActionButton('SALVAR', Colors.green, _saveNaturezaData),
                      const SizedBox(width: 30),
                      _buildActionButton('RELATÓRIO', Colors.yellow, _generateAndDownloadNaturezasPdf),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
