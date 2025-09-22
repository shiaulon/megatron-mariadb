// lib/registroGeral/natureza_caracteristica_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/botao_ajuda_flutuante.dart';
import 'package:flutter_application_1/reutilizaveis/customImputField.dart';
import 'package:flutter_application_1/reutilizaveis/menuLateral.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/natureza_caracteristica_service.dart';
import 'package:flutter_application_1/services/natureza_service.dart';
import 'package:flutter_application_1/submenus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NaturezaCaracteristicaScreen extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;
  final String? userRole;

  const NaturezaCaracteristicaScreen({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    this.userRole,
  });

  @override
  State<NaturezaCaracteristicaScreen> createState() => _NaturezaCaracteristicaScreenState();
}

class _NaturezaCaracteristicaScreenState extends State<NaturezaCaracteristicaScreen> {
  final NaturezaService _naturezaService = NaturezaService();
  final NaturezaCaracteristicaService _service = NaturezaCaracteristicaService();

  static const double _breakpoint = 900.0;
  
  bool _isLoading = false;
  late String _currentDate;

  List<Map<String, dynamic>> _allNaturezas = [];
  List<Map<String, dynamic>> _caracteristicasDaNatureza = [];
  List<String> _sequenciasDaCaracteristica = [];
  
  final _naturezaController = TextEditingController();
  Map<String, dynamic>? _selectedNatureza;
  String? _selectedCaracteristica;
  String? _selectedSequencia;
  final _exibirAssociadosController = TextEditingController(text: 'N');

  List<Map<String, dynamic>> _rgList = [];
  final Set<String> _selectedRgIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _naturezaController.dispose();
    _exibirAssociadosController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception("Usuário não autenticado.");
      _allNaturezas = await _naturezaService.getAll(token);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar naturezas: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNaturezaSelected(Map<String, dynamic> natureza) {
    setState(() {
      _selectedNatureza = natureza;
      _naturezaController.text = natureza['descricao'] ?? '';
      _caracteristicasDaNatureza = List<Map<String, dynamic>>.from(natureza['caracteristicas'] ?? []);
      _selectedCaracteristica = null;
      _sequenciasDaCaracteristica.clear();
      _selectedSequencia = null;
      _rgList.clear();
    });
  }

  void _onCaracteristicaSelected(String? caracNome) {
    setState(() {
      _selectedCaracteristica = caracNome;
      _sequenciasDaCaracteristica.clear();
      _selectedSequencia = null;
      _rgList.clear();
      
      if (caracNome != null) {
        final caracData = _caracteristicasDaNatureza.firstWhere((c) => c['nome'] == caracNome, orElse: () => {});
        _sequenciasDaCaracteristica = List<String>.from(caracData['sequencias'] ?? []);
      }
    });
  }
  
  void _clearNaturezaSelection() {
    setState(() {
      _naturezaController.clear();
      _selectedNatureza = null;
      _caracteristicasDaNatureza.clear();
      _selectedCaracteristica = null;
      _sequenciasDaCaracteristica.clear();
      _selectedSequencia = null;
      _rgList.clear();
    });
  }

  Future<void> _fetchRgData() async {
    if (_selectedNatureza == null || _selectedCaracteristica == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione Natureza e Característica para buscar.')));
      return;
    }
    
    setState(() { _isLoading = true; _selectAll = false; });
    _selectedRgIds.clear();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final Map<String, String> filters = {
        'natureza_id': _selectedNatureza!['id'].toString(),
        'caracteristica_nome': _selectedCaracteristica!,
        'exibir_associados': _exibirAssociadosController.text.toUpperCase(),
      };
      
      final result = await _service.getDados(filters, token);
      if(mounted) setState(() => _rgList = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar dados: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyChanges() async {
    if (_selectedRgIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum RG selecionado para aplicar.')));
      return;
    }
    if (_selectedNatureza == null || _selectedCaracteristica == null || _selectedSequencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione Natureza, Característica e Sequência para aplicar.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final dataToSave = {
        'natureza_id': _selectedNatureza!['id'],
        'caracteristica_nome': _selectedCaracteristica,
        'sequencia_valor': _selectedSequencia,
        'rg_ids': _selectedRgIds.toList(),
        'secondaryCompanyId': widget.secondaryCompanyId,
      };

      await _service.aplicar(dataToSave, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alterações aplicadas com sucesso!'), backgroundColor: Colors.green));
        await _fetchRgData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao aplicar alterações: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: BotaoAjudaFlutuante(helpContent: _buildHelpContent(),
        child: Stack(
          children: [
            Column(
              children: [
                TopAppBar(onBackPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TelaSubPrincipal(mainCompanyId: widget.mainCompanyId, secondaryCompanyId: widget.secondaryCompanyId, userRole: widget.userRole))), currentDate: _currentDate),
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
            if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralContent() {
    final theme = Theme.of(context);
    return Column(
      children: [
         Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('Manut RG "Natureza/Caracteristica"', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: theme.colorScheme.surface.withOpacity(0.5), // Cor de fundo do container principal
                border: Border.all(color: theme.dividerColor), // Cor da borda
                 borderRadius: BorderRadius.circular(10.0)),
              child: Column(
                children: [
                  _buildFilterBar(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildRgTable()),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _applyChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, fixedSize: const Size(150, 50),shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),),
                      child: const Text('APLICAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildFilterBar() {
    return Column(
      children: [
        Row(
          // ▼▼▼ AJUSTE DE ALINHAMENTO ▼▼▼
          // Alinha todos os campos pelo topo, resolvendo a diferença de altura.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtro Natureza
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedNatureza,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Natureza',
                  border: OutlineInputBorder(),
                ),
                // Mapeia a lista de naturezas para os itens do dropdown
                items: _allNaturezas.map<DropdownMenuItem<Map<String, dynamic>>>((natureza) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: natureza, // O valor do item é o mapa completo da natureza
                    child: Text(natureza['descricao'] ?? 'N/A'), // O que o usuário vê
                  );
                }).toList(),
                onChanged: (Map<String, dynamic>? newValue) {
                  if (newValue != null) {
                    _onNaturezaSelected(newValue);
                  }
                },
              ),
            
            ),
            const SizedBox(width: 10),
            // Filtro Característica
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedCaracteristica,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Característica',
                  border: const OutlineInputBorder(),
                  //fillColor: _selectedNatureza != null ? Theme.of(context).colorScheme.surface : Colors.grey[200],
                  filled: true,
                ),
                items: _caracteristicasDaNatureza.map<DropdownMenuItem<String>>((carac) {
                  String nome = carac['nome'].toString();
                  return DropdownMenuItem<String>(
                    value: nome,
                    child: Text(nome),
                  );
                }).toList(),
                onChanged: _selectedNatureza != null ? _onCaracteristicaSelected : null,
              ),
            ),
            const SizedBox(width: 10),
            // Filtro Sequência
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedSequencia,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Sequência',
                  border: const OutlineInputBorder(),
                  //fillColor: _selectedCaracteristica != null ? Theme.of(context).colorScheme.surface : Colors.grey[200],
                  filled: true,
                ),
                items: _sequenciasDaCaracteristica.map((seq) => DropdownMenuItem(value: seq, child: Text(seq))).toList(),
                onChanged: _selectedCaracteristica != null ? (val) => setState(() => _selectedSequencia = val) : null,
              ),
            ),
            const SizedBox(width: 10),
            
            // ▼▼▼ AJUSTE: DROPDOWN PARA 'ASSOCIADOS' ▼▼▼
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _exibirAssociadosController.text.toUpperCase(),
                decoration: const InputDecoration(
                  labelText: 'Associados?',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'N', child: Text('Não')),
                  DropdownMenuItem(value: 'S', child: Text('Sim')),
                ],
                onChanged: (value) {
                  setState(() {
                    _exibirAssociadosController.text = value ?? 'N';
                  });
                },
              ),
            ),
            // ▲▲▲ FIM DO AJUSTE ▲▲▲

            const SizedBox(width: 10),
            // Botão de Busca
            // ▼▼▼ SUBSTITUA O BOTÃO DE BUSCAR POR ESTE ▼▼▼
            ElevatedButton(
              onPressed: _fetchRgData,
              
              style: ElevatedButton.styleFrom(
                
                backgroundColor: Colors.yellow, // Cor de fundo amarela
                foregroundColor: Colors.black, // Cor do texto preta para contraste
                fixedSize: const Size(120, 50), // Mantém a altura dos outros campos
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                side: const BorderSide(color: Colors.black, width: 1.0), // Adiciona a borda preta
              ),
              child: const Text(
                'BUSCAR', // Coloquei em maiúsculo para padronizar
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ▼▼▼ FUNÇÃO AUXILIAR PARA AUTOCOMPLETE (COMO NAS OUTRAS TELAS) ▼▼▼
  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required String displayFieldKey,
    required List<String> searchFieldKeys,
    required List<Map<String, dynamic>> options,
    required Function(Map<String, dynamic>) onSelected,
    required VoidCallback onClear,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option[displayFieldKey]?.toString() ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          onClear();
          return const Iterable.empty();
        }
        return options.where((option) {
          // Busca em múltiplos campos (ex: 'id' e 'descricao')
          return searchFieldKeys.any((key) {
            return (option[key]?.toString() ?? '').toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        });
      },
      onSelected: (selection) {
        onSelected(selection);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        // Sincroniza o controller do autocomplete com o nosso controller de estado
        if (controller.text != fieldController.text) {
          fieldController.value = controller.value;
        }
        return CustomInputField(
          controller: fieldController,
          focusNode: focusNode,
          label: label,
          hintText: "Digite para buscar...",
          onChanged: (value) {
            controller.text = value; // Atualiza o controller principal
            if (value.isEmpty) {
              onClear();
            }
          },
        );
      },
    );
  }

  Widget _buildRgTable() {
    if (_rgList.isEmpty) {
      return const Center(child: Text("Use os filtros e clique em 'Buscar'."));
    }
    final theme = Theme.of(context); 
    return Column(
      children: [
        Container(
          color: theme.primaryColor.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Checkbox(
                  value: _selectAll,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (value) {
                    setState(() {
                      _selectAll = value ?? false;
                      _selectedRgIds.clear();
                      if (_selectAll) {
                        _selectedRgIds.addAll(_rgList.map((rg) => rg['id'].toString()));
                      }
                    });
                  },
                ),
              ),
               Expanded(flex: 2, child: Text('Código', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
               Expanded(flex: 5, child: Text('Razão Social', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
               Expanded(flex: 2, child: Text('Sequência Atrelada', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _rgList.length,
            itemBuilder: (context, index) {
              final rg = _rgList[index];
              final rgId = rg['id'].toString();
              final isSelected = _selectedRgIds.contains(rgId);
              return Material(
                color: index.isEven ? theme.colorScheme.surface : theme.scaffoldBackgroundColor,
                child: InkWell(
                  onTap: () => setState(() => isSelected ? _selectedRgIds.remove(rgId) : _selectedRgIds.add(rgId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Checkbox(
                            value: isSelected,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) { _selectedRgIds.add(rgId); } 
                                else { _selectedRgIds.remove(rgId); }
                              });
                            },
                          ),
                        ),
                        Expanded(flex: 2, child: Text(rg['codigo_interno']?.toString() ?? '')),
                        Expanded(flex: 5, child: Text(rg['razao_social']?.toString() ?? '')),
                        Expanded(flex: 2, child: Text(rg['sequencia_valor']?.toString() ?? '-')),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}