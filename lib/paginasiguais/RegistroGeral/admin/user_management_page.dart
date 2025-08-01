// lib/pages/admin/user_management_page.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart';
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

  // --- FUNÇÃO DE DUPLICAR USUÁRIO (MOVIDA PARA CÁ) ---
  Future<void> _duplicateUser(String originalUserId) async {
    final formKey = GlobalKey<FormState>();
    final newEmailController = TextEditingController();
    final newNameController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicar Usuário'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newNameController,
                decoration: const InputDecoration(labelText: 'Novo Nome de Exibição'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: newEmailController,
                decoration: const InputDecoration(labelText: 'Novo Email'),
                validator: (v) {
                  if (v!.isEmpty) return 'Campo obrigatório';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop({
                  'email': newEmailController.text.trim(),
                  'name': newNameController.text.trim(),
                });
              }
            },
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );

    if (result == null) return;

    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'userDuplicationTemp-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final newUserCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: result['email']!,
        password: 'temporaryPassword${DateTime.now()}',
      );
      final newUserId = newUserCredential.user!.uid;
      await newUserCredential.user!.updateDisplayName(result['name']);

      final originalUserDocRef = FirebaseFirestore.instance.collection('users').doc(originalUserId);
      final originalUserDoc = await originalUserDocRef.get();
      if (!originalUserDoc.exists) {
        throw Exception("Usuário original não encontrado para copiar.");
      }
      final originalUserData = originalUserDoc.data()!;

      final originalPermissionsSnapshot = await originalUserDocRef.collection('permissions').get();
      final batch = FirebaseFirestore.instance.batch();
      final newUserDocRef = FirebaseFirestore.instance.collection('users').doc(newUserId);
      batch.set(newUserDocRef, {
        ...originalUserData,
        'email': result['email'],
        'displayName': result['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.email ?? 'admin_desconhecido',
      });

      for (var permDoc in originalPermissionsSnapshot.docs) {
        final newPermissionRef = newUserDocRef.collection('permissions').doc(permDoc.id);
        batch.set(newPermissionRef, permDoc.data());
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário duplicado! O novo usuário deve usar a opção 'Esqueci minha senha' para definir uma senha."))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao duplicar: ${e.toString()}"))
      );
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Scaffold(
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
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Nenhum usuário encontrado.'));
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
                          // --- ALTERAÇÃO PRINCIPAL AQUI ---
                          // Trocamos a seta por uma fileira de botões de ação.
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
                              Tooltip(
                                message: 'Duplicar Usuário',
                                child: IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.orange),
                                  onPressed: () => _duplicateUser(userId),
                                ),
                              ),
                              Tooltip(
                                message: 'Excluir Usuário (Requer Plano Blaze)',
                                child: IconButton(
                                  icon: Icon(Icons.delete_forever, color: Colors.grey[400]),
                                  onPressed: null, // Desabilitado
                                ),
                              ),
                            ],
                          ),
                          // O onTap na linha inteira foi removido para dar lugar aos botões.
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