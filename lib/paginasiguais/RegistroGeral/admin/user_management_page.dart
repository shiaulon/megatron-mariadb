// lib/pages/admin/user_management_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart'; // Importe para DateFormat
// Certifique-se de que este import está correto
import 'user_permission_page.dart';
import 'user_registration_page.dart';

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

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase( // Mantemos a TelaBase para a estrutura geral do app
      body: Scaffold( // <<< --- O FLOATINGACTIONBUTTON PERTENCE AO SCAFFOLD!
        appBar: TopAppBar( // Seu TopAppBar personalizado
          onBackPressed: () {
            Navigator.pop(context);
          },
          currentDate: _currentDate,
        ),
        body: Column( // O corpo principal da sua página
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Gerenciamento de Permissões de Usuários',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('mainCompanyId', isEqualTo: widget.mainCompanyId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}\nPor favor, tente novamente ou contate o suporte.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Nenhum usuário encontrado para esta empresa principal.'));
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userDoc = users[index];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final userId = userDoc.id;
                      final userEmail = userData['email'] ?? 'N/A';
                      final userName = userData['displayName'] ?? userEmail.split('@').first;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Email: $userEmail'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton( // <<< --- ESTÁ AQUI, DENTRO DO SCAFFOLD!
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserRegistrationPage(
                  mainCompanyId: widget.mainCompanyId,
                  secondaryCompanyId: widget.secondaryCompanyId,
                ),
              ),
            );
          },
          child: const Icon(Icons.person_add),
          tooltip: 'Registrar Novo Usuário',
        ),
      ),
    );
  }
}