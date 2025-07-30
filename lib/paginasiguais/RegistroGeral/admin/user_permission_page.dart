// lib/pages/admin/user_permission_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/permission_model.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:intl/intl.dart';

class UserPermissionPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String mainCompanyId;
  final String secondaryCompanyId; // secondaryCompanyId do admin logado

  const UserPermissionPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
  });

  @override
  State<UserPermissionPage> createState() => _UserPermissionPageState();
}

class _UserPermissionPageState extends State<UserPermissionPage> {
  late String _currentDate;
  // AGORA: Um mapa para guardar as permissões de CADA filial. Chave: filialId, Valor: mapa de permissões.
  late Map<String, Map<String, dynamic>> _permissionsByFilial;
  // AGORA: Um mapa para guardar os nomes das filiais. Chave: filialId, Valor: nome da filial.
  late Map<String, String> _filialNames;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _permissionsByFilial = {};
    _filialNames = {};
    _loadUserPermissionsAndFiliais();
  }

  Future<void> _loadUserPermissionsAndFiliais() async {
    setState(() => _isLoading = true);
    try {
      // 1. Buscar as filiais permitidas do usuário
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (!userDoc.exists) {
        throw Exception("Usuário não encontrado.");
      }
      final List<String> allowedFiliais = List<String>.from(userDoc.data()?['allowedSecondaryCompanies'] ?? []);
      if (allowedFiliais.isEmpty) {
        setState(() => _isLoading = false);
        return; // Sai se não houver filiais
      }

      // 2. Buscar os nomes das filiais
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.mainCompanyId)
          .collection('secondaryCompanies')
          .where(FieldPath.documentId, whereIn: allowedFiliais)
          .get();

      for (var doc in companiesSnapshot.docs) {
        _filialNames[doc.id] = doc.data()['name'] ?? 'Nome Desconhecido';
      }

      // 3. Buscar as permissões para cada filial
      final permissionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('permissions')
          .where(FieldPath.documentId, whereIn: allowedFiliais)
          .get();

      final Map<String, Map<String, dynamic>> loadedPermissions = {};
      for (var doc in permissionsSnapshot.docs) {
        loadedPermissions[doc.id] = Map<String, dynamic>.from(doc.data()?['acessos'] ?? {});
      }

      // 4. Garantir que cada filial tenha um conjunto de permissões (mesmo que padrão)
      for (String filialId in allowedFiliais) {
        if (!loadedPermissions.containsKey(filialId)) {
          loadedPermissions[filialId] = UserPermissions.defaultPermissions().acessos;
        }
      }
      
      setState(() {
        _permissionsByFilial = loadedPermissions;
      });

    } catch (e) {
      print("Erro ao carregar permissões para edição: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar permissões: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _togglePermission(String filialId, List<String> path, bool newValue) {
    setState(() {
      Map<String, dynamic> currentLevel = _permissionsByFilial[filialId]!;
      for (int i = 0; i < path.length; i++) {
        final key = path[i];
        if (i == path.length - 1) {
          currentLevel[key] = newValue;
        } else {
          currentLevel.putIfAbsent(key, () => {});
          if (currentLevel[key] is! Map<String, dynamic>) {
            currentLevel[key] = {};
          }
          currentLevel = currentLevel[key] as Map<String, dynamic>;
        }
      }
    });
  }

  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      _permissionsByFilial.forEach((filialId, acessos) {
        DocumentReference permDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('permissions')
            .doc(filialId);
        
        // Usando o toMap do modelo para incluir metadados
        final permissionsData = UserPermissions(acessos: acessos);
        batch.set(permDocRef, permissionsData.toMap());
      });

      await batch.commit();

      // LOG DE ALTERAÇÃO DE PERMISSÃO
      await LogService.addLog(
        action: LogAction.PERMISSION_CHANGE,
        mainCompanyId: widget.mainCompanyId,
        secondaryCompanyId: widget.secondaryCompanyId, // Filial do admin
        targetCollection: 'users',
        targetDocId: widget.userId,
        details: 'Admin ${FirebaseAuth.instance.currentUser?.email} alterou as permissões para o usuário ${widget.userName} (ID: ${widget.userId}).',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissões salvas com sucesso!')),
      );
      
      // Não é mais necessário recarregar o provider global aqui,
      // pois ele é carregado com a filial ativa no momento do login/seleção.

    } catch (e) {
      print("Erro ao salvar permissões: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar permissões: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _getPermissionValue(String filialId, List<String> path) {
    Map<String, dynamic>? current = _permissionsByFilial[filialId];
    if (current == null) return false;

    for (int i = 0; i < path.length; i++) {
      final key = path[i];
      if (current!.containsKey(key)) {
        if (i == path.length - 1) {
          return current[key] == true;
        } else {
          if (current[key] is! Map<String, dynamic>) {
            return false;
          }
          current = current[key] as Map<String, dynamic>;
        }
      } else {
        return false;
      }
    }
    return false;
  }

  // AGORA: Os widgets de construção recebem o `filialId`
  Widget _buildPermissionCheckbox(String filialId, String title, List<String> path, {double paddingLeft = 0.0}) {
    bool currentValue = _getPermissionValue(filialId, path);
    return Padding(
      padding: EdgeInsets.only(left: paddingLeft),
      child: Row(
        children: [
          Checkbox(
            value: currentValue,
            onChanged: _isLoading ? null : (bool? newValue) {
              if (newValue != null) {
                _togglePermission(filialId, path, newValue);
              }
            },
          ),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildExpandablePermissionBlock(String filialId, String title, IconData icon, List<String> blockPath, List<Widget> children, {double paddingLeft = 0.0}) {
    bool blockAccess = _getPermissionValue(filialId, blockPath);
    return ExpansionTile(
      leading: Icon(icon),
      title: Row(
        children: [
          Checkbox(
            value: blockAccess,
            onChanged: _isLoading ? null : (bool? newValue) {
              if (newValue != null) {
                _togglePermission(filialId, blockPath, newValue);
              }
            },
          ),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      children: children,
      tilePadding: EdgeInsets.only(left: paddingLeft + 16.0, right: 16.0),
      childrenPadding: const EdgeInsets.only(left: 30.0),
    );
  }

  // AGORA: Constrói a árvore de permissões para UMA filial
  Widget _buildPermissionTreeForFilial(String filialId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandablePermissionBlock(
          filialId, 'Registro Geral', Icons.groups, ['registro_geral', 'acesso'],
          [
            _buildExpandablePermissionBlock(
              filialId, 'Tabelas', Icons.table_chart, ['registro_geral', 'tabelas', 'acesso'],
              [
                _buildPermissionCheckbox(filialId, 'Controle', ['registro_geral', 'tabelas', 'controle'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'País', ['registro_geral', 'tabelas', 'pais'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Estado', ['registro_geral', 'tabelas', 'estado'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Estado x Imposto', ['registro_geral', 'tabelas', 'estado_x_imposto'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Cidade', ['registro_geral', 'tabelas', 'cidade'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Natureza', ['registro_geral', 'tabelas', 'natureza'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Situação', ['registro_geral', 'tabelas', 'situacao'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Cargo', ['registro_geral', 'tabelas', 'cargo'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Tipo Telefone', ['registro_geral', 'tabelas', 'tipo_telefone'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Tipo Histórico', ['registro_geral', 'tabelas', 'tipo_historico'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Tipo Bem Crédito', ['registro_geral', 'tabelas', 'tipo_bem_credito'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Condição Pagamento', ['registro_geral', 'tabelas', 'condicao_pagamento'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'IBGE x Cidade', ['registro_geral', 'tabelas', 'ibge_x_cidade'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Como nos Conheceu', ['registro_geral', 'tabelas', 'como_nos_conheceu'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Atividade Empresa', ['registro_geral', 'tabelas', 'atividade_empresa'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Tabela CEST', ['registro_geral', 'tabelas', 'tabela_cest'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Manut Tab Governo NCM Imposto', ['registro_geral', 'tabelas', 'manut_tab_governo_ncm_imposto'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Fazenda', ['registro_geral', 'tabelas', 'fazenda'], paddingLeft: 10.0),
                _buildPermissionCheckbox(filialId, 'Natureza Rendimento', ['registro_geral', 'tabelas', 'natureza_rendimento'], paddingLeft: 10.0),
                // ... adicione todos os outros checkboxes aqui, passando o filialId
              ],
              paddingLeft: 20.0,
            ),
            _buildExpandablePermissionBlock(
              filialId, 'Registro Geral (Manut.)', Icons.app_registration, ['registro_geral', 'registro_geral_manut', 'acesso'],
              [
                _buildPermissionCheckbox(filialId, 'Manut RG', ['registro_geral', 'registro_geral_manut', 'manut_rg'], paddingLeft: 10.0),
              ],
              paddingLeft: 20.0,
            ),
          ],
        ),
        _buildExpandablePermissionBlock(
          filialId, 'Crédito', Icons.credit_card, ['credito', 'acesso'],
          [
            _buildPermissionCheckbox(filialId, 'Documentos Básicos', ['credito', 'tabelas', 'documentos_basicos'], paddingLeft: 10.0),
            // Adicione outros checkboxes de crédito aqui no futuro
          ]
        ),
        
        //_buildPermissionCheckbox(filialId, 'Crédito', ['credito', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Relatório', ['relatorio', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Relatório de Crítica', ['relatorio_de_critica', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Etiqueta', ['etiqueta', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Contatos Geral', ['contatos_geral', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Portaria', ['portaria', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Qualificação RG', ['qualificacao_rg', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Área RG', ['area_rg', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Tabela Preço X RG', ['tabela_preco_x_rg', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Módulo Especial', ['modulo_especial', 'acesso']),
        _buildPermissionCheckbox(filialId, 'CRM', ['crm', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Follow-up', ['follow_up', 'acesso']),
        _buildPermissionCheckbox(filialId, 'Administração de Usuários', ['administracao_usuarios', 'acesso']),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        children: [
          TopAppBar(
            onBackPressed: () => Navigator.pop(context),
            currentDate: _currentDate,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Editar Permissões para ${widget.userName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _permissionsByFilial.isEmpty
                    ? const Center(child: Text('Este usuário não possui filiais associadas.'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        children: _permissionsByFilial.keys.map((filialId) {
                          final filialName = _filialNames[filialId] ?? filialId;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 4,
                            child: ExpansionTile(
                              leading: const Icon(Icons.business, color: Colors.blueAccent),
                              title: Text(
                                'Filial: $filialName',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text('ID: $filialId'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildPermissionTreeForFilial(filialId),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _savePermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SALVAR TODAS AS PERMISSÕES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}