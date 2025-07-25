import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/login_page.dart'; // Para logout
import 'package:flutter_application_1/menu.dart'; // Sua TelaPrincipal
import 'package:provider/provider.dart'; // Importe o Provider
import 'package:flutter_application_1/providers/permission_provider.dart'; // Importe o PermissionProvider

class SecondaryCompanySelectionPage extends StatefulWidget {
  final String mainCompanyId;
  // REMOVER allowedSecondaryCompanies do construtor
  // final List<String> allowedSecondaryCompanies; // <--- REMOVER ESTA LINHA
  // final String? userRole; // REMOVER: Não é mais passado

  const SecondaryCompanySelectionPage({
    super.key,
    required this.mainCompanyId,
    // required this.allowedSecondaryCompanies, // <--- REMOVER ESTA LINHA
    // this.userRole, // REMOVER
  });

  @override
  State<SecondaryCompanySelectionPage> createState() => _SecondaryCompanySelectionPageState();
}

class _SecondaryCompanySelectionPageState extends State<SecondaryCompanySelectionPage> {
  // Adicione um Future para carregar os dados do usuário e das empresas
  late Future<List<DocumentSnapshot>> _loadCompaniesFuture;

  @override
  void initState() {
    super.initState();
    _loadCompaniesFuture = _loadAllowedCompanies();
  }

  Future<List<DocumentSnapshot>> _loadAllowedCompanies() async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      // Redireciona para login se o usuário não estiver autenticado
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Busca o documento do usuário para obter allowedSecondaryCompanies
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userDoc.exists || userDoc['mainCompanyId'] != widget.mainCompanyId) {
        throw Exception('Dados do usuário ou empresa principal não correspondem.');
      }

      List<String> allowedSecondaryCompanies = (userDoc['allowedSecondaryCompanies'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [];

      if (allowedSecondaryCompanies.isEmpty) {
        throw Exception('Nenhuma empresa secundária permitida para este usuário.');
      }

      // Agora, busca os documentos das empresas secundárias
      final querySnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.mainCompanyId)
          .collection('secondaryCompanies')
          .where(FieldPath.documentId, whereIn: allowedSecondaryCompanies)
          .get();

      return querySnapshot.docs;

    } catch (e) {
      print("Erro ao carregar empresas permitidas: $e");
      rethrow; // Re-lança o erro para o FutureBuilder lidar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione a Empresa Secundária'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black),
            tooltip: 'Sair',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot>>( // O tipo do FutureBuilder foi atualizado
        future: _loadCompaniesFuture, // Usa o Future que carrega os dados
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar empresas: ${snapshot.error}\nPor favor, tente novamente ou contate o suporte.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma empresa secundária encontrada para você.\nEntre em contato com o administrador.'));
          }

          final companies = snapshot.data!; // Os documentos já filtrados

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Você está conectado à empresa principal: ${widget.mainCompanyId}.',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Selecione a empresa secundária para gerenciar:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot companyDoc = companies[index];
                      String companyId = companyDoc.id;
                      String companyName = companyDoc['name'] ?? 'Empresa Secundária Desconhecida';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: const Icon(Icons.business, color: Colors.blueAccent, size: 30),
                          title: Text(
                            companyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text('ID: $companyId'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () async{
                            // NOVO: Carregar as permissões para a filial selecionada ANTES de navegar
                            final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
                            await permissionProvider.loadUserPermissions(FirebaseAuth.instance.currentUser!.uid); // <-- SEM activeSecondaryCompanyId aqui

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TelaPrincipal(
                                  mainCompanyId: widget.mainCompanyId,
                                  secondaryCompanyId: companyId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}