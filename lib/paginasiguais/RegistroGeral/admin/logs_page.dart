// lib/pages/admin/logs_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart';

class LogsPage extends StatefulWidget {
  final String mainCompanyId;

  const LogsPage({super.key, required this.mainCompanyId});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  // Controladores e variáveis de estado para os filtros
  final TextEditingController _userEmailController = TextEditingController();
  String? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;

  // Query que será reconstruída e usada pelo StreamBuilder
  late Query _logsQuery;

  @override
  void initState() {
    super.initState();
    // Inicia com a query padrão (sem filtros)
    _buildQuery();
  }

  // Constrói a query do Firestore com base nos filtros aplicados
  void _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.mainCompanyId)
        .collection('logs')
        .orderBy('timestamp', descending: true);

    // Aplica filtro de email (se preenchido)
    if (_userEmailController.text.isNotEmpty) {
      query = query.where('userEmail', isEqualTo: _userEmailController.text.trim());
    }

    // Aplica filtro de ação (se selecionada)
    if (_selectedAction != null) {
      query = query.where('action', isEqualTo: _selectedAction);
    }

    // Aplica filtro de data inicial
    if (_startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: _startDate);
    }

    // Aplica filtro de data final
    if (_endDate != null) {
      // Adiciona 1 dia e subtrai 1 segundo para incluir o dia inteiro
      final endOfDay = _endDate!.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      query = query.where('timestamp', isLessThanOrEqualTo: endOfDay);
    }

    setState(() {
      _logsQuery = query.limit(200); // Limita para performance
    });
  }

  void _clearFilters() {
    _userEmailController.clear();
    setState(() {
      _selectedAction = null;
      _startDate = null;
      _endDate = null;
    });
    _buildQuery(); // Reconstrói a query original
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
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
            currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Logs de Atividades', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          _buildFiltersUI(), // Adiciona a UI dos filtros
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _logsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: SelectableText('Erro ao carregar logs: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum log encontrado para os filtros aplicados.'));
                }
                final logs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                        title: Text(log['details'] ?? 'Ação sem detalhes', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Por: ${log['userEmail'] ?? 'N/A'}\n'
                          'Ação: ${log['action']} em ${log['targetCollection']}\n'
                          'Filial: ${log['secondaryCompanyId']}\n'
                          'Data: ${_formatTimestamp(log['timestamp'] as Timestamp?)}',
                        ),
                        isThreeLine: true,
                      ),
                    );
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
    // Lista de ações para o Dropdown, baseada no seu Enum
    final actions = ['CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'GENERATE_REPORT', 'PERMISSION_CHANGE', 'ERROR'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ExpansionTile(
        title: const Text('Filtros de Pesquisa', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.filter_list),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.center,
              children: [
                // Filtro por Email
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _userEmailController,
                    decoration: const InputDecoration(labelText: 'Email do Usuário', border: OutlineInputBorder()),
                  ),
                ),
                // Filtro por Ação
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAction,
                    decoration: const InputDecoration(labelText: 'Tipo de Ação', border: OutlineInputBorder()),
                    items: actions.map((String action) {
                      return DropdownMenuItem<String>(value: action, child: Text(action));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedAction = newValue;
                      });
                    },
                  ),
                ),
                // Filtro por Data
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate == null ? 'Data Inicial' : DateFormat('dd/MM/yy').format(_startDate!)),
                      onPressed: () => _selectDate(context, true),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate == null ? 'Data Final' : DateFormat('dd/MM/yy').format(_endDate!)),
                      onPressed: () => _selectDate(context, false),
                    ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpar Filtros'),
                  onPressed: _clearFilters,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}