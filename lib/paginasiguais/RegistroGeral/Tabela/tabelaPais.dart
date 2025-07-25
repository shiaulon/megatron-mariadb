import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importes para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Prefixo 'pw' para widgets do PDF
import 'package:printing/printing.dart'; // Para visualização/download


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
  static const double _breakpoint = 700.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _currentDate;

  // Controllers para os campos de texto
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _resumoController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _codigoPaisController = TextEditingController();

  // Lista para armazenar os países para o Autocomplete
  List<Map<String, dynamic>> _allPaises = [];

  bool _isLoading = false; // Para feedback de carregamento

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    // Busca todos os países ao iniciar a tela para o autocomplete
    _fetchAllPaises();

    // Adiciona listeners para atualizar os contadores de caracteres
    _codigoController.addListener(_updateCounters);
    _resumoController.addListener(_updateCounters);
    _paisController.addListener(_updateCounters);
    _codigoPaisController.addListener(_updateCounters);

    // Adiciona o listener principal para buscar dados ao mudar o código
    _codigoController.addListener(_onCodigoChanged);
  }
  
  // Referência para a coleção de 'paises' no Firestore se elas forem individuais para cada empresa. ou seja independente de ser filial a ou b tem um banco individual
  /*CollectionReference get _paisesCollectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId)
      .collection('secondaryCompanies')
      .doc(widget.secondaryCompanyId)
      .collection('data')
      .doc('paises')
      .collection('items');*/
////////////////////////////////////////////////////////////////////////////////////////
///referencia para coleção paises se for compartilhada entre empresas principais. os docs de filiais sao iguais:
      CollectionReference get _paisesCollectionRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(widget.mainCompanyId) // Acessa diretamente a empresa principal
      .collection('shared_data') // NOVA SUBCOLEÇÃO PARA DADOS COMPARTILHADOS
      .doc('paises') // Documento que contém os países
      .collection('items'); 

  /// Busca todos os países no Firestore para popular a lista de autocomplete.
  Future<void> _fetchAllPaises() async {
    try {
      final querySnapshot = await _paisesCollectionRef.get();
      final List<Map<String, dynamic>> paises = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        paises.add({
          'codigo': doc.id,
          'pais': data['pais'] ?? '',
          'resumo': data['resumo'] ?? '',
          'codigoPais': data['codigoPais'] ?? '',
        });
      }
      if (mounted) {
        setState(() {
          _allPaises = paises;
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar lista de países: $e')),
        );
      }
    }
  }


  /// Busca os dados do país no Firestore quando o código é alterado.
  Future<void> _onCodigoChanged() async {
    final String codigo = _codigoController.text.trim();

    // Evita busca desnecessária se o código foi preenchido pelo autocomplete
    if (_paisController.text.isNotEmpty) {
      final paisMatch = _allPaises.where((p) => p['codigo'] == codigo);
      if (paisMatch.isNotEmpty && paisMatch.first['pais'] == _paisController.text) {
        return;
      }
    }
    
    // CORREÇÃO: Busca por qualquer código digitado, desde que não seja vazio.
    if (codigo.isEmpty) {
      _clearFormFields(clearCodigo: false); // Limpa outros campos se o código for apagado
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docSnapshot = await _paisesCollectionRef.doc(codigo).get();

      if (docSnapshot.exists) {
        // Documento encontrado, preenche os campos
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _resumoController.text = data['resumo'] ?? '';
          _paisController.text = data['pais'] ?? '';
          _codigoPaisController.text = data['codigoPais'] ?? '';
        });
      } else {
        // Documento não encontrado, limpa os campos para novo cadastro
        _clearFormFields(clearCodigo: false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao consultar país: $e')),
      );
      _clearFormFields(clearCodigo: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Limpa os campos do formulário.
  void _clearFormFields({bool clearCodigo = true}) {
    if (clearCodigo) {
      _codigoController.clear();
    }
    _resumoController.clear();
    _paisController.clear();
    _codigoPaisController.clear();
  }

  /// Salva ou atualiza os dados do país no Firebase.
  Future<void> _savePaisData() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha os campos obrigatórios.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final String codigo = _codigoController.text.trim();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? 'desconhecido';

    final Map<String, dynamic> dataToSave = {
      'resumo': _resumoController.text.trim(),
      'pais': _paisController.text.trim(),
      'codigoPais': _codigoPaisController.text.trim(),
      'ultima_atualizacao': FieldValue.serverTimestamp(),
      'criado_por': currentUserEmail,
    };

    try {
      await _paisesCollectionRef.doc(codigo).set(dataToSave, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('País salvo com sucesso!')),
      );
      await _fetchAllPaises(); // Atualiza a lista de países para o autocomplete
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar país: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Exclui os dados do país do Firebase.
  Future<void> _deletePaisData() async {
    final String codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um código para excluir.')),
      );
      return;
    }

    // Pede confirmação do usuário
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o país com código "$codigo"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      try {
        await _paisesCollectionRef.doc(codigo).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('País "$codigo" excluído com sucesso!')),
        );
        _clearFormFields();
        await _fetchAllPaises(); // Atualiza a lista de países para o autocomplete
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir país: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Gera e exibe um relatório em PDF de todos os países.
  Future<void> _generateReport() async {
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerando relatório...')),
    );

    setState(() => _isLoading = true);
    
    try {
      final querySnapshot = await _paisesCollectionRef.get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Nenhum país encontrado para gerar o relatório.')),
        );
        setState(() => _isLoading = false); // Finaliza o loading
        return;
      }

      final List<Map<String, dynamic>> allPaisesData = [];
      for (var doc in querySnapshot.docs) {
         final data = doc.data() as Map<String, dynamic>;
         allPaisesData.add({
           'codigo': doc.id,
           'resumo': data['resumo'] ?? 'N/A',
           'pais': data['pais'] ?? 'N/A',
           'codigoPais': data['codigoPais'] ?? 'N/A',
         });
      }

      // Ordenar a lista pelo código do país
      allPaisesData.sort((a, b) => a['codigo'].compareTo(b['codigo']));


      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(bottom: 20.0),
              child: pw.Text(
                'Relatório de Países - ${widget.secondaryCompanyId}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10.0),
              child: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          },
          build: (pw.Context context) => [
            pw.Table.fromTextArray(
              headers: ['Código', 'Resumo', 'País', 'Código País'],
              data: allPaisesData.map((pais) => [
                pais['codigo'],
                pais['resumo'],
                pais['pais'],
                pais['codigoPais'],
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              border: pw.TableBorder.all(),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
             pw.SizedBox(height: 20),
             pw.Align(
               alignment: pw.Alignment.bottomRight,
               child: pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
             ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
         name: 'relatorio_paises_${widget.secondaryCompanyId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
    } finally {
       setState(() => _isLoading = false);
    }
  }


  void _updateCounters() {
    setState(() {});
  }

  @override
  void dispose() {
    _codigoController.removeListener(_updateCounters);
    _resumoController.removeListener(_updateCounters);
    _paisController.removeListener(_updateCounters);
    _codigoPaisController.removeListener(_updateCounters);
    _codigoController.removeListener(_onCodigoChanged);

    _codigoController.dispose();
    _resumoController.dispose();
    _paisController.dispose();
    _codigoPaisController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
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
                  return _buildDesktopLayout(constraints);
                } else {
                  return _buildMobileLayout(constraints);
                }
              },
            ),
          ),
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
                padding: EdgeInsets.only(top: 20.0, bottom: 0.0),
                child: Center(
                  child: Text(
                    'País',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildCentralInputArea()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 15.0, bottom: 8.0),
            child: Center(
              child: Text(
                'País',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          AppDrawer(
            parentMaxWidth: constraints.maxWidth,
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
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Container(
         decoration: BoxDecoration(
          color: Colors.blue[100],
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                          children: [
                            SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _codigoController,
                                label: 'Codigo',
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 2,
                                
                                suffixText:
                                    '${_codigoController.text.length}/2',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 150,),
                          ],
                        ),
                          const SizedBox(height: 20),
                          Row(
                          children: [
                            SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _resumoController,
                                label: 'Resumo',
                                
                                maxLength: 15,
                                
                                suffixText:
                                    '${_resumoController.text.length}/15',
                                
                              ),
                            ),
                            SizedBox(width: 150,),
                          ],
                        ),
                          const SizedBox(height: 20),
                          
                          // NOVO: Campo de Autocomplete para País
                          Autocomplete<Map<String, dynamic>>(
                            displayStringForOption: (option) => option['pais'] as String,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<Map<String, dynamic>>.empty();
                              }
                              return _allPaises.where((Map<String, dynamic> option) {
                                final paisName = option['pais'] as String;
                                return paisName.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (Map<String, dynamic> selection) {
                              // Quando um item é selecionado, preenche todos os campos
                              setState(() {
                                 _codigoController.text = selection['codigo'] ?? '';
                                 _paisController.text = selection['pais'] ?? '';
                                 _resumoController.text = selection['resumo'] ?? '';
                                 _codigoPaisController.text = selection['codigoPais'] ?? '';
                              });
                            },
                            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                              // Sincroniza o controller do Autocomplete com o controller principal da tela
                              if (_paisController.text != fieldTextEditingController.text) {
                                 WidgetsBinding.instance.addPostFrameCallback((_) {
                                    fieldTextEditingController.text = _paisController.text;
                                 });
                              }
                              return Row(
                                children: [
                                  SizedBox(width: 150,),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: fieldTextEditingController,
                                      focusNode: fieldFocusNode,
                                      label: 'País',
                                      maxLength: 30,
                                      //isRequired: true,
                                      suffixText: '${fieldTextEditingController.text.length}/30',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Campo obrigatório';
                                        }
                                        
                                                            return null;
                                      },
                                      // Atualiza o controller principal sempre que o usuário digita
                                      onChanged: (value) {
                                         _paisController.text = value;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 150,),

                                ],
                              );
                            },
                             optionsViewBuilder: (context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 200), // Limita a altura da lista
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final option = options.elementAt(index);
                                          return InkWell(
                                            onTap: () {
                                              onSelected(option);
                                            },
                                            child: ListTile(
                                              title: Text(option['pais'] as String),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                          ),

                          const SizedBox(height: 20),
                          Row(
                          children: [
                            SizedBox(width: 150,),
                            Expanded(
                              child: CustomInputField(
                                controller: _codigoPaisController,
                                label: 'Codigo País',
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 4,
                                
                                suffixText:
                                    '${_codigoPaisController.text.length}/4',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  if (value.length != 4) {
                                                      return 'A sigla deve ter exatamente 4 dígitos.';
                                                    }
                                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 150,),
                          ],
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Botões de ação fora do scroll
                _buildActionButtons(),
                const SizedBox(height: 20), // Espaçamento inferior para os botões
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, int maxLength, {bool isNumeric = false, bool isRequired = false, ValueChanged<String>? onChanged}) {
    return CustomInputField(
      controller: controller,
      label: label,
      maxLength: maxLength,
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      suffixText: '${controller.text.length}/$maxLength',
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      } : null,
      onChanged: onChanged,
    );
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0), // Ajuste de padding
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20, // Espaçamento horizontal entre os botões
        runSpacing: 15, // Espaçamento vertical entre as linhas de botões
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
      onPressed: _isLoading ? null : onPressed, // Desabilita o botão durante o carregamento
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(200, 50),
        side: const BorderSide(width: 1.0, color: Colors.black),
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
