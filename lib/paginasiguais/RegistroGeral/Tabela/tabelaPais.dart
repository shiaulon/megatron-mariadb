import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/pais_service.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// REMOVIDOS: Imports do Firebase ('cloud_firestore', 'firebase_auth', 'log_services')

class TabelaPais extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaPais({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaPais> createState() => _TabelaPaisState();
}

class _TabelaPaisState extends State<TabelaPais> {
  final PaisService _paisService = PaisService();
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _resumoController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _codigoPaisController = TextEditingController();

  List<Map<String, dynamic>> _allPaises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllPaises();
    _codigoController.addListener(_onCodigoChanged);
    _paisController.addListener(_onNomeChanged);
  }

  @override
  void dispose() {
    _codigoController.removeListener(_onCodigoChanged);
    _paisController.removeListener(_onNomeChanged);
    _codigoController.dispose();
    _resumoController.dispose();
    _paisController.dispose();
    _codigoPaisController.dispose();
    super.dispose();
  }

  void _onCodigoChanged() {
    final text = _codigoController.text;
    if (text.isEmpty) {
      _clearFormFields(clearCodigo: false, clearNome: false);
      return;
    }
    final exactMatches = _allPaises.where((p) => p['id'].toString() == text).toList();
    if (exactMatches.length == 1) {
      _populateForm(exactMatches.first);
    } else {
      _clearFormFields(clearCodigo: false, clearNome: true);
    }
  }

  void _onNomeChanged() {
    final text = _paisController.text;
    final exactMatches = _allPaises.where((p) => p['nome']?.toString().toLowerCase() == text.toLowerCase()).toList();
    if (exactMatches.length == 1) {
      _populateForm(exactMatches.first);
    } else if (text.isEmpty) {
      _clearFormFields(clearNome: false);
    }
  }

  Future<void> _fetchAllPaises() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");
      final paises = await _paisService.getAllPaises(token);
      if (mounted) {
        setState(() {
          _allPaises = paises;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar países: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    setState(() {
      _codigoController.text = data['id']?.toString() ?? '';
      _paisController.text = data['nome']?.toString() ?? '';
      _resumoController.text = data['resumo']?.toString() ?? '';
      _codigoPaisController.text = data['codigo_bacen']?.toString() ?? '';
    });
  }

  void _clearFormFields({bool clearCodigo = true, bool clearNome = true}) {
    if (clearCodigo) _codigoController.clear();
    if (clearNome) _paisController.clear();
    _resumoController.clear();
    _codigoPaisController.clear();
    setState(() {}); // Para atualizar contadores
  }

  Future<void> _savePaisData() async {
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
      'nome': _paisController.text.trim(),
      'resumo': _resumoController.text.trim(),
      'codigo_bacen': _codigoPaisController.text.trim(),
    };

    try {
      await _paisService.saveData(dataToSave, token);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('País salvo com sucesso!'), backgroundColor: Colors.green));
      await _fetchAllPaises(); // Atualiza a lista para o autocomplete
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar país: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePaisData() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite um código para excluir.')));
      return;
    }
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Exclusão'),
      content: Text('Tem certeza que deseja excluir o país com código "$codigo"?'),
      actions: [
        TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop(false)),
        TextButton(child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ));

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) { /* ... Lida com erro de token ... */ return; }

    try {
      await _paisService.deleteData(codigo, token);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('País "$codigo" excluído com sucesso!')));
      _clearFormFields();
      await _fetchAllPaises();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir país: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      if (_allPaises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum país para gerar relatório.')));
        return;
      }
      _allPaises.sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
      final pdf = pw.Document();
      final headers = ['Código', 'País', 'Resumo', 'Cód. Bacen'];
      final data = _allPaises.map((pais) => [
        pais['id']?.toString() ?? '',
        pais['nome']?.toString() ?? '',
        pais['resumo']?.toString() ?? '',
        pais['codigo_bacen']?.toString() ?? '',
      ]).toList();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(level: 0, child: pw.Text('Relatório de Países', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: AppDrawer(parentMaxWidth: constraints.maxWidth, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId)),
        Expanded(flex: 3, child: Column(children: [
          const Padding(padding: EdgeInsets.only(top: 20.0, bottom: 0.0), child: Center(child: Text('País', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)))),
          Expanded(child: _buildCentralInputArea()),
        ])),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      child: Column(children: [
        const Padding(padding: EdgeInsets.only(top: 15.0, bottom: 8.0), child: Center(child: Text('País', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)))),
        AppDrawer(parentMaxWidth: constraints.maxWidth, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId),
        _buildCentralInputArea(),
      ]),
    );
  }

  Widget _buildCentralInputArea() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Container(
        decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAutocompleteField(_codigoController, "Código", "id", isNumeric: true, maxLength: 4, isRequired: true),
                    const SizedBox(height: 20),
                    _buildAutocompleteField(_paisController, "País", "nome", maxLength: 50, isRequired: true),
                    const SizedBox(height: 20),
                    CustomInputField(controller: _resumoController, label: 'Resumo', maxLength: 15),
                    const SizedBox(height: 20),
                    CustomInputField(controller: _codigoPaisController, label: 'Código Bacen', maxLength: 5, /*isNumeric: true*/),
                  ],
                ),
              )),
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteField(TextEditingController controller, String label, String fieldKey, {bool isRequired = false, bool isNumeric = false, int? maxLength}) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option[fieldKey]?.toString() ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _allPaises.where((option) {
          final fieldValue = option[fieldKey]?.toString().toLowerCase() ?? '';
          return fieldValue.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (selection) {
        _populateForm(selection);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        if (controller.text != fieldController.text) {
          fieldController.value = controller.value;
        }
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: label,
          maxLength: maxLength,
          
          validator: isRequired ? (v) => v!.isEmpty ? 'Campo obrigatório' : null : null,
          inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onChanged: (value) {
            controller.text = value;
          },
        );
      },
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
          _buildActionButton('EXCLUIR', Colors.red, _deletePaisData),
          _buildActionButton('SALVAR', Colors.green, _savePaisData),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}