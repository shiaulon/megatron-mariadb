// lib/registroGeral/manut_rg_situacao.dart

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

class ManutRgSituacao extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;

  const ManutRgSituacao({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
  });

  @override
  State<ManutRgSituacao> createState() => _ManutRgSituacaoState();
}

class _ManutRgSituacaoState extends State<ManutRgSituacao> {
  final ManutRgService _manutRgService = ManutRgService();
  bool _isLoading = false;

  Map<String, dynamic>? _rgData;
  List<Map<String, dynamic>> _rgSuggestions = [];
  List<Map<String, dynamic>> _allSituacoes = [];
  String? _selectedSituacaoId;

  final _codigoController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _razaoSocialController = TextEditingController();

  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }
  
  // Seus métodos de lógica (_fetchInitialData, _loadDataById, etc.)
  // permanecem os mesmos e foram omitidos para brevidade.
  // Cole-os de volta aqui do seu código original.

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado");

      final results = await Future.wait([
        _manutRgService.getRgSuggestions(token),
        _manutRgService.getDadosAuxiliares('situacoes', token),
      ]);

      if (mounted) {
        setState(() {
          _rgSuggestions = results[0];
          _allSituacoes = results[1];
        });
      }
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

      final newSituacaoId = data['situacao_id'];
      if (_allSituacoes.any((s) => s['id'] == newSituacaoId)) {
        _selectedSituacaoId = newSituacaoId;
      } else {
        _selectedSituacaoId = null;
      }
    });
  }

  void _clearFields() {
    setState(() {
      _rgData = null;
      _selectedSituacaoId = null;
      _codigoController.clear();
      _cpfCnpjController.clear();
      _razaoSocialController.clear();
      _enderecoController.clear();
      _numeroController.clear();
      _bairroController.clear();
      _cidadeController.clear();
    });
  }

  Future<void> _saveData() async {
    if (_rgData == null || _selectedSituacaoId == null) {
      _showErrorSnackbar('Nenhum registro carregado ou situação selecionada.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      await _manutRgService.updateRgSituacao(
        rgId: _rgData!['id'],
        situacaoId: _selectedSituacaoId!,
        secondaryCompanyId: widget.secondaryCompanyId,
        token: token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Situação salva com sucesso!'), backgroundColor: Colors.green),
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
        Text('Ajuda - Manutenção de Situação do RG', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        const ListTile(
          leading: Icon(Icons.search),
          title: Text('Use os campos de busca (Código, CPF/CNPJ ou Razão Social) para encontrar e carregar os dados de um cliente.'),
        ),
        const ListTile(
          leading: Icon(Icons.edit_off),
          title: Text('Os dados de endereço são apenas para visualização e não podem ser editados nesta tela.'),
        ),
        const ListTile(
          leading: Icon(Icons.edit),
          title: Text('O único campo editável é a "Situação". Selecione a nova situação na lista e clique em "SALVAR" para efetuar a alteração.'),
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
    // ▼▼▼ CORREÇÃO DE TEMA AQUI ▼▼▼
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
              'Manut. RG "Situação"',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineSmall?.color, // Garante cor do tema
                  ),
            ),
          ),
          _buildTopSearchFields(),
          const SizedBox(height: 20),
          _buildInfoFields(),
          const SizedBox(height: 20),
          _buildSituacaoField(),
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
    final readOnlyDecoration = InputDecoration(
      filled: true,
      fillColor: theme.disabledColor.withOpacity(0.1), // Cor adaptável
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.disabledColor),
      ),
      labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
    );
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
          decoration: readOnlyDecoration
        );
      },
    );
  }

  Widget _buildInfoFields() {
    // ▼▼▼ CORREÇÃO DE TEMA AQUI ▼▼▼
    final theme = Theme.of(context);
    final readOnlyDecoration = InputDecoration(
      filled: true,
      fillColor: theme.disabledColor.withOpacity(0.1), // Cor adaptável
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
  
  Widget _buildSituacaoField() {
    // ▼▼▼ CORREÇÃO DE TEMA AQUI ▼▼▼
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedSituacaoId,
      decoration: InputDecoration(
        labelText: 'Situação',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: theme.cardColor, // Cor de fundo adaptável
      ),
      dropdownColor: theme.cardColor, // Cor do menu dropdown adaptável
      items: _allSituacoes.map((situacao) {
        return DropdownMenuItem<String>(
          value: situacao['id'],
          child: Text(situacao['descricao'] ?? ''),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSituacaoId = value;
        });
      },
      validator: (value) => value == null ? 'Selecione uma situação' : null,
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