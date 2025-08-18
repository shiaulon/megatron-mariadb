import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'user_permission_page.dart';
// import 'user_registration_page.dart'; // Manteremos a lógica de criação para depois

// REMOVIDO: Todos os imports do Firebase

class UserManagementPage extends StatefulWidget {
  final String mainCompanyId;
  final String secondaryCompanyId;

  const UserManagementPage({
    super.key,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
  });

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late String _currentDate;
  late Future<List<Map<String, dynamic>>> _usersFuture;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    // Acessa o token via Provider assim que o estado é iniciado
    _loadUsers();
  }
  
  void _loadUsers() {
    // Usamos o 'listen: false' porque só precisamos pegar o valor do token uma vez
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _usersFuture = _adminService.listUsers(token);
      });
    } else {
      // Se por algum motivo não houver token, lidamos com o erro
      setState(() {
         _usersFuture = Future.error('Token de autenticação não encontrado.');
      });
    }
  }

  // As funções de duplicar, deletar e registrar novo usuário serão migradas em seguida.
  // Por enquanto, vamos focar em listar e navegar para as permissões.

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Scaffold(
        backgroundColor: Colors.transparent, // Para o fundo da TelaBase aparecer
        appBar: TopAppBar(
          onBackPressed: () => Navigator.pop(context),
          currentDate: _currentDate,
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Gerenciamento de Usuários',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar usuários: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum usuário encontrado.'));
                  }
                  
                  final users = snapshot.data!;
                  
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index];
                      final userId = userData['id'];
                      final userEmail = userData['email'] ?? 'N/A';
                      final userName = userData['displayName'] ?? userEmail.split('@').first;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Email: $userEmail'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Editar Permissões',
                                child: IconButton(
                                  icon: const Icon(Icons.security),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserPermissionPage(
                                          userId: userId,
                                          userName: userName,
                                          mainCompanyId: widget.mainCompanyId,
                                          secondaryCompanyId: widget.secondaryCompanyId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Os outros botões serão reativados quando migrarmos suas funções
                              Tooltip(
                                message: 'Duplicar Usuário (em breve)',
                                child: IconButton(
                                  icon: Icon(Icons.copy, color: Colors.grey[400]),
                                  onPressed: null,
                                ),
                              ),
                              Tooltip(
                                message: 'Excluir Usuário (em breve)',
                                child: IconButton(
                                  icon: Icon(Icons.delete_forever, color: Colors.grey[400]),
                                  onPressed: null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // A navegação para UserRegistrationPage será reativada em breve
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("A tela de registro será migrada em breve!"))
            );
          },
          child: const Icon(Icons.person_add),
          tooltip: 'Registrar Novo Usuário',
        ),
      ),
    );
  }
}