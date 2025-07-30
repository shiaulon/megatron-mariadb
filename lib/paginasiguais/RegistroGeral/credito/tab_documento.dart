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


class TabelaCreditoDocumentosBasicos extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaCreditoDocumentosBasicos({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaCreditoDocumentosBasicos> createState() => _TabelaCreditoDocumentosBasicosState();
}

class _TabelaCreditoDocumentosBasicosState extends State<TabelaCreditoDocumentosBasicos> {
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  // Controladores para os novos campos
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _documentosBasicosController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _codigoController.addListener(_onCodigoChanged);
  }

  // Referência para a nova coleção no Firestore
  CollectionReference get _collectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('credito_documentos_basicos') // <- NOME DA COLEÇÃO ATUALIZADO
      .collection('items');

  void _clearFields({bool clearCode = false}) {
    if (clearCode) {
      _codigoController.clear();
    }
    _documentosBasicosController.clear();
    setState(() {}); // Apenas para reconstruir a UI se necessário
  }

  Future<void> _onCodigoChanged() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _clearFields();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docSnapshot = await _collectionRef.doc(codigo).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          // Carrega os dados do campo 'documentos_basicos'
          _documentosBasicosController.text = data['documentos_basicos'] ?? '';
        });
      } else {
        _clearFields();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar documento: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final docId = _codigoController.text.trim();
    setState(() => _isLoading = true);

    // Mapa de dados com os novos campos
    final dataToSave = {
      'documentos_basicos': _documentosBasicosController.text.trim(),
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'criado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      final docExists = (await _collectionRef.doc(docId).get()).exists;
      await _collectionRef.doc(docId).set(dataToSave);
      await LogService.addLog(
      action: docExists ? LogAction.UPDATE : LogAction.CREATE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'credito_documentos_basicos',
      targetDocId: docId,
      details: 'Usuário salvou/atualizou o documento com código $docId.',
    );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento salvo com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
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
        content: Text('Deseja excluir o documento com código $docId?'),
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
      await LogService.addLog(
      action: LogAction.DELETE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'credito_documentos_basicos',
      targetDocId: docId,
      details: 'Usuário excluiu o documento com código $docId.',
    );
      _clearFields(clearCode: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento excluído com sucesso!')),
      );
    } catch (e) {
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
      final querySnapshot = await _collectionRef.get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum documento para gerar relatório.')));
        setState(() => _isLoading = false);
        return;
      }

      final pdf = pw.Document();
      // Cabeçalhos e dados do relatório atualizados
      final headers = ['Código', 'Documentos Básicos'];
      final data = querySnapshot.docs.map((doc) {
        final item = doc.data() as Map<String, dynamic>;
        return [doc.id, item['documentos_basicos'] ?? ''];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Relatório de Documentos Básicos - ${widget.secondaryCompanyId}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
              },
            )
          ],
        ),
      );

      await LogService.addLog(
        action: LogAction.GENERATE_REPORT,
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
        targetCollection: 'credito_documentos_basicos',
        details: 'Usuário gerou um relatório da tabela de documentos básicos.',
      );


      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codigoController.removeListener(_onCodigoChanged);
    _codigoController.dispose();
    _documentosBasicosController.dispose();
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
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: Text('Documentos Básicos de Crédito', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), // TÍTULO ATUALIZADO
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
            child: Text('Documentos Básicos de Crédito', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // TÍTULO ATUALIZADO
          ),
          AppDrawer(
            parentMaxWidth: 0,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: CustomInputField(
                              controller: _codigoController,
                              label: 'Código',
                              maxLength: 4, // Aumentado para 4 dígitos se necessário
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                          
                          
                        ],
                      ),
                      Row(children: [
                        Expanded(
                            flex: 3,
                            child: CustomInputField(
                              controller: _documentosBasicosController,
                              label: 'Documentos Básicos', // LABEL ATUALIZADA
                              maxLength: 100, // Aumentado para mais texto
                              maxLines: 3, // Permite múltiplas linhas
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                      ],)
                      // A seção de "Bloqueio" foi removida
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
              const SizedBox(height: 20,),
            ],
          ),
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