import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/natureza_rendimento_service.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:provider/provider.dart';
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
  State<TabelaNaturezaRendimento> createState() => _TabelaNaturezaRendimentoState();
}

class _TabelaNaturezaRendimentoState extends State<TabelaNaturezaRendimento> {
  final NaturezaRendimentoService _service = NaturezaRendimentoService();
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _codigoNatRendimento = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllData();
    _codigoNatRendimento.addListener(_onCodigoChanged);
  }

  @override
  void dispose() {
    _codigoNatRendimento.removeListener(_onCodigoChanged);
    _codigoNatRendimento.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
  
  void _onCodigoChanged() {
    final text = _codigoNatRendimento.text;
    if (text.isEmpty) {
      _clearFields(clearCode: false);
      return;
    }
    final exactMatches = _allData.where((item) => item['id'].toString() == text).toList();
    if (exactMatches.length == 1) {
      _populateForm(exactMatches.first);
    } else {
      _clearFields(clearCode: false);
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");
      final data = await _service.getAll(token);
      if (mounted) {
        setState(() {
          _allData = data;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    setState(() {
      _codigoNatRendimento.text = data['id']?.toString() ?? '';
      _descricaoController.text = data['descricao']?.toString() ?? '';
    });
  }

  void _clearFields({bool clearCode = true}) {
    if (clearCode) _codigoNatRendimento.clear();
    _descricaoController.clear();
  }

  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) { /* Lida com erro de token */ return; }

    final dataToSave = {
      'id': _codigoNatRendimento.text.trim(),
      'descricao': _descricaoController.text.trim(),
    };

    try {
      await _service.saveData(dataToSave, token);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo com sucesso!'), backgroundColor: Colors.green));
      await _fetchAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
  final docId = _codigoNatRendimento.text.trim();
  if (docId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preencha o código para excluir.')),
    );
    return;
  }

  // --- CORREÇÃO AQUI ---
  // Adiciona o contexto e o builder para criar o diálogo
  final confirm = await showDialog<bool>(
    context: context, // O contexto da tela
    builder: (ctx) => AlertDialog( // O construtor do diálogo
      title: const Text('Confirmar Exclusão'),
      content: Text('Deseja excluir a Natureza de Rendimento com código "$docId"?'),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(ctx).pop(false), // Fecha e retorna 'false'
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Excluir'),
          onPressed: () => Navigator.of(ctx).pop(true), // Fecha e retorna 'true'
        ),
      ],
    ),
  );
  // --- FIM DA CORREÇÃO ---
  if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) { /* Lida com erro de token */ return; }

    try {
      await _service.deleteData(docId, token);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído com sucesso!')));
      _clearFields(clearCode: true);
      await _fetchAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      if (_allData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum dado para gerar relatório.')));
        return;
      }
      _allData.sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
      final pdf = pw.Document();
      final headers = ['Código', 'Descrição'];
      final data = _allData.map((item) => [item['id']?.toString() ?? '', item['descricao']?.toString() ?? '']).toList();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(level: 0, child: pw.Text('Relatório de Natureza de Rendimento')),
        build: (context) => [pw.Table.fromTextArray(headers: headers, data: data)],
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A UI que você já tinha, mas agora conectada aos novos métodos.
    // O código da UI original (com TelaBase, LayoutBuilder, etc.) pode ser mantido.
    // Apenas garanta que os botões chamem as funções corretas: _saveData, _deleteData, _generateReport.
    return TelaBase(
      body: Stack(
        children: [
          Column(
            children: [
              TopAppBar(
                onBackPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TelaSubPrincipal(mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId))),
                currentDate: _currentDate,
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth > _breakpoint) {
                    return _buildDesktopLayout(constraints);
                  } else {
                    return _buildMobileLayout(constraints);
                  }
                }),
              ),
            ],
          ),
          if (_isLoading)
            Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  // Cole seus widgets de UI aqui (_buildDesktopLayout, _buildMobileLayout, _buildCentralInputArea, etc)
  // Exemplo da área central:
  
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