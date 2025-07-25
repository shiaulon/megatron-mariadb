import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/permission_model.dart';
import 'package:flutter_application_1/providers/permission_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  late Map<String, dynamic> _localPermissionsData; // Permissões do usuário selecionado
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    // Inicializa com um mapa vazio ou as permissões padrão antes de carregar
    _localPermissionsData = UserPermissions.defaultPermissions().acessos; // Carrega os acessos padrão
    _loadUserPermissionsForEditing();
  }

  Future<void> _loadUserPermissionsForEditing() async {
    setState(() => _isLoading = true);
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('permissions')
          .doc('user_access') // Documento fixo 'user_access'
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          _localPermissionsData = Map<String, dynamic>.from(docSnapshot.data()!['acessos'] ?? {});
        });
      } else {
        // Se não houver documento de permissões, usa as padrão e salva para criar o documento
        final defaultAccesses = UserPermissions.defaultPermissions().acessos;
        setState(() {
          _localPermissionsData = Map<String, dynamic>.from(defaultAccesses);
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('permissions')
            .doc('user_access')
            .set({'acessos': defaultAccesses});
      }
    } catch (e) {
      print("Erro ao carregar permissões para edição: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar permissões: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Função para alternar o estado de um checkbox e atualizar as permissões locais
  void _togglePermission(List<String> path, bool newValue) {
    setState(() {
      Map<String, dynamic> currentLevel = _localPermissionsData; // Começa com o mapa base

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

  // Função para salvar as permissões editadas no Firestore
  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('permissions')
          .doc('user_access')
          .set({'acessos': _localPermissionsData}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissões salvas com sucesso!')),
      );

      // Se o usuário logado atualmente for o próprio usuário que teve as permissões alteradas,
      // recarregue as permissões no PermissionProvider global para que a interface se atualize.
      if (FirebaseAuth.instance.currentUser?.uid == widget.userId) {
        Provider.of<PermissionProvider>(context, listen: false)
            .loadUserPermissions(widget.userId); // Sem activeSecondaryCompanyId
      }
    } catch (e) {
      print("Erro ao salvar permissões: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar permissões: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Função auxiliar para obter o valor de uma permissão aninhada para o checkbox
  bool _getPermissionValue(List<String> path) {
    Map<String, dynamic> current = _localPermissionsData;
    for (int i = 0; i < path.length; i++) {
      final key = path[i];
      if (current.containsKey(key)) {
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

  // Widget auxiliar para construir um checkbox de permissão
  Widget _buildPermissionCheckbox(String title, List<String> path, {double paddingLeft = 0.0}) {
    bool currentValue = _getPermissionValue(path);

    return Padding(
      padding: EdgeInsets.only(left: paddingLeft),
      child: Row(
        children: [
          Checkbox(
            value: currentValue,
            onChanged: _isLoading ? null : (bool? newValue) {
              if (newValue != null) {
                _togglePermission(path, newValue);
              }
            },
          ),
          Text(title),
        ],
      ),
    );
  }

  // Widget auxiliar para construir um bloco expansível de permissões (menu/submenu)
  Widget _buildExpandablePermissionBlock(String title, IconData icon, List<String> blockPath, List<Widget> children, {double paddingLeft = 0.0}) {
    bool blockAccess = _getPermissionValue(blockPath);

    return ExpansionTile(
      leading: Icon(icon),
      title: Row(
        children: [
          Checkbox(
            value: blockAccess,
            onChanged: _isLoading ? null : (bool? newValue) {
              if (newValue != null) {
                _togglePermission(blockPath, newValue);
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

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      body: Column(
        children: [
          TopAppBar(
            onBackPressed: () {
              Navigator.pop(context); // Voltar para a lista de usuários
            },
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bloco principal "Registro Geral"
                        _buildExpandablePermissionBlock(
                          'Registro Geral',
                          Icons.groups,
                          ['registro_geral', 'acesso'],
                          [
                            // Submenu "Tabelas"
                            _buildExpandablePermissionBlock(
                              'Tabelas',
                              Icons.table_chart,
                              ['registro_geral', 'tabelas', 'acesso'],
                              [
                                _buildPermissionCheckbox('Controle', ['registro_geral', 'tabelas', 'controle'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('País', ['registro_geral', 'tabelas', 'pais'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Estado', ['registro_geral', 'tabelas', 'estado'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Estado x Imposto', ['registro_geral', 'tabelas', 'estado_x_imposto'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Cidade', ['registro_geral', 'tabelas', 'cidade'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Natureza', ['registro_geral', 'tabelas', 'natureza'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Situação', ['registro_geral', 'tabelas', 'situacao'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Cargo', ['registro_geral', 'tabelas', 'cargo'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Tipo Telefone', ['registro_geral', 'tabelas', 'tipo_telefone'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Tipo Histórico', ['registro_geral', 'tabelas', 'tipo_historico'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Tipo Bem Crédito', ['registro_geral', 'tabelas', 'tipo_bem_credito'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Condição Pagamento', ['registro_geral', 'tabelas', 'condicao_pagamento'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('IBGE x Cidade', ['registro_geral', 'tabelas', 'ibge_x_cidade'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Como nos Conheceu', ['registro_geral', 'tabelas', 'como_nos_conheceu'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Atividade Empresa', ['registro_geral', 'tabelas', 'atividade_empresa'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Tabela CEST', ['registro_geral', 'tabelas', 'tabela_cest'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Manut Tab Governo NCM Imposto', ['registro_geral', 'tabelas', 'manut_tab_governo_ncm_imposto'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Fazenda', ['registro_geral', 'tabelas', 'fazenda'], paddingLeft: 10.0),
                                _buildPermissionCheckbox('Natureza Rendimento', ['registro_geral', 'tabelas', 'natureza_rendimento'], paddingLeft: 10.0),
                              ],
                              paddingLeft: 20.0, // Indentação para submenu
                            ),
                            // Submenu "Registro Geral" (Manut RG)
                            _buildExpandablePermissionBlock(
                              'Registro Geral (Manut.)',
                              Icons.app_registration,
                              ['registro_geral', 'registro_geral_manut', 'acesso'],
                              [
                                _buildPermissionCheckbox('Manut RG', ['registro_geral', 'registro_geral_manut', 'manut_rg'], paddingLeft: 10.0),
                              ],
                              paddingLeft: 20.0,
                            ),
                          ],
                        ),
                        // ---
                        // Outros blocos de menu principal
                        _buildPermissionCheckbox('Crédito', ['credito', 'acesso']),
                        _buildPermissionCheckbox('Relatório', ['relatorio', 'acesso']),
                        _buildPermissionCheckbox('Relatório de Crítica', ['relatorio_de_critica', 'acesso']),
                        _buildPermissionCheckbox('Etiqueta', ['etiqueta', 'acesso']),
                        _buildPermissionCheckbox('Contatos Geral', ['contatos_geral', 'acesso']),
                        _buildPermissionCheckbox('Portaria', ['portaria', 'acesso']),
                        _buildPermissionCheckbox('Qualificação RG', ['qualificacao_rg', 'acesso']),
                        _buildPermissionCheckbox('Área RG', ['area_rg', 'acesso']),
                        _buildPermissionCheckbox('Tabela Preço X RG', ['tabela_preco_x_rg', 'acesso']),
                        _buildPermissionCheckbox('Módulo Especial', ['modulo_especial', 'acesso']),
                        _buildPermissionCheckbox('CRM', ['crm', 'acesso']),
                        _buildPermissionCheckbox('Follow-up', ['follow_up', 'acesso']),
                        // Adicionar o checkbox para Administração de Usuários aqui
                        _buildPermissionCheckbox('Administração de Usuários', ['administracao_usuarios', 'acesso']),
                      ],
                    ),
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
                  : const Text('SALVAR PERMISSÕES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}