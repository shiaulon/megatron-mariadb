import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/cidades_service.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

String? _ufValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Obrigatório.';
    }
    final List<String> validUFs = [
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
      'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
      'SP', 'SE', 'TO', 'EX'
    ];
    if (!validUFs.contains(value.toUpperCase())) {
      return 'UF inválida.';
    }
    return null;
  }

// Remova os imports do Firebase que não são mais necessários

// ... (Sua função _ufValidator continua a mesma)

class TabelaCidade extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaCidade({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaCidade> createState() => _TabelaCidadeState();
}

class _TabelaCidadeState extends State<TabelaCidade> {
  final CidadeService _cidadesService = CidadeService();
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _abreviadoController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _issController = TextEditingController();
  final TextEditingController _tabelaIBGEController = TextEditingController();
  
  bool _paisReadOnly = true;
  bool _cartorio = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _allCidades = [];

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchAllCidades();
    _estadoController.addListener(_onEstadoChanged);
    _codigoController.addListener(_onCodigoChanged);
    _cidadeController.addListener(_handleClearCheck); // Listener para limpar campos
  }
  
  void _onCodigoChanged() {
    final text = _codigoController.text;
    final exactMatches = _allCidades.where((c) => c['id'].toString() == text).toList();

    if (exactMatches.length == 1) {
      // Se encontrou o código exato, preenche tudo.
      _populateAllFields(exactMatches.first);
    } else {
      // Se NÃO encontrou (seja porque apagou um dígito ou o código não existe),
      // limpa todos os campos, exceto o próprio campo de código.
      _clearDependentFields(clearCode: false);
    }
  }

  Future<void> _fetchAllCidades() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");
      final cidades = await _cidadesService.getAllCidades(token, widget.secondaryCompanyId);
      setState(() {
        _allCidades = cidades;
      });
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar cidades: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _populateAllFields(Map<String, dynamic> data) {
    setState(() {
      _codigoController.text = data['id']?.toString() ?? '';
      _cidadeController.text = data['cidade']?.toString() ?? '';
      _abreviadoController.text = data['abreviado']?.toString() ?? '';
      _estadoController.text = data['estado']?.toString() ?? '';
      _paisController.text = data['pais']?.toString() ?? '';
      _issController.text = data['iss']?.toString() ?? '';
      _tabelaIBGEController.text = data['tabelaIBGE']?.toString() ?? '';
      _cartorio = data['cartorio'] ?? false;
      _onEstadoChanged();
    });
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

  void _clearDependentFields({bool clearCode = true}) {
    if (clearCode) _codigoController.clear();
    _abreviadoController.clear();
    _estadoController.clear();
    _paisController.clear();
    _issController.clear();
    _tabelaIBGEController.clear();
    setState(() {
      _cartorio = false;
      _paisReadOnly = true;
    });
  }

  void _onEstadoChanged() {
    setState(() {
      final String estado = _estadoController.text.toUpperCase();
      final List<String> ufsBrasileiras = ['AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'];
      if (estado == 'EX') {
        _paisController.text = '';
        _paisReadOnly = false;
      } else if (ufsBrasileiras.contains(estado)) {
        _paisController.text = 'Brasil';
        _paisReadOnly = true;
      } else {
        _paisController.text = '';
        _paisReadOnly = true;
      }
    });
  }

  // FUNÇÕES QUE FALTAVAM
  void _clearAllFields() {
    _codigoController.clear();
    _cidadeController.clear();
    _clearDependentFields(clearCode: false);
  }

  void _handleClearCheck() {
    if (_codigoController.text.isEmpty && _cidadeController.text.isEmpty) {
      _clearDependentFields();
    }
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
      'cidade': _cidadeController.text.trim(),
      'abreviado': _abreviadoController.text.trim(),
      'estado': _estadoController.text.trim().toUpperCase(),
      'pais': _paisController.text.trim(),
      'iss': _issController.text.trim(),
      'tabelaIBGE': _tabelaIBGEController.text.trim(),
      'cartorio': _cartorio,
    };

    try {
      await _cidadesService.saveData(dataToSave, token);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cidade salva com sucesso!'), backgroundColor: Colors.green));
      await _fetchAllCidades(); // Recarrega a lista após salvar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar cidade: $e'), backgroundColor: Colors.red));
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
        content: Text('Deseja excluir a cidade com código $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação.')));
      setState(() => _isLoading = false);
      return;
    }
    try {
      await _cidadesService.deleteData(docId, token);
      _clearAllFields();
      await _fetchAllCidades();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cidade excluída com sucesso!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateReport() async {
  setState(() => _isLoading = true);
  try {
    if (_allCidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma cidade para gerar relatório.')));
      return; // O return estava faltando aqui, boa prática adicioná-lo
    }
    // ---> ADICIONAR LOG AQUI <---
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final logService = LogService(token);
    await logService.addReportLog(
      reportName: 'Relatório de Cidades',
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
    );
    // ----------------------------

    final pdf = pw.Document();
    final headers = ['Código', 'Cidade', 'Abreviado', 'Estado', 'País', 'ISS', 'IBGE', 'Cartório'];

    final data = _allCidades.map((cidade) => [
      cidade['id']?.toString() ?? '',
      cidade['cidade']?.toString() ?? '',
      cidade['abreviado']?.toString() ?? '',
      cidade['estado']?.toString() ?? '',
      cidade['pais']?.toString() ?? '',
      cidade['iss']?.toString() ?? '',
      cidade['tabelaIBGE']?.toString() ?? '',
      (cidade['cartorio'] == true) ? 'Sim' : 'Não',
    ]).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Relatório de Cidades - ${widget.secondaryCompanyId}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
          )
        ],
      ),
    );

    // REMOVIDO: A chamada ao LogService foi removida.
    
    // Agora o app apenas exibe o PDF.
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());

  } catch (e) {
    // REMOVIDO: A chamada ao LogService foi removida.
    print('Erro ao gerar PDF: $e'); // Adicionamos um print para o console de debug
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  void dispose() {
    _codigoController.removeListener(_onCodigoChanged);
    _cidadeController.removeListener(_handleClearCheck);
    _estadoController.removeListener(_onEstadoChanged);
    _codigoController.dispose();
    _cidadeController.dispose();
    _abreviadoController.dispose();
    _estadoController.dispose();
    _paisController.dispose();
    _issController.dispose();
    _tabelaIBGEController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A estrutura do seu build (TelaBase, LayoutBuilder, etc.) permanece a mesma.
    // A única mudança é que o _buildAutocompleteField agora vai funcionar corretamente
    // porque _allCidades será preenchido pela API.
    // O código abaixo é uma reconstrução fiel do seu, garantindo que tudo se conecte.
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
                child: Text('Cidade', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
            child: Text('Cidade', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                      //_buildCamposDeBusca(),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildAutocompleteField(_codigoController, "Código", "id", isRequired: true,isNumeric: true, maxLength: 5),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildAutocompleteField(_cidadeController, "Cidade", "cidade", isRequired: true, maxLength: 35),
                                ),
                               // const SizedBox(height: 10),
                                
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_abreviadoController, "Abreviado", 15),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_estadoController, "Estado", 2, validator: _ufValidator, textCapitalization: TextCapitalization.characters),
                                ),
                                
                              ],
                            ),
                          ),
                          const SizedBox(width: 60),
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_paisController, "País", 15, readOnly: _paisReadOnly,isRequired: true),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_issController, "ISS", 4, isNumeric: true),
                                ),
                                //const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildInputField(_tabelaIBGEController, "Tabela IBGE", 7, isNumeric: true, isRequired: true, validator: (value){
                                    if (value == null || value.isEmpty) {
                                    return 'O código IBGE deve ser preenchido.';
                                  }
                                  if (value.length != 7) {
                                    return 'O código IBGE deve ter 7 dígitos.'; // Mensagem de erro mais clara
                                  }
                                  return null;
                                  }),
                                ),
                                //const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 60,),
                                    Expanded(child: _buildCheckboxRow()),
                                    SizedBox(width: 60,),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
              SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }
  // podem ser colados aqui exatamente como estavam no seu arquivo original, pois a lógica deles não muda) ...

  // Substitua o seu _buildAutocompleteField por este, que é igual mas garante a conexão.
  Widget _buildAutocompleteField(TextEditingController controller, String label, String fieldKey, {bool isRequired = false,bool isNumeric = false, int? maxLength}) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option[fieldKey]?.toString() ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable.empty();
        }
        return _allCidades.where((option) {
          final fieldValue = option[fieldKey]?.toString().toLowerCase() ?? '';
          return fieldValue.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (selection) {
        _populateAllFields(selection);
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
          validator: isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null,
          inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onChanged: (value) {
            controller.text = value; // Atualiza o controller principal
          },
        );
      },
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, int maxLength, {String? Function(String?)? validator, bool isNumeric = false, bool isRequired = false, bool readOnly = false, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return CustomInputField(
      controller: controller,
      label: label,
      maxLength: maxLength,
      validator: validator ?? (isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null),
      
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            suffixText: '${controller.text.length}/$maxLength',
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
      readOnly: readOnly,
      fillColor: readOnly ? Colors.grey[300] : Colors.white,
      textCapitalization: textCapitalization,
    );
  }

 Widget _buildCheckboxRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 153, 205, 248),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.blue, width: 2.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Column(
              children: [
                Text('Cartório :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [ Checkbox(value: _cartorio, onChanged: (v) => setState(() => _cartorio = true)), const Text('Sim') ]),
                Row(children: [ Checkbox(value: !_cartorio!, onChanged: (v) => setState(() => _cartorio = false)), const Text('Não') ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

  
  
  

  

  




  

  

  

