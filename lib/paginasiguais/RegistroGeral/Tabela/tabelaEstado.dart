import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/estado_service.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/services/pais_service.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

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
  final EstadoService _estadoService = EstadoService();
  final PaisService _paisService = PaisService();
  
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _siglaController = TextEditingController();
  
  String? _selectedPaisId;
  List<Map<String, dynamic>> _allPaises = [];
  List<Map<String, dynamic>> _allEstados = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _loadInitialData();
    _codigoController.addListener(_onCodigoChanged);
    _siglaController.addListener(_onEstadoChanged);
  }

  @override
  void dispose() {
    _codigoController.removeListener(_onCodigoChanged);
    _siglaController.removeListener(_onEstadoChanged);
    _codigoController.dispose();
    _estadoController.dispose();
    _siglaController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");

      final results = await Future.wait([
        _estadoService.getAll(token),
        _paisService.getAllPaises(token),
      ]);
      
      if (mounted) {
        setState(() {
          _allEstados = results[0];
          _allPaises = results[1];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCodigoChanged() {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _clearFields(clearCode: false);
      return;
    }
    final match = _allEstados.firstWhereOrNull((estado) => estado['id'].toString() == codigo);
    if (match != null) {
      _populateFields(match);
    } else {
      _clearFields(clearCode: false);
    }
  }

  void _onEstadoChanged() {
    setState(() {
      final String sigla = _siglaController.text.toUpperCase();
      if (sigla != 'EX') {
        var brasil = _allPaises.firstWhereOrNull((p) => (p['nome'] as String).toLowerCase() == 'brasil');
        if (brasil != null) {
          _selectedPaisId = brasil['id'];
        }
      }
    });
  }

  void _populateFields(Map<String, dynamic> data) {
    setState(() {
      _codigoController.text = data['id']?.toString() ?? '';
      _estadoController.text = data['nome'] ?? '';
      _siglaController.text = data['sigla'] ?? '';
      _selectedPaisId = data['pais_id'];
    });
  }

  void _clearFields({bool clearCode = true}) {
    if (clearCode) _codigoController.clear();
    _estadoController.clear();
    _siglaController.clear();
    setState(() {
      _selectedPaisId = null;
    });
  }
  
  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
      setState(() => _isLoading = false);
      return;
    }

    final dataToSave = {
      'id': _codigoController.text.trim(),
      'nome': _estadoController.text.trim(),
      'sigla': _siglaController.text.trim().toUpperCase(),
      'pais_id': _selectedPaisId,
      'secondaryCompanyId': widget.secondaryCompanyId,
    };

    try {
      await _estadoService.saveData(dataToSave, token);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado salvo com sucesso!'), backgroundColor: Colors.green));
      await _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
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
        content: Text('Deseja excluir o estado com código $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) { /* ... */ return; }
    
    try {
      await _estadoService.deleteData(docId, widget.secondaryCompanyId, token);
      _clearFields(clearCode: true);
      await _loadInitialData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado excluído com sucesso!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) { /* ... */ return; }
    final logService = LogService(token);

    try {
      if (_allEstados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum estado para gerar relatório.')));
        return;
      }
      
      await logService.addReportLog(
        reportName: 'Relatório de Estados',
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
      );

      final paisesMap = {for (var pais in _allPaises) pais['id']: pais};
      final reportData = _allEstados.map((estado) {
        final paisData = paisesMap[estado['pais_id']];
        return [
          estado['id'] ?? 'N/A',
          estado['nome'] ?? 'N/A',
          estado['sigla'] ?? 'N/A',
          paisData?['nome'] ?? 'País N/A',
        ];
      }).toList();

      final pdf = pw.Document();
      final headers = ['Código', 'Estado', 'Sigla', 'País'];
      
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(level: 0, child: pw.Text('Relatório de Estados', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        build: (context) => [pw.Table.fromTextArray(headers: headers, data: reportData)],
      ));

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        Expanded(flex: 1, child: AppDrawer(parentMaxWidth: constraints.maxWidth, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId)),
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
          AppDrawer(parentMaxWidth: 0, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId),
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
          child: Text(pais['nome']),
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
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
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