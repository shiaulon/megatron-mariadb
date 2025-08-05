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

class TabelaNaturezaRendimento extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaNaturezaRendimento({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaNaturezaRendimento> createState() =>
      _TabelaNaturezaRendimentoState();
}

class _TabelaNaturezaRendimentoState extends State<TabelaNaturezaRendimento> {
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _codigoNatRendimento = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _codigoNatRendimento.addListener(_onCodigoChanged);
  }

  CollectionReference get _collectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('natureza_rendimento')
      .collection('items');

  void _clearFields({bool clearCode = false}) {
    if (clearCode) {
      _codigoNatRendimento.clear();
    }
    _descricaoController.clear();
  }

  Future<void> _onCodigoChanged() async {
    final codigo = _codigoNatRendimento.text.trim();
    if (codigo.isEmpty) {
      _clearFields(clearCode: false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docSnapshot = await _collectionRef.doc(codigo).get();

      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
        action: LogAction.VIEW,
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
        targetCollection: 'natureza_rendimento',
        targetDocId: codigo,
        details:
            'Usuário consultou a Natureza de Rendimento cód. "$codigo". Resultado: ${docSnapshot.exists ? "Encontrado" : "Não encontrado"}.',
      );

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _descricaoController.text = data['descricao'] ?? '';
        });
      } else {
        _clearFields(clearCode: false);
      }
    } catch (e) {
      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
          action: LogAction.ERROR,
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          targetCollection: 'natureza_rendimento',
          targetDocId: codigo,
          details:
              'FALHA ao consultar Nat. Rendimento cód. "$codigo". Erro: ${e.toString()}');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao consultar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final docId = _codigoNatRendimento.text.trim();
    setState(() => _isLoading = true);

    final dataToSave = {
      'descricao': _descricaoController.text.trim(),
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'criado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      final docExists = (await _collectionRef.doc(docId).get()).exists;
      await _collectionRef.doc(docId).set(dataToSave);

      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
        action: docExists ? LogAction.UPDATE : LogAction.CREATE,
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
        targetCollection: 'natureza_rendimento',
        targetDocId: docId,
        details:
            'Usuário salvou/atualizou a Natureza de Rendimento: $docId - ${_descricaoController.text}.',
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Salvo com sucesso!')));
    } catch (e) {
      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
          action: LogAction.ERROR,
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          targetCollection: 'natureza_rendimento',
          targetDocId: docId,
          details:
              'FALHA ao salvar Nat. Rendimento $docId. Erro: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorreu um erro ao salvar.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
    final docId = _codigoNatRendimento.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha o código para excluir.')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir a Natureza de Rendimento $docId?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir'),
              style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _collectionRef.doc(docId).delete();

      await LogService.addLog(
          action: LogAction.DELETE,
          modulo: LogModule.TABELA, // <-- ADICIONADO
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          targetCollection: 'natureza_rendimento',
          targetDocId: docId,
          details: 'Usuário excluiu a Nat. Rendimento cód. $docId.');

      _clearFields(clearCode: true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Excluído com sucesso!')));
    } catch (e) {
      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
          action: LogAction.ERROR,
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          targetCollection: 'natureza_rendimento',
          targetDocId: docId,
          details:
              'FALHA ao excluir Nat. Rendimento $docId. Erro: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorreu um erro ao excluir.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _collectionRef.orderBy(FieldPath.documentId).get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum dado para gerar relatório.')));
        setState(() => _isLoading = false);
        return;
      }

      final pdf = pw.Document();
      final headers = ['Código', 'Descrição'];
      final data = querySnapshot.docs.map((doc) {
        final item = doc.data() as Map<String, dynamic>;
        return [doc.id, item['descricao'] ?? ''];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Header(
              level: 0,
              child: pw.Text(
                  'Relatório de Natureza de Rendimento - ${widget.secondaryCompanyId}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold))),
          build: (context) => [
            pw.Table.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold))
          ],
        ),
      );

      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
          action: LogAction.GENERATE_REPORT,
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          targetCollection: 'natureza_rendimento',
          details:
              'Usuário gerou um relatório da tabela de Nat. Rendimento.');

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
          action: LogAction.ERROR,
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          targetCollection: 'natureza_rendimento',
          details:
              'FALHA ao gerar relatório de Nat. Rendimento. Erro: ${e.toString()}');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateEmpresaCounter() => setState(() {});

  @override
  void dispose() {
    _codigoNatRendimento.removeListener(_onCodigoChanged);
    _codigoNatRendimento.removeListener(_updateEmpresaCounter);
    _descricaoController.removeListener(_updateEmpresaCounter);
    _codigoNatRendimento.dispose();
    _descricaoController.dispose();
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
                          mainCompanyId: widget.mainCompanyId,
                          secondaryCompanyId: widget.secondaryCompanyId,
                          userRole: widget.userRole,
                        )),
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
                child: Text('Natureza Rendimento',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
            child: Text('Natureza Rendimento',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomInputField(
                            controller: _codigoNatRendimento,
                            label: 'Cod. Natureza Rendimento',
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            maxLength: 5,
                            keyboardType: TextInputType.number,
                            suffixText:
                                '${_codigoNatRendimento.text.length}/5',
                            validator: (v) => v!.isEmpty || v.length < 5
                                ? 'Obrigatório (5 dígitos)'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          CustomInputField(
                            controller: _descricaoController,
                            label: 'Descrição',
                            maxLength: 40,
                            suffixText: '${_descricaoController.text.length}/40',
                            validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
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
          ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('EXCLUIR'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: _deleteData),
          ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('SALVAR'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white),
              onPressed: _saveData),
          ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('RELATÓRIO'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black),
              onPressed: _generateReport),
        ],
      ),
    );
  }
}