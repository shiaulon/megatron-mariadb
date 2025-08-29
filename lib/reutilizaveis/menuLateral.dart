// lib/reutilizaveis/menuLateral.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/naturezaRendimento.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaAtividadeEmpresas.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaCargo.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaCest.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaCidade.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaComoNosConheceu.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaCondicaoPagamento.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaControle.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaEstado.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaEstadoXImposto.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaFazenda.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaIBGEXCidade.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaManutTabGovernoNcmImposto.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaNatureza.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaPais.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaSituacao.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaTipoBemCredito.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tabelaTipoHistorico.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/Tabela/tipoTelefone.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/credito/credito_faixa_x_documento.dart';
import 'package:flutter_application_1/paginasiguais/RegistroGeral/credito/tab_documento.dart';
import 'package:flutter_application_1/registroGeral/cnpj_iscricao.dart';
import 'package:flutter_application_1/registroGeral/consulta_rg_page.dart';
import 'package:flutter_application_1/registroGeral/manut_rg.dart';
import 'package:flutter_application_1/registroGeral/naturea_X_rg.dart';
import 'package:flutter_application_1/registroGeral/natureza_caracteristica.dart';
import 'package:flutter_application_1/reutilizaveis/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/permission_provider.dart';


// NOVO WIDGET: Item de menu com efeito de hover
class HoverMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSubItem; // Novo parâmetro para diferenciar sub-itens

  const HoverMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSubItem = false,
  });

  @override
  State<HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<HoverMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Define as cores e tamanhos de fonte baseados no estado de hover e se é sub-item
    final Color backgroundColor = _isHovering ? colorScheme.primary : colorScheme.surface.withOpacity(0.5);
    final Color textColor = _isHovering ? colorScheme.onPrimary : colorScheme.onSurface;
    final Color iconColor = _isHovering ? colorScheme.onPrimary : colorScheme.onSurface;
    final double fontSize = widget.isSubItem
        ? (_isHovering ? 15.0 : 13.0)
        : (_isHovering ? 16.0 : 14.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        // Usando GestureDetector para onTap, pois ListTile já tem onTap
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Duração da animação
          curve: Curves.easeInOut, // Curva da animação
          decoration: BoxDecoration(
            color: backgroundColor, // A cor agora é definida dentro do BoxDecoration
            border: Border(
              bottom:
                  BorderSide(color: Colors.black, width: widget.isSubItem ? 0.5 : 1.0),
            ),
          ),
          child: ListTile(
            leading: widget.isSubItem
                ? null
                : AnimatedContainer(
                    // Esconde o ícone principal para sub-itens
                    duration: const Duration(milliseconds: 200),
                    child: Icon(widget.icon, color: iconColor),
                  ),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: _isHovering ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(widget.title),
            ),
            dense: true,
            contentPadding: widget.isSubItem
                ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0)
                : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        ),
      ),
    );
  }
}

// NOVO WIDGET: Item de menu com sub-itens e efeito de hover
class HoverExpansionTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> subitems;

  const HoverExpansionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.subitems,
  });

  @override
  State<HoverExpansionTile> createState() => _HoverExpansionTileState();
}

class _HoverExpansionTileState extends State<HoverExpansionTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color backgroundColor = _isHovering ? colorScheme.primary : colorScheme.surface.withOpacity(0.5);
    final Color textColor = _isHovering ? colorScheme.onPrimary : colorScheme.onSurface;
    final Color iconColor = _isHovering ? colorScheme.onPrimary : colorScheme.onSurface;
    final double fontSize = _isHovering ? 16.0 : 14.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: backgroundColor, // Color defined within BoxDecoration
          border: const Border(
            bottom: BorderSide(color: Colors.black, width: 1.0),
          ),
        ),
        child: ExpansionTile(
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(widget.icon, color: iconColor),
          ),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: _isHovering ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(widget.title),
          ),
          children: widget.subitems,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          childrenPadding: const EdgeInsets.only(left: 30.0),
          iconColor: iconColor, // Use animated icon color for the expansion arrow
          collapsedIconColor: iconColor,
        ),
      ),
    );
  }
}

/// Um widget que representa o menu lateral da aplicação.
/// Ele pode ser usado em qualquer tela que precise do menu padrão.
class AppDrawer extends StatelessWidget {
  final double parentMaxWidth;
  final double breakpoint; // Adicione o breakpoint como parâmetro
  final String mainCompanyId;
  final String secondaryCompanyId;
  // final String? userRole; // REMOVIDO: Permissões via Provider

  const AppDrawer({
    Key? key,
    required this.parentMaxWidth,
    required this.breakpoint,
    required this.mainCompanyId,
    required this.secondaryCompanyId,
    // this.userRole, // REMOVIDO
  }) : super(key: key);

  // Widget auxiliar para construir itens de menu individuais
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return HoverMenuItem(
      title: title,
      icon: icon,
      onTap: onTap,
      isSubItem: false,
    );
  }

  // Widget auxiliar para construir itens de menu com sub-itens
  Widget _buildMenuItemWithSubitems(BuildContext context, String title, IconData icon, List<Widget> subitems) {
    return HoverExpansionTile(
      title: title,
      icon: icon,
      subitems: subitems,
    );
  }

  // Widget auxiliar para construir sub-itens de menu
  Widget _buildSubMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return HoverMenuItem(
      title: title,
      icon: Icons.circle,
      onTap: onTap,
      isSubItem: true,
    );
  }

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context); // Pega o tema
    final permissionProvider = Provider.of<PermissionProvider>(context); // Acessa o provider

    return Container(
      margin: parentMaxWidth > breakpoint
          ? const EdgeInsets.only(right: 10.0, top: 10.0, bottom: 10.0)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8), 
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Bloco principal "Registro Geral"
          if (permissionProvider.hasAccess(['registro_geral', 'acesso'])) // Verificação de permissão
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  child: Text(
                    'REGISTRO GERAL',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: theme.colorScheme.onSurface, // Usa a cor de texto do tema
                    ),
                  ),
                ),
                // Submenu "Tabelas"
                if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'acesso'])) // Verificação de permissão
                  _buildMenuItemWithSubitems(context, 'Tabelas', Icons.table_chart, [
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'controle']))
                      _buildSubMenuItem(context, 'Controle', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaControle(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'pais']))
                      _buildSubMenuItem(context, 'País', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaPais(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'estado']))
                      _buildSubMenuItem(context, 'Estado', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaEstado(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'estado_x_imposto']))
                      _buildSubMenuItem(context, 'Estado x Imposto', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaEstadoXImposto(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'cidade']))
                      _buildSubMenuItem(context, 'Cidade', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaCidade(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'natureza']))
                      _buildSubMenuItem(context, 'Natureza', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NaturezaTela(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'situacao']))
                      _buildSubMenuItem(context, 'Situação', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaSituacao(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'cargo']))
                      _buildSubMenuItem(context, 'Cargo', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaCargo(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'tipo_telefone']))
                      _buildSubMenuItem(context, 'Tipo Telefone', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaTipoTelefone(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'tipo_historico']))
                      _buildSubMenuItem(context, 'Tipo Histórico', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaTipoHistorico(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'tipo_bem_credito']))
                      _buildSubMenuItem(context, 'Tipo Bem Crédito', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaTipoBemCredito(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'condicao_pagamento']))
                      _buildSubMenuItem(context, 'Condição Pagamento', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaCondicaoPagamento(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'ibge_x_cidade']))
                      _buildSubMenuItem(context, 'IBGE x Cidade', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaIBGEXCidade(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'como_nos_conheceu']))
                      _buildSubMenuItem(context, 'Como nos Conheceu', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaComoNosConheceu(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'atividade_empresa']))
                      _buildSubMenuItem(context, 'Atividade Empresa', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaAtividadeEmpresas(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'tabela_cest']))
                      _buildSubMenuItem(context, 'Tabela CEST', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaCest(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'manut_tab_governo_ncm_imposto']))
                      _buildSubMenuItem(context, 'Manut Tab Governo NCM Imposto', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaManutTabGovNcmImposto(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'fazenda']))
                      _buildSubMenuItem(context, 'Fazenda', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaFazenda(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'tabelas', 'natureza_rendimento']))
                      _buildSubMenuItem(context, 'Natureza Rendimento', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaNaturezaRendimento(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                  ]),
                // Submenu "Registro Geral" (Manut RG)
                if (permissionProvider.hasAccess(['registro_geral', 'registro_geral_manut', 'acesso']))
                  _buildMenuItemWithSubitems(context, 'Registro Geral (Manut.)', Icons.app_registration, [
                    if (permissionProvider.hasAccess(['registro_geral', 'registro_geral_manut', 'manut_rg']))
                      _buildSubMenuItem(context, 'Manut RG', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaginaComAbasLaterais(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                    if (permissionProvider.hasAccess(['registro_geral', 'manut_rg', 'natureza_x_rg']))
                      _buildSubMenuItem(context, 'Natureza X RG', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NaturezaXRgScreen(mainCompanyId: mainCompanyId, secondaryCompanyId: secondaryCompanyId)))),
                      _buildSubMenuItem(
                        context, 
                        'Natureza/Caracteristica', 
                        () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NaturezaCaracteristicaScreen(
                          mainCompanyId: mainCompanyId, 
                          secondaryCompanyId: secondaryCompanyId
                        )))
                      ),
                      _buildSubMenuItem(
                        context, 
                        'RG X CNPJ', 
                        () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ManutRgCnpjInscricao(
                          mainCompanyId: mainCompanyId, 
                          secondaryCompanyId: secondaryCompanyId
                        )))
                      ),
                      _buildSubMenuItem(
                        context, 
                        'Relatorios', 
                        () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConsultaRgPage (
                          mainCompanyId: mainCompanyId, 
                          secondaryCompanyId: secondaryCompanyId
                        )))
                      ),
                  ]),
              ],
            ),
          if (permissionProvider.hasAccess(['credito', 'acesso']))
            _buildMenuItemWithSubitems(context, 'Crédito', Icons.credit_card, [
               if (permissionProvider.hasAccess(['credito', 'tabelas', 'documentos_basicos'])) // Descomente quando a permissão for criada
                _buildSubMenuItem(
                  context,
                  'Documentos Básicos',
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TabelaCreditoDocumentosBasicos(
                        mainCompanyId: mainCompanyId,
                        secondaryCompanyId: secondaryCompanyId,
                      ),
                    ),
                  ),
                ),
                _buildSubMenuItem(
                        context, 
                        'Tab Crédito X Documento', 
                        () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabelaCreditoFaixas (
                          mainCompanyId: mainCompanyId, 
                          secondaryCompanyId: secondaryCompanyId
                        )))
                      ),
            ]),

          if (permissionProvider.hasAccess(['relatorio', 'acesso']))
            _buildMenuItem(context, 'Relatório', Icons.bar_chart, () => print('Clicou em Relatório')),
          if (permissionProvider.hasAccess(['relatorio_de_critica', 'acesso']))
            _buildMenuItem(context, 'Relatório de Crítica', Icons.error_outline, () => print('Clicou em Relatório de Crítica')),
          if (permissionProvider.hasAccess(['etiqueta', 'acesso']))
            _buildMenuItem(context, 'Etiqueta', Icons.label_outline, () => print('Clicou em Etiqueta')),
          if (permissionProvider.hasAccess(['contatos_geral', 'acesso']))
            _buildMenuItem(context, 'Contatos Geral', Icons.contacts, () => print('Clicou em Contatos Geral')),
          if (permissionProvider.hasAccess(['portaria', 'acesso']))
            _buildMenuItem(context, 'Portaria', Icons.security, () => print('Clicou em Portaria')),
          if (permissionProvider.hasAccess(['qualificacao_rg', 'acesso']))
            _buildMenuItem(context, 'Qualificação RG', Icons.verified_user, () => print('Clicou em Qualificação RG')),
          if (permissionProvider.hasAccess(['area_rg', 'acesso']))
            _buildMenuItem(context, 'Área RG', Icons.area_chart, () => print('Clicou em Área RG')),
          if (permissionProvider.hasAccess(['tabela_preco_x_rg', 'acesso']))
            _buildMenuItem(context, 'Tabela Preço X RG', Icons.price_change, () => print('Clicou em Tabela Preço X RG')),
          if (permissionProvider.hasAccess(['modulo_especial', 'acesso']))
            _buildMenuItem(context, 'Módulo Especial', Icons.extension, () => print('Clicou em Módulo Especial')),
          if (permissionProvider.hasAccess(['crm', 'acesso']))
            _buildMenuItem(context, 'CRM', Icons.support_agent, () => print('Clicou em CRM')),
          if (permissionProvider.hasAccess(['follow_up', 'acesso']))
            _buildMenuItem(context, 'Follow-up', Icons.follow_the_signs, () => print('Clicou em Follow-up')),
          // Em reutilizaveis/menuLateral.dart (exemplo)
_buildMenuItem(
  context,
  'Configurações',
  Icons.settings,
  () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SettingsPage()),
  ),
),
          // Botão de administração de usuários (já tratado no _buildButtonsData da TelaPrincipal)
          // ...
        ],
      ),
    );
  }
}