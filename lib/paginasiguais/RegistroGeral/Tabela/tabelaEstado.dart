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
  if (value.length != 2 || !validUFs.contains(value.toUpperCase())) {
    return 'UF inválida.';
  }
  return null;
}

class TabelaEstado extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaEstado({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaEstado> createState() => _TabelaEstadoState();
}

class _TabelaEstadoState extends State<TabelaEstado> {
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _siglaController = TextEditingController();
  
  String? _selectedPaisId;
  List<Map<String, dynamic>> _allPaises = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllPaises();
    _codigoController.addListener(_onCodigoChanged);
    _siglaController.addListener(_onEstadoChanged);
  }

  CollectionReference get _estadosCollectionRef => FirebaseFirestore.instance
      .collection('companies').doc(widget.mainCompanyId)
      .collection('secondaryCompanies').doc(widget.secondaryCompanyId)
      .collection('data').doc('estados').collection('items');

  // CORREÇÃO: Aponta para a coleção de países compartilhada, conforme as regras do Firebase
  CollectionReference get _paisesCollectionRef => FirebaseFirestore.instance
      .collection('companies').doc(widget.mainCompanyId)
      .collection('shared_data').doc('paises')
      .collection('items');

  Future<void> _fetchAllPaises() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _paisesCollectionRef.get();
      _allPaises = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'pais': data['pais'] ?? 'País sem nome',
          'resumo': data['resumo'] ?? '',
          'codigoPais': data['codigoPais'] ?? '',
        };
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar países: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields({bool clearCode = false}) {
    if (clearCode) _codigoController.clear();
    _estadoController.clear();
    _siglaController.clear();
    setState(() {
      _selectedPaisId = null;
    });
  }

  void _onEstadoChanged() {
    final String sigla = _siglaController.text.toUpperCase();
    if (sigla == 'EX') {
      setState(() {
        _selectedPaisId = null; // Limpa a seleção para que o usuário escolha
      });
    } else {
      // Procura pelo país "Brasil" na lista
      var brasil = _allPaises.firstWhere(
        (p) => (p['pais'] as String).toLowerCase() == 'brasil',
        orElse: () => {}, // Retorna um mapa vazio se não encontrar
      );
      if (brasil.isNotEmpty) {
        setState(() {
          _selectedPaisId = brasil['id']; // Define o ID do Brasil
        });
      }
    }
  }

  Future<void> _onCodigoChanged() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _clearFields(clearCode: false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docSnapshot = await _estadosCollectionRef.doc(codigo).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _estadoController.text = data['estado'] ?? '';
          _siglaController.text = data['sigla'] ?? '';
          _selectedPaisId = data['paisId'];
        });
      } else {
        _clearFields(clearCode: false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar estado: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final docId = _codigoController.text.trim();
    setState(() => _isLoading = true);

    final dataToSave = {
      'estado': _estadoController.text.trim(),
      'sigla': _siglaController.text.trim().toUpperCase(),
      'paisId': _selectedPaisId,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'criado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      final docExists = (await _estadosCollectionRef.doc(docId).get()).exists;
      await _estadosCollectionRef.doc(docId).set(dataToSave, SetOptions(merge: true));
      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
      action: docExists ? LogAction.UPDATE : LogAction.CREATE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estados', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'Usuário salvou/atualizou o estado com código $docId.', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado salvo com sucesso!')));
    } catch (e) {
      // --- LOG DE ERRO SAVE---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estados', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'FALHA ao salvar estado com código $docId. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
    final docId = _codigoController.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o Código para excluir.')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir o estado com código $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _estadosCollectionRef.doc(docId).delete();
      // --- LOG DE SUCESSO DELETE---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.DELETE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estados', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'Usuário excluiu o estado com código $docId.', // <-- PARTE CUSTOMIZÁVEL 2
    );

      _clearFields(clearCode: true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado excluído com sucesso!')));
    } catch (e) {
      // --- LOG DE ERRO DELETE---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estados', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'FALHA ao excluir estado com código $docId. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      final estadosSnapshot = await _estadosCollectionRef.get();
      if (estadosSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum estado para gerar relatório.')));
        return;
      }

      final List<Map<String, dynamic>> allEstadosData = [];
      for (var doc in estadosSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allEstadosData.add({
          'codigo': doc.id,
          'estado': data['estado'] ?? 'N/A',
          'sigla': data['sigla'] ?? 'N/A',
          'paisId': data['paisId'] ?? 'N/A',
        });
      }

      final pdf = pw.Document();
      final headers = ['Código', 'Estado', 'Sigla', 'Cód. País'];
      
      final data = allEstadosData.map((estado) => [
        estado['codigo'],
        estado['estado'],
        estado['sigla'],
        estado['paisId'],
      ]).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Relatório de Estados - ${widget.secondaryCompanyId}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            )
          ],
        ),
      );
      // --- LOG DE SUCESSO REPORT---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.GENERATE_REPORT,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estados', // <-- PARTE CUSTOMIZÁVEL 1
      details: 'Usuário gerou um relatório da tabela de estados.', // <-- PARTE CUSTOMIZÁVEL 2
    );


      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      // --- LOG DE ERRO REPPORT---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estados', // <-- PARTE CUSTOMIZÁVEL 1
      details: 'FALHA ao gerar relatório de estados. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCombinedReport() async {
    setState(() => _isLoading = true);
    try {
      final estadosSnapshot = await _estadosCollectionRef.get();
      if (estadosSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum estado para gerar relatório.')));
        return;
      }
      
      final paisesMap = {for (var pais in _allPaises) pais['id']: pais};

      final List<List<String>> reportData = [];
      for (var estadoDoc in estadosSnapshot.docs) {
        final estadoData = estadoDoc.data() as Map<String, dynamic>;
        final paisId = estadoData['paisId'];
        final paisData = paisesMap[paisId];

        reportData.add([
          estadoDoc.id,
          estadoData['estado'] ?? 'N/A',
          estadoData['sigla'] ?? 'N/A',
          paisId ?? 'N/A',
          paisData?['pais'] ?? 'País não encontrado',
          paisData?['resumo'] ?? 'N/A',
        ]);
      }

      final pdf = pw.Document();
      final headers = ['Cód. Estado', 'Estado', 'Sigla', 'Cód. País', 'País', 'Resumo País'];
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Relatório Completo: Estados e Países', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headers: headers,
              data: reportData,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            )
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  void dispose() {
    _codigoController.removeListener(_onCodigoChanged);
    _estadoController.removeListener(_onEstadoChanged);
    _codigoController.dispose();
    _estadoController.dispose();
    _siglaController.dispose();
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
                onBackPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TelaSubPrincipal(mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, userRole: widget.userRole))),
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
            Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: AppDrawer(parentMaxWidth: constraints.maxWidth, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, 
        //userRole: widget.userRole,
                          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: Text('Estado', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
            child: Text('Estado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          AppDrawer(parentMaxWidth: 0, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, 
          //userRole: widget.userRole,
                          )
          ,
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
          decoration: BoxDecoration(color: Colors.blue[100], border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomInputField(controller: _codigoController, label: 'Código', maxLength: 2, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                      const SizedBox(height: 35),
                      CustomInputField(controller: _estadoController, label: 'Estado', maxLength: 20, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                      const SizedBox(height: 35),
                      CustomInputField(controller: _siglaController, label: 'Sigla', maxLength: 2, validator: _ufValidator, textCapitalization: TextCapitalization.characters),
                      const SizedBox(height: 35),
                      _buildPaisDropdown(),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPaisDropdown() {
    final bool isNotExterior = _siglaController.text.toUpperCase() != 'EX';
    return DropdownButtonFormField<String>(
      value: _selectedPaisId,
      decoration: InputDecoration(
        labelText: 'País',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: isNotExterior ? Colors.grey[300] : Colors.white,
      ),
      items: _allPaises.map<DropdownMenuItem<String>>((pais) {
        return DropdownMenuItem<String>(
          value: pais['id'],
          child: Text(pais['pais']),
        );
      }).toList(),
      onChanged: isNotExterior ? null : (String? newValue) {
        setState(() {
          _selectedPaisId = newValue;
        });
      },
      validator: (value) => value == null ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 15,
        alignment: WrapAlignment.center,
        children: [
          _buildActionButton('EXCLUIR', Colors.red, _deleteData),
          _buildActionButton('SALVAR', Colors.green, _saveData),
          _buildActionButton('RELATÓRIO', Colors.yellow, _generateReport),
          _buildActionButton('REL. COMPLETO', Colors.orange, _generateCombinedReport),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(180, 50),
        backgroundColor: color,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Colors.black)
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
