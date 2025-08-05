import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/log_services.dart';

import 'package:intl/intl.dart';

class LogsPage extends StatefulWidget {
  final String mainCompanyId;

  const LogsPage({super.key, required this.mainCompanyId});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _userEmailController = TextEditingController();
  String? _selectedAction;
  String? _selectedModule; // <-- NOVO ESTADO PARA O FILTRO DE MÓDULO
  DateTime? _startDate;
  DateTime? _endDate;

  late Query _logsQuery;

  @override
  void initState() {
    super.initState();
    _buildQuery();
  }

  void _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.mainCompanyId)
        .collection('logs')
        .orderBy('timestamp', descending: true);

    if (_userEmailController.text.isNotEmpty) {
      query = query.where('userEmail', isEqualTo: _userEmailController.text.trim());
    }
    if (_selectedAction != null) {
      query = query.where('action', isEqualTo: _selectedAction);
    }
    // --- NOVO FILTRO DE MÓDULO ---
    if (_selectedModule != null) {
      query = query.where('modulo', isEqualTo: _selectedModule);
    }
    // ----------------------------
    if (_startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: _startDate);
    }
    if (_endDate != null) {
      final endOfDay = _endDate!.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      query = query.where('timestamp', isLessThanOrEqualTo: endOfDay);
    }

    setState(() {
      _logsQuery = query.limit(200);
    });
  }

  void _clearFilters() {
    _userEmailController.clear();
    setState(() {
      _selectedAction = null;
      _selectedModule = null; // <-- LIMPAR FILTRO DE MÓDULO
      _startDate = null;
      _endDate = null;
    });
    _buildQuery();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Data indisponível';
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        children: [
          TopAppBar(
              onBackPressed: () => Navigator.pop(context),
              currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now())),
          const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Logs de Atividades',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          _buildFiltersUI(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _logsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: SelectableText(
                          'Erro ao carregar logs: ${snapshot.error}\n\nLembre-se de criar os índices compostos no Firestore se necessário.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text(
                          'Nenhum log encontrado para os filtros aplicados.'));
                }
                final logs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    // --- ATUALIZAÇÃO PARA EXIBIR O MÓDULO ---
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                        title: Text(log['details'] ?? 'Ação sem detalhes',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Módulo: ${log['modulo'] ?? 'N/A'}\n'
                          'Por: ${log['userEmail'] ?? 'N/A'}\n'
                          'Ação: ${log['action']} em ${log['targetCollection']}\n'
                          'Filial: ${log['secondaryCompanyId']}\n'
                          'Data: ${_formatTimestamp(log['timestamp'] as Timestamp?)}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                    // ----------------------------------------
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersUI() {
    final actions = LogAction.values.map((e) => e.name).toList();
    final modules = LogModule.values.map((e) => e.name).toList(); // <-- LISTA DE MÓDULOS

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ExpansionTile(
        title: const Text('Filtros de Pesquisa',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.filter_list),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                    width: 250,
                    child: TextField(
                        controller: _userEmailController,
                        decoration: const InputDecoration(
                            labelText: 'Email do Usuário',
                            border: OutlineInputBorder()))),
                // --- NOVO DROPDOWN DE MÓDULOS ---
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedModule,
                    decoration: const InputDecoration(
                        labelText: 'Módulo', border: OutlineInputBorder()),
                    items: modules.map((String module) {
                      return DropdownMenuItem<String>(
                          value: module, child: Text(module));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedModule = newValue;
                      });
                    },
                  ),
                ),
                // ------------------------------------
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAction,
                    decoration: const InputDecoration(
                        labelText: 'Tipo de Ação',
                        border: OutlineInputBorder()),
                    items: actions.map((String action) {
                      return DropdownMenuItem<String>(
                          value: action, child: Text(action));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedAction = newValue;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate == null
                            ? 'Data Inicial'
                            : DateFormat('dd/MM/yy').format(_startDate!)),
                        onPressed: () => _selectDate(context, true)),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate == null
                            ? 'Data Final'
                            : DateFormat('dd/MM/yy').format(_endDate!)),
                        onPressed: () => _selectDate(context, false)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Aplicar Filtros'),
                    onPressed: _buildQuery,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white)),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpar Filtros'),
                    onPressed: _clearFilters),
              ],
            ),
          )
        ],
      ),
    );
  }
}