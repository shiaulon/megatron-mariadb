// lib/credito/liberacao_credito_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/botao_ajuda_flutuante.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/credito_faixas_service.dart';
import 'package:flutter_application_1/services/manut_rg_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


// --- Formatters ---
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return const TextEditingValue();
    if (cleanText.length > 15) cleanText = cleanText.substring(0, 15);
    double value = double.parse(cleanText) / 100;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);
    String newText = formatter.format(value).trim();
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.length > 8) cleanText = cleanText.substring(0, 8);
    var buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      if ((i == 1 || i == 3) && i != cleanText.length - 1) {
        buffer.write('/');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
// --- Fim dos Formatters ---

class LiberacaoCreditoPage extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;

  const LiberacaoCreditoPage({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
  });

  @override
  State<LiberacaoCreditoPage> createState() => _LiberacaoCreditoPageState();
}

class _LiberacaoCreditoPageState extends State<LiberacaoCreditoPage> {
  final _manutRgService = ManutRgService();
  final _creditoFaixasService = CreditoFaixasService();
  bool _isLoading = false;

  Map<String, dynamic>? _rgData;
  Map<String, dynamic>? _faixasCreditoData;
  List<Map<String, dynamic>> _rgSuggestions = [];
  
  List<Map<String, dynamic>> _documentosExigidos = [];
  Map<String, bool> _documentosEntregues = {};

  final _codigoController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _valorFaturamentoController = TextEditingController();
  final _valorCreditoController = TextEditingController();
  final _validadeCreditoController = TextEditingController();
  String _faturamentoTipo = 'mensal';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _valorCreditoController.addListener(_onValorCreditoChanged);
  }

  @override
  void dispose() {
    _valorCreditoController.removeListener(_onValorCreditoChanged);
    _codigoController.dispose();
    _cpfCnpjController.dispose();
    _razaoSocialController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _valorFaturamentoController.dispose();
    _valorCreditoController.dispose();
    _validadeCreditoController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      _rgSuggestions = await _manutRgService.getRgSuggestions(token);
    } catch (e) {
      if(mounted) _showErrorSnackbar('Erro ao carregar dados: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataById(String rgId) async {
    setState(() => _isLoading = true);
    _clearFields(clearSearch: false);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _manutRgService.getRgCompleto(rgId, token);

      if (mounted && data.isNotEmpty) {
        if (data['tipo_pessoa'] != null) {
          _faixasCreditoData = await _creditoFaixasService.getData(data['tipo_pessoa'], token);
          print('>>> DADOS DAS FAIXAS CARREGADOS: $_faixasCreditoData');
          _populateFields(data);
          _onValorCreditoChanged();
        } else {
          _populateFields(data);
          _showErrorSnackbar("Cliente sem tipo de pessoa (Física/Jurídica) definido. Não é possível carregar faixas de crédito.");
        }
      } else {
        _clearFields();
        if(mounted) _showErrorSnackbar('Registro não encontrado.');
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
      _cidadeController.text = data['cidade_id'] ?? '';

      _faturamentoTipo = data['faturamento_tipo'] ?? 'mensal';
      _valorFaturamentoController.text = data['faturamento_valor'] != null ? MoneyInputFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: (double.tryParse(data['faturamento_valor'])! * 100).toInt().toString())).text : '';
      _valorCreditoController.text = data['valor_credito'] != null ? MoneyInputFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: (double.tryParse(data['valor_credito'])! * 100).toInt().toString())).text : '';
      
      if (data['validade_credito'] != null) {
        final date = DateTime.tryParse(data['validade_credito']);
        if (date != null) {
          _validadeCreditoController.text = DateFormat('dd/MM/yyyy').format(date);
        }
      } else {
        _validadeCreditoController.clear();
      }
      
      _documentosEntregues.clear();
      if(data['documentos_entregues'] != null && data['documentos_entregues'].isNotEmpty) {
        try {
          // O backend agora retorna JSON, então usamos jsonDecode
          List<dynamic> docs = jsonDecode(data['documentos_entregues']);
          for(var docId in docs) {
            _documentosEntregues[docId.toString()] = true;
          }
        } catch(e) {
          print("Erro ao decodificar documentos entregues: $e");
        }
      }
    });
  }
  
  void _clearFields({bool clearSearch = true}) {
    setState(() {
      _rgData = null;
      _faixasCreditoData = null;
      _documentosExigidos.clear();
      _documentosEntregues.clear();

      if (clearSearch) {
        _codigoController.clear();
        _cpfCnpjController.clear();
        _razaoSocialController.clear();
      }

      _enderecoController.clear();
      _numeroController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      
      _faturamentoTipo = 'mensal';
      _valorFaturamentoController.clear();
      _valorCreditoController.clear();
      _validadeCreditoController.clear();
    });
  }
  
  void _onValorCreditoChanged() {
    if (_faixasCreditoData == null || !mounted) {
      print('>>> _onValorCreditoChanged abortado: _faixasCreditoData é nulo.');
      return;
    }

    final valorCreditoStr = _valorCreditoController.text.replaceAll('.', '').replaceAll(',', '.');
    final valorCredito = double.tryParse(valorCreditoStr) ?? 0.0;
    print('>>> Valor do crédito digitado: $valorCredito');

    String? faixaEncontrada;
    for (int i = 1; i <= 5; i++) {
      final inicio = double.tryParse(_faixasCreditoData!['faixa${i}_inicio'] ?? '0.0') ?? 0.0;
      final fimStr = _faixasCreditoData!['faixa${i}_fim'];
      final fim = (fimStr == null || fimStr.isEmpty) ? double.infinity : (double.tryParse(fimStr) ?? double.infinity);
      
      if (valorCredito >= inicio && valorCredito <= fim) {
        faixaEncontrada = 'faixa$i';
        break;
      }
    }

    print('>>> Faixa encontrada: $faixaEncontrada');

    if (faixaEncontrada != null) {
      final List<dynamic> docIds = (_faixasCreditoData!['documentos'] as Map<String, dynamic>)[faixaEncontrada] ?? [];
      print('>>> IDs de documento para a faixa: $docIds');
      
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) return;
      
      _manutRgService.getDadosAuxiliares('credito-documentos', token).then((allDocs) {
        if(mounted) {
          setState(() {
            _documentosExigidos = allDocs.where((doc) => docIds.contains(doc['id'])).toList();
            print('>>> Documentos exigidos (final): $_documentosExigidos');
          });
        }
      });
    } else {
      if(mounted) {
        setState(() {
          _documentosExigidos.clear();
        });
      }
    }
  }

  Future<void> _saveData() async {
     if (_rgData == null) {
      _showErrorSnackbar('Nenhum registro carregado.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      
      final dataToSave = {
        'faturamento_tipo': _faturamentoTipo,
        'faturamento_valor': _valorFaturamentoController.text.replaceAll('.', '').replaceAll(',', '.'),
        'valor_credito': _valorCreditoController.text.replaceAll('.', '').replaceAll(',', '.'),
        'validade_credito': _validadeCreditoController.text.isNotEmpty 
          ? DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(_validadeCreditoController.text)) 
          : null,
        'documentos_entregues': _documentosEntregues.entries.where((e) => e.value).map((e) => e.key).toList(),
        'secondaryCompanyId': widget.secondaryCompanyId,
      };

      await _manutRgService.updateRgCredito(_rgData!['id'], dataToSave, token);
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados de crédito salvos!'), backgroundColor: Colors.green));
      }

    } catch (e) {
      if(mounted) _showErrorSnackbar('Erro ao salvar: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
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
              'Liberação de Crédito',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
          ),
          _buildTopSearchFields(),
          const SizedBox(height: 20),
          _buildInfoFields(),
          const Divider(height: 40, thickness: 1),
          _buildEditableFields(),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTopSearchFields() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildAutocompleteField('Código', _codigoController, 'codigo_interno')),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: _buildAutocompleteField('Razão Social', _razaoSocialController, 'razao_social')),
        const SizedBox(width: 16),
        Expanded(flex: 3, child: _buildAutocompleteField('CPF/CNPJ', _cpfCnpjController, 'id')),
      ],
    );
  }
  
  Widget _buildAutocompleteField(String label, TextEditingController controller, String fieldKey) {
    final theme = Theme.of(context);
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option[fieldKey] ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return _rgSuggestions.where((option) =>
            (option[fieldKey] ?? '').toLowerCase().contains(textEditingValue.text.toLowerCase()));
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
      border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.disabledColor)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildFaturamentoRadios(),
              const SizedBox(height: 16),
              CustomInputField(controller: _valorFaturamentoController, label: 'Vl. Faturamento', inputFormatters: [MoneyInputFormatter()], keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomInputField(controller: _valorCreditoController, label: 'Valor do Crédito', inputFormatters: [MoneyInputFormatter()], keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomInputField(controller: _validadeCreditoController, label: 'Validade do Crédito', hintText: 'dd/mm/aaaa', maxLength: 10, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8), DateInputFormatter()]),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildDocumentosChecklist(),
        ),
      ],
    );
  }

  Widget _buildFaturamentoRadios() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text("Faturamento:"),
          Row(
            children: [
              Radio<String>(value: 'mensal', groupValue: _faturamentoTipo, onChanged: (v) => setState(() => _faturamentoTipo = v!)),
              const Text('Mensal'),
            ],
          ),
          Row(
            children: [
              Radio<String>(value: 'anual', groupValue: _faturamentoTipo, onChanged: (v) => setState(() => _faturamentoTipo = v!)),
              const Text('Anual'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentosChecklist() {
    if (_rgData == null) {
       return const SizedBox.shrink();
    }
    if (_valorCreditoController.text.isEmpty || _documentosExigidos.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text("Preencha o Valor do Crédito para ver os documentos necessários.")),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Documentos Necessários", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._documentosExigidos.map((doc) {
            final docId = doc['id'].toString();
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(doc['documentos_basicos']),
              value: _documentosEntregues[docId] ?? false,
              onChanged: (bool? value) {
                setState(() {
                  _documentosEntregues[docId] = value ?? false;
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('SALVAR'),
          onPressed: _isLoading || _rgData == null ? null : _saveData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('RELATÓRIO'),
          onPressed: () { /* Lógica para relatório */ },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}