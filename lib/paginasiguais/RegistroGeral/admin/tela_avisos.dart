// lib/admin/tela_avisos.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/botao_ajuda_flutuante.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';



class TelaAvisos extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;

  const TelaAvisos({
    super.key, 
    required this.mainCompanyId, 
    required this.secondaryCompanyId
  });

  @override
  State<TelaAvisos> createState() => _TelaAvisosState();
}

class _TelaAvisosState extends State<TelaAvisos> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) return;
      final historyData = await _adminService.getBroadcastHistory(token);
      setState(() {
        _history = historyData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar histórico: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token == null) throw Exception('Token não encontrado!');
        
        await _adminService.enviarMensagemBroadcast(_messageController.text, token);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem enviada com sucesso para todos os usuários!'), backgroundColor: Colors.green),
        );
        _messageController.clear();
        _loadHistory(); // Atualiza o histórico após o envio

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
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

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna da Esquerda: Formulário de Envio
        Expanded(
          flex: 2, // O formulário ocupa 2/3 do espaço
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enviar Aviso Global', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _messageController,
                  maxLines: 8, // Aumentei um pouco para aproveitar o espaço vertical
                  decoration: const InputDecoration(
                    labelText: 'Mensagem',
                    hintText: 'Digite o aviso que será enviado para todos os usuários online...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, digite uma mensagem.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar para Todos'),
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        const VerticalDivider(width: 24), // Linha divisória
        // Coluna da Direita: Histórico
        Expanded(
          flex: 1, // O histórico ocupa 1/3 do espaço
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Últimos Avisos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Expanded(
                child: _buildHistoryList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // NOVO: Widget para o layout de telas ESTREITAS (um abaixo do outro)
  Widget _buildNarrowLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Enviar Aviso Global', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Mensagem',
              hintText: 'Digite o aviso...',
              border: OutlineInputBorder(),
            ),
            validator: (value) { /* ... */ return null; },
          ),
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar para Todos'),
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
        const Divider(height: 48),
        const Text('Últimos Avisos Enviados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Expanded(
          child: _buildHistoryList(),
        ),
      ],
    );
  }

  // NOVO: Extraí a lista do histórico para um método separado para reutilizar
  Widget _buildHistoryList() {
    if (_isLoading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return const Center(child: Text('Nenhum aviso enviado recentemente.'));
    }
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['created_at']));
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(item['message']),
          subtitle: Text('Enviado em: $date'),
        );
      },
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: BotaoAjudaFlutuante(
         helpContent: _buildHelpContent(),
        child: Column(
          children: [
            TopAppBar(
              currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200), // Aumentei o tamanho máximo
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      // AQUI ESTÁ A MUDANÇA PRINCIPAL
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Define um ponto de quebra. Se a largura for maior que 800, usa o layout largo.
                          if (constraints.maxWidth > 800) {
                            return _buildWideLayout();
                          } else {
                            return _buildNarrowLayout();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}