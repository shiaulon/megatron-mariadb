import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

String? _ufValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Obrigatório.';
  }
  final List<String> validUFs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO', 'EX'
  ];
  if (!validUFs.contains(value.toUpperCase())) {
    return 'UF inválida.';
  }
  return null;
}

class TabelaCidade extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaCidade({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaCidade> createState() => _TabelaCidadeState();
}

class _TabelaCidadeState extends State<TabelaCidade> {
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _abreviadoController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _issController = TextEditingController();
  final TextEditingController _tabelaIBGEController = TextEditingController();
  
  bool _paisReadOnly = true;
  bool? _cartorio = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _allCidades = [];

  void _updateCounters() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllCidades();
    _estadoController.addListener(_onEstadoChanged);
    
    // Listeners para limpar campos dependentes
    _codigoController.addListener(_updateCounters);
    _cidadeController.addListener(_updateCounters);
    _abreviadoController.addListener(_updateCounters);
    _estadoController.addListener(_updateCounters);
    _paisController.addListener(_updateCounters);
    _issController.addListener(_updateCounters);
    _tabelaIBGEController.addListener(_updateCounters);
  }

  CollectionReference get _collectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('cidades')
      .collection('items');

  Future<void> _fetchAllCidades() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _collectionRef.get();
      _allCidades = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Adiciona o ID do documento aos dados
        return data;
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar cidades: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  

  void _populateAllFields(Map<String, dynamic> data) {
    setState(() {
      _codigoController.text = data['id'] ?? '';
      _cidadeController.text = data['cidade'] ?? '';
      _abreviadoController.text = data['abreviado'] ?? '';
      _estadoController.text = data['estado'] ?? '';
      _paisController.text = data['pais'] ?? '';
      _issController.text = data['iss'] ?? '';
      _tabelaIBGEController.text = data['tabelaIBGE'] ?? '';
      _cartorio = data['cartorio'] ?? false;
      _onEstadoChanged(); // Atualiza o estado do campo País
    });
  }

  void _clearDependentFields() {
    _abreviadoController.clear();
    _estadoController.clear();
    _paisController.clear();
    _issController.clear();
    _tabelaIBGEController.clear();
    setState(() {
      _cartorio = false;
      _paisReadOnly = true;
    });
  }

  void _clearSearchFields() {
    _codigoController.clear();
    _cidadeController.clear();
  }

  void _handleClearCheck() {
    if (_codigoController.text.isEmpty && _cidadeController.text.isEmpty) {
      _clearDependentFields();
    }
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
        _paisController.text = '';
        _paisReadOnly = false;
      } else if (ufsBrasileiras.contains(estado)) {
        _paisController.text = 'Brasil';
        _paisReadOnly = true;
      } else {
        _paisController.text = '';
        _paisReadOnly = true;
      }
    });
  }

  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final docId = _codigoController.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O campo "Código" é obrigatório para salvar.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dataToSave = {
      'cidade': _cidadeController.text.trim(),
      'abreviado': _abreviadoController.text.trim(),
      'estado': _estadoController.text.trim().toUpperCase(),
      'pais': _paisController.text.trim(),
      'iss': _issController.text.trim(),
      'tabelaIBGE': _tabelaIBGEController.text.trim(),
      'cartorio': _cartorio,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'atualizado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      final docExists = (await _collectionRef.doc(docId).get()).exists;
      await _collectionRef.doc(docId).set(dataToSave);
      await LogService.addLog(
      action: docExists ? LogAction.UPDATE : LogAction.CREATE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'cidades', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'Usuário salvou/atualizou a cidade com código $docId.', // <-- PARTE CUSTOMIZÁVEL 2
    );

      await _fetchAllCidades();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cidade salva com sucesso!')),
      );
    } catch (e) {
      // --- LOG DE ERRO SAVE---
    await LogService.addLog(
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'cidades', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'FALHA ao salvar cidade com código $docId. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar cidade: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
    final docId = _codigoController.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o Código para excluir.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir a cidade com código $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _collectionRef.doc(docId).delete();
      // --- LOG DE SUCESSO DELETE---
    await LogService.addLog(
      action: LogAction.DELETE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'cidades', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'Usuário excluiu a cidade com código $docId.', // <-- PARTE CUSTOMIZÁVEL 2
    );

      _clearSearchFields();
      await _fetchAllCidades();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cidade excluída com sucesso!')),
      );
    } catch (e) {
      // --- LOG DE ERRO DELETE---
    await LogService.addLog(
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'cidades', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'FALHA ao excluir cidade com código $docId. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      if (_allCidades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma cidade para gerar relatório.')));
        return;
      }

      final pdf = pw.Document();
      final headers = ['Código', 'Cidade', 'Abreviado', 'Estado', 'País', 'ISS', 'IBGE', 'Cartório'];

      final data = _allCidades.map((cidade) => [
        cidade['id'],
        cidade['cidade'],
        cidade['abreviado'],
        cidade['estado'],
        cidade['pais'],
        cidade['iss'],
        cidade['tabelaIBGE'],
        (cidade['cartorio'] ?? false) ? 'Sim' : 'Não',
      ]).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Relatório de Cidades - ${widget.secondaryCompanyId}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
            )
          ],
        ),
      );

      // --- LOG DE SUCESSO REPORT---
    await LogService.addLog(
      action: LogAction.GENERATE_REPORT,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'cidades', // <-- PARTE CUSTOMIZÁVEL 1
      details: 'Usuário gerou um relatório da tabela de cidades.', // <-- PARTE CUSTOMIZÁVEL 2
    );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      // --- LOG DE ERRO REPPORT---
    await LogService.addLog(
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'cidades', // <-- PARTE CUSTOMIZÁVEL 1
      details: 'FALHA ao gerar relatório de cidades. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codigoController.removeListener(_handleClearCheck);
    _cidadeController.removeListener(_handleClearCheck);
    _estadoController.removeListener(_onEstadoChanged);
    _codigoController.dispose();
    _cidadeController.dispose();
    _abreviadoController.dispose();
    _estadoController.dispose();
    _paisController.dispose();
    _issController.dispose();
    _tabelaIBGEController.dispose();
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
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
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
          flex: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: Text('Cidade', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _buildCentralInputArea()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
            child: Text('Cidade', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          AppDrawer(
            parentMaxWidth: 0,
            breakpoint: _breakpoint,
            mainCompanyId: widget.mainCompanyId,
            secondaryCompanyId: widget.secondaryCompanyId,
            //userRole: widget.userRole,
                          ),
          _buildCentralInputArea(),
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
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      //_buildCamposDeBusca(),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildAutocompleteField(_codigoController, "Código", "id", isRequired: true,isNumeric: true, maxLength: 5),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildAutocompleteField(_cidadeController, "Cidade", "cidade", isRequired: true, maxLength: 35),
                                ),
                               // const SizedBox(height: 10),
                                
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_abreviadoController, "Abreviado", 15),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_estadoController, "Estado", 2, validator: _ufValidator, textCapitalization: TextCapitalization.characters),
                                ),
                                
                              ],
                            ),
                          ),
                          const SizedBox(width: 60),
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_paisController, "País", 15, readOnly: _paisReadOnly,isRequired: true),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_issController, "ISS", 4, isNumeric: true),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_tabelaIBGEController, "Tabela IBGE", 7, isNumeric: true, isRequired: true, validator: (value){
                                    if (value == null || value.isEmpty) {
                                    return 'O código IBGE deve ser preenchido.';
                                  }
                                  if (value.length != 7) {
                                    return 'O código IBGE deve ter 7 dígitos.'; // Mensagem de erro mais clara
                                  }
                                  return null;
                                  }),
                                ),
                                //const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 60,),
                                    Expanded(child: _buildCheckboxRow()),
                                    SizedBox(width: 60,),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
              SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }
  
  

  Widget _buildAutocompleteField(TextEditingController controller, String label, String fieldKey, {bool isRequired = false,bool isNumeric = false, int? maxLength}) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option[fieldKey] as String,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable.empty();
        }
        return _allCidades.where((option) {
          final fieldValue = option[fieldKey]?.toString().toLowerCase() ?? '';
          return fieldValue.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (selection) {
        _populateAllFields(selection);
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
          maxLength: maxLength,
          validator: isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null,
          inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),],
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            suffixText: '${controller.text.length}/$maxLength',
          onChanged: (value) {
            controller.text = value;
            final exactMatches = _allCidades.where((item) =>
              (item[fieldKey] as String?)?.toLowerCase() == value.toLowerCase()).toList();
            if (exactMatches.length == 1) {
              _populateAllFields(exactMatches.first);
            }
          },
        );
      },
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, int maxLength, {String? Function(String?)? validator, bool isNumeric = false, bool isRequired = false, bool readOnly = false, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return CustomInputField(
      controller: controller,
      label: label,
      maxLength: maxLength,
      validator: validator ?? (isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null),
      
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            suffixText: '${controller.text.length}/$maxLength',
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
      readOnly: readOnly,
      fillColor: readOnly ? Colors.grey[300] : Colors.white,
      textCapitalization: textCapitalization,
    );
  }

 Widget _buildCheckboxRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 153, 205, 248),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.blue, width: 2.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Column(
              children: [
                Text('Cartório :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [ Checkbox(value: _cartorio, onChanged: (v) => setState(() => _cartorio = true)), const Text('Sim') ]),
                Row(children: [ Checkbox(value: !_cartorio!, onChanged: (v) => setState(() => _cartorio = false)), const Text('Não') ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 15,
        children: [
          _buildActionButton('EXCLUIR', Colors.red, _deleteData),
          _buildActionButton('SALVAR', Colors.green, _saveData),
          _buildActionButton('RELATÓRIO', Colors.yellow, _generateReport),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(200, 50),
        side: const BorderSide(width: 1.0, color: Colors.black),
        backgroundColor: color,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}