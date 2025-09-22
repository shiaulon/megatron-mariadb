

import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/botao_ajuda_flutuante.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/manut_rg_service.dart';
import 'package:flutter_application_1/services/natureza_service.dart';
import 'package:flutter_application_1/services/natureza_x_rg_service.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class NaturezaXRgScreen extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const NaturezaXRgScreen({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<NaturezaXRgScreen> createState() => _NaturezaXRgScreenState();
}

class _NaturezaXRgScreenState extends State<NaturezaXRgScreen> {
  final NaturezaService _naturezaService = NaturezaService();
  final NaturezaXRgService _naturezaXRgService = NaturezaXRgService();
  final ManutRgService _manutRgService = ManutRgService();
  
  List<Map<String, dynamic>> _allNaturezas = [];
  List<Map<String, dynamic>> _allRgs = [];
  Map<String, dynamic>? _selectedNatureza;
  String? _selectedRgId;
  List<Map<String, dynamic>> _caracteristicasState = [];
  bool _isLoading = false;

  static const double _breakpoint = 900.0;
  late String _currentDate;

  final _naturezaController = TextEditingController();
  final _nomeNaturezaController = TextEditingController();
  final _rgIdController = TextEditingController(); // Agora para o CPF/CNPJ
  final _rgNomeController = TextEditingController(); // Para a Razão Social
  
  // Controllers do formulário
  final _setorController = TextEditingController();
  final _contaFinanceiraController = TextEditingController();
  final _aplicacaoController = TextEditingController();
  final _natRendimentoController = TextEditingController();
  final _opcaoNatRendimentoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _loadInitialData();
  }

  Widget _buildHelpContent() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ajuda - Envio de Avisos',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(height: 20),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Esta tela permite enviar uma mensagem em tempo real para todos os usuários que estiverem online no sistema.'),
        ),
        const ListTile(
          leading: Icon(Icons.history),
          title: Text('Abaixo do campo de envio, você pode visualizar um histórico dos últimos avisos enviados.'),
        ),
         ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          title: RichText(
            text: TextSpan(
              style: textTheme.bodyMedium,
              children: const [
                TextSpan(text: 'Atenção: '),
                TextSpan(text: 'As mensagens são enviadas instantaneamente e não podem ser desfeitas.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _clearForm() {
    _setorController.clear();
    _contaFinanceiraController.clear();
    _aplicacaoController.clear();
    _natRendimentoController.clear();
    _opcaoNatRendimentoController.clear();
    _caracteristicasState.forEach((c) => c['valorSelecionado'] = null);
    setState(() {});
  }

  Future<void> _onRgSelected(Map<String, dynamic> rg) async {
    _selectedRgId = rg['id']?.toString();
    setState(() {
      _rgIdController.text = rg['codigo_interno']?.toString() ?? '';
      _rgNomeController.text = rg['razao_social']?.toString() ?? '';
    });
    
    if (_selectedNatureza != null) {
      await _loadSavedConfig(_selectedRgId!);
    }
  }

  @override
  void dispose() {
    _naturezaController.dispose();
    _nomeNaturezaController.dispose();
    //_rgCodigoInternoController.dispose();
    _rgNomeController.dispose();
    _setorController.dispose();
    //_nomeSetorController.dispose();
    _contaFinanceiraController.dispose();
    //_nomeContaFinController.dispose();
    _aplicacaoController.dispose();
   // _nomeAplicacaoController.dispose();
    _natRendimentoController.dispose();
    //_nomeNatRendController.dispose();
    _opcaoNatRendimentoController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");
      _allNaturezas = await _naturezaService.getAll(token);
      _allRgs = await _manutRgService.getRgSuggestions(token);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados iniciais: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  

   Future<void> _onNaturezaSelected(Map<String, dynamic> natureza) async {
    _clearForm();
    setState(() {
      _selectedNatureza = natureza;
      _naturezaController.text = natureza['id']?.toString() ?? '';
      _nomeNaturezaController.text = natureza['descricao']?.toString() ?? '';
      
      final List<dynamic> caracteristicas = natureza['caracteristicas'] ?? [];
      _caracteristicasState = caracteristicas.map((carac) {
        return {
          'nome': carac['nome'],
          'opcoesSequencia': (carac['sequencias'] as List<dynamic>).map((s) => s.toString()).toList(),
          'valorSelecionado': null,
        };
      }).toList();
    });

    if (_selectedRgId != null) {
      await _loadSavedConfig(_selectedRgId!);
    }
  }

 
  

   Future<void> _loadSavedConfig(String rgId) async {
    if (rgId.isEmpty || _selectedNatureza == null) return;
    
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final naturezaId = _selectedNatureza!['id'];
      final savedData = await _naturezaXRgService.getData(rgId, naturezaId, token);
      
      if (savedData.isNotEmpty && mounted) {
        setState(() {
          _setorController.text = savedData['setor_id'] ?? '';
          _contaFinanceiraController.text = savedData['conta_financeira_id'] ?? '';
          _aplicacaoController.text = savedData['aplicacao_id'] ?? '';
          _natRendimentoController.text = savedData['nat_rendimento_id'] ?? '';
          _opcaoNatRendimentoController.text = savedData['opcao_nat_rendimento'] ?? '';

          final List<dynamic> savedCaracteristicas = savedData['caracteristicas_salvas'] ?? [];
          for (var savedCarac in savedCaracteristicas) {
            final index = _caracteristicasState.indexWhere((stateCarac) => stateCarac['nome'] == savedCarac['caracteristica']);
            if (index != -1) {
              _caracteristicasState[index]['valorSelecionado'] = savedCarac['sequencia'];
            }
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar configuração salva: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (_selectedRgId == null || _selectedNatureza == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um RG e uma Natureza para salvar.')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final List<Map<String, String?>> caracteristicasSelecionadas = [];
      _caracteristicasState.forEach((carac) {
        // Salva mesmo que a sequência não esteja selecionada, para manter a característica
        caracteristicasSelecionadas.add({
          'caracteristica': carac['nome'],
          'sequencia': carac['valorSelecionado'],
        });
      });

      final dataToSave = {
        'secondaryCompanyId': widget.secondaryCompanyId,
        'natureza_id': _naturezaController.text,
        'setor_id': _setorController.text,
        'conta_financeira_id': _contaFinanceiraController.text,
        'aplicacao_id': _aplicacaoController.text,
        'nat_rendimento_id': _natRendimentoController.text,
        'opcao_nat_rendimento': _opcaoNatRendimentoController.text,
        'caracteristicas_selecionadas': caracteristicasSelecionadas,
      };

      await _naturezaXRgService.saveData(_selectedRgId!, dataToSave, token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados salvos com sucesso!'), backgroundColor: Colors.green));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar dados: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  


  Future<void> _deleteData() async {
    final rgId = _selectedRgId;
    if (rgId == null || rgId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um RG para excluir.')));
      return;
    }

    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Exclusão'),
      content: Text('Tem certeza que deseja excluir a configuração para o RG "${_rgNomeController.text}"?'),
      actions: [
        TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop(false)),
        TextButton(child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ));
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final naturezaId = _selectedNatureza!['id'];
      if (token == null) throw Exception("Usuário não autenticado.");
      
      await _naturezaXRgService.deleteData(rgId, naturezaId, widget.secondaryCompanyId, token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro excluído com sucesso!')));
        _clearAllFields();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearAllFields() {
    _naturezaController.clear();
    _nomeNaturezaController.clear();
    _rgIdController.clear();
    //_rgCodigoInternoController.clear();
    _rgNomeController.clear();
    _setorController.clear();
    //_nomeSetorController.clear();
    _contaFinanceiraController.clear();
    //_nomeContaFinController.clear();
    _aplicacaoController.clear();
    //_nomeAplicacaoController.clear();
    _natRendimentoController.clear();
    //_nomeNatRendController.clear();
    _opcaoNatRendimentoController.clear();
    _clearNaturezaSelection();
    _clearRgSelection();
  }

  Future<void> _generateReport() async {
    final rgId = _selectedRgId;
    if (rgId == null || rgId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um RG para gerar o relatório.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final logService = LogService(token);
      final naturezaId = _selectedNatureza!['id'];

      final data = await _naturezaXRgService.getData(rgId, naturezaId, token);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum dado salvo para este RG.')));
        return;
      }
      await logService.addReportLog(
        reportName: 'Relatório Natureza X RG (RG: $rgId)',
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId,
      );
      final naturezaInfo = _allNaturezas.firstWhere((n) => n['id'] == data['natureza_id'], orElse: () => {});
      final rgInfo = _allRgs.firstWhere((rg) => rg['id'] == _selectedRgId, orElse: () => {});

      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Relatório - Natureza X RG', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.Text('RG (Cód. Interno): ${_rgIdController.text} - ${rgInfo['razao_social'] ?? 'N/A'}'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              
              pw.Text('Natureza: ${data['natureza_id']} - ${naturezaInfo['descricao'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Setor: ${data['setor_id']}'),
              pw.Text('Conta Financeira: ${data['conta_financeira_id']}'),
              pw.Text('Aplicação: ${data['aplicacao_id']}'),
              pw.Text('Nat. de Rendimento: ${data['nat_rendimento_id']}'),
              pw.SizedBox(height: 20),
              
              pw.Text('Seleção de Características:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['Característica', 'Sequência Selecionada'],
                data: (data['caracteristicas_salvas'] as List).map((item) => [item['caracteristica'], item['sequencia']]).toList(),
              ),
              
              pw.SizedBox(height: 20),
              pw.Text('Opção: ${data['opcao_nat_rendimento']}'),
            ],
          );
        },
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required String fieldKey,
    required List<Map<String, dynamic>> options,
    required Function(Map<String, dynamic>) onSelected,
    required VoidCallback onClear,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option[fieldKey]?.toString() ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return options.where((option) {
          final fieldValue = option[fieldKey]?.toString().toLowerCase() ?? '';
          return fieldValue.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (selection) {
        onSelected(selection);
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
          onChanged: (value) {
            controller.text = value;
            if (value.isEmpty) onClear();
          },
        );
      },
    );
  }

  void _clearNaturezaSelection() {
    setState(() {
      _naturezaController.clear();
      _nomeNaturezaController.clear();
      _selectedNatureza = null;
      _caracteristicasState.clear();
    });
  }
  
  void _clearRgSelection() {
    setState(() {
      _selectedRgId = null;
      _rgIdController.clear();
      _rgNomeController.clear();
      _clearNaturezaSelection();
    });
  }

  // --- BUILD METHODS ---
  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: BotaoAjudaFlutuante(
        helpContent: _buildHelpContent(),
        child: Stack(
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
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: AppDrawer(parentMaxWidth: constraints.maxWidth, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId)),
        Expanded(flex: 8, child: _buildCentralContent()),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppDrawer(parentMaxWidth: constraints.maxWidth, breakpoint: _breakpoint, mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId),
          _buildCentralContent(),
        ],
      ),
    );
  }
  
  Widget _buildCentralContent() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('Manut RG "Natureza X RG"', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
            child: _buildMainForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainForm() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                  ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildLeftInputFields()),
                const SizedBox(width: 20),
                const VerticalDivider(color: Colors.blue, thickness: 1),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: _buildRightInputFields()),
              ],
            ),
          ),
          const SizedBox(height: 10),
          //_buildOptionRow(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 15,
      children: [
        _buildActionButton('EXCLUIR', Colors.red, _deleteData),
        _buildActionButton('SALVAR', Colors.green, _saveData),
        _buildActionButton('RELATÓRIO', Colors.yellow, _generateReport),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback? onPressed) {
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

  Widget _buildLeftInputFields() {
    // ▼▼▼ CORREÇÃO AQUI - Removido os campos duplicados de "Nome" ▼▼▼
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAutocompleteField(controller: _rgIdController, label: 'Código RG', fieldKey: 'codigo_interno', options: _allRgs, onSelected: _onRgSelected, onClear: _clearRgSelection)),
              const SizedBox(width: 10),
              Expanded(child: _buildAutocompleteField(controller: _rgNomeController, label: 'Nome RG', fieldKey: 'razao_social', options: _allRgs, onSelected: _onRgSelected, onClear: _clearRgSelection)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAutocompleteField(controller: _naturezaController, label: 'Natureza', fieldKey: 'id', options: _allNaturezas, onSelected: _onNaturezaSelected, onClear: _clearNaturezaSelection)),
              const SizedBox(width: 10),
              Expanded(child: _buildAutocompleteField(controller: _nomeNaturezaController, label: 'Nome Natureza', fieldKey: 'descricao', options: _allNaturezas, onSelected: _onNaturezaSelected, onClear: _clearNaturezaSelection)),
            ],
          ),
          const SizedBox(height: 15),
          CustomInputField(controller: _setorController, label: 'Setor'),
          const SizedBox(height: 15),
          CustomInputField(controller: _contaFinanceiraController, label: 'Conta financeira'),
          const SizedBox(height: 15),
          CustomInputField(controller: _aplicacaoController, label: 'Aplicação'),
          const SizedBox(height: 15),
          CustomInputField(controller: _natRendimentoController, label: 'Nat de rendimento'),
        ],
      ),
    );
  }

  Widget _buildRightInputFields() {
    if (_selectedNatureza == null) {
      return const Center(child: Text('Selecione uma Natureza para ver as características.'));
    }
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Text('Característica', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 10),
            Expanded(child: Text('Sequencia', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 5),
        Expanded(
          child: ListView.builder(
            itemCount: _caracteristicasState.length,
            itemBuilder: (context, index) {
              final carac = _caracteristicasState[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomInputField(
                        controller: TextEditingController(text: carac['nome']),
                        label: '',
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: carac['valorSelecionado'],
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          filled: true,
                          //fillColor: Colors.white,
                        ),
                        hint: const Text('Selecione'),
                        items: (carac['opcoesSequencia'] as List<String>).map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _caracteristicasState[index]['valorSelecionado'] = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionRow() {
    return Row(
      children: [
        const Text('OPÇÃO:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: CustomInputField(controller: _opcaoNatRendimentoController, label: 'Nat. de Rendimento')),
      ],
    );
  }
}