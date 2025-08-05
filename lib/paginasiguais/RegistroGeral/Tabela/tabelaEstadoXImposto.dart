// lib/tabela_estado_imposto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para FilteringTextInputFormatter
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importar os componentes reutilizáveis
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';

// Importes para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

//Validator para UF
String? ufValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Obrigatório.';
  }
  final List<String> validUFs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
  ];
  if (value.length != 2 || !validUFs.contains(value.toUpperCase())) {
    return 'UF inválida.';
  }
  return null;
}

// FORMATTER: PercentageInputFormatter com 2 casas decimais
class PercentageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return TextEditingValue.empty;
    }

    double value = double.parse(newText) / 100.0;
    String formattedText = NumberFormat("#,##0.00", "pt_BR").format(value);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// FORMATTER: PercentageInputFormatter com 4 casas decimais
class PercentageInputFormatter4Casas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (newText.isEmpty) {
      return TextEditingValue.empty;
    }

    double value = double.parse(newText) / 10000.0;
    String formattedText = NumberFormat("#,##0.0000", "pt_BR").format(value);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}


class TabelaEstadoXImposto extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const TabelaEstadoXImposto({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<TabelaEstadoXImposto> createState() => _TabelaEstadoXImpostoState();
}

class _TabelaEstadoXImpostoState extends State<TabelaEstadoXImposto> {
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  // Controllers para os campos
  final TextEditingController _estadoOrigemController = TextEditingController();
  final TextEditingController _estadoDestinoController = TextEditingController();
  final TextEditingController _aliqInterstadualController = TextEditingController();
  final TextEditingController _aliqInternaDIFALController = TextEditingController();
  final TextEditingController _descontoDiferencaICMSRevendaController = TextEditingController();
  final TextEditingController _descontoDiferencaICMSOutrosController = TextEditingController();
  final TextEditingController _aliqICMSSubstituicaoController = TextEditingController();
  final TextEditingController _aliqAbatimentoICMSController = TextEditingController();
  final TextEditingController _aliqAbatimentoICMSRevendaController = TextEditingController();
  final TextEditingController _aliqAbatimentoICMSConsumidorController = TextEditingController();
  final TextEditingController _mvaSTController = TextEditingController();
  final TextEditingController _mvaSTImportaController = TextEditingController();
  final TextEditingController _ctaContabilSubsTribEntrDebController = TextEditingController();
  final TextEditingController _aliqCombatePobrezaController = TextEditingController();

  bool _calculoDIFALDentro = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Listeners para buscar dados quando origem e destino são preenchidos
    _estadoOrigemController.addListener(_onStateFieldsChanged);
    _estadoDestinoController.addListener(_onStateFieldsChanged);
    _aliqInterstadualController.addListener(_updateCounters);
    _aliqInternaDIFALController.addListener(_updateCounters);
    _descontoDiferencaICMSRevendaController.addListener(_updateCounters);
    _descontoDiferencaICMSOutrosController.addListener(_updateCounters);
    _aliqICMSSubstituicaoController.addListener(_updateCounters);
    _aliqAbatimentoICMSController.addListener(_updateCounters);
    _aliqAbatimentoICMSRevendaController.addListener(_updateCounters);
    _aliqAbatimentoICMSConsumidorController.addListener(_updateCounters);
    _mvaSTController.addListener(_updateCounters);
    _mvaSTImportaController.addListener(_updateCounters);
    _ctaContabilSubsTribEntrDebController.addListener(_updateCounters);
    _aliqCombatePobrezaController.addListener(_updateCounters);
  }

  // Helper para obter a referência da coleção
  CollectionReference get _collectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('estado_imposto')
      .collection('items');

  // Constrói o ID do documento a partir dos estados
  String _getDocumentId() {
    final origem = _estadoOrigemController.text.trim().toUpperCase();
    final destino = _estadoDestinoController.text.trim().toUpperCase();
    if (origem.isNotEmpty && destino.isNotEmpty) {
      return '$origem-$destino';
    }
    return '';
  }

  // Limpa todos os campos dependentes (exceto origem e destino)
  void _clearDependentFields() {
    _aliqInterstadualController.clear();
    _aliqInternaDIFALController.clear();
    _descontoDiferencaICMSRevendaController.clear();
    _descontoDiferencaICMSOutrosController.clear();
    _aliqICMSSubstituicaoController.clear();
    _aliqAbatimentoICMSController.clear();
    _aliqAbatimentoICMSRevendaController.clear();
    _aliqAbatimentoICMSConsumidorController.clear();
    _mvaSTController.clear();
    _mvaSTImportaController.clear();
    _ctaContabilSubsTribEntrDebController.clear();
    _aliqCombatePobrezaController.clear();
    setState(() {
      _calculoDIFALDentro = false;
    });
  }

  // Listener que verifica se deve buscar os dados
  void _onStateFieldsChanged() {
    final origem = _estadoOrigemController.text.trim();
    final destino = _estadoDestinoController.text.trim();

    if (origem.length == 2 && destino.length == 2) {
      _fetchImpostoData();
    } else {
      _clearDependentFields();
    }
  }

  // Busca os dados no Firebase
  Future<void> _fetchImpostoData() async {
    final docId = _getDocumentId();
    if (docId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final docSnapshot = await _collectionRef.doc(docId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _aliqInterstadualController.text = data['aliqInterstadual'] ?? '';
          _aliqInternaDIFALController.text = data['aliqInternaDIFAL'] ?? '';
          _descontoDiferencaICMSRevendaController.text = data['descontoIcmsRevenda'] ?? '';
          _descontoDiferencaICMSOutrosController.text = data['descontoIcmsOutros'] ?? '';
          _aliqICMSSubstituicaoController.text = data['aliqIcmsSubstituicao'] ?? '';
          _aliqAbatimentoICMSController.text = data['aliqAbatimentoIcms'] ?? '';
          _aliqAbatimentoICMSRevendaController.text = data['aliqAbatimentoIcmsRevenda'] ?? '';
          _aliqAbatimentoICMSConsumidorController.text = data['aliqAbatimentoIcmsConsumidor'] ?? '';
          _mvaSTController.text = data['mvaST'] ?? '';
          _mvaSTImportaController.text = data['mvaSTImporta'] ?? '';
          _ctaContabilSubsTribEntrDebController.text = data['ctaContabil'] ?? '';
          _aliqCombatePobrezaController.text = data['aliqCombatePobreza'] ?? '';
          _calculoDIFALDentro = data['calculoDifalDentro'] ?? false;
        });
      } else {
        _clearDependentFields();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar dados: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Salva os dados no Firebase
  Future<void> _saveData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final docId = _getDocumentId();
    if (docId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado de Origem e Destino são obrigatórios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dataToSave = {
      'estadoOrigem': _estadoOrigemController.text.trim().toUpperCase(),
      'estadoDestino': _estadoDestinoController.text.trim().toUpperCase(),
      'aliqInterstadual': _aliqInterstadualController.text.trim(),
      'aliqInternaDIFAL': _aliqInternaDIFALController.text.trim(),
      'descontoIcmsRevenda': _descontoDiferencaICMSRevendaController.text.trim(),
      'descontoIcmsOutros': _descontoDiferencaICMSOutrosController.text.trim(),
      'aliqIcmsSubstituicao': _aliqICMSSubstituicaoController.text.trim(),
      'aliqAbatimentoIcms': _aliqAbatimentoICMSController.text.trim(),
      'aliqAbatimentoIcmsRevenda': _aliqAbatimentoICMSRevendaController.text.trim(),
      'aliqAbatimentoIcmsConsumidor': _aliqAbatimentoICMSConsumidorController.text.trim(),
      'mvaST': _mvaSTController.text.trim(),
      'mvaSTImporta': _mvaSTImportaController.text.trim(),
      'ctaContabil': _ctaContabilSubsTribEntrDebController.text.trim(),
      'aliqCombatePobreza': _aliqCombatePobrezaController.text.trim(),
      'calculoDifalDentro': _calculoDIFALDentro,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'criado_por': FirebaseAuth.instance.currentUser?.email ?? 'desconhecido',
    };

    try {
      final docExists = (await _collectionRef.doc(docId).get()).exists;

      await _collectionRef.doc(docId).set(dataToSave, SetOptions(merge: true));
      await LogService.addLog(
        modulo: LogModule.TABELA, // <-- ADICIONADO
      action: docExists ? LogAction.UPDATE : LogAction.CREATE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estado_imposto', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'Usuário salvou/atualizou o estado_imposto com código $docId.', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados salvos com sucesso!')),
      );
    } catch (e) {
      // --- LOG DE ERRO SAVE---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estado_imposto', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'FALHA ao salvar estado_imposto com código $docId. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Exclui os dados do Firebase
  Future<void> _deleteData() async {
    final docId = _getDocumentId();
    if (docId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha Origem e Destino para excluir.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir os impostos para o par de estados $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _collectionRef.doc(docId).delete();
      // --- LOG DE SUCESSO DELETE---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.DELETE,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estado_imposto', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'Usuário excluiuo estado_imposto com código $docId.', // <-- PARTE CUSTOMIZÁVEL 2
    );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro excluído com sucesso!')),
      );
      _clearFormFields();
    } catch(e) {
      // --- LOG DE ERRO DELETE---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estado_imposto', // <-- PARTE CUSTOMIZÁVEL 1
      targetDocId: docId,
      details: 'FALHA ao excluir estado_imposto com código $docId. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    } finally {
       setState(() => _isLoading = false);
    }
  }

  // Gera o relatório em PDF
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gerando relatório...')),
    );

    try {
        final querySnapshot = await _collectionRef.get();

        if (querySnapshot.docs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nenhum dado de imposto encontrado para gerar relatório.')),
            );
            return;
        }

        final List<Map<String, dynamic>> allData = [];
        for (var doc in querySnapshot.docs) {
            allData.add(doc.data() as Map<String, dynamic>);
        }
        
        allData.sort((a, b) {
            int compare = (a['estadoOrigem'] ?? '').compareTo(b['estadoOrigem'] ?? '');
            if (compare == 0) {
                compare = (a['estadoDestino'] ?? '').compareTo(b['estadoDestino'] ?? '');
            }
            return compare;
        });

        final pdf = pw.Document();

        final headers = [
            'Origem',
            'Destino',
            'C/Insc',
            'S/Insc',
            'Revenda',
            'Outros',
            'Alíq. FCP',
            'MVA ST',
            'DIFAL Dentro'
        ];
        
        final data = allData.map((item) => [
            item['estadoOrigem'] ?? '',
            item['estadoDestino'] ?? '',
            item['aliqInterstadual'] ?? '0',
            item['aliqInternaDIFAL'] ?? '0',
            item['descontoIcmsRevenda'] ?? '0',
            item['descontoIcmsOutros'] ?? '0',
            
            item['aliqCombatePobreza'] ?? '0',
            item['mvaST'] ?? '0',
            (item['calculoDifalDentro'] ?? false) ? 'Sim' : 'Não',
        ]).toList();

        pdf.addPage(
            pw.MultiPage(
                pageFormat: PdfPageFormat.a4.landscape,
                header: (context) => pw.Header(
                    level: 0,
                    child: pw.Text('Relatório de Impostos por Estado - ${widget.secondaryCompanyId}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))
                ),
                build: (context) => [
                    pw.Table.fromTextArray(
                        headers: headers,
                        data: data,
                        border: pw.TableBorder.all(),
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        cellAlignments: {
                            0: pw.Alignment.center,
                            1: pw.Alignment.center,
                            6: pw.Alignment.center,
                        }
                    )
                ],
                footer: (context) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                        pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                        pw.Text('Página ${context.pageNumber} de ${context.pagesCount}'),
                    ]
                )
            ),
        );
        // --- LOG DE SUCESSO REPORT---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.GENERATE_REPORT,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estado_imposto', // <-- PARTE CUSTOMIZÁVEL 1
      details: 'Usuário gerou um relatório da tabela de estado_imposto.', // <-- PARTE CUSTOMIZÁVEL 2
    );

        
        await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name: 'relatorio_impostos_${widget.secondaryCompanyId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf'
        );

    } catch (e) {
      // --- LOG DE ERRO REPPORT---
    await LogService.addLog(
      modulo: LogModule.TABELA, // <-- ADICIONADO
      action: LogAction.ERROR,
      mainCompanyId: widget.mainCompanyId,
      secondaryCompanyId: widget.secondaryCompanyId,
      targetCollection: 'estado_imposto', // <-- PARTE CUSTOMIZÁVEL 1
      details: 'FALHA ao gerar relatório de estado_imposto. Erro: ${e.toString()}', // <-- PARTE CUSTOMIZÁVEL 2
    );

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao gerar relatório: $e')),
        );
    } finally {
        setState(() => _isLoading = false);
    }
  }
  
  void _clearFormFields(){
     _estadoOrigemController.clear();
     _estadoDestinoController.clear();
     _clearDependentFields();
  }

  void _updateCounters() {
    setState(() {});
  }

  @override
  void dispose() {
    _estadoOrigemController.removeListener(_onStateFieldsChanged);
    _estadoDestinoController.removeListener(_onStateFieldsChanged);

    _estadoOrigemController.dispose();
    _estadoDestinoController.dispose();
    _aliqInterstadualController.dispose();
    _aliqInternaDIFALController.dispose();
    _descontoDiferencaICMSRevendaController.dispose();
    _descontoDiferencaICMSOutrosController.dispose();
    _aliqICMSSubstituicaoController.dispose();
    _aliqAbatimentoICMSController.dispose();
    _aliqAbatimentoICMSRevendaController.dispose();
    _aliqAbatimentoICMSConsumidorController.dispose();
    _mvaSTController.dispose();
    _mvaSTImportaController.dispose();
    _ctaContabilSubsTribEntrDebController.dispose();
    _aliqCombatePobrezaController.dispose();
    super.dispose();
  }

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
                  builder: (BuildContext context, BoxConstraints constraints) {
                    if (constraints.maxWidth > _breakpoint) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: AppDrawer(
                                    parentMaxWidth: constraints.maxWidth,
                                    breakpoint: 700.0,
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
                                        padding: EdgeInsets.only(top: 20.0, bottom: 0.0),
                                        child: Center(
                                          child: Text(
                                            'Estado X Imposto',
                                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                      Expanded(child: _buildCentralInputArea()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
                              child: Center(
                                child: Text(
                                  'Estado X Imposto',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ),
                            AppDrawer(
                              parentMaxWidth: constraints.maxWidth,
                              breakpoint: 700.0,
                              mainCompanyId: widget.mainCompanyId,
                              secondaryCompanyId: widget.secondaryCompanyId,
                              //userRole: widget.userRole,
                          ),
                            _buildCentralInputArea(),
                          ],
                        ),
                      );
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

  Widget _buildCentralInputArea() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 15, bottom: 0),
                  child: Column(
                    children: [
                      // Linha 1: Estado Origem, Estado Destino
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 90),
                          Expanded(
                            child: CustomInputField(
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                              controller: _estadoOrigemController,
                              label: 'Estado Origem',
                              maxLength: 2,
                              suffixText: '${_estadoOrigemController.text.length}/2',
                              validator: ufValidator,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: CustomInputField(
                              controller: _estadoDestinoController,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                              label: 'Estado Destino',
                              maxLength: 2,
                              suffixText: '${_estadoDestinoController.text.length}/2',
                              validator: ufValidator,
                            ),
                          ),
                          const SizedBox(width: 90),
                        ],
                      ),
                      const Divider(height: 6, thickness: 2, color: Colors.blue),
                      const SizedBox(height: 5),
                      // Linha que conterá as duas colunas ICMS e ST
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Coluna ICMS
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    const Text('ICMS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 3),
                                    _buildInputField(_aliqCombatePobrezaController, 'Alíquota Combate a Fundo Pobreza', 5, formatter: PercentageInputFormatter()),
                                    _buildInputField(_aliqInterstadualController, 'Alíquota Interestadual', 5, formatter: PercentageInputFormatter()),
                                    _buildInputField(_aliqInternaDIFALController, 'Alíquota Interna - DIFAL', 5, formatter: PercentageInputFormatter()),
                                    _buildInputField(_descontoDiferencaICMSRevendaController, 'Desconto Diferença ICMS Revenda', 7, formatter: PercentageInputFormatter4Casas()),
                                    _buildInputField(_descontoDiferencaICMSOutrosController, 'Desconto Diferença ICMS Outros', 7, formatter: PercentageInputFormatter4Casas()),
                                    _buildCheckboxRow(),
                                  ],
                                ),
                              ),
                              const VerticalDivider(width: 60, thickness: 2, color: Colors.blue),
                              // Coluna ST
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    const Text('ST - Substituição Tributária ICMS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center),
                                    const SizedBox(height: 3),
                                    _buildInputField(_aliqICMSSubstituicaoController, 'Aliq. ICMS Substituição', 5, formatter: PercentageInputFormatter()),
                                    _buildInputField(_aliqAbatimentoICMSController, 'Aliq. Abatimento ICMS', 5, formatter: PercentageInputFormatter()),
                                    _buildInputField(_aliqAbatimentoICMSRevendaController, 'Aliq. Abatimento ICMS Revenda', 5, formatter: PercentageInputFormatter()),
                                    _buildInputField(_aliqAbatimentoICMSConsumidorController, 'Aliq. Abatimento ICMS Consumidor', 5, formatter: PercentageInputFormatter()),
                                    _buildStRow(),
                                    _buildInputField(_ctaContabilSubsTribEntrDebController, 'Cta Contabil Subs.Trib.Entr.Deb', 7,validator: (value){
                                      if (value == null || value.isEmpty) {
                                    return 'O campo deve ser preenchido.';
                                  }
                                  if (value.length != 7) {
                                    return 'O campo deve ter 7 dígitos.'; // Mensagem de erro mais clara
                                  }
                                  return null;
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botões de Ação
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton('EXCLUIR', Colors.red, _deleteData),
                    const SizedBox(width: 30),
                    _buildActionButton('SALVAR', Colors.green, _saveData),
                     const SizedBox(width: 30),
                    _buildActionButton('RELATÓRIO', Colors.yellow, _generateReport),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, int maxLength, {bool isRequired = false, String? Function(String?)? validator,TextInputFormatter? formatter}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: CustomInputField(
        controller: controller,
        validator: validator ?? (isRequired ? (v) => v!.isEmpty ? 'Obrigatório' : null : null),
        label: label,
        maxLength: maxLength,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: formatter != null ? [formatter] : [],
        suffixText: '${controller.text.length}/$maxLength',
      ),
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
                Text('Cálculo :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('DIFAL :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Dentro :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [ Checkbox(value: _calculoDIFALDentro, onChanged: (v) => setState(() => _calculoDIFALDentro = true)), const Text('Sim') ]),
                Row(children: [ Checkbox(value: !_calculoDIFALDentro, onChanged: (v) => setState(() => _calculoDIFALDentro = false)), const Text('Não') ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStRow() {
     return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInputField(_mvaSTController, 'MVA-St', 6, formatter: PercentageInputFormatter())),
        const SizedBox(width: 20),
        Expanded(child: _buildInputField(_mvaSTImportaController, 'MVA-St Importa', 6, formatter: PercentageInputFormatter())),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
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
