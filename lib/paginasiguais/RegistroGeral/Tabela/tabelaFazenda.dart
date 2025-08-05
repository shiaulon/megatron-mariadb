import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';

import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TabelaFazenda extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaFazenda({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaFazenda> createState() => _TabelaFazendaState();
}

class _TabelaFazendaState extends State<TabelaFazenda> {
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;
  bool _isLoading = false;

  final TextEditingController _fazendaController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fazendaController.addListener(_onCodigoChanged);
  }

  CollectionReference get _collectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('fazendas') // Nome da coleção
      .collection('items');

  void _clearFields({bool clearCode = true}) {
    if (clearCode) {
      _fazendaController.clear();
    }
    _descricaoController.clear();
    _rgController.clear();
  }

  Future<void> _onCodigoChanged() async {
    final codigo = _fazendaController.text.trim();
    if (codigo.isEmpty) {
      _clearFields(clearCode: false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docSnapshot = await _collectionRef.doc(codigo).get();

      await LogService.addLog(
        action: LogAction.VIEW,
        modulo: LogModule.REGISTRO_GERAL,
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
        targetCollection: 'fazendas',
        targetDocId: codigo,
        details: 'Usuário consultou a Fazenda cód. "$codigo". Resultado: ${docSnapshot.exists ? "Encontrado" : "Não encontrado"}.',
      );

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _descricaoController.text = data['descricao'] ?? '';
          _rgController.text = data['rg'] ?? '';
        });
      } else {
        _clearFields(clearCode: false);
      }
    } catch (e) {
      await LogService.addLog(action: LogAction.ERROR, modulo: LogModule.REGISTRO_GERAL, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, targetCollection: 'fazendas', targetDocId: codigo, details: 'FALHA ao consultar Fazenda cód. "$codigo". Erro: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao consultar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final docId = _fazendaController.text.trim();
    setState(() => _isLoading = true);

    final dataToSave = {
      'descricao': _descricaoController.text.trim(),
      'rg': _rgController.text.trim(),
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'criado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      final docExists = (await _collectionRef.doc(docId).get()).exists;
      await _collectionRef.doc(docId).set(dataToSave);

      await LogService.addLog(
        action: docExists ? LogAction.UPDATE : LogAction.CREATE,
        modulo: LogModule.REGISTRO_GERAL,
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
        targetCollection: 'fazendas',
        targetDocId: docId,
        details: 'Usuário salvou/atualizou a Fazenda: $docId - ${_descricaoController.text}.',
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo com sucesso!')));
    } catch (e) {
      await LogService.addLog(action: LogAction.ERROR, modulo: LogModule.REGISTRO_GERAL, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, targetCollection: 'fazendas', targetDocId: docId, details: 'FALHA ao salvar Fazenda $docId. Erro: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocorreu um erro ao salvar.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
    final docId = _fazendaController.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o código para excluir.')));
      return;
    }

    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirmar Exclusão'), content: Text('Deseja excluir a Fazenda $docId?'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red))]));
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _collectionRef.doc(docId).delete();
      await LogService.addLog(action: LogAction.DELETE, modulo: LogModule.REGISTRO_GERAL, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, targetCollection: 'fazendas', targetDocId: docId, details: 'Usuário excluiu a Fazenda cód. $docId.');
      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído com sucesso!')));
    } catch (e) {
      await LogService.addLog(action: LogAction.ERROR, modulo: LogModule.REGISTRO_GERAL, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, targetCollection: 'fazendas', targetDocId: docId, details: 'FALHA ao excluir Fazenda $docId. Erro: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocorreu um erro ao excluir.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _collectionRef.orderBy(FieldPath.documentId).get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum dado para gerar relatório.')));
        setState(() => _isLoading = false);
        return;
      }
      final pdf = pw.Document();
      final headers = ['Fazenda (Cód)', 'Descrição', 'RG'];
      final data = querySnapshot.docs.map((doc) {
        final item = doc.data() as Map<String, dynamic>;
        return [doc.id, item['descricao'] ?? '', item['rg'] ?? ''];
      }).toList();
      pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, header: (context) => pw.Header(level: 0, child: pw.Text('Relatório de Fazendas - ${widget.secondaryCompanyId}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))), build: (context) => [pw.Table.fromTextArray(headers: headers, data: data, border: pw.TableBorder.all(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold))]));
      await LogService.addLog(action: LogAction.GENERATE_REPORT, modulo: LogModule.REGISTRO_GERAL, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, targetCollection: 'fazendas', details: 'Usuário gerou um relatório da tabela de Fazendas.');
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      await LogService.addLog(action: LogAction.ERROR, modulo: LogModule.REGISTRO_GERAL, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, targetCollection: 'fazendas', details: 'FALHA ao gerar relatório de Fazendas. Erro: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  void dispose() {
    _fazendaController.removeListener(_onCodigoChanged);
    _fazendaController.dispose();
    _descricaoController.dispose();
    _rgController.dispose();
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
                  builder: (BuildContext context, BoxConstraints constraints) {
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
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('Fazenda', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Text('Fazenda', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomInputField(
                        controller: _fazendaController,
                        label: 'Fazenda (Código)',
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 5,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        controller: _descricaoController,
                        label: 'Descrição',
                        maxLength: 30,
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        controller: _rgController,
                        label: 'RG',
                        maxLength: 5,
                         keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 15,
        children: [
          ElevatedButton.icon(icon: const Icon(Icons.delete), label: const Text('EXCLUIR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: _deleteData),
          ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('SALVAR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: _saveData),
          ElevatedButton.icon(icon: const Icon(Icons.print), label: const Text('RELATÓRIO'), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black), onPressed: _generateReport),
        ],
      ),
    );
  }
}