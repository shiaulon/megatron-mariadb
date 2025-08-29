// lib/telas/tabela_credito_faixas.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/credito_docs_service.dart';
import 'package:flutter_application_1/services/credito_faixas_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


// Formatador para valores monetários
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return const TextEditingValue();
    if (cleanText.length > 11) cleanText = cleanText.substring(0, 11);

    double value = double.parse(cleanText) / 100;
    
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
    String newText = formatter.format(value).replaceAll('R\$', '').trim();

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}


class TabelaCreditoFaixas extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaCreditoFaixas({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaCreditoFaixas> createState() => _TabelaCreditoFaixasState();
}

class _TabelaCreditoFaixasState extends State<TabelaCreditoFaixas> {
  final _service = CreditoFaixasService();
  final _docsService = CreditoDocsService();

  static const double _breakpoint = 700.0;
  
  bool _isLoading = false;
  String? _selectedPessoa = 'fisica'; // Valor inicial
  
  // Lista de todos os documentos disponíveis para os dropdowns
  List<Map<String, dynamic>> _allDocumentos = [];

  // Controllers para as 5 faixas de valor
  final List<TextEditingController> _faixaInicioControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _faixaFimControllers = List.generate(5, (_) => TextEditingController());
  
  // Controllers para os documentos de cada faixa
  final Map<int, List<String?>> _documentosSelecionados = {};
  int? _selectedFaixaIndex;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      _allDocumentos = await _docsService.getAllDocumentos(token);
      await _loadDataForSelectedPessoa();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataForSelectedPessoa() async {
    if (_selectedPessoa == null) return;
    
    _clearForm();
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _service.getData(_selectedPessoa!, token);
      
      if (mounted && data.isNotEmpty) {
        setState(() {
          for (int i = 0; i < 5; i++) {
            _faixaInicioControllers[i].text = data['faixa${i+1}_inicio'] ?? '';
            _faixaFimControllers[i].text = data['faixa${i+1}_fim'] ?? '';
          }
          final Map<String, dynamic> documentos = data['documentos'] ?? {};
          documentos.forEach((faixaKey, docList) {
            int faixaIndex = int.parse(faixaKey.replaceAll('faixa', '')) - 1;
            _documentosSelecionados[faixaIndex] = List<String?>.from(docList);
          });
        });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      for (var c in _faixaInicioControllers) { c.clear(); }
      for (var c in _faixaFimControllers) { c.clear(); }
      _documentosSelecionados.clear();
      _selectedFaixaIndex = null;
    });
  }

  Future<void> _saveData() async {
    if (_selectedPessoa == null) return;
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      
      final Map<String, dynamic> dataToSave = {
        'tipo_pessoa': _selectedPessoa,
        'mainCompanyId': widget.mainCompanyId,
        'secondaryCompanyId': widget.secondaryCompanyId,
      };

      for (int i = 0; i < 5; i++) {
        dataToSave['faixa${i+1}_inicio'] = _faixaInicioControllers[i].text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
        dataToSave['faixa${i+1}_fim'] = _faixaFimControllers[i].text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
      }

      final Map<String, List<String>> docsParaSalvar = {};
      _documentosSelecionados.forEach((faixaIndex, docList) {
        docsParaSalvar['faixa${faixaIndex+1}'] = docList.where((d) => d != null).cast<String>().toList();
      });
      dataToSave['documentos'] = docsParaSalvar;

      await _service.saveData(dataToSave, token);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo com sucesso!')));
      await _loadDataForSelectedPessoa();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
     if (_selectedPessoa == null) return;

    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Exclusão'),
      content: Text('Tem certeza que deseja excluir toda a configuração para Pessoa ${_selectedPessoa}?'),
      actions: [
        TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop(false)),
        TextButton(child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ));

    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      await _service.deleteData(_selectedPessoa!, token);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído com sucesso!')));
      _clearForm();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _addDocumentoField() {
    if (_selectedFaixaIndex == null) return;
    setState(() {
      _documentosSelecionados.putIfAbsent(_selectedFaixaIndex!, () => []);
      if (_documentosSelecionados[_selectedFaixaIndex!]!.length < 8) {
        _documentosSelecionados[_selectedFaixaIndex!]!.add(null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limite de 8 documentos por faixa atingido.')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Stack(
        children: [
          Column(
            children: [
              TopAppBar(
                currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                onBackPressed: () => Navigator.of(context).pop(),
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
          
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final theme = Theme.of(context);
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
          flex: 4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text('Natureza de Crédito por Faixa', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        _buildPessoaSelector(),
                        const Divider(height: 30),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildFaixasColumn()),
                              const VerticalDivider(width: 30, thickness: 1),
                              Expanded(flex: 2, child: _buildDocumentosColumn()),
                            ],
                          ),
                        ),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPessoaSelector() {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPessoa,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'fisica', child: Text('Pessoa Física')),
            DropdownMenuItem(value: 'juridica', child: Text('Pessoa Jurídica')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedPessoa = value);
              _loadDataForSelectedPessoa();
            }
          },
        ),
      ),
    );
  }

  Widget _buildFaixasColumn() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        bool isSelected = _selectedFaixaIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedFaixaIndex = index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Text('Faixa ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomInputField(
                    controller: _faixaInicioControllers[index],
                    label: 'De',
                    inputFormatters: [MoneyInputFormatter()],
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('a'),
                ),
                Expanded(
                  child: CustomInputField(
                    controller: _faixaFimControllers[index],
                    label: 'Até',
                    inputFormatters: [MoneyInputFormatter()],
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentosColumn() {
    if (_selectedFaixaIndex == null) {
      return const Center(child: Text('Selecione uma faixa à esquerda para ver/adicionar documentos.'));
    }
    
    final documentosDaFaixa = _documentosSelecionados.putIfAbsent(_selectedFaixaIndex!, () => [null]);

    return Column(
      children: [
        const Text('Documentos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(
          child: ListView.builder(
            itemCount: documentosDaFaixa.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: DropdownButtonFormField<String>(
                  value: documentosDaFaixa[index],
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Documento ${index + 1}',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: _allDocumentos.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc['id'],
                      child: Text(doc['documentos_basicos']),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      documentosDaFaixa[index] = newValue;
                    });
                  },
                ),
              );
            },
          ),
        ),
        if (documentosDaFaixa.length < 8)
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
          onPressed: _addDocumentoField,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(icon: const Icon(Icons.delete), label: const Text('EXCLUIR'), onPressed: _deleteData, style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white)),
          ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('SALVAR'), onPressed: _saveData, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white)),
          ElevatedButton.icon(icon: const Icon(Icons.print), label: const Text('RELATÓRIO'), onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white)),
        ],
      ),
    );
  }
}