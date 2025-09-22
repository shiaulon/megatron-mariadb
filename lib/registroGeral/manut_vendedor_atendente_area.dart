// lib/registroGeral/manut_rg_vaa.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../reutilizaveis/barraSuperior.dart';
import '../reutilizaveis/customImputField.dart';
import '../reutilizaveis/menuLateral.dart';
import '../reutilizaveis/tela_base.dart';
import '../services/manut_rg_service.dart';
import 'package:flutter_application_1/reutilizaveis/botao_ajuda_flutuante.dart';

class ManutRgVAA extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;

  const ManutRgVAA({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
  });

  @override
  State<ManutRgVAA> createState() => _ManutRgVAAState();
}

class _ManutRgVAAState extends State<ManutRgVAA> {
  final ManutRgService _manutRgService = ManutRgService();
  bool _isLoading = false;

  Map<String, dynamic>? _rgData;
  List<Map<String, dynamic>> _rgSuggestions = [];
  
  // Controllers dos campos de busca
  final _codigoController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _razaoSocialController = TextEditingController();

  // Controllers dos campos de informação (read-only)
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();

  // Controllers dos campos editáveis
  final _vendedorController = TextEditingController();
  final _atendenteController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado");
      final suggestions = await _manutRgService.getRgSuggestions(token);
      if (mounted) setState(() => _rgSuggestions = suggestions);
    } catch (e) {
      if (mounted) _showErrorSnackbar('Erro ao carregar dados iniciais: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataById(String rgId) async {
    if (rgId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _manutRgService.getRgCompleto(rgId, token);
      if (mounted) {
        if (data.isNotEmpty) {
          _populateFields(data);
        } else {
          _clearFields();
          _showErrorSnackbar('Registro não encontrado.');
        }
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Erro ao carregar dados do RG: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    setState(() {
      _rgData = data;
      _codigoController.text = data['codigo_interno'] ?? '';
      _cpfCnpjController.text = data['id'] ?? '';
      _razaoSocialController.text = data['razao_social'] ?? '';
      _enderecoController.text = data['endereco'] ?? '';
      _numeroController.text = data['numero'] ?? '';
      _bairroController.text = data['bairro'] ?? '';
      _cidadeController.text = data['cidade_id'] ?? 'Não informado';
      
      _vendedorController.text = data['vendedor_id'] ?? '';
      _atendenteController.text = data['atendente_id'] ?? '';
      _areaController.text = data['area_id'] ?? '';
    });
  }

  void _clearFields() {
    setState(() {
      _rgData = null;
      _codigoController.clear();
      _cpfCnpjController.clear();
      _razaoSocialController.clear();
      _enderecoController.clear();
      _numeroController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _vendedorController.clear();
      _atendenteController.clear();
      _areaController.clear();
    });
  }

  Future<void> _saveData() async {
    if (_rgData == null) {
      _showErrorSnackbar('Nenhum registro carregado.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      await _manutRgService.updateRgAssociados(
        rgId: _rgData!['id'],
        vendedorId: _vendedorController.text,
        atendenteId: _atendenteController.text,
        areaId: _areaController.text,
        secondaryCompanyId: widget.secondaryCompanyId,
        token: token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildHelpContent() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ajuda - Manut. Vendedor/Atendente/Área', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        const ListTile(
          leading: Icon(Icons.search),
          title: Text('Use os campos de busca para encontrar e carregar os dados de um cliente.'),
        ),
        const ListTile(
          leading: Icon(Icons.edit),
          title: Text('Altere os códigos do Vendedor, Atendente e/ou Área e clique em "SALVAR" para efetuar a alteração.'),
        ),
      ],
    );
  }

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
                  currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: AppDrawer(
                              parentMaxWidth: constraints.maxWidth,
                              breakpoint: 700,
                              mainCompanyId: widget.mainCompanyId,
                              secondaryCompanyId: widget.secondaryCompanyId,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildMainContent(),
                            ),
                          ),
                        ],
                      );
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
      ),
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.colorScheme.primary, width: 1.0),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              'Manut RG "Vendedor/Atendente/Area"',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
          ),
          _buildTopSearchFields(),
          const SizedBox(height: 20),
          _buildInfoFields(),
          const SizedBox(height: 20),
          _buildEditableFields(),
          const SizedBox(height: 30),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildTopSearchFields() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildAutocompleteField('Código', _codigoController, 'codigo_interno')),
        const SizedBox(width: 16),
        Expanded(flex: 3, child: _buildAutocompleteField('CPF/CNPJ', _cpfCnpjController, 'id')),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: _buildAutocompleteField('Razão Social', _razaoSocialController, 'razao_social')),
      ],
    );
  }
  
  Widget _buildAutocompleteField(String label, TextEditingController controller, String fieldKey) {
    final theme = Theme.of(context);
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option[fieldKey] ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable.empty();
        }
        return _rgSuggestions.where((option) {
          return (option[fieldKey] ?? '').toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (selection) {
        _loadDataById(selection['id']);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (controller.text != fieldController.text) {
              fieldController.text = controller.text;
            }
        });
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: label,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: theme.cardColor,
          ),
        );
      },
    );
  }

  Widget _buildInfoFields() {
    final theme = Theme.of(context);
    final readOnlyDecoration = InputDecoration(
      filled: true,
      fillColor: theme.disabledColor.withOpacity(0.1),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.disabledColor),
      ),
      labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 4, child: CustomInputField(controller: _enderecoController, label: 'Endereço', readOnly: true, decoration: readOnlyDecoration)),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: CustomInputField(controller: _numeroController, label: 'Número', readOnly: true, decoration: readOnlyDecoration)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: CustomInputField(controller: _bairroController, label: 'Bairro', readOnly: true, decoration: readOnlyDecoration)),
            const SizedBox(width: 16),
            Expanded(child: CustomInputField(controller: _cidadeController, label: 'Cidade', readOnly: true, decoration: readOnlyDecoration)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildEditableFields() {
    return Row(
      children: [
        Expanded(child: CustomInputField(controller: _vendedorController, label: 'Vendedor')),
        const SizedBox(width: 16),
        Expanded(child: CustomInputField(controller: _atendenteController, label: 'Atendente')),
        const SizedBox(width: 16),
        Expanded(child: CustomInputField(controller: _areaController, label: 'Área')),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.save),
      label: const Text('SALVAR'),
      onPressed: _isLoading || _rgData == null ? null : _saveData,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}