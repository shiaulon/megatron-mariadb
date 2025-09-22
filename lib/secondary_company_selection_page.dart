import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/permission_provider.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';
import 'menu.dart'; // Sua TelaPrincipal
import 'providers/auth_provider.dart';
import 'services/api_service.dart'; // Nosso novo ApiService

// REMOVIDO: import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVIDO: import 'package:firebase_auth/firebase_auth.dart';
// REMOVIDO: import 'package:flutter_application_1/providers/permission_provider.dart';

class SecondaryCompanySelectionPage extends StatefulWidget {
  final String mainCompanyId;
  final String token; 

  const SecondaryCompanySelectionPage({
    super.key,
    required this.mainCompanyId,
    required this.token,
  });

  @override
  State<SecondaryCompanySelectionPage> createState() => _SecondaryCompanySelectionPageState();
}

class _SecondaryCompanySelectionPageState extends State<SecondaryCompanySelectionPage> {
  late Future<List<Map<String, dynamic>>> _loadCompaniesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadCompaniesFuture = _loadAllowedCompanies();
  }

  Future<List<Map<String, dynamic>>> _loadAllowedCompanies() async {
    // Os dados agora vêm do nosso AuthProvider, não do Firestore!
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final allowedIds = authProvider.allowedSecondaryCompanies;
    final token = widget.token; // DEPOIS: Usa o token recebido pelo construtor

    if (token.isEmpty || allowedIds.isEmpty) { // Verificação ajustada
      throw Exception('Dados de autenticação ou empresas permitidas não encontrados.');
    }
    
    return _apiService.getSecondaryCompaniesDetails(allowedIds, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione a Empresa Secundária'),
        // ... (resto da sua AppBar, incluindo o botão de logout que agora usa o AuthProvider)
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black),
            tooltip: 'Sair',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadCompaniesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar empresas: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma empresa secundária encontrada.'));
          }

          final companies = snapshot.data!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ... (Textos de cabeçalho podem continuar os mesmos)
                Expanded(
                  child: ListView.builder(
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      final companyData = companies[index];
                      final companyId = companyData['id'];
                      final companyName = companyData['nome'] ?? 'Nome Desconhecido';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.business),
                          title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: $companyId'),
                          onTap: () async { // 1. Transforma a função em "async"

                            
                            // 2. Pega os providers necessários
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);

                            // 3. (Boa Prática) Mostra um indicador de carregamento
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => const Center(child: CircularProgressIndicator()),
                            );

                            // 4. Carrega as permissões da API para a filial selecionada
                            await permissionProvider.loadUserPermissions(companyId, widget.token);
                            
                            // 5. Garante que o widget ainda está na tela antes de continuar
                            if (!mounted) return;

                            // 6. Fecha o indicador de carregamento
                            Navigator.pop(context); 

                            // 7. Navega para a tela principal
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