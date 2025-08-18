// lib/pages/admin/user_permission_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/permission_model.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/reutilizaveis/barraSuperior.dart';
import 'package:flutter_application_1/reutilizaveis/tela_base.dart';
import 'package:flutter_application_1/services/admin_service.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/log_services.dart';
import 'package:flutter_application_1/services/permission_service.dart';
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
  late Map<String, Map<String, dynamic>> _permissionsByFilial;
  late Map<String, String> _filialNames;
  bool _isLoading = true;
  
  final AdminService _adminService = AdminService();
  final ApiService _apiService = ApiService(); // Para buscar nomes das filiais
  final PermissionService _permissionService = PermissionService(); // Para buscar permissões
  late String _currentDate;
  @override
  void initState() {
    _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    super.initState();
    _permissionsByFilial = {};
    _filialNames = {};
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de autenticação')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Busca os IDs das filiais que o USUÁRIO (que está sendo editado) pode acessar
      final allowedFilialIds = await _adminService.getUserAllowedCompanies(widget.userId, token);

      if (allowedFilialIds.isEmpty) {
        setState(() => _isLoading = false);
        return; // Sai se o usuário não tem filiais associadas
      }

      // 2. Com os IDs, busca os detalhes (nomes) dessas filiais
      final filiaisDetails = await _apiService.getSecondaryCompaniesDetails(allowedFilialIds, token);
      
      for (var filial in filiaisDetails) {
        _filialNames[filial['id']] = filial['nome'];
      }

      // 3. Para cada filial permitida, busca as permissões específicas do usuário
      for (String filialId in allowedFilialIds) {
        final permissionsData = await _permissionService.getUserPermissions(filialId, token);
        _permissionsByFilial[filialId] = permissionsData['acessos'] ?? {};
      }

    } catch (e) {
      print('Erro ao carregar dados de permissão: $e');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _togglePermission(String filialId, List<String> path, bool newValue) {
  // 1. Cria uma cópia profunda do mapa de permissões para não modificar o original diretamente.
  final newPermissionsByFilial = Map<String, Map<String, dynamic>>.from(
    _permissionsByFilial.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    ),
  );

  // 2. Navega na cópia para encontrar o local a ser alterado.
  Map<String, dynamic> currentLevel = newPermissionsByFilial[filialId]!;
  for (int i = 0; i < path.length; i++) {
    final key = path[i];
    if (i == path.length - 1) {
      // 3. Altera o valor na cópia.
      currentLevel[key] = newValue;
    } else {
      // Garante que o próximo nível seja um mapa editável (uma cópia também).
      currentLevel.putIfAbsent(key, () => <String, dynamic>{});
      currentLevel[key] = Map<String, dynamic>.from(currentLevel[key]);
      currentLevel = currentLevel[key];
    }
  }

  // 4. Atualiza o estado com o NOVO mapa modificado.
  setState(() {
    _permissionsByFilial = newPermissionsByFilial;
  });
}

  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) { /* Tratar erro */ return; }
    
    try {
      // Prepara os dados no formato que o backend espera
      final Map<String, dynamic> dataToSave = {'admin_secondary_company_id': widget.secondaryCompanyId,};
      _permissionsByFilial.forEach((filialId, acessos) {
        dataToSave[filialId] = {'acessos': acessos};
      });

      await _adminService.savePermissions(widget.userId, dataToSave, token);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissões salvas com sucesso!')));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar permissões: $e')));
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
                // ✔️ ADICIONE O CHECKBOX PARA A NOVA TELA AQUI
              _buildPermissionCheckbox(filialId, 'Natureza X RG', ['registro_geral', 'manut_rg', 'natureza_x_rg'], paddingLeft: 10.0),
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