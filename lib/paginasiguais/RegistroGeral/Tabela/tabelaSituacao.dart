// lib/paginasiguais/RegistroGeral/Tabela/tabelaSituacao.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../services/situacao_service.dart'; // <<< IMPORTE O NOVO SERVIÇO

class TabelaSituacao extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaSituacao({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaSituacao> createState() => _TabelaSituacaoState();
}

class _TabelaSituacaoState extends State<TabelaSituacao> {
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final SituacaoService _situacaoService = SituacaoService(); // <<< USE O NOVO SERVIÇO
  List<Map<String, dynamic>> _allSituacoes = [];

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  
  String _selectedBloqueioOption = 'Normal';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _loadSituacoes();
    _codigoController.addListener(_onCodigoChanged);
  }

  Future<void> _loadSituacoes() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");
      
      final situacoes = await _situacaoService.getAll(token);
      if (mounted) {
        setState(() {
          _allSituacoes = situacoes;
        });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar situações: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFields({bool clearCode = false}) {
    if (clearCode) {
      _codigoController.clear();
    }
    _descricaoController.clear();
    setState(() {
      _selectedBloqueioOption = 'Normal';
    });
  }

  void _onCodigoChanged() {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _clearFields();
      return;
    }
    final situacao = _allSituacoes.firstWhere(
      (s) => s['id'].toString() == codigo,
      orElse: () => <String, dynamic>{},
    );

    if (situacao.isNotEmpty) {
      setState(() {
        _descricaoController.text = situacao['descricao'] ?? '';
        _selectedBloqueioOption = situacao['bloqueio'] ?? 'Normal';
      });
    } else {
      _clearFields();
    }
  }

  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final docId = _codigoController.text.trim();
    setState(() => _isLoading = true);

    final dataToSave = {
      'id': docId,
      'descricao': _descricaoController.text.trim(),
      'bloqueio': _selectedBloqueioOption,
      'mainCompanyId': widget.mainCompanyId,
      'secondaryCompanyId': widget.secondaryCompanyId,
    };

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      await _situacaoService.saveData(dataToSave, token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Situação salva com sucesso!'), backgroundColor: Colors.green),
        );
        _loadSituacoes(); // Recarrega a lista
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        content: Text('Deseja excluir a situação com código $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      await _situacaoService.deleteData(docId, widget.secondaryCompanyId, token);
      
      if(mounted) {
        _clearFields(clearCode: true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Situação excluída com sucesso!')));
        _loadSituacoes(); // Recarrega a lista
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_allSituacoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma situação para gerar relatório.')));
      return;
    }
    setState(() => _isLoading = true);
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final logService = LogService(token);
      await logService.addReportLog(
        reportName: 'Relatório de Situações',
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
      );

      final pdf = pw.Document();
      final headers = ['Código', 'Descrição', 'Bloqueio'];
      final data = _allSituacoes.map((item) {
        return [item['id'] ?? '', item['descricao'] ?? '', item['bloqueio'] ?? ''];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Relatório de Situações - ${widget.secondaryCompanyId}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            )
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codigoController.removeListener(_onCodigoChanged);
    _codigoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // A partir daqui, o método build e os sub-widgets
  // permanecem os mesmos, pois a lógica de UI não muda.
  // Cole o restante do seu código (build, _buildDesktopLayout, etc.) aqui.
  
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
                child: Text('Situação', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
            child: Text('Situação', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: CustomInputField(
                              controller: _codigoController,
                              label: 'Código',
                              maxLength: 2,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 20,),
                          Expanded(
                            flex: 3,
                            child: CustomInputField(
                                                    controller: _descricaoController,
                                                    label: 'Descrição',
                                                    maxLength: 30,
                                                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      const SizedBox(height: 20),
                      _buildBloqueioOptions(),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
              SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBloqueioOptions() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                  ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(child: Text('Bloqueio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Normal'),
                  value: 'Normal',
                  groupValue: _selectedBloqueioOption,
                  onChanged: (v) => setState(() => _selectedBloqueioOption = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Mensagem'),
                  value: 'Mensagem',
                  groupValue: _selectedBloqueioOption,
                  onChanged: (v) => setState(() => _selectedBloqueioOption = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Bloqueio'),
                  value: 'Bloqueio',
                  groupValue: _selectedBloqueioOption,
                  onChanged: (v) => setState(() => _selectedBloqueioOption = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Apenas Dinheiro'),
                  value: 'Apenas Dinheiro',
                  groupValue: _selectedBloqueioOption,
                  onChanged: (v) => setState(() => _selectedBloqueioOption = v!),
                ),
              ),
            ],
          ),
          
        ],
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
