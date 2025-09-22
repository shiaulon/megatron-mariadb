// lib/registroGeral/consulta_rg_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/botao_ajuda_flutuante.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart'; // Import do AppDrawer
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/manut_rg_service.dart';
import 'package:flutter_application_1/registroGeral/manut_rg.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Importes para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ConsultaRgPage extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const ConsultaRgPage({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<ConsultaRgPage> createState() => _ConsultaRgPageState();
}

class _ConsultaRgPageState extends State<ConsultaRgPage> {
  final ManutRgService _manutRgService = ManutRgService();
  bool _isLoading = false;
  late String _currentDate;

  // --- NOVO: Ponto de quebra para layout responsivo ---
  static const double _breakpoint = 800.0;

  // --- Estado da Tabela ---
  List<Map<String, dynamic>> _allRegistros = [];
  List<Map<String, dynamic>> _filteredRegistros = [];
  
  final TextEditingController _searchController = TextEditingController();

  // --- Mapa de colunas completo ---
  final Map<String, String> _allPossibleColumns = {
    // Chave da API : Nome de Exibição
    // Aba Dados Gerais
    'tipo_pessoa': 'Tipo Pessoa',
    'cep': 'CEP',
    'endereco': 'Endereço',
    'numero': 'Número',
    'complemento': 'Complemento',
    'bairro': 'Bairro',
    'cidade_id': 'Cód. Cidade',
    'uf': 'UF',
    'caixa_postal': 'Cx. Postal',
    'como_nos_conheceu': 'Como nos Conheceu',
    'portador': 'Portador',
    'tab_desconto': 'Tab. Desconto',
    'insc_suframa': 'Insc. Suframa',
    'insc_produtor': 'Insc. Produtor',
    'insc_municipal': 'Insc. Municipal',
    'vendedor_id': 'Cód. Vendedor',
    'atendente_id': 'Cód. Atendente',
    'area_id': 'Cód. Área',
    'situacao_id': 'Cód. Situação',
    // Aba Física
    'estado_civil': 'Estado Civil',
    'rg': 'RG',
    'data_expedicao_rg': 'Data Expedição',
    'data_nascimento': 'Data Nascimento',
    'profissao': 'Profissão',
    // Aba Jurídica
    'cnpj_juridico': 'CNPJ (Jurídico)',
    'insc_estadual': 'Insc. Estadual',
    'contrib_icms': 'Contrib. ICMS',
    'revenda': 'Revenda',
    // Aba Complemento
    'confidencial': 'Confidencial',
    'observacao': 'Observação',
    'observacao_nf': 'Observação NF',
    'email_principal': 'E-mail Principal',
    'email_cobranca': 'E-mail Cobrança',
    'email_nfe': 'E-mail NF-e',
    'site': 'Site',
    // Aba Fantasia
    'fantasia1': 'Fantasia 1',
    'fantasia2': 'Fantasia 2',
    'fantasia3': 'Fantasia 3',
    'fantasia4': 'Fantasia 4',
    'fantasia5': 'Fantasia 5',
    // Endereços Adicionais
    'cobranca_endereco': 'End. Cobrança',
    'cobranca_cidade_id': 'Cidade Cobrança',
    'correspondencia_endereco': 'End. Correspondência',
    'entrega_endereco': 'End. Entrega',
    // --- Dados do Primeiro Registro das Sub-Tabelas ---
    'primeiro_tel_ddd': '1º DDD',
    'primeiro_tel_numero': '1º Telefone',
    'primeiro_socio_nome': '1º Sócio (Nome)',
    'primeiro_socio_participacao': '1º Sócio (Part. %)',
    'primeiro_banco_nome': '1º Ref. Banco',
    'primeiro_banco_telefone': '1º Ref. Banco (Tel)',
    'primeiro_comercial_nome': '1º Ref. Comercial',
    'primeiro_comercial_telefone': '1º Ref. Comercial (Tel)',
    'primeiro_contato_nome': '1º Contato (Nome)',
    'primeiro_contato_email': '1º Contato (Email)',
  };
  List<String> _visibleColumnKeys = [];

  // Ordenação
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _visibleColumnKeys = _allPossibleColumns.keys.take(5).toList();
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterData);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _manutRgService.getAllRegistros(token);
      if (mounted) {
        setState(() {
          _allRegistros = data;
          _filteredRegistros = List.from(_allRegistros);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar registros: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRegistros = _allRegistros.where((registro) {
        bool matchesFixed = (registro['codigo_interno']?.toString().toLowerCase().contains(query) ?? false) ||
                            (registro['id']?.toString().toLowerCase().contains(query) ?? false) ||
                            (registro['razao_social']?.toString().toLowerCase().contains(query) ?? false);
        bool matchesDynamic = _visibleColumnKeys.any((key) => registro[key]?.toString().toLowerCase().contains(query) ?? false);
        return matchesFixed || matchesDynamic;
      }).toList();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _filteredRegistros.sort((a, b) {
        dynamic aValue;
        dynamic bValue;
        List<String> fixedKeys = ['edit_action', 'codigo_interno', 'id', 'razao_social'];
        if (columnIndex < fixedKeys.length) {
          if (columnIndex == 0) return 0;
          final key = fixedKeys[columnIndex];
          aValue = a[key];
          bValue = b[key];
        } else {
          final key = _visibleColumnKeys[columnIndex - fixedKeys.length];
          aValue = a[key];
          bValue = b[key];
        }
        final comparison = Comparable.compare(aValue ?? '', bValue ?? '');
        return ascending ? comparison : -comparison;
      });
    });
  }

  void _navigateToManutRg({String? rgId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaComAbasLaterais(
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          userRole: widget.userRole,
          initialRgId: rgId,
        ),
      ),
    ).then((_) => _loadData());
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

  void _showManageColumnsDialog() {
    List<String> tempVisibleKeys = List.from(_visibleColumnKeys);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Gerenciar Colunas'),
              content: SizedBox(
                width: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: _allPossibleColumns.entries.map((entry) {
                    final key = entry.key;
                    final name = entry.value;
                    final isSelected = tempVisibleKeys.contains(key);
                    return CheckboxListTile(
                      title: Text(name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        if (value == true && tempVisibleKeys.length >= 5) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Você pode selecionar no máximo 5 colunas dinâmicas.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        setDialogState(() {
                          if (value == true) {
                            tempVisibleKeys.add(key);
                          } else {
                            tempVisibleKeys.remove(key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _visibleColumnKeys = tempVisibleKeys; });
                    Navigator.pop(context);
                  }, 
                  child: const Text('Aplicar')
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _generatePdf() async {
    final doc = pw.Document();
    final List<String> headers = ['Código', 'CPF/CNPJ', 'Razão Social', ..._visibleColumnKeys.map((key) => _allPossibleColumns[key] ?? key)];
    final List<List<String>> data = _filteredRegistros.map((registro) {
      return [
        registro['codigo_interno']?.toString() ?? '',
        registro['id']?.toString() ?? '',
        registro['razao_social']?.toString() ?? '',
        ..._visibleColumnKeys.map((key) {
           final value = registro[key];
           if (key.contains('data') && value is String && DateTime.tryParse(value) != null) {
              try {
                return DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
              } catch (e) {
                return value;
              }
           }
           return value?.toString() ?? '';
        }),
      ];
    }).toList();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(30),
      header: (pw.Context context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Text('Relatório de Registros Gerais', style: pw.Theme.of(context).header3)),
      build: (pw.Context context) => [
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignments: { for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft },
          border: pw.TableBorder.all(),
        ),
      ],
      footer: (pw.Context context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Relatório gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}')
        ])
    ));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  // --- NOVO: Widget para o conteúdo principal da página ---
  Widget _buildContentArea() {
    final theme = Theme.of(context);
    List<DataColumn> columns = [
      const DataColumn(label: Text('Editar')),
      DataColumn(label: const Text('Código'), onSort: _onSort),
      DataColumn(label: const Text('CPF/CNPJ'), onSort: _onSort),
      DataColumn(label: const Text('Razão Social'), onSort: _onSort),
      ..._visibleColumnKeys.map((key) => DataColumn(
        label: Text(_allPossibleColumns[key]!),
        onSort: _onSort,
      )),
    ];
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Adicionar Novo'), onPressed: () => _navigateToManutRg()),
              const SizedBox(width: 16),
              ElevatedButton.icon(icon: const Icon(Icons.view_column), label: const Text('Gerenciar Colunas'), onPressed: _showManageColumnsDialog),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Gerar PDF'),
                onPressed: _isLoading ? null : _generatePdf,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar...',
                    suffixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
          ? const Expanded(child: Center(child: CircularProgressIndicator()))
          : Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all<Color>(theme.primaryColor.withOpacity(0.2)),
                      border: TableBorder.all(color: theme.dividerColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      columns: columns,
                      rows: _filteredRegistros.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final Map<String, dynamic> registro = entry.value;
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>((states) {
                            return index.isEven ? Colors.grey.withOpacity(0.05) : null;
                          }),
                          cells: [
                            DataCell(IconButton(
                              icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                              onPressed: () => _navigateToManutRg(rgId: registro['id']),
                            )),
                            DataCell(Text(registro['codigo_interno']?.toString() ?? '')),
                            DataCell(Text(registro['id']?.toString() ?? '')),
                            DataCell(Text(registro['razao_social']?.toString() ?? '')),
                            ..._visibleColumnKeys.map((key) {
                              final value = registro[key];
                              String displayText = value?.toString() ?? '';
                              if (key.contains('data') && value is String && DateTime.tryParse(value) != null) {
                                try {
                                  displayText = DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
                                } catch (e) {
                                  // se falhar, exibe o valor original
                                }
                              }
                              return DataCell(Text(displayText));
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

        
  // --- NOVO: Layout para Desktop ---
  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CORREÇÃO: Adicionado Expanded com flex para definir um tamanho proporcional para o menu.
        Expanded(
          flex: 1, // Ocupa 1/5 do espaço
          child: AppDrawer(parentMaxWidth: constraints.maxWidth,
            breakpoint: _breakpoint,
            
          
          mainCompanyId: widget.mainCompanyId,
          secondaryCompanyId: widget.secondaryCompanyId,
          
        ),
        ),
        // CORREÇÃO: Adicionado flex para garantir a proporção correta com o menu.
        Expanded(
          flex: 4, // Ocupa 4/5 do espaço
          child: _buildContentArea(),
        ),
      ],
    );
  }

  // --- NOVO: Layout para Mobile ---
  Widget _buildMobileLayout() {
    return _buildContentArea();
  }

  // --- ATUALIZADO: Build principal agora usa LayoutBuilder ---
  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: BotaoAjudaFlutuante(helpContent: _buildHelpContent(),
        child: Column(
          children: [
            TopAppBar(
              onBackPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TelaSubPrincipal(mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, userRole: widget.userRole))),
              currentDate: _currentDate,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > _breakpoint) {
                    return _buildDesktopLayout( constraints);
                  } else {
                    return _buildMobileLayout();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}