// lib/pages/admin/logs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:provider/provider.dart';
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
  String? _selectedModule;
  DateTime? _startDate;
  DateTime? _endDate;
  
  Future<List<Map<String, dynamic>>>? _logsFuture;

  @override
  void initState() {
    super.initState();
    // CORREÇÃO: Chama a função para carregar os logs iniciais
    _applyFilters(); 
  }

  void _applyFilters() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      setState(() {
        _logsFuture = Future.error('Usuário não autenticado.');
      });
      return;
    }
    final logService = LogService(token);
    setState(() {
      _logsFuture = logService.getLogs(
        userEmail: _userEmailController.text.trim(),
        action: _selectedAction,
        modulo: _selectedModule,
      );
    });
  }

  void _clearFilters() {
    _userEmailController.clear();
    setState(() {
      _selectedAction = null;
      _selectedModule = null;
      _startDate = null; // Garante que as datas também sejam limpas
      _endDate = null;
    });
    _applyFilters();
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return 'Data indisponível';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime.toLocal());
    } catch (e) {
      return 'Data inválida';
    }
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
              child: Text('Logs de Atividades', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          _buildFiltersUI(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: SelectableText('Erro ao carregar logs: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum log encontrado para os filtros aplicados.'));
                }
                final logs = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                        title: Text(log['details'] ?? 'Ação sem detalhes', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Módulo: ${log['modulo'] ?? 'N/A'}\n'
                          'Por: ${log['user_email'] ?? 'N/A'}\n'
                          'Ação: ${log['action']} em ${log['target_collection'] ?? 'N/A'}\n'
                          'Filial: ${log['id_empresa_secundaria'] ?? 'N/A'}\n'
                          'Data: ${_formatTimestamp(log['timestamp'] as String?)}',
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
    final actions = LogAction.values.map((e) => e.name).toList();
    final modules = LogModule.values.map((e) => e.name).toList();

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
                SizedBox(
                    width: 250,
                    child: TextField(
                        controller: _userEmailController,
                        decoration: const InputDecoration(labelText: 'Email do Usuário', border: OutlineInputBorder()))),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedModule,
                    decoration: const InputDecoration(labelText: 'Módulo', border: OutlineInputBorder()),
                    items: modules.map((String module) => DropdownMenuItem<String>(value: module, child: Text(module))).toList(),
                    onChanged: (newValue) => setState(() => _selectedModule = newValue),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAction,
                    decoration: const InputDecoration(labelText: 'Tipo de Ação', border: OutlineInputBorder()),
                    items: actions.map((String action) => DropdownMenuItem<String>(value: action, child: Text(action))).toList(),
                    onChanged: (newValue) => setState(() => _selectedAction = newValue),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate == null ? 'Data Inicial' : DateFormat('dd/MM/yy').format(_startDate!)),
                        onPressed: () => _selectDate(context, true)),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate == null ? 'Data Final' : DateFormat('dd/MM/yy').format(_endDate!)),
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
                    onPressed: _applyFilters, // CORRIGIDO AQUI
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
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